# Prompt maestro — Landing award-level de Challengers Ranking

> Para ejecutar en `/Users/bernardoloitegui/Challengers Landing` (repo con
> auto-deploy al pushear a main). Objetivo doble e inseparable: una landing de
> nivel Awwwards **y** que convierta más trials. Si una animación no empuja la
> historia hacia el CTA, no entra.

## Rol

Sos diseñador/developer de landings premiadas Y responsable de growth de
Challengers Ranking. Cada decisión se evalúa con dos preguntas: ¿eleva el
craft? ¿acerca al visitante a "Creá tu ranking gratis"? Empate no alcanza:
tienen que ganar las dos.

## Concepto creativo: "La Escalada"

**El producto es el héroe. La página ES un ranking vivo.**

Un hilo narrativo único recorre toda la página: un jugador (chip con nombre y
posición) **escala el ranking a medida que el visitante scrollea**. Cada
sección es un beat de su historia: desafía → juegan → carga el 9-6 → el
ranking se mueve EN VIVO → la Tribuna celebra → al llegar a pricing, está
arriba. En desktop, un rail lateral fino muestra su posición trepando —
funciona a la vez como indicador de progreso de scroll. El visitante no lee
qué hace el producto: **lo ve pasar**.

Por qué gana premios: una sola idea continua scroll-driven (no animaciones
sueltas). Por qué convierte: es una demo del producto sin pedir nada.

## Lo que NO se negocia

1. **Stack**: HTML estático + CSS + JS vanilla. Sin frameworks, sin GSAP/Lenis.
   Pinning con `position: sticky` (universal), reveals con IntersectionObserver,
   progreso de escenas con un solo listener rAF, `animation-timeline: view()`
   solo como progressive enhancement. Todo `transform`/`opacity` (compositor).
2. **Performance budget** (medir antes y después): Lighthouse ≥95 en todo,
   LCP < 2.0s, CLS < 0.05, INP < 200ms, peso inicial < 500KB. El hero pasa a
   ser DOM puro (hoy es una foto de Unsplash de 1800px = el LCP): quitarla
   **mejora** LCP. En la fase de perf: Tailwind compilado (CLI) en lugar del
   Play CDN, fuentes subset + `font-display: swap` (ya está).
3. **Accesibilidad**: `prefers-reduced-motion` = experiencia completa estática
   (ya hay patrón en el repo), contraste AA, navegable por teclado, `aria` en
   todo lo interactivo.
4. **Bilingüe**: TODO copy nuevo con `data-en`/`data-es` (sistema existente,
   default visible ES). Nada hardcodeado en un solo idioma.
5. **SEO intacto**: title/meta/JSON-LD/FAQ schema/hreflang no se degradan.
   El contenido textual sigue presente en el DOM (nada de texto solo-canvas).
6. **Shippeable por fases**: nunca una rama larga. Cada fase se pushea sola y
   la página queda mejor que antes. El repo auto-deploya a producción.

## Storyboard sección por sección

| # | Sección | Qué pasa al scrollear | Conversión |
|---|---|---|---|
| 1 | **Hero "El ranking vivo"** | Reemplaza la foto stock por un ladder DOM animado: posiciones que se intercambian solas, toast de desafío que entra, score que se carga. H1 actual (3 beats) + sub nuevo | CTA primario "Creá tu ranking gratis →" + micro risk-reversal debajo ("30 días gratis · sin tarjeta · cancelás cuando quieras") + secundario "Ver demo 60s". Chip social proof "15 → 122 jugadores" |
| 2 | **El problema** | Burbujas de WhatsApp se apilan, se superponen y se desvanecen ("¿alguien para el sábado?" ×40). Caos visual → silencio | "Armar un partido no debería ser un trabajo" |
| 3 | **La Escalada (pinned, centerpiece)** | Teléfono sticky al centro; 5 beats al scrollear: 1-tap desafío → notificación al rival → cargan 6-9 → **el ranking se reordena en vivo** → Tribuna celebra. El chip del jugador sube en el rail | Cada beat con una línea de copy. Beat final: "Todo esto sin que tu staff toque nada" |
| 4 | **Números vivos** | Counters animados al entrar: 15→122 jugadores, partidos/mes, 2 países. Barras tipo race | Reusar el claim defendible ("muchos más partidos") |
| 5 | **Features** | Grid actual con micro-hover (lift + icono animado). Sin scroll-drama: respiro | — |
| 6 | **Tribuna** | Feed que auto-scrollea dentro del mockup | "La comunidad que tu club no sabía que tenía" |
| 7 | **Sponsor que paga el plan** | **Interactivo**: slider "¿cuánto le cobrás a un sponsor local? $X/mes" → "tu plan queda gratis y el club gana $Y/año". El banner se desliza al mockup | El argumento #1 anti-precio, ahora tangible |
| 8 | **Pricing** | Toggle mensual/anual (badge "2 meses gratis"), Starter destacado, hover states | Risk-reversal repetido bajo el CTA |
| 9 | **FAQ + CTA final** | FAQ actual (ya corregida a self-serve). Cierre: el ladder del hero vuelve, completo, con el jugador arriba: "Tu ranking puede estar vivo hoy" | CTA final + UTM |
| — | **Sticky mobile CTA** | Barra inferior con "Crear ranking gratis" que aparece tras pasar el hero | El lever #1 de conversión mobile |

