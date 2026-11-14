// [Sprint 57 W4] The rant scene (art.ts's SCENES.rant).
import { t as tr } from '../../../lib/i18n'
import { burst, headOf, vein } from '../effects'
import { player, title } from '../figures'
import { K, type SceneData, el, lerp, rnd, sa, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 42 F7] The coach's megaphone: play stops for a moment, he stands on the line and shouts through a huge
// megaphone; angry letters and symbols fly out and bounce off his players, who shake and sweat. No instruction is
// shown (the other side's stay private).
export function rant(e: SceneData) {
  const R = rnd(e.v ?? 37),
    svg = stage(e.side),
    w = svg.world,
    kit = K(e.side).kit
  const pls = [0, 1, 2].map(() => player(w, kit, '', 1.1, { look: Math.floor(R() * 40) }))
  const co = player(w, '#1F2937', '', 1.7, { look: Math.floor(R() * 40), shorts: '#1F2937', socks: '#111827', trim: kit })
  const mega = el('g', {}, w)
  mega.innerHTML =
    '<path d="M0 -6 L34 -22 L34 22 L0 6 Z" fill="#F5B82E" stroke="#8A5A00" stroke-width="2"/><rect x="-8" y="-6" width="10" height="12" rx="2" fill="#333"/><ellipse cx="34" cy="0" rx="5" ry="22" fill="#FFD36B" stroke="#8A5A00" stroke-width="2"/>'
  const SYM = ['#@!', '!!', '%&$', '?!', '@#!', '!!!']
  const sym = SYM.map((x) => {
    const e2 = el(
      'text',
      {
        'font-family': 'Barlow Condensed, sans-serif',
        'font-weight': 800,
        'font-size': 22,
        fill: '#EF4444',
        stroke: '#fff',
        'stroke-width': 3,
        'paint-order': 'stroke',
        opacity: 0,
      },
      w,
    )
    e2.textContent = x
    return e2
  })
  const waves = burst(svg, w, '#FFD36B', 6),
    vn = vein(svg)
  const drops = pls.map(() => el('path', { d: 'M0 -5 Q4 1 0 3 Q-4 1 0 -5 Z', fill: '#9AD4FF', opacity: 0 }, w))
  const tt = title(svg, tr('المدرب غاضب!'), '#EF4444')
  return {
    dur: 3.6,
    svg,
    update(t: number) {
      cam(svg, 1.04, 320, 200)
      co.face?.('side', 1)
      co.mood('angry')
      co.at(120, 214 + Math.sin(t * 30) * 1.5, 0, 1.7)
      co.pose(4, -4, 20, -95 + Math.sin(t * 20) * 6)
      const [hx, hy] = headOf(120, 214, 1.7),
        mx = hx + 22,
        my = hy + 6
      sa(
        mega,
        'transform',
        `translate(${mx} ${my}) rotate(${(-6 + Math.sin(t * 20) * 4).toFixed(1)}) scale(${(1 + 0.08 * Math.sin(t * 30)).toFixed(2)})`,
      )
      vn(hx - 8, hy - 18, seg(t, 0.2, 0.3), t)
      waves(mx + 40, my, (t * 3) % 1, 18)
      // The words fly out of the megaphone to the players and bounce off them.
      sym.forEach((x, i) => {
        const ph = ((t - 0.3) * 1.1 + i / SYM.length) % 1,
          on = t > 0.3 && t < 3.3,
          to = [400 + (i % 3) * 70, 150]
        const px = lerp(mx + 40, to[0], ph),
          py = lerp(my, to[1], ph) - Math.sin(Math.PI * ph) * 40
        sa(x, 'opacity', on ? (ph < 0.85 ? 1 : (1 - ph) * 6.6).toFixed(2) : 0)
        sa(x, 'x', px.toFixed(1))
        sa(x, 'y', py.toFixed(1))
        sa(x, 'font-size', (16 + ph * 14).toFixed(1))
      })
      pls.forEach((p, i) => {
        const x = 400 + i * 70,
          y = 196 + (i % 2) * 14,
          sh = t > 0.6 ? Math.sin(t * 50 + i) * 2.5 : 0
        p.face?.('front')
        p.mood(t > 0.6 ? 'shock' : 'idle')
        p.at(x + sh, y, 0, 1.1)
        p.pose(4, -4, t > 0.6 ? 40 : 10, t > 0.6 ? -40 : -10)
        sa(drops[i], 'opacity', t > 0.7 ? 0.9 : 0)
        sa(drops[i], 'transform', `translate(${x + 12} ${(y - 30 + ((t * 40 + i * 5) % 14)).toFixed(1)})`)
      })
      tt(seg(t, 0.3, 0.7))
    },
  }
}
