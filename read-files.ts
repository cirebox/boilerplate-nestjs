import * as fs from 'fs';
import * as path from 'path';

const srcPath = path.join(__dirname, 'src');
const outputFile = path.join(__dirname, 'all_ts_files_content.txt');

// Função para buscar todos os arquivos .ts de forma recursiva
function getTsFilesRecursively(dir: string): string[] {
  let results: string[] = [];
  const list = fs.readdirSync(dir);

  list.forEach((file) => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat && stat.isDirectory()) {
      results = results.concat(getTsFilesRecursively(filePath));
    } else if (file.endsWith('.ts')) {
      results.push(filePath);
    }
  });

  return results;
}

// Função para ler e salvar o conteúdo dos arquivos em um arquivo txt
function readAndSaveFiles() {
  const files = getTsFilesRecursively(srcPath);
  let allContent = '';

  files.forEach((filePath) => {
    const content = fs.readFileSync(filePath, 'utf8');
    allContent += `// File: ${filePath}\n${content}\n\n`;
  });

  fs.writeFileSync(outputFile, allContent, 'utf8');
  console.log(`All TypeScript files content saved to ${outputFile}`);
}

readAndSaveFiles();
