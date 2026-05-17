#!/usr/bin/env bash
# Regenerate explainer-audio/es/scene-02.m4a using ElevenLabs API.
#
# Original audio mispronounced "app" as "ape" (English). Fix: rewrite
# using "aplicación en tu teléfono" — natural Spanish, no ambiguity,
# adds device context.
#
# Uses the same voice clone + settings as the original production batch
# so the regenerated audio matches the rest of the explainer in tone.
#
# Usage:
#   ELEVENLABS_API_KEY=sk_... bash scripts/regen-scene-02-es.sh

set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY env var}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"      # Chris (premade — used in Voiceover v3 final)
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."

OUTPUT="explainer-audio/es/scene-02.m4a"
BACKUP="explainer-audio/es/scene-02.OLD.m4a"
TMP_MP3="$(mktemp -t scene-02-XXXX).mp3"

TEXT="Challengers Ranking convierte la escalera de tu club en una aplicación en tu teléfono. Tus socios desafían, juegan, suben en el ranking. Vos ves todo en tiempo real desde un dashboard. Sin instalar nada del App Store. Listo en 24 horas."

echo "→ Backing up current scene-02 to $BACKUP"
[ -f "$OUTPUT" ] && cp "$OUTPUT" "$BACKUP"

# Build JSON payload via python (safer escaping than bash sed)
JSON=$(python3 -c "import json,sys; print(json.dumps({'text': sys.argv[1], 'model_id': sys.argv[2], 'voice_settings': {'stability': 0.30, 'similarity_boost': 0.80, 'style': 0.45, 'use_speaker_boost': True}}))" "$TEXT" "$MODEL")

echo "→ Calling ElevenLabs TTS (voice=$VOICE_ID, model=$MODEL)"
HTTP=$(curl -s -w "%{http_code}" -X POST \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
  -H "xi-api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: audio/mpeg" \
  -d "$JSON" \
  -o "$TMP_MP3")

if [ "$HTTP" != "200" ]; then
  echo "❌ ElevenLabs returned HTTP $HTTP. Body:"
  cat "$TMP_MP3"
  rm -f "$TMP_MP3"
  exit 1
fi

SZ=$(stat -f%z "$TMP_MP3")
echo "  Got MP3 ($SZ bytes)"

echo "→ Converting MP3 → M4A with afconvert (AAC in MP4 container)"
afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
rm -f "$TMP_MP3"

NEW_SZ=$(stat -f%z "$OUTPUT")
echo ""
echo "✅ Done. New $OUTPUT generated ($NEW_SZ bytes)"
echo "   Old version saved at $BACKUP (delete after verifying)."
echo ""
echo "→ Duration check:"
afinfo "$OUTPUT" 2>&1 | grep "estimated\|duration"
