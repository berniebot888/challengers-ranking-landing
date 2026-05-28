#!/usr/bin/env bash
# Generate the 3 EN voiceover scenes for the SPONSOR REVENUE pitch video.
# Audience: club decision-makers (presidents, committee).
# Focus: the ranking as a tool to generate revenue via a sponsor.
# Voice: Chris (iP95p4xoKVk53GoZ742B) + same config as community/welcome.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="sponsor-audio/en"
SCRIPT_DIR="sponsor-audio/_scripts/en"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() {
  printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"
}

write_scene 01 "Your club's ranking has a featured space. A sponsor banner every member sees each time they open the app."

write_scene 02 "Sell that space to a local brand. Your racquet sponsor, a bank, the shop next door. The sponsor reaches your members, and the club keeps one hundred percent of the revenue."

write_scene 03 "No App Store install. Live in twenty-four hours. Turn the ranking into a new revenue stream for your club. Challengers Ranking."

for SC in 01 02 03; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t sponsor-en-${SC}-XXXX).mp3"
  TEXT=$(cat "$TEXT_FILE")
  echo "→ EN scene ${SC}… (${#TEXT} chars)"

  JSON=$(python3 -c "
import json, sys
print(json.dumps({
  'text': sys.argv[1],
  'model_id': sys.argv[2],
  'voice_settings': {'stability': 0.20, 'similarity_boost': 0.80, 'style': 0.55, 'use_speaker_boost': True}
}))
" "$TEXT" "$MODEL")

  HTTP=$(curl -s -w "%{http_code}" -X POST \
    "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${API_KEY}" -H "Content-Type: application/json" \
    -H "Accept: audio/mpeg" -d "$JSON" -o "$TMP_MP3")

  if [ "$HTTP" != "200" ]; then
    echo "❌ EN scene $SC HTTP $HTTP:"; head -c 300 "$TMP_MP3"; echo; rm -f "$TMP_MP3"; exit 1
  fi

  afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
  rm -f "$TMP_MP3"
  DUR=$(afinfo "$OUTPUT" 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' || echo "?")
  SZ=$(stat -f%z "$OUTPUT")
  echo "  ✓ ${SZ}b  ${DUR}s"
done
echo "✅ Done. 3 EN scenes in $OUT_DIR/"
