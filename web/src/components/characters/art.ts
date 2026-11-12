/**
 * [Sprint 26 W1] The nine characters of the game (README section 0, 2026-10-30) in their nine moods: the mascots A1 to
 * A3, the assistant's faces B1 to B3 and the touchline coaches C1 to C3. Drawn as SVG with soft gradients and moved by
 * CSS (characters.css); the mood always comes from the server (App\Characters\Mood).
 */
export const MOODS = ['idle', 'joy', 'cheer', 'sad', 'angry', 'worried', 'think', 'surprise', 'sleep'] as const;
export type Mood = (typeof MOODS)[number];
export const MODELS = ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'] as const;
export type Model = (typeof MODELS)[number];

/** The gradients and filters every character shares, put in the page once. */
export function ensureDefs(): void {
  if (typeof document === 'undefined' || document.getElementById('lgc-defs')) return;
  const html = `<svg id="lgc-defs" class="lgc-palette" width="0" height="0" style="position:absolute" aria-hidden="true"><defs>${SHADED.map(c => `<radialGradient id="lgc-g-${c}" cx=".38" cy=".3" r=".85" fx=".32" fy=".22">
  <stop offset="0" style="stop-color:color-mix(in srgb, var(--${c}) 62%, #fff)"/><stop offset=".5" style="stop-color:var(--${c})"/><stop offset="1" style="stop-color:color-mix(in srgb, var(--${c}) 68%, var(--k))"/></radialGradient>`).join('')}
  <filter id="lgc-soft" x="-25%" y="-20%" width="150%" height="150%"><feDropShadow dx="0" dy="1.6" stdDeviation="1.3" flood-color="#06111E" flood-opacity=".3"/></filter>
  <filter id="lgc-cloth" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="7" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 .24 0" result="a"/><feComposite in="a" in2="SourceGraphic" operator="in" result="t"/>
    <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="t"/></feMerge></filter></defs></svg>`;
  document.body.insertAdjacentHTML('afterbegin', html);
}

