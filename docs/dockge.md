# Instalacao pelo Dockge

O [Dockge](https://github.com/louislam/dockge) e um gerenciador de stacks
Docker Compose com interface web. Como todo o conteudo do assistente (schema
do banco, workflows e bootstrap) viaja dentro da imagem publicada, o stack e
autocontido: nao existe build local, nem bind mount de pasta do repositorio.
Na pratica, instalar pelo Dockge e colar um arquivo e preencher um formulario.

> Antes de comecar, leia a secao [Segredos e seguranca](#segredos-e-seguranca).
> O Dockge mostra o `.env` do stack em texto claro no navegador.

## Requisitos

- Dockge instalado e acessivel somente por voce;
- bot criado no [@BotFather](https://t.me/BotFather);
- chave da Anthropic;
- HTTPS publico, se quiser ativar o Telegram Trigger;
- 2 GB de RAM livres como referencia de partida (n8n + PostgreSQL).

## Passo a passo

### 1. Gere os segredos

Em qualquer terminal, antes de abrir o Dockge:

```bash
openssl rand -hex 24   # vira PG_PASSWORD
openssl rand -hex 32   # vira N8N_ENCRYPTION_KEY
```

Ou, com o repositorio clonado:

```bash
./scripts/gen-secrets.sh      # Linux/macOS
.\scripts\gen-secrets.ps1     # Windows PowerShell
```

Guarde `N8N_ENCRYPTION_KEY` em um gerenciador de senhas. Ela cifra as
credenciais dentro do n8n; um backup restaurado com outra chave nao consegue
ler o token do Telegram nem a chave da Anthropic.

### 2. Crie o stack

No Dockge: **+ Compose** -> nome do stack, por exemplo `assistente-telegram`.

Use letras minusculas, numeros e hifen. O nome vira o prefixo dos volumes
(`assistente-telegram_pgdata`, etc.), entao troca-lo depois equivale a comecar
uma instalacao nova.

### 3. Cole o compose

Copie o conteudo de
[`deploy/dockge/compose.yaml`](../deploy/dockge/compose.yaml) no editor de
compose do Dockge.

Esse arquivo e uma versao plana do `docker-compose.yml` da raiz: mesmas
imagens e mesmas variaveis, porem sem ancoras YAML (`&`/`*`) e sem `profiles`,
porque a interface do Dockge nao oferece selecao de perfil e o arquivo fica
mais facil de editar na tela. O Cloudflare Tunnel esta no fim do arquivo,
comentado.

### 4. Preencha o ambiente

Na aba de ambiente (`.env`) do stack, cole
[`deploy/dockge/.env.example`](../deploy/dockge/.env.example) e preencha:

| Variavel | De onde vem |
| --- | --- |
| `TELEGRAM_BOT_TOKEN` | BotFather, ao criar o bot |
| `ANTHROPIC_API_KEY` | console da Anthropic |
| `OWNER_CHAT_ID` | seu chat ID numerico no Telegram |
| `OWNER_NAME` | como o bot deve te chamar |
| `PG_PASSWORD` | gerado no passo 1 |
| `N8N_ENCRYPTION_KEY` | gerado no passo 1 |

O restante tem padrao funcional. `BOT_NAME`, `SECONDARY_NAME`, `CNJ_API_KEY`
e as variaveis de URL publica sao ajustes opcionais.

Se alguma obrigatoria ficar vazia, o deploy falha com uma mensagem dizendo
qual variavel falta. Isso e proposital: e melhor falhar do que subir um stack
com banco sem senha.

### 5. Deploy

Clique em **Deploy** e acompanhe os logs. A ordem esperada e:

```text
assets       -> copia o schema e sai (exited 0)
postgres     -> fica saudavel (healthy)
n8n-import   -> cria credenciais, importa workflows e sai (exited 0)
n8n          -> fica em execucao
```

`assets` e `n8n-import` aparecem parados no Dockge depois do deploy. **Isso e
o certo**: sao tarefas de inicializacao, nao servicos. Se o Dockge mostrar o
stack como parcialmente parado, confira apenas se `postgres` e `n8n` estao de
pe.

### 6. Primeiro acesso

1. abra o n8n na URL configurada (`http://IP-do-servidor:5678` por padrao);
2. crie o usuario local do n8n — ele nao existe antes disso;
3. confira os workflows `AI Assistant Community` e `AI Assistant Community Pro`;
4. ative **apenas um** deles;
5. mande uma mensagem de teste no Telegram.

Os dois workflows chegam desativados de proposito. Ativar os dois com o mesmo
token faz o Telegram entregar a mesma mensagem para ambos.

## Atalho pelo terminal da VPS

Se preferir preparar o stack por SSH e so depois abrir o Dockge, baixe os
arquivos direto na pasta de stacks (`/opt/stacks` na instalacao padrao):

```bash
STACK=/opt/stacks/assistente-telegram
RAW=https://raw.githubusercontent.com/DienysonSouza/n8n-telegram-ai-assistant/main/deploy/dockge

sudo mkdir -p "$STACK"
sudo curl -fsSL "$RAW/compose.yaml"  -o "$STACK/compose.yaml"
sudo curl -fsSL "$RAW/.env.example"  -o "$STACK/.env"
sudo chmod 600 "$STACK/.env"
sudo nano "$STACK/.env"   # preencha os obrigatorios
```

Leia os dois arquivos antes de subir. O Dockge detecta a pasta e mostra o
stack na lista; basta clicar em **Deploy**.

## URL publica para o Telegram

O Telegram Trigger so ativa com HTTPS publico. Com um dominio proprio, ajuste
no ambiente do stack:

```env
N8N_HOST=bot.exemplo.com
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
WEBHOOK_URL=https://bot.exemplo.com/
N8N_PORT=127.0.0.1:5678
```

E aponte o proxy reverso (Nginx Proxy Manager, Caddy, Traefik) para
`http://127.0.0.1:5678`. Com `N8N_PORT=127.0.0.1:5678` a porta deixa de ficar
exposta na internet e responde so ao proxy do proprio host.

Se o proxy estiver em outro container, mantenha `N8N_PORT=5678` e ligue o
proxy a rede do stack, ou troque a porta publicada por uma rede externa
compartilhada.

### Cloudflare Tunnel

O Dockge nao seleciona `profiles` do Compose, entao o `cloudflared` vem
comentado no fim do `compose.yaml`. Para usar:

1. crie o tunnel na sua conta Cloudflare e aponte o hostname para
   `http://n8n:5678`;
2. preencha `CLOUDFLARE_TUNNEL_TOKEN` no ambiente do stack;
3. descomente o bloco `cloudflared` no compose;
4. faca deploy de novo.

O token do tunnel da acesso ao seu tunnel Cloudflare: trate como senha.

## Operacao pelo Dockge

| Acao | Como fazer |
| --- | --- |
| Atualizar | botao **Update** do stack (equivale a `docker compose pull && up -d`) |
| Reiniciar | **Restart**; o bootstrap nao roda de novo nem duplica workflows |
| Parar sem perder dados | **Stop**; os volumes continuam intactos |
| Ver logs | aba de terminal/logs do stack |
| Rodar comandos | terminal do container, ex.: `n8n list:workflow --onlyId` |

Para atualizacoes controladas, troque `ASSISTANT_VERSION=latest` por uma tag
fixa (`v1.0.0`) e so mude quando for atualizar de proposito.

O botao **Delete** do Dockge apaga a pasta do stack, inclusive o `.env`. Faca
backup antes.

## Backup

Volumes a preservar: `n8n_data` (credenciais e workflows) e `pgdata` (seus
dados). Os dois recebem o prefixo do nome do stack.

```bash
# banco
docker compose -f /opt/stacks/assistente-telegram/compose.yaml \
  exec -T postgres pg_dump -U assistant -d assistant -Fc > assistant.dump

# n8n: pare o stack antes de copiar o volume
docker run --rm -v assistente-telegram_n8n_data:/data -v "$PWD":/backup \
  alpine tar czf /backup/n8n_data.tar.gz -C /data .
```

Guarde tambem o `.env` — ou pelo menos `N8N_ENCRYPTION_KEY` — em local
protegido e **fora** do mesmo servidor. Um backup so vale depois de ter sido
restaurado com sucesso em um ambiente isolado.

## Segredos e seguranca

O stack lida com tres segredos de verdade: o token do bot, a chave da
Anthropic e a chave de criptografia do n8n. Quem tiver acesso ao Dockge tem
acesso aos tres.

**No repositorio**

- o `.env` preenchido nunca entra no git; o `.gitignore` ja bloqueia `.env` e
  `*.env`, e o unico arquivo versionado e o `.env.example` com campos vazios;
- nenhum arquivo do projeto contem token, senha ou dado pessoal. Se precisar
  exportar um workflow editado, rode `node scripts/prepare-workflows.mjs`
  antes de commitar: o script remove referencias pessoais.

**No servidor**

- proteja o proprio Dockge: senha forte, atras de HTTPS e, de preferencia,
  sem a porta 5001 aberta para a internet;
- o Dockge grava o `.env` em texto claro em `/opt/stacks/<stack>/.env`.
  Aplique `chmod 600` nesse arquivo e refaca depois de editar pela interface,
  que pode reescrever o arquivo;
- nao publique a porta do n8n direto na internet sem proxy e HTTPS;
- mantenha `PG_HOST=postgres`: o banco fica na rede interna do stack e nao
  precisa de porta publicada.

**No dia a dia**

- ao pedir ajuda, em issue ou grupo, nunca cole logs, prints da tela do Dockge
  ou trechos de `.env` sem antes apagar tokens e senhas;
- se um token vazar: revogue no BotFather (`/revoke`) e gere a chave da
  Anthropic de novo no console. Depois atualize o ambiente do stack e faca
  deploy;
- trocar `N8N_ENCRYPTION_KEY` de uma instalacao existente invalida as
  credenciais ja salvas: elas precisam ser recriadas no n8n;
- trocar `PG_PASSWORD` depois do primeiro boot exige atualizar tambem a senha
  do usuario no PostgreSQL e a credencial `Assistant Postgres` dentro do n8n —
  o bootstrap so cria credenciais no primeiro deploy.

## Diagnostico

**O deploy para dizendo que falta variavel**

Mensagem no formato `defina X no ambiente do stack`. Preencha o campo na aba
de ambiente e faca deploy de novo.

**`n8n-import` terminou com erro**

Veja os logs do servico. As causas comuns sao campo obrigatorio vazio,
PostgreSQL que nao ficou saudavel e permissao do volume `n8n_data`.

**Os workflows nao aparecem**

O bootstrap ignora a importacao quando encontra uma instancia n8n que ja tem
workflows, para nao sobrescrever instalacao existente. Em um stack novo, isso
costuma indicar volume reaproveitado de outra instalacao.

**O stack aparece "parcialmente parado"**

Comportamento esperado: `assets` e `n8n-import` sao tarefas de inicializacao e
saem com codigo zero. Verifique so `postgres` e `n8n`.

**O Telegram nao ativa o trigger**

Confirme que `WEBHOOK_URL` e HTTPS publico, que o dominio realmente chega ao
n8n e que apenas um workflow usa o token.

## Instalacao sem Dockge

Para instalacao assistida por script, uso local ou Docker Compose puro, veja
[instalacao.md](instalacao.md).
