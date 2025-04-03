# Módulo [Nome do Módulo]

## Descrição
Breve descrição do propósito do módulo.

## Recursos Criados
- Lista de recursos principais criados por este módulo
- ...

## Uso
```hcl
module "example" {
  source = "./modules/[caminho-do-módulo]"
  
  # Parâmetros obrigatórios
  environment = "dev"
  project_name = "example"
  
  # Outros parâmetros
  # ...
}
```

## Variáveis de Entrada

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|------------|
| environment | Ambiente de deploy | string | - | sim |
| project_name | Nome do projeto | string | - | sim |
| ... | ... | ... | ... | ... |

## Outputs

| Nome | Descrição |
|------|-----------|
| example_id | ID do recurso criado |
| ... | ... |

## Dependências

- Lista de outros módulos dos quais este depende
- ...

## Notas de Uso
Informações adicionais relevantes para o uso do módulo.

## Considerações de Segurança
Informações sobre configurações de segurança importantes.

## Considerações de Custo
Informações sobre custos e otimizações potenciais.

## Manutenção
- Frequência de atualizações recomendadas
- Práticas para manutenção e monitoramento

## Exemplos
Exemplos detalhados de uso para diferentes casos.