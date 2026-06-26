-- ============================================================
--  n8n Telegram AI Assistant — schema do banco (Postgres)
--  Genérico, SEM dados pessoais. Aplicado automaticamente na
--  1ª subida do Postgres (via docker-entrypoint-initdb.d).
--  Obs.: este é o núcleo; será afinado para casar 1:1 com os
--  workflows na etapa de despersonalização.
-- ============================================================

-- Identidade do dono é sempre o OWNER_CHAT_ID (texto), nunca um número fixo.

-- ── Financeiro ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gastos (
  id              SERIAL PRIMARY KEY,
  usuario         TEXT        NOT NULL,
  valor           NUMERIC(12,2) NOT NULL,
  categoria       TEXT,
  descricao       TEXT,
  origem          TEXT        DEFAULT 'telegram_bot',
  forma_pagamento TEXT,
  estabelecimento TEXT,
  data_transacao  DATE,
  status          TEXT        DEFAULT 'confirmado',
  criado_em       TIMESTAMP   DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gastos_fixos (
  id        SERIAL PRIMARY KEY,
  usuario   TEXT NOT NULL,
  categoria TEXT,
  descricao TEXT,
  valor     NUMERIC(12,2) NOT NULL,
  ativo     BOOLEAN DEFAULT true,
  fim_em    DATE
);

CREATE TABLE IF NOT EXISTS faturas (
  id          SERIAL PRIMARY KEY,
  usuario     TEXT NOT NULL,
  cartao      TEXT NOT NULL,
  competencia DATE NOT NULL,
  valor       NUMERIC(12,2) NOT NULL,
  pago        BOOLEAN DEFAULT false,
  pago_em     TIMESTAMPTZ,
  UNIQUE (usuario, cartao, competencia)
);

CREATE TABLE IF NOT EXISTS orcamentos (
  id        SERIAL PRIMARY KEY,
  usuario   TEXT NOT NULL,
  categoria TEXT NOT NULL,
  valor     NUMERIC(12,2) NOT NULL,
  mes       DATE NOT NULL,
  UNIQUE (usuario, categoria, mes)
);

CREATE TABLE IF NOT EXISTS categorias (
  id            SERIAL PRIMARY KEY,
  nome          TEXT UNIQUE NOT NULL,
  palavras_chave TEXT,
  ativo         BOOLEAN DEFAULT true
);

-- ── Produtividade ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tarefas (
  id         SERIAL PRIMARY KEY,
  usuario    TEXT NOT NULL,
  descricao  TEXT NOT NULL,
  prazo_dt   TIMESTAMP,
  concluida  BOOLEAN DEFAULT false,
  criado_em  TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notas (
  id        SERIAL PRIMARY KEY,
  usuario   TEXT NOT NULL,
  conteudo  TEXT NOT NULL,
  criado_em TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS humor (
  id        SERIAL PRIMARY KEY,
  usuario   TEXT NOT NULL,
  nivel     INTEGER CHECK (nivel BETWEEN 1 AND 5),
  nota      TEXT,
  criado_em TIMESTAMP DEFAULT now()
);

-- ── Seeds genéricos (categorias padrão) ─────────────────────
INSERT INTO categorias (nome) VALUES
  ('alimentacao'), ('transporte'), ('saude'), ('lazer'),
  ('moradia'), ('contas'), ('educacao'), ('outros')
ON CONFLICT (nome) DO NOTHING;

-- ── Módulos opcionais (jurídico / fitness) ──────────────────
-- Veja db/schema_juridico.sql e db/schema_fitness.sql (aplicar só se usar o módulo).
