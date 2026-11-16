// Builds the sample pages of "My First Numbers & Counting" (ages 4–5).
//   node kids-books/math-4-5/build.mjs
// Writes sample/interior-sample.pdf (black & white, 8.5 x 11 in),
// sample/cover-front.pdf (colour) and a PNG of every page in sample/png/.

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import { g, fish, apple, duck, cat, star, owl, turtle, crayon, sun, THREE, eye } from './art.mjs';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, 'sample');
mkdirSync(join(out, 'png'), { recursive: true });

const PW = 816, PH = 1056; // 8.5 x 11 in at 96 px per inch
const LINE = 'fill="#fff" stroke="#111" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"';

const css = `
@font-face { font-family: Fredoka; font-weight: 600; src: url(fonts/fredoka-latin-600-normal.woff2); }
@font-face { font-family: Fredoka; font-weight: 700; src: url(fonts/fredoka-latin-700-normal.woff2); }
@font-face { font-family: Andika; font-weight: 400; src: url(fonts/andika-latin-400-normal.woff2); }
@font-face { font-family: Andika; font-weight: 700; src: url(fonts/andika-latin-700-normal.woff2); }
@page { size: 8.5in 11in; margin: 0; }
html, body { margin: 0; padding: 0; background: #fff; }
.page { width: 8.5in; height: 11in; page-break-after: always; overflow: hidden; }
.page svg { display: block; width: 100%; height: 100%; }
.title { font-family: Fredoka; font-weight: 700; fill: #111; stroke: none; }
.say { font-family: Andika; font-weight: 700; fill: #111; stroke: none; }
.region { font-family: Fredoka; font-weight: 700; fill: #111; stroke: none; }
.trace { font-family: Andika; font-weight: 700; fill: #c4c4c4; stroke: none; }
`;

const page = (body) => `<div class="page"><svg viewBox="0 0 ${PW} ${PH}" xmlns="http://www.w3.org/2000/svg"><g ${LINE}>${body}</g></svg></div>`;
const text = (x, y, s, t, cls = 'say', anchor = 'middle') => `<text x="${x}" y="${y}" class="${cls}" font-size="${s}" text-anchor="${anchor}">${t}</text>`;

// Every activity page: Ollie, a title band, one short instruction, a page number.
function frame(no, title, instruction, body) {
  return page(`
    ${g(98, 112, 0.62, owl())}
    <rect x="160" y="62" width="608" height="88" rx="44"/>
    ${text(464, 122, 44, title, 'title')}
    ${text(PW / 2, 210, 28, instruction)}
    ${body}
    <circle cx="${PW / 2}" cy="1000" r="24" stroke-width="4"/>
    ${text(PW / 2, 1009, 24, no, 'region')}`);
}

const box = (x, y, s = 84) => `<rect x="${x}" y="${y}" width="${s}" height="${s}" rx="14"/>`;
const row = (n, x0, gap, y, s, art) => Array.from({ length: n }, (_, i) => g(x0 + i * gap, y, s, art)).join('');

// ---------------- pages ----------------

const intro = page(`
  ${text(PW / 2, 150, 46, 'This book belongs to:', 'title')}
  <path d="M150,250 L666,250" fill="none" stroke-width="5"/>
  ${g(PW / 2, 470, 2.1, owl())}
  ${g(170, 470, 0.9, star())}${g(650, 430, 0.9, star())}${g(110, 640, 0.7, star())}
  <path d="M200,700 L384,700 L408,668 L432,700 L616,700 Q646,700 646,730 L646,790 Q646,820 616,820 L200,820 Q170,820 170,790 L170,730 Q170,700 200,700 Z"/>
  ${text(PW / 2, 752, 30, 'Hi! I am Ollie the Owl.')}
  ${text(PW / 2, 794, 30, "Let's count, color, and learn!")}
  ${text(PW / 2, 905, 22, 'Grown-ups: read the short line at the top of each page.')}
  ${text(PW / 2, 937, 22, 'Let your child count with a finger before coloring.')}
`);

