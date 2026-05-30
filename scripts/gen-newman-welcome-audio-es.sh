#!/usr/bin/env bash
# Genera las 8 escenas ES del WELCOME de Club Newman (onboarding de socio).
# Newman-branded. Escenas 2,3,6,7,8 son idénticas al welcome genérico;
# 1 (bienvenida Newman), 4 (regla del wildcard de Newman) y 5 (formato del
# partido: set a 9, tiebreak 8-8) son específicas del club.
# Voice: Chris (iP95p4xoKVk53GoZ742B) + misma config que el resto.
set -euo pipefail

API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-iP95p4xoKVk53GoZ742B}"
MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"

cd "$(dirname "$0")/.."
OUT_DIR="newman-welcome-audio/es"
SCRIPT_DIR="newman-welcome-audio/_scripts/es"
mkdir -p "$OUT_DIR" "$SCRIPT_DIR"

write_scene() { printf '%s' "$2" > "$SCRIPT_DIR/scene-$1.txt"; }

write_scene 01 '¡Bienvenido al ranking de Club Newman! Te llevo en unos minutos por las reglas, para que arranques a jugar hoy mismo.'
write_scene 02 'Primero lo primero: agregá la app al home screen de tu celular. En iPhone, abrí Safari; en Android, Chrome. Entrá a la URL de tu club, tocá el botón de compartir y elegí "Agregar a inicio". Listo, ahora la app vive en tu celular como cualquier otra. Después, activá las notificaciones. Cuando alguien te desafíe, te va a llegar al toque al celular. Sin notificaciones, te podés perder un partido.'
write_scene 03 'Esto es el ranking de tu club: una escalera del 1 al último. Tocás cualquier nombre y entrás a la ficha del jugador, con su posición, win rate, racha. Para desafiar, tocás "Desafiar" y listo. La regla principal: podés desafiar hasta 5 posiciones por encima tuyo. Si estás en el 20, podés ir al 15. Eso le da chance a los de abajo de subir rápido, y a los de arriba les exige defender.'
write_scene 04 'Acá viene lo bueno. Los que ya estaban en el ranking arrancan en su puesto del seed. Pero si no estabas, y entrás desde el fondo, te llevás una Wild Card de regalo. La Wild Card te deja desafiar a CUALQUIER posición, sin la restricción de los cinco puestos. Sí, podés ir al número uno desde tu primer día. Y si ganás tres partidos al hilo, te ganás otra. Forever.'
write_scene 05 'Cuando mandás un desafío, el rival tiene 2 días para responder. Si no contesta, cuenta como rechazo y podés ir a desafiar a otro. Si acepta, los dos tienen 10 días para jugar. Cada desafío tiene su chat integrado para coordinar día, hora y cancha, sin saltar a WhatsApp. ¿El formato? Un set largo a nueve games. Si llegan ocho iguales, lo define un tiebreak. Y las pelotas las pone quien desafía.'
write_scene 06 'Cuando jugaron, cualquiera de los dos carga el resultado desde el celular. El otro recibe una notificación para confirmar, y el ranking se actualiza al instante. ¿Cómo se mueven las posiciones? Si el ganador iba más atrás, toma la posición del vencido y el vencido baja un puesto. Si el ganador ya iba por delante, no hay cambio. Premia subir, sin castigar al que ya estaba arriba.'
write_scene 07 'Tu club tiene también la Tribuna: un feed donde los socios pueden compartir noticias, fotos del club, anuncios o lo que se les ocurra. Es el lugar donde vive la cultura del club, más allá del ranking.'
write_scene 08 'Listo. Tu primera Wild Card te espera. ¿A quién vas a desafiar? Buena suerte y... a jugar.'

for SC in 01 02 03 04 05 06 07 08; do
  TEXT=$(cat "$SCRIPT_DIR/scene-${SC}.txt")
  TMP="$(mktemp -t nwl-${SC}-XXXX).mp3"
  echo "→ scene ${SC}… (${#TEXT} chars)"
  JSON=$(python3 -c "
import json,sys
print(json.dumps({'text':sys.argv[1],'model_id':sys.argv[2],'voice_settings':{'stability':0.20,'similarity_boost':0.80,'style':0.55,'use_speaker_boost':True}}))
" "$TEXT" "$MODEL")
  HTTP=$(curl -s -w "%{http_code}" -X POST "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
    -H "xi-api-key: ${API_KEY}" -H "Content-Type: application/json" -H "Accept: audio/mpeg" -d "$JSON" -o "$TMP")
  if [ "$HTTP" != "200" ]; then echo "❌ scene $SC HTTP $HTTP"; head -c 300 "$TMP"; rm -f "$TMP"; exit 1; fi
  afconvert -f m4af -d aac "$TMP" "$OUT_DIR/scene-${SC}.m4a"; rm -f "$TMP"
  echo "  ✓"
done
echo "✅ Done. 8 escenas ES en $OUT_DIR/"
