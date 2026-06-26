# 📥 Instalação

## Pré-requisitos
- [Docker](https://docs.docker.com/get-docker/) e Docker Compose
- Uma conta na [Anthropic](https://console.anthropic.com) (chave de API)
- Um bot do Telegram (criado no BotFather)

## Passo a passo

### 1. Clonar e configurar
```bash
git clone <este-repo>
cd n8n-telegram-ai-assistant
cp .env.example .env
```

### 2. Criar o bot no Telegram
1. Fale com o [@BotFather](https://t.me/BotFather) → `/newbot` → escolha nome e usuário.
2. Copie o **token** → cole em `TELEGRAM_BOT_TOKEN` no `.env`.
3. Descubra seu **chat id** com o [@userinfobot](https://t.me/userinfobot) → cole em `OWNER_CHAT_ID`.

### 3. Preencher o `.env`
- `ANTHROPIC_API_KEY` — sua chave da Anthropic.
- `PG_PASSWORD` — uma senha forte para o banco.
- `N8N_ENCRYPTION_KEY` — gere com `openssl rand -hex 24` e **guarde em lugar seguro**
  (sem ela, as credenciais salvas no n8n ficam ilegíveis após reiniciar).
- `OWNER_NAME` / `BOT_NAME` — seu nome e o nome do assistente.

### 4. Subir
```bash
docker compose up -d
```
O Postgres já aplica o `db/schema.sql` na primeira subida. Acompanhe com `docker compose logs -f`.

### 5. Configurar o n8n
1. Abra `http://localhost:5678` e crie sua conta local.
2. **Credenciais** (menu Credentials), crie:
   - **Telegram API** → seu token.
   - **Anthropic** → sua chave.
   - **Postgres** → host `postgres`, os dados do `.env`.
3. **Importar workflows**: Workflows → *Import from File* → selecione cada `.json` de [`../workflows/`](../workflows/).
4. Em cada workflow, ligue as credenciais que você criou e **ative**.

### 6. Testar
Mande uma mensagem para o seu bot no Telegram. Ele deve responder. 🎉

## Atualizar
```bash
git pull
docker compose pull && docker compose up -d
```

## Backup
- Banco: `docker compose exec postgres pg_dump -U "$PG_USER" "$PG_DATABASE" > backup.sql`
- n8n (credenciais/workflows): faça backup do volume `n8n_data` e **guarde a `N8N_ENCRYPTION_KEY`**.
