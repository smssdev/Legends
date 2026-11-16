// Builds "My First Numbers & Counting" (Little Math Adventures, Book 1, ages 4–5) for Amazon KDP.
//   node kids-books/math-4-5/build.mjs [preview-dir]
// Writes print/interior.pdf (black & white, 8.5 x 11 in, no bleed),
// print/cover.pdf (colour, full wrap with 0.125 in bleed) and print/cover-front.png.
// With a preview dir, also writes a PNG of every interior page there.

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import { g, fish, apple, duck, cat, star, owl, sun, bunny, balloon } from './art.mjs';
import { sections, answerKeyPages, PW, PH } from './book.mjs';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, 'print');
const preview = process.argv[2];
mkdirSync(out, { recursive: true });

const css = (w, h) => `
@font-face { font-family: Fredoka; font-weight: 600; src: url(../fonts/fredoka-latin-600-normal.woff2); }
@font-face { font-family: Fredoka; font-weight: 700; src: url(../fonts/fredoka-latin-700-normal.woff2); }
@font-face { font-family: Andika; font-weight: 400; src: url(../fonts/andika-latin-400-normal.woff2); }
@font-face { font-family: Andika; font-weight: 700; src: url(../fonts/andika-latin-700-normal.woff2); }
@page { size: ${w}in ${h}in; margin: 0; }
html, body { margin: 0; padding: 0; background: #fff; }
.page { width: ${w}in; height: ${h}in; page-break-after: always; overflow: hidden; }
.page svg { display: block; width: 100%; height: 100%; }
.title { font-family: Fredoka; font-weight: 700; fill: #111; stroke: none; }
.say { font-family: Andika; font-weight: 700; fill: #111; stroke: none; }
.region { font-family: Fredoka; font-weight: 700; fill: #111; stroke: none; }
.trace { font-family: Andika; font-weight: 700; fill: #c4c4c4; stroke: none; }
`;
const html = (pages, w, h) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Little Math Adventures</title><style>${css(w, h)}</style></head><body>${pages.join('')}</body></html>`;

// ---------- interior ----------
const titles = (p) => (p.render(0).match(/class="title"[^>]*>([^<]+)</) || [])[1] || '';
const entries = [];
sections.forEach((p, i) => { if (p.answer) entries.push([i + 1, titles(p).replace('&amp;', '&'), p.answer]); });
const all = [...sections, ...answerKeyPages(entries)];
if (all.length % 2) all.push({ render: () => '<div class="page"></div>' });
const interior = all.map((p, i) => p.render(i + 1));
writeFileSync(join(out, 'interior.html'), html(interior, 8.5, 11));

// ---------- cover: back | spine | front, 0.125 in bleed all round ----------
const pages = interior.length;
const spineIn = +(pages * 0.002252).toFixed(4); // KDP: black & white on white paper
const BLEED = 12, SPINE = spineIn * 96;
const CW = BLEED * 2 + PW * 2 + SPINE, CH = PH + BLEED * 2;
const frontX = BLEED + PW + SPINE;

const C = {
  owl: { body: '#b5793f', belly: '#fbe3bd', wing: '#8a5527', beak: '#ff9f1c' },
  fish: { body: '#ff7b54', fin: '#ffb347' },
  duck: { body: '#ffd93d', beak: '#ff8c1a', wing: '#ffbf00' },
  apple: { body: '#ef3b36', leaf: '#4caf50' },
  star: { body: '#ffd23f' },
  cat: { body: '#c9b8ff', ear: '#ff9fc6' },
  bunny: { body: '#ffffff', ear: '#ffb3c9' },
};
const bubble = (x, y, n, fill) => `<circle cx="${x}" cy="${y}" r="52" fill="${fill}"/>
  <text x="${x}" y="${y + 26}" class="region" font-size="74" text-anchor="middle" style="fill:#fff;stroke:#111;stroke-width:5" paint-order="stroke">${n}</text>`;

const front = `
  <rect x="120" y="44" width="576" height="56" rx="28" fill="#1f3a93"/>
  <text x="408" y="83" class="title" font-size="30" text-anchor="middle" style="fill:#fff">LITTLE MATH ADVENTURES</text>
  <rect x="48" y="126" width="720" height="250" rx="40" fill="#fff" stroke-width="8"/>
  <text x="408" y="210" class="title" font-size="62" text-anchor="middle" style="fill:#ff5a36">My First Numbers</text>
  <text x="408" y="285" class="title" font-size="62" text-anchor="middle" style="fill:#1f3a93">&amp; Counting</text>
  <text x="408" y="345" class="title" font-size="38" text-anchor="middle" style="fill:#2a9d4b">Coloring Workbook</text>
  ${g(690, 455, 1, sun({ body: '#ffd23f' }))}
  ${bubble(170, 460, 1, '#ff5a36')}${bubble(300, 500, 2, '#2a9d4b')}${bubble(430, 460, 3, '#1f6fe0')}
  ${g(408, 690, 1.9, owl(C.owl))}
  ${g(150, 690, 1.05, cat(C.cat))}${g(660, 680, 0.95, star(C.star))}
  ${g(160, 900, 1.1, duck(C.duck))}${g(420, 915, 1.05, fish(C.fish))}${g(650, 900, 1.1, apple(C.apple))}
  <rect x="566" y="975" width="210" height="60" rx="30" fill="#ff5a36"/>
  <text x="671" y="1016" class="title" font-size="34" text-anchor="middle" style="fill:#fff">Ages 4–5</text>
  <text x="48" y="1016" class="title" font-size="26" style="fill:#13361d">Pre-K &amp; Kindergarten</text>`;

const points = [
  'Numbers 1 to 10: trace, count, and color',
  'Counting, matching, and number hunts',
  'More, fewer, and the same',
  'Circles, squares, triangles, rectangles',
  'Color by number and dot to dot',
  'Adding and taking away within 5',
];
const dots = ['#ff5a36', '#2a9d4b', '#1f6fe0', '#ffd23f', '#b5793f', '#ff5a36'];
const back = `
  <rect x="60" y="70" width="696" height="640" rx="40" fill="#fff" stroke-width="8"/>
  <text x="408" y="150" class="title" font-size="40" text-anchor="middle" style="fill:#1f3a93">Count, color, and learn</text>
  <text x="408" y="200" class="title" font-size="40" text-anchor="middle" style="fill:#1f3a93">with Ollie the Owl!</text>
  <text x="408" y="258" class="say" font-size="22" text-anchor="middle">${pages} pages of happy, hands-on math for little learners.</text>
  ${points.map((t, i) => `<circle cx="120" cy="${318 + i * 56}" r="16" fill="${dots[i]}" stroke-width="4"/>
    <text x="152" y="${327 + i * 56}" class="say" font-size="25">${t}</text>`).join('')}
  <text x="408" y="680" class="say" font-size="20" text-anchor="middle">Big pictures · thick lines · one page, one idea · answer key</text>
  ${g(150, 860, 1.1, bunny(C.bunny))}${g(300, 840, 1.2, balloon({ body: '#ff5a36' }))}
  ${g(420, 870, 0.9, owl(C.owl))}
  <text x="60" y="1010" class="title" font-size="24" style="fill:#13361d">Little Math Adventures · Book 1</text>`;

const sky = `<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7cc8ff"/><stop offset="1" stop-color="#d9f2ff"/></linearGradient></defs>`;
const hill = (x) => `M${x - 20},${BLEED + 800} Q${x + 200},${BLEED + 740} ${x + 408},${BLEED + 780} Q${x + 620},${BLEED + 820} ${x + 836},${BLEED + 760}`;
const ground = (x) => `<path d="${hill(x)} L${x + 836},${CH + 10} L${x - 20},${CH + 10} Z" fill="#7fd36b" stroke="none"/><path d="${hill(x)}" fill="none"/>`;
const wrap = `<div class="page"><svg viewBox="0 0 ${CW} ${CH}" xmlns="http://www.w3.org/2000/svg">${sky}
  <defs><clipPath id="backClip"><rect x="-5" y="-5" width="${BLEED + PW + 5}" height="${CH + 10}"/></clipPath><clipPath id="frontClip"><rect x="${frontX}" y="-5" width="${PW + BLEED + 5}" height="${CH + 10}"/></clipPath></defs>
  <g fill="#fff" stroke="#111" stroke-width="6" stroke-linejoin="round" stroke-linecap="round">
  <rect x="-5" y="-5" width="${CW + 10}" height="${CH + 10}" fill="url(#sky)" stroke="none"/>
  <g clip-path="url(#backClip)">${ground(BLEED)}</g><g clip-path="url(#frontClip)">${ground(frontX)}</g>
  <rect x="${BLEED + PW}" y="-5" width="${SPINE}" height="${CH + 10}" fill="#1f3a93" stroke="none"/>
  <g transform="translate(${BLEED} ${BLEED})">${back}</g>
  <g transform="translate(${frontX} ${BLEED})">${front}</g></g></svg></div>`;
