package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestNetworkModuleAWS(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/network/aws",
		Vars: map[string]interface{}{
			"environment":  "test",
			"project_name": "test-project",
			"vpc_cidr":     "10.0.0.0/16",
			"tags": map[string]string{
				"TestName": "NetworkModuleTest",
			},
		},
	})

	// Destruir os recursos criados após o teste
	defer terraform.Destroy(t, terraformOptions)
	
	// Inicializar e aplicar a configuração
	terraform.InitAndApply(t, terraformOptions)

	// Validar os outputs
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId, "VPC ID não deve ser vazio")
	
	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.NotEmpty(t, publicSubnetIds, "IDs de subnets públicas não devem ser vazios")
	
	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.NotEmpty(t, privateSubnetIds, "IDs de subnets privadas não devem ser vazios")

	// Validar quantidade de subnets
	assert.Equal(t, 3, len(publicSubnetIds), "Devem existir 3 subnets públicas")
	assert.Equal(t, 3, len(privateSubnetIds), "Devem existir 3 subnets privadas")
}

func TestNetworkModuleDigitalOcean(t *testing.T) {
	t.Parallel()

	// Skip este teste se não houver credenciais configuradas
	t.Skip("Este teste requer credenciais do Digital Ocean configuradas")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/network/digital-ocean",
		Vars: map[string]interface{}{
			"environment":  "test",
			"project_name": "test-project",
			"vpc_cidr":     "10.0.0.0/16",
		},
	})

	// Destruir os recursos criados após o teste
	defer terraform.Destroy(t, terraformOptions)
	
	// Inicializar e aplicar a configuração
	terraform.InitAndApply(t, terraformOptions)

	// Validar os outputs
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId, "VPC ID não deve ser vazio")
}

func TestNetworkModuleGCP(t *testing.T) {
	t.Parallel()

	// Skip este teste se não houver credenciais configuradas
	t.Skip("Este teste requer credenciais do GCP configuradas")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/network/gcp",
		Vars: map[string]interface{}{
			"environment":  "test",
			"project_name": "test-project",
			"vpc_cidr":     "10.0.0.0/16",
			"tags": map[string]string{
				"TestName": "NetworkModuleTest",
			},
		},
	})

	// Destruir os recursos criados após o teste
	defer terraform.Destroy(t, terraformOptions)
	
	// Inicializar e aplicar a configuração
	terraform.InitAndApply(t, terraformOptions)

	// Validar os outputs
	vpcSelfLink := terraform.Output(t, terraformOptions, "vpc_self_link")
	assert.NotEmpty(t, vpcSelfLink, "VPC self link não deve ser vazio")
	
	privateSubnetSelfLink := terraform.Output(t, terraformOptions, "private_subnet_self_link")
	assert.NotEmpty(t, privateSubnetSelfLink, "Self link de subnet privada não deve ser vazio")
}