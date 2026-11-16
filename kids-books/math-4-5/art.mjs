// Line art for "My First Numbers & Counting" (ages 4–5).
// Every piece is drawn around (0,0) with thick, rounded outlines so a
// 4-year-old can colour inside it. Pass colours only for the cover;
// the interior stays black and white.

export const INK = '#111';
const W = '#fff';

export const g = (x, y, s, body) => `<g transform="translate(${x} ${y}) scale(${s})">${body}</g>`;

// Kawaii eye: solid black with a white shine.
export const eye = (x, y, r) =>
  `<circle cx="${x}" cy="${y}" r="${r}" fill="${INK}" stroke="none"/>` +
  `<circle cx="${x - r * 0.35}" cy="${y - r * 0.38}" r="${r * 0.36}" fill="#fff" stroke="none"/>`;

const smile = (d, w = 4) => `<path d="${d}" fill="none" stroke-width="${w}"/>`;

export function fish(c = {}) {
  const body = c.body ?? W, fin = c.fin ?? W;
  return `
  <path d="M-50,0 L-94,-34 Q-80,0 -94,34 Z" fill="${fin}"/>
  <path d="M-8,-33 Q8,-64 32,-35 Z" fill="${fin}"/>
  <path d="M-58,0 C-40,-48 40,-50 66,0 C40,50 -40,48 -58,0 Z" fill="${body}"/>
  <path d="M-16,-30 Q0,0 -16,30" fill="none" stroke-width="4"/>
  <path d="M-2,14 Q12,34 26,16 Z" fill="${fin}" stroke-width="4"/>
  ${eye(34, -8, 9)}
  ${smile('M44,12 Q52,19 59,10')}`;
}

export function apple(c = {}) {
  const body = c.body ?? W, leaf = c.leaf ?? W;
  return `
  <path d="M0,-32 Q4,-50 12,-60" fill="none"/>
  <path d="M6,-46 Q28,-70 48,-52 Q26,-34 6,-46 Z" fill="${leaf}"/>
  <path d="M0,-30 C22,-48 58,-34 56,2 C54,40 22,58 0,46 C-22,58 -54,40 -56,2 C-58,-34 -22,-48 0,-30 Z" fill="${body}"/>
  <path d="M-38,-10 Q-40,-24 -28,-30" fill="none" stroke-width="4"/>
  ${eye(-16, 6, 6)}${eye(16, 6, 6)}
  ${smile('M-7,17 Q0,24 7,17')}`;
}

export function duck(c = {}) {
  const body = c.body ?? W, beak = c.beak ?? W, wing = c.wing ?? W;
  return `
  <path d="M-56,2 L-84,-20 L-52,-14 Z" fill="${body}"/>
  <ellipse cx="-4" cy="18" rx="60" ry="40" fill="${body}"/>
  <circle cx="40" cy="-30" r="32" fill="${body}"/>
  <path d="M66,-38 Q94,-38 96,-27 Q88,-16 66,-20 Z" fill="${beak}"/>
  <path d="M-36,8 Q-4,-8 22,16 Q-6,46 -36,8 Z" fill="${wing}" stroke-width="5"/>
  ${eye(46, -38, 7)}`;
}

export function cat(c = {}) {
  const body = c.body ?? W, ear = c.ear ?? W;
  return `
  <path d="M-48,-12 L-42,-64 L-6,-40 Z" fill="${body}"/>
  <path d="M48,-12 L42,-64 L6,-40 Z" fill="${body}"/>
  <path d="M-40,-30 L-38,-52 L-20,-40 Z" fill="${ear}" stroke-width="4"/>
  <path d="M40,-30 L38,-52 L20,-40 Z" fill="${ear}" stroke-width="4"/>
  <ellipse cx="0" cy="0" rx="58" ry="46" fill="${body}"/>
  ${eye(-21, -4, 8)}${eye(21, -4, 8)}
  <path d="M-6,10 L6,10 L0,17 Z" fill="${INK}" stroke-width="3"/>
  ${smile('M-12,22 Q-6,29 0,21 Q6,29 12,22')}
  <path d="M-32,12 L-64,6 M-32,21 L-64,25 M32,12 L64,6 M32,21 L64,25" fill="none" stroke-width="3.5"/>`;
}

export function star(c = {}) {
  const fill = c.body ?? W;
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? 25 : 54;
    const a = -Math.PI / 2 + (i * Math.PI) / 5;
    pts.push(`${(r * Math.cos(a)).toFixed(1)},${(r * Math.sin(a)).toFixed(1)}`);
  }
  return `
  <polygon points="${pts.join(' ')}" fill="${fill}"/>
  ${eye(-10, 2, 5)}${eye(10, 2, 5)}
  ${smile('M-6,12 Q0,18 6,12', 3.5)}`;
}

