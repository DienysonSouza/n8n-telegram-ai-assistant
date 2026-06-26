# 🧩 Módulos

O assistente é dividido em módulos. Os **principais** vêm ligados; os **opcionais** você ativa no `.env`.

## Principais (sempre ativos)

### 💰 Financeiro
- Lançar gastos por linguagem natural: *"ifood 45 no crédito"*.
- Gastos fixos mensais, faturas de cartão, orçamentos por categoria.
- Relatórios (diário/semanal/mensal) e categorização automática pela IA.
- Categorias customizáveis via `EXPENSE_CATEGORIES`.

### ✅ Produtividade
- Tarefas com prazo, conclusão, adiamento e recorrência.
- Lembretes automáticos no horário.
- Notas rápidas e registro de humor.

### ⏰ Rotinas agendadas
- Resumo diário, relatório semanal e alertas — enviados automaticamente no seu Telegram.

## Opcionais

### ⚖️ Jurídico — `ENABLE_JURIDICO=true`
Para quem é da área jurídica:
- Registro de honorários e clientes.
- Acompanhamento de prazos processuais.
- Monitor de publicações via API pública do CNJ (informe a `OAB_NUMBER`).

> Requer aplicar `db/schema_juridico.sql`.

### 🏋️ Fitness — `ENABLE_FITNESS=true`
- Registro de treinos (tipo, duração).
- Registro de refeições / acompanhamento de dieta.

> Requer aplicar `db/schema_fitness.sql`.

---

Cada módulo é um conjunto de "tools" no workflow do n8n. Você pode remover os que não usar diretamente na interface do n8n, sem quebrar os demais.
