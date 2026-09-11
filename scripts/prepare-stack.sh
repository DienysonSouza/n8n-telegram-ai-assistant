#!/usr/bin/env bash
# Prepara um stack do Dockge em um comando.
#
# Cria a pasta do stack, baixa o compose, gera os segredos, descobre seu chat
# ID no Telegram e grava o .env com permissao restrita. Ao terminar, o stack
# aparece no Dockge e so falta clicar em Deploy.
#
#   ./scripts/prepare-stack.sh
#   ./scripts/prepare-stack.sh --dir /opt/stacks/meu-assistente
#
# Modo nao interativo (para reinstalar ou automatizar): exporte
# TELEGRAM_BOT_TOKEN, ANTHROPIC_API_KEY, OWNER_CHAT_ID e OWNER_NAME antes de
# rodar. Os campos ja definidos no ambiente nao sao perguntados.
#
# Nenhum segredo e escrito em disco fora do .env do stack, e nenhum token
# passa pela linha de comando de outro processo.
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/stacks/assistente-telegram}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/DienysonSouza/n8n-telegram-ai-assistant/main/deploy/dockge}"
FORCE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir) STACK_DIR="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opcao desconhecida: $1" >&2; exit 2 ;;
  esac
done

for cmd in curl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERRO: $cmd nao encontrado." >&2; exit 1; }
done

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$1"
  else
    od -An -N "$1" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

# Le um valor sem ecoar na tela.
read_secret() {
  local prompt="$1" value=""
  printf '%s: ' "$prompt" >&2
  if [ -t 0 ]; then
    stty -echo 2>/dev/null || true
    read -r value
    stty echo 2>/dev/null || true
    printf '\n' >&2
  else
    read -r value
  fi
  printf '%s' "$value"
}

read_plain() {
  local prompt="$1" default="${2:-}" value=""
  if [ -n "$default" ]; then
    printf '%s [%s]: ' "$prompt" "$default" >&2
  else
    printf '%s: ' "$prompt" >&2
  fi
  read -r value
  printf '%s' "${value:-$default}"
}

# Consulta a API do Telegram sem expor o token no argv (visivel em `ps`).
telegram_get_updates() {
  local token="$1"
  curl -fsS --max-time 15 --config - <<EOF
url = "https://api.telegram.org/bot${token}/getUpdates"
EOF
}

extract_chat_id() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json,sys
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for update in reversed(payload.get("result") or []):
    for key in ("message", "edited_message", "channel_post"):
        chat = (update.get(key) or {}).get("chat") or {}
        if "id" in chat:
            print(chat["id"])
            sys.exit(0)
sys.exit(1)
'
  else
    grep -o '"chat":{"id":-\{0,1\}[0-9]\{1,\}' | tail -1 | grep -o -- '-\{0,1\}[0-9]\{1,\}$'
  fi
}

if [ -e "$STACK_DIR/.env" ] && [ "$FORCE" -ne 1 ]; then
  echo "ERRO: $STACK_DIR/.env ja existe. Use --force para sobrescrever." >&2
  echo "Sobrescrever troca a chave de criptografia e invalida as credenciais salvas." >&2
  exit 1
fi

echo "Preparando o stack em $STACK_DIR"
echo

telegram_token="${TELEGRAM_BOT_TOKEN:-}"
[ -n "$telegram_token" ] || telegram_token="$(read_secret 'Token do bot Telegram (BotFather)')"
[ -n "$telegram_token" ] || { echo "ERRO: token vazio." >&2; exit 1; }

anthropic_key="${ANTHROPIC_API_KEY:-}"
[ -n "$anthropic_key" ] || anthropic_key="$(read_secret 'Chave da Anthropic')"
[ -n "$anthropic_key" ] || { echo "ERRO: chave vazia." >&2; exit 1; }

