// [Sprint 57 W4] The card scene (art.ts's SCENES.card).
import { t as tr } from '../../../lib/i18n'
import { bottle, brawlCloud, bubbleOf, burst, dust, headOf, referee, shakeIt, tackle, tint, vein } from '../effects'
import { player, title } from '../figures'
import { K, type SceneData, ease, el, lerp, other, rnd, sa, seg } from '../kit'
import { cam, ref, stage } from '../stage'

// [Sprint 35 C2] The card: the referee holds it up over the offender, who protests (arms out, or hands together
// pleading); a red, and he walks off, head down, past his team-mate.
// [Sprint 42 D1] A card, as a cartoon (tick.moment.drama, the server's): the slide tackle and the flip, then one of
// four tellings. tackle: the referee runs in angry, rummages in his pocket and whips the card out; swarm: the
// offender's team-mates surround him, arms flying, and he backs off blowing his whistle; brawl: the two vanish in a
// cloud of dust with fists and boots flying out; spit: a close-up of the argument, the spit, the referee's shock,
// his slow wipe, his face going red. A yellow: the offender acts innocent. A red: a red flash, the referee points
// to the tunnel, and on his way off the player kicks a water bottle.
export function card(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    red = e.type === 'red',
    R = rnd(e.v ?? Number(e.no ?? 4) * 13)
  const drama = e.drama && ['swarm', 'brawl', 'spit'].includes(e.drama) ? e.drama : 'tackle',
    KT = 3.4,
    k = 1.4
  const kit = K(e.side).kit,
    col = red ? '#EF4444' : '#FFD400'
  const vi = player(w, K(other(e.side)).kit, e.victimNo ?? '', k, { look: Math.floor(R() * 40) })
  const mates = drama === 'swarm' ? [0, 1, 2].map(() => player(w, kit, '', k, { look: Math.floor(R() * 40) })) : []
  const bot = red ? bottle(w) : null
  const pl = player(w, kit, e.no, k, { look: Math.floor(R() * 40) }),
    rf = referee(w, k)
  const fx = { dust: dust(svg), slide: dust(svg, w, 5), ouch: bubbleOf(svg, w, '!!!') }
  const cloud = drama === 'brawl' ? brawlCloud(svg) : null
  const vnP = vein(svg),
    vnR = vein(svg),
    swear = bubbleOf(svg, w, '#@!%&!'),
    swear2 = bubbleOf(svg, w, '?!#@!'),
    blow = burst(svg, w),
    kickB = burst(svg, w, '#7FC8FF')
  const hot = el('circle', { r: 13.2, fill: '#B00000', opacity: 0 }, w),
    steam = dust(svg, w, 6)
  const spit = el('ellipse', { rx: 2.6, ry: 1.8, fill: '#DFF4FF', stroke: '#7FB4D9', 'stroke-width': 0.8, opacity: 0 }, w)
  const notes = el('text', { 'font-size': 16, fill: '#FFFFFF', 'font-family': 'sans-serif', opacity: 0 }, w)
  notes.textContent = '♪ ♫'
  const glow = el('circle', { r: 70, fill: col, opacity: 0, filter: ref(svg, 'soft') }, w)
  const yel = tint(svg, '#FFD400'),
    redT = tint(svg, '#FF1E1E'),
    blue = tint(svg, '#3B82F6')
  const tt = title(svg, red ? tr('طرد!') : tr('إنذار'), col)
  // Where the referee stands to show it, and where the offender stands in front of him.
  const RX = drama === 'swarm' ? 430 : 395,
    PX = drama === 'spit' ? 318 : 300
  return {
    dur: 6.6,
    svg,
    update(t: number) {
      blow(0, 0, 0)
      // The tackle (contact at 0.8 s); the victim lies there and rolls, unless a brawl gets him up.
      const up = drama === 'brawl' ? 1.55 : Infinity
      tackle(svg, t, 0.8, pl, vi, k, fx, up, drama === 'spit' || drama === 'swarm' ? 1.7 : Infinity)
      // The camera: a little closer for the card; right up on the faces for the spit.
      const near = drama === 'spit' ? ease(seg(t, 1.8, 2.1)) * (1 - ease(seg(t, KT, KT + 0.4))) : 0
      cam(svg, lerp(1.06 + 0.06 * seg(t, 1.4, KT), 2.3, near), lerp(320, 336, near), lerp(205, 172, near))
      // ---- the referee comes in
      const tIn = drama === 'spit' ? [1.35, 1.8] : drama === 'brawl' ? [2.1, 2.7] : [1.35, 2.2]
      const rIn = ease(seg(t, tIn[0], tIn[1]))
      let rx = lerp(700, drama === 'spit' ? 362 : RX, rIn)
      if (drama === 'swarm') rx += 40 * ease(seg(t, 2.0, 3.0)) - 40
      if (t < tIn[1]) {
        rf.face?.('side', -1)
        rf.mood('focus')
        rf.run(t * 16, 1)
      } else {
        rf.face?.(drama === 'spit' && t < 2.62 ? 'side' : 'front', -1)
        rf.mood(drama === 'spit' && t > 2.62 && t < 3.0 ? 'shock' : 'angry')
        rf.pose(3, -3, 12, -12)
      }
      rf.at(rx, 200, 0, k)
      const [hx, hy] = headOf(rx, 200, k)
      vnR(hx + 12, hy - 14, drama === 'spit' ? 0 : seg(t, tIn[1], tIn[1] + 0.2) * (1 - seg(t, 5.4, 5.6)), t)
      // ---- each drama before the card
      if (drama === 'swarm') {
        // Four of them round him, arms flying; he backs away blowing his whistle again and again.
        const crowd = [pl, ...mates],
          spots = [
            [-62, 4],
            [-34, -10],
            [44, -8],
            [70, 6],
          ],
          from = [
            [-260, 10],
            [-320, -20],
            [-420, 0],
            [-200, 30],
          ]
        const s1 = ease(seg(t, 1.5, 2.0)),
          back = ease(seg(t, 3.0, 3.25))
        crowd.forEach((p, i) => {
          if (t < 1.5 && i === 0) return
          const x = rx + lerp(from[i][0], spots[i][0] * (1 + back * 0.9), s1),
            y = 200 + spots[i][1] + from[i][1] * (1 - s1)
          p.face?.(s1 < 1 ? 'side' : 'front', 1)
          p.mood('angry')
          p.at(x, y, 0, k)
          if (s1 < 1) p.run(t * 15, 1)
          else if (t < 3.0) p.pose(4, -4, 90 + Math.sin(t * 28 + i) * 55, -90 - Math.sin(t * 31 + i * 2) * 55)
          else p.pose(3, -3, 14, -14)
        })
        swear(rx - 40, 128, seg(t, 2.0, 2.15) * (1 - seg(t, 2.95, 3.05)), 0.9, Math.sin(t * 40) * 2)
        swear2(rx + 60, 134, seg(t, 2.2, 2.35) * (1 - seg(t, 2.95, 3.05)), 0.85, Math.cos(t * 37) * 2)
        if (t > 2.0 && t < 3.0) {
          rf.pose(3, -3, 30, -150)
          blow(hx + 5, hy + 4, ((t - 2.0) % 0.25) / 0.25)
        }
      } else if (drama === 'brawl') {
        // The victim is up and charges; the two vanish in the dust cloud!, fists and boots flying out of it.
        const inCloud = t > 1.85 && t < 2.95,
          f = seg(t, 1.8, 1.95) * (1 - seg(t, 2.9, 3.15))
        cloud!(340, 236, t, f)
        sa(pl.g, 'opacity', inCloud ? 0 : 1)
        sa(vi.g, 'opacity', inCloud ? 0 : 1)
        swear(340, 150, f, 1, Math.sin(t * 40) * 2)
        shakeIt(svg, inCloud ? 3 : 0, t)
        if (t >= up && t < 1.85) {
          const c = ease(seg(t, up, 1.85))
          vi.face?.('side', -1)
          vi.mood('angry')
          vi.at(lerp(430, 360, c), lerp(268, 200, Math.min(1, c * 2)), lerp(90, 0, Math.min(1, c * 2)), k)
          vi.run(t * 14, 1)
        } else if (t >= 2.95) {
          vi.face?.('front')
          vi.mood('angry')
          vi.at(500, 206, 0, k)
          vi.pose(4, -4, 40 + Math.sin(t * 9) * 10, -40)
        }
        if (t > 2.7 && t < 3.2) blow(hx + 5, hy + 4, seg(t, 2.7, 3.1))
        vnP(PX + 12, 200 - 21 * k - 14, t > 2.95 && t < 3.9 ? 1 : 0, t)
      } else if (drama === 'spit') {
        // The close-up: he argues, spits, the referee stares, wipes his face slowly, and goes red with anger.
        if (t > 1.6 && t < KT) {
          pl.face?.('side', 1)
          pl.mood('angry')
          pl.at(PX, 200, 0, k)
          t < 2.5 ? pl.pose(4, -4, -60 + Math.sin(t * 24) * 40, -110 + Math.cos(t * 21) * 40) : pl.pose(4, -4, -20, -30)
        }
        swear(PX - 6, 128, seg(t, 1.9, 2.0) * (1 - seg(t, 2.4, 2.5)), 0.8, Math.sin(t * 40) * 1.5)
        const sp = seg(t, 2.5, 2.62)
        sa(spit, 'opacity', sp > 0 && sp < 1 ? 1 : 0)
        if (sp > 0 && sp < 1)
          sa(
            spit,
            'transform',
            `translate(${lerp(PX + 14, hx - 4, sp).toFixed(1)} ${(lerp(175, hy + 2, sp) - Math.sin(Math.PI * sp) * 6).toFixed(1)})`,
          )
        blue(0.3 * seg(t, 2.62, 2.7) * (1 - seg(t, 2.85, 3.0)))
        // The slow wipe of his face, then the volcano: dark red, steam out of the top of his head.
        if (t > 2.95 && t < 3.3) {
          const wp = Math.sin(Math.PI * seg(t, 2.95, 3.3))
          rf.pose(3, -3, 12, lerp(10, 160, wp))
        }
        const boil = seg(t, 3.1, 3.35) * (1 - seg(t, 4.4, 4.8))
        sa(hot, 'opacity', (0.6 * boil).toFixed(2))
        sa(hot, 'cx', hx)
        sa(hot, 'cy', hy)
        steam(hx, hy - 16, boil > 0 ? ((t - 3.1) % 0.5) / 0.5 : 0)
      }
      // ---- the card: his hand in the pocket, then whipped up (KT); a red's second yellow first shows yellow.
      const pocket = t > KT - 0.45 && t < KT - 0.1 && drama !== 'spit'
      if (pocket) rf.pose(3, -3, 12, -22 + Math.sin(t * 40) * 7)
      const snap = seg(t, KT - 0.12, KT + 0.05),
        arm = snap >= 1 ? -172 + Math.sin(Math.min(1, (t - KT - 0.05) * 6) * Math.PI) * 10 : lerp(-22, -180, ease(snap))
      const shown = e.second && t < KT + 0.6 ? '#FFD400' : col
      if (t > KT - 0.12 && t < 5.8) {
        rf.pose(3, -3, red && t > KT + 0.5 ? lerp(12, 96, ease(seg(t, KT + 0.5, KT + 0.8))) : 12, arm)
        rf.card(snap > 0.3 ? shown : null)
      } else rf.card(null)
      sa(glow, 'cx', hx + 20)
      sa(glow, 'cy', hy - 30)
      sa(glow, 'opacity', 0.4 * seg(t, KT, KT + 0.3) * (1 - seg(t, 5.4, 5.8)))
      ;(red ? redT : yel)(0.3 * seg(t, KT, KT + 0.06) * (1 - seg(t, KT + 0.15, KT + 0.6)))
      shakeIt(
        svg,
        (red ? 4 : 2) * seg(t, KT, KT + 0.03) * (1 - seg(t, KT + 0.05, KT + 0.4)) + (drama === 'brawl' && t > 1.85 && t < 2.95 ? 3 : 0),
        t,
      )
      // ---- the offender after it
      if ((t > KT - 0.6 && drama !== 'swarm' && drama !== 'spit') || (drama === 'spit' && t >= KT)) {
        const off = red ? seg(t, KT + 0.6, 6.4) : 0,
          x = lerp(PX, -60, off)
        if (off > 0) {
          // Walking off, angry; he kicks the bottle on his way (5.0 s).
          const kick = seg(t, 4.95, 5.2)
          pl.face?.('side', -1)
          pl.mood('angry')
          pl.at(x, 200, 0, k)
          kick > 0 && kick < 1 ? pl.kick(kick) : pl.run(t * 9, 0.45)
          vnP(x - 4, 200 - 21 * k - 14, 1, t)
        } else if (!red) {
          // A yellow: all innocence, hands together, whistling to himself.
          pl.face?.('front')
          pl.mood('idle')
          pl.at(PX, 200, 0, k)
          pl.pose(3, -3, -24, 24)
          sa(notes, 'opacity', seg(t, KT + 0.2, KT + 0.4) * (1 - seg(t, 5.8, 6.2)))
          sa(notes, 'x', PX + 14)
          sa(notes, 'y', 200 - 21 * k - 18 - ((t * 12) % 8))
        } else {
          pl.face?.('front')
          pl.mood(t > KT ? 'angry' : 'idle')
          pl.at(PX, 200, 0, k)
          pl.pose(4, -4, 60 + Math.sin(t * 8) * 12, -60)
        }
      }
      if (drama === 'swarm' && red && t > KT + 0.6) {
        const off = seg(t, KT + 0.6, 6.4),
          x = lerp(rx - 62, -60, off),
          kick = seg(t, 4.95, 5.2)
        pl.face?.('side', -1)
        pl.mood('angry')
        pl.at(x, 204, 0, k)
        kick > 0 && kick < 1 ? pl.kick(kick) : pl.run(t * 9, 0.45)
      }
      // The bottle by the touchline: still until the kick, then away, spinning.
      if (bot) {
        const fly = ease(seg(t, 5.08, 5.9)),
          bx = lerp(150, -40, fly),
          by = 287 - Math.sin(Math.PI * Math.min(1, fly * 1.3)) * 110 * (1 - fly * 0.3)
        sa(bot, 'transform', `translate(${bx.toFixed(1)} ${by.toFixed(1)}) rotate(${Math.round(fly * 900)}) scale(1.3)`)
        kickB(150, 278, seg(t, 5.08, 5.5))
      }
      tt(seg(t, KT + 0.2, KT + 0.6))
    },
  }
}
