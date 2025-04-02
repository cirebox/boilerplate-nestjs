package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestKubernetesCluster verifica se o cluster Kubernetes é implantado corretamente
func TestKubernetesCluster(t *testing.T) {
	t.Parallel()

	// Configurar as opções do Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Diretório onde os arquivos do Terraform estão localizados
		TerraformDir: "../environments/dev/digital-ocean",

		// Variáveis a serem passadas para o Terraform CLI
		Vars: map[string]interface{}{
			"environment": "test",
		},

		// Variáveis de ambiente a serem passadas para o Terraform CLI
		EnvVars: map[string]string{
			"DIGITALOCEAN_TOKEN": "", // Preencher via variável de ambiente no ambiente de CI
		},
	})

	// No final do teste, execute terraform destroy
	defer terraform.Destroy(t, terraformOptions)

	// Inicialize e aplique a configuração do Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Obtenha o nome do cluster Kubernetes
	clusterName := terraform.Output(t, terraformOptions, "kubernetes_cluster_name")
	assert.NotEmpty(t, clusterName, "O nome do cluster não deve estar vazio")

	// Obtenha o endpoint do cluster
	clusterEndpoint := terraform.Output(t, terraformOptions, "kubernetes_cluster_endpoint")
	assert.NotEmpty(t, clusterEndpoint, "O endpoint do cluster não deve estar vazio")

	// Obtenha o arquivo kubeconfig
	kubeConfigPath := terraform.Output(t, terraformOptions, "kubeconfig_path")
	
	// Configuração do Kubernetes
	kubectlOptions := k8s.NewKubectlOptions(
		"",
		kubeConfigPath,
		"default",
	)

	// Teste a conectividade com o cluster
	retry.DoWithRetry(t, "Testando conexão com o cluster Kubernetes", 30, 10*time.Second, func() (string, error) {
		nodes, err := k8s.GetNodesE(t, kubectlOptions)
		if err != nil {
			return "", err
		}
		
		return "", nil
	})

	// Verifique se o número de nós corresponde ao esperado
	nodes, err := k8s.GetNodesE(t, kubectlOptions)
	if err != nil {
		t.Fatalf("Erro ao obter nós do cluster: %v", err)
	}
	
	minNodes := 1 // Número mínimo de nós esperados
	assert.GreaterOrEqual(t, len(nodes), minNodes, "O cluster deve ter pelo menos %d nós", minNodes)

	// Verifique a versão do Kubernetes
	version, err := k8s.GetKubernetesClusterVersionE(t, kubectlOptions)
	if err != nil {
		t.Fatalf("Erro ao obter a versão do Kubernetes: %v", err)
	}
	assert.NotEmpty(t, version, "A versão do Kubernetes não deve estar vazia")

	// Verifique se namespaces padrões foram criados
	namespaces, err := k8s.GetNamespacesE(t, kubectlOptions)
	if err != nil {
		t.Fatalf("Erro ao obter namespaces: %v", err)
	}
	
	// Verifique se o namespace default existe
	hasDefaultNamespace := false
	for _, ns := range namespaces {
		if ns.Name == "default" {
			hasDefaultNamespace = true
			break
		}
	}
	assert.True(t, hasDefaultNamespace, "O namespace 'default' deve existir")

	// Verifique a saúde do cluster
	clusterHealth := terraform.OutputMap(t, terraformOptions, "cluster_status")
	assert.Equal(t, "running", clusterHealth["status"], "O status do cluster deve ser 'running'")
}

// TestKubernetesNetwork verifica as configurações de rede do cluster
func TestKubernetesNetwork(t *testing.T) {
	t.Parallel()

	// Configurar as opções do Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../environments/dev/digital-ocean",
		Vars: map[string]interface{}{
			"environment": "test",
		},
		EnvVars: map[string]string{
			"DIGITALOCEAN_TOKEN": "", // Preencher via variável de ambiente no ambiente de CI
		},
	})

	// Reutilize o cluster existente em vez de criar um novo
	terraform.InitAndPlan(t, terraformOptions)

	// Obtenha as configurações de rede
	vpcName := terraform.Output(t, terraformOptions, "vpc_name")
	assert.NotEmpty(t, vpcName, "O nome da VPC não deve estar vazio")

	vpcIp := terraform.Output(t, terraformOptions, "vpc_ip_range")
	assert.NotEmpty(t, vpcIp, "O range de IP da VPC não deve estar vazio")

	// Verifique se o range de IP está no formato CIDR esperado (por exemplo: 10.0.0.0/16)
	assert.Regexp(t, `^\d+\.\d+\.\d+\.\d+\/\d+$`, vpcIp, "O range de IP deve estar no formato CIDR")
}

// TestKubernetesConfigMap verifica se os ConfigMaps necessários estão presentes
func TestKubernetesConfigMap(t *testing.T) {
	t.Parallel()

	// Configurar as opções do Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../environments/dev/digital-ocean",
		Vars: map[string]interface{}{
			"environment": "test",
		},
		EnvVars: map[string]string{
			"DIGITALOCEAN_TOKEN": "", // Preencher via variável de ambiente no ambiente de CI
		},
	})

	// Obtenha o arquivo kubeconfig
	terraform.InitAndPlan(t, terraformOptions)
	kubeConfigPath := terraform.Output(t, terraformOptions, "kubeconfig_path")

	// Configuração do Kubernetes
	kubectlOptions := k8s.NewKubectlOptions(
		"",
		kubeConfigPath,
		"kube-system", // Namespace onde os ConfigMaps do sistema estão
	)

	// Teste a presença de ConfigMaps específicos
	retry.DoWithRetry(t, "Verificando ConfigMaps", 10, 5*time.Second, func() (string, error) {
		configMaps, err := k8s.ListConfigMapsE(t, kubectlOptions)
		if err != nil {
			return "", err
		}
		
		// Verifique se pelo menos um ConfigMap existe
		if len(configMaps) == 0 {
			return "", fmt.Errorf("nenhum ConfigMap encontrado no namespace kube-system")
		}
		
		return "", nil
	})
}

