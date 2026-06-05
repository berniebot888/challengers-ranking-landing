#!/usr/bin/env bash
# Generate the 5 EN voiceover scenes for the COMMUNITY pitch video.
# Audience: club decision-makers (presidents, committee).
# Tagline: "More matches, more club".
# Voice: Chris (iP95p4xoKVk53GoZ742B) + same energetic settings as welcome.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="community-audio/en"
SCRIPT_DIR="community-audio/_scripts/en"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() {
  printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"
}

write_scene 01 "Your club has members who want to play more, but setting up a match is a headache. WhatsApp goes off the rails, nobody finds an opponent at their level. In the end, the same four players keep crossing paths on court."

write_scene 02 'With Challengers Ranking, a member taps New Challenge, picks an opponent from the ranking, and taps Challenge. The other gets a notification instantly. No groups. No three-way coordination.'

write_scene 03 "Suddenly, members play with people they would have never faced. Number thirty-three challenges twenty-eight. The new guy goes up against the veteran. The live ranking is the excuse your club needed to keep the courts moving non-stop."

write_scene 04 "Clubs already using it see many more matches per month. Matches that wouldn't have happened otherwise. Community that didn't exist before. All from a phone, live."

write_scene 05 "No App Store install. Live in twenty-four hours. Try it free with your club, no strings attached. Challengers Ranking: more matches, more club."

for SC in 01 02 03 04 05; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t community-en-${SC}-XXXX).mp3"
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
echo "✅ Done. 5 EN scenes in $OUT_DIR/"
