export const sql = {
  createSession: `
    INSERT INTO sessions (campaign_id, title, session_number, scheduled_for, status, created_by)
    VALUES ($1, $2, $3, $4, 'scheduled', $5)
    RETURNING id, campaign_id, title, session_number, status, scheduled_for, created_at;
  `,
  startSession: `
    UPDATE sessions
    SET status = 'active', started_at = NOW(), updated_at = NOW()
    WHERE id = $1 AND status = 'scheduled'
    RETURNING id, status, started_at;
  `,
  endSession: `
    UPDATE sessions
    SET status = 'completed', ended_at = NOW(), updated_at = NOW()
    WHERE id = $1 AND status = 'active'
    RETURNING id, status, ended_at;
  `,
  getSessionStatus: `SELECT id, campaign_id, status FROM sessions WHERE id = $1;`,
  insertGameEvent: `
    INSERT INTO game_events (
      campaign_id, session_id, event_type, actor_participant_id, payload_json, schema_version, ts
    ) VALUES ($1, $2, $3, $4, $5::jsonb, '1.0.0', NOW())
    RETURNING id, campaign_id, session_id, event_type, actor_participant_id, schema_version, ts, payload_json;
  `,
  getSessionTimeline: `
    SELECT id, campaign_id, session_id, event_type, actor_participant_id, schema_version, ts, payload_json
    FROM game_events
    WHERE session_id = $1
    ORDER BY ts ASC
    LIMIT $2;
  `,
  findIdempotentResponse: `
    SELECT response_json
    FROM api_idempotency_keys
    WHERE session_id = $1 AND endpoint = $2 AND idempotency_key = $3;
  `,
  saveIdempotentResponse: `
    INSERT INTO api_idempotency_keys (session_id, idempotency_key, endpoint, response_json)
    VALUES ($1, $2, $3, $4::jsonb)
    ON CONFLICT (session_id, endpoint, idempotency_key) DO NOTHING;
  `,
  queueRecapJob: `
    INSERT INTO ai_job_runs (campaign_id, session_id, job_type, status, request_json, prompt_version)
    VALUES ($1, $2, 'session_recap', 'queued', $3::jsonb, $4)
    RETURNING id, status;
  `,
  getLatestRecap: `
    SELECT id, session_id, status, short_recap_markdown, long_recap_markdown,
      source_coverage_json, model_name, prompt_version, token_input, token_output,
      estimated_cost_usd, completed_at
    FROM session_recaps
    WHERE session_id = $1
    ORDER BY created_at DESC
    LIMIT 1;
  `
};
