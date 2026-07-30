-- n8n Telegram AI Assistant - schema comunitario
-- Gerado a partir do contrato real dos workflows e sanitizado.
-- Aplicado somente na primeira inicializacao do volume PostgreSQL.

-- Dumped from database version 15.18 (Debian 15.18-1.pgdg13+1)
-- Dumped by pg_dump version 15.18 (Debian 15.18-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: faturas_norm_cartao(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.faturas_norm_cartao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.cartao IS NOT NULL THEN
    NEW.cartao := lower(btrim(regexp_replace(NEW.cartao, '[[:space:]_]+', ' ', 'g')));
  END IF;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bot_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_audit_log (
    id integer NOT NULL,
    usuario text,
    workflow text,
    acao text,
    entidade text,
    entidade_id text,
    antes jsonb,
    depois jsonb,
    desfeito boolean DEFAULT false,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: bot_audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_audit_log_id_seq OWNED BY public.bot_audit_log.id;


--
-- Name: bot_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_logs (
    id integer NOT NULL,
    usuario text,
    workflow text,
    nivel text DEFAULT 'info'::text,
    origem text,
    mensagem text,
    contexto jsonb,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: bot_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bot_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bot_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bot_logs_id_seq OWNED BY public.bot_logs.id;


--
-- Name: bot_telegram_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_telegram_updates (
    bot text NOT NULL,
    update_id bigint NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    nome text NOT NULL,
    rotulo text,
    emoji text,
    palavras text[],
    ativo boolean DEFAULT true,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: clientes_juridicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_juridicos (
    id integer NOT NULL,
    usuario text,
    nome text,
    telefone text,
    email text,
    observacoes text,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: clientes_juridicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_juridicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_juridicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_juridicos_id_seq OWNED BY public.clientes_juridicos.id;


--
-- Name: faturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faturas (
    id integer NOT NULL,
    usuario text DEFAULT 'casa'::text NOT NULL,
    cartao text NOT NULL,
    competencia date NOT NULL,
    valor numeric(12,2) NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now(),
    pago boolean DEFAULT false,
    pago_em timestamp with time zone,
    pago_parcial numeric DEFAULT 0,
    vencimento date,
    total_oficial numeric,
    status_conciliacao text
);


--
-- Name: COLUMN faturas.total_oficial; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas.total_oficial IS 'Total oficial real da fatura (quando difere do valor projetado); NULL usa valor';


--
-- Name: COLUMN faturas.status_conciliacao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas.status_conciliacao IS 'aberta|conciliada|divergente';


--
-- Name: faturas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faturas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faturas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faturas_id_seq OWNED BY public.faturas.id;


--
-- Name: gastos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gastos (
    id integer NOT NULL,
    usuario text NOT NULL,
    valor numeric(10,2) NOT NULL,
    categoria text,
    descricao text,
    criado_em timestamp without time zone DEFAULT now(),
    lancado_por text,
    origem text DEFAULT 'variavel'::text,
    data_transacao date,
    estabelecimento text,
    cnpj text,
    forma_pagamento text,
    banco text,
    ext_id text,
    status text DEFAULT 'confirmado'::text,
    raw jsonb,
    competencia_fatura date,
    tipo_lancamento text
);


--
-- Name: COLUMN gastos.competencia_fatura; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gastos.competencia_fatura IS 'Se a compra e de cartao, competencia (1o dia do mes) da fatura a que pertence; NULL = nao-cartao';


--
-- Name: COLUMN gastos.tipo_lancamento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gastos.tipo_lancamento IS 'compra|ajuste|juros|iof|tarifa|saldo_anterior|nao_identificada (NULL=compra)';


--
-- Name: gastos_fixos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gastos_fixos (
    id integer NOT NULL,
    usuario text DEFAULT 'casa'::text NOT NULL,
    categoria text NOT NULL,
    descricao text NOT NULL,
    valor numeric(12,2) NOT NULL,
    dia integer DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    fim_em date,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: gastos_fixos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gastos_fixos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gastos_fixos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gastos_fixos_id_seq OWNED BY public.gastos_fixos.id;


--
-- Name: gastos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gastos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gastos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gastos_id_seq OWNED BY public.gastos.id;


--
-- Name: gastos_import_raw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gastos_import_raw (
    id bigint NOT NULL,
    usuario text DEFAULT 'casa'::text,
    origem text,
    ext_id text,
    data_transacao date,
    descricao text,
    estabelecimento text,
    valor numeric(14,2),
    banco text,
    forma_pagamento text,
    categoria_sugerida text,
    raw jsonb,
    status text DEFAULT 'novo'::text,
    criado_em timestamp with time zone DEFAULT now(),
    promovido_em timestamp with time zone,
    gasto_id integer,
    lote text
);


--
-- Name: gastos_import_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gastos_import_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gastos_import_raw_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gastos_import_raw_id_seq OWNED BY public.gastos_import_raw.id;


--
-- Name: gastos_parcelados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gastos_parcelados (
    id integer NOT NULL,
    usuario text,
    descricao text,
    categoria text,
    cartao text,
    valor_total numeric,
    parcelas integer,
    primeira_competencia date,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: gastos_parcelados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gastos_parcelados_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gastos_parcelados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gastos_parcelados_id_seq OWNED BY public.gastos_parcelados.id;


--
-- Name: honorarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.honorarios (
    id integer NOT NULL,
    usuario character varying(50),
    cliente character varying(200),
    valor numeric(10,2),
    descricao text,
    status character varying(20) DEFAULT 'pendente'::character varying,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: honorarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.honorarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: honorarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.honorarios_id_seq OWNED BY public.honorarios.id;


--
-- Name: humor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.humor (
    id integer NOT NULL,
    usuario text NOT NULL,
    nivel integer NOT NULL,
    nota text,
    criado_em timestamp with time zone DEFAULT now(),
    CONSTRAINT humor_nivel_check CHECK (((nivel >= 1) AND (nivel <= 5)))
);


--
-- Name: humor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.humor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: humor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.humor_id_seq OWNED BY public.humor.id;


--
-- Name: n8n_chat_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.n8n_chat_histories (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    message jsonb NOT NULL
);


--
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.n8n_chat_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: n8n_chat_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.n8n_chat_histories_id_seq OWNED BY public.n8n_chat_histories.id;


--
-- Name: notas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notas (
    id integer NOT NULL,
    usuario text NOT NULL,
    texto text NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);


--
-- Name: notas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notas_id_seq OWNED BY public.notas.id;


--
-- Name: orcamentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orcamentos (
    id integer NOT NULL,
    usuario text NOT NULL,
    categoria text NOT NULL,
    valor_limite numeric(10,2) NOT NULL,
    mes date DEFAULT date_trunc('month'::text, now()) NOT NULL
);


--
-- Name: orcamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orcamentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orcamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orcamentos_id_seq OWNED BY public.orcamentos.id;


--
-- Name: pluggy_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pluggy_items (
    pluggy_item_id text NOT NULL,
    connector_name text,
    titular_conexao text DEFAULT 'owner'::text NOT NULL,
    usuario text DEFAULT 'casa'::text NOT NULL,
    status text,
    criado_em timestamp with time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pluggy_transactions_raw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pluggy_transactions_raw (
    pluggy_transaction_id text NOT NULL,
    pluggy_item_id text,
    pluggy_account_id text,
    titular_conexao text DEFAULT 'owner'::text,
    usuario text DEFAULT 'casa'::text,
    origem text DEFAULT 'pluggy'::text,
    data_transacao date,
    descricao text,
    valor numeric(14,2),
    tipo text,
    categoria_pluggy text,
    moeda text,
    conta_nome text,
    raw jsonb,
    importado_em timestamp with time zone DEFAULT now() NOT NULL,
    promovido_em timestamp with time zone
);


--
-- Name: processos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.processos (
    id integer NOT NULL,
    usuario character varying(20) NOT NULL,
    numero_cnj character varying(50) NOT NULL,
    tribunal character varying(10) NOT NULL,
    descricao text,
    ultima_movimentacao timestamp without time zone,
    ultimo_hash character varying(64),
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now(),
    fase text,
    proximo_ato text,
    cliente text,
    atualizado_em timestamp with time zone
);


--
-- Name: processos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.processos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: processos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.processos_id_seq OWNED BY public.processos.id;


--
-- Name: publicacoes_vistas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publicacoes_vistas (
    chave text NOT NULL,
    usuario text,
    visto_em timestamp with time zone DEFAULT now()
);


--
-- Name: refeicoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refeicoes (
    id integer NOT NULL,
    usuario character varying(50),
    refeicao character varying(100),
    itens text,
    calorias integer,
    proteinas numeric(6,1),
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: refeicoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refeicoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refeicoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refeicoes_id_seq OWNED BY public.refeicoes.id;


--
-- Name: tarefas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarefas (
    id integer NOT NULL,
    usuario text NOT NULL,
    titulo text NOT NULL,
    prazo text,
    status text DEFAULT 'pendente'::text,
    criado_em timestamp without time zone DEFAULT now(),
    prazo_dt timestamp without time zone,
    lembrete_enviado boolean DEFAULT false,
    tipo character varying(50) DEFAULT 'pessoal'::character varying
);


--
-- Name: tarefas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tarefas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tarefas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tarefas_id_seq OWNED BY public.tarefas.id;


--
-- Name: tarefas_recorrentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarefas_recorrentes (
    id integer NOT NULL,
    usuario text,
    titulo text,
    regra text,
    hora text,
    tipo text DEFAULT 'pessoal'::text,
    ativo boolean DEFAULT true,
    ultimo_gerado date,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: tarefas_recorrentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tarefas_recorrentes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tarefas_recorrentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tarefas_recorrentes_id_seq OWNED BY public.tarefas_recorrentes.id;


--
-- Name: treinos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treinos (
    id integer NOT NULL,
    usuario character varying(50),
    tipo character varying(50),
    dados jsonb,
    observacoes text,
    criado_em timestamp with time zone DEFAULT now()
);


--
-- Name: treinos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.treinos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: treinos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.treinos_id_seq OWNED BY public.treinos.id;


--
-- Name: bot_audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_audit_log ALTER COLUMN id SET DEFAULT nextval('public.bot_audit_log_id_seq'::regclass);


--
-- Name: bot_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_logs ALTER COLUMN id SET DEFAULT nextval('public.bot_logs_id_seq'::regclass);


--
-- Name: clientes_juridicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_juridicos ALTER COLUMN id SET DEFAULT nextval('public.clientes_juridicos_id_seq'::regclass);


--
-- Name: faturas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas ALTER COLUMN id SET DEFAULT nextval('public.faturas_id_seq'::regclass);


--
-- Name: gastos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos ALTER COLUMN id SET DEFAULT nextval('public.gastos_id_seq'::regclass);


--
-- Name: gastos_fixos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_fixos ALTER COLUMN id SET DEFAULT nextval('public.gastos_fixos_id_seq'::regclass);


--
-- Name: gastos_import_raw id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_import_raw ALTER COLUMN id SET DEFAULT nextval('public.gastos_import_raw_id_seq'::regclass);


--
-- Name: gastos_parcelados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_parcelados ALTER COLUMN id SET DEFAULT nextval('public.gastos_parcelados_id_seq'::regclass);


--
-- Name: honorarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.honorarios ALTER COLUMN id SET DEFAULT nextval('public.honorarios_id_seq'::regclass);


--
-- Name: humor id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.humor ALTER COLUMN id SET DEFAULT nextval('public.humor_id_seq'::regclass);


--
-- Name: n8n_chat_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories ALTER COLUMN id SET DEFAULT nextval('public.n8n_chat_histories_id_seq'::regclass);


--
-- Name: notas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notas ALTER COLUMN id SET DEFAULT nextval('public.notas_id_seq'::regclass);


--
-- Name: orcamentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcamentos ALTER COLUMN id SET DEFAULT nextval('public.orcamentos_id_seq'::regclass);


--
-- Name: processos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processos ALTER COLUMN id SET DEFAULT nextval('public.processos_id_seq'::regclass);


--
-- Name: refeicoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refeicoes ALTER COLUMN id SET DEFAULT nextval('public.refeicoes_id_seq'::regclass);


--
-- Name: tarefas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarefas ALTER COLUMN id SET DEFAULT nextval('public.tarefas_id_seq'::regclass);


--
-- Name: tarefas_recorrentes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarefas_recorrentes ALTER COLUMN id SET DEFAULT nextval('public.tarefas_recorrentes_id_seq'::regclass);


--
-- Name: treinos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treinos ALTER COLUMN id SET DEFAULT nextval('public.treinos_id_seq'::regclass);


--
-- Name: bot_audit_log bot_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_audit_log
    ADD CONSTRAINT bot_audit_log_pkey PRIMARY KEY (id);


--
-- Name: bot_logs bot_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_logs
    ADD CONSTRAINT bot_logs_pkey PRIMARY KEY (id);


--
-- Name: bot_telegram_updates bot_telegram_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_telegram_updates
    ADD CONSTRAINT bot_telegram_updates_pkey PRIMARY KEY (bot, update_id);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (nome);


--
-- Name: clientes_juridicos clientes_juridicos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_juridicos
    ADD CONSTRAINT clientes_juridicos_pkey PRIMARY KEY (id);


--
-- Name: faturas faturas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas
    ADD CONSTRAINT faturas_pkey PRIMARY KEY (id);


--
-- Name: faturas faturas_usuario_cartao_competencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas
    ADD CONSTRAINT faturas_usuario_cartao_competencia_key UNIQUE (usuario, cartao, competencia);


--
-- Name: gastos_fixos gastos_fixos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_fixos
    ADD CONSTRAINT gastos_fixos_pkey PRIMARY KEY (id);


--
-- Name: gastos_import_raw gastos_import_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_import_raw
    ADD CONSTRAINT gastos_import_raw_pkey PRIMARY KEY (id);


--
-- Name: gastos_parcelados gastos_parcelados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos_parcelados
    ADD CONSTRAINT gastos_parcelados_pkey PRIMARY KEY (id);


--
-- Name: gastos gastos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gastos
    ADD CONSTRAINT gastos_pkey PRIMARY KEY (id);


--
-- Name: honorarios honorarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.honorarios
    ADD CONSTRAINT honorarios_pkey PRIMARY KEY (id);


--
-- Name: humor humor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.humor
    ADD CONSTRAINT humor_pkey PRIMARY KEY (id);


--
-- Name: n8n_chat_histories n8n_chat_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n8n_chat_histories
    ADD CONSTRAINT n8n_chat_histories_pkey PRIMARY KEY (id);


--
-- Name: notas notas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notas
    ADD CONSTRAINT notas_pkey PRIMARY KEY (id);


--
-- Name: orcamentos orcamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcamentos
    ADD CONSTRAINT orcamentos_pkey PRIMARY KEY (id);


--
-- Name: orcamentos orcamentos_usuario_categoria_mes_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcamentos
    ADD CONSTRAINT orcamentos_usuario_categoria_mes_key UNIQUE (usuario, categoria, mes);


--
-- Name: pluggy_items pluggy_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pluggy_items
    ADD CONSTRAINT pluggy_items_pkey PRIMARY KEY (pluggy_item_id);


--
-- Name: pluggy_transactions_raw pluggy_transactions_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pluggy_transactions_raw
    ADD CONSTRAINT pluggy_transactions_raw_pkey PRIMARY KEY (pluggy_transaction_id);


--
-- Name: processos processos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT processos_pkey PRIMARY KEY (id);


--
-- Name: publicacoes_vistas publicacoes_vistas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicacoes_vistas
    ADD CONSTRAINT publicacoes_vistas_pkey PRIMARY KEY (chave);


--
-- Name: refeicoes refeicoes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refeicoes
    ADD CONSTRAINT refeicoes_pkey PRIMARY KEY (id);


--
-- Name: tarefas tarefas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarefas
    ADD CONSTRAINT tarefas_pkey PRIMARY KEY (id);


--
-- Name: tarefas_recorrentes tarefas_recorrentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarefas_recorrentes
    ADD CONSTRAINT tarefas_recorrentes_pkey PRIMARY KEY (id);


--
-- Name: treinos treinos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treinos
    ADD CONSTRAINT treinos_pkey PRIMARY KEY (id);


--
-- Name: bot_telegram_updates_received_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bot_telegram_updates_received_at_idx ON public.bot_telegram_updates USING btree (received_at);


--
-- Name: idx_bot_logs_nivel_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bot_logs_nivel_criado ON public.bot_logs USING btree (nivel, criado_em);


--
-- Name: idx_bot_logs_workflow; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bot_logs_workflow ON public.bot_logs USING btree (workflow, criado_em);


--
-- Name: idx_faturas_usuario_pago; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_faturas_usuario_pago ON public.faturas USING btree (usuario, pago);


--
-- Name: idx_gastos_fixos_usuario_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gastos_fixos_usuario_ativo ON public.gastos_fixos USING btree (usuario, ativo);


--
-- Name: idx_gastos_usuario_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gastos_usuario_categoria ON public.gastos USING btree (usuario, categoria);


--
-- Name: idx_gastos_usuario_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gastos_usuario_criado ON public.gastos USING btree (usuario, criado_em);


--
-- Name: idx_gastos_usuario_data_tx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gastos_usuario_data_tx ON public.gastos USING btree (usuario, data_transacao);


--
-- Name: idx_honorarios_usuario_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_honorarios_usuario_status ON public.honorarios USING btree (usuario, status);


--
-- Name: idx_humor_usuario_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_humor_usuario_criado ON public.humor USING btree (usuario, criado_em);


--
-- Name: idx_import_lote; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_lote ON public.gastos_import_raw USING btree (lote);


--
-- Name: idx_import_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_status ON public.gastos_import_raw USING btree (status, criado_em);


--
-- Name: idx_notas_usuario_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notas_usuario_criado ON public.notas USING btree (usuario, criado_em);


--
-- Name: idx_pluggy_raw_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pluggy_raw_data ON public.pluggy_transactions_raw USING btree (data_transacao);


--
-- Name: idx_pluggy_raw_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pluggy_raw_item ON public.pluggy_transactions_raw USING btree (pluggy_item_id);


--
-- Name: idx_processos_cnj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_processos_cnj ON public.processos USING btree (numero_cnj);


--
-- Name: idx_processos_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_processos_usuario ON public.processos USING btree (usuario);


--
-- Name: idx_processos_usuario_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_processos_usuario_ativo ON public.processos USING btree (usuario) WHERE ativo;


--
-- Name: idx_publicacoes_vistas_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_publicacoes_vistas_usuario ON public.publicacoes_vistas USING btree (usuario, visto_em);


--
-- Name: idx_refeicoes_usuario_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refeicoes_usuario_criado ON public.refeicoes USING btree (usuario, criado_em);


--
-- Name: idx_tarefas_usuario_lembrete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarefas_usuario_lembrete ON public.tarefas USING btree (usuario, lembrete_enviado, prazo_dt) WHERE (status = 'pendente'::text);


--
-- Name: idx_tarefas_usuario_status_prazo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarefas_usuario_status_prazo ON public.tarefas USING btree (usuario, status, prazo_dt);


--
-- Name: idx_treinos_usuario_criado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_treinos_usuario_criado ON public.treinos USING btree (usuario, criado_em);


--
-- Name: processos_usuario_cnj_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX processos_usuario_cnj_uniq ON public.processos USING btree (usuario, numero_cnj);


--
-- Name: uq_gastos_origem_extid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_gastos_origem_extid ON public.gastos USING btree (usuario, origem, ext_id) WHERE ((ext_id IS NOT NULL) AND (ext_id <> ''::text));


--
-- Name: uq_gastos_usuario_extid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_gastos_usuario_extid ON public.gastos USING btree (usuario, ext_id) WHERE ((ext_id IS NOT NULL) AND (ext_id <> ''::text));


--
-- Name: uq_import_origem_extid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_import_origem_extid ON public.gastos_import_raw USING btree (origem, ext_id) WHERE ((ext_id IS NOT NULL) AND (ext_id <> ''::text));


--
-- Name: faturas trg_faturas_norm_cartao; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_faturas_norm_cartao BEFORE INSERT OR UPDATE ON public.faturas FOR EACH ROW EXECUTE FUNCTION public.faturas_norm_cartao();

INSERT INTO public.categorias (nome, rotulo, emoji, palavras, ativo)
VALUES
    ('alimentacao', 'Alimentacao', '🍽️', ARRAY['mercado','restaurante','ifood','lanche'], true),
    ('transporte', 'Transporte', '🚗', ARRAY['uber','99','posto','gasolina','onibus'], true),
    ('saude', 'Saude', '💊', ARRAY['farmacia','medico','consulta','exame'], true),
    ('lazer', 'Lazer', '🎉', ARRAY['cinema','show','viagem','jogo'], true),
    ('vestuario', 'Vestuario', '👕', ARRAY['roupa','calcado','tenis'], true),
    ('moradia', 'Moradia', '🏠', ARRAY['aluguel','condominio','reparo'], true),
    ('contas', 'Contas', '🧾', ARRAY['energia','agua','internet','telefone'], true),
    ('trabalho', 'Trabalho', '💼', ARRAY['software','curso','escritorio'], true),
    ('educacao', 'Educacao', '📚', ARRAY['livro','faculdade','escola'], true),
    ('outros', 'Outros', '📦', ARRAY[]::text[], true)
ON CONFLICT (nome) DO NOTHING;

--
-- PostgreSQL database dump complete
--
