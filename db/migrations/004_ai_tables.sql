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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT campaign_memory_items_created_by_job_fk
    FOREIGN KEY (created_by_job_id) REFERENCES ai_job_runs(id) ON DELETE SET NULL
);
