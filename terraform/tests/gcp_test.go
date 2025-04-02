package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestGcpInfrastructure verifica se a infraestrutura GCP é criada corretamente
func TestGcpInfrastructure(t *testing.T) {
	t.Parallel()

	// Gera um ID único para evitar conflitos de nome
	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-nestjs-%s", uniqueID)
	projectID := gcp.GetGoogleProjectIDFromEnvVar(t)

	// Configurações do terratest para GCP
	terraformOptions := &terraform.Options{
		// Diretório onde estão os arquivos Terraform para teste
		TerraformDir: "../environments/dev",

		// Variáveis a serem passadas para o Terraform
		Vars: map[string]interface{}{
			"environment":     "test",
			"project_name":    projectName,
			"active_provider": "gcp",
			"provider_config": map[string]interface{}{
				"gcp_project": projectID,
				"gcp_region":  "us-central1",
				"gcp_zone":    "us-central1-a",
			},
		},

		// Configura log detalhado
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)

	// Para testes de integração completos, descomente:
	// defer terraform.Destroy(t, terraformOptions)
	// terraform.InitAndApply(t, terraformOptions)
	// 
	// // Obtém os outputs do Terraform
	// vpcName := terraform.Output(t, terraformOptions, "vpc_name")
	// clusterEndpoint := terraform.Output(t, terraformOptions, "kubernetes_endpoint")
	// dbEndpoint := terraform.Output(t, terraformOptions, "database_endpoint")
	// 
	// // Verifica se a VPC foi criada
	// vpc := gcp.GetVpc(t, vpcName, projectID)
	// assert.Equal(t, vpcName, vpc.Name)
	//
	// // Verifica se o cluster Kubernetes foi criado corretamente
	// assert.NotEmpty(t, clusterEndpoint)
	// 
	// // Verifica se o banco de dados foi criado corretamente
	// assert.NotEmpty(t, dbEndpoint)
}

// TestGcpKubernetesCluster testa especificamente o cluster Kubernetes no GCP
func TestGcpKubernetesCluster(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-gke-%s", uniqueID)
	projectID := gcp.GetGoogleProjectIDFromEnvVar(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/kubernetes/gcp",
		Vars: map[string]interface{}{
			"environment":      "test",
			"project_name":     projectName,
			"project_id":       projectID,
			"region":           "us-central1",
			"cluster_version":  "1.26",
			"node_instance_types": []string{"e2-standard-2"},
			"min_nodes":        1,
			"max_nodes":        2,
			"desired_nodes":    1,
			"vpc_self_link":    "dummy-vpc-self-link", // Seria substituído por uma VPC real em testes de integração
			"subnet_self_link": "dummy-subnet-self-link", // Seria substituído por subnets reais
		},
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}

// TestGcpCostMonitoring testa o módulo de monitoramento de custos do GCP
func TestGcpCostMonitoring(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-cost-%s", uniqueID)
	projectID := gcp.GetGoogleProjectIDFromEnvVar(t)
	billingAccountID := "ABCDEF-123456-GHIJKL" // Substitua por um ID real em testes de integração

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/cost_monitor/gcp",
		Vars: map[string]interface{}{
			"environment":            "test",
			"project_name":           projectName,
			"project_id":             projectID,
			"billing_account_id":     billingAccountID,
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

// TestGcpNetwork testa a configuração de rede no GCP
func TestGcpNetwork(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-net-%s", uniqueID)
	projectID := gcp.GetGoogleProjectIDFromEnvVar(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/network/gcp",
		Vars: map[string]interface{}{
			"environment":  "test",
			"project_name": projectName,
			"project_id":   projectID,
			"vpc_cidr":     "10.0.0.0/16",
		},
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}

// TestGcpDatabase testa a configuração do banco de dados no GCP
func TestGcpDatabase(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-db-%s", uniqueID)
	projectID := gcp.GetGoogleProjectIDFromEnvVar(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/database/gcp",
		Vars: map[string]interface{}{
			"environment":     "test",
			"project_name":    projectName,
			"project_id":      projectID,
			"instance_type":   "db-custom-1-3840",
			"storage_gb":      20,
			"engine_version":  "POSTGRES_14",
			"vpc_self_link":   "dummy-vpc-self-link", // Seria substituído por uma VPC real em testes de integração
		},
		NoColor: true,
	}

	// Este teste é configuracional apenas, não realiza deploy real
	terraform.InitAndPlan(t, terraformOptions)
}