import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, '..');
const workflowsDir = path.join(rootDir, 'workflows');

const credentialByNodeType = {
  'n8n-nodes-base.telegram': {
    telegramApi: { id: 'communityTelegram', name: 'Telegram Community Bot' },
  },
  'n8n-nodes-base.telegramTrigger': {
    telegramApi: { id: 'communityTelegram', name: 'Telegram Community Bot' },
  },
  '@n8n/n8n-nodes-langchain.lmChatAnthropic': {
    anthropicApi: { id: 'communityAnthropic', name: 'Anthropic Community' },
  },
  '@n8n/n8n-nodes-langchain.memoryPostgresChat': {
    postgres: { id: 'communityPostgres', name: 'Assistant Postgres' },
  },
  'n8n-nodes-base.postgres': {
    postgres: { id: 'communityPostgres', name: 'Assistant Postgres' },
  },
};

const workflowConfig = {
  'assistente-pessoal.json': {
    id: 'communityPersonal',
    name: 'AI Assistant Community',
  },
  'assistente-pessoal-pro.json': {
    id: 'communityPro',
    name: 'AI Assistant Community Pro',
  },
};

function sanitizeString(value) {
  return value
    .replace(
      /\{\{ \$env\.OWNER_NAME \}\} é [^\n]*/g,
      '{{ $env.OWNER_NAME }} pode personalizar profissão, rotina e preferências no prompt.',
    )
    .replace(
      /const FINAIS = \{[^}]*\};/g,
      'const FINAIS = {};',
    )
    .replace(
      /Defina como variavel de ambiente do n8n ou, temporariamente, em Variables > BOT_PGPASSWORD\./g,
      'Defina BOT_PGPASSWORD como variavel de ambiente do n8n.',
    )
    .replace(
      /Defina como variável de ambiente do n8n ou, temporariamente, em Variables > BOT_PGPASSWORD\./g,
      'Defina BOT_PGPASSWORD como variavel de ambiente do n8n.',
    );
}

function sanitizeValue(value) {
  if (typeof value === 'string') return sanitizeString(value);
  if (Array.isArray(value)) return value.map(sanitizeValue);
  if (!value || typeof value !== 'object') return value;

  for (const [key, child] of Object.entries(value)) {
    value[key] = sanitizeValue(child);
  }
  return value;
}

for (const [fileName, config] of Object.entries(workflowConfig)) {
  const filePath = path.join(workflowsDir, fileName);
  const workflow = sanitizeValue(JSON.parse(fs.readFileSync(filePath, 'utf8')));

  workflow.id = config.id;
  workflow.name = config.name;
  workflow.active = false;

  delete workflow.versionId;
  delete workflow.createdAt;
  delete workflow.updatedAt;
  delete workflow.meta;
  delete workflow.shared;
  delete workflow.tags;
  delete workflow.pinData;
  delete workflow.staticData;

  workflow.settings ??= {};
  if (workflow.settings.errorWorkflow === 'ERROR_WORKFLOW_ID') {
    delete workflow.settings.errorWorkflow;
  }

  for (const node of workflow.nodes ?? []) {
    if (credentialByNodeType[node.type]) {
      node.credentials = credentialByNodeType[node.type];
    }
    if (node.type === 'n8n-nodes-base.telegramTrigger') {
      delete node.webhookId;
    }
  }

  fs.writeFileSync(filePath, `${JSON.stringify(workflow, null, 2)}\n`);
  console.log(`Preparado: ${fileName}`);
}
