# Instalacao e operacao

## Requisitos

- Docker Engine ou Docker Desktop com Compose v2;
- bot criado no BotFather;
- chave da Anthropic;
- HTTPS publico para ativar o Telegram Trigger.

## Interface web (Dockge)

Se voce administra a VPS pelo Dockge, use
[dockge.md](dockge.md): stack pronto para colar, ambiente sem segredos
versionados e operacao pela interface.

## Instalacao assistida

Use `install.sh` em Linux/macOS ou `install.ps1` no Windows. O instalador cria
o `.env`, gera segredos fortes e sobe os containers.

Depois do primeiro boot:

1. abra o n8n;
2. crie o usuario local;
3. escolha o workflow pessoal ou Pro;
4. ative somente um;
5. envie uma mensagem curta.

## Instalacao manual

```bash
cp .env.example .env
```

Preencha:

- `TELEGRAM_BOT_TOKEN`;
- `ANTHROPIC_API_KEY`;
- `OWNER_CHAT_ID`;
- `OWNER_NAME`;
- `BOT_NAME`;
- `PG_PASSWORD`;
- `N8N_ENCRYPTION_KEY`.

Depois:

```bash
docker compose up -d
docker compose ps
docker compose logs -f n8n-import n8n
```

O `n8n-import` deve terminar com codigo zero. Ele nao fica em execucao.

## HTTPS e Telegram

Para um dominio como `bot.example.com`:

```env
N8N_HOST=bot.example.com
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
WEBHOOK_URL=https://bot.example.com/
```

Configure a rota HTTPS para `http://n8n:5678`. O perfil `tunnel` do Compose
pode executar um Cloudflare Tunnel ja criado:

```env
CLOUDFLARE_TUNNEL_TOKEN=token-do-seu-tunnel
```

```bash
docker compose --profile tunnel up -d
```

## Escolha do workflow

- `AI Assistant Community`: financeiro, tarefas, notas e lembretes.
- `AI Assistant Community Pro`: adiciona rotinas juridicas e fitness.

Nao ative os dois com o mesmo token, pois ambos receberiam a mesma atualizacao.

## Backup

### PostgreSQL

```bash
docker compose exec -T postgres \
  pg_dump -U assistant -d assistant -Fc > assistant.dump
```

### n8n

Pare o n8n por alguns minutos e copie o volume `n8n_data`, ou use o comando
SQLite `.backup` dentro de um procedimento consistente. Guarde o `.env` em
local protegido.

Um backup deve ser restaurado em ambiente isolado antes de ser considerado
valido.

## Atualizacao

```bash
docker compose pull
docker compose up -d
```

Em producao, use uma tag de versao em `ASSISTANT_VERSION` e faca backup antes.

## Diagnostico

### O importador falhou

```bash
docker compose logs n8n-import
```

Confira campos obrigatorios do `.env`, saude do PostgreSQL e permissao do
volume `n8n_data`.

### O workflow nao aparece

```bash
docker compose run --rm n8n-import
```

Se a instancia ja tinha workflows, o bootstrap nao importa automaticamente
para evitar sobrescrever uma instalacao existente.

### Telegram nao ativa

Confirme que `WEBHOOK_URL` e HTTPS publico, que o dominio chega ao n8n e que
somente um workflow usa o token.

### Banco nao conecta

Confirme `PG_HOST=postgres`, usuario, banco e senha. As credenciais sao criadas
somente no primeiro bootstrap; alteracoes posteriores devem ser feitas no n8n
ou em um volume novo de teste.

## Segredos

Os arquivos versionados (`.env.example`, `deploy/dockge/.env.example`) chegam
com os campos sensiveis vazios e o `.gitignore` bloqueia `.env` e `*.env`.

- mantenha o `.env` com `chmod 600` e fora de backups publicos;
- guarde `N8N_ENCRYPTION_KEY` em um gerenciador de senhas: sem ela um backup
  do n8n nao volta a ler as credenciais salvas;
- ao pedir ajuda, apague tokens de logs e prints antes de enviar;
- se vazar, revogue o token no BotFather (`/revoke`) e gere outra chave da
  Anthropic, atualize o `.env` e suba os containers de novo.

## Remocao

Parar containers preservando dados:

```bash
docker compose down
```

O comando `docker compose down -v` apaga os dados e deve ser usado somente em
uma instalacao descartavel.
