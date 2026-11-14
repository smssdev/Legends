// [Sprint 57 W4] The coach scene (art.ts's SCENES.coach).
import { K, type SceneData, ease, el, esc, lerp, sa, seg } from '../kit'
import { ref, stage } from '../stage'

export function coach(e: SceneData) {
  // The touchline tablet: the shape and the instruction's arrows, drawn live.
  const svg = stage(e.side),
    kit = K(e.side).kit
  const tab = el('g', {}, svg)
  tab.innerHTML = `<rect x="-150" y="-100" width="300" height="200" rx="16" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><rect x="-136" y="-86" width="272" height="172" rx="8" fill="#0C3A26"/><g stroke="rgba(255,255,255,.45)" fill="none" stroke-width="1.3"><path d="M0 -86 V86"/><circle r="24"/><rect x="-136" y="-40" width="40" height="80"/><rect x="96" y="-40" width="40" height="80"/></g>`
  const dots = [
    [-110, 0],
    [-70, -50],
    [-70, -17],
    [-70, 17],
    [-70, 50],
    [-20, -35],
    [-20, 0],
    [-20, 35],
    [35, -50],
    [45, 0],
    [35, 50],
  ].map(([x, y]) => {
    const d = el('circle', { r: 8, fill: kit, stroke: '#071733', 'stroke-width': 2 }, tab)
    d.dataset.x = String(x)
    d.dataset.y = String(y)
    return d
  })
  const ar = el('g', { fill: 'none', stroke: '#FFD36B', 'stroke-width': 3, 'stroke-linecap': 'round', filter: ref(svg, 'glow') }, tab)
  const A = [
    [-20, -35, 30, -60],
    [-20, 35, 30, 60],
    [-70, -50, -30, -75],
    [-70, 50, -30, 75],
  ].map(([a, b, c, d]) => el('path', { d: `M${a} ${b} L${c} ${d}`, 'stroke-dasharray': 80, 'stroke-dashoffset': 80 }, ar))
  const chip = el('g', { opacity: 0 }, svg)
  chip.innerHTML = `<rect x="-150" y="-20" width="300" height="40" rx="20" fill="${ref(svg, 'gold')}"/><text y="7" text-anchor="middle" font-family="Tajawal, sans-serif" font-weight="800" font-size="18" fill="#071733">${esc(e.tactic)}</text>`
  return {
    dur: 4.6,
    svg,
    update(t: number) {
      sa(tab, 'transform', `translate(320 ${lerp(380, 158, ease(seg(t, 0, 0.6)))}) scale(.9)`)
      const push = ease(seg(t, 1, 2))
      dots.forEach((d) => {
        sa(d, 'cx', +d.dataset.x! + (+d.dataset.x! > -100 ? push * 26 : 0))
        sa(d, 'cy', d.dataset.y!)
      })
      A.forEach((a, i) => sa(a, 'stroke-dashoffset', 80 * (1 - ease(seg(t, 0.9 + i * 0.15, 1.6 + i * 0.15)))))
      sa(chip, 'opacity', seg(t, 1.6, 2))
      sa(chip, 'transform', `translate(320 306) scale(${0.85 + 0.15 * ease(seg(t, 1.6, 2))})`)
    },
  }
}
