#!/usr/bin/env node
/**
 * Capture real screenshots from the demo app (logged in as James Wilson #2).
 * Each screen → explainer-screens/NN-name.png at 440×950 (iPhone-ish).
 *
 * Usage: cd ../Challengers\ Landing && node scripts/capture-demo-screens.js
 *
 * Requires puppeteer (installed via npx).
 */
const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const OUT_DIR = path.join(__dirname, '..', 'explainer-screens');
const BASE_URL = 'https://demo.challengersranking.online';
const PHONE = '+15551234002';
const PIN = '1234';

const VIEWPORT = { width: 440, height: 950, deviceScaleFactor: 2 };

async function shot(page, name) {
  const file = path.join(OUT_DIR, `${name}.png`);
  await page.screenshot({ path: file, fullPage: false });
  const sz = fs.statSync(file).size;
  console.log(`  ✓ ${name}.png (${(sz / 1024).toFixed(1)}KB)`);
}

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);

  console.log('→ Login…');
  await page.goto(BASE_URL, { waitUntil: 'networkidle2', timeout: 30000 });

  // Fill phone & pin
  await page.waitForSelector('input[type="tel"], input[name="phone"], input[placeholder*="+"]', { timeout: 15000 });
  const phoneInput = await page.$('input[type="tel"], input[name="phone"], input[placeholder*="+"]');
  await phoneInput.click();
  await phoneInput.type(PHONE);

  const pwInput = await page.$('input[type="password"]');
  await pwInput.click();
  await pwInput.type(PIN);

  // Submit
  const submit = await page.$('button[type="submit"]') || await page.$x("//button[contains(., 'Entrar') or contains(., 'Login')]").then(r => r[0]);
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 }).catch(() => {}),
    submit.click(),
  ]);
  await new Promise(r => setTimeout(r, 2000));
  console.log('  logged in, URL:', page.url());

  // Screens to capture
  const screens = [
    { name: '01-ranking',       url: '/' },
    { name: '02-challenges',    url: '/challenges' },
    { name: '03-challenges-new', url: '/challenges/new' },
    { name: '04-bar',           url: '/bar' },
    { name: '05-stats',         url: '/stats' },
    { name: '06-account',       url: '/account' },
  ];

  for (const s of screens) {
    console.log(`→ ${s.url}`);
    try {
      await page.goto(BASE_URL + s.url, { waitUntil: 'networkidle2', timeout: 20000 });
      await new Promise(r => setTimeout(r, 1500)); // settle animations
      await shot(page, s.name);
    } catch (e) {
      console.log(`  ✗ ${s.url} failed: ${e.message}`);
    }
  }

  // Try to capture a player profile (click first player in ranking)
  try {
    console.log('→ player profile…');
    await page.goto(BASE_URL + '/', { waitUntil: 'networkidle2', timeout: 20000 });
    await new Promise(r => setTimeout(r, 1500));
    // Click first player row link
    const playerLink = await page.$('a[href*="/players/"]');
    if (playerLink) {
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }).catch(() => {}),
        playerLink.click(),
      ]);
      await new Promise(r => setTimeout(r, 1500));
      await shot(page, '07-player-profile');
    } else {
      console.log('  ✗ no player link found');
    }
  } catch (e) {
    console.log(`  ✗ player profile: ${e.message}`);
  }

  await browser.close();
  console.log('\\n✅ Done. Screenshots in', OUT_DIR);
})().catch(e => { console.error(e); process.exit(1); });
