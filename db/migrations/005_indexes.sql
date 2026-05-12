CREATE INDEX idx_sessions_campaign_id ON sessions(campaign_id);
CREATE INDEX idx_game_events_session_ts ON game_events(session_id, ts);
CREATE INDEX idx_chat_messages_session_ts ON chat_messages(session_id, ts);
CREATE INDEX idx_transcript_segments_session_start ON transcript_segments(session_id, start_ts);
CREATE INDEX idx_recaps_session ON session_recaps(session_id);
CREATE INDEX idx_memory_campaign_status ON campaign_memory_items(campaign_id, status);
CREATE INDEX idx_ai_job_runs_session_status ON ai_job_runs(session_id, status);
