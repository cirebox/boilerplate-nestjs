package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"fmt"
)

// Teste para o módulo abstrato de load balancing
func TestLoadBalancingAbstractModule(t *testing.T) {
	t.Parallel()
	
	// Preparar dados do teste
	testName := "lb-test"
	envName := "test"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/load_balancing/main",
		Vars: map[string]interface{}{
			"name":        testName,
			"environment": envName,
			"provider_type": "aws", // Usando AWS como provedor para os testes
			"protocol":    "http",
			"port":        80,
			"target_port": 8080,
			"health_check_path": "/health",
			"aws_region": "us-east-1",
			"tags": map[string]string{
				"TestName": "LoadBalancingTest",
			},
		},
	})

	// Limpar recursos após o teste
	defer terraform.Destroy(t, terraformOptions)
	
	// Testar com plano (sem aplicar)
	// Isso permite testar o código sem realmente criar recursos na nuvem
	terraform.InitAndPlan(t, terraformOptions)
	
	// Em um cenário real, poderíamos aplicar e verificar os outputs:
	// terraform.InitAndApply(t, terraformOptions)
	// lbId := terraform.Output(t, terraformOptions, "load_balancer_id")
	// assert.NotEmpty(t, lbId)
}

// Teste dedicado para o módulo de load balancing do Digital Ocean
func TestLoadBalancingDigitalOcean(t *testing.T) {
	t.Parallel()
	
	// Skip este teste se não houver credenciais configuradas
	t.Skip("Este teste requer credenciais do Digital Ocean configuradas")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/load_balancing/digital-ocean",
		Vars: map[string]interface{}{
			"name":        "do-test-lb",
			"environment": "test",
			"region":      "nyc1",
			"protocol":    "http",
			"port":        80,
			"target_port": 8080,
			"health_check_path": "/health",
			// Normalmente precisaríamos de droplet_ids, mas não os temos no teste
		},
	})

	// Destruir recursos após o teste
	defer terraform.Destroy(t, terraformOptions)
	
	// Como não temos droplets reais, vamos apenas validar o plano
	terraform.InitAndPlan(t, terraformOptions)
}

// Teste para o Azure Load Balancer
func TestLoadBalancingAzure(t *testing.T) {
	t.Parallel()
	
	// Skip este teste se não houver credenciais configuradas
	t.Skip("Este teste requer credenciais do Azure configuradas")

	// Normalmente teríamos recursos pré-existentes como grupo de recursos e VNet
	// Para testes, podemos usar valores fictícios
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/load_balancing/azure",
		Vars: map[string]interface{}{
			"name":                "azure-test-lb",
			"resource_group_name": fmt.Sprintf("test-rg-%s", "unique-id"),
			"location":            "brazilsouth",
			"subnet_name":         "test-subnet",
			"virtual_network_name": "test-vnet",
			"enable_https":        false,
			"backend_port":        8080,
			"frontend_port":       80,
			"health_check_path":   "/health",
			"tags": map[string]string{
				"Environment": "Test",
				"Project":     "TerratestExample",
			},
		},
	})

	// Como não temos recursos reais para testar, verificamos apenas o plano
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
}

