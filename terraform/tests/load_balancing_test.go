package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// TestLoadBalancingDigitalOcean testa a implementação do load balancer no Digital Ocean
func TestLoadBalancingDigitalOcean(t *testing.T) {
	t.Parallel()

	// Pasta temporária para o teste
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load_balancing/digital-ocean")

	// ID único para evitar conflitos
	uniqueID := random.UniqueId()
	name := fmt.Sprintf("lb-test-%s", uniqueID)

	// Configuração do Terraform para o Digital Ocean
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: exampleFolder,
		Vars: map[string]interface{}{
			"name":        name,
			"environment": "test",
			"region":      "nyc1",
			"protocol":    "http",
			"port":        80,
			"target_port": 8080,
			"provider":    "digitalocean",
		},
		NoColor: true,
	})

	// Limpeza após o teste
	defer terraform.Destroy(t, terraformOptions)

	// Aplica a configuração do Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Obtém o endereço IP do load balancer
	lbIP := terraform.Output(t, terraformOptions, "load_balancer_ip")
	lbID := terraform.Output(t, terraformOptions, "load_balancer_id")

	// Validações
	assert.NotEmpty(t, lbIP, "O endereço IP do load balancer não deve ser vazio")
	assert.NotEmpty(t, lbID, "O ID do load balancer não deve ser vazio")

	// Verificar se o load balancer está respondendo (simulado)
	t.Log("O load balancer do Digital Ocean foi criado com sucesso:", lbIP)
}

// TestLoadBalancingAWS testa a implementação do load balancer na AWS
func TestLoadBalancingAWS(t *testing.T) {
	t.Parallel()

	// Configurações da AWS para o teste
	awsRegion := "us-east-1"

	// Pasta temporária para o teste
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load_balancing/aws")

	// ID único para evitar conflitos
	uniqueID := random.UniqueId()
	name := fmt.Sprintf("lb-test-%s", uniqueID)

	// Configuração do Terraform para AWS
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: exampleFolder,
		Vars: map[string]interface{}{
			"name":        name,
			"environment": "test",
			"region":      awsRegion,
			"protocol":    "http",
			"port":        80,
			"target_port": 8080,
			"provider":    "aws",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
		NoColor: true,
	})

	// Limpeza após o teste
	defer terraform.Destroy(t, terraformOptions)

	// Aplica a configuração do Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Obtém o DNS do load balancer
	lbDNS := terraform.Output(t, terraformOptions, "load_balancer_dns")
	lbARN := terraform.Output(t, terraformOptions, "load_balancer_arn")

	// Validações
	assert.NotEmpty(t, lbDNS, "O DNS do load balancer não deve ser vazio")
	assert.NotEmpty(t, lbARN, "O ARN do load balancer não deve ser vazio")

	// Verificar se o load balancer está ativo
	maxRetries := 30
	timeBetweenRetries := 10 * time.Second
	
	aws.WaitForLBToExist(t, awsRegion, lbARN, maxRetries, timeBetweenRetries)

	t.Log("O load balancer da AWS foi criado com sucesso:", lbDNS)
}

// TestLoadBalancingGCP testa a implementação do load balancer no GCP
func TestLoadBalancingGCP(t *testing.T) {
	t.Parallel()

	// Configurações do GCP para o teste
	projectID := "my-gcp-project-id" // Substitua pelo ID do seu projeto
	region := "us-central1"

	// Pasta temporária para o teste
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load_balancing/gcp")

	// ID único para evitar conflitos
	uniqueID := random.UniqueId()
	name := fmt.Sprintf("lb-test-%s", uniqueID)

	// Configuração do Terraform para GCP
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: exampleFolder,
		Vars: map[string]interface{}{
			"name":        name,
			"environment": "test",
			"region":      region,
			"protocol":    "http",
			"port":        80,
			"target_port": 8080,
			"provider":    "gcp",
			"project_id":  projectID,
		},
		NoColor: true,
	})

	// Limpeza após o teste
	defer terraform.Destroy(t, terraformOptions)

	// Aplica a configuração do Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Obtém o IP do load balancer
	lbIP := terraform.Output(t, terraformOptions, "load_balancer_ip")
	lbName := terraform.Output(t, terraformOptions, "load_balancer_name")

	// Validações
	assert.NotEmpty(t, lbIP, "O IP do load balancer não deve ser vazio")
	assert.NotEmpty(t, lbName, "O nome do load balancer não deve ser vazio")

	// Verificar se o load balancer está ativo
	maxRetries := 30
	timeBetweenRetries := 10 * time.Second
	
	// Aguarda o load balancer do GCP ficar ativo
	urlToCheck := fmt.Sprintf("http://%s", lbIP)
	gcp.WaitForUrlWithRetry(t, urlToCheck, nil, 200, "OK", maxRetries, timeBetweenRetries)

	t.Log("O load balancer do GCP foi criado com sucesso:", lbIP)
}

// TestLoadBalancingAbstração testa o módulo abstrato de load balancing com diferentes provedores
func TestLoadBalancingAbstracao(t *testing.T) {
	t.Parallel()

	// Pasta temporária para o teste
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load_balancing/main")

	// Testes para cada provedor
	testProviders := []string{"digitalocean", "aws", "gcp", "azure"}

	for _, provider := range testProviders {
		provider := provider // Captura a variável para evitar problemas de concorrência
		
		t.Run(fmt.Sprintf("Provedor_%s", provider), func(t *testing.T) {
			t.Parallel()

			// ID único para evitar conflitos
			uniqueID := random.UniqueId()
			name := fmt.Sprintf("lb-test-%s", uniqueID)
			
			// Configurações específicas do provedor
			vars := map[string]interface{}{
				"name":        name,
				"environment": "test",
				"protocol":    "http",
				"port":        80,
				"target_port": 8080,
				"provider":    provider,
			}
			
			// Adiciona configurações específicas por provedor
			switch provider {
			case "aws":
				vars["region"] = "us-east-1"
			case "gcp":
				vars["region"] = "us-central1"
				vars["project_id"] = "my-gcp-project-id" // Substitua pelo ID do seu projeto
			case "digitalocean":
				vars["region"] = "nyc1"
			case "azure":
				vars["region"] = "eastus" // Região padrão do Azure
				vars["resource_group_name"] = "test-lb-rg" // Nome do grupo de recursos
				vars["subscription_id"] = "00000000-0000-0000-0000-000000000000" // Substitua pelo ID da sua assinatura
				vars["vnet_name"] = "test-vnet" // Nome da rede virtual
				vars["subnet_name"] = "test-subnet" // Nome da subnet
			}

			// Configuração do Terraform
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: exampleFolder,
				Vars:         vars,
				NoColor:      true,
			})

			// Limpeza após o teste
			defer terraform.Destroy(t, terraformOptions)

			// Aplica a configuração do Terraform
			terraform.InitAndApply(t, terraformOptions)

			// Obtém a URL do load balancer (saída padronizada do módulo abstrato)
			lbEndpoint := terraform.Output(t, terraformOptions, "load_balancer_endpoint")
			lbID := terraform.Output(t, terraformOptions, "load_balancer_id")

			// Validações
			assert.NotEmpty(t, lbEndpoint, "O endpoint do load balancer não deve ser vazio")
			assert.NotEmpty(t, lbID, "O ID do load balancer não deve ser vazio")

			t.Logf("O load balancer do provedor %s foi criado com sucesso: %s", provider, lbEndpoint)
		})
	}
}

