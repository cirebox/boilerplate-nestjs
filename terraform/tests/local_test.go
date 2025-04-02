package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestLocalEnvironment verifica se o ambiente local é criado corretamente usando Docker
func TestLocalEnvironment(t *testing.T) {
	t.Parallel()

	// Gera um ID único para evitar conflitos de nome
	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-local-%s", uniqueID)

	// Configurações do terratest para o ambiente local
	terraformOptions := &terraform.Options{
		// Diretório onde estão os arquivos Terraform para teste
		TerraformDir: "../",

		// Variáveis a serem passadas para o Terraform
		Vars: map[string]interface{}{
			"environment":     "test",
			"project_name":    projectName,
			"active_provider": "local",
			"provider_config": map[string]interface{}{
				"local": map[string]interface{}{
					"docker_host": "unix:///var/run/docker.sock",
					"deploy_app":  true,
				},
			},
		},

		// Configura log detalhado
		NoColor: true,
	}

	// Limpa a infraestrutura no final do teste
	defer terraform.Destroy(t, terraformOptions)

	// Inicializa e aplica a configuração Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verifica se os contêineres foram criados
	dbContainerName := fmt.Sprintf("%s-test-db", projectName)
	appContainerName := fmt.Sprintf("%s-test-app", projectName)
	
	// Verifica se o contêiner do banco de dados está em execução
	dbRunning := docker.RunDockerCommand(t, "", "ps", "--filter", fmt.Sprintf("name=%s", dbContainerName), "--format", "{{.Names}}")
	assert.Contains(t, dbRunning, dbContainerName)

	// Verifica se o contêiner da aplicação está em execução
	appRunning := docker.RunDockerCommand(t, "", "ps", "--filter", fmt.Sprintf("name=%s", appContainerName), "--format", "{{.Names}}")
	assert.Contains(t, appRunning, appContainerName)

	// Testa a conexão entre os contêineres
	// Espera um tempo para os serviços estarem disponíveis
	time.Sleep(5 * time.Second)
	
	// Executa um comando no contêiner da aplicação para verificar a conexão com o banco de dados
	// Exemplo: curl ou ping para verificar a conectividade
	networkCheck := docker.RunDockerCommand(t, "", "network", "inspect", fmt.Sprintf("%s-test-network", projectName))
	assert.Contains(t, networkCheck, dbContainerName)
	assert.Contains(t, networkCheck, appContainerName)
}

// TestLocalModuleConfiguration verifica se o módulo local está configurado corretamente
func TestLocalModuleConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-local-config-%s", uniqueID)

	// Configurações do terratest para o módulo local
	terraformOptions := &terraform.Options{
		// Diretório onde está o módulo local
		TerraformDir: "../modules/local",

		// Variáveis a serem passadas para o Terraform
		Vars: map[string]interface{}{
			"project_name":     projectName,
			"docker_host":      "unix:///var/run/docker.sock",
			"network_name":     fmt.Sprintf("%s-network", projectName),
			"data_volume_name": fmt.Sprintf("%s-data", projectName),
			"db_username":      "testuser",
			"db_password":      "testpassword",
			"db_name":          "testdb",
			"db_port":          5432,
			"app_port":         3000,
			"app_image":        "node:18-alpine",
			"database_image":   "postgres:14",
			"deploy_app":       false, // Testar apenas a configuração, sem criar o contêiner
		},

		// Configura log detalhado
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}

// TestLocalIntegration testa a integração entre o módulo local e outros componentes
func TestLocalIntegration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-local-integ-%s", uniqueID)

	// Configurações do terratest para o ambiente de desenvolvimento com provedor local
	terraformOptions := &terraform.Options{
		// Diretório onde estão os arquivos Terraform para teste
		TerraformDir: "../environments/dev",

		// Variáveis a serem passadas para o Terraform
		Vars: map[string]interface{}{
			"environment":     "test",
			"project_name":    projectName,
			"active_provider": "local",
		},

		// Configura log detalhado
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}