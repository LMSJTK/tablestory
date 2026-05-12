-- Demo data for investor walkthrough
WITH inserted_users AS (
  INSERT INTO users (id, email, display_name)
  VALUES
    ('11111111-1111-1111-1111-111111111111', 'gm@tablestory.dev', 'Morgan the GM'),
    ('22222222-2222-2222-2222-222222222222', 'player1@tablestory.dev', 'Aria Stormblade'),
    ('33333333-3333-3333-3333-333333333333', 'player2@tablestory.dev', 'Bram Ironroot')
  ON CONFLICT (email) DO NOTHING
  RETURNING id
), inserted_campaign AS (
  INSERT INTO campaigns (id, name, description, created_by)
  VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'Ashes of Blacktide',
    'A coastal mystery where the party investigates disappearances and cult activity.',
    '11111111-1111-1111-1111-111111111111'
  )
  ON CONFLICT DO NOTHING
  RETURNING id
), inserted_members AS (
  INSERT INTO campaign_members (campaign_id, user_id, role)
  VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'gm'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'player'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'player')
  ON CONFLICT DO NOTHING
  RETURNING campaign_id
), inserted_session AS (
  INSERT INTO sessions (id, campaign_id, title, session_number, started_at, ended_at, status, created_by)
  VALUES (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'Session 4: The Lighthouse Vault',
    4,
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '30 minutes',
    'completed',
    '11111111-1111-1111-1111-111111111111'
  )
  ON CONFLICT DO NOTHING
  RETURNING id
), inserted_participants AS (
  INSERT INTO session_participants (id, session_id, user_id, kind, display_name, joined_at)
  VALUES
    ('44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'human', 'Morgan the GM', NOW() - INTERVAL '2 hours'),
    ('55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'human', 'Aria Stormblade', NOW() - INTERVAL '2 hours'),
    ('66666666-6666-6666-6666-666666666666', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333', 'human', 'Bram Ironroot', NOW() - INTERVAL '2 hours')
  ON CONFLICT DO NOTHING
  RETURNING id
)
INSERT INTO game_events (id, campaign_id, session_id, event_type, actor_participant_id, payload_json, ts)
VALUES
  ('77777777-7777-7777-7777-777777777777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'session.started', '44444444-4444-4444-4444-444444444444', '{"title":"The Lighthouse Vault"}', NOW() - INTERVAL '2 hours'),
  ('88888888-8888-8888-8888-888888888888', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'dice.roll.resolved', '55555555-5555-5555-5555-555555555555', '{"expression":"1d20+6","context":"investigation","rolls":[17],"total":23}', NOW() - INTERVAL '90 minutes'),
  ('99999999-9999-9999-9999-999999999999', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'quest.updated', '44444444-4444-4444-4444-444444444444', '{"quest":"Find the missing harbor children","status":"advanced"}', NOW() - INTERVAL '45 minutes')
ON CONFLICT DO NOTHING;

INSERT INTO session_recaps (
  id, campaign_id, session_id, status, short_recap_markdown, long_recap_markdown, source_coverage_json, model_name, prompt_version, token_input, token_output, estimated_cost_usd, completed_at
)
VALUES (
  'abababab-abab-abab-abab-abababababab',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'completed',
  'The party breached the Lighthouse Vault and found clues linking the disappearances to a tide cult.',
  'Aria identified hidden sigils in the lighthouse vault while Bram held off animated guardians. The party recovered a salt-stained ledger pointing to a moonlit rendezvous near the breakwater. They ended the session with a clear lead and a worried sense that someone inside the harbor office is complicit.',
  '{"covered_event_ids":["77777777-7777-7777-7777-777777777777","88888888-8888-8888-8888-888888888888","99999999-9999-9999-9999-999999999999"],"omitted_high_importance_event_ids":[]}',
  'gpt-5.3-mini',
  'recap-v1',
  1800,
  420,
  0.024500,
  NOW() - INTERVAL '29 minutes'
)
ON CONFLICT DO NOTHING;
