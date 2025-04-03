#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { promisify } from 'util';
import { exec } from 'child_process';

const execAsync = promisify(exec);

// Cria interface para leitura das entradas do usuário
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// Função para fazer perguntas ao usuário e obter respostas
const question = (query) =>
  new Promise((resolve) => rl.question(query, resolve));

// Função para verificar se um diretório existe
const directoryExists = (dirPath) => {
  try {
    return fs.statSync(dirPath).isDirectory();
  } catch {
    return false;
  }
};

// Função para substituir texto em arquivos
const replaceInFile = async (filePath, searchValues, replacements) => {
  try {
    if (!fs.existsSync(filePath)) {
      console.log(`Arquivo não encontrado: ${filePath}`);
      return;
    }

    let content = fs.readFileSync(filePath, 'utf8');

    // Verificar e atualizar especificamente arquivos de configuração do Swagger
    const isSwaggerFile =
      filePath.includes('swagger') ||
      filePath.includes('openapi') ||
      content.includes('SwaggerModule') ||
      content.includes('@nestjs/swagger');

    for (let i = 0; i < searchValues.length; i++) {
      // Para arquivos relacionados ao Swagger e padrões de Swagger, usar regex com flag 's' para considerar quebras de linha
      const regexFlags = isSwaggerFile && i >= 8 ? 'gs' : 'g';
      const regex = new RegExp(searchValues[i], regexFlags);
      content = content.replace(regex, replacements[i]);
    }

    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`✅ Arquivo atualizado: ${filePath}`);
  } catch (error) {
    console.error(`❌ Erro ao processar o arquivo ${filePath}:`, error);
  }
};

// Função para processar recursivamente diretórios
const processDirectory = async (
  dirPath,
  searchValues,
  replacements,
  ignorePatterns,
) => {
  try {
    const files = fs.readdirSync(dirPath);

    for (const file of files) {
      const fullPath = path.join(dirPath, file);

      // Verificar se o caminho deve ser ignorado
      if (ignorePatterns.some((pattern) => fullPath.includes(pattern))) {
        continue;
      }

      if (fs.statSync(fullPath).isDirectory()) {
        await processDirectory(
          fullPath,
          searchValues,
          replacements,
          ignorePatterns,
        );
      } else {
        // Verifica se é um arquivo de texto antes de processar
        const ext = path.extname(file).toLowerCase();
        const textFileExts = [
          '.ts',
          '.js',
          '.json',
          '.md',
          '.yml',
          '.yaml',
          '.env',
          '.example',
          '.gitignore',
          '.dockerignore',
          '.editorconfig',
          '.prettierrc',
          '.eslintrc',
          '.txt',
          '.html',
          '.css',
          '.sh',
          '.prisma',
        ];

        // Dar prioridade aos arquivos de configuração do Swagger
        const isSwaggerRelated =
          file.toLowerCase().includes('swagger') ||
          file.toLowerCase().includes('openapi') ||
          fullPath.includes('main.ts');

        if (textFileExts.includes(ext) || !ext) {
          if (isSwaggerRelated) {
            console.log(
              `🔍 Processando arquivo relacionado ao Swagger: ${fullPath}`,
            );
          }
          await replaceInFile(fullPath, searchValues, replacements);
        }
      }
    }
  } catch (error) {
    console.error(`❌ Erro ao processar o diretório ${dirPath}:`, error);
  }
};

