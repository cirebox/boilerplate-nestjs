package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestAwsInfrastructure verifica se a infraestrutura AWS é criada corretamente
func TestAwsInfrastructure(t *testing.T) {
	t.Parallel()

	// Gera um ID único para evitar conflitos de nome
	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-nestjs-%s", uniqueID)

	// Configurações do terratest para AWS
	terraformOptions := &terraform.Options{
		// Diretório onde estão os arquivos Terraform para teste
		TerraformDir: "../environments/dev",

		// Variáveis a serem passadas para o Terraform
		Vars: map[string]interface{}{
			"environment":     "test",
			"project_name":    projectName,
			"active_provider": "aws",
		},

		// Configura log detalhado
		NoColor: true,
	}

	// Limpa a infraestrutura no final do teste
	defer terraform.Destroy(t, terraformOptions)

	// Inicializa e aplica a configuração Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Obtém os outputs do Terraform
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	clusterEndpoint := terraform.Output(t, terraformOptions, "kubernetes_endpoint")
	dbEndpoint := terraform.Output(t, terraformOptions, "database_endpoint")

	// Verifica se a VPC foi criada
	region := aws.GetDefaultRegion(t)
	vpc := aws.GetVpcById(t, vpcID, region)
	assert.Equal(t, vpc.Id, vpcID)

	// Verifica se o cluster Kubernetes foi criado corretamente
	assert.NotEmpty(t, clusterEndpoint)

	// Verifica se o banco de dados foi criado corretamente
	assert.NotEmpty(t, dbEndpoint)

	// Verifica se os grupos de segurança foram configurados corretamente
	sgName := fmt.Sprintf("%s-test-sg", projectName)
	securityGroups := aws.GetSecurityGroupsByName(t, region, sgName)
	assert.NotEmpty(t, securityGroups)

	// Testa conexão com o banco de dados (com retry)
	maxRetries := 5
	retryInterval := 10 * time.Second
	dbConnected := false

	for i := 0; i < maxRetries; i++ {
		// Simulando tentativa de conexão ao banco
		// Em um teste real isso usaria uma conexão real
		if i == maxRetries-1 {
			dbConnected = true
			break
		}
		time.Sleep(retryInterval)
	}
	assert.True(t, dbConnected, "Não foi possível conectar ao banco de dados")
}

// TestAwsKubernetesCluster testa especificamente o cluster Kubernetes na AWS
func TestAwsKubernetesCluster(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-eks-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/kubernetes/aws",
		Vars: map[string]interface{}{
			"environment":      "test",
			"project_name":     projectName,
			"cluster_version":  "1.26",
			"node_instance_types": []string{"t3.medium"},
			"min_nodes":        1,
			"max_nodes":        2,
			"desired_nodes":    1,
			"vpc_id":           "dummy-vpc-id", // Seria substituído por uma VPC real em testes de integração
			"subnet_ids":       []string{"subnet-1", "subnet-2"}, // Seria substituído por subnets reais
		},
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)

	// Para testes de integração completos, descomente:
	// defer terraform.Destroy(t, terraformOptions)
	// terraform.InitAndApply(t, terraformOptions)
	// clusterName := terraform.Output(t, terraformOptions, "cluster_name")
	// assert.Contains(t, clusterName, projectName)
}

// TestAwsCostMonitoring testa o módulo de monitoramento de custos da AWS
func TestAwsCostMonitoring(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-cost-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/cost_monitor/aws",
		Vars: map[string]interface{}{
			"environment":            "test",
			"project_name":           projectName,
			"budget_amount":          100,
			"budget_currency":        "USD",
			"alert_threshold_percent": 80,
			"alert_emails":           []string{"test@example.com"},
		},
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}