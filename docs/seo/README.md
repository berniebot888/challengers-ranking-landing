# SEO context — Challengers Ranking

> Carpeta self-contained para que un auditor SEO arranque sin tener que
> explorar dos repos. Todo lo que necesitás está acá o referenciado con
> paths absolutos.

---

## 1. Producto en una frase

**Challengers Ranking** — sistema de ranking de escalera (ladder) para
clubes de tenis, pádel, pickleball y squash. PWA multi-tenant. Cada club
tiene su propio subdominio.

---

## 2. Arquitectura: 3 superficies, 3 estrategias de SEO distintas

| Surface | Hosting | Repo | SEO target |
|---|---|---|---|
| `www.challengersranking.online` | Vercel CDN (HTML estático) | `Challengers Landing/` | **Target principal de SEO orgánico**. Quiere rankear por queries de adquisición. |
| `app.challengersranking.online` | Vercel (Next.js) | `Challengers Demo/` | Entry genérico — solo accesible para no-logueados. **Quizás indexar `/signup` solamente**. Login/etc. no aporta SEO. |
| `*.challengersranking.online` (`tca`, `demo`, `<club>`) | Vercel (mismo Next.js multi-tenant) | `Challengers Demo/` | Subdominios por cliente. **Probablemente NO indexar** (data privada del club). Excepción: `/posts/[clubId]/[postId]` (página pública shareable de un post). |

### Multi-tenant routing
El middleware (`Challengers Demo/middleware.ts`) lee el subdominio del
host y mete `clubId` en un header `x-club-id` que el RootLayout consume.
- `tca.*` → cliente real (TCA)
- `demo.*` → club demo público con jugadores fake (Federer, etc.)
- `app.*` → entry genérico, sin contexto de club; redirige a `/login`
- `super.*` → admin interno (no indexar nunca)
- `r.*` → redirector

---

## 3. Repos y paths absolutos

```
LANDING (HTML estático — SEO target principal)
└── /Users/bernardoloitegui/Challengers Landing/
    ├── index.html                    ← landing (1700+ líneas, todas las secciones SEO acá)
    ├── promo.html                    ← video promocional embebido en landing
    ├── robots.txt                    ← actual (ver §6)
    ├── sitemap.xml                   ← actual (ver §6)
    ├── og-image.png                  ← OG banner 1200×630 brand v2
    ├── favicon.png                   ← 32px
    ├── brand-kit/                    ← assets del brand (SVG + PNG)
    │   ├── favicon.svg
    │   ├── lockup-horizontal-white.svg
    │   ├── badge-orange.svg
    │   └── png/
    │       ├── icon-app-orange-{16,32,64,128,192,256,512,1024}.png
    │       ├── badge-orange-1024.png
    │       └── social-banner-og-1200x630.png
    └── docs/seo/                     ← ESTÁ CARPETA (este README)

APP (Next.js multi-tenant)
└── /Users/bernardoloitegui/Challengers Demo/
    ├── middleware.ts                 ← multi-tenant subdomain routing
    ├── app/layout.tsx                ← RootLayout, generateMetadata global por club
    ├── app/posts/[clubId]/[postId]/page.tsx  ← Server Component con OG dinámico (página pública shareable)
    ├── app/api/manifest/route.ts     ← Manifest PWA dinámico por club
    ├── public/manifest.json          ← Manifest PWA estático fallback
    ├── public/brand/                 ← Mismo brand-kit duplicado para subdominios
    └── public/sw.js                  ← Service Worker (cache-first /_next/static, SWR HTML)
```

---

## 4. Estado actual del SEO (landing)

### `<head>` actual de `index.html`