// Number 3: colour the big 3, trace 3s, count the fish, fill a five-frame.
const digit3 = [0, 1, 2, 3].map((i) => {
  const x = 335 + i * 108;
  return `<g transform="translate(${x} 262) scale(1.45)">
    <path d="${THREE}" fill="none" stroke="#9a9a9a" stroke-width="6" stroke-dasharray="0.1 10"/>
    <circle cx="8" cy="20" r="6" fill="#111" stroke="none"/></g>`;
}).join('');
const number3 = frame(1, 'The Number 3', 'Color the 3. Trace the 3s.', `
  <text x="190" y="455" class="region" font-size="300" text-anchor="middle" fill="#fff" stroke="#111" stroke-width="7" style="fill:#fff;stroke:#111" paint-order="stroke">3</text>
  ${digit3}
  ${text(530, 480, 64, 'three', 'trace')}
  <path d="M60,510 L756,510" fill="none" stroke-width="3" stroke-dasharray="10 12"/>
  ${text(PW / 2, 568, 28, 'Count the fish. Color them.')}
  ${g(190, 680, 0.95, fish())}${g(420, 640, 0.95, fish())}${g(630, 700, 0.95, fish())}
  <circle cx="300" cy="610" r="10" stroke-width="4"/><circle cx="318" cy="584" r="7" stroke-width="4"/>
  <circle cx="540" cy="600" r="9" stroke-width="4"/><circle cx="728" cy="640" r="8" stroke-width="4"/>
  <path d="M80,800 Q60,760 85,730 Q105,700 85,668 Q100,656 108,670 Q128,700 106,730 Q86,762 104,800 Z" stroke-width="5"/><path d="M716,800 Q698,770 720,746 Q738,724 722,700 Q736,690 744,702 Q760,726 742,748 Q722,772 740,800 Z" stroke-width="5"/>
  ${text(PW / 2, 862, 28, 'Color 3 boxes.')}
  ${[0, 1, 2, 3, 4].map((i) => box(198 + i * 86, 885, 76)).join('')}
`);

// Count and match: groups on the left, numbers on the right.
const rowsY = [330, 495, 660, 825];
const groups = [
  row(2, 120, 150, rowsY[0], 0.75, cat()),
  row(4, 95, 92, rowsY[1], 0.72, star()),
  g(170, rowsY[2], 0.85, duck()),
  row(3, 110, 120, rowsY[3], 0.72, apple()),
];
const nums = [3, 1, 4, 2];
const match = frame(2, 'Count and Match', 'Count. Draw a line to the number.', `
  ${groups.join('')}
  ${rowsY.map((y) => `<circle cx="470" cy="${y}" r="10" fill="#111" stroke="none"/>`).join('')}
  ${rowsY.map((y, i) => `<circle cx="590" cy="${y}" r="10" fill="#111" stroke="none"/>
     <circle cx="680" cy="${y}" r="56"/>
     <text x="680" y="${y + 30}" class="region" font-size="84" text-anchor="middle">${nums[i]}</text>`).join('')}
`);

// More and fewer.
const panel = (x, y) => `<rect x="${x}" y="${y}" width="330" height="250" rx="28"/>`;
const more = frame(3, 'More or Fewer?', 'Look. Count. Compare.', `
  ${text(PW / 2, 280, 28, 'Color the group with MORE ducks.')}
  ${panel(60, 305)}${panel(426, 305)}
  ${g(160, 400, 0.6, duck())}${g(290, 480, 0.6, duck())}
  ${g(520, 390, 0.55, duck())}${g(670, 390, 0.55, duck())}${g(520, 490, 0.55, duck())}${g(670, 490, 0.55, duck())}
  ${text(PW / 2, 630, 28, 'Circle the group with FEWER apples.')}
  ${panel(60, 655)}${panel(426, 655)}
  ${g(125, 740, 0.55, apple())}${g(225, 740, 0.55, apple())}${g(325, 740, 0.55, apple())}${g(175, 840, 0.55, apple())}${g(275, 840, 0.55, apple())}
  ${g(520, 760, 0.6, apple())}${g(660, 760, 0.6, apple())}${g(590, 850, 0.6, apple())}
`);

