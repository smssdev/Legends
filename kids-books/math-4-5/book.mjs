// Every page of "My First Numbers & Counting" (Little Math Adventures, Book 1, ages 4–5).
// A page is { render(no), answer? }. build.mjs numbers the pages, writes the
// answer key from the answers and prints the PDF.

import * as A from './art.mjs';

const { g, eye, owl, crayon, sun, DIGITS, nums } = A;
export const PW = 816, PH = 1056;

// ---------- helpers ----------

export const text = (x, y, s, t, cls = 'say', anchor = 'middle', extra = '') =>
  `<text x="${x}" y="${y}" class="${cls}" font-size="${s}" text-anchor="${anchor}" ${extra}>${t}</text>`;
export const box = (x, y, s = 84) => `<rect x="${x}" y="${y}" width="${s}" height="${s}" rx="14"/>`;

function seeded(seed) {
  return () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
}
function shuffle(list, rnd) {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// Art catalogue: [drawing, width, height, centre x, centre y, singular, plural]
const ART = {
  fish: [A.fish, 175, 115, -14, -4, 'fish', 'fish'],
  apple: [A.apple, 115, 122, 0, -6, 'apple', 'apples'],
  duck: [A.duck, 185, 115, 6, -6, 'duck', 'ducks'],
  cat: [A.cat, 140, 115, 0, -8, 'cat', 'cats'],
  star: [A.star, 112, 106, 0, 0, 'star', 'stars'],
  ladybug: [A.ladybug, 104, 145, 0, -14, 'ladybug', 'ladybugs'],
  flower: [A.flower, 108, 148, 0, -2, 'flower', 'flowers'],
  balloon: [A.balloon, 90, 158, 0, 14, 'balloon', 'balloons'],
  bee: [A.bee, 130, 112, -6, -10, 'bee', 'bees'],
  frog: [A.frog, 118, 110, 0, 10, 'frog', 'frogs'],
  butterfly: [A.butterfly, 152, 130, 0, -4, 'butterfly', 'butterflies'],
  heart: [A.heart, 112, 100, 0, 2, 'heart', 'hearts'],
  ball: [A.ball, 100, 100, 0, 0, 'ball', 'balls'],
  snail: [A.snail, 150, 95, 8, -2, 'snail', 'snails'],
  bunny: [A.bunny, 84, 175, 0, -10, 'bunny', 'bunnies'],
  cupcake: [A.cupcake, 112, 135, 0, -8, 'cupcake', 'cupcakes'],
  car: [A.car, 152, 72, 1, -10, 'car', 'cars'],
  owl: [A.owl, 112, 175, 0, -2, 'owl', 'owls'],
};
const word = (k, n) => (n === 1 ? ART[k][5] : ART[k][6]);

// One drawing centred on (x, y) at a scale that fits w x h.
function fit(k, x, y, w, h, max = 1, c) {
  const [draw, aw, ah, cx, cy] = ART[k];
  const s = Math.min(max, w / aw, h / ah);
  return { svg: g(x - cx * s, y - cy * s, s, draw(c)), s };
}

// n drawings spread over a box, as large as they fit.
function group(k, n, x, y, w, h, max = 1, mark) {
  const [, aw, ah] = ART[k];
  let best;
  for (let cols = 1; cols <= Math.min(n, 5); cols++) {
    const rows = Math.ceil(n / cols);
    const s = Math.min(max, (w / cols) / (aw * 1.12), (h / rows) / (ah * 1.12));
    const tie = best && Math.abs(s - best.s) < 1e-6 && Math.abs(cols - rows) < Math.abs(best.cols - best.rows);
    if (!best || s > best.s + 1e-6 || tie) best = { cols, rows, s };
  }
  const { cols, rows } = best;
  const cw = w / cols, ch = h / rows;
  let out = '';
  for (let i = 0; i < n; i++) {
    const r = Math.floor(i / cols), c = i % cols;
    const inRow = r === rows - 1 ? n - r * cols : cols;
    const px = x + (w - inRow * cw) / 2 + cw * (c + 0.5), py = y + ch * (r + 0.5);
    out += fit(k, px, py, cw / 1.12, ch / 1.12, max).svg;
    if (mark && mark(i)) {
      const d = Math.min(cw, ch) * 0.36;
      out += `<path d="M${px - d},${py - d} L${px + d},${py + d} M${px + d},${py - d} L${px - d},${py + d}" fill="none" stroke-width="8"/>`;
    }
  }
  return out;
}

const LINE = 'fill="#fff" stroke="#111" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"';
const sheet = (body) => `<div class="page"><svg viewBox="0 0 ${PW} ${PH}" xmlns="http://www.w3.org/2000/svg"><g ${LINE}>${body}</g></svg></div>`;

// Activity page: Ollie, a title band, one short instruction, the page number.
const page = (title, instruction, body, answer) => ({
  answer,
  render: (no) => sheet(`
    ${g(98, 108, 0.6, owl())}
    <rect x="160" y="58" width="608" height="86" rx="43"/>
    ${text(464, 117, title.length > 22 ? 36 : 42, title, 'title')}
    ${text(PW / 2, 202, 27, instruction)}
    ${body}
    <circle cx="${PW / 2}" cy="1010" r="20" stroke-width="4"/>
    ${text(PW / 2, 1018, 21, no, 'region')}`),
});
const plain = (body, answer) => ({ answer, render: () => sheet(body) });

const dotted = (paths, x, y, s, start = true) =>
  `<g transform="translate(${x} ${y}) scale(${s})">${paths.map((p) => `<path d="${p}" fill="none" stroke="#9a9a9a" stroke-width="${6 / s * 1.45}" stroke-dasharray="0.1 ${10 / s * 1.45}"/>`).join('')}
   ${start ? paths.map((p) => { const [mx, my] = p.slice(1).split(/[ ,]/); return `<circle cx="${mx}" cy="${my}" r="${6 / s * 1.45}" fill="#111" stroke="none"/>`; }).join('') : ''}</g>`;

const hollow = (x, y, size, t) =>
  `<text x="${x}" y="${y}" class="region" font-size="${size}" text-anchor="middle" style="fill:#fff;stroke:#111;stroke-width:7" paint-order="stroke">${t}</text>`;

function shape(type, x, y, s, extra = '') {
  if (type === 'circle') return `<circle cx="${x}" cy="${y}" r="${s / 2}" ${extra}/>`;
  if (type === 'square') return `<rect x="${x - s / 2}" y="${y - s / 2}" width="${s}" height="${s}" rx="4" ${extra}/>`;
  if (type === 'rectangle') return `<rect x="${x - s * 0.75}" y="${y - s * 0.4}" width="${s * 1.5}" height="${s * 0.8}" rx="4" ${extra}/>`;
  if (type === 'triangle') return `<path d="M${x - s / 2},${y + s * 0.43} L${x},${y - s * 0.43} L${x + s / 2},${y + s * 0.43} Z" ${extra}/>`;
  if (type === 'heart') return `<path d="M${x},${y + s * 0.45} C${x - s * 0.62},${y + s * 0.05} ${x - s * 0.55},${y - s * 0.5} ${x},${y - s * 0.25} C${x + s * 0.55},${y - s * 0.5} ${x + s * 0.62},${y + s * 0.05} ${x},${y + s * 0.45} Z" ${extra}/>`;
  if (type === 'star') {
    const p = [];
    for (let i = 0; i < 10; i++) {
      const r = (i % 2 ? 0.25 : 0.55) * s, a = -Math.PI / 2 + (i * Math.PI) / 5;
      p.push(`${(x + r * Math.cos(a)).toFixed(1)},${(y + 0.05 * s + r * Math.sin(a)).toFixed(1)}`);
    }
    return `<polygon points="${p.join(' ')}" ${extra}/>`;
  }
  return '';
}

// Colour key at the bottom of colour-by-number pages.
const key = (list) => list.map(([n, w], i) => g(PW / 2 + (i - (list.length - 1) / 2) * 165, 880, 0.95, crayon(n, w))).join('');

const WORDS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];

