/** Config para el build estático de index.html (F5). Espeja la config inline
 * que usaba el Play CDN — si tocás colores acá, tocá también las otras
 * páginas que siguen en CDN. Build:
 *   node_modules/.bin/tailwindcss -i assets/tw.in.css -o assets/tw.css --minify
 */
module.exports = {
  content: ['./index.html'],
  // Clases que el JS togglea y podrían no estar en el HTML estático:
  safelist: ['bg-gold', 'text-navy', 'text-white/60', 'hidden', 'translate-y-full'],
  theme: {
    extend: {
      colors: {
        navy: '#1A1A2E',
        'navy-light': '#3A3A52',
        'navy-dark': '#0F0F1F',
        terracotta: '#C8451C',
        'terracotta-hover': '#A8381A',
        'terracotta-soft': '#FCE8DC',
        cream: '#FAF7F2',
        'cream-warm': '#F2EBE0',
        gold: '#E8B04C',
        'gold-light': '#F2C46E',
        sand: '#FAF7F2',
        'brand-border': '#E7E0D4',
      },
      fontFamily: {
        serif: ['Playfair Display', 'serif'],
        sans: ['Inter', 'sans-serif'],
      },
      borderRadius: { pill: '999px' },
    },
  },
};
