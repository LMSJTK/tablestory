# Tablestory MVP API Contracts (Phase 1-3)

This document specifies initial request/response contracts for:
1. Session lifecycle + timeline
2. Authoritative dice rolling
3. AI recap generation and memory review

## Conventions

- Base path: `/api/v1`
- Content type: `application/json`
- Auth: bearer token (omitted from examples)
- Date-time format: ISO-8601 with timezone offset
- IDs are UUIDs unless explicitly noted

---

## 1) Session Lifecycle + Timeline

## POST `/campaigns/{campaignId}/sessions`
Create a session record under a campaign.

### Request
```json
{
  "title": "Session 4: The Lighthouse Vault",
  "session_number": 4,
  "scheduled_for": "2026-05-18T18:00:00Z"
}
```

### Response `201`
```json
{
  "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "campaign_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "title": "Session 4: The Lighthouse Vault",
  "session_number": 4,
  "status": "scheduled",
  "scheduled_for": "2026-05-18T18:00:00Z",
  "created_at": "2026-05-12T12:00:00Z"
}
```

## POST `/sessions/{sessionId}/start`
Transition a session to `active`.

### Request
```json
{}
```

### Response `200`
```json
{
  "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "status": "active",
  "started_at": "2026-05-18T18:02:10Z"
}
```

## POST `/sessions/{sessionId}/end`
Transition a session to `completed`.

### Request
```json
{}
```

### Response `200`
```json
{
  "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "status": "completed",
  "ended_at": "2026-05-18T21:37:54Z"
}
```

## GET `/sessions/{sessionId}/timeline?cursor={cursor}&limit={limit}`
Read ordered timeline items derived from `game_events`.

### Response `200`
```json
{
  "items": [
    {
      "id": "77777777-7777-7777-7777-777777777777",
      "session_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "campaign_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "event_type": "session.started",
      "actor_participant_id": "44444444-4444-4444-4444-444444444444",
      "schema_version": "1.0.0",
      "ts": "2026-05-18T18:02:10Z",
      "payload": {
        "title": "The Lighthouse Vault"
      }
    }
  ],
  "next_cursor": null
}
```

---

## 2) Authoritative Dice Rolling

## POST `/sessions/{sessionId}/rolls`
Request a server-authoritative roll and persist both request/resolution events.

### Request
```json
{
  "actor_participant_id": "55555555-5555-5555-5555-555555555555",
  "expression": "2d20kh1+6",
  "context": "skill_check",
  "label": "Investigation",
  "metadata": {
    "character_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "target_dc": 18
  },
  "client_request_id": "d3f6f672-77e7-43f3-9146-a8e098e3deec"
}
```

### Response `201`
```json
{
  "request_event_id": "0c3eb6fb-51c6-4c52-b2d7-628f472ab7bc",
  "resolved_event": {
    "id": "88888888-8888-8888-8888-888888888888",
    "event_type": "dice.roll.resolved",
    "actor_participant_id": "55555555-5555-5555-5555-555555555555",
    "schema_version": "1.0.0",
    "ts": "2026-05-18T19:13:17Z",
    "payload": {
      "expression": "2d20kh1+6",
      "context": "skill_check",
      "rolls": [17, 9],
      "kept_rolls": [17],
      "modifier_total": 6,
      "total": 23,
      "critical": "none"
    }
  }
}
```

### Error `409` (idempotency)
```json
{
  "error": "duplicate_client_request_id",
  "message": "Roll already processed for this client_request_id."
}
```

---

## 3) AI Recaps + Campaign Memory Review

## POST `/sessions/{sessionId}/recap:generate`
Queue recap generation after session end.

### Request
```json
{
  "mode": "standard",
  "prompt_version": "recap-v1"
}
```

### Response `202`
```json
{
  "job_id": "efefefef-efef-efef-efef-efefefefefef",
  "status": "queued"
}
```

## GET `/sessions/{sessionId}/recap`
Fetch latest recap artifact for session.

### Response `200`
```json
{
  "id": "abababab-abab-abab-abab-abababababab",
  "session_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "status": "completed",
  "short_recap_markdown": "The party breached the Lighthouse Vault and found clues linking the disappearances to a tide cult.",
  "long_recap_markdown": "Aria identified hidden sigils ...",
  "source_coverage": {
    "covered_event_ids": [
      "77777777-7777-7777-7777-777777777777",
      "88888888-8888-8888-8888-888888888888"
    ],
    "omitted_high_importance_event_ids": []
  },
  "model_name": "gpt-5.3-mini",
  "prompt_version": "recap-v1",
  "token_input": 1800,
  "token_output": 420,
  "estimated_cost_usd": 0.0245,
  "completed_at": "2026-05-18T21:41:02Z"
}
```

## GET `/campaigns/{campaignId}/memory?status=proposed&limit=50`
List memory items proposed/confirmed for GM review.

### Response `200`
```json
{
  "items": [
    {
      "id": "f0d68d54-37df-4f0f-aa20-f925f336589c",
      "item_type": "npc",
      "canonical_name": "Captain Elira",
      "summary": "Harbormaster who quietly aided the party with key access.",
      "attributes_json": {
        "faction": "Harbor Office"
      },
      "confidence": 0.94,
      "status": "proposed",
      "source_event_ids": [
        "77777777-7777-7777-7777-777777777777"
      ]
    }
  ]
}
```

## PATCH `/campaigns/{campaignId}/memory/{memoryItemId}`
Approve/reject/edit proposed campaign memory.

### Request
```json
{
  "status": "confirmed",
  "summary": "Harbormaster who quietly aided the party and warned of cult activity.",
  "attributes_json": {
    "faction": "Harbor Office",
    "trust_level": "ally"
  }
}
```

### Response `200`
```json
{
  "id": "f0d68d54-37df-4f0f-aa20-f925f336589c",
  "status": "confirmed",
  "updated_at": "2026-05-18T22:01:45Z"
}
```

---

## Error Contract (all endpoints)

```json
{
  "error": "validation_error",
  "message": "Request payload failed validation.",
  "details": [
    {
      "path": "expression",
      "reason": "Unsupported dice syntax"
    }
  ],
  "request_id": "5d9638cd-9a5f-4b11-b8df-aa0145b851c5"
}
```

---

## WebSocket Event Contracts (client-facing)

Channels are scoped by session.

- `game.event.appended`
- `dice.roll.resolved`
- `ai.recap.status`
- `ai.recap.ready`

All events should include:

```json
{
  "event_id": "uuid",
  "session_id": "uuid",
  "ts": "ISO-8601",
  "schema_version": "1.0.0",
  "payload": {}
}
```