const coverW = +(CW / 96).toFixed(4), coverH = +(CH / 96).toFixed(4);
writeFileSync(join(out, 'cover.html'), html([wrap], coverW, coverH));

// ---------- print ----------
const browser = await chromium.launch();
const tab = await browser.newPage({ viewport: { width: Math.ceil(CW), height: CH }, deviceScaleFactor: 1 });
await tab.goto(pathToFileURL(join(out, 'interior.html')).href);
await tab.evaluate(() => document.fonts.ready);
await tab.pdf({ path: join(out, 'interior.pdf'), preferCSSPageSize: true, printBackground: true });
if (preview) {
  mkdirSync(preview, { recursive: true });
  const els = await tab.$$('.page');
  for (let i = 0; i < els.length; i++) await els[i].screenshot({ path: join(preview, `p${String(i + 1).padStart(2, '0')}.png`) });
}
await tab.goto(pathToFileURL(join(out, 'cover.html')).href);
await tab.evaluate(() => document.fonts.ready);
await tab.pdf({ path: join(out, 'cover.pdf'), preferCSSPageSize: true, printBackground: true });
await tab.screenshot({ path: join(out, 'cover-front.png'), clip: { x: frontX, y: BLEED, width: PW, height: PH } });
await tab.screenshot({ path: join(out, 'cover-full.png') });
await browser.close();
console.log(`interior: ${pages} pages; cover: ${coverW} x ${coverH} in (spine ${spineIn} in)`);