// ---------- front matter ----------

const titlePage = plain(`
  ${text(PW / 2, 190, 34, 'LITTLE MATH ADVENTURES · BOOK 1', 'title')}
  ${text(PW / 2, 300, 66, 'My First Numbers', 'title')}
  ${text(PW / 2, 380, 66, '&amp; Counting', 'title')}
  ${text(PW / 2, 450, 40, 'Coloring Workbook', 'title')}
  ${g(PW / 2, 650, 1.6, owl())}
  ${g(200, 620, 0.8, A.star())}${g(620, 600, 0.8, A.star())}
  ${text(PW / 2, 870, 32, 'Ages 4–5 · Pre-K &amp; Kindergarten', 'say')}
  ${text(PW / 2, 920, 26, 'Count · Trace · Color · Match · Shapes · Add', 'say')}
`);

const copyright = plain(`
  ${text(PW / 2, 600, 22, 'My First Numbers &amp; Counting Coloring Workbook', 'say')}
  ${text(PW / 2, 636, 20, 'Little Math Adventures · Book 1', 'say')}
  ${text(PW / 2, 690, 20, 'Copyright © 2026 [Author Name]. All rights reserved.', 'say')}
  ${text(PW / 2, 726, 18, 'No part of this book may be copied or shared without written permission,', 'say')}
  ${text(PW / 2, 752, 18, 'except for personal use with your own child or classroom.', 'say')}
  ${text(PW / 2, 806, 18, 'All illustrations and text are original.', 'say')}
  ${text(PW / 2, 860, 18, 'Tip: crayons and colored pencils work best. Markers can show through,', 'say')}
  ${text(PW / 2, 886, 18, 'so slide a sheet of paper behind the page.', 'say')}
`);

const belongs = plain(`
  ${text(PW / 2, 150, 46, 'This book belongs to:', 'title')}
  <path d="M150,250 L666,250" fill="none" stroke-width="5"/>
  ${g(PW / 2, 470, 2.1, owl())}
  ${g(170, 470, 0.9, A.star())}${g(650, 430, 0.9, A.star())}${g(110, 640, 0.7, A.star())}
  <path d="M200,700 L384,700 L408,668 L432,700 L616,700 Q646,700 646,730 L646,790 Q646,820 616,820 L200,820 Q170,820 170,790 L170,730 Q170,700 200,700 Z"/>
  ${text(PW / 2, 752, 30, 'Hi! I am Ollie the Owl.')}
  ${text(PW / 2, 794, 30, "Let's count, color, and learn!")}
`);

const grownups = plain(`
  ${g(110, 120, 0.6, owl())}
  ${text(180, 135, 44, 'For Grown-Ups', 'title', 'start')}
  ${[
    'This book helps your child learn numbers 1 to 10 through',
    'counting, tracing, coloring, and simple adding and taking away.',
    '',
    '• Do one or two pages a day. Short and happy is best.',
    '• Read the short line at the top of each page aloud.',
    '• Let your child count out loud and touch each picture.',
    '• Praise effort, not only right answers.',
    '• Answers are at the back of the book.',
  ].map((l, i) => text(80, 250 + i * 38, 23, l, 'say', 'start')).join('')}
  ${text(80, 610, 28, 'What your child will practice', 'title', 'start')}
  ${[
    ['Write numbers 0–20 (starting with 1–10)', 'K.CC.A.3'],
    ['Count objects and match them to a number', 'K.CC.B.4, K.CC.B.5'],
    ['Compare groups: more, fewer, the same', 'K.CC.C.6'],
    ['Name and find circles, squares, triangles', 'K.G.A.2'],
    ['Add and take away with pictures', 'K.OA.A.1'],
    ['Add and subtract within 5', 'K.OA.A.5'],
  ].map(([a, b], i) => `<rect x="70" y="${640 + i * 50}" width="676" height="44" rx="10" stroke-width="3"/>
     ${text(88, 670 + i * 50, 20, a, 'say', 'start')}${text(730, 670 + i * 50, 18, b, 'say', 'end')}`).join('')}
  ${text(PW / 2, 975, 18, 'Activities are aligned with selected Common Core Kindergarten math standards.', 'say')}
`);

// ---------- numbers 1–10 ----------

const NUMBER_ART = ['', 'bunny', 'cat', 'fish', 'ladybug', 'balloon', 'flower', 'star', 'heart', 'bee', 'apple'];

function numberPage(n) {
  const k = NUMBER_ART[n];
  const copies = n === 10 ? 3 : 4, s = n === 10 ? 1.15 : 1.45, step = n === 10 ? 140 : 108;
  const traces = Array.from({ length: copies }, (_, i) => dotted(DIGITS[n], 335 + i * step, 262, s)).join('');
  const frameBoxes = Array.from({ length: 10 }, (_, i) => box(388 + (i % 5) * 74, 836 + Math.floor(i / 5) * 72, 66)).join('');
  return page(`The Number ${n}`, `Color the ${n}. Trace the ${n}s.`, `
    ${hollow(190, 455, n === 10 ? 220 : 300, n)}
    ${traces}
    ${text(530, 480, 64, WORDS[n], 'trace')}
    <path d="M60,515 L756,515" fill="none" stroke-width="3" stroke-dasharray="10 12"/>
    ${text(PW / 2, 566, 28, `Count the ${word(k, n)}. Color ${n === 1 ? 'it' : 'them'}.`)}
    ${group(k, n, 60, 590, 696, 210, 1)}
    ${text(80, 892, 28, `Color ${n} ${n === 1 ? 'box' : 'boxes'}.`, 'say', 'start')}
    ${frameBoxes}`,
    `${n} ${word(k, n)}; ${n} ${n === 1 ? 'box' : 'boxes'} colored`);
}

