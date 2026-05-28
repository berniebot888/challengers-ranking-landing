#!/usr/bin/env bash
# Generate the 3 ES voiceover scenes for the SPONSOR REVENUE pitch video.
# Audiencia: decision-makers de clubes (presidentes, comisión).
# Foco: el ranking como herramienta para generar ingresos via sponsor.
# Voice: Chris (iP95p4xoKVk53GoZ742B) + misma config que community/welcome.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="sponsor-audio/es"
SCRIPT_DIR="sponsor-audio/_scripts/es"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() {
  printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"
}

write_scene 01 'El ranking de tu club tiene un espacio destacado. Un banner publicitario que ven todos los socios cada vez que entran a la app.'

write_scene 02 'Vendele ese espacio a una marca local. Tu raqueta sponsor, un banco, el comercio del barrio. El sponsor llega a tus socios, y el club se lleva el cien por ciento del revenue.'

write_scene 03 'Generá comunidad. Generá valor para el club. Generá valor para tu sponsor. Listo en veinticuatro horas, free trial sin contratos. Challengers Ranking.'

for SC in 01 02 03; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t sponsor-es-${SC}-XXXX).mp3"
  TEXT=$(cat "$TEXT_FILE")
  echo "→ ES scene ${SC}… (${#TEXT} chars)"

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
    echo "❌ ES scene $SC HTTP $HTTP:"; head -c 300 "$TMP_MP3"; echo; rm -f "$TMP_MP3"; exit 1
  fi

  afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
  rm -f "$TMP_MP3"
  DUR=$(afinfo "$OUTPUT" 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' || echo "?")
  SZ=$(stat -f%z "$OUTPUT")
  echo "  ✓ ${SZ}b  ${DUR}s"
done
echo "✅ Done. 3 ES scenes in $OUT_DIR/"
