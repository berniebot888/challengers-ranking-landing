#!/usr/bin/env bash
# Genera audios del video de signup de Newman (7 escenas ES) con la voz Chris
# (mismas settings que explainer / welcome).
set -euo pipefail
API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
mkdir -p newman-signup-audio/es

regen() {
  local SC="$1"
  local TEXT_FILE="newman-signup-audio/_scripts/es/scene-${SC}.txt"
  local OUTPUT="newman-signup-audio/es/scene-${SC}.m4a"
  local TMP_MP3="$(mktemp -t newman-${SC}-XXXX).mp3"

  if [ ! -f "$TEXT_FILE" ]; then echo "❌ Missing $TEXT_FILE"; return 1; fi
  local TEXT; TEXT=$(cat "$TEXT_FILE")

  echo "→ scene ${SC}…"

  local JSON; JSON=$(python3 -c "
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
    echo "❌ scene $SC HTTP $HTTP:"; head -c 300 "$TMP_MP3"; echo; rm -f "$TMP_MP3"; return 1
  fi

  afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
  rm -f "$TMP_MP3"
  local DUR; DUR=$(afinfo "$OUTPUT" 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' || echo "?")
  echo "  ✓ ${DUR}s"
}

for SC in 01 02 03 04 05 06 07; do
  regen "$SC"
done

echo ""
echo "✅ Done. 7 audios en newman-signup-audio/es/"
TOTAL=$(afinfo newman-signup-audio/es/scene-*.m4a 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' | awk '{s+=$1} END {print s}')
echo "Total: ~${TOTAL}s"
