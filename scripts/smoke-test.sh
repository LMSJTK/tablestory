#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://localhost:3000/api/v1}"
CAMPAIGN_ID="${CAMPAIGN_ID:-aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa}"
PARTICIPANT_ID="${PARTICIPANT_ID:-55555555-5555-5555-5555-555555555555}"

uuidgen_fallback() {
  if command -v uuidgen >/dev/null 2>&1; then uuidgen; else cat /proc/sys/kernel/random/uuid; fi
}

ROLL_REQUEST_ID="$(uuidgen_fallback)"

curl -sS -X POST "$API_BASE/campaigns/$CAMPAIGN_ID/sessions" \
  -H 'content-type: application/json' \
  -H 'x-user-id: 11111111-1111-1111-1111-111111111111' \
  -d '{"title":"Smoke Session","session_number":99}' >/tmp/tablestory-create-session.json

NEW_SESSION_ID="$(node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('/tmp/tablestory-create-session.json','utf8'));console.log(j.id)")"

curl -sS -X POST "$API_BASE/sessions/$NEW_SESSION_ID/start" >/tmp/tablestory-start-session.json

curl -sS -X POST "$API_BASE/sessions/$NEW_SESSION_ID/rolls" \
  -H 'content-type: application/json' \
  -d "{\"actor_participant_id\":\"$PARTICIPANT_ID\",\"expression\":\"1d20+5\",\"context\":\"skill_check\",\"client_request_id\":\"$ROLL_REQUEST_ID\"}" >/tmp/tablestory-roll.json

curl -sS -X POST "$API_BASE/sessions/$NEW_SESSION_ID/end" >/tmp/tablestory-end-session.json

curl -sS -X POST "$API_BASE/sessions/$NEW_SESSION_ID/recap:generate" \
  -H 'content-type: application/json' \
  -d '{"mode":"standard","prompt_version":"recap-v1"}' >/tmp/tablestory-recap-queue.json

echo "Smoke flow complete for session: $NEW_SESSION_ID"
