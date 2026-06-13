/**
 * Renderiza welcome.html (8 scenes, multi-audio per scene) a MP4.
 * Adaptado de render-community.js (mismo patrón):
 *   - 8 escenas
 *   - localStorage key: cr-welcome-lang
 *   - audio dir: welcome-audio/{lang}/
 *
 * Uso: node scripts/render-welcome.js <es|en> <output.mp4>
 */
import { chromium } from 'playwright';
import ffmpegStatic from 'ffmpeg-static';
import { spawn } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';

const [, , lang, outputMp4] = process.argv;
if (!lang || !outputMp4 || (lang !== 'es' && lang !== 'en')) {
  console.error('Uso: node scripts/render-welcome.js <es|en> <output.mp4>');
  process.exit(1);
}

const W = 1080, H = 1920;
const LANDING = '/Users/bernardoloitegui/Challengers Landing';
const SALES_HTML = `${LANDING}/welcome.html`;
const AUDIO_DIR = `${LANDING}/welcome-audio/${lang}`;
const SCENES = ['01','02','03','04','05','06','07','08'];
const LANG_KEY = 'cr-welcome-lang';

function ffrun(args) {
  return new Promise((resolve, reject) => {
    const p = spawn(ffmpegStatic, args, { stdio: ['ignore', 'ignore', 'pipe'] });
    let err = '';
    p.stderr.on('data', d => { err += d.toString(); });
    p.on('close', code => code === 0 ? resolve() : reject(new Error(err.slice(-1000))));
  });
}

async function getDuration(file) {
  return new Promise((resolve, reject) => {
    const p = spawn(ffmpegStatic, ['-i', file], { stdio: ['ignore', 'ignore', 'pipe'] });
    let err = '';
    p.stderr.on('data', d => { err += d.toString(); });
    p.on('close', () => {
      const m = err.match(/Duration: (\d+):(\d+):(\d+\.\d+)/);
      if (!m) return reject(new Error('No duration'));
      resolve((+m[1]) * 3600 + (+m[2]) * 60 + (+m[3]));
    });
  });
}

async function main() {
  const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'welcome-render-'));
  console.log(`Work dir: ${workDir}`);

  let total = 0;
  for (const sc of SCENES) total += await getDuration(path.join(AUDIO_DIR, `scene-${sc}.m4a`));
  console.log(`Duración total ${lang}: ${total.toFixed(2)}s`);

  const manifest = SCENES.map(sc => `file '${path.join(AUDIO_DIR, `scene-${sc}.m4a`)}'`).join('\n');
  const manifestPath = path.join(workDir, 'concat.txt');
  await fs.writeFile(manifestPath, manifest);
  const combinedAudio = path.join(workDir, 'combined.m4a');
  console.log(`→ Concatenando ${SCENES.length} audios...`);
  await ffrun(['-y', '-f', 'concat', '-safe', '0', '-i', manifestPath, '-c', 'copy', combinedAudio]);

  console.log(`→ Lanzando playwright para grabar video (${(total + 1).toFixed(0)}s)...`);
  const videoDir = path.join(workDir, 'video');
  await fs.mkdir(videoDir);

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--autoplay-policy=no-user-gesture-required', '--hide-scrollbars', '--mute-audio'],
  });
  const context = await browser.newContext({
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
    recordVideo: { dir: videoDir, size: { width: W, height: H } },
  });
  const page = await context.newPage();
  const recStart = Date.now();

  await page.addInitScript((l) => { try { localStorage.setItem('cr-welcome-lang', l); } catch {} }, lang);
  await page.goto(`file://${SALES_HTML}`, { waitUntil: 'networkidle' });
  await page.addStyleTag({ content: `
    html, body { overflow: hidden !important; background: #000 !important; }
    #controls, #captions, #replay-overlay, #top-progress, #top-progress-fill { display: none !important; }
  ` });

  const leadSec = Math.max(0, (Date.now() - recStart) / 1000);
  await page.evaluate(() => { document.getElementById('play-overlay-btn')?.click(); });
  await page.waitForTimeout((total + 0.8) * 1000);

  await context.close();
  await browser.close();

  const videoFiles = (await fs.readdir(videoDir)).filter(f => f.endsWith('.webm'));
  if (videoFiles.length === 0) throw new Error('No video file generated');
  const webm = path.join(videoDir, videoFiles[0]);
  console.log(`✓ WebM: ${((await fs.stat(webm)).size / 1024 / 1024).toFixed(2)} MB`);

  console.log(`→ Encodeando MP4 final · recortando lead-in ${leadSec.toFixed(2)}s...`);
  await ffrun([
    '-y', '-ss', leadSec.toFixed(3), '-i', webm, '-i', combinedAudio,
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '22', '-pix_fmt', 'yuv420p',
    '-c:a', 'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart', outputMp4,
  ]);

  await fs.rm(workDir, { recursive: true, force: true });
  console.log(`✓ ${outputMp4} (${((await fs.stat(outputMp4)).size / 1024 / 1024).toFixed(2)} MB)`);
}

main().catch(e => { console.error(e); process.exit(1); });
