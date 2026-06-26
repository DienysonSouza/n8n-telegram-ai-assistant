# 🤖 n8n Telegram AI Assistant

> Um assistente pessoal de Telegram, self-hosted no [n8n](https://n8n.io), com IA (Anthropic Claude) e banco Postgres. Controle de **gastos**, **tarefas**, **notas**, **lembretes** e módulos opcional **fitness** — tudo por mensagem de texto.

![n8n](https://img.shields.io/badge/n8n-workflow-EA4B71?logo=n8n&logoColor=white)
![Telegram](https://img.shields.io/badge/Telegram-Bot-26A5E4?logo=telegram&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-compose-2496ED?logo=docker&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

---

## ✨ Funcionalidades

- 💬 **Conversa natural no Telegram** — fale como quiser ("ifood 45 no crédito"), a IA entende e registra.
- 💰 **Financeiro** — gastos, gastos fixos, faturas de cartão, orçamentos e relatórios.
- ✅ **Tarefas & lembretes** — criar, concluir, adiar, recorrências e alertas no horário.
- 📝 **Notas** e 🙂 **registro de humor**.
- ⏰ **Rotinas agendadas** — resumo diário, relatório semanal, lembretes automáticos.
- 🧩 **Módulos opcionais** — `jurídico` (prazos/processos/honorários) e `fitness` (treinos/dieta).

## 🏗️ Arquitetura

```
Telegram  ──▶  n8n (workflow + AI Agent Claude)  ──▶  Postgres
                         │
                         └── rotinas agendadas (cron) ──▶ Telegram
```

Tudo roda em containers Docker: **n8n** (orquestração + IA) e **Postgres** (dados). Você sobe com um `docker compose up` e importa os workflows.

## 🚀 Início rápido

```bash
# 1. clone
git clone <este-repo> && cd n8n-telegram-ai-assistant

# 2. configure (copie e preencha com os SEUS valores)
cp .env.example .env
#   edite o .env: token do bot, chat id, senha do banco, chave da IA...

# 3. suba
docker compose up -d

# 4. abra o n8n em http://localhost:5678 e importe os workflows (pasta workflows/)
```

> Cada pessoa roda **a própria instância**, com **os próprios dados e credenciais**. Nada pessoal vem embutido neste repositório.

## ⚙️ Configuração

Todas as configurações ficam no arquivo `.env` (veja `.env.example`). As principais:

| Variável | O que é |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Token do seu bot (BotFather) |
| `OWNER_CHAT_ID` | Seu chat id no Telegram (só você comanda o bot) |
| `ANTHROPIC_API_KEY` | Chave da API da Anthropic (a IA) |
| `PG_*` | Conexão do Postgres |
| `OWNER_NAME` / `BOT_NAME` | Seu nome e o nome do bot |
| `N8N_ENCRYPTION_KEY` | Chave que cifra as credenciais do n8n — **gere e guarde** |

## 🤖 Criar o bot no Telegram

1. No Telegram, fale com o [@BotFather](https://t.me/BotFather) → `/newbot` → copie o **token** para `TELEGRAM_BOT_TOKEN`.
2. Descubra seu **chat id** com o [@userinfobot](https://t.me/userinfobot) → coloque em `OWNER_CHAT_ID`.

## 📦 Importar os workflows

Os workflows ficam em [`workflows/`](workflows/). No n8n: **Workflows → Import from File** e selecione cada `.json`. Depois conecte as **credenciais** (Telegram, Anthropic, Postgres) na UI — elas **não** vêm preenchidas (é assim que mantemos o repo sem segredos).

## 🧩 Módulos opcionais

Ative pelo `.env`:
- `ENABLE_JURIDICO=true` — prazos processuais, honorários, monitor de publicações (CNJ).
- `ENABLE_FITNESS=true` — registro de treinos e refeições/dieta.

Veja [`docs/modulos.md`](docs/modulos.md).

## 🔐 Segurança

- **Nenhum segredo ou dado pessoal** é versionado. Tudo sensível vive no seu `.env` (que está no `.gitignore`).
- As credenciais (token, chave da IA, senha do banco) você configura na **sua** instância — nunca são compartilhadas.
- Veja [`docs/instalacao.md`](docs/instalacao.md) para o passo a passo completo.

## 📄 Licença

[MIT](LICENSE) — use, modifique e compartilhe livremente.