export function owl(c = {}) {
  const body = c.body ?? W, belly = c.belly ?? W, wing = c.wing ?? W, beak = c.beak ?? W;
  return `
  <path d="M-38,-50 L-48,-86 L-12,-62 Z" fill="${body}"/>
  <path d="M38,-50 L48,-86 L12,-62 Z" fill="${body}"/>
  <path d="M0,-70 C46,-70 56,-30 53,10 C50,56 26,72 0,72 C-26,72 -50,56 -53,10 C-56,-30 -46,-70 0,-70 Z" fill="${body}"/>
  <ellipse cx="0" cy="32" rx="30" ry="34" fill="${belly}" stroke-width="5"/>
  <path d="M-13,18 Q-6.5,25 0,18 Q6.5,25 13,18 M-13,36 Q-6.5,43 0,36 Q6.5,43 13,36" fill="none" stroke-width="3.5"/>
  <path d="M-50,-2 Q-76,30 -44,54 Q-34,24 -50,-2 Z" fill="${wing}"/>
  <path d="M50,-2 Q76,30 44,54 Q34,24 50,-2 Z" fill="${wing}"/>
  <circle cx="-21" cy="-30" r="21" fill="#fff"/>
  <circle cx="21" cy="-30" r="21" fill="#fff"/>
  ${eye(-18, -28, 10)}${eye(18, -28, 10)}
  <path d="M-8,-12 L8,-12 L0,2 Z" fill="${beak}" stroke-width="4"/>
  <path d="M-22,70 L-28,82 M-16,72 L-16,84 M22,70 L28,82 M16,72 L16,84" fill="none" stroke-width="4"/>`;
}

// Big turtle for colour-by-number. Region numbers are part of the drawing.
export function turtle(label = true) {
  const n = (x, y, t, s = 30) =>
    label ? `<text x="${x}" y="${y}" class="region" font-size="${s}" text-anchor="middle" dominant-baseline="central">${t}</text>` : '';
  return `
  <ellipse cx="-62" cy="56" rx="22" ry="22" fill="#fff"/>
  <ellipse cx="62" cy="56" rx="22" ry="22" fill="#fff"/>
  <circle cx="136" cy="-14" r="38" fill="#fff"/>
  <path d="M-100,10 C-100,-96 100,-96 100,10 Z" fill="#fff"/>
  <path d="M-36,-52 L36,-52 L56,-16 L36,12 L-36,12 L-56,-16 Z" fill="#fff" stroke-width="5"/>
  <path d="M-110,10 L110,10 Q114,40 90,40 L-90,40 Q-114,40 -110,10 Z" fill="#fff"/>
  ${eye(152, -24, 8)}
  ${smile('M146,-2 Q156,6 166,-4')}
  ${n(0, -20, 2)}${n(-76, -12, 3, 26)}${n(76, -12, 3, 26)}
  ${n(0, 25, 4, 22)}${n(124, -30, 1, 22)}${n(-62, 60, 1, 22)}${n(62, 60, 1, 22)}`;
}

// A crayon for the colour key: the child colours the crayon first.
export function crayon(num, word) {
  return `
  <path d="M-30,-58 L30,-58 L30,40 L-30,40 Z" fill="#fff"/>
  <path d="M-30,-58 L0,-92 L30,-58 Z" fill="#fff"/>
  <path d="M-30,-40 L30,-40 M-30,22 L30,22" fill="none" stroke-width="4"/>
  <circle cx="0" cy="-9" r="20" fill="#fff" stroke-width="4"/>
  <text x="0" y="-8" class="region" font-size="26" text-anchor="middle" dominant-baseline="central">${num}</text>
  <text x="0" y="74" class="say" font-size="24" text-anchor="middle">${word}</text>`;
}

export function sun(c = {}) {
  const fill = c.body ?? W;
  let rays = '';
  for (let i = 0; i < 8; i++) {
    const a = (i * Math.PI) / 4;
    rays += `M${(52 * Math.cos(a)).toFixed(1)},${(52 * Math.sin(a)).toFixed(1)} L${(72 * Math.cos(a)).toFixed(1)},${(72 * Math.sin(a)).toFixed(1)} `;
  }
  return `<path d="${rays}" fill="none"/><circle r="40" fill="${fill}"/>`;
}

// Single-stroke path for tracing the digit 3 (box ~ 60 x 100).
export const THREE = 'M8,20 C14,2 50,0 52,22 C54,40 36,48 26,48 C42,48 58,56 56,76 C54,98 16,102 6,84';