owner_chat_id="${OWNER_CHAT_ID:-}"
if [ -z "$owner_chat_id" ]; then
  echo
  echo "Agora abra o Telegram e envie qualquer mensagem para o seu bot."
  printf 'Feito? Aperte Enter para eu descobrir seu chat ID. '
  read -r _
  if updates="$(telegram_get_updates "$telegram_token" 2>/dev/null)" \
     && owner_chat_id="$(printf '%s' "$updates" | extract_chat_id 2>/dev/null)" \
     && [ -n "$owner_chat_id" ]; then
    echo "Chat ID encontrado: $owner_chat_id"
  else
    echo "Nao consegui ler o chat ID automaticamente."
    echo "Abra https://api.telegram.org/bot<SEU_TOKEN>/getUpdates no navegador"
    echo "e copie o valor de result[].message.chat.id."
    owner_chat_id="$(read_plain 'Seu chat ID do Telegram')"
  fi
fi
[ -n "$owner_chat_id" ] || { echo "ERRO: chat ID vazio." >&2; exit 1; }

owner_name="${OWNER_NAME:-}"
[ -n "$owner_name" ] || owner_name="$(read_plain 'Seu nome')"
[ -n "$owner_name" ] || { echo "ERRO: nome vazio." >&2; exit 1; }

bot_name="${BOT_NAME:-}"
[ -n "$bot_name" ] || bot_name="$(read_plain 'Nome do assistente' 'Assistente')"

webhook_url="${WEBHOOK_URL:-}"
[ -n "$webhook_url" ] || webhook_url="$(read_plain 'URL publica HTTPS do n8n' 'http://localhost:5678/')"

if [ "$webhook_url" = "http://localhost:5678/" ]; then
  n8n_host="localhost"; n8n_protocol="http"; secure_cookie="false"
else
  n8n_host="$(printf '%s' "$webhook_url" | sed -E 's#https?://([^/]+)/?.*#\1#')"
  n8n_protocol="https"; secure_cookie="true"
fi

mkdir -p "$STACK_DIR"

# O compose sai do repositorio quando o script roda dentro dele; senao, do main.
repo_compose="$(dirname "$0")/../deploy/dockge/compose.yaml"
if [ -f "$repo_compose" ]; then
  cp "$repo_compose" "$STACK_DIR/compose.yaml"
  echo "compose.yaml copiado do repositorio."
else
  curl -fsSL "$RAW_BASE/compose.yaml" -o "$STACK_DIR/compose.yaml"
  echo "compose.yaml baixado de $RAW_BASE."
fi

umask 077
cat > "$STACK_DIR/.env" <<EOF
# Gerado por scripts/prepare-stack.sh. Contem segredos: nao versione, nao
# compartilhe e nao tire print desta tela.
TELEGRAM_BOT_TOKEN=$telegram_token
ANTHROPIC_API_KEY=$anthropic_key
OWNER_CHAT_ID=$owner_chat_id
OWNER_NAME=$owner_name
BOT_NAME=${bot_name:-Assistente}
SECONDARY_NAME=
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
N8N_LISTEN_ADDRESS=${N8N_LISTEN_ADDRESS:-::}
WEBHOOK_URL=$webhook_url
GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo
ASSISTANT_VERSION=latest
ANTHROPIC_MODEL=claude-haiku-4-5-20251001
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE_MAX_COUNT=1000
CNJ_API_KEY=
CLOUDFLARE_TUNNEL_TOKEN=
EOF
chmod 600 "$STACK_DIR/.env"
unset telegram_token anthropic_key

cat <<EOF

Stack pronto em $STACK_DIR (.env com permissao 600).

Proximos passos:
  1. abra o Dockge: o stack aparece na lista;
  2. clique em Deploy e acompanhe os logs;
  3. abra o n8n, crie o usuario local e ative apenas um workflow.

Guarde N8N_ENCRYPTION_KEY do .env em um gerenciador de senhas: sem ela um
backup do n8n nao volta a ler as credenciais salvas.
EOF