// Shapes train.
const tri = (x, y, s) => `<path d="M${x},${y} L${x + s / 2},${y - s * 0.86} L${x + s},${y} Z"/>`;
const shapes = frame(4, 'Shape Train', 'Find the shapes. Color them.', `
  <g transform="translate(0 -10)">
    <rect x="248" y="265" width="200" height="56" rx="14" stroke-width="5"/>
    <circle cx="276" cy="293" r="16" stroke-width="4"/>${text(352, 303, 26, 'red', 'say')}
    <rect x="470" y="265" width="200" height="56" rx="14" stroke-width="5"/>
    <rect x="490" y="277" width="32" height="32" stroke-width="4"/>${text(590, 303, 26, 'blue', 'say')}
    <rect x="148" y="335" width="200" height="56" rx="14" stroke-width="5"/>
    ${tri(170, 379, 34)}${text(272, 373, 26, 'yellow', 'say')}
    <rect x="370" y="335" width="300" height="56" rx="14" stroke-width="5"/>
    <rect x="388" y="349" width="44" height="28" stroke-width="4"/>${text(552, 373, 24, 'any color you like', 'say')}
  </g>
  <rect x="70" y="560" width="190" height="110" rx="12"/>
  <rect x="120" y="500" width="40" height="64" rx="6"/>
  <rect x="250" y="470" width="125" height="200" rx="12"/>
  <rect x="270" y="500" width="76" height="76" rx="4"/>
  <path d="M236,462 L390,462" fill="none" stroke-width="10"/>
  <rect x="405" y="575" width="160" height="95" rx="12"/>
  <rect x="455" y="592" width="60" height="60" rx="4"/>
  ${tri(415, 570, 140)}
  <rect x="595" y="575" width="160" height="95" rx="12"/>
  <rect x="645" y="592" width="60" height="60" rx="4"/>
  ${tri(600, 570, 70)}${tri(680, 570, 70)}
  <path d="M375,640 L405,640 M565,640 L595,640" fill="none" stroke-width="8"/>
  <circle cx="125" cy="700" r="40"/><circle cx="300" cy="700" r="40"/>
  <circle cx="445" cy="704" r="30"/><circle cx="525" cy="704" r="30"/>
  <circle cx="635" cy="704" r="30"/><circle cx="715" cy="704" r="30"/>
  <path d="M40,742 L776,742" fill="none" stroke-width="6"/>
  ${[80, 180, 280, 380, 480, 580, 680].map((x) => `<path d="M${x},742 L${x + 30},770" fill="none" stroke-width="5"/>`).join('')}
  ${text(80, 846, 30, 'How many circles?', 'say', 'start')}${box(400, 798, 78)}
  ${text(80, 942, 30, 'How many triangles?', 'say', 'start')}${box(400, 894, 78)}
  ${g(640, 880, 0.9, owl())}
`);

// Colour by number.
const colorBy = frame(5, 'Color by Number', 'Color the crayons first. Then color the turtle!', `
  ${g(660, 330, 0.9, sun())}
  <text x="660" y="331" class="region" font-size="30" text-anchor="middle" dominant-baseline="central">2</text>
  <path d="M120,320 Q140,290 175,300 Q200,270 235,295 Q265,295 262,322 Z" stroke-width="5"/>
  ${g(370, 520, 2.15, turtle())}
  <path d="M50,736 Q200,712 408,730 Q620,748 766,724" fill="none" stroke-width="5"/>
  ${[70, 560, 700].map((x) => `<path d="M${x},734 l8,-24 l8,24 l8,-18 l6,18" fill="none" stroke-width="4"/>`).join('')}
  ${g(150, 885, 1, crayon(1, 'green'))}${g(320, 885, 1, crayon(2, 'yellow'))}
  ${g(490, 885, 1, crayon(3, 'orange'))}${g(660, 885, 1, crayon(4, 'brown'))}
`);

