#!/usr/bin/env bash
# Generate the 5 ES voiceover scenes for the COMMUNITY pitch video.
# Audiencia: decision-makers de clubes (presidentes, comisión).
# Tagline: "Más partidos, más club".
# Voice: Chris (iP95p4xoKVk53GoZ742B) + same energetic settings as welcome
# (stability 0.20, similarity 0.80, style 0.55) — para mantener consistencia
# con los otros videos.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="community-audio/es"
SCRIPT_DIR="community-audio/_scripts/es"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() {
  printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"
}

write_scene 01 'Tu club tiene socios que quieren jugar más, pero coordinar un partido es un dolor de cabeza. WhatsApp se desordena, nadie encuentra rival del mismo nivel. Al final, los mismos cuatro de siempre se cruzan en cancha.'

write_scene 02 'Con Challengers Ranking, un socio toca Nuevo Desafío, elige a un rival del ranking, y toca Desafiar. Al otro le llega una notificación al instante. Sin grupos. Sin coordinar a tres bandas.'

write_scene 03 'De golpe, los socios juegan con gente que nunca hubieran enfrentado. El número treinta y tres desafía al veintiocho. El nuevo se mide con el veterano. El ranking en vivo es la excusa que al club le faltaba para que la cancha no pare nunca.'

write_scene 04 'Los clubes que ya lo usan están viendo tres, cuatro, cinco veces más partidos por mes. Partidos que antes no se hubieran jugado. Comunidad que antes no existía. Todo desde el celular, en vivo.'

write_scene 05 'Sin instalar nada del App Store. Listo en veinticuatro horas. Probalo gratis con tu club, sin compromiso. Challengers Ranking: más partidos, más club.'

for SC in 01 02 03 04 05; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t community-es-${SC}-XXXX).mp3"
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
echo "✅ Done. 5 ES scenes in $OUT_DIR/"
