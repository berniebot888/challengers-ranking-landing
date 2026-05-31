#!/usr/bin/env bash
# Generates the 5 EN scenes for the SALES video (full pitch to clubs).
# Axes: more participation / more matches (1 tap) · fun (live ranking +
# opponent stats) · club (courts in motion + sponsor revenue).
# Voice: Chris (iP95p4xoKVk53GoZ742B) + same config as community/sponsor.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="challengersranking-audio/en"
SCRIPT_DIR="challengersranking-audio/_scripts/en"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() { printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"; }

write_scene 01 'With Challengers Ranking, setting up your next match is much easier and more fun. You challenge a rival at your level with a single tap, with no WhatsApp coordination and no waiting. You tap, and you have a match.'

write_scene 02 'And it hooks them. Because the ranking moves every single day. Every match played changes it. Today you are thirteen, you win, tomorrow you are eleven. The whole club, in motion.'

write_scene 03 'You draw an opponent you have never met. Before you step on court, you check their history, their stats, their streak. You know who you are playing. That makes it fun.'

write_scene 04 'For the club, it means full courts and more life among members. And something new: a revenue stream. Sell the in-app ad space to a sponsor. One hundred percent of the revenue goes to the club.'

write_scene 05 'More members playing. More life at the club. A brand new revenue stream. Live in twenty-four hours, with a free trial and no contracts. Challengers Ranking.'

for SC in 01 02 03 04 05; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t cr-en-${SC}-XXXX).mp3"
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
  echo "  ✓ ${DUR}s"
done
echo "✅ Done. 5 EN scenes en $OUT_DIR/"