const HUNT_SHAPES = ['circle', 'star', 'heart', 'square', 'circle', 'star', 'heart', 'square', 'circle', 'star'];

function huntPage(n) {
  const rnd = seeded(n * 97 + 13);
  const target = 4 + (n % 4);
  const cells = shuffle([...Array(target).fill(n), ...Array.from({ length: 20 - target }, () => {
    let d;
    do d = 1 + Math.floor(rnd() * 9); while (d === n || (n === 10 && d === 1));
    return d;
  })], rnd);
  const kind = HUNT_SHAPES[n - 1];
  const size = kind === 'star' ? 132 : kind === 'heart' ? 128 : 108;
  const body = cells.map((d, i) => {
    const x = 60 + 139 * (i % 5) + 70, y = 255 + 136 * Math.floor(i / 5) + 68;
    const ty = y + (kind === 'heart' ? 10 : kind === 'star' ? 18 : 16);
    return shape(kind, x, y, size) + text(x, ty, kind === 'star' ? 34 : 44, d, 'region');
  }).join('');
  return page(`Find the ${n}s!`, `Color every shape with the number ${n}.`, `
    ${body}
    ${text(70, 922, 28, `How many ${n}s did you find?`, 'say', 'start')}${box(445, 870, 80)}
    ${g(660, 900, 0.75, owl())}`, `${target}`);
}

// ---------- counting ----------

function matchPage(rows, order) {
  const ys = [330, 495, 660, 825];
  return page('Count and Match', 'Count. Draw a line to the number.', `
    ${rows.map(([k, n], i) => group(k, n, 50, ys[i] - 70, 390, 140, 0.8)).join('')}
    ${ys.map((y) => `<circle cx="470" cy="${y}" r="10" fill="#111" stroke="none"/>`).join('')}
    ${ys.map((y, i) => `<circle cx="590" cy="${y}" r="10" fill="#111" stroke="none"/>
       <circle cx="680" cy="${y}" r="56"/>${text(680, y + 30, 84, order[i], 'region')}`).join('')}`,
    rows.map(([k, n]) => `${word(k, n)} ${n}`).join(', '));
}

function howManyPage(rows) {
  const ys = [320, 485, 650, 815];
  return page('How Many?', 'Count. Color the right number.', `
    ${rows.map(([k, n, choices], i) => `${group(k, n, 50, ys[i] - 70, 420, 140, 0.8)}
      <rect x="40" y="${ys[i] - 78}" width="736" height="156" rx="24" fill="none" stroke-width="3"/>
      ${choices.map((c, j) => `<circle cx="${560 + j * 85}" cy="${ys[i]}" r="34" stroke-width="4"/>${text(560 + j * 85, ys[i] + 17, 46, c, 'region')}`).join('')}`).join('')}`,
    rows.map(([k, n]) => `${n}`).join(', '));
}

function writePage(cells) {
  return page('Count and Write', 'Count. Write the number in the box.', `
    ${cells.map(([k, n], i) => {
      const x = 60 + (i % 2) * 358, y = 250 + Math.floor(i / 2) * 360;
      return `<rect x="${x}" y="${y}" width="338" height="340" rx="28"/>
        ${group(k, n, x + 15, y + 15, 308, 220, 0.75)}${box(x + 129, y + 246, 80)}`;
    }).join('')}`, cells.map(([k, n]) => `${word(k, n)} ${n}`).join(', '));
}

const tally = (items) => `
  ${items.map(([k], i) => `${fit(k, 120 + i * 240, 900, 90, 80, 0.6).svg}${box(185 + i * 240, 860, 80)}`).join('')}`;

const pond = page('At the Pond', 'Count the ducks, fish, and frogs.', `
  ${g(690, 300, 0.7, sun())}
  <path d="M120,320 Q140,290 175,300 Q200,270 235,295 Q265,295 262,322 Z" stroke-width="5"/>
  <path d="M50,470 Q130,450 210,470 Q300,490 400,468 Q500,446 600,470 Q690,490 766,470 L766,790 L50,790 Z" stroke-width="5"/>
  <ellipse cx="640" cy="525" rx="80" ry="24" stroke-width="5"/>
  <ellipse cx="600" cy="705" rx="70" ry="22" stroke-width="5"/>
  ${fit('duck', 150, 440, 120, 80, 0.6).svg}${fit('duck', 320, 430, 120, 80, 0.6).svg}${fit('duck', 480, 445, 120, 80, 0.6).svg}
  ${fit('frog', 640, 490, 90, 80, 0.6).svg}${fit('frog', 600, 670, 90, 80, 0.55).svg}
  ${fit('fish', 150, 580, 110, 70, 0.6).svg}${fit('fish', 380, 575, 110, 70, 0.6).svg}
  ${fit('fish', 230, 700, 110, 70, 0.6).svg}${fit('fish', 420, 700, 110, 70, 0.6).svg}
  ${tally([['duck'], ['fish'], ['frog']])}`, 'ducks 3, fish 4, frogs 2');

const garden = page('In the Garden', 'Count the flowers, bees, and butterflies.', `
  ${g(110, 300, 0.55, sun())}
  <path d="M50,700 Q200,680 408,694 Q620,708 766,690" fill="none" stroke-width="5"/>
  ${[110, 250, 390, 530, 670].map((x) => fit('flower', x, 640, 120, 130, 0.8).svg).join('')}
  ${fit('bee', 260, 380, 110, 90, 0.55).svg}${fit('bee', 460, 300, 110, 90, 0.55).svg}${fit('bee', 650, 420, 110, 90, 0.55).svg}
  ${fit('butterfly', 380, 470, 110, 90, 0.6).svg}${fit('butterfly', 620, 300, 110, 90, 0.6).svg}
  ${tally([['flower'], ['bee'], ['butterfly']])}`, 'flowers 5, bees 3, butterflies 2');

// ---------- comparing ----------

