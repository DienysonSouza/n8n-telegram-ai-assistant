#!/usr/bin/env bash
# Garante que deploy/dockge/compose.yaml continua equivalente ao
# docker-compose.yml da raiz.
#
# O arquivo do Dockge e uma copia plana (sem ancoras YAML e sem profiles), o
# que abre espaco para os dois divergirem em silencio. Este script resolve as
# duas configuracoes com o proprio Docker Compose e compara servico a servico.
#
# Requer um .env preenchido no diretorio atual.
set -euo pipefail

ROOT_FILE="docker-compose.yml"
DOCKGE_FILE="deploy/dockge/compose.yaml"
FIELDS='{image, environment, command, entrypoint, volumes, user, depends_on, healthcheck, restart, ports}'

resolve() {
  docker compose --env-file .env -f "$1" config --format json
}

root_json="$(resolve "$ROOT_FILE")"
dockge_json="$(resolve "$DOCKGE_FILE")"

status=0
for service in assets postgres n8n-import n8n; do
  a="$(printf '%s' "$root_json" | jq -S ".services[\"$service\"] | $FIELDS")"
  b="$(printf '%s' "$dockge_json" | jq -S ".services[\"$service\"] | $FIELDS")"
  if [ "$a" = "$b" ]; then
    echo "ok: $service"
  else
    echo "divergente: $service"
    diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") || true
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo
  echo "Atualize $DOCKGE_FILE para refletir $ROOT_FILE."
fi

exit "$status"
