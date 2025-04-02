# Configuração do Husky e Regras de Commits

Este documento detalha as configurações do Husky e as regras de commits implementadas no NestJS Boilerplate para microsserviços, visando garantir a qualidade e padronização do código antes de cada operação Git.

## O que é o Husky?

Husky é uma ferramenta que permite a configuração de Git hooks para executar scripts automaticamente antes de eventos Git, como commits ou pushes, facilitando a validação do código e garantindo padrões de qualidade.

## Hooks Configurados

### Pre-commit

O hook `pre-commit` executa diversas verificações antes de permitir um commit:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Executa lint-staged para verificar apenas arquivos modificados
npx lint-staged

# Verifica se existem segredos no código
npx gitleaks protect --staged --verbose

# Valide o esquema Prisma
npx prisma validate

# Execute verificações de tipos TypeScript
npx tsc --noEmit

# Verifica tamanho máximo de arquivos (5MB)
find . -type f -not -path '*/node_modules/*' -not -path '*/\.*' -not -path '*/dist/*' -size +5M | grep -v '.git/' > /dev/null && echo '❌ Arquivos muito grandes encontrados (>5MB)' && exit 1 || echo '✅ Nenhum arquivo grande encontrado'

# Verifica TODOs/FIXMEs nos arquivos modificados
git diff --cached --name-only | xargs grep -l "TODO\|FIXME" && echo "⚠️ Aviso: TODOs/FIXMEs encontrados nos arquivos modificados"

# Execute testes e build como já configurado
npm test && npm run lint && npm run build
```

### Commit-msg

O hook `commit-msg` valida a mensagem de commit usando o Commitlint:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Verifica padrão convencional de commits
npx --no -- commitlint --edit $1

# Verifica tamanho da mensagem
COMMIT_MSG_FILE=$1
FIRST_LINE=$(head -n1 $COMMIT_MSG_FILE)
if [ ${#FIRST_LINE} -gt 72 ]; then
  echo "❌ A primeira linha da mensagem de commit deve ter no máximo 72 caracteres"
  exit 1
fi

if [ ${#FIRST_LINE} -lt 10 ]; then
  echo "❌ A primeira linha da mensagem de commit deve ter pelo menos 10 caracteres"
  exit 1
fi
```

### Pre-push

O hook `pre-push` executa verificações mais pesadas antes de enviar as alterações ao repositório remoto:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Verificação de cobertura de testes
npm run test:cov

# Verificação de segurança para dependências (apenas alerta)
echo "🔍 Verificando vulnerabilidades nas dependências..."
npm audit --audit-level=high || (
  echo ""
  echo "⚠️ AVISO DE SEGURANÇA ⚠️"
  echo "Foram encontradas vulnerabilidades de alto risco nas dependências."
  echo "Recomenda-se executar 'npm audit fix' ou revisar as vulnerabilidades."
  echo "Esta verificação é apenas informativa e não bloqueará seu push."
  echo ""
  # Retorna 0 para permitir que o push continue
  exit 0
)

# Verificação mais rigorosa de tipos
npx tsc --noEmit --skipLibCheck
```

### Prevent-main-commit

Protege branches importantes, impedindo commits diretos:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "main" ] || [ "$branch" = "develop" ]; then
  echo "❌ Você não pode fazer commit diretamente na branch $branch"
  exit 1
fi
```

## Configuração do lint-staged

O `lint-staged` é utilizado para executar linters apenas nos arquivos modificados, otimizando o processo:

```json
{
    "lint-staged": {
        "*.{ts,js}": ["eslint --fix", "prettier --write"],
        "*.{json,md}": ["prettier --write"],
        "*.prisma": ["npx prisma format"]
    }
}
```

## Regras de Commits

O projeto utiliza o padrão de Conventional Commits para normalizar as mensagens de commit, configurado em `commitlint.config.ts`:

```typescript
import type { UserConfig } from '@commitlint/types';
import { RuleConfigSeverity } from '@commitlint/types';

const Configuration: UserConfig = {
    extends: ['@commitlint/config-conventional'],
    parserPreset: 'conventional-changelog-atom',
    formatter: '@commitlint/format',
};

export default Configuration;
```

### Padrão de Mensagens

As mensagens de commit devem seguir o formato:

```
tipo(escopo opcional): descrição

corpo opcional
rodapé opcional
```

### Tipos Permitidos

- **feat**: Nova funcionalidade
- **fix**: Correção de bug
- **docs**: Alterações na documentação
- **style**: Mudanças que não afetam o significado do código
- **refactor**: Alteração de código que não corrige um bug nem adiciona um recurso
- **perf**: Alteração de código que melhora o desempenho
- **test**: Adição ou correção de testes
- **build**: Alterações que afetam o sistema de build ou dependências
- **ci**: Alterações nos arquivos de configuração de CI/CD
- **chore**: Outras alterações que não modificam arquivos de código-fonte

## Instalação e Configuração

1. As configurações do Husky são inicializadas automaticamente através do script `prepare`:

```json
"prepare": "husky"
```

2. Para ativar manualmente, execute:

```bash
npm run prepare
```

3. Certifique-se de que os arquivos de hook têm permissão de execução:

```bash
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg
chmod +x .husky/pre-push
chmod +x .husky/prevent-main-commit
```

## Integração com CI/CD

Estas verificações locais são complementadas por validações similares na pipeline de CI/CD (GitHub Actions), garantindo a consistência das verificações em todos os ambientes.

## Benefícios

- Padronização do histórico de commits
- Prevenção de código problemático no repositório
- Detecção precoce de vulnerabilidades de segurança
- Proteção contra commits em branches sensíveis
- Garantia de qualidade de código consistente
- Melhoria na geração automática de changelogs
- Estruturação adequada para versionamento semântico

## Dicas para Desenvolvedores

1. Para ignorar temporariamente as verificações (use apenas em situações excepcionais):

    ```bash
    git commit --no-verify -m "mensagem"
    ```

2. Para resolver vulnerabilidades detectadas:

    ```bash
    npm audit fix
    ```

3. Para testar as validações sem fazer commit:
    ```bash
    npx lint-staged
    ```

A implementação destas ferramentas garante um fluxo de trabalho mais organizado e facilita a manutenção do código a longo prazo, especialmente em projetos de equipe onde a consistência é crucial.