const panel = (x, y, w = 330, h = 250) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="28"/>`;
function comparePage(top, bottom) {
  const [k1, a1, b1] = top, [k2, a2, b2] = bottom;
  return page('More or Fewer?', 'Look. Count. Compare.', `
    ${text(PW / 2, 272, 27, `Color the group with MORE ${word(k1, 2)}.`)}
    ${panel(60, 295)}${panel(426, 295)}
    ${group(k1, a1, 75, 310, 300, 220, 0.62)}${group(k1, b1, 441, 310, 300, 220, 0.62)}
    ${text(PW / 2, 622, 27, `Circle the group with FEWER ${word(k2, 2)}.`)}
    ${panel(60, 645)}${panel(426, 645)}
    ${group(k2, a2, 75, 660, 300, 220, 0.62)}${group(k2, b2, 441, 660, 300, 220, 0.62)}`,
    `more: ${a1 > b1 ? 'left' : 'right'} (${Math.max(a1, b1)}); fewer: ${a2 < b2 ? 'left' : 'right'} (${Math.min(a2, b2)})`);
}

const samePage = (() => {
  const left = [['heart', 2], ['ball', 4], ['flower', 3]];
  const right = [['ladybug', 4], ['apple', 3], ['car', 2]];
  const ys = [340, 560, 780];
  return page('The Same Number', 'Draw a line to the group with the same number.', `
    ${left.map(([k, n], i) => `<rect x="50" y="${ys[i] - 90}" width="300" height="180" rx="24" stroke-width="4"/>${group(k, n, 62, ys[i] - 80, 276, 160, 0.7)}
       <circle cx="370" cy="${ys[i]}" r="10" fill="#111" stroke="none"/>`).join('')}
    ${right.map(([k, n], i) => `<rect x="466" y="${ys[i] - 90}" width="300" height="180" rx="24" stroke-width="4"/>${group(k, n, 478, ys[i] - 80, 276, 160, 0.7)}
       <circle cx="446" cy="${ys[i]}" r="10" fill="#111" stroke="none"/>`).join('')}`,
    'hearts 2 → cars, balls 4 → ladybugs, flowers 3 → apples');
})();

const bigSmall = (() => {
  const rows = [['bunny', true], ['cupcake', false], ['frog', false], ['balloon', true]];
  const ys = [320, 490, 660, 830];
  return page('Big and Small', 'Color the BIG one. Circle the small one.', `
    ${rows.map(([k, bigLeft], i) => `${fit(k, 260, ys[i], 200, 150, bigLeft ? 1 : 0.45).svg}${fit(k, 556, ys[i], 200, 150, bigLeft ? 0.45 : 1).svg}`).join('')}`,
    rows.map(([k, l]) => `${k}: big ${l ? 'left' : 'right'}`).join(', '));
})();

const countCompare = (() => {
  const rows = [['apple', 3, 5], ['bee', 6, 4], ['star', 7, 8]];
  const ys = [300, 520, 740];
  return page('Which Is More?', 'Count. Write the numbers. Circle the bigger one.', `
    ${rows.map(([k, a, b], i) => `
      <rect x="50" y="${ys[i] - 60}" width="330" height="200" rx="24" stroke-width="4"/>
      <rect x="436" y="${ys[i] - 60}" width="330" height="200" rx="24" stroke-width="4"/>
      ${group(k, a, 62, ys[i] - 52, 306, 110, 0.55)}${group(k, b, 448, ys[i] - 52, 306, 110, 0.55)}
      ${box(180, ys[i] + 62, 70)}${box(566, ys[i] + 62, 70)}`).join('')}`,
    rows.map(([, a, b]) => `${a} and ${b} → ${Math.max(a, b)}`).join('; '));
})();

// ---------- shapes ----------

function shapePage(kind, title) {
  const rnd = seeded(kind.length * 31 + 7);
  const others = ['circle', 'square', 'triangle', 'rectangle'].filter((s) => s !== kind);
  const count = kind === 'circle' ? 5 : kind === 'square' ? 4 : kind === 'triangle' ? 5 : 4;
  const list = shuffle([...Array(count).fill(kind), ...Array.from({ length: 12 - count }, (_, i) => others[i % 3])], rnd);
  const sizes = kind === 'rectangle' ? [60, 80, 100, 120] : [70, 95, 120, 145];
  let x = 90;
  const traces = sizes.map((s) => {
    const w = kind === 'rectangle' ? s * 1.5 : s;
    const cx = x + w / 2;
    x += w + 40;
    return shape(kind, cx, 345, s, 'fill="none" stroke="#9a9a9a" stroke-width="6" stroke-dasharray="0.1 11"');
  });
  const shift = (PW - (x - 40) - 90) / 2;
  return page(title, `Trace the ${kind}s.`, `
    <g transform="translate(${shift} 0)">${traces.join('')}</g>
    <path d="M60,450 L756,450" fill="none" stroke-width="3" stroke-dasharray="10 12"/>
    ${text(PW / 2, 505, 28, `Color only the ${kind}s.`)}
    ${list.map((s, i) => shape(s, 140 + (i % 4) * 178, 565 + Math.floor(i / 4) * 120, 88)).join('')}
    ${text(380, 945, 28, `How many ${kind}s?`, 'say', 'end')}${box(400, 895, 76)}`,
    `${count}`);
}

const shapeKey = ([circle, square, triangle, rectangle]) => `
  <g transform="translate(0 -10)">
    <rect x="148" y="265" width="250" height="56" rx="14" stroke-width="5"/>
    <circle cx="176" cy="293" r="16" stroke-width="4"/>${text(280, 303, 26, circle)}
    <rect x="418" y="265" width="250" height="56" rx="14" stroke-width="5"/>
    <rect x="430" y="277" width="32" height="32" stroke-width="4"/>${text(560, 303, 26, square)}
    <rect x="148" y="335" width="250" height="56" rx="14" stroke-width="5"/>
    ${shape('triangle', 176, 363, 36, 'stroke-width="4"')}${text(280, 373, 26, triangle)}
    <rect x="418" y="335" width="250" height="56" rx="14" stroke-width="5"/>
    <rect x="430" y="349" width="44" height="28" stroke-width="4"/>${text(565, 373, 26, rectangle)}
  </g>`;
const SHAPE_KEY = shapeKey(['red', 'blue', 'yellow', 'green']);

const train = page('Shape Train', 'Color the shapes. Use the key.', `
  ${SHAPE_KEY}
  <rect x="70" y="560" width="190" height="110" rx="12"/>
  <rect x="120" y="500" width="40" height="64" rx="6"/>
  <rect x="250" y="470" width="125" height="200" rx="12"/>
  <rect x="270" y="500" width="76" height="76" rx="4"/>
  <path d="M236,462 L390,462" fill="none" stroke-width="10"/>
  <rect x="405" y="575" width="160" height="95" rx="12"/>
  <rect x="455" y="592" width="60" height="60" rx="4"/>
  ${shape('triangle', 485, 510, 140)}
  <rect x="595" y="575" width="160" height="95" rx="12"/>
  <rect x="645" y="592" width="60" height="60" rx="4"/>
  ${shape('triangle', 635, 540, 70)}${shape('triangle', 715, 540, 70)}
  <path d="M375,640 L405,640 M565,640 L595,640" fill="none" stroke-width="8"/>
  <circle cx="125" cy="700" r="40"/><circle cx="300" cy="700" r="40"/>
  <circle cx="445" cy="704" r="30"/><circle cx="525" cy="704" r="30"/>
  <circle cx="635" cy="704" r="30"/><circle cx="715" cy="704" r="30"/>
  <path d="M40,742 L776,742" fill="none" stroke-width="6"/>
  ${[80, 180, 280, 380, 480, 580, 680].map((x) => `<path d="M${x},742 L${x + 30},770" fill="none" stroke-width="5"/>`).join('')}
  ${text(80, 846, 30, 'How many circles?', 'say', 'start')}${box(400, 798, 78)}
  ${text(80, 942, 30, 'How many triangles?', 'say', 'start')}${box(400, 894, 78)}
  ${g(640, 880, 0.9, owl())}`, 'circles 6, triangles 3');

// Windows and sun are circles, roof and tree are triangles, walls a square,
// chimney, door and trunk rectangles: the key colours all make sense.
const house = page('Shape House', 'Color the shapes. Use the key.', `
  ${shapeKey(['yellow', 'blue', 'green', 'brown'])}
  <circle cx="664" cy="481" r="49"/>
  <rect x="272" y="452" width="36" height="100" rx="3"/>
  <path d="M187,639 L332.5,418 L478,639 Z"/>
  <rect x="204" y="639" width="257" height="254" rx="3"/>
  <circle cx="267" cy="717" r="41"/><circle cx="397" cy="717" r="41"/>
  <rect x="293" y="773" width="81" height="120" rx="3"/>
  <rect x="597" y="751" width="35" height="142" rx="3"/>
  ${shape('triangle', 612, 668, 208)}
  <path d="M60,893 L762,893" fill="none" stroke-width="6"/>
  ${text(60, 965, 22, 'How many circles?', 'say', 'start')}${box(268, 918, 72)}
  ${text(400, 965, 22, 'How many rectangles?', 'say', 'start')}${box(672, 918, 72)}`, 'circles 3, rectangles 3');

const robot = page('Shape Robot', 'Count each shape. Write how many.', `
  <rect x="396" y="232" width="24" height="44" rx="4"/>
  <circle cx="408" cy="232" r="16"/>
  ${shape('triangle', 285, 340, 50)}${shape('triangle', 531, 340, 50)}
  <rect x="308" y="276" width="200" height="200" rx="6"/>
  <circle cx="368" cy="346" r="26"/><circle cx="448" cy="346" r="26"/>
  <rect x="358" y="410" width="100" height="34" rx="4"/>
  <rect x="288" y="500" width="240" height="160" rx="6"/>
  <circle cx="370" cy="580" r="22"/><circle cx="446" cy="580" r="22"/>
  <rect x="186" y="515" width="104" height="40" rx="4"/><rect x="526" y="515" width="104" height="40" rx="4"/>
  <rect x="130" y="505" width="60" height="60" rx="4"/><rect x="626" y="505" width="60" height="60" rx="4"/>
  <rect x="330" y="664" width="50" height="110" rx="4"/><rect x="436" y="664" width="50" height="110" rx="4"/>
  ${shape('triangle', 355, 800, 60)}${shape('triangle', 461, 800, 60)}
  ${[['circle'], ['square'], ['triangle'], ['rectangle']].map(([s], i) => `${shape(s, 150 + i * 172, 862, 44, 'stroke-width="5"')}${box(115 + i * 172, 896, 70)}`).join('')}`,
  'circles 5, squares 3, triangles 4, rectangles 7');

const patterns = (() => {
  const rows = [
    [['circle', 'square', 'circle', 'square', 'circle'], 'square'],
    [['triangle', 'triangle', 'circle', 'triangle', 'triangle'], 'circle'],
    [['apple', 'fish', 'apple', 'fish', 'apple'], 'fish'],
    [['square', 'circle', 'triangle', 'square', 'circle'], 'triangle'],
  ];
  const ys = [320, 490, 660, 830];
  return page('What Comes Next?', 'Look at the pattern. Draw what comes next.', `
    ${rows.map(([list], i) => list.map((s, j) => {
      const x = 105 + j * 118;
      return ART[s] ? fit(s, x, ys[i], 100, 100, 0.65).svg : shape(s, x, ys[i], 80);
    }).join('') + `<rect x="${105 + 5 * 118 - 55}" y="${ys[i] - 60}" width="120" height="120" rx="18" stroke-dasharray="14 12" stroke-width="5"/>`).join('')}`,
    rows.map(([, a]) => a).join(', '));
})();

// ---------- colour by number ----------

const cbn = (title, art, colours, answer = 'Answers will vary') =>
  page(title, 'Color the crayons first. Then color by number!', `${art}${key(colours)}`, answer);

const cbnTurtle = cbn('Color the Turtle', `
  ${g(660, 320, 0.9, sun())}<text x="660" y="321" class="region" font-size="30" text-anchor="middle" dominant-baseline="central">2</text>
  <path d="M120,320 Q140,290 175,300 Q200,270 235,295 Q265,295 262,322 Z" stroke-width="5"/>
  ${g(370, 520, 2.15, A.turtle())}
  <path d="M50,736 Q200,712 408,730 Q620,748 766,724" fill="none" stroke-width="5"/>`,
  [[1, 'green'], [2, 'yellow'], [3, 'orange'], [4, 'brown']]);

const plainStar = (x, y, s, n) => shape('star', x, y, s) + `<text x="${x}" y="${y + 6}" class="region" font-size="24" text-anchor="middle" dominant-baseline="central">${n}</text>`;

const cbnOwl = cbn('Color the Owl', `
  ${plainStar(140, 330, 110, 2)}${plainStar(680, 330, 110, 2)}${plainStar(130, 640, 80, 2)}${plainStar(690, 620, 80, 2)}
  <g transform="translate(408 515) scale(2.8)">${owl()}${nums([[0, -60, 1], [-34, -68, 1, 20], [34, -68, 1, 20], [0, 54, 2], [-51, 24, 3, 26], [51, 24, 3, 26], [0, -6, 4, 20]].map(([x, y, t]) => [x, y, t]), 2.8)}</g>`,
  [[1, 'brown'], [2, 'yellow'], [3, 'red'], [4, 'orange']]);

const seaweed = (x, h) => `<path d="M${x},780 C${x - 30},${780 - h * 0.35} ${x + 30},${780 - h * 0.65} ${x},${780 - h} Q${x + 20},${770 - h} ${x + 40},${780 - h} C${x + 70},${780 - h * 0.65} ${x + 10},${780 - h * 0.35} ${x + 40},780 Z" stroke-width="5"/>`;
const label = (x, y, t, s = 26) => `<text x="${x}" y="${y}" class="region" font-size="${s}" text-anchor="middle" dominant-baseline="central">${t}</text>`;

const cbnFish = cbn('Color the Fish', `
  ${seaweed(80, 230)}${label(100, 680, 4)}${seaweed(680, 180)}${label(700, 700, 4)}
  <circle cx="650" cy="330" r="30"/>${label(650, 331, 3)}<circle cx="700" cy="420" r="22"/>${label(700, 421, 3, 22)}<circle cx="150" cy="380" r="26"/>${label(150, 381, 3, 24)}
  <g transform="translate(430 520) scale(3)">${A.fish()}${nums([[-38, 2, 1], [8, -6, 1], [-74, 0, 2, 26], [14, -46, 2, 22], [12, 23, 2, 20]], 3)}</g>`,
  [[1, 'orange'], [2, 'yellow'], [3, 'blue'], [4, 'green']]);

const cbnDuck = cbn('Color the Duck', `
  ${g(130, 320, 0.8, sun())}${label(130, 321, 2)}
  <path d="M50,620 Q150,596 250,620 Q350,644 450,620 Q550,596 650,620 Q710,636 766,620 L766,780 L50,780 Z" stroke-width="5"/>
  ${label(110, 720, 4)}${label(700, 720, 4)}
  <g transform="translate(400 470) scale(2.8)">${A.duck()}${nums([[34, 38, 1], [24, -18, 1], [-66, -11, 1, 16], [-6, 18, 3], [80, -28, 2, 16]], 2.8)}</g>`,
  [[1, 'yellow'], [2, 'orange'], [3, 'brown'], [4, 'blue']]);

const cbnLadybug = cbn('Color the Ladybug', `
  <path d="M110,740 Q200,330 700,330 Q690,700 110,740 Z" stroke-width="6"/>
  <path d="M110,740 Q420,560 700,330" fill="none" stroke-width="4"/>
  ${label(220, 640, 3)}${label(620, 420, 3)}${label(560, 640, 3)}
  <g transform="translate(408 520) scale(2.6)">${A.ladybug()}${nums([[-18, 44, 1], [18, 44, 1], [-30, -18, 1, 20], [30, -18, 1, 20], [-24, -10, 2, 16], [24, -10, 2, 16], [-28, 24, 2, 16], [28, 24, 2, 16], [0, -66, 2, 14]], 2.6)}</g>`,
  [[1, 'red'], [2, 'black'], [3, 'green']]);

const cbnButterfly = cbn('Color the Butterfly', `
  <g transform="translate(408 510) scale(3)">${A.butterfly()}${nums([[-24, -22, 1], [24, -22, 1], [-20, 42, 2, 26], [20, 42, 2, 26], [-44, -26, 3, 22], [44, -26, 3, 22], [-38, 30, 3, 18], [38, 30, 3, 18], [0, 10, 4, 22]], 3)}</g>
  ${fit('flower', 110, 700, 120, 150, 0.9, { plain: true }).svg}${fit('flower', 706, 700, 120, 150, 0.9, { plain: true }).svg}`,
  [[1, 'purple'], [2, 'blue'], [3, 'yellow'], [4, 'brown']]);

const cbnFlower = (() => {
  let petals = [];
  for (let i = 0; i < 6; i++) {
    const a = (i * Math.PI) / 3;
    petals.push([+(38 * Math.cos(a)).toFixed(1), +(-24 + 38 * Math.sin(a)).toFixed(1), 1, 20]);
  }
  return cbn('Color the Flower', `
    <g transform="translate(408 430) scale(2.6)">${A.flower({ plain: true })}${nums([...petals, [0, -24, 2], [-26, 46, 3, 16], [26, 32, 3, 16]], 2.6)}</g>
    <path d="M290,606 L526,606 L526,650 L290,650 Z"/>
    <path d="M304,650 L512,650 L490,780 L326,780 Z"/>
    ${label(408, 629, 4, 24)}${label(408, 715, 4)}`,
    [[1, 'pink'], [2, 'yellow'], [3, 'green'], [4, 'brown']]);
})();

const cbnBalloons = cbn('Color the Balloons', `
  <g transform="translate(250 400) scale(1.8)">${A.balloon()}${nums([[0, 18, 1]], 1.8)}</g>
  <g transform="translate(408 350) scale(1.8)">${A.balloon()}${nums([[0, 18, 2]], 1.8)}</g>
  <g transform="translate(566 410) scale(1.8)">${A.balloon()}${nums([[0, 18, 3]], 1.8)}</g>
  <path d="M250,555 Q320,620 372,668 M408,505 Q406,590 408,640 M566,565 Q500,620 444,668" fill="none" stroke-width="4"/>
  <g transform="translate(408 690) scale(1.1)">${A.bunny()}${nums([[0, 30, 4, 22], [0, 56, 4, 24]], 1.1)}</g>`,
  [[1, 'red'], [2, 'blue'], [3, 'green'], [4, 'gray']]);

// ---------- dot to dot ----------

function dotPage(title, pts, extra, answer) {
  const cx = pts.reduce((s, p) => s + p[0], 0) / pts.length, cy = pts.reduce((s, p) => s + p[1], 0) / pts.length;
  return page(title, 'Connect the dots from 1 to 10. Then color it!', `
    ${extra}
    ${pts.map(([x, y], i) => {
      const dx = x - cx, dy = y - cy, d = Math.hypot(dx, dy) || 1;
      const lx = x + (dx / d) * 34, ly = y + (dy / d) * 34 + 10;
      return `<circle cx="${x}" cy="${y}" r="8" fill="#111" stroke="none"/>${text(lx, ly, 30, i + 1, 'region')}`;
    }).join('')}
    ${text(pts[0][0], pts[0][1] + (pts[0][1] > cy ? 74 : -50), 20, 'start', 'say')}`, answer);
}

const starDots = (() => {
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? 115 : 270, a = -Math.PI / 2 + (i * Math.PI) / 5;
    pts.push([Math.round(408 + r * Math.cos(a)), Math.round(590 + r * Math.sin(a))]);
  }
  return dotPage('Dot to Dot: Star', pts, `${eye(380, 600, 10)}${eye(436, 600, 10)}<path d="M392,630 Q408,644 424,630" fill="none" stroke-width="5"/>`, 'a star');
})();

const fishDots = dotPage('Dot to Dot: Fish', [[650, 570], [570, 440], [420, 410], [280, 470], [150, 380], [200, 570], [150, 760], [280, 670], [420, 730], [570, 700]],
  `${eye(565, 540, 12)}<path d="M580,600 Q596,612 612,598" fill="none" stroke-width="5"/><path d="M380,470 Q420,570 380,670" fill="none" stroke-width="5"/>`, 'a fish');

const heartDots = dotPage('Dot to Dot: Heart', [[408, 840], [250, 690], [160, 540], [190, 400], [300, 340], [408, 430], [516, 340], [626, 400], [656, 540], [566, 690]],
  `${eye(350, 540, 12)}${eye(466, 540, 12)}<path d="M388,590 Q408,606 428,590" fill="none" stroke-width="5"/>`, 'a heart');

const crownDots = dotPage('Dot to Dot: Crown', [[200, 800], [408, 800], [616, 800], [640, 470], [560, 610], [476, 420], [408, 570], [340, 420], [256, 610], [176, 470]],
  `<circle cx="300" cy="720" r="22"/><circle cx="408" cy="720" r="22"/><circle cx="516" cy="720" r="22"/>`, 'a crown');

// ---------- adding and taking away ----------

function sumRow(y, k, a, b) {
  const w = Math.min(130, (696 - 232) / (a + b));
  const total = (a + b) * w + 232;
  const x0 = (PW - total) / 2;
  const plusX = x0 + a * w + 35, eqX = plusX + 35 + b * w + 35;
  return `${group(k, a, x0, y - 60, a * w, 120, 0.6)}${text(plusX, y + 22, 60, '+', 'region')}
    ${group(k, b, plusX + 35, y - 60, b * w, 120, 0.6)}${text(eqX, y + 22, 60, '=', 'region')}${box(eqX + 35, y - 46, 92)}
    ${text(x0 + (a * w) / 2, y + 110, 44, a, 'region')}${text(plusX + 35 + (b * w) / 2, y + 110, 44, b, 'region')}`;
}
const addPage = (rows) => page("Let's Add!", 'Count them all. Write how many.',
  rows.map(([k, a, b], i) => sumRow(330 + i * 250, k, a, b)).join(''), rows.map(([, a, b]) => `${a}+${b}=${a + b}`).join(', '));

function takeRow(y, k, a, b) {
  const w = Math.min(140, 696 / a);
  return `${group(k, a, (PW - a * w) / 2, y - 70, a * w, 140, 0.65, (i) => i >= a - b)}
    ${text(PW / 2 - 40, y + 130, 52, `${a} − ${b} =`, 'region')}${box(PW / 2 + 70, y + 76, 84)}`;
}
const takePage = (rows) => page('Take Away', 'Some go away. How many are left?',
  rows.map(([k, a, b], i) => takeRow(310 + i * 245, k, a, b)).join(''), rows.map(([, a, b]) => `${a}−${b}=${a - b}`).join(', '));

// ---------- review ----------

const missing = (() => {
  const row = (y, list) => list.map((n, i) => {
    const x = 90 + i * 132;
    return `<rect x="${x}" y="${y}" width="112" height="100" rx="12"/>
      <circle cx="${x + 28}" cy="${y + 112}" r="16"/><circle cx="${x + 84}" cy="${y + 112}" r="16"/>
      ${i ? `<path d="M${x - 20},${y + 60} L${x},${y + 60}" fill="none" stroke-width="7"/>` : ''}
      ${n ? text(x + 56, y + 72, 60, n, 'region') : `<rect x="${x + 22}" y="${y + 14}" width="68" height="72" rx="8" stroke-width="3" stroke-dasharray="8 8"/>`}`;
  }).join('');
  return page('Missing Numbers', 'Write the missing numbers on the train.', `
    ${row(300, [1, 0, 3, 0, 5])}${row(520, [6, 7, 0, 9, 0])}
    <path d="M50,652 L766,652 M50,432 L766,432" fill="none" stroke-width="5"/>
    ${g(408, 830, 1.1, owl())}${g(220, 830, 0.8, A.star())}${g(596, 830, 0.8, A.star())}`, '2, 4, 8, 10');
})();

const traceAll = page('Trace 1 to 10', 'Say each number. Trace it.', Array.from({ length: 10 }, (_, i) => {
  const n = i + 1, col = i < 5 ? 0 : 1, r = i % 5;
  const x = 70 + col * 360, y = 250 + r * 146;
  const s = 0.95, step = n === 10 ? 112 : 76;
  return `<rect x="${x - 14}" y="${y - 10}" width="340" height="130" rx="18" stroke-width="3"/>
    ${text(x + (n === 10 ? 40 : 26), y + 92, 96, n, 'region')}
    ${(n === 10 ? [0, 1] : [0, 1, 2]).map((j) => dotted(DIGITS[n], x + (n === 10 ? 104 : 86) + j * step, y + 14, s)).join('')}`;
}).join(''), 'trace 1 to 10');

const graph = (() => {
  const items = [['apple', [[120, 300], [300, 360], [520, 290], [690, 380]]], ['fish', [[210, 460], [610, 470]]], ['star', [[130, 400], [400, 290], [420, 450], [620, 300], [720, 470]]]];
  return page('Picture Graph', 'Count each kind. Color one box for each one.', `
    <rect x="50" y="240" width="716" height="280" rx="24" stroke-width="4"/>
    ${items.map(([k, at]) => at.map(([x, y]) => fit(k, x, y, 90, 80, 0.55).svg).join('')).join('')}
    ${items.map(([k], i) => `${fit(k, 110, 610 + i * 92, 80, 76, 0.55).svg}${Array.from({ length: 6 }, (_, j) => `<rect x="${180 + j * 84}" y="${574 + i * 92}" width="76" height="76" rx="8" stroke-width="5"/>`).join('')}`).join('')}
    ${text(PW / 2, 910, 27, 'Which kind has the most? Circle it in the graph.')}`, 'apples 4, fish 2, stars 5; the stars have the most');
})();

const challenge = page("Ollie's Challenge", 'You can do it! Four little puzzles.', `
  ${panel(50, 240, 345, 330)}${panel(421, 240, 345, 330)}${panel(50, 600, 345, 330)}${panel(421, 600, 345, 330)}
  ${text(222, 285, 24, 'How many hearts?')}${group('heart', 7, 70, 300, 305, 170, 0.5)}${box(185, 480, 74)}
  ${text(593, 285, 24, 'Color the bigger number.')}
  <circle cx="520" cy="420" r="62"/>${text(520, 450, 84, 4, 'region')}<circle cx="666" cy="420" r="62"/>${text(666, 450, 84, 9, 'region')}
  ${text(222, 645, 24, 'Add the dots.')}
  ${[0, 1].map((i) => `<rect x="${78 + i * 150}" y="670" width="110" height="110" rx="14" stroke-width="5"/>`).join('')}
  <circle cx="110" cy="705" r="11" fill="#111" stroke="none"/><circle cx="155" cy="745" r="11" fill="#111" stroke="none"/>
  <circle cx="260" cy="705" r="11" fill="#111" stroke="none"/><circle cx="305" cy="745" r="11" fill="#111" stroke="none"/>
  ${text(208, 742, 44, '+', 'region')}
  ${text(190, 870, 44, '2 + 2 =', 'region')}${box(270, 822, 70)}
  ${text(593, 645, 24, 'Color 5 boxes.')}
  ${Array.from({ length: 10 }, (_, i) => box(445 + (i % 5) * 61, 700 + Math.floor(i / 5) * 61, 56)).join('')}
  ${g(593, 880, 0.45, owl())}`, '7 hearts; 9; 2 + 2 = 4; color 5 boxes');

// ---------- the end ----------

const certificate = plain(`
  <rect x="48" y="48" width="720" height="960" rx="40" stroke-width="10"/>
  <rect x="72" y="72" width="672" height="912" rx="28" stroke-width="4"/>
  ${text(PW / 2, 190, 64, 'Great Job!', 'title')}
  ${text(PW / 2, 260, 28, 'This certificate is given to')}
  <path d="M170,350 L646,350" fill="none" stroke-width="5"/>
  ${text(PW / 2, 420, 28, 'for finishing')}
  ${text(PW / 2, 470, 32, 'My First Numbers &amp; Counting', 'title')}
  ${g(PW / 2, 660, 1.5, owl())}
  ${g(200, 640, 0.9, A.star())}${g(616, 640, 0.9, A.star())}${g(250, 800, 0.6, A.star())}${g(566, 800, 0.6, A.star())}
  ${text(250, 920, 24, 'Date')}<path d="M150,880 L350,880" fill="none" stroke-width="4"/>
  ${text(566, 920, 24, 'Signed')}<path d="M466,880 L666,880" fill="none" stroke-width="4"/>