/* Volume: every cloth and skin colour is a soft radial gradient (light from the top left), and its outline is a darker shade of itself. */
const SHADED = ['gold', 'goldD', 'goldL', 'em', 'emD', 'navy', 'navyD', 'chrome', 'chromeD', 'skin', 'bronze', 'orange', 'white', 'silver', 'night'];
const st = (c: string, o = true, w = 3) => `style="fill:${SHADED.includes(c) ? `url(#lgc-g-${c})` : `var(--${c})`}${o ? `;stroke:color-mix(in srgb, var(--${c}) 38%, var(--k));stroke-width:${(w * .8).toFixed(1)};stroke-linejoin:round` : ''}"`;
const ln = (c: string, w = 3) => `style="fill:none;stroke:var(--${c});stroke-width:${w};stroke-linecap:round;stroke-linejoin:round"`;

/** How a face is drawn: a glowing screen face (B), a beak (A1), the iris colour of real eyes. */
type FaceLook = { glow?: boolean; iris?: string; beak?: boolean }

function face(m: Mood, o: FaceLook = {}) {
  const ink = o.glow ? 'emL' : 'k';
  const S = (d: string, w = 3.4) => `<path d="${d}" ${ln(ink, w)}/>`;
  const dot = (x: number, y: number, rx: number, ry: number) => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" ${st(ink, false)}/>`;
  const shine = (x: number, y: number) => o.glow ? '' : `<circle cx="${x}" cy="${y}" r="1.8" style="fill:#fff"/>`;
  const E = [-16, 16];
  let eyes = '', brows = '', mouth = '', cheeks = '', fx = '';
  /* People get real eyes: white, a coloured iris, a pupil and two glints. */
  const real = (x: number, y: number, look = 0, ry = 7.5) => `<ellipse cx="${x}" cy="${y}" rx="6.5" ry="${ry}" style="fill:#fff;stroke:var(--k);stroke-width:2"/>`
    + `<circle cx="${x + look}" cy="${y + 1}" r="4.4" style="fill:var(--${o.iris})"/><circle cx="${x + look}" cy="${y + 1}" r="2.2" style="fill:var(--k)"/>`
    + `<circle cx="${x + look + 1.6}" cy="${y - 1}" r="1.3" style="fill:#fff"/><circle cx="${x + look - 1.4}" cy="${y + 2.6}" r=".7" style="fill:#fff"/>`;
  let realEyes = '';
  if (o.iris && ['idle', 'sad', 'think', 'worried', 'angry'].includes(m)) {
    const look = m === 'think' ? 2.2 : 0, y = m === 'think' ? -2 : m === 'angry' ? 2 : 0, ry = m === 'angry' ? 5.5 : m === 'worried' ? 6.5 : 7.5;
    realEyes = (m === 'idle' ? '<g class="blink">' : '') + E.map(x => real(x, y, look, ry)).join('') + (m === 'idle' ? '</g>' : '');
  }
  switch (m) {
    case 'joy': case 'cheer':
      eyes = E.map(x => S(`M${x - 7} 2 Q${x} -8 ${x + 7} 2`, 3.8)).join(''); break;
    case 'sleep':
      eyes = E.map(x => S(`M${x - 7} 0 Q${x} 6 ${x + 7} 0`)).join(''); break;
    case 'surprise':
      eyes = E.map(x => `<circle cx="${x}" cy="-1" r="8.5" ${o.glow ? ln(ink, 2.6) : st('white', true, 2.4)}/>` + dot(x, 0, 3.6, 3.6)).join('');
      brows = E.map(x => S(`M${x - 7} -17 Q${x} -22 ${x + 7} -17`, 3)).join(''); break;
    case 'think':
      eyes = E.map(x => dot(x + 3, -2, 5, 6.5) + shine(x + 5, -5)).join('');
      brows = S('M-24 -12 L-9 -12', 3) + S('M8 -15 Q16 -21 24 -16', 3); break;
    case 'sad':
      eyes = E.map(x => dot(x, 2, 5, 6.5) + shine(x + 2, -1)).join('');
      brows = S('M-24 -9 L-9 -15', 3) + S('M24 -9 L9 -15', 3); break;
    case 'angry':
      eyes = E.map(x => dot(x, 2, 5, 5.5)).join('');
      brows = S('M-25 -15 L-8 -7', 4.2) + S('M25 -15 L8 -7', 4.2); break;
    case 'worried':
      eyes = E.map(x => dot(x, 1, 4, 5) + shine(x + 1.5, -1)).join('');
      brows = S('M-23 -9 Q-16 -15 -9 -14', 3) + S('M23 -9 Q16 -15 9 -14', 3); break;
    default:
      eyes = '<g class="blink">' + E.map(x => dot(x, 0, 5.5, 7) + shine(x + 2, -3)).join('') + '</g>';
  }
  if (realEyes) eyes = realEyes;
  if (o.iris && ['idle', 'joy', 'cheer', 'sleep'].includes(m)) brows = S('M-24 -13 Q-16 -17 -8 -13', 3) + S('M24 -13 Q16 -17 8 -13', 3);
  if (o.beak) {
    const open = ['joy', 'cheer', 'surprise', 'angry'].includes(m);
    const tip = m === 'surprise' ? 6 : 0;
    mouth = (open ? `<path d="M-8 12 L8 12 L0 ${27 + tip} Z" ${st('k', false)}/>` : '')
      + `<path d="M-10 7 Q0 3 10 7 L0 ${m === 'sad' ? 21 : 19} Z" ${st('orange', true, 2.6)}/>`
      + (open ? `<path d="M-6 ${23 + tip} L6 ${23 + tip} L0 ${29 + tip} Z" ${st('orange', true, 2.2)}/>` : '');
  } else {
    switch (m) {
      case 'joy': case 'cheer':
        mouth = `<path d="M-12 13 Q0 31 12 13 Z" ${st(ink, false)}/>` + (o.glow ? '' : `<path d="M-6 22 Q0 18 6 22 Q0 27 -6 22 Z" ${st('red', false)}/>`); break;
      case 'sad': mouth = S('M-9 22 Q0 14 9 22'); break;
      case 'angry': mouth = S('M-10 21 Q0 15 10 21', 3.8); break;
      case 'worried': mouth = S('M-10 19 q3.3 -4 6.6 0 t6.6 0 t6.6 0', 3); break;
      case 'think': mouth = S('M-3 19 L8 16'); break;
      case 'surprise': mouth = `<ellipse cx="0" cy="20" rx="5" ry="7" ${st(ink, false)}/>`; break;
      case 'sleep': mouth = `<ellipse cx="2" cy="19" rx="3" ry="2.2" ${st(ink, false)}/>`; break;
      default: mouth = S('M-8 16 Q0 22 8 16');
    }
  }
  const blush = ({ idle: .3, joy: .4, cheer: .4, angry: .6, sleep: .25 } as Partial<Record<Mood, number>>)[m];
  if (blush && !o.glow) cheeks = [-25, 25].map(x => `<ellipse cx="${x}" cy="11" rx="5.5" ry="3.2" style="fill:var(--red);opacity:${blush}"/>`).join('');
  const drop = (x: number, y: number, cls: string) => `<path class="${cls}" d="M${x} ${y} q-4.5 7 0 10 q4.5 -3 0 -10z" ${st('emL', true, 1.6)}/>`;
  const star = (x: number, y: number, d: number) => `<g transform="translate(${x} ${y})"><path class="fx-spark" style="animation-delay:${d}s" d="M0 -8 L2.2 -2.2 L8 0 L2.2 2.2 L0 8 L-2.2 2.2 L-8 0 L-2.2 -2.2Z" ${st('goldL', true, 1.6)}/></g>`;
  switch (m) {
    case 'sad': fx = drop(-19, 6, 'fx-tear'); break;
    case 'worried': fx = drop(30, -24, 'fx-sweat'); break;
    case 'angry': fx = [-1, 1].map(s => `<g class="fx-steam" style="animation-delay:${s > 0 ? .5 : 0}s"><circle cx="${s * 34}" cy="-30" r="5" ${st('silver', true, 1.6)}/><circle cx="${s * 40}" cy="-39" r="3.6" ${st('silver', true, 1.6)}/></g>`).join(''); break;
    case 'think': fx = [[30, -40, 3], [40, -50, 4.2], [53, -61, 5.6]].map(([x, y, r], i) => `<circle class="fx-dot" style="animation-delay:${i * .25}s" cx="${x}" cy="${y}" r="${r}" ${st('white', true, 1.6)}/>`).join(''); break;
    case 'surprise': fx = `<text class="fx-pop" x="42" y="-30" text-anchor="middle" style="font:800 30px var(--f-num);fill:var(--gold);stroke:var(--k);stroke-width:2;paint-order:stroke">!</text>`; break;
    case 'sleep': fx = [[30, -26, 13, 0], [40, -40, 17, .8], [53, -56, 21, 1.6]].map(([x, y, s, d]) => `<text class="fx-z" style="animation-delay:${d}s;font:800 ${s}px var(--f-num);fill:var(--white);stroke:var(--k);stroke-width:1.6;paint-order:stroke" x="${x}" y="${y}">z</text>`).join(''); break;
    case 'joy': case 'cheer': fx = star(-48, -26, 0) + star(48, -32, .3) + star(54, 4, .6); break;
  }
  return brows + eyes + cheeks + mouth + fx;
}

const pent = (cx: number, cy: number, r: number) => Array.from({ length: 5 }, (_, i) => {
  const a = -Math.PI / 2 + i * 2 * Math.PI / 5;
  return `${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`;
}).join(' ');

/* Arms are drawn hanging down from the shoulder (sx, sy); the mood rotates them. */
type Draw = (x: number, y: number) => string
const arm = (side: string, sx: number, sy: number, draw: Draw) => `<g class="arm arm${side}" style="transform-origin:${sx}px ${sy}px">${draw(sx, sy)}</g>`;
const arms = (l: number, r: number, sy: number, draw: Draw) => arm('L', l, sy, draw) + arm('R', r, sy, draw);
const legs = (cloth: string, shoe: string, shoeO = false) =>
  `<rect x="82" y="180" width="15" height="22" ${st(cloth)}/><rect x="103" y="180" width="15" height="22" ${st(cloth)}/>`
  + `<ellipse cx="88" cy="204" rx="12" ry="5" ${st(shoe, shoeO)}/><ellipse cx="112" cy="204" rx="12" ry="5" ${st(shoe, shoeO)}/>`;


/* The touchline coaches are drawn closer to life: a head a sixth of the body, long legs, and arms with an elbow. */
const coachArm = (side: string, x: number, y: number, o: CoachLook) => {
  const s = side === 'L' ? 'L' : 'R';
  const stripe = o.stripe ? (yy: number, h: number) => `<rect x="${x - 1.2}" y="${yy}" width="2.4" height="${h}" ${st(o.stripe!, false)}/>` : () => '';
  return `<g class="up up${s}" style="transform-origin:${x}px ${y}px"><rect x="${x - 7}" y="${y - 3}" width="14" height="31" rx="7" ${st(o.sleeve)}/>${stripe(y, 24)}
    <path class="rich" d="M${x - 5} ${y + 20} q5 3 10 0" style="fill:none;stroke:var(--k);stroke-opacity:.22;stroke-width:1.2;stroke-linecap:round"/>
    <g class="fo fo${s}" style="transform-origin:${x}px ${y + 26}px"><rect x="${x - 6}" y="${y + 22}" width="12" height="28" rx="6" ${st(o.sleeve)}/>${stripe(y + 26, 20)}
    ${o.cuff ? `<rect x="${x - 6}" y="${y + 45}" width="12" height="4" ${st(o.cuff, false)}/>` : ''}
    <ellipse cx="${x}" cy="${y + 54}" rx="6" ry="7" ${st(o.skin, true, 2.4)}/><ellipse cx="${x + (s === 'L' ? 4 : -4)}" cy="${y + 51}" rx="2.4" ry="3.6" ${st(o.skin, true, 1.8)}/></g></g>`;
};
/** A touchline coach's looks: his words, skin, eyes, sleeves and cuffs, legs and shoes, and the drawn parts. */
type CoachLook = {
  name: string; desc: string; tags: string[]; skin: string; iris: string; sleeve: string; cuff?: string; stripe?: string; strands?: string
  legs: string; legStripe?: string; shoe: string; shoeO?: boolean; torso: string; hair?: string; hijab?: string; hijabFront?: string; face?: number[]
}
function coach(o: CoachLook): Char {
  const shoe = (d: string) => `<path d="${d}" ${st(o.shoe, o.shoeO !== undefined ? o.shoeO : false)}/>`;
  return {
    group: 'C', name: o.name, desc: o.desc, tags: o.tags, neck: '100px 92px', f: o.face || [100, 63, .62], fo: { iris: o.iris }, shadow: 40,
    body: () => `<g class="cloth"><path d="M75 150 H99 L97 199 H83 Z" ${st(o.legs)}/><path d="M101 150 H125 L117 199 H103 Z" ${st(o.legs)}/>
      ${o.legStripe ? `<path d="M77 154 L84 198 M123 154 L116 198" ${ln(o.legStripe, 2)}/>` : ''}
      ${shoe('M81 197 H98 Q100 206 94 206 H75 Q70 206 73 201 Q75 197 81 197Z')}${shoe('M102 197 H119 Q125 197 127 201 Q130 206 125 206 H106 Q100 206 102 197Z')}
      <path class="rich" d="M87 156 L89 196 M113 156 L111 196 M99 150 q1 6 0 12" style="fill:none;stroke:var(--k);stroke-opacity:.24;stroke-width:1.4;stroke-linecap:round"/>
      <ellipse class="rich" cx="80" cy="200" rx="4" ry="1.4" style="fill:#fff;opacity:.45"/><ellipse class="rich" cx="120" cy="200" rx="4" ry="1.4" style="fill:#fff;opacity:.45"/>
      <rect x="93" y="80" width="14" height="18" rx="4" ${st(o.skin)}/>${o.torso}
      <path class="rich" d="M80 140 q6 3 12 1 M108 141 q6 2 12 -1 M78 118 q3 7 2 15 M122 118 q-3 7 -2 15 M84 152 q16 -3 32 0" style="fill:none;stroke:var(--k);stroke-opacity:.24;stroke-width:1.4;stroke-linecap:round"/></g>`,
    head: `${o.hijab || ''}${o.hijab ? '' : `<ellipse cx="79" cy="64" rx="4.5" ry="6.5" ${st(o.skin, true, 2.4)}/><ellipse cx="121" cy="64" rx="4.5" ry="6.5" ${st(o.skin, true, 2.4)}/>`}
      <ellipse cx="100" cy="${o.hijab ? 64 : 62}" rx="${o.hijab ? 17 : 21}" ry="${o.hijab ? 21 : 25}" ${st(o.skin, true, 2.6)}/>
      <ellipse cx="100" cy="${o.hijab ? 82 : 84}" rx="9" ry="3" style="fill:var(--k);opacity:.12"/>
      ${o.hair || ''}${o.strands ? `<path class="rich" d="${o.strands}" style="fill:none;stroke:#fff;stroke-opacity:.28;stroke-width:1.2;stroke-linecap:round"/>` : ''}${o.hijabFront || ''}
      <path class="rich" d="M${o.hijab ? 110 : 113} ${o.hijab ? 48 : 42} Q${o.hijab ? 118 : 122} ${o.hijab ? 58 : 52} ${o.hijab ? 116 : 120} ${o.hijab ? 74 : 70}" style="fill:none;stroke:#fff;stroke-opacity:.45;stroke-width:1.6;stroke-linecap:round"/><path d="M101 ${o.hijab ? 64 : 63} q-3 5 0 6.5" style="fill:none;stroke:color-mix(in srgb, var(--${o.skin}) 50%, var(--k));stroke-width:1.6;stroke-linecap:round"/>`,
    arms: coachArm('L', 72, 104, o) + coachArm('R', 128, 104, o),
  };
}

/** A character: its words, where its neck turns, its face's place and looks, and its drawn parts (a part may take the drawing's id). */
type Part = string | ((id: number) => string)
type Char = {
  group: string; name: string; desc: string; tags: string[]; neck: string; f: number[]; fo?: FaceLook; chin?: string; shadow?: number
  body: Part; head: Part; after?: Part; arms?: Part
}
const CHARS: Record<Model, Char> = {
  A1: {
    group: 'A', name: 'صقر', desc: 'صقر ذهبي بوشاح أخضر. رمز عربي للسرعة والطموح، وجناحاه يصفقان ويلوّحان.',
    tags: ['الترحيب', 'الشارات'], neck: '100px 128px', f: [100, 86, 1], fo: { beak: true }, chin: '112deg',
    body: () => `<ellipse cx="88" cy="203" rx="10" ry="5" ${st('orange')}/><ellipse cx="112" cy="203" rx="10" ry="5" ${st('orange')}/>
      <ellipse cx="100" cy="152" rx="44" ry="50" ${st('gold')}/><ellipse cx="100" cy="164" rx="27" ry="31" ${st('chrome', false)}/>
      <path d="M88 150 q6 5 12 0 q6 5 12 0 M88 166 q6 5 12 0 q6 5 12 0" ${ln('goldD', 2.4)}/>`,
    head: `<path d="M84 54 L90 32 L98 50 L104 28 L110 50 L120 36 L118 58Z" ${st('goldD')}/>
      <circle cx="100" cy="88" r="40" ${st('gold')}/><path d="M66 84 Q100 58 134 84 Q130 104 100 104 Q70 104 66 84Z" ${st('goldL', false)}/>`,
    after: `<rect x="66" y="112" width="68" height="14" rx="7" ${st('em')}/><path d="M114 120 h12 l3 26 l-9 -5 l-7 5z" ${st('emD')}/>`,
    arms: arms(58, 142, 126, (x, y) => `<ellipse cx="${x}" cy="${y + 22}" rx="11" ry="25" ${st('goldD')}/><path d="M${x - 5} ${y + 30} q5 6 10 0 M${x - 5} ${y + 38} q5 6 10 0" ${ln('gold', 2.2)}/>`),
  },
  A2: {
    group: 'A', name: 'أسد', desc: 'أسد بقميص رقم 10. قوي وودود، ورأسه الكبير واضح حتى بحجم صغير على الجوال.',
    tags: ['ما بعد الجولة', 'الشاشات الفارغة'], neck: '100px 128px', f: [100, 90, .85], chin: '126deg',
    body: () => `<path d="M132 176 q30 0 26 -30" ${ln('goldD', 5)}/><circle cx="158" cy="144" r="7" ${st('goldD')}/>
      <rect x="80" y="186" width="14" height="16" ${st('gold')}/><rect x="106" y="186" width="14" height="16" ${st('gold')}/>
      <ellipse cx="86" cy="204" rx="11" ry="5" ${st('k', false)}/><ellipse cx="114" cy="204" rx="11" ry="5" ${st('k', false)}/>
      <rect x="70" y="174" width="60" height="18" rx="6" ${st('emD')}/><rect x="66" y="122" width="68" height="60" rx="24" ${st('em')}/>
      <text x="100" y="165" text-anchor="middle" style="font:700 24px var(--f-num);fill:var(--gold)">10</text>`,
    head: Array.from({ length: 12 }, (_, i) => { const a = i * Math.PI / 6; return `<circle cx="${(100 + 40 * Math.cos(a)).toFixed(1)}" cy="${(92 + 40 * Math.sin(a)).toFixed(1)}" r="15" ${st('goldD')}/>`; }).join('')
      + `<circle cx="100" cy="92" r="42" ${st('goldD', false)}/>
      <circle cx="72" cy="64" r="10" ${st('gold')}/><circle cx="128" cy="64" r="10" ${st('gold')}/><circle cx="72" cy="64" r="4.5" ${st('goldL', false)}/><circle cx="128" cy="64" r="4.5" ${st('goldL', false)}/>
      <circle cx="100" cy="94" r="33" ${st('gold')}/><ellipse cx="100" cy="106" rx="18" ry="12" ${st('goldL', false)}/>
      <path d="M96 97 h8 l-4 4z" ${st('k', false)}/>`,
    arms: arms(70, 130, 130, (x, y) => `<rect x="${x - 7}" y="${y - 4}" width="14" height="22" rx="7" ${st('em')}/><rect x="${x - 6}" y="${y + 15}" width="12" height="14" rx="6" ${st('gold')}/><circle cx="${x}" cy="${y + 32}" r="8" ${st('gold')}/>`),
  },
  A3: {
    group: 'A', name: 'كورة', desc: 'الكرة نفسها بوجه وقفازين. أبسط النماذج وأكثرها مرحاً، وتناسب الصغار.',
    tags: ['التحميل', 'صفحة الخطأ'], neck: '100px 184px', f: [100, 124, 1.1], chin: '60deg', shadow: 52,
    body: () => `<path d="M86 180 L84 198 M114 180 L116 198" ${ln('k', 5)}/>
      <ellipse cx="80" cy="202" rx="11" ry="6" ${st('gold')}/><ellipse cx="120" cy="202" rx="11" ry="6" ${st('gold')}/>`,
    head: (uid) => `<clipPath id="ball${uid}"><circle cx="100" cy="128" r="56"/></clipPath>
      <circle cx="100" cy="128" r="56" ${st('chrome', false)}/>
      <g clip-path="url(#ball${uid})">${[[100, 66, 17], [44, 112, 16], [156, 112, 16], [64, 182, 16], [136, 182, 16]].map(([x, y, r]) => `<polygon points="${pent(x, y, r)}" ${st('navy', false)}/>`).join('')}</g>
      <circle cx="100" cy="128" r="56" ${ln('k', 3)}/>`,
    arms: arms(46, 154, 130, (x, y) => `<rect x="${x - 4}" y="${y}" width="8" height="28" rx="4" ${st('k', false)}/><circle cx="${x}" cy="${y + 32}" r="9" ${st('white')}/>`),
  },
  B1: {
    group: 'B', name: 'روبوت', desc: 'روبوت ذهبي بشاشة وجه خضراء مضيئة. يقول بوضوح إنه ذكاء اصطناعي، ويطابق اسم Manager Bot.',
    tags: ['نافذة الشات', 'التحليل'], neck: '100px 112px', f: [100, 74, .82], fo: { glow: true }, chin: '119deg',
    body: () => `<rect x="80" y="176" width="14" height="22" rx="4" ${st('goldD')}/><rect x="106" y="176" width="14" height="22" rx="4" ${st('goldD')}/>
      <rect x="74" y="196" width="24" height="10" rx="5" ${st('k', false)}/><rect x="102" y="196" width="24" height="10" rx="5" ${st('k', false)}/>
      <rect x="66" y="116" width="68" height="64" rx="18" ${st('gold')}/><rect x="80" y="130" width="40" height="30" rx="8" ${st('navy', false)}/>
      <circle class="fx-pulse" cx="100" cy="145" r="7" ${st('emL', false)}/><rect x="92" y="106" width="16" height="14" ${st('goldD')}/>`,
    head: `<path d="M100 42 V26" ${ln('k', 3)}/><circle class="fx-pulse" cx="100" cy="22" r="6" ${st('gold')}/>
      <rect x="48" y="62" width="12" height="26" rx="5" ${st('goldD')}/><rect x="140" y="62" width="12" height="26" rx="5" ${st('goldD')}/>
      <rect x="56" y="40" width="88" height="70" rx="24" ${st('gold')}/><rect x="64" y="48" width="72" height="54" rx="16" ${st('night', false)}/>`,
    arms: arms(62, 138, 124, (x, y) => `<rect x="${x - 6}" y="${y}" width="12" height="30" rx="6" ${st('goldD')}/><circle cx="${x}" cy="${y + 34}" r="8" ${st('gold')}/>`),
  },
  B2: {
    group: 'B', name: 'مساعد بقبعة', desc: 'شاب بقبعة وقميص النادي. أقرب للمدرب المساعد الحقيقي على الخط، ودافئ أكثر من الروبوت.',
    tags: ['نافذة الشات', 'ملاحظات المباراة'], neck: '100px 118px', f: [100, 92, .82], fo: { iris: 'bronze' }, chin: '118deg',
    body: () => legs('navy', 'k') + `<rect x="68" y="120" width="64" height="62" rx="20" ${st('em')}/>
      <path d="M88 120 L100 134 L112 120" ${st('chrome')}/><circle cx="116" cy="144" r="5" ${st('gold', false)}/>
      <rect x="93" y="108" width="14" height="14" ${st('skin')}/>`,
    head: `<circle cx="67" cy="92" r="7" ${st('skin')}/><circle cx="133" cy="92" r="7" ${st('skin')}/>
      <circle cx="100" cy="90" r="33" ${st('skin')}/>
      <path d="M68 84 Q70 64 100 62 Q130 64 132 84 Q120 74 100 74 Q80 74 68 84Z" ${st('k', false)}/>
      <path d="M66 78 Q68 48 100 48 Q132 48 134 78Z" ${st('em')}/><path d="M62 78 Q100 92 138 78 Q100 70 62 78Z" ${st('gold')}/>
      <circle cx="100" cy="48" r="4" ${st('gold', false)}/>`,
    arms: arms(70, 130, 128, (x, y) => `<rect x="${x - 8}" y="${y - 4}" width="16" height="18" rx="7" ${st('em')}/><rect x="${x - 5}" y="${y + 12}" width="10" height="18" rx="5" ${st('skin')}/><circle cx="${x}" cy="${y + 32}" r="7" ${st('skin')}/>`),
  },
  B3: {
    group: 'B', name: 'الزر بوجه', desc: 'الزر الذهبي نفسه بعينين وفم. يعمل بحجم 56 بكسل، ويناسب الوجه على الزر العائم إن غيّرت قرارك.',
    tags: ['الزر العائم', 'نافذة الشات'], neck: '100px 178px', f: [100, 112, 1.35], shadow: 40,
    body: () => '',
    head: `<path d="M64 160 L50 198 L92 176Z" ${st('gold')}/><circle cx="100" cy="114" r="62" ${st('gold')}/>
      <path d="M50 160 L64 160 L92 176" ${ln('gold', 0)}/><path d="M56 96 Q64 66 94 58" ${ln('goldL', 6)}/>`,
    arms: '',
  },
  C1: coach({
    name: 'مدرب ببدلة', desc: 'بدلة كحلية وربطة ذهبية، وشعر مسرّح جانباً. المدرب الكلاسيكي في المباريات الكبيرة.',
    tags: ['المباراة المباشرة', 'المؤتمر الصحفي'], skin: 'skin', iris: 'bronze', sleeve: 'navy', cuff: 'white', strands: 'M86 44 q8 -6 18 -4 M92 39 q10 -3 20 1 M80 54 q2 -8 7 -11',
    legs: 'navyD', shoe: 'k',
    torso: `<path d="M72 100 Q100 90 128 100 Q136 106 133 120 L126 154 L74 154 L67 120 Q64 106 72 100Z" ${st('navy')}/>
      <path d="M90 96 L100 121 L110 96Z" ${st('white', false)}/><path d="M98 99 h4 l2.5 22 l-4.5 5 l-4.5 -5z" ${st('gold', true, 2)}/>
      <path d="M90 96 L97 125 L92 128 M110 96 L103 125 L108 128" ${ln('k', 2)}/><circle cx="100" cy="136" r="2" ${st('goldD', false)}/><circle cx="100" cy="146" r="2" ${st('goldD', false)}/>
      <path d="M113 110 h9 l-1.5 5 l-3.5 -1.5 l-3 1.5z" ${st('em', false)}/>`,
    hair: `<path d="M78 62 Q74 34 100 32 Q126 32 123 58 Q119 46 108 46 Q97 39 87 46 Q80 51 78 62Z" ${st('k', false)}/>
      <path d="M86 42 Q98 36 112 40" ${ln('navy', 2)}/>`,
  }),
  C2: coach({
    name: 'مدرب بالتراك سوت', desc: 'بدلة تدريب خضراء بخطوط ذهبية، ولحية خفيفة وصافرة. مدرب الملعب والتدريب.',
    tags: ['المباراة المباشرة', 'التدريب'], skin: 'bronze', iris: 'k', sleeve: 'em', stripe: 'gold', strands: 'M88 40 q12 -4 24 0',
    legs: 'em', legStripe: 'gold', shoe: 'white', shoeO: true,
    torso: `<path d="M72 100 Q100 90 128 100 Q136 106 133 120 L127 154 L73 154 L67 120 Q64 106 72 100Z" ${st('em')}/>
      <path d="M100 100 V154" ${ln('emD', 2.4)}/><path d="M88 94 Q100 100 112 94 L112 100 Q100 106 88 100Z" ${st('emD')}/>
      <path d="M68 116 L72 102 M132 116 L128 102" ${ln('gold', 2.4)}/>
      <path d="M92 100 Q100 126 108 100" ${ln('gold', 1.6)}/><rect x="96" y="122" width="10" height="6" rx="3" ${st('silver', true, 1.8)}/>`,
    hair: `<path d="M79 58 Q80 33 100 33 Q120 33 121 58 Q112 45 100 45 Q88 45 79 58Z" ${st('k', false)}/>
      <path d="M79 62 Q80 90 100 90 Q120 90 121 62 Q118 80 100 83 Q82 80 79 62Z" style="fill:var(--k);opacity:.88"/>`,
  }),
  C3: coach({
    name: 'مدربة بحجاب', desc: 'حجاب أخضر وسترة عاجية وبطاقة الجهاز الفني. تمنح المدربات شخصية تمثلهن.',
    tags: ['المباراة المباشرة', 'ملف المدرب'], skin: 'skin', iris: 'emD', sleeve: 'chrome', face: [100, 64, .55],
    legs: 'navyD', shoe: 'gold',
    torso: `<path d="M72 100 Q100 90 128 100 Q136 106 133 120 L126 154 L74 154 L67 120 Q64 106 72 100Z" ${st('chrome')}/>
      <path d="M100 112 V154" ${ln('chromeD', 2)}/><circle cx="105" cy="126" r="2.2" ${st('goldD', false)}/><circle cx="105" cy="140" r="2.2" ${st('goldD', false)}/>
      <path d="M88 100 L112 128" ${ln('em', 2)}/><rect x="108" y="126" width="12" height="15" rx="2" ${st('gold', true, 2)}/>`,
    hijab: `<path d="M76 68 Q72 28 100 28 Q128 28 124 68 L130 106 Q100 118 70 106Z" ${st('em')}/>`,
    hijabFront: `<path class="rich" d="M76 90 Q77 102 84 110 M124 90 Q123 102 116 110" style="fill:none;stroke:var(--k);stroke-opacity:.2;stroke-width:1.4;stroke-linecap:round"/><path d="M82 56 Q85 40 100 40 Q115 40 118 56" ${ln('emD', 3)}/><circle cx="121" cy="92" r="2.6" ${st('gold', false)}/>`,
  }),
};

let uid = 0;
/** One character in a mood, as an SVG string (the draft's own drawing). */
export function drawCharacter(code: Model, mood: Mood): string {
  const c = CHARS[code];
  const id = ++uid;
  const part = (v: Part | undefined) => typeof v === 'function' ? v(id) : v ?? '';
  return `<svg class="char m-${mood}" viewBox="0 0 200 220" style="--chin:${c.chin || '120deg'}" aria-hidden="true">
    <ellipse class="shadow" cx="100" cy="208" rx="${c.shadow || 46}" ry="7"/>
    <g class="rig">${part(c.body)}<g class="head" style="transform-origin:${c.neck}">${part(c.head)}<g class="face" transform="translate(${c.f[0]} ${c.f[1]}) scale(${c.f[2]})">${face(mood, c.fo)}</g></g>${part(c.after || '')}${part(c.arms)}</g>
  </svg>`;
}

/** The face alone, for a mood change without redrawing the body (the arms then move smoothly). */
export function drawFace(code: Model, mood: Mood): string {
  return face(mood, CHARS[code].fo);
}
