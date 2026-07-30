# n8n Telegram AI Assistant

Assistente pessoal self-hosted para Telegram, baseado em n8n, Anthropic e
PostgreSQL. A imagem comunitaria prepara o banco, cria as credenciais locais e
importa os workflows automaticamente.

[![Publicar imagem](https://github.com/DienysonSouza/n8n-telegram-ai-assistant/actions/workflows/container.yml/badge.svg)](https://github.com/DienysonSouza/n8n-telegram-ai-assistant/actions/workflows/container.yml)
[![Validar instalacao](https://github.com/DienysonSouza/n8n-telegram-ai-assistant/actions/workflows/validate.yml/badge.svg)](https://github.com/DienysonSouza/n8n-telegram-ai-assistant/actions/workflows/validate.yml)

## O que vem pronto

- n8n 2.26.3 com dois templates: pessoal e Pro;
- PostgreSQL 15 com o schema completo;
- credenciais de Telegram, Anthropic e PostgreSQL criadas no primeiro boot;
- workflows importados e vinculados as credenciais;
- retencao de execucoes e rotacao de logs;
- financeiro, tarefas, notas, lembretes e humor;
- modulos opcionais juridico e fitness;
- imagem para `amd64` e `arm64`;
- nenhuma senha, token ou dado pessoal embutido.

## Instalacao simples

### Linux ou macOS

```bash
git clone https://github.com/DienysonSouza/n8n-telegram-ai-assistant.git
cd n8n-telegram-ai-assistant
chmod +x install.sh
./install.sh
```

### Windows PowerShell

```powershell
git clone https://github.com/DienysonSouza/n8n-telegram-ai-assistant.git
cd n8n-telegram-ai-assistant
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

O instalador pede somente:

1. token do bot criado no BotFather;
2. chave da Anthropic;
3. chat ID do proprietario;
4. nome do proprietario e do bot;
5. URL publica do n8n, quando houver.

As senhas do PostgreSQL e a chave de criptografia do n8n sao geradas
automaticamente.

## Usar diretamente a imagem

```bash
docker pull ghcr.io/dienysonsouza/n8n-telegram-ai-assistant:latest
```

A imagem contem n8n, workflows e bootstrap. O `docker-compose.yml` adiciona o
PostgreSQL e os volumes persistentes:

```bash
cp .env.example .env
# preencha os campos obrigatorios
docker compose up -d
```

## Primeiro acesso

1. Abra a URL configurada e crie o usuario local do n8n.
2. Confira os workflows `AI Assistant Community` e
   `AI Assistant Community Pro`.
3. Ative somente a edicao que deseja usar.
4. Envie uma mensagem de teste no Telegram.

Os workflows ficam desativados por padrao para impedir que os dois respondam ao
mesmo bot.

## URL publica do Telegram

O Telegram Trigger precisa de HTTPS publico. Em uma VPS, configure
`WEBHOOK_URL`, `N8N_HOST`, `N8N_PROTOCOL=https` e um proxy ou tunnel.

O Compose inclui um perfil opcional para Cloudflare Tunnel:

```bash
# preencha CLOUDFLARE_TUNNEL_TOKEN e a URL publica no .env
docker compose --profile tunnel up -d
```

Cloudflare Tunnel e opcional e usa a conta do proprio instalador.

## Como o bootstrap funciona

```text
imagem comunitaria
  -> entrega schema ao PostgreSQL
  -> espera o banco ficar saudavel
  -> cria credenciais cifradas no n8n
  -> importa os dois workflows
  -> grava um marcador no volume
  -> inicia o n8n
```

O processo e idempotente. Reiniciar os containers nao duplica workflows nem
sobrescreve credenciais.

## Atualizar

```bash
docker compose pull
docker compose up -d
```

Fixe `ASSISTANT_VERSION` em uma tag `vX.Y.Z` para ambientes que exigem
atualizacoes controladas.

## Dados e backup

Os dados ficam nos volumes `n8n_data` e `pgdata`. Guarde tambem o `.env`,
principalmente `N8N_ENCRYPTION_KEY`.

Veja [docs/instalacao.md](docs/instalacao.md) para HTTPS, backup,
troubleshooting e atualizacao.

## Desenvolvimento

Depois de editar um workflow:

```bash
node scripts/prepare-workflows.mjs
```

O script remove referencias pessoais, mantem os workflows desativados e aplica
os IDs das credenciais comunitarias. A validacao de pull request constroi a
imagem e faz uma instalacao completa descartavel.

## Licenca

[MIT](LICENSE)