`);

const friends = plain(`
  ${text(PW / 2, 120, 50, 'Color Ollie and Friends!', 'title')}
  ${g(140, 250, 0.8, sun())}
  <path d="M520,220 Q540,190 575,200 Q600,170 635,195 Q665,195 662,222 Z" stroke-width="5"/>
  ${g(250, 360, 1.3, A.balloon())}${g(350, 330, 1.3, A.balloon())}
  <path d="M250,470 Q300,560 380,640 M350,440 Q360,540 385,640" fill="none" stroke-width="4"/>
  ${g(408, 650, 2, owl())}
  ${g(160, 760, 1.3, A.bunny())}${g(650, 770, 1.3, A.frog())}
  ${g(610, 430, 1.2, A.butterfly())}
  <path d="M40,930 Q220,900 408,920 Q600,940 776,910" fill="none" stroke-width="6"/>
  ${g(300, 900, 0.9, A.snail())}${g(520, 905, 0.9, A.ladybug())}
`);

const picnic = plain(`
  ${text(PW / 2, 120, 50, 'Picnic Time!', 'title')}
  ${g(680, 240, 0.8, sun())}
  <path d="M40,520 Q220,490 408,510 Q600,530 776,500" fill="none" stroke-width="6"/>
  ${[100, 230, 600, 720].map((x) => g(x, 450, 0.9, A.flower())).join('')}
  ${g(420, 300, 0.8, A.bee())}${g(230, 280, 0.9, A.butterfly())}
  <path d="M120,620 L700,620 L760,900 L60,900 Z"/>
  <path d="M100,713 L720,713 M80,806 L740,806 M313,620 L280,900 M506,620 L540,900" fill="none" stroke-width="4"/>
  ${g(260, 640, 1.1, A.cupcake())}${g(420, 650, 1.1, A.apple())}${g(580, 640, 1.1, A.cupcake())}
  ${g(150, 960, 0.9, A.cat())}${g(680, 965, 0.8, A.duck())}