```html
<title>Challengers Ranking — Tennis, Padel, Pickleball &amp; Squash Ladder App for Clubs</title>
<meta name="description" content="The ladder ranking app for racket sports clubs. Tennis, padel, pickleball and squash. Live rankings, automated challenges, match history, and a community feed — more matches, more participation, happier members. App de ranking de escalera para clubes de tenis, pádel, pickleball y squash." />
<meta name="keywords" content="tennis ladder app, padel ladder app, pickleball ladder app, squash ladder app, app ranking tenis, app ranking padel, ranking pádel club, ranking pickleball, ranking squash, club tennis app, club padel app, escalera tenis, escalera pádel, racket sports ladder software" />
<meta name="robots" content="index, follow" />
<link rel="canonical" href="https://challengersranking.online/" />

<!-- hreflang — DECISIÓN ACTUAL: same URL serves EN by default, ES via geo-detection -->
<link rel="alternate" hreflang="en"        href="https://challengersranking.online/" />
<link rel="alternate" hreflang="es"        href="https://challengersranking.online/" />
<link rel="alternate" hreflang="x-default" href="https://challengersranking.online/" />

<!-- Open Graph -->
<meta property="og:type"              content="website" />
<meta property="og:url"               content="https://challengersranking.online/" />
<meta property="og:site_name"         content="Challengers Ranking" />
<meta property="og:title"             content="Challengers Ranking — Tennis Ladder App for Clubs" />
<meta property="og:description"       content="The tennis ladder app that drives real member engagement. Live rankings, automated challenges, and a community feed that keeps members coming back." />
<meta property="og:image"             content="https://challengersranking.online/og-image.png?v=3" />
<meta property="og:image:width"       content="1200" />
<meta property="og:image:height"      content="630" />
<meta property="og:locale"            content="en_US" />
<meta property="og:locale:alternate"  content="es_AR" />

<!-- Twitter Card -->
<meta name="twitter:card"        content="summary_large_image" />
<meta name="twitter:title"       content="Challengers Ranking — Tennis Ladder App for Clubs" />
<meta name="twitter:description" content="The tennis ladder app that drives real member engagement. Live rankings, automated challenges, and a community feed that keeps members coming back." />
<meta name="twitter:image"       content="https://challengersranking.online/og-image.png?v=3" />

<meta name="theme-color" content="#C8451C" />
<link rel="sitemap" type="application/xml" href="/sitemap.xml" />
```

### JSON-LD schemas (3 bloques en el `<head>`)

1. **`SoftwareApplication`** (app/index.html línea ~36)
   - applicationCategory, operatingSystem, offers, screenshot, keywords
2. **`Organization`** (línea ~69)
   - name, url, logo, description, contactPoint, sameAs
3. **`FAQPage`** (línea ~86)
   - 8 FAQ items con preguntas y respuestas (mezcla ES/EN — auditar)

### Bilingüe ES/EN
**Decisión actual**: mismo URL para ambos idiomas, swap de innerHTML via
`[data-en]` / `[data-es]` attrs con JS. Locale auto-detectado:
1. `localStorage('cr-lang')` (override manual del user)
2. Geo IP → AR/UY/CL/MX/etc. = ES, resto = EN
3. Default EN

**Implicancias SEO** (a auditar):
- Google ve solo el contenido inicial server-side (¿es ES o EN?)
- hreflang apuntando al mismo URL es válido pero subóptimo
- Alternativa: `/es/` y `/en/` con redirects geo — más trabajo pero mejor para multi-language SEO

---

## 5. Estado actual del SEO (app)

### `app/layout.tsx` — generateMetadata global por club
```ts
export async function generateMetadata(): Promise<Metadata> {
  const clubId = headers().get('x-club-id') ?? 'demo';
  const club = await getClubConfig(clubId);
  return {
    title: club.name,
    description: `${club.name} — Ranking de escalera en vivo para clubes de raqueta`,
    manifest: '/api/manifest',
    appleWebApp: { capable: true, title: club.shortName, statusBarStyle: 'default' },
    icons: { /* SVG + PNG fallback */ },
    openGraph: {
      images: [{ url: '/brand/png/social-banner-og-1200x630.png?v=3', width: 1200, height: 630 }],
    },
  };
}
```

### `app/posts/[clubId]/[postId]/page.tsx` (Server Component, ISR 300s)
- OG dinámico: si el post es público, levanta foto + texto del post como `og:image` y description
- Si no existe o `is_public:false`, devuelve `notFound()`
- Renderiza con branding CR-neutro (no del club) para cross-promo

---

## 6. `robots.txt` y `sitemap.xml` actuales

### `robots.txt`
```
User-agent: *
Allow: /

Sitemap: https://challengersranking.online/sitemap.xml
```

⚠️ **Notar**: no bloquea NADA. Si los subdominios `*.challengersranking.online`
no tienen su propio `robots.txt`, los crawlers indexan todo lo que es
crawlable. La app sí usa AuthGuard, pero quizás `/login`, `/signup`,
`/posts/[clubId]/[postId]` son públicas y se indexan.

### `sitemap.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>https://challengersranking.online/</loc>
    <lastmod>2026-04-29</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
    <xhtml:link rel="alternate" hreflang="en"        href="https://challengersranking.online/"/>
    <xhtml:link rel="alternate" hreflang="es"        href="https://challengersranking.online/"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="https://challengersranking.online/"/>
  </url>
