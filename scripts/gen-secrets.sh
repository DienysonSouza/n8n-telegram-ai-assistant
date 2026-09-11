#!/usr/bin/env bash
# Gera os segredos que o stack precisa e imprime na tela.
#
# Nao escreve arquivo nenhum: copie as linhas para o campo de ambiente do
# Dockge (ou para o seu .env) e limpe o terminal depois.
#
#   ./scripts/gen-secrets.sh
set -euo pipefail

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$1"
  else
    od -An -N "$1" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

cat <<EOF
PG_PASSWORD=$(random_hex 24)
N8N_ENCRYPTION_KEY=$(random_hex 32)
EOF

cat >&2 <<'EOF'

Guarde N8N_ENCRYPTION_KEY em um gerenciador de senhas: sem ela as credenciais
salvas no n8n nao podem ser lidas de volta a partir de um backup.
Trocar PG_PASSWORD depois do primeiro boot exige ajustar tambem a credencial
"Assistant Postgres" dentro do n8n.
EOF