// Função principal
const main = async () => {
  console.log(
    '\n🚀 Assistente de customização do Boilerplate NestJS para Microsserviços\n',
  );

  // Pergunta ao usuário as informações do novo projeto
  const currentDir = process.cwd();
  let targetDir;

  // Define o nome do projeto e diretório de destino
  const projectName = await question('📝 Nome do projeto: ');

  // Valida e normaliza o nome do projeto para uso em pacotes npm
  const npmProjectName = projectName
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '');

  // Perguntar se deseja criar um novo diretório
  const createNewDir =
    (
      await question('📁 Criar um novo diretório para o projeto? (S/n): ')
    ).toLowerCase() !== 'n';

  if (createNewDir) {
    targetDir = path.join(currentDir, npmProjectName);

    // Verificar se o diretório já existe
    if (directoryExists(targetDir)) {
      const overwrite =
        (
          await question(
            `⚠️ O diretório ${npmProjectName} já existe. Deseja continuar e sobrescrever? (s/N): `,
          )
        ).toLowerCase() === 's';

      if (!overwrite) {
        console.log('❌ Operação cancelada pelo usuário.');
        rl.close();
        return;
      }
    } else {
      // Criar o novo diretório
      fs.mkdirSync(targetDir, { recursive: true });
    }

    console.log(`📁 Configurando projeto no diretório: ${targetDir}`);
  } else {
    targetDir = currentDir;
    console.log(`📁 Configurando projeto no diretório atual: ${targetDir}`);
  }

  // Coletar outras informações
  const description = await question('📝 Descrição do projeto: ');
  const version = (await question('📝 Versão (1.0.0): ')) || '1.0.0';
  const author = await question('📝 Autor: ');
  const authorEmail = await question('📝 Email do autor: ');
  await question('📝 Licença (MIT): '); // Coletamos mas não usamos, para compatibilidade com npm init
  const repositoryUrl = await question('📝 URL do repositório: ');

  console.log('\n📋 Configuração de microsserviço:');
  const serviceName = await question(
    '📝 Nome do microsserviço (ex: user-service): ',
  );
  const servicePort =
    (await question('📝 Porta do serviço (3000): ')) || '3000';

  // Definir valores de substituição
  const searchValues = [
    'nestjs-boilerplate', // Nome do projeto original
    'NestJS Boilerplate', // Título do projeto original
    'Boilerplate para aplicações NestJS', // Descrição original
    'autor@original.com', // Autor original
    '0.0.1', // Versão original
    'https://github.com/autor/nestjs-boilerplate', // Repositório original
    'microservice-name', // Nome do serviço original
    '3000', // Porta original

    // Valores específicos de documentação Swagger
    '"title": "NestJS Boilerplate API"',
    '"description": "API Documentation for NestJS Boilerplate"',
    '"version": "0.0.1"',
    '"contact": {\\s*"name": "API Support",\\s*"email": "support@example.com"\\s*}',
    '"termsOfService": "http://swagger.io/terms/"',
  ];

  const replacements = [
    npmProjectName,
    projectName,
    description,
    authorEmail || author,
    version,
    repositoryUrl ||
      `https://github.com/${author.replace(/\s+/g, '')}/${npmProjectName}`,
    serviceName,
    servicePort,

    // Substituições para documentação Swagger
    `"title": "${projectName} API"`,
    `"description": "API Documentation for ${projectName}"`,
    `"version": "${version}"`,
    `"contact": {\n      "name": "${author}",\n      "email": "${authorEmail || 'contact@example.com'}"\n    }`,
    repositoryUrl
      ? `"termsOfService": "${repositoryUrl}"`
      : `"termsOfService": "http://swagger.io/terms/"`,
  ];

  // Padrões para ignorar durante o processamento
  const ignorePatterns = [
    'node_modules',
    '.git',
    'dist',
    'coverage',
    '.next',
    '.nuxt',
    'build',
    '.cache',
  ];

  console.log('\n🔄 Processando arquivos de template...');

  // Verificar se estamos trabalhando com um repositório já clonado ou precisamos clonar o boilerplate
  const hasPackageJson = fs.existsSync(path.join(targetDir, 'package.json'));

  if (!hasPackageJson) {
    console.log(
      '📦 Repositório de boilerplate não encontrado. Deseja clonar o repositório padrão?',
    );
    const cloneRepo =
      (
        await question('Clonar o repositório boilerplate? (S/n): ')
      ).toLowerCase() !== 'n';

    if (cloneRepo) {
      console.log('🔄 Clonando repositório boilerplate...');
      try {
        const repoUrl = 'https://github.com/seu-usuario/nestjs-boilerplate.git'; // Substitua pelo URL real do seu boilerplate
        await execAsync(`git clone ${repoUrl} "${targetDir}" --depth=1`);

        // Remover diretório .git para começar um novo histórico
        fs.rmSync(path.join(targetDir, '.git'), {
          recursive: true,
          force: true,
        });

        console.log('✅ Repositório clonado com sucesso!');
      } catch (error) {
        console.error('❌ Erro ao clonar repositório:', error);
        rl.close();
        return;
      }
    } else {
      console.log(
        '❌ Operação cancelada. É necessário ter os arquivos do boilerplate.',
      );
      rl.close();
      return;
    }
  }

  // Processar o diretório
  await processDirectory(targetDir, searchValues, replacements, ignorePatterns);

  console.log('\n✅ Customização concluída com sucesso!');

  // Atualizar especificamente arquivos do Swagger
  console.log(
    '\n🔄 Verificando e atualizando configurações específicas do Swagger...',
  );

  // Procurar pelo arquivo main.ts e outros arquivos de configuração do Swagger
  const mainTsPath = path.join(targetDir, 'src', 'main.ts');
  const swaggerConfigPath = path.join(
    targetDir,
    'src',
    'core',
    'swagger',
    'index.ts',
  );

  if (fs.existsSync(mainTsPath)) {
    console.log(
      '🔍 Verificando arquivo main.ts para configurações do Swagger...',
    );

    // Leitura do arquivo main.ts
    let mainTsContent = fs.readFileSync(mainTsPath, 'utf8');

    // Verificar se tem configuração do Swagger e atualizar título e descrição
    if (mainTsContent.includes('SwaggerModule')) {
      console.log('🔧 Atualizando configurações do Swagger em main.ts...');

      // Substituições específicas para o Swagger no main.ts
      mainTsContent = mainTsContent.replace(
        /SwaggerModule\.setup\([^)]*\)/g,
        `SwaggerModule.setup('api/docs', app, document)`,
      );

      fs.writeFileSync(mainTsPath, mainTsContent, 'utf8');
    }
  }

  if (fs.existsSync(swaggerConfigPath)) {
    console.log('🔍 Verificando arquivo de configuração do Swagger...');

    // Processar arquivo de configuração do Swagger
    let swaggerContent = fs.readFileSync(swaggerConfigPath, 'utf8');

    // Garantir que as informações do Swagger estejam atualizadas
    if (
      swaggerContent.includes('SwaggerConfig') ||
      swaggerContent.includes('SwaggerOptions')
    ) {
      console.log('🔧 Atualizando arquivo de configuração do Swagger...');

      // Substituições específicas para arquivo de configuração do Swagger
      swaggerContent = swaggerContent
        .replace(/title:[^,]+/g, `title: '${projectName} API'`)
        .replace(
          /description:[^,]+/g,
          `description: 'API Documentation for ${projectName}'`,
        )
        .replace(/version:[^,]+/g, `version: '${version}'`);

      fs.writeFileSync(swaggerConfigPath, swaggerContent, 'utf8');
    }
  }

  console.log(`\n💡 Próximos passos:`);
  console.log(
    `1. Navegue para o diretório do projeto: cd ${createNewDir ? npmProjectName : ''}`,
  );
  console.log(`2. Instale as dependências: npm install`);
  console.log(`3. Execute o projeto: npm run start:dev`);
  console.log(
    `4. Acesse a documentação Swagger em: http://localhost:${servicePort}/api/docs`,
  );

  rl.close();
};

// Iniciar o script
main().catch((error) => {
  console.error('❌ Erro ao executar o script:', error);
  process.exit(1);
});

