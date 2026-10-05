-- Agentic Support MVP - PostgreSQL 16+
-- Enable pgvector separately if semantic retrieval is used:
-- CREATE EXTENSION IF NOT EXISTS vector;

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE tenant_status AS ENUM ('active','suspended','archived');
CREATE TYPE knowledge_status AS ENUM ('pending','approved','rejected','superseded','expired');
CREATE TYPE conversation_status AS ENUM ('open','waiting_customer','waiting_human','resolved','closed');
CREATE TYPE message_role AS ENUM ('customer','assistant','human_agent','system','tool');
CREATE TYPE tool_risk AS ENUM ('read_only','controlled_write','approval_required');
CREATE TYPE approval_status AS ENUM ('pending','approved','rejected','expired','cancelled');
CREATE TYPE run_status AS ENUM ('queued','running','waiting_approval','completed','failed','cancelled');

CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  display_name text NOT NULL,
  public_key text NOT NULL UNIQUE,
  status tenant_status NOT NULL DEFAULT 'active',
  default_locale text NOT NULL DEFAULT 'en',
  retention_days integer NOT NULL DEFAULT 90 CHECK (retention_days BETWEEN 1 AND 3650),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tenant_domains (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  hostname text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, hostname)
);

CREATE TABLE end_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  external_subject text,
  display_name text,
  email_ciphertext bytea,
  locale text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, external_subject)
);

CREATE TABLE consent_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  end_user_id uuid REFERENCES end_users(id) ON DELETE SET NULL,
  purpose text NOT NULL,
  granted boolean NOT NULL,
  policy_version text NOT NULL,
  channel text NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  end_user_id uuid REFERENCES end_users(id) ON DELETE SET NULL,
  channel text NOT NULL,
  status conversation_status NOT NULL DEFAULT 'open',
  locale text NOT NULL DEFAULT 'en',
  tone_preference text NOT NULL DEFAULT 'adaptive',
  external_thread_id text,
  assigned_team text,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  UNIQUE (tenant_id, channel, external_thread_id)
);

CREATE INDEX conversations_tenant_status_idx ON conversations(tenant_id, status, updated_at DESC);

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role message_role NOT NULL,
  content text NOT NULL,
  content_sha256 text NOT NULL,
  actor_id text,
  client_message_id text,
  citations jsonb NOT NULL DEFAULT '[]'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (conversation_id, client_message_id)
);

CREATE INDEX messages_conversation_created_idx ON messages(conversation_id, created_at);

CREATE TABLE knowledge_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  source_type text NOT NULL,
  canonical_uri text,
  title text NOT NULL,
  owner text NOT NULL,
  audience text NOT NULL DEFAULT 'public',
  status knowledge_status NOT NULL DEFAULT 'pending',
  current_version integer NOT NULL DEFAULT 1,
  effective_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, canonical_uri)
);

CREATE TABLE knowledge_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  source_id uuid NOT NULL REFERENCES knowledge_sources(id) ON DELETE CASCADE,
  version integer NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  body_sha256 text NOT NULL,
  mime_type text NOT NULL DEFAULT 'text/markdown',
  status knowledge_status NOT NULL DEFAULT 'pending',
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (source_id, version)
);

CREATE TABLE knowledge_chunks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES knowledge_documents(id) ON DELETE CASCADE,
  ordinal integer NOT NULL,
  content text NOT NULL,
  token_count integer NOT NULL CHECK (token_count >= 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  -- embedding vector(768), -- uncomment after enabling pgvector and choosing dimension
  searchable_tsv tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (document_id, ordinal)
);

CREATE INDEX knowledge_chunks_fts_idx ON knowledge_chunks USING gin(searchable_tsv);

CREATE TABLE agent_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  request_message_id uuid REFERENCES messages(id),
  status run_status NOT NULL DEFAULT 'queued',
  intent text,
  risk_tier tool_risk NOT NULL DEFAULT 'read_only',
  specialist text,
  model_policy text,
  trace_id text NOT NULL,
  input_tokens integer NOT NULL DEFAULT 0,
  output_tokens integer NOT NULL DEFAULT 0,
  latency_ms integer,
  error_code text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX agent_runs_trace_idx ON agent_runs(trace_id);

CREATE TABLE retrieval_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  run_id uuid NOT NULL REFERENCES agent_runs(id) ON DELETE CASCADE,
  chunk_id uuid NOT NULL REFERENCES knowledge_chunks(id),
  rank integer NOT NULL,
  retrieval_score numeric(8,6),
  rerank_score numeric(8,6),
  used_in_answer boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (run_id, chunk_id)
);

CREATE TABLE tool_registry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  name text NOT NULL,
  version text NOT NULL,
  description text NOT NULL,
  risk tool_risk NOT NULL,
  required_scopes text[] NOT NULL DEFAULT '{}',
  input_schema jsonb NOT NULL,
  output_schema jsonb NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  timeout_ms integer NOT NULL DEFAULT 5000 CHECK (timeout_ms BETWEEN 100 AND 120000),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, name, version)
);

CREATE TABLE tool_invocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  run_id uuid NOT NULL REFERENCES agent_runs(id) ON DELETE CASCADE,
  tool_id uuid NOT NULL REFERENCES tool_registry(id),
  idempotency_key text NOT NULL,
  arguments_redacted jsonb NOT NULL,
  status text NOT NULL CHECK (status IN ('proposed','waiting_approval','executing','succeeded','failed','cancelled')),
  result_redacted jsonb,
  error_code text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  tool_invocation_id uuid NOT NULL UNIQUE REFERENCES tool_invocations(id) ON DELETE CASCADE,
  status approval_status NOT NULL DEFAULT 'pending',
  required_role text NOT NULL,
  requested_by text NOT NULL,
  decided_by text,
  reason_code text,
  expires_at timestamptz NOT NULL,
  decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE handoffs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  run_id uuid REFERENCES agent_runs(id) ON DELETE SET NULL,
  destination text NOT NULL,
  priority text NOT NULL DEFAULT 'normal',
  customer_objective text NOT NULL,
  summary text NOT NULL,
  attempted_steps jsonb NOT NULL DEFAULT '[]'::jsonb,
  evidence jsonb NOT NULL DEFAULT '[]'::jsonb,
  current_blocker text,
  external_case_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  message_id uuid REFERENCES messages(id) ON DELETE SET NULL,
  rating smallint CHECK (rating BETWEEN 1 AND 5),
  resolved boolean,
  comment text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  actor_type text NOT NULL,
  actor_id text,
  resource_type text NOT NULL,
  resource_id text NOT NULL,
  trace_id text,
  reason_code text,
  before_state jsonb,
  after_state jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_events_resource_idx ON audit_events(tenant_id, resource_type, resource_id, created_at DESC);
CREATE INDEX audit_events_trace_idx ON audit_events(trace_id);

COMMIT;