// Picture addition within 5.
const sum = (y, a, b, art, s, w) => {
  const total = (a + b) * w + 70 + 70 + 92;
  const x0 = (PW - total) / 2;
  const plusX = x0 + a * w + 35;
  const eqX = plusX + 35 + b * w + 35;
  const at = (start, i) => start + w / 2 + i * w;
  return `${row(a, at(x0, 0), w, y, s, art)}${text(plusX, y + 22, 60, '+', 'region')}
    ${row(b, at(plusX + 35, 0), w, y, s, art)}${text(eqX, y + 22, 60, '=', 'region')}${box(eqX + 35, y - 46, 92)}
    ${text(x0 + (a * w) / 2, y + 110, 44, a, 'region')}${text(plusX + 35 + (b * w) / 2, y + 110, 44, b, 'region')}`;
};
const add = frame(6, 'Let\'s Add!', 'Count them all. Write how many.', `
  ${sum(330, 2, 1, duck(), 0.55, 125)}
  ${sum(580, 3, 2, apple(), 0.55, 92)}
  ${sum(830, 1, 3, fish(), 0.45, 100)}
`);

// ---------------- cover (colour, front only) ----------------
const C = {
  owl: { body: '#b5793f', belly: '#fbe3bd', wing: '#8a5527', beak: '#ff9f1c' },
  fish: { body: '#ff7b54', fin: '#ffb347' },
  duck: { body: '#ffd93d', beak: '#ff8c1a', wing: '#ffbf00' },
  apple: { body: '#ef3b36', leaf: '#4caf50' },
  star: { body: '#ffd23f' },
  cat: { body: '#c9b8ff', ear: '#ff9fc6' },
};
const bubble = (x, y, n, fill) => `<circle cx="${x}" cy="${y}" r="52" fill="${fill}"/>
  <text x="${x}" y="${y + 26}" class="region" font-size="74" text-anchor="middle" style="fill:#fff;stroke:#111;stroke-width:5" paint-order="stroke">${n}</text>`;
const cover = page(`
  <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7cc8ff"/><stop offset="1" stop-color="#d9f2ff"/></linearGradient></defs>
  <rect x="-10" y="-10" width="840" height="1080" fill="url(#sky)" stroke="none"/>
  <path d="M-10,800 Q200,740 408,780 Q620,820 830,760 L830,1070 L-10,1070 Z" fill="#7fd36b"/>
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
  <circle cx="690" cy="575" r="0" fill="none"/>
  <rect x="566" y="975" width="210" height="60" rx="30" fill="#ff5a36"/>
  <text x="671" y="1016" class="title" font-size="34" text-anchor="middle" style="fill:#fff">Ages 4–5</text>
  <text x="48" y="1016" class="title" font-size="26" style="fill:#13361d">Pre-K &amp; Kindergarten</text>
`);

const html = (pages) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Little Math Adventures</title><style>${css}</style></head><body>${pages.join('')}</body></html>`;
const interior = [intro, number3, match, more, shapes, colorBy, add];
writeFileSync(join(here, 'interior.html'), html(interior));
writeFileSync(join(here, 'cover.html'), html([cover]));

const browser = await chromium.launch();
const tab = await browser.newPage({ viewport: { width: PW, height: PH }, deviceScaleFactor: 1 });
for (const [name, count] of [['interior', interior.length], ['cover', 1]]) {
  await tab.goto(pathToFileURL(join(here, `${name}.html`)).href);
  await tab.evaluate(() => document.fonts.ready);
  await tab.pdf({ path: join(out, name === 'cover' ? 'cover-front.pdf' : 'interior-sample.pdf'), preferCSSPageSize: true, printBackground: true });
  const pages = await tab.$$('.page');
  for (let i = 0; i < count; i++) await pages[i].screenshot({ path: join(out, 'png', `${name}-${i}.png`) });
}
await browser.close();
console.log('done:', out);
