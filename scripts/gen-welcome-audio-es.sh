#!/usr/bin/env bash
# Generate the 8 ES voiceover scenes for the welcome video.
# Voice: Chris (iP95p4xoKVk53GoZ742B) + energetic settings
# (stability 0.20, similarity 0.80, style 0.55).
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="welcome-audio/es"
SCRIPT_DIR="welcome-audio/_scripts/es"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

# Write each scene's text to its own file (avoids bash 3.2 array issues + safer
# quoting for long Spanish text with accents).
write_scene() {
  local sc="$1"
  local txt="$2"
  printf '%s' "$txt" > "$SCRIPT_DIR/scene-${sc}.txt"
}

write_scene 01 '¡Bienvenido a Challengers Ranking! Te llevo en 4 minutos por las reglas, para que arranques a jugar hoy mismo.'

write_scene 02 'Primero lo primero: agregá la app al home screen de tu celular. En iPhone, abrí Safari; en Android, Chrome. Entrá a la URL de tu club, tocá el botón de compartir y elegí "Agregar a inicio". Listo, ahora la app vive en tu celular como cualquier otra. Después, activá las notificaciones. Cuando alguien te desafíe, te va a llegar al toque al celular. Sin notificaciones, te podés perder un partido.'

write_scene 03 'Esto es el ranking de tu club: una escalera del 1 al último. Tocás cualquier nombre y entrás a la ficha del jugador, con su posición, win rate, racha. Para desafiar, tocás "Desafiar" y listo. La regla principal: podés desafiar hasta 5 posiciones por encima tuyo. Si estás en el 20, podés ir al 15. Eso le da chance a los de abajo de subir rápido, y a los de arriba les exige defender.'

write_scene 04 'Acá viene lo bueno: cada jugador nuevo recibe UNA Wild Card de bienvenida. La Wild Card es una carta especial: te deja desafiar a CUALQUIER posición del ranking, sin restricciones. Sí, podés ir al número uno desde tu primer día. ¿Perdiste? Tranqui. Si ganás 3 partidos al hilo, te ganás otra Wild Card. Forever.'

write_scene 05 'Cuando mandás un desafío, el rival tiene 2 días para responder. Si en esas 48 horas no contesta, cuenta como rechazo y vos podés ir a desafiar a otro. Si acepta, los dos tienen 10 días para jugar el partido. ¿Cómo coordinan día, horario y cancha? Cada desafío tiene su propio chat integrado dentro de la app, no hace falta saltar a WhatsApp ni armar un grupo. Toda la conversación queda guardada ahí.'

write_scene 06 'Cuando jugaron, cualquiera de los dos carga el resultado desde el celular. El otro recibe una notificación para confirmar, y el ranking se actualiza al instante. ¿Cómo se mueven las posiciones? Si el ganador iba más atrás, toma la posición del vencido y el vencido baja un puesto. Si el ganador ya iba por delante, no hay cambio. Premia subir, sin castigar al que ya estaba arriba.'

write_scene 07 'Tu club tiene también la Tribuna: un feed donde los socios pueden compartir noticias, fotos del club, anuncios o lo que se les ocurra. Es el lugar donde vive la cultura del club, más allá del ranking.'

write_scene 08 'Listo. Tu primera Wild Card te espera. ¿A quién vas a desafiar? Buena suerte y... a jugar.'

# Iterate scenes 01-08 explicitly
for SC in 01 02 03 04 05 06 07 08; do
  TEXT_FILE="$SCRIPT_DIR/scene-${SC}.txt"
  OUTPUT="$OUT_DIR/scene-${SC}.m4a"
  TMP_MP3="$(mktemp -t welcome-${SC}-XXXX).mp3"

  if [ ! -f "$TEXT_FILE" ]; then
    echo "❌ Missing $TEXT_FILE"; exit 1
  fi

  TEXT=$(cat "$TEXT_FILE")
  echo "→ Scene ${SC}… (${#TEXT} chars)"

  JSON=$(python3 -c "
import json, sys
print(json.dumps({
  'text': sys.argv[1],
  'model_id': sys.argv[2],
  'voice_settings': {
    'stability': 0.20,
    'similarity_boost': 0.80,
    'style': 0.55,
    'use_speaker_boost': True
  }
}))
" "$TEXT" "$MODEL")

  HTTP=$(curl -s -w "%{http_code}" -X POST \
    "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H "Accept: audio/mpeg" \
    -d "$JSON" \
    -o "$TMP_MP3")

  if [ "$HTTP" != "200" ]; then
    echo "❌ Scene $SC failed HTTP $HTTP:"
    cat "$TMP_MP3" | head -3
    rm -f "$TMP_MP3"
    exit 1
  fi

  afconvert -f m4af -d aac "$TMP_MP3" "$OUTPUT"
  rm -f "$TMP_MP3"

  DUR=$(afinfo "$OUTPUT" 2>&1 | grep "estimated duration" | sed 's/.*: //;s/ sec//' || echo "?")
  SZ=$(stat -f%z "$OUTPUT")
  echo "  ✓ $OUTPUT  ${SZ}b  ${DUR}s"
done

echo ""
echo "✅ Done. 8 ES scenes generated in $OUT_DIR/"
afinfo "$OUT_DIR"/scene-*.m4a 2>&1 | grep -E "scene-|estimated duration" | head -30