`);

export const answerKeyPages = (entries) => {
  const perPage = 36;
  const out = [];
  for (let p = 0; p * perPage < entries.length; p++) {
    const chunk = entries.slice(p * perPage, (p + 1) * perPage);
    out.push(plain(`
      ${text(PW / 2, 110, 48, p ? 'Answer Key (continued)' : 'Answer Key', 'title')}
      ${chunk.map(([no, title, a], i) => {
        const y = 172 + i * 23.4;
        return `${text(64, y, 16, `p. ${no}`, 'region', 'start')}${text(124, y, 16, `${title}: ${a}`, 'say', 'start')}`;
      }).join('')}`));
  }
  return out;
};

// ---------- the whole book ----------

export const sections = [
  titlePage, copyright, belongs, grownups,
  ...Array.from({ length: 10 }, (_, i) => [numberPage(i + 1), huntPage(i + 1)]).flat(),
  matchPage([['cat', 2], ['star', 4], ['duck', 1], ['apple', 3]], [3, 1, 4, 2]),
  matchPage([['bee', 5], ['heart', 3], ['frog', 6], ['ball', 4]], [4, 6, 3, 5]),
  howManyPage([['apple', 3, [2, 3, 4]], ['car', 2, [1, 2, 3]], ['butterfly', 5, [5, 4, 6]], ['heart', 4, [3, 5, 4]]]),
  writePage([['fish', 4], ['bunny', 2], ['cupcake', 5], ['frog', 3]]),
  pond,
  matchPage([['flower', 7], ['ladybug', 5], ['cupcake', 8], ['snail', 6]], [6, 8, 5, 7]),
  howManyPage([['cupcake', 6, [6, 5, 7]], ['snail', 3, [4, 3, 2]], ['bee', 7, [8, 6, 7]], ['flower', 5, [5, 6, 4]]]),
  writePage([['balloon', 7], ['ball', 6], ['heart', 9], ['bee', 8]]),
  garden,
  matchPage([['balloon', 9], ['star', 10], ['bunny', 7], ['fish', 8]], [8, 7, 10, 9]),
  howManyPage([['ball', 8, [7, 8, 9]], ['ladybug', 9, [9, 10, 8]], ['duck', 6, [5, 7, 6]], ['star', 10, [10, 9, 8]]]),
  comparePage(['duck', 2, 4], ['apple', 5, 3]),
  comparePage(['star', 6, 3], ['car', 4, 2]),
  comparePage(['balloon', 5, 4], ['bee', 3, 5]),
  samePage, bigSmall, countCompare,
  shapePage('circle', 'Circles'), shapePage('square', 'Squares'), shapePage('triangle', 'Triangles'), shapePage('rectangle', 'Rectangles'),
  train, house, robot, patterns,
  cbnTurtle, cbnOwl, cbnFish, cbnDuck, cbnLadybug, cbnButterfly, cbnFlower, cbnBalloons,
  starDots, fishDots, heartDots, crownDots,
  addPage([['duck', 1, 1], ['apple', 2, 1], ['fish', 1, 2]]),
  addPage([['cat', 2, 2], ['star', 3, 1], ['bee', 1, 3]]),
  takePage([['apple', 2, 1], ['duck', 3, 1], ['fish', 3, 2]]),
  addPage([['flower', 2, 3], ['heart', 4, 1], ['ball', 3, 2]]),
  takePage([['star', 4, 1], ['balloon', 4, 2], ['cupcake', 4, 3]]),
  addPage([['ladybug', 1, 4], ['cupcake', 2, 2], ['balloon', 3, 1]]),
  takePage([['bee', 5, 1], ['heart', 5, 2], ['ball', 5, 3]]),
  addPage([['snail', 2, 1], ['car', 3, 2], ['bunny', 2, 3]]),
  takePage([['flower', 5, 4], ['ladybug', 3, 1], ['frog', 4, 2]]),
  takePage([['car', 5, 2], ['bunny', 3, 2], ['butterfly', 4, 1]]),
  missing, traceAll, graph, challenge,
  certificate, friends, picnic,
];
