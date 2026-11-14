// [Sprint 57 W4] The trap scene (art.ts's SCENES.trap).
import { t as tr } from '../../../lib/i18n'
import { burst, dust, headOf } from '../effects'
import { ball, player, put, title } from '../figures'
import { K, type SceneData, type SvgNode, ease, el, inout, lerp, other, rnd, sa, seg } from '../kit'
import { cam, persp, stage } from '../stage'

// [Sprint 42 F3] The offside trap: the through ball is played, and in one step the whole back line jumps forward
// together. The striker stops dead, white dashed lines appear on the grass, and the assistant's flag waves in the
// corner of the screen with a sharp whistle.
export function trap(e: SceneData) {
  const R = rnd(Number(e.no || 9) * 61), svg = stage(e.side), w = svg.world, atk = K(e.side).kit, dfk = K(other(e.side)).kit
  const defs = [214, 282, 358, 426].map(() => player(w, dfk, '', 1, { look: Math.floor(R() * 40) }))
  const st = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) }), pm = player(w, atk, '', 1, { look: Math.floor(R() * 40) }), b = ball(svg)
  const lines = el('g', { stroke: '#FFFFFF', 'stroke-width': 2, 'stroke-dasharray': '10 7', fill: 'none', opacity: 0 }, w)
  lines.innerHTML = `<path data-l="d" d="M110 0 H530"/><path data-l="a" d="M110 0 H530" stroke="#FFD36B"/>`
  const lD = lines.querySelector<SvgNode>('[data-l="d"]')!, lA = lines.querySelector<SvgNode>('[data-l="a"]')!
  const skid = dust(svg, w, 6), blow = burst(svg, w)
  // The assistant's flag in the corner of the screen.
  const flag = el('g', { opacity: 0 }, svg)
  flag.innerHTML = '<rect x="520" y="78" width="104" height="104" rx="10" fill="rgba(4,11,28,.8)" stroke="#F5B82E" stroke-width="2"/><path d="M552 170 V96" stroke="#C9D2E1" stroke-width="4" stroke-linecap="round"/><path data-flag="1" fill="#EF4444" stroke="#B91C1C" stroke-width="1"/>'
  const cloth = flag.querySelector<SvgNode>('[data-flag]')!
  const tt = title(svg, tr('مصيدة التسلل!'), '#EF4444')
  const KT = 1.5
  return { dur: 3.6, svg, update(t: number) {
    cam(svg, 1.08, 320, 210)
    // The back line: level, then all four step up at once (a little hop) at 0.95 s.
    const up = inout(seg(t, 0.95, 1.25)), hop = Math.sin(Math.PI * seg(t, 0.95, 1.25)) * 8
    const dy = lerp(214, 250, up)
    // eslint-disable-next-line @typescript-eslint/no-unused-expressions -- the clips' frames are written as comma sequences
    defs.forEach((d, i) => { const x = [214, 282, 358, 426][i]; put(d, x, dy, 0, 1, hop * persp(dy)); d.face?.('front'); t > 0.95 && t < 1.25 ? d.pose(10, -10, 40, -40, 0.4, 0.4) : t > 1.3 ? (d.mood('joy'), d.pose(3, -3, i % 2 ? 150 : 14, i % 2 ? -14 : -150)) : d.run(t * 9, 0.3) })
    // The striker sets off for the ball, and stops dead, skidding.
    const go = ease(seg(t, 0.8, 1.3)), sy = lerp(222, 196, go)
    // eslint-disable-next-line @typescript-eslint/no-unused-expressions -- the clips' frames are written as comma sequences
    put(st, 330, sy); t < 1.3 ? st.run(t * 13, 0.3 + go) : (st.face?.('front'), st.mood('shock'), st.pose(20, -20, 60, -60))
    skid(330, sy + 4, seg(t, 1.3, 1.9))
    // The playmaker plays it through at 0.85 s.
    put(pm, 300, 300); t < 0.7 ? pm.run(t * 10, 0.4) : pm.kick(seg(t, 0.7, 0.95))
    const f = seg(t, 0.85, 1.6), p = [lerp(300, 344, f), lerp(296, 168, ease(f))]
    b.set(p[0], p[1], p[1], t * 900)
    // The lines on the grass: the defence's, and the striker beyond it.
    sa(lines, 'opacity', seg(t, KT, KT + 0.15))
    sa(lD, 'transform', `translate(0 ${dy + 58 * persp(dy) * 0 + 2})`); sa(lA, 'transform', `translate(0 ${sy + 2})`)
    sa(flag, 'opacity', seg(t, KT, KT + 0.1))
    const wv = Math.sin(t * 18) * 6
    sa(cloth, 'd', `M554 98 Q574 ${98 + wv} 596 98 L596 128 Q574 ${128 - wv} 554 128 Z`)
    const [hx, hy] = headOf(320, 186, 1)
    blow(hx + 220, hy - 40, seg(t, KT, KT + 0.4))
    tt(seg(t, KT + 0.25, KT + 0.6))
  } }
}
