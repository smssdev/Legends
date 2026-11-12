// @ts-nocheck
// [Sprint 57 W4] The blocked scene (art.ts's SCENES.blocked).
import { t as tr } from '../../../lib/i18n'
import { title } from '../figures'
import { el, sa, seg } from '../kit'
import { openPlay } from '../play'
import { ref } from '../stage'

export function blocked(e) {
  const KT = 2.6, { svg, go } = openPlay(e, 'blocked', KT)
  const ring = el('circle', { r: 22, fill: 'none', stroke: '#7FB4FF', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg.world)
  const tt = title(svg, tr('صدّها الدفاع'), '#7FB4FF')
  return { dur: 4.8, svg, update(t) {
    const { target } = go(t)
    const s = seg(t, KT - 0.02, KT + 0.6); sa(ring, 'transform', `translate(${target[0]} ${target[1]}) scale(${0.4 + s * 1.5})`); sa(ring, 'opacity', s > 0 ? 1 - s : 0)
    tt(seg(t, KT + 0.3, KT + 0.7))
  } }
}
