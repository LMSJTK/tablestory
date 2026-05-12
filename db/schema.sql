-- Tablestory MVP v1 schema

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE member_role AS ENUM ('owner', 'gm', 'player', 'viewer');
CREATE TYPE session_status AS ENUM ('scheduled', 'active', 'completed', 'archived');
CREATE TYPE participant_kind AS ENUM ('human', 'ai');
CREATE TYPE message_kind AS ENUM ('chat', 'system', 'narration', 'ooc');
CREATE TYPE memory_item_type AS ENUM ('npc', 'location', 'quest', 'loot', 'relationship', 'fact');
CREATE TYPE memory_status AS ENUM ('proposed', 'confirmed', 'rejected', 'superseded');
CREATE TYPE job_status AS ENUM ('queued', 'running', 'completed', 'failed', 'dead_lettered');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE campaign_members (
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role member_role NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  session_number INTEGER,
  scheduled_for TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  status session_status NOT NULL DEFAULT 'scheduled',
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE session_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  kind participant_kind NOT NULL,
  display_name TEXT NOT NULL,
  ai_profile_key TEXT,
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,
  UNIQUE (session_id, user_id)
);

CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  class_name TEXT,
  level INTEGER,
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE character_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
  version INTEGER NOT NULL,
  snapshot_json JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (character_id, version)
);

CREATE TABLE game_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  actor_participant_id UUID REFERENCES session_participants(id),
  payload_json JSONB NOT NULL,
  schema_version TEXT NOT NULL DEFAULT '1.0.0',
  ts TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  sender_participant_id UUID REFERENCES session_participants(id),
  kind message_kind NOT NULL DEFAULT 'chat',
  body TEXT NOT NULL,
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  ts TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transcript_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  speaker_participant_id UUID REFERENCES session_participants(id),
  start_ts TIMESTAMPTZ NOT NULL,
  end_ts TIMESTAMPTZ NOT NULL,
  confidence NUMERIC(4,3),
  raw_text TEXT NOT NULL,
  normalized_text TEXT,
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE session_recaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  status job_status NOT NULL DEFAULT 'queued',
  short_recap_markdown TEXT,
  long_recap_markdown TEXT,
  source_coverage_json JSONB,
  model_name TEXT,
  prompt_version TEXT,
  token_input INTEGER,
  token_output INTEGER,
  estimated_cost_usd NUMERIC(12,6),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE (session_id, prompt_version)
);

CREATE TABLE session_highlights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  importance INTEGER NOT NULL CHECK (importance BETWEEN 1 AND 5),
  source_event_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE campaign_memory_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  item_type memory_item_type NOT NULL,
  canonical_name TEXT NOT NULL,
  summary TEXT NOT NULL,
  attributes_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  confidence NUMERIC(4,3),
  status memory_status NOT NULL DEFAULT 'proposed',
  source_event_ids UUID[] NOT NULL DEFAULT '{}',
  created_by_job_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ai_job_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL,
  status job_status NOT NULL DEFAULT 'queued',
  request_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_json JSONB,
  model_name TEXT,
  prompt_version TEXT,
  token_input INTEGER,
  token_output INTEGER,
  estimated_cost_usd NUMERIC(12,6),
  attempts INTEGER NOT NULL DEFAULT 0,
  queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT
);

ALTER TABLE campaign_memory_items
  ADD CONSTRAINT campaign_memory_items_created_by_job_fk
  FOREIGN KEY (created_by_job_id) REFERENCES ai_job_runs(id) ON DELETE SET NULL;

CREATE INDEX idx_sessions_campaign_id ON sessions(campaign_id);
CREATE INDEX idx_game_events_session_ts ON game_events(session_id, ts);
CREATE INDEX idx_chat_messages_session_ts ON chat_messages(session_id, ts);
CREATE INDEX idx_transcript_segments_session_start ON transcript_segments(session_id, start_ts);
CREATE INDEX idx_recaps_session ON session_recaps(session_id);
CREATE INDEX idx_memory_campaign_status ON campaign_memory_items(campaign_id, status);
CREATE INDEX idx_ai_job_runs_session_status ON ai_job_runs(session_id, status);


CREATE TABLE api_idempotency_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  idempotency_key UUID NOT NULL,
  endpoint TEXT NOT NULL,
  response_json JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, endpoint, idempotency_key)
);

CREATE INDEX idx_api_idempotency_lookup ON api_idempotency_keys(session_id, endpoint, idempotency_key);
