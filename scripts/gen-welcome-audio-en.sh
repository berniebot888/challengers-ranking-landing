#!/usr/bin/env bash
# Generate the 8 EN voiceover scenes for the welcome video.
# Voice: Chris (iP95p4xoKVk53GoZ742B) + energetic settings.
set -euo pipefail
API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="welcome-audio/en"
SCRIPT_DIR="welcome-audio/_scripts/en"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() {
  printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"
}

write_scene 01 "Welcome to Challengers Ranking! I'll walk you quickly through the rules, so you can start playing today."

write_scene 02 "First things first: add the app to your phone's home screen. On iPhone, open Safari; on Android, open Chrome. Go to your club's URL, tap the share button, and choose \"Add to Home Screen\". Done — the app now lives on your phone like any other. Then activate notifications. When someone challenges you, it pings your phone instantly. Without notifications, you might miss a match."

write_scene 03 "This is your club's ranking: a ladder from 1 to the last spot. To challenge someone, go to the \"Challenges\" section and tap \"New challenge\". You'll see the list of all players you can challenge: up to 5 positions above you. If you're at number 20, you can go to 15. That gives lower-ranked players a real shot at climbing fast, and pressures the top to defend."

write_scene 04 "Here's the fun part: every new player gets ONE welcome Wild Card. The Wild Card is a special card — it lets you challenge ANY position on the ranking, no restrictions. Yes, you can go for number one from day one. Lost? No worries. Win 3 matches in a row, and you earn another Wild Card. Forever."

write_scene 05 "When you send a challenge, your opponent has 2 days to respond. If they don't reply in those 48 hours, it counts as a rejection and you can go challenge someone else. If they accept, you both have 10 days to play the match. How do you coordinate day, time, and court? Each challenge has its own chat built into the app, no need to jump to WhatsApp or set up a group. Everything stays saved there."

write_scene 06 "Once you've played, either player logs the score from their phone. The other gets a notification to confirm, and the ranking updates instantly. How do positions change? If the winner was behind, they take the loser's spot and the loser drops one position. If the winner was already ahead, no change. Rewards climbing, without punishing those already at the top."

write_scene 07 "Your club also has the Tribuna: a feed where members can share news, club photos, announcements, whatever they want. It's where your club's culture lives, beyond just the ranking."

write_scene 08 "All set. Your first Wild Card is waiting. Who are you going to challenge? Good luck and... let's play."

for SC in 01 02 03 04 05 06 07 08; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t welcome-en-${SC}-XXXX).mp3"
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
echo "✅ Done. 8 EN scenes in $OUT_DIR/"
