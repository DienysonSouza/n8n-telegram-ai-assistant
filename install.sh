#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker nao encontrado. Instale Docker e execute novamente."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose nao encontrado."
  exit 1
fi

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$1"
  else
    od -An -N "$1" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

if [ ! -f .env ]; then
  printf "Token do bot Telegram: "
  read -r -s telegram_token
  printf "\nChave da Anthropic: "
  read -r -s anthropic_key
  printf "\nSeu chat ID do Telegram: "
  read -r owner_chat_id
  printf "Seu nome: "
  read -r owner_name
  printf "Nome do assistente [Assistente]: "
  read -r bot_name
  bot_name="${bot_name:-Assistente}"
  printf "URL publica HTTPS do n8n [http://localhost:5678/]: "
  read -r webhook_url
  webhook_url="${webhook_url:-http://localhost:5678/}"

  if [ "$webhook_url" = "http://localhost:5678/" ]; then
    n8n_host="localhost"
    n8n_protocol="http"
    secure_cookie="false"
  else
    n8n_host="$(printf '%s' "$webhook_url" | sed -E 's#https?://([^/]+)/?.*#\1#')"
    n8n_protocol="https"
    secure_cookie="true"
  fi

  umask 077
  cat > .env <<EOF
TELEGRAM_BOT_TOKEN=$telegram_token
ANTHROPIC_API_KEY=$anthropic_key
OWNER_CHAT_ID=$owner_chat_id
OWNER_NAME=$owner_name
BOT_NAME=$bot_name
PG_PASSWORD=$(random_hex 24)
N8N_ENCRYPTION_KEY=$(random_hex 32)
PG_HOST=postgres
PG_PORT=5432
PG_DATABASE=assistant
PG_USER=assistant
N8N_PORT=5678
N8N_HOST=$n8n_host
N8N_PROTOCOL=$n8n_protocol
N8N_SECURE_COOKIE=$secure_cookie
WEBHOOK_URL=$webhook_url
GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo
ASSISTANT_VERSION=latest
ANTHROPIC_MODEL=claude-haiku-4-5-20251001
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE_MAX_COUNT=1000
SECONDARY_NAME=
CNJ_API_KEY=
CLOUDFLARE_TUNNEL_TOKEN=
EOF

  unset telegram_token anthropic_key
  echo "Arquivo .env criado com permissoes restritas."
else
  echo "Usando o .env existente."
fi

docker compose pull
docker compose up -d

echo
echo "Instalacao iniciada."
echo "Abra o n8n na URL configurada, crie o usuario local e ative apenas o workflow escolhido."
echo "O Telegram exige uma URL publica HTTPS para ativar o trigger."
