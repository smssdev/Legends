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

// Digits as single strokes for tracing (each in a 60 x 100 box; 10 is 100 wide).
export const DIGITS = {
  0: ['M30,4 C8,4 4,30 4,52 C4,76 12,98 30,98 C48,98 56,76 56,52 C56,30 52,4 30,4'],
  1: ['M14,22 L32,4 L32,98'],
  2: ['M6,26 C8,6 28,2 40,6 C56,12 58,32 46,46 L4,98 L58,98'],
  3: [THREE],
  4: ['M30,4 L4,68 L58,68', 'M42,4 L42,98'],
  5: ['M12,4 L8,44 C20,36 50,34 56,60 C60,86 40,100 22,98 C12,97 6,92 4,88', 'M12,4 L52,4'],
  6: ['M48,8 C36,2 14,6 8,38 C2,70 10,98 32,98 C52,98 58,80 56,66 C54,46 36,40 24,44 C14,48 8,56 6,62'],
  7: ['M4,4 L56,4 L22,98'],
  8: ['M30,50 C12,46 8,30 10,20 C14,6 46,6 50,20 C52,30 48,46 30,50 C10,54 4,70 6,80 C10,98 50,100 54,80 C56,68 50,54 30,50'],
  9: ['M54,32 C52,10 36,4 28,4 C12,4 4,18 6,32 C8,48 30,56 46,46 C52,42 54,36 54,32 L50,98'],
};
DIGITS[10] = [DIGITS[1][0], DIGITS[0][0].replace(/(-?\d+),/g, (m, x) => `${+x + 40},`)];

// Numbers written inside a drawing for colour-by-number (local coords).
export const nums = (list, scale = 1, size = 30) =>
  list.map(([x, y, t, s = size]) => `<text x="${x}" y="${y}" class="region" font-size="${(s / scale).toFixed(1)}" text-anchor="middle" dominant-baseline="central">${t}</text>`).join('');

export function ladybug(c = {}) {
  const body = c.body ?? W, spot = c.spot ?? W;
  return `
  <path d="M-8,-56 Q-14,-74 -24,-80 M8,-56 Q14,-74 24,-80" fill="none" stroke-width="4"/>
  <circle cx="-24" cy="-80" r="5" fill="${INK}" stroke="none"/><circle cx="24" cy="-80" r="5" fill="${INK}" stroke="none"/>
  <circle cx="0" cy="-46" r="24" fill="${c.head ?? W}"/>
  <circle cx="0" cy="8" r="50" fill="${body}"/>
  <path d="M0,-42 L0,58" fill="none" stroke-width="5"/>
  <circle cx="-24" cy="-10" r="10" fill="${spot}" stroke-width="4"/><circle cx="24" cy="-10" r="10" fill="${spot}" stroke-width="4"/>
  <circle cx="-28" cy="24" r="9" fill="${spot}" stroke-width="4"/><circle cx="28" cy="24" r="9" fill="${spot}" stroke-width="4"/>
  ${eye(-9, -54, 5)}${eye(9, -54, 5)}`;
}

export function flower(c = {}) {
  const petal = c.petal ?? W, mid = c.mid ?? W, leaf = c.leaf ?? W;
  let petals = '';
  for (let i = 0; i < 6; i++) {
    const a = (i * Math.PI) / 3;
    petals += `<circle cx="${(30 * Math.cos(a)).toFixed(1)}" cy="${(-24 + 30 * Math.sin(a)).toFixed(1)}" r="22" fill="${petal}"/>`;
  }
  return `
  <path d="M0,0 L0,72" fill="none"/>
  <path d="M0,50 Q-30,28 -42,46 Q-22,62 0,50 Z" fill="${leaf}" stroke-width="5"/>
  <path d="M0,38 Q30,16 42,34 Q22,50 0,38 Z" fill="${leaf}" stroke-width="5"/>
  ${petals}
  <circle cx="0" cy="-24" r="20" fill="${mid}"/>
  ${c.plain ? '' : `${eye(-7, -27, 4)}${eye(7, -27, 4)}${smile('M-5,-17 Q0,-12 5,-17', 3)}`}`;
}

