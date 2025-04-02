package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAzureLoadBalancer(t *testing.T) {
	t.Parallel()

	// Gere um nome aleatório para evitar conflitos
	uniqueID := random.UniqueId()
	lbName := fmt.Sprintf("lb-test-%s", uniqueID)
	resourceGroupName := fmt.Sprintf("rg-test-%s", uniqueID)

	// Configuração do Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Diretório onde está o código Terraform para este teste
		TerraformDir: "../examples/load_balancing/azure",

		// Variáveis a serem passadas para o código Terraform
		Vars: map[string]interface{}{
			"resource_group_name": resourceGroupName,
			"load_balancer_name":  lbName,
			"location":            "eastus",
			"environment":         "test",
			"health_check_path":   "/health",
			"enable_https":        true,
			"tags": map[string]string{
				"Environment": "Test",
				"Terraform":   "true",
			},
		},

		// Configurações específicas do ambiente de teste
		EnvVars: map[string]string{},

		// Logs da aplicação do Terraform
		NoColor: true,
	})

	// Limpar os recursos após o teste
	defer terraform.Destroy(t, terraformOptions)

	// Inicializar e aplicar a configuração Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Validar os outputs do Terraform
	loadBalancerID := terraform.Output(t, terraformOptions, "load_balancer_id")
	loadBalancerIP := terraform.Output(t, terraformOptions, "load_balancer_ip")
	frontendIPConfigName := terraform.Output(t, terraformOptions, "frontend_ip_configuration_name")

	// Verificar se o Load Balancer foi criado corretamente
	assert.NotEmpty(t, loadBalancerID, "O ID do Load Balancer não deve estar vazio")
	assert.NotEmpty(t, loadBalancerIP, "O IP do Load Balancer não deve estar vazio")
	assert.NotEmpty(t, frontendIPConfigName, "O nome da configuração de IP frontend não deve estar vazio")

	// Verificar se o Load Balancer existe no Azure
	exists := azure.LoadBalancerExists(t, lbName, resourceGroupName, "")
	assert.True(t, exists, "O Load Balancer deve existir no Azure")

	// Verificar as regras de balanceamento de carga
	httpRuleExists := checkLoadBalancingRuleExists(t, terraformOptions, "http")
	assert.True(t, httpRuleExists, "A regra HTTP deve existir no Load Balancer")

	httpsRuleExists := checkLoadBalancingRuleExists(t, terraformOptions, "https")
	assert.True(t, httpsRuleExists, "A regra HTTPS deve existir no Load Balancer")

	// Verificar o probe de saúde
	healthProbeExists := checkHealthProbeExists(t, terraformOptions)
	assert.True(t, healthProbeExists, "O health probe deve existir no Load Balancer")

	// Testar a resposta HTTP (isso pode exigir uma instância real em execução)
	// Em um ambiente de teste completo, você pode implantar um servidor web simples
	// e verificar se o Load Balancer está encaminhando o tráfego corretamente
	if loadBalancerIP != "" {
		// Aguardar um tempo para o Load Balancer estar totalmente operacional
		time.Sleep(30 * time.Second)

		// Este é um teste ideal que você implementaria em um ambiente real
		// httpStatusOK := checkHTTPStatus(t, fmt.Sprintf("http://%s/health", loadBalancerIP))
		// assert.True(t, httpStatusOK, "O endpoint de saúde deve retornar um status HTTP 200")
	}

	// Testar integração com Azure Monitor (opcional)
	// metricsEnabled := checkAzureMonitorIntegration(t, terraformOptions)
	// assert.True(t, metricsEnabled, "A integração com Azure Monitor deve estar habilitada")
}

// Função auxiliar para verificar se uma regra de balanceamento existe
func checkLoadBalancingRuleExists(t *testing.T, terraformOptions *terraform.Options, protocol string) bool {
	// Em um ambiente real, você usaria o SDK do Azure para verificar
	// se a regra existe no Load Balancer
	// Aqui, estamos apenas verificando se o output do Terraform tem um valor
	ruleName := terraform.Output(t, terraformOptions, fmt.Sprintf("%s_rule_name", protocol))
	return ruleName != ""
}

// Função auxiliar para verificar se o health probe existe
func checkHealthProbeExists(t *testing.T, terraformOptions *terraform.Options) bool {
	// Em um ambiente real, você usaria o SDK do Azure para verificar
	// se o health probe existe no Load Balancer
	// Aqui, estamos apenas verificando se o output do Terraform tem um valor
	probeName := terraform.Output(t, terraformOptions, "health_probe_name")
	return probeName != ""
}

// Teste de integração com módulo principal abstrato
func TestAzureAbstractLoadBalancer(t *testing.T) {
	t.Parallel()

	// Gere um nome aleatório para evitar conflitos
	uniqueID := random.UniqueId()
	lbName := fmt.Sprintf("lb-test-%s", uniqueID)
	resourceGroupName := fmt.Sprintf("rg-test-%s", uniqueID)

	// Configuração do Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Diretório onde está o código Terraform para o teste abstrato
		TerraformDir: "../examples/abstraction",

		// Variáveis a serem passadas para o código Terraform
		Vars: map[string]interface{}{
			"provider_name":       "azure",
			"resource_group_name": resourceGroupName,
			"load_balancer_name":  lbName,
			"location":            "eastus",
			"environment":         "test",
		},

		// Configurações específicas do ambiente de teste
		EnvVars: map[string]string{},

		// Logs da aplicação do Terraform
		NoColor: true,
	})

	// Limpar os recursos após o teste
	defer terraform.Destroy(t, terraformOptions)

	// Inicializar e aplicar a configuração Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verificar o output específico de provedor
	providerOutput := terraform.Output(t, terraformOptions, "load_balancer_provider")
	assert.Equal(t, "azure", providerOutput, "O provedor deve ser Azure")

	// Verificar outputs comuns a todos os provedores
	loadBalancerEndpoint := terraform.Output(t, terraformOptions, "load_balancer_endpoint")
	assert.NotEmpty(t, loadBalancerEndpoint, "O endpoint do Load Balancer não deve estar vazio")

	// Testar a mudança de provedor (isso pode ser feito em um teste separado)
	// Verificar se alterando a variável provider_name para "aws" o módulo correto é usado
}

