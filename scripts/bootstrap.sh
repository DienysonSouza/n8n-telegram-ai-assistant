#!/bin/sh
set -eu

MARKER="/home/node/.n8n/.telegram-assistant-community-v1"
CREDENTIALS_FILE="/tmp/assistant-credentials.json"

cleanup() {
  rm -f "$CREDENTIALS_FILE"
}
trap cleanup EXIT INT TERM

require_env() {
  name="$1"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    echo "ERRO: configure $name no arquivo .env."
    exit 1
  fi
}

for name in \
  N8N_ENCRYPTION_KEY \
  TELEGRAM_BOT_TOKEN \
  ANTHROPIC_API_KEY \
  OWNER_CHAT_ID \
  OWNER_NAME \
  BOT_NAME \
  PG_HOST \
  PG_PORT \
  PG_DATABASE \
  PG_USER \
  PG_PASSWORD
do
  require_env "$name"
done

mkdir -p /home/node/.n8n

if [ -f "$MARKER" ]; then
  echo "Bootstrap ja concluido; mantendo workflows e credenciais existentes."
  exit 0
fi

existing_ids="$(n8n list:workflow --onlyId 2>/dev/null || true)"
if printf '%s\n' "$existing_ids" | grep -Eq '^[A-Za-z0-9_-]{8,}$'; then
  echo "Instancia n8n existente detectada; importacao automatica ignorada."
  touch "$MARKER"
  exit 0
fi

node <<'NODE'
const fs = require('fs');

const credentials = [
  {
    id: 'communityTelegram',
    name: 'Telegram Community Bot',
    type: 'telegramApi',
    data: {
      accessToken: process.env.TELEGRAM_BOT_TOKEN,
      baseUrl: 'https://api.telegram.org',
    },
  },
  {
    id: 'communityAnthropic',
    name: 'Anthropic Community',
    type: 'anthropicApi',
    data: {
      apiKey: process.env.ANTHROPIC_API_KEY,
    },
  },
  {
    id: 'communityPostgres',
    name: 'Assistant Postgres',
    type: 'postgres',
    data: {
      host: process.env.PG_HOST,
      database: process.env.PG_DATABASE,
      user: process.env.PG_USER,
      password: process.env.PG_PASSWORD,
      port: Number(process.env.PG_PORT || 5432),
      ssl: 'disable',
      allowUnauthorizedCerts: false,
      sshTunnel: false,
    },
  },
];

fs.writeFileSync('/tmp/assistant-credentials.json', JSON.stringify(credentials), {
  encoding: 'utf8',
  mode: 0o600,
});
NODE

echo "Importando credenciais locais..."
n8n import:credentials --input="$CREDENTIALS_FILE"

echo "Importando workflows comunitarios..."
n8n import:workflow --separate --input=/opt/assistant/workflows

touch "$MARKER"
echo "Bootstrap concluido. Os workflows foram importados desativados."