export function balloon(c = {}) {
  const body = c.body ?? W;
  return `
  <path d="M0,34 Q-12,50 0,62 Q12,74 0,86" fill="none" stroke-width="4"/>
  <path d="M-8,36 L8,36 L0,26 Z" fill="${body}" stroke-width="4"/>
  <ellipse cx="0" cy="-18" rx="42" ry="50" fill="${body}"/>
  <path d="M-26,-38 Q-26,-54 -12,-60" fill="none" stroke-width="4"/>
  ${eye(-13, -18, 5)}${eye(13, -18, 5)}
  ${smile('M-6,-6 Q0,0 6,-6', 3.5)}`;
}

export function bee(c = {}) {
  const body = c.body ?? W, wing = c.wing ?? W;
  return `
  <ellipse cx="-12" cy="-40" rx="16" ry="24" transform="rotate(-20 -12 -40)" fill="${wing}" stroke-width="5"/>
  <ellipse cx="12" cy="-40" rx="16" ry="24" transform="rotate(20 12 -40)" fill="${wing}" stroke-width="5"/>
  <path d="M-50,0 L-66,-8 L-64,8 Z" fill="${INK}" stroke-width="4"/>
  <ellipse cx="0" cy="0" rx="52" ry="36" fill="${body}"/>
  <path d="M-18,-33 Q-28,0 -18,33 M6,-36 Q-4,0 6,36" fill="none" stroke-width="8"/>
  <path d="M32,-28 Q36,-46 46,-50" fill="none" stroke-width="4"/>
  <circle cx="46" cy="-50" r="5" fill="${INK}" stroke="none"/>
  ${eye(30, -6, 6)}
  ${smile('M26,10 Q33,16 40,9', 3.5)}`;
}

export function frog(c = {}) {
  const body = c.body ?? W;
  return `
  <ellipse cx="-36" cy="56" rx="18" ry="9" fill="${body}" stroke-width="5"/>
  <ellipse cx="36" cy="56" rx="18" ry="9" fill="${body}" stroke-width="5"/>
  <ellipse cx="0" cy="18" rx="56" ry="40" fill="${body}"/>
  <circle cx="-26" cy="-24" r="19" fill="${body}"/>
  <circle cx="26" cy="-24" r="19" fill="${body}"/>
  ${eye(-26, -24, 9)}${eye(26, -24, 9)}
  ${smile('M-26,14 Q0,36 26,14', 5)}`;
}

export function butterfly(c = {}) {
  const top = c.top ?? W, low = c.low ?? W, body = c.body ?? W;
  const wings = `
    <path d="M-4,-8 C-30,-72 -84,-56 -70,-14 C-62,8 -24,6 -4,-2 Z" fill="${top}"/>
    <path d="M-4,2 C-24,8 -64,22 -52,50 C-40,70 -10,44 -4,12 Z" fill="${low}"/>
    <circle cx="-44" cy="-26" r="10" fill="#fff" stroke-width="4"/>
    <circle cx="-38" cy="30" r="7" fill="#fff" stroke-width="4"/>`;
  return `
  <path d="M-4,-44 Q-14,-64 -24,-70 M4,-44 Q14,-64 24,-70" fill="none" stroke-width="4"/>
  ${wings}<g transform="scale(-1 1)">${wings}</g>
  <ellipse cx="0" cy="4" rx="10" ry="40" fill="${body}"/>
  <circle cx="0" cy="-42" r="12" fill="${body}"/>
  ${eye(-4, -44, 3)}${eye(4, -44, 3)}`;
}

export function heart(c = {}) {
  return `
  <path d="M0,50 C-62,10 -62,-42 -26,-46 C-10,-48 0,-36 0,-26 C0,-36 10,-48 26,-46 C62,-42 62,10 0,50 Z" fill="${c.body ?? W}"/>
  ${eye(-14, -12, 6)}${eye(14, -12, 6)}
  ${smile('M-6,2 Q0,8 6,2', 3.5)}`;
}

