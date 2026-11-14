// [Sprint 57 W4] The whistle scene (art.ts's SCENES.whistle).
import { K, type SceneData, ease, el, sa, seg } from '../kit'
import { ref, stage } from '../stage'

export function whistle(e: SceneData) {
  // Half time and full time: the score and the numbers of the match so far.
  const svg = stage('home'),
    g = el('g', {}, svg)
  el('rect', { x: 110, y: 26, width: 420, height: 296, rx: 18, fill: 'rgba(4,11,28,.9)', stroke: 'rgba(245,184,46,.35)' }, g)
  el(
    'text',
    {
      x: 320,
      y: 66,
      'text-anchor': 'middle',
      'font-family': 'Tajawal, sans-serif',
      'font-weight': 700,
      'font-size': 28,
      fill: ref(svg, 'gold'),
    },
    g,
  ).textContent = e.big ?? ''
  el(
    'text',
    {
      x: 320,
      y: 108,
      'text-anchor': 'middle',
      'font-family': 'Barlow Condensed, sans-serif',
      'font-weight': 800,
      'font-size': 42,
      fill: '#fff',
      direction: 'ltr',
    },
    g,
  ).textContent = e.score ?? ''
  const rows = (e.stats ?? []).slice(0, 4)
  const bars = rows.map(([label, h, a], i: number) => {
    const y = 146 + i * 44
    el(
      'text',
      { x: 320, y: y - 6, 'text-anchor': 'middle', 'font-family': 'Tajawal, sans-serif', 'font-size': 13, fill: '#93A3BF' },
      g,
    ).textContent = label
    el(
      'text',
      {
        x: 500,
        y: y + 12,
        'text-anchor': 'middle',
        'font-family': 'Barlow Condensed, sans-serif',
        'font-weight': 700,
        'font-size': 22,
        fill: '#fff',
      },
      g,
    ).textContent = String(h)
    el(
      'text',
      {
        x: 140,
        y: y + 12,
        'text-anchor': 'middle',
        'font-family': 'Barlow Condensed, sans-serif',
        'font-weight': 700,
        'font-size': 22,
        fill: '#fff',
      },
      g,
    ).textContent = String(a)
    el('rect', { x: 170, y: y + 3, width: 300, height: 8, rx: 4, fill: 'rgba(255,255,255,.08)' }, g)
    return {
      hb: el('rect', { x: 320, y: y + 3, width: 0, height: 8, rx: 4, fill: K('home').kit }, g),
      ab: el('rect', { x: 320, y: y + 3, width: 0, height: 8, rx: 4, fill: K('away').kit }, g),
      h,
      a,
    }
  })
  return {
    dur: 3.6,
    svg,
    update(t: number) {
      sa(g, 'opacity', seg(t, 0, 0.4))
      // Home on the right, as on the scoreboard.
      bars.forEach((b, i) => {
        const f = ease(seg(t, 0.4 + i * 0.15, 1.2 + i * 0.15)),
          tot = b.h + b.a || 1,
          wh = ((150 * b.h) / tot) * f,
          wa = ((150 * b.a) / tot) * f
        sa(b.hb, 'width', wh)
        sa(b.ab, 'x', 320 - wa)
        sa(b.ab, 'width', wa)
      })
    },
  }
}
