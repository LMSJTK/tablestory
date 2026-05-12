CREATE TABLE api_idempotency_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  idempotency_key UUID NOT NULL,
  endpoint TEXT NOT NULL,
  response_json JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, endpoint, idempotency_key)
);

CREATE INDEX idx_api_idempotency_lookup
  ON api_idempotency_keys(session_id, endpoint, idempotency_key);