export function ball(c = {}) {
  return `
  <circle r="48" fill="${c.body ?? W}"/>
  <path d="M0,-48 Q-34,0 0,48 M0,-48 Q34,0 0,48 M-46,-12 Q0,6 46,-12" fill="none" stroke-width="4"/>`;
}

export function snail(c = {}) {
  const body = c.body ?? W, shell = c.shell ?? W;
  return `
  <path d="M62,-22 L58,-46 M72,-20 L76,-44" fill="none" stroke-width="4"/>
  <circle cx="58" cy="-46" r="5" fill="${INK}" stroke="none"/><circle cx="76" cy="-44" r="5" fill="${INK}" stroke="none"/>
  <path d="M-62,42 Q-62,30 -44,30 L40,30 Q46,-16 60,-22 Q80,-26 80,-4 L74,42 Z" fill="${body}"/>
  <circle cx="-6" cy="-4" r="40" fill="${shell}"/>
  <path d="M-6,-4 Q-6,-14 4,-12 Q14,-8 10,4 Q4,18 -10,14 Q-26,8 -24,-8 Q-20,-28 0,-30 Q24,-30 28,-4" fill="none" stroke-width="5"/>
  ${eye(66, -6, 4)}
  ${smile('M62,8 Q68,14 74,7', 3.5)}`;
}

export function bunny(c = {}) {
  const body = c.body ?? W, ear = c.ear ?? W;
  return `
  <ellipse cx="0" cy="52" rx="36" ry="26" fill="${body}"/>
  <ellipse cx="-17" cy="-62" rx="14" ry="36" fill="${body}"/>
  <ellipse cx="17" cy="-62" rx="14" ry="36" fill="${body}"/>
  <ellipse cx="-17" cy="-62" rx="6" ry="22" fill="${ear}" stroke-width="4"/>
  <ellipse cx="17" cy="-62" rx="6" ry="22" fill="${ear}" stroke-width="4"/>
  <circle cx="0" cy="-4" r="40" fill="${body}"/>
  ${eye(-15, -8, 6)}${eye(15, -8, 6)}
  <path d="M-5,6 L5,6 L0,11 Z" fill="${INK}" stroke-width="3"/>
  ${smile('M-8,16 Q-4,21 0,15 Q4,21 8,16', 3.5)}`;
}

export function cupcake(c = {}) {
  const cake = c.cake ?? W, top = c.top ?? W;
  return `
  <path d="M0,-56 Q4,-68 12,-72" fill="none" stroke-width="4"/>
  <circle cx="0" cy="-54" r="11" fill="${c.cherry ?? W}"/>
  <path d="M-40,0 L40,0 L30,56 L-30,56 Z" fill="${cake}"/>
  <path d="M-20,0 L-15,56 M0,0 L0,56 M20,0 L15,56" fill="none" stroke-width="4"/>
  <path d="M-48,6 Q-58,-20 -32,-24 Q-30,-50 0,-46 Q30,-50 32,-24 Q58,-20 48,6 Z" fill="${top}"/>
  ${eye(-12, -16, 5)}${eye(12, -16, 5)}
  ${smile('M-6,-6 Q0,0 6,-6', 3.5)}`;
}

export function car(c = {}) {
  const body = c.body ?? W;
  return `
  <path d="M-72,22 L-72,-4 Q-70,-16 -52,-18 L-34,-18 L-18,-44 L30,-44 L48,-18 L62,-16 Q74,-14 74,4 L74,22 Z" fill="${body}"/>
  <path d="M-22,-18 L-10,-36 L4,-36 L4,-18 Z M14,-18 L14,-36 L26,-36 L38,-18 Z" fill="#fff" stroke-width="4"/>
  <circle cx="-42" cy="24" r="17" fill="#fff"/><circle cx="44" cy="24" r="17" fill="#fff"/>
  <circle cx="-42" cy="24" r="5" fill="${INK}" stroke="none"/><circle cx="44" cy="24" r="5" fill="${INK}" stroke="none"/>
  <circle cx="64" cy="0" r="5" fill="#fff" stroke-width="3.5"/>`;
}
