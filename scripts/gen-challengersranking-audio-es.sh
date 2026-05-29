#!/usr/bin/env bash
# Genera las 5 escenas ES del SALES video (pitch completo a clubes).
# Ejes: más participación / más partidos (1 tap) · diversión (ranking vivo
# + stats del rival) · club (canchas en movimiento + revenue del sponsor).
# Voice: Chris (iP95p4xoKVk53GoZ742B) + misma config que community/sponsor.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="challengersranking-audio/es"
SCRIPT_DIR="challengersranking-audio/_scripts/es"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() { printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"; }

write_scene 01 'En tu club hay socios que quieren jugar más. Con Challengers Ranking, desafiar a alguien de tu nivel es un solo tap. Sin coordinar por WhatsApp, sin esperar. Tocás, y ya tenés partido.'

write_scene 02 'Y engancha. Porque el ranking se mueve todos los días. Cada partido que se juega lo cambia. Hoy estás trece, ganás, y mañana estás once. El club entero, en movimiento.'

write_scene 03 'Te toca un rival que no conocés. Antes de salir a la cancha, mirás su historial, sus estadísticas, su racha. Sabés contra quién jugás. Eso lo hace divertido.'

write_scene 04 'Para el club, son las canchas llenas, más vida entre los socios. Y algo nuevo: una fuente de ingresos. Vendele el espacio publicitario de la app a un sponsor. El cien por ciento del revenue es del club.'

write_scene 05 'Más socios jugando. Más vida en el club. Una nueva fuente de ingresos. Listo en veinticuatro horas, con free trial y sin contratos. Challengers Ranking.'

for SC in 01 02 03 04 05; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t cr-es-${SC}-XXXX).mp3"
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
  echo "  ✓ ${DUR}s"
done
echo "✅ Done. 5 ES scenes en $OUT_DIR/"