</urlset>
```

⚠️ Solo 1 URL. No incluye `app.challengersranking.online/signup`,
ni las páginas públicas de posts shareables.

---

## 7. Targets keywords actuales (en `<meta name="keywords">`)

### Inglés
- `tennis ladder app`, `padel ladder app`, `pickleball ladder app`, `squash ladder app`
- `racket sports ranking software`, `club tennis app`, `club padel app`

### Español
- `app ranking tenis`, `app ranking padel`, `ranking pádel club`
- `ranking pickleball`, `ranking squash`, `escalera tenis`, `escalera pádel`

### Long-tail no usado todavía (sugerencias)
- `cómo armar ranking de escalera en mi club de tenis`
- `software para club de pádel`
- `app para organizar partidos del club`
- `tennis club management software`
- `pickleball club ladder system`

---

## 8. Geo targeting

**Prioridades comerciales**:
1. **LatAm**: Argentina (primario), Uruguay, Chile, México, Colombia
2. **USA sunbelt**: Texas, Florida, California, Arizona (pickleball + tenis)
3. **EU**: España, Italia (pádel)

**Lo que ya hay**:
- og:locale `en_US` + alternate `es_AR`
- Geo-detection JS (lee `cf-ipcountry` o similar — chequear) → setea ES si AR/MX/etc.

---

## 9. Lo que sospecho que falta (para auditar)

- [ ] **Subdominios sin `noindex`**: `tca.challengersranking.online/players/123` puede estar siendo crawleado. Hay que decidir si bloquear con robots.txt por subdomain o agregar `<meta name="robots" content="noindex">` en el layout cuando aplique.
- [ ] **Sitemap incompleto**: solo tiene la home. Falta `/signup` (app), páginas públicas de posts, y subsecciones del landing si aplica.
- [ ] **JSON-LD FAQPage**: revisar que las preguntas/respuestas sean coherentes con el copy actual de la landing (cambió hace poco).
- [ ] **JSON-LD Organization**: `sameAs` puede estar vacío — agregar redes sociales si existen.
- [ ] **Schema.org BreadcrumbList**: no hay. Para posts públicos podría sumar.
- [ ] **Schema.org Product/Pricing**: ya está dentro de SoftwareApplication, pero verificar que los tiers reales (Free/Pro/Enterprise) estén reflejados.
- [ ] **hreflang** strategy: same-URL para EN/ES es válido pero pierde rankings localizados. Evaluar `/es/` y `/en/` con redirects 302 geo.
- [ ] **Core Web Vitals (mobile)**: no hay datos reales de Search Console — pedirlos al user.
- [ ] **H1/H2/H3 hierarchy**: la landing tiene mucho contenido — verificar que la jerarquía sea clean.
- [ ] **Internal linking**: los anchors `#features`, `#pricing` están bien; falta linking a páginas de uso real (live demo, blog, etc.) si existen.
- [ ] **Imagen `<img alt="">`**: muchas imgs decorativas tienen alt vacío (correcto), pero verificar que las informativas tengan alt descriptivo.
- [ ] **OG title/description**: actualmente solo en EN; agregar `og:title` y `og:description` localizadas para `og:locale:alternate`.

---

## 10. Cómo testear / herramientas

- **Lighthouse mobile + desktop**: `npx lighthouse https://challengersranking.online/ --form-factor=mobile`
- **Schema validator**: https://validator.schema.org/ (pegar cada JSON-LD)
- **Rich Results Test**: https://search.google.com/test/rich-results
- **Mobile-Friendly Test**: https://search.google.com/test/mobile-friendly
- **Search Console**: requiere acceso del owner (Bernie). Datos reales de impresiones/clicks/CWV.
- **Bing Webmaster Tools**: idem.
- **Facebook Sharing Debugger**: https://developers.facebook.com/tools/debug/?q=https%3A%2F%2Fchallengersranking.online%2F (forzar refresh OG)
- **Twitter Card Validator**: https://cards-dev.twitter.com/validator
- **Hreflang validator**: https://www.aleydasolis.com/english/international-seo-tools/hreflang-tags-generator/

---

## 11. Restricciones / cosas que NO tocar

- **No romper bilingüe**: cualquier cambio de copy debe mantener `data-en` / `data-es` attrs.
- **No tocar el JS de `setLang()`** — el toggle de idioma comparte localStorage entre subdominios via cookie con `domain=.challengersranking.online`.
- **No bloquear el subdominio `super.challengersranking.online`** del crawl indiscriminadamente — ya tiene auth, pero el robots general puede afectar.
- **No tocar el SW de la app** (`Challengers Demo/public/sw.js`) — recién optimizado para perf.
- **No reemplazar `og-image.png`** sin regenerar desde el SVG (ver `brand-kit/social-banner-og.svg`); si lo regenerás mal, el preview de WhatsApp se rompe.

---

## 12. Decisiones pendientes que afectan SEO

1. ¿Mantener same-URL bilingüe o separar `/es/` y `/en/`?
2. ¿Indexar las páginas públicas de posts (`/posts/[clubId]/[postId]`) en sitemap dinámico?
3. ¿Bloquear los subdominios de clubs reales (`tca.*`) del crawl o dejar que se indexen y meter `noindex` página por página?
4. ¿Agregar un blog (`/blog`) para content SEO long-tail? (no implementado todavía)

---

**Última actualización**: 2026-05-07
**Owner**: Bernie (b@uildu.com)
