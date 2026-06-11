# Baseline Lighthouse — 2026-06-10 (pre-rediseño)

URL: https://challengersranking.online/ · mobile emulado · Lighthouse 13.4.0

| Categoría | Score |
|---|---|
| performance | 60 |
| accessibility | 91 |
| best-practices | 100 |
| seo | 100 |

| Métrica | Valor |
|---|---|
| first-contentful-paint | 4.7 s |
| largest-contentful-paint | 8.6 s |
| speed-index | 6.8 s |
| cumulative-layout-shift | 0.002 |
| total-blocking-time | 70 ms |
| interactive | 8.6 s |

Diagnóstico: LCP 8.6s = foto hero Unsplash 1800px + cadena render-blocking
(Tailwind Play CDN + Google Fonts). El hero DOM de F2 + Tailwind compilado de F5
atacan exactamente esto. CLS/TBT ya están bien.