#!/usr/bin/env bash
# Regenerate ALL welcome audios (ES + EN) with explainer-matching settings.
# Voice: Chris (iP95p4xoKVk53GoZ742B)
# Settings: stability 0.30, similarity 0.80, style 0.45 (same as explainer v3 production)
#
# Why these settings: lower stability (0.20) makes the voice more variable but
# sometimes "less confident". The explainer's 0.30 + 0.45 lands a crisp "podcast
# announcer" energy — that's what we want for the welcome too.
set -euo pipefail
API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."

regen() {
  local LANG="$1" SC="$2"
  local TEXT_FILE="welcome-audio/_scripts/${LANG}/scene-${SC}.txt"
  local OUTPUT="welcome-audio/${LANG}/scene-${SC}.m4a"
  local TMP_MP3="$(mktemp -t welcome-${LANG}-${SC}-XXXX).mp3"

  if [ ! -f "$TEXT_FILE" ]; then
    echo "❌ Missing $TEXT_FILE"; return 1
  fi
  local TEXT
  TEXT=$(cat "$TEXT_FILE")

  echo "→ ${LANG} scene ${SC}…"

  local JSON
  JSON=$(python3 -c "
import json, sys
print(json.dumps({
  'text': sys.argv[1], 'model_id': sys.argv[2],
  'voice_settings': {'stability': 0.30, 'similarity_boost': 0.80, 'style': 0.45, 'use_speaker_boost': True}
}))
" "$TEXT" "$MODEL")

  local HTTP
  HTTP=$(curl -s -w "%{http_code}" -X POST \
    "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${API_KEY}" -H "Content-Type: application/json" \
    -H "Accept: audio/mpeg" -d "$JSON" -o "$TMP_MP3")

  if [ "$HTTP" != "200" ]; then
    echo "❌ ${LANG} scene $SC HTTP $HTTP:"; head -c 300 "$TMP_MP3"; echo; rm -f "$TMP_MP3"; return 1
  fi

  afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
  rm -f "$TMP_MP3"
  local DUR
  DUR=$(afinfo "$OUTPUT" 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' || echo "?")
  echo "  ✓ ${DUR}s"
}

for LANG in es en; do
  for SC in 01 02 03 04 05 06 07 08; do
    regen "$LANG" "$SC"
  done
done

echo "✅ Done. 16 audios regenerated (8 ES + 8 EN) with explainer-matching settings"
