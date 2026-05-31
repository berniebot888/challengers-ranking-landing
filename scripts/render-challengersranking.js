/**
 * Renderiza challengersranking.html (5 scenes, multi-audio per scene) a MP4.
 * Mismo patrón que render-welcome.js, adaptado a community:
 *   - 5 escenas (vs 8 en welcome)
 *   - localStorage key: cr-cr-video-lang
 *   - audio dir: challengersranking-audio/{lang}/
 *
 * Uso: node render-community.js <lang> <output.mp4>
 */
import { chromium } from 'playwright';
import ffmpegStatic from 'ffmpeg-static';
import { spawn } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';

const [, , lang, outputMp4] = process.argv;
if (!lang || !outputMp4 || (lang !== 'es' && lang !== 'en')) {
  console.error('Uso: node render-community.js <es|en> <output.mp4>');
  process.exit(1);
}

const W = 1080, H = 1920;
const LANDING = '/Users/bernardoloitegui/Challengers Landing';
const SALES_HTML = `${LANDING}/challengersranking.html`;
const AUDIO_DIR = `${LANDING}/challengersranking-audio/${lang}`;
const SCENES = ['01','02','03','04','05'];

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
  const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sales-render-'));
  console.log(`Work dir: ${workDir}`);

  let total = 0;
  const scDur = [];
  for (const sc of SCENES) {
    const d = await getDuration(path.join(AUDIO_DIR, `scene-${sc}.m4a`));
    scDur.push(d);
    total += d;
  }
  console.log(`Duración total ${lang}: ${total.toFixed(2)}s`);

  const manifest = SCENES.map(sc => `file '${path.join(AUDIO_DIR, `scene-${sc}.m4a`)}'`).join('\n');
  const manifestPath = path.join(workDir, 'concat.txt');
  await fs.writeFile(manifestPath, manifest);
  const combinedAudio = path.join(workDir, 'combined.m4a');
  console.log('→ Concatenando 5 audios...');
  await ffrun([
    '-y', '-f', 'concat', '-safe', '0', '-i', manifestPath,
    '-c', 'copy', combinedAudio,
  ]);

  console.log(`→ Lanzando playwright para grabar video (${(total + 1).toFixed(0)}s)...`);
  const videoDir = path.join(workDir, 'video');
  await fs.mkdir(videoDir);

  const browser = await chromium.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--autoplay-policy=no-user-gesture-required',
      '--hide-scrollbars',
      '--mute-audio',
    ],
  });
  const context = await browser.newContext({
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
    recordVideo: { dir: videoDir, size: { width: W, height: H } },
  });
  const page = await context.newPage();
  const recStart = Date.now(); // para recortar el lead-in (flash blanco + overlay)

  // Preset lang en localStorage (community usa cr-cr-video-lang)
  await page.addInitScript((l) => {
    try { localStorage.setItem('cr-cr-video-lang', l); } catch {}
  }, lang);

  await page.goto(`file://${SALES_HTML}`, { waitUntil: 'networkidle' });
  // Inyectar CSS que limpia toda la UI de chrome (controls, captions, overlays).
  // El video final debe mostrar solo los slides + audio, como un MP4 limpio
  // listo para subir a redes — sin botones, sin selector ES/EN, sin progress bar.
  await page.addStyleTag({ content: `
    html, body { overflow: hidden !important; background: #000 !important; }
    #controls, #captions, #replay-overlay, #top-progress { display: none !important; }
    /* Top progress fill también por las dudas */
    #top-progress-fill { display: none !important; }
  ` });

  // Lead-in a recortar (flash blanco de carga + overlay) — solo del video.
  const leadSec = Math.max(0, (Date.now() - recStart) / 1000);

  // Click play overlay para arrancar la secuencia de scenes
  await page.evaluate(() => {
    document.getElementById('play-overlay-btn')?.click();
  });

  // Esperar la duración total + buffer chico
  await page.waitForTimeout((total + 0.8) * 1000);

  await context.close();
  await browser.close();

  const videoFiles = (await fs.readdir(videoDir)).filter(f => f.endsWith('.webm'));
  if (videoFiles.length === 0) throw new Error('No video file generated');
  const webm = path.join(videoDir, videoFiles[0]);
  const webmStat = await fs.stat(webm);
  console.log(`✓ WebM: ${(webmStat.size / 1024 / 1024).toFixed(2)} MB`);

  console.log(`→ Encodeando MP4 final (h264 + aac) · recortando lead-in ${leadSec.toFixed(2)}s del video...`);
  await ffrun([
    '-y',
    '-ss', leadSec.toFixed(3), '-i', webm,   // recorta el lead-in SOLO del video (sin frame blanco)
    '-i', combinedAudio,
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '22',
    '-pix_fmt', 'yuv420p',
    '-c:a', 'aac', '-b:a', '192k',
    '-shortest', '-movflags', '+faststart',
    outputMp4,
  ]);

  await fs.rm(workDir, { recursive: true, force: true });

  const stat = await fs.stat(outputMp4);
  console.log(`✓ ${outputMp4} (${(stat.size / 1024 / 1024).toFixed(2)} MB)`);
}

main().catch(e => { console.error(e); process.exit(1); });
