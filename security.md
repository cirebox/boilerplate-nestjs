# Scanner de Vulnerabilidades na CI

Este documento descreve a configuração e uso dos scanners de vulnerabilidades integrados na pipeline de CI do projeto.

## Ferramentas Implementadas

O projeto utiliza múltiplas ferramentas para verificação de segurança:

1. **npm audit** - Verifica vulnerabilidades nas dependências do npm
2. **Snyk** - Análise de vulnerabilidades em dependências e código
3. **SonarCloud** - Análise estática de código e vulnerabilidades 
4. **Gitleaks** - Detecta segredos expostos no código
5. **OWASP Dependency-Check** - Análise detalhada de dependências contra o banco de dados NVD

## Configuração

### Requisitos

Para utilizar todas as ferramentas, você precisa configurar:

1. **Snyk**:
   - Crie uma conta em [Snyk.io](https://snyk.io)
   - Gere um token API
   - Adicione o token como secret no GitHub: `SNYK_TOKEN`

2. **SonarCloud**:
   - Crie uma conta em [SonarCloud](https://sonarcloud.io)
   - Configure uma organização e projeto
   - Obtenha um token de análise
   - Adicione o token como secret no GitHub: `SONAR_TOKEN`
   - Atualize o arquivo `sonar-project.properties` com os dados do seu projeto

3. **OWASP Dependency-Check**:
   - Não requer configuração adicional
   - O arquivo `suppression.xml` pode ser usado para suprimir falsos positivos

### Secrets Necessários

Adicione os seguintes secrets no seu repositório GitHub:

- `SNYK_TOKEN`: Token de API do Snyk
- `SONAR_TOKEN`: Token de análise do SonarCloud

## Como Funciona

O pipeline de segurança é executado:
- Em cada push para as branches `main` e `develop`
- Em cada pull request para essas branches
- Semanalmente aos domingos (para capturar vulnerabilidades recém-descobertas)

### Relatórios

Após a execução, os relatórios são disponibilizados como artefatos da action e podem ser baixados para análise detalhada.

### Níveis de Severidade

- **npm audit**: Falha em vulnerabilidades de nível alto ou crítico
- **Snyk**: Falha em vulnerabilidades de nível alto ou crítico
- **Dependency-Check**: Falha em vulnerabilidades com CVSS ≥ 7.0

## Supressão de Falsos Positivos

Para suprimir falsos positivos no OWASP Dependency-Check, edite o arquivo `suppression.xml` com a seguinte estrutura:

```xml
<suppress>
   <notes>Razão para suprimir esta vulnerabilidade</notes>
   <packageUrl regex="true">^pkg:npm/package\-name@.*$</packageUrl>
   <cve>CVE-XXXX-XXXXX</cve>
</suppress>
```

## Integração com PR Review

Os resultados do scanner são automaticamente comentados nos Pull Requests, facilitando a revisão das vulnerabilidades antes do merge.

## Boas Práticas

1. **Resolva vulnerabilidades rapidamente**: Priorize a correção de vulnerabilidades de alta severidade
2. **Atualize dependências regularmente**: Execute `npm update` periodicamente
3. **Revise os relatórios semanais**: Mesmo vulnerabilidades de baixa severidade podem se tornar críticas
4. **Documente supressões**: Sempre documente por que uma vulnerabilidade foi suprimida
5. **Verifique vulnerabilidades localmente**: Execute `npm audit` e `npx snyk test` antes de fazer commits

## Recursos Adicionais

- [Documentação do Snyk](https://docs.snyk.io/)
- [Documentação do SonarCloud](https://docs.sonarcloud.io/)
- [Documentação do OWASP Dependency-Check](https://jeremylong.github.io/DependencyCheck/)
- [Guia do Gitleaks](https://github.com/zricethezav/gitleaks)