## Copy: principios de conversión

- **Un solo CTA** repetido (trial self-serve). La demo/video es secundaria.
- Sub del hero propuesto: ES *"La app de ranking escalera que llena las
  canchas de tu club — lista hoy, sin que tu staff haga nada."* / EN *"The
  ladder app that fills your club's courts — live today, zero work for your
  staff."*
- Risk-reversal pegado a CADA CTA (gratis/sin tarjeta/cancelás cuando quieras).
- Social proof temprano y específico (15→122; nombrar al club si Bernie
  aprueba — si no, "uno de los clubes más tradicionales de Buenos Aires").
- Todos los CTAs con UTM: `?utm_source=landing&utm_content={hero|pricing|sticky|final}`
  → atribución completa hasta trial y pago (el signup ya persiste UTM cuando
  se implemente P1.7 del doc de growth).

## Medición (antes de tocar nada → F0)

- Baseline Lighthouse (mobile+desktop) + WebPageTest del estado actual.
- Eventos: click de CTA por ubicación, scroll depth 25/50/75/100, play del
  video. (Vercel Analytics o beacon mínimo propio.)
- Éxito = conversión visita→signup-click sube y los CWV no bajan.

## Fases (cada una se shippea sola)

- **F0 · Baseline** — Lighthouse + eventos de medición. Sin cambios visuales.
- **F1 · Conversión quick-wins** (sin rediseño): sub del hero, risk-reversal
  bajo CTAs, sticky mobile CTA, UTMs, toggle anual en pricing. *Un día.*
- **F2 · Motion core**: sistema de reveals + counters + hero "ranking vivo"
  (reemplaza la foto stock → gana LCP). El rail lateral del jugador.
- **F3 · La Escalada**: la sección pinned del teléfono con los 5 beats.
  El centerpiece del premio.
- **F4 · Sponsor interactivo** + Tribuna auto-scroll.
- **F5 · Perf & polish**: Tailwind compilado, subset de fuentes, QA
  cross-browser (Safari/Firefox/Chrome/iOS), a11y audit, diff SEO, Lighthouse
  ≥95 verificado.

## QA checklist (gate de cada fase)

- [ ] Lighthouse ≥95 ×4 categorías (mobile)
- [ ] `prefers-reduced-motion`: página completa y legible sin animación
- [ ] ES y EN: todo el copy nuevo en ambos idiomas
- [ ] Safari + Firefox: pinning y reveals degradan con gracia
- [ ] JSON-LD + FAQ schema validan igual que antes
- [ ] CLS: cero saltos por imágenes/fonts (dims explícitas)
- [ ] CTAs: todos con UTM y midiendo

## Decisiones abiertas (Bernie)

1. ¿Nombramos a **Newman** en la prueba social o seguimos con "uno de los
   clubes más tradicionales de Buenos Aires"? (con nombre convierte más;
   necesita su OK)
2. Hero sin foto de tenis (producto vivo en DOM) — ¿OK conceptual?
3. ¿El slider del sponsor con números editables está OK o preferís claim fijo?
