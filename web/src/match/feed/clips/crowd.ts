// [Sprint 57 W4] The crowd scene (art.ts's SCENES.crowd).
import { t as tr } from '../../../lib/i18n'
import { title } from '../figures'
import { K, type SceneData, type SvgNode, ease, el, rnd, sa, seg } from '../kit'
import { cam, ref, stage } from '../stage'

// ------------------------------------------------------------ [Sprint 35 C1] the director's cutaways
// The crowd behind the goal on its feet: the scoring side's fans jumping with their arms and scarves up, two big
// flags waving, and (the full tier) flares and paper raining down. e.side: whose fans; e.count: how many to draw.
export function crowd(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    k = K(e.side),
    R = rnd(e.v ?? 7)
  const g = el('g', {}, w)
  const skins = ['#C99A78', '#8D5A3B', '#E2B48F', '#6B4027', '#B07B57', '#D9A982']
  const n = e.count ?? 90
  // [Sprint 42 I1] The fans in blocks (a row by an eighth of the stand) that jump together, each block on its own
  // beat: about 48 moves a frame instead of three for every fan (the cutaway was the slowest drawing of all).
  // Made in order, back row first, so the front rows stand in front.
  const blocks = new Map()
  for (let row = 0; row < 6; row++)
    for (let col = 0; col < 8; col++) blocks.set(row * 8 + col, { g: el('g', {}, g), x: col * 88 + 14, row, ph: R() * 6.3 })
  for (let i = 0; i < n; i++) {
    const row = i % 6,
      x = ((i * 53 + row * 29) % 700) - 30,
      y = 120 + row * 38,
      s = 0.7 + row * 0.12,
      col = Math.max(0, Math.min(7, Math.floor((x + 30) / 88)))
    const key = row * 8 + col
    const bl = blocks.get(key),
      shirt = R() < 0.7 ? k.kit : (k.trim ?? '#fff'),
      arms = i % 2 ? 'up' : 'v'
    const f = el('g', { transform: `translate(${x} ${y}) scale(${s})` }, bl.g)
    f.innerHTML =
      `<rect x="-9" y="0" width="18" height="26" rx="6" fill="${shirt}"/><circle cy="-8" r="8" fill="${skins[i % skins.length]}"/>` +
      (arms === 'up'
        ? `<rect x="-13" y="-22" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(-12 -10 -4)"/><rect x="8" y="-22" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(12 10 -4)"/>`
        : `<rect x="-16" y="-14" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(-40 -9 2)"/><rect x="11" y="-14" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(40 9 2)"/>`) +
      (i % 4 === 0 ? `<rect x="-16" y="-34" width="32" height="7" rx="2" fill="${k.trim ?? '#F5B82E'}"/>` : '')
  }
  const fans = [...blocks.values()]
  const flags = [140, 470].map((x) => {
    const p = el('path', { fill: k.kit, stroke: k.trim ?? '#fff', 'stroke-width': 3, opacity: 0.95 }, w)
    return { p, x }
  })
  const flares = (e.flares ? [90, 330, 560] : []).map((x) =>
    el('circle', { cx: x, cy: 150, r: 26, fill: '#FF8A3D', opacity: 0, filter: ref(svg, 'soft') }, w),
  )
  const paper = e.flares
    ? Array.from({ length: 40 }, (_, i) => el('rect', { width: 5, height: 3, fill: ['#fff', k.kit, '#F5B82E'][i % 3], opacity: 0.9 }, w))
    : []
  // [Sprint 42 H2] One crowd in two does a Mexican wave; and the club's mascot dances in front of them.
  const wave = rnd((e.v ?? 7) * 5 + 3)() < 0.5
  const masc = el('g', {}, w)
  masc.innerHTML = `<ellipse cx="0" cy="62" rx="34" ry="7" fill="rgba(0,0,0,.4)"/><ellipse cx="0" cy="20" rx="30" ry="38" fill="${k.kit}" stroke="${k.trim ?? '#fff'}" stroke-width="3"/><circle cy="-30" r="26" fill="${k.trim ?? '#F5B82E'}" stroke="${k.kit}" stroke-width="3"/><circle cx="-9" cy="-34" r="8" fill="#fff"/><circle cx="9" cy="-34" r="8" fill="#fff"/><circle cx="-8" cy="-33" r="3.5" fill="#111"/><circle cx="10" cy="-33" r="3.5" fill="#111"/><path d="M-12 -18 Q0 -6 12 -18" fill="#5A1A14"/><path d="M-22 -50 L-14 -62 L-8 -50 M8 -50 L14 -62 L22 -50" fill="${k.kit}"/><rect data-m="1" x="-44" y="0" width="14" height="40" rx="7" fill="${k.kit}"/><rect data-m="2" x="30" y="0" width="14" height="40" rx="7" fill="${k.kit}"/>`
  const mArm = [masc.querySelector<SvgNode>('[data-m="1"]')!, masc.querySelector<SvgNode>('[data-m="2"]')!]
  const tt = title(svg, wave ? tr('موجة في المدرجات') : tr('فرحة الجماهير'))
  return {
    dur: 2.6,
    svg,
    update(t: number) {
      cam(svg, 1.25 - 0.08 * ease(seg(t, 0, 2.6)), 320, 200)
      const mx = 320 + Math.sin(t * 2) * 120,
        md = Math.sin(t * 10)
      sa(masc, 'transform', `translate(${mx.toFixed(1)} ${(250 - Math.abs(md) * 12).toFixed(1)}) rotate(${(md * 8).toFixed(1)})`)
      sa(mArm[0], 'transform', `rotate(${(150 + md * 30).toFixed(0)} -37 4)`)
      sa(mArm[1], 'transform', `rotate(${(-150 + md * 30).toFixed(0)} 37 4)`)
      for (const q of fans) {
        const j = wave ? Math.max(0, Math.sin(t * 4 - q.x / 70)) ** 3 * 22 : Math.abs(Math.sin(t * 7 + q.ph)) * 10
        sa(q.g, 'transform', `translate(0 ${(-j).toFixed(1)})`)
      }
      for (const { p, x } of flags) {
        const wv = (dx: number) => Math.sin(t * 6 + dx / 18) * 8
        sa(p, 'd', `M${x} 60 L${x + 120} ${60 + wv(120)} L${x + 120} ${130 + wv(120)} L${x} 130 Z`)
      }
      flares.forEach((f, i) => sa(f, 'opacity', 0.5 + 0.3 * Math.sin(t * 13 + i * 2)))
      paper.forEach((r, i) => {
        const x = ((i * 83 + t * 30 * ((i % 3) + 1)) % 700) - 30,
          y = ((t * (60 + (i % 5) * 20) + i * 37) % 360) - 20
        sa(r, 'transform', `translate(${x} ${y}) rotate(${t * 200 + i * 40})`)
      })
      tt(seg(t, 0.3, 0.7))
    },
  }
}
