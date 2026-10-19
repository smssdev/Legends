// @ts-nocheck
// The broadcast director (docs/MOMENTS.md 4): turns one minute's events into a
// shot script with the real players in it (scorer, assist, keeper, the fouler,
// the taker), written in a frame where the side owning the moment attacks
// x = 105, then mirrored to the real direction. The shot kind and its length
// come from the server (tick.moment), so both screens of a live match agree.
// Pure and seeded by the match and minute: the same minute always looks the same.
// TODO(Flutter, Sprint 34): move to a server MomentChoreographer [MATCH_VIEW 4.3].

const LANE = { left: 18, center: 34, right: 50 }

function rng(seed) {
  let a = seed >>> 0
  return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296 }
}
export function lerpKeys(keys, t) {
  if (!keys || !keys.length) return null
  if (t <= keys[0][0]) return keys[0].slice(1)
  for (let i = 1; i < keys.length; i++) if (t <= keys[i][0]) { const a = keys[i - 1], b = keys[i], f = (t - a[0]) / (b[0] - a[0] || 1); return a.slice(1).map((v, j) => v + (b[j + 1] - v) * f) }
  return keys[keys.length - 1].slice(1)
}
const first = (events, type) => events.find((e) => e.type === type)

/**
 * tick: the minute from the API. ctx: { teams, seed, dirHome (1 when home attacks +x on screen) }.
 * Returns { kind, dur, A, actors, ball, cam, fx, cuts, slow, snd, cues, say, extraIn }.
 */
export function direct(tick, ctx) {
  const ev = tick.events
  const kind = tick.moment?.kind ?? 'quiet'
  const R = rng((ctx.seed || 1) * 7919 + tick.tick * 104729)
  const pick = (a, b) => a + (b - a) * R()
  const goalEv = first(ev, 'goal'), attack = first(ev, 'attack'), foul = first(ev, 'foul'), card = first(ev, 'card')
  const pen = first(ev, 'penalty'), fk = first(ev, 'free_kick'), corner = first(ev, 'corner'), sub = first(ev, 'sub'), injury = first(ev, 'injury'), stoppage = first(ev, 'stoppage')

  // The side the moment belongs to.
  let A = 'home'
  if (goalEv) A = goalEv.team
  else if (pen || fk) A = (pen || fk).team
  else if (card) A = card.team === 'home' ? 'away' : 'home'
  else if (attack) A = attack.team
  else if (corner) A = corner.team
  else if (sub || injury) A = (sub || injury).team
  const B = A === 'home' ? 'away' : 'home'

  // Who is on the pitch and where they start (server frames are home attacking +x, decimetres).
  const players = {}
  for (const side of ['home', 'away']) for (const p of ctx.teams[side]?.players ?? []) players[p.id] = { ...p, side }
  const f0 = tick.frames?.[0]?.p ?? {}
  const toA = ([x, y]) => (A === 'home' ? [x / 10, y / 10] : [105 - x / 10, 68 - y / 10])
  const base = {}
  for (const [id, pos] of Object.entries(f0)) if (players[id]) base[id] = toA(pos)
  const on = (side) => Object.keys(base).filter((id) => players[id].side === side)
  const gk = (side) => on(side).find((id) => players[id].slot_line === 'gk') ?? on(side)[0]
  const outfield = (side) => on(side).filter((id) => players[id].slot_line !== 'gk')
  const near = (side, pt, n = 1, not = []) => outfield(side).filter((id) => !not.includes(String(id))).sort((a, b) => dist(base[a], pt) - dist(base[b], pt)).slice(0, n)
  const dist = (a, b) => (a && b ? Math.hypot(a[0] - b[0], a[1] - b[1]) : 999)
  const valid = (id, side) => (id !== undefined && id !== null && base[id] && players[id].side === side ? String(id) : null)

  const s = { kind, dur: (tick.moment?.ms ?? 3000) / 1000, A, B, over: {}, poses: {}, ball: [], cam: [], fx: [], cuts: [], slow: [], snd: [], cues: [], say: [], extraIn: null }
  const mv = (id, keys) => { if (id) s.over[id] = keys }
  const ps = (id, t0, t1, pose) => { if (id) (s.poses[id] ||= []).push([t0, t1, pose]) }
  const L = LANE[attack?.lane] ?? 34
  const min = tick.minute[1] ? `${tick.minute[0]}+${tick.minute[1]}'` : `${tick.minute[0]}'`
  // English commentary (PLAN 2.21): [t, line, excited]. {A}/{B} are the clubs, {id} a player.
  // Its own random stream, so a line never changes how the shot looks.
  const RS = rng((ctx.seed || 1) * 31 + tick.tick * 977)
  const say = (t, lines, excited = 0) => { const l = Array.isArray(lines) ? lines[Math.floor(RS() * lines.length)] : lines; if (l) s.say.push([t, l, excited]) }
  const P = (id) => (id ? `{${id}}` : '')

  // ---------------------------------------------------------------- shots
  const T = {}
  // The build-up and finish shared by goal, save and miss.
  function buildUp(shooter, creator, carrier) {
    const q = attack?.quality ?? 'normal'
    const sp = q === 'big' ? [95, 34 + (L - 34) * 0.15 + pick(-2, 2)] : q === 'half' ? [89.5, L < 34 ? 25 : L > 34 ? 43 : 29] : q === 'long' ? [79.5, 34 + (L - 34) * 0.25] : q === 'header' ? [97, pick(31, 37)] : [91, 34 + (L - 34) * 0.3 + pick(-2, 2)]
    const cp = q === 'header' ? [93, L <= 34 ? 8.5 : 59.5] : [90, L]
    const start = [50, 34 + (L - 34) * 0.4]
    s.ball.push([0, ...start, 0], [0.8, 79, L, 0])
    if (q === 'long') s.ball.push([1.6, 76, sp[1] - 3, 0], [2.8, sp[0], sp[1], 0.1])
    else s.ball.push([2.3, ...cp, 0], [2.8, ...sp, q === 'header' ? 2.2 : 0.1])
    s.ball.push([3.1, sp[0] + 0.3, sp[1], q === 'header' ? 2.0 : 0.1])
    mv(carrier, [[0, start[0] - 0.6, start[1]], [0.8, start[0] + 6, start[1]], [3, 66, start[1]]]); ps(carrier, 0.62, 0.86, 'kick')
    if (creator && creator !== shooter) {
      mv(creator, [[0, 72, L], [0.8, 79, L + 0.4], [2.3, cp[0], cp[1] + 0.4], [3.6, cp[0] + 1, cp[1] + (cp[1] > 34 ? -2 : 2)]]); ps(creator, 0.75, 0.9, 'kick'); ps(creator, 2.6, 2.85, 'kick')
    }
    mv(shooter, [[0, 83, 34 + (L - 34) * 0.2], [2.8, sp[0] - 0.4, sp[1]], [3.1, sp[0], sp[1]], [3.6, sp[0] + 1, sp[1]]])
    ps(shooter, q === 'header' ? 2.7 : 2.98, q === 'header' ? 3.15 : 3.22, q === 'header' ? 'jump' : 'kick')
    const def = valid(attack?.defender, B) ?? near(B, sp, 1)[0]
    mv(def, [[0, 89, sp[1] - 4], [2.9, sp[0] - 1.6, sp[1] + 1.8], [3.6, sp[0] - 0.6, sp[1] + 1.4]])
    s.cam.push([0, 52, 33, 12], [1.5, 74, (L + 68) / 3, 14], [2.6, 89, (L + 34) / 2, 18], [3.25, 98, 34, 24])
    s.snd.push([0.05, 'kick'], [0.8, 'kick'], [2.8, 'kick'], [3.1, 'kick'])
    return { sp, def }
  }
  function roles() {
    const shooter = valid(goalEv?.scorer ?? attack?.shooter, A) ?? near(A, [92, 34], 1)[0]
    const creator = valid(goalEv?.assist ?? attack?.creator ?? attack?.receiver, A) ?? near(A, [80, L], 1, [shooter])[0]
    const carrier = valid(attack?.carrier, A) ?? near(A, [50, 34], 1, [shooter, creator])[0]
    return { shooter, creator, carrier: carrier === creator || carrier === shooter ? null : carrier }
  }

  T.goal = () => {
    const { shooter, creator, carrier } = roles(), k = gk(B)
    const { sp, def } = buildUp(shooter, creator, carrier)
    const gy = pick(31, 37), gz = attack?.quality === 'header' ? pick(0.6, 1.8) : pick(0.2, 1.7), flagY = gy > 34 ? 64.5 : 3.5
    s.ball.push([3.5, 105, gy, gz], [3.7, 106.3, gy, gz * 0.5], [4.2, 106.3, gy, 0.11])
    mv(k, [[0, 101, 34], [3.0, 102.4, 34], [3.4, 103.3, gy]]); ps(k, 3.2, 4.3, 'dive'); ps(k, 4.3, 99, 'down')
    mv(shooter, [[0, 83, 34 + (L - 34) * 0.2], [2.8, sp[0] - 0.4, sp[1]], [3.1, sp[0], sp[1]], [3.7, sp[0] + 1.2, sp[1]], [6.2, 103.2, flagY], [99, 103.3, flagY]])
    ps(shooter, 3.7, 6.2, 'run-arms'); ps(shooter, 6.2, 99, 'celebrate')
    const mates = [creator !== shooter ? creator : null, ...near(A, sp, 2, [shooter, creator])].filter(Boolean)
    mates.forEach((id, i) => { const b = base[id] ?? [80, 34]; mv(id, [[0, ...(s.over[id]?.[0]?.slice(1) ?? b)], [3.6, ...(s.over[id] ? lerpKeys(s.over[id], 3.6) : b)], [6.6 + i * 0.2, 101.5 - i * 1.2, flagY + (flagY > 34 ? -2 - i : 2 + i)], [99, 101.5 - i * 1.2, flagY + (flagY > 34 ? -2 - i : 2 + i)]]); ps(id, 6.6, 99, 'celebrate') })
    ps(def, 3.7, 99, 'head')
    s.cam.push([3.9, 101, 34, 25], [5.0, 99, flagY > 34 ? 48 : 20, 18], [6.5, 100, flagY > 34 ? 58 : 10, 20])
    s.slow.push([2.85, 3.75, 0.33]); s.cues.push([3.5, 'goal'])
    s.fx.push({ t0: 3.5, t1: 4.8, type: 'ripple', x: 105 }, { t0: 3.6, t1: 5.1, type: 'center', text: 'هدف!', team: 'A' }, { t0: 4.8, t1: 8.2, type: 'banner', title: shooter, sub: creator && creator !== shooter ? ['صناعة', creator, min] : [min], team: 'A', goal: true })
    s.cuts.push({ t0: 6.8, t1: 8.0, type: 'crowd', team: 'A', mood: 'jump' }, { t0: 8.0, t1: 9.0, type: 'coach', team: 'A', mood: 'celebrate' }, { t0: 9.0, t1: 9.8, type: 'coach', team: 'B', mood: 'head' }, { t0: 9.8, t1: 12.8, type: 'replay', from: 2.4, to: 3.8 })
    s.snd.push([3.5, 'net'], [3.5, 'roar'])
    say(0.3, carrier ? [`{A} on the move. ${P(carrier)} carries it forward.`, `${P(carrier)} drives {A} up the pitch.`] : '{A} on the move.')
    if (creator && creator !== shooter) say(1.7, [`${P(creator)}, looking for a way through...`, `Now ${P(creator)}, into a dangerous area...`])
    say(2.7, [`Here's ${P(shooter)}!`, `${P(shooter)}!`])
    say(3.5, attack?.quality === 'header' ? [`GOAL! ${P(shooter)} with the header! Oh, what a goal!`, `GOAL! A thumping header from ${P(shooter)}!`] : [`GOAL! ${P(shooter)}! Oh, that is magnificent!`, `GOAL! ${P(shooter)} buries it! What a finish!`, `It's in! ${P(shooter)}! The keeper had no chance!`], 1)
    say(5.1, creator && creator !== shooter ? `What a ball from ${P(creator)}, and what a finish from ${P(shooter)}!` : [`${P(shooter)} with a moment of real quality! The fans are on their feet!`], 1)
    say(8.0, ['Look at the bench. They are loving it.', 'The manager is punching the air!'])
    say(9.9, ["Let's see it again. Perfect timing, and a calm, calm finish.", "One more look. Just superb."])
    return 12.8
  }
  T.save = () => {
    const { shooter, creator, carrier } = roles(), k = gk(B)
    buildUp(shooter, creator, carrier)
    const gy = pick(31.5, 36.5), gz = pick(0.4, 1.8), out = gy < 34 ? 22 : 46
    s.ball.push([3.45, 103.7, gy, gz], [3.9, 101, out, 2.4], [4.4, 103, out < 34 ? 12 : 56, 0.11])
    mv(k, [[0, 101, 34], [3.0, 102, 34], [3.45, 103.5, gy]]); ps(k, 3.12, 4.2, 'dive'); ps(k, 4.2, 99, 'down')
    ps(shooter, 3.8, 99, 'head')
    s.cam.push([3.6, 101, 33, 26], [4.4, 100, 30, 22])
    s.slow.push([2.85, 3.7, 0.3])
    s.fx.push({ t0: 2.2, t1: 3.0, type: 'tag', text: attack?.quality === 'big' ? 'فرصة محققة!' : 'تسديدة!', team: 'A' }, { t0: 3.7, t1: 5.4, type: 'banner', title: 'تصدٍّ رائع', sub: attack?.result === 'corner' ? [k, '· ركنية'] : [k], team: 'B' })
    s.cuts.push({ t0: 5.4, t1: 6.4, type: 'crowd', team: 'B', mood: 'jump' })
    s.snd.push([3.45, 'kick'], [3.5, 'groan'])
    say(0.4, attack?.quality === 'big' ? [`{A} break through! ${P(shooter)} is clean through on goal!`] : ['{A} moving forward with purpose...', '{A} probing on the edge of the box...'])
    say(2.75, [`${P(shooter)} shoots...`, `${P(shooter)} lets fly...`])
    say(3.5, [`Saved! What a stop from ${P(k)}!`, `Oh, brilliant from ${P(k)}! He keeps it out!`], 1)
    say(4.8, attack?.result === 'corner' ? 'Tipped behind for a corner.' : ['That is top class goalkeeping.', "He'll be very pleased with that one."])
    return 6.4
  }
  T.miss = () => {
    const { shooter, creator, carrier } = roles()
    const { sp, def } = buildUp(shooter, creator, carrier)
    const blocked = attack?.result === 'blocked'
    if (blocked) {
      mv(def, [[0, 89, sp[1] - 4], [2.95, sp[0] + 1.6, sp[1] + 0.6], [3.6, sp[0] + 2, sp[1] + 0.6]]); ps(def, 2.95, 3.6, 'slide')
      s.ball.push([3.3, sp[0] + 2.6, sp[1] + 3, 0.6], [3.9, sp[0] + 5, sp[1] + 9, 0.11])
    } else {
      const wide = R() < 0.5
      s.ball.push([3.5, 105, wide ? (L < 34 ? 28.4 : 39.8) : pick(31, 37), wide ? pick(0.3, 1.5) : 2.9], [3.9, 109, wide ? (L < 34 ? 26 : 42) : 34, 1.2])
    }
    ps(shooter, 3.6, 99, 'head')
    s.cam.push([3.6, 99, 34, 23], [4.6, 97, 36, 22])
    s.slow.push([2.9, 3.5, 0.45])
    s.fx.push({ t0: 0.3, t1: 2.4, type: 'tag', text: 'هجمة خطيرة', team: 'A' }, { t0: 3.9, t1: 5.6, type: 'banner', title: blocked ? 'تسديدة محجوبة' : 'فرصة ضائعة', sub: ['تسديدة', shooter], team: 'A' })
    s.cuts.push({ t0: 5.6, t1: 7.0, type: 'coach', team: 'A', mood: 'head' })
    s.snd.push([3.5, 'groan'])
    say(0.3, ['Dangerous from {A} here...', '{A} on the attack...'])
    say(2.75, [`${P(shooter)} shoots...`, `${P(shooter)} goes for goal...`])
    say(3.5, blocked ? [`Blocked! Brave defending from ${P(def)}!`, `Charged down by ${P(def)}!`] : ["Wide! What a chance that was!", "Oh, he's put it over the bar! He should have scored!", 'Just past the post! So close!'], 1)
    say(5.6, ["The manager can't believe it.", 'He holds his head in his hands.'])
    return 7
  }
  T.offside = () => {
    const passer = valid(attack?.carrier, A) ?? near(A, [46, 40], 1)[0]
    const runner = valid(attack?.receiver ?? attack?.shooter, A) ?? near(A, [86, 32], 1, [passer])[0]
    s.ball = [[0, 46, 40, 0], [0.4, 46, 40, 0], [1.05, 68, 35, 7], [1.7, 89, 30, 0], [2.1, 91, 30, 0]]
    mv(passer, [[0, 45.5, 40.5], [0.5, 46, 40.5]]); ps(passer, 0.3, 0.5, 'kick')
    mv(runner, [[0, 84.6, 32], [0.4, 85.2, 31.8], [1.7, 89, 30.5], [2.3, 90, 30.4]]); ps(runner, 2.4, 99, 'argue')
    near(B, [84, 34], 4).forEach((id, i) => mv(id, [[0, 84, 14 + i * 13.5], [1.7, 86, 14.5 + i * 13.5]]))
    mv('lin', [[0, 84, 69.6], [1.7, 86.5, 69.6]]); ps('lin', 1.8, 99, 'flag')
    mv('ref', [[0, 68, 40], [2.4, 74, 40]])
    s.cam = [[0, 50, 40, 11], [1.0, 70, 36, 13], [1.8, 85, 40, 16], [2.3, 85, 46, 16]]
    s.fx.push({ t0: 2.0, t1: 2.5, type: 'whistle' }, { t0: 4.8, t1: 6.3, type: 'banner', title: 'تسلل', sub: [runner, 'متقدم بخطوة لحظة التمرير'], team: 'A' })
    s.cuts.push({ t0: 2.5, t1: 4.8, type: 'freeze', at: 0.4, lines: [[84, '#2F6FDB', 'آخر مدافع'], [85.2, '#EF4444', 'المهاجم']], label: 'تسلل', cam: [80, 34, 14] })
    s.snd.push([0.4, 'kick'], [2.0, 'whistle'])
    say(0.4, [`Ball over the top for ${P(runner)}...`, `${P(passer)} picks out ${P(runner)}...`])
    say(2.0, ['But the flag is up. Offside.', 'No! The linesman says offside.'])
    say(2.9, "Let's freeze it. Yes, he went a step too early.")
    return 6.4
  }
  T.card = (red) => {
    const fouler = valid(card?.player ?? foul?.player, B) ?? near(B, [72, 50], 1)[0]
    const victim = valid(foul?.victim, A) ?? near(A, [70, 52], 1)[0]
    if (red) {
      s.ball = [[0, 72, 36.5, 0], [1.4, 83.5, 38.5, 0], [1.7, 85, 40, 0], [2.2, 86, 41, 0]]
      mv(victim, [[0, 72, 36], [1.4, 83, 38]]); ps(victim, 1.45, 4.5, 'fall')
      mv(fouler, [[0, 76, 39], [1.35, 82.6, 38.2], [5.0, 82.6, 38.4], [8.8, 70, 67.6]]); ps(fouler, 1.15, 1.9, 'slide'); ps(fouler, 5.0, 99, 'walk')
      mv('ref', [[0, 66, 42], [1.6, 70, 41], [2.8, 80, 40]])
      s.cam = [[0, 72, 38, 15], [1.5, 83, 39, 20], [2.8, 80, 40, 19], [5, 80, 45, 15], [8.6, 72, 58, 15]]
      s.cues.push([3.0, 'red'])
    } else {
      s.ball = [[0, 62, 54.5, 0], [1.3, 71, 52.5, 0], [1.5, 72.5, 51, 0], [2, 74, 50, 0]]
      mv(victim, [[0, 62, 54], [1.3, 71, 52]]); ps(victim, 1.35, 3.4, 'fall')
      mv(fouler, [[0, 74, 47], [1.25, 71.6, 51], [3, 72, 50]]); ps(fouler, 1.1, 1.8, 'slide')
      mv('ref', [[0, 62, 40], [1.5, 64, 44], [2.9, 70, 48.5]])
      s.cam = [[0, 62, 52, 15], [1.4, 70, 51, 20], [2.8, 70, 49, 19]]
    }
    s.fx.push({ t0: 1.55, t1: 2.2, type: 'whistle' }, { t0: 5.0, t1: 6.7, type: 'banner', title: red ? 'بطاقة حمراء' : 'بطاقة صفراء', sub: red ? [fouler, '· فريقه يكمل بعشرة'] : [fouler], team: 'B', card: red ? 'red' : 'yellow' })
    s.cuts.push({ t0: 3.0, t1: 5.0, type: 'refcard', color: red ? 'red' : 'yellow', who: fouler, team: 'B' })
    if (red) s.cuts.push({ t0: 6.7, t1: 7.6, type: 'coach', team: 'B', mood: 'argue' })
    s.snd.push([0.05, 'kick'], [1.3, 'thud'], [1.55, 'whistle'], [3.1, 'whistle'], [3.15, red ? 'groan' : 'murmur'])
    if (red) {
      say(0.3, [`${P(victim)} is clean through...`, `${P(victim)} breaks away...`])
      say(1.5, "And he's been brought down from behind!", 1)
      say(3.1, [`It's red! ${P(fouler)} is sent off! {B} are down to ten men!`, `Straight red for ${P(fouler)}! {B} will have to play with ten!`], 1)
      say(5.4, 'A long walk back to the dressing room.')
    } else {
      say(0.3, [`${P(victim)} running at the defence...`, `${P(victim)} on the ball...`])
      say(1.35, [`Ooh, a late challenge from ${P(fouler)}!`, `${P(fouler)} goes in hard!`])
      say(3.1, [`The referee reaches for his pocket. Yellow card for ${P(fouler)}.`, `That's a booking for ${P(fouler)}.`])
    }
    return red ? 9 : 6.8
  }
  T.yellow = () => T.card(false)
  T.red = () => T.card(true)
  T.free_kick = () => {
    const goal = !!goalEv
    const taker = valid(fk?.taker, A) ?? near(A, [76, 38], 1)[0], k = gk(B)
    const victim = valid(foul?.victim, A) ?? near(A, [79, 36], 1, [taker])[0], fouler = valid(foul?.player, B) ?? near(B, [80, 35], 1)[0]
    const wall = near(B, [89, 34], 3, [fouler])
    s.ball = [[0, 72, 36.5, 0], [1.0, 79, 36.4, 0], [1.4, 80, 36, 0], [4.45, 80, 36, 0]]
    mv(victim, [[0, 72, 36], [1.0, 79, 36], [2.2, 79.4, 36.4], [3.2, 94, 30]]); ps(victim, 1.0, 2.3, 'fall')
    mv(fouler, [[0, 82, 34], [1.0, 79.6, 35.5], [2.2, 80.4, 35], [3.2, 89.2, 34.2]]); ps(fouler, 0.85, 1.4, 'slide')
    wall.forEach((id, i) => mv(id, [[0, 84, 39 + i], [2.2, 86, 36 + i], [3.2, 89.2, 33.2 + [0, 2, 3][i]]]))
    mv(k, [[0, 101, 34], [3.2, 103, 34.8], [5.0, 103, 34.6], [5.35, 103.6, goal ? 33 : 32]]); ps(k, 5.02, 6.2, 'dive'); ps(k, 6.2, 99, 'down')
    mv('ref', [[0, 70, 42], [1.4, 75, 41], [3.2, 86, 44]])
    if (goal) {
      mv(taker, [[0, 64, 30], [3.2, 76.4, 38.8], [4.0, 76.4, 38.8], [4.45, 79.4, 36.6], [5.6, 82, 37], [7.4, 90, 52]]); ps(taker, 4.38, 4.6, 'kick'); ps(taker, 5.8, 99, 'celebrate')
      s.ball.push([4.5, 80, 36, 0.1], [4.9, 89.2, 34.6, 2.7], [5.35, 105, 31.2, 1.9], [5.6, 106.4, 31, 1], [6, 106.4, 31, 0.11])
      s.cues.push([5.35, 'goal'])
      s.fx.push({ t0: 5.35, t1: 6.4, type: 'ripple', x: 105 }, { t0: 5.5, t1: 6.8, type: 'center', text: 'هدف!', team: 'A' }, { t0: 6.6, t1: 8.4, type: 'banner', title: taker, sub: ['ضربة حرة مباشرة ·', min], team: 'A', goal: true })
      s.cuts.push({ t0: 8.4, t1: 9.4, type: 'crowd', team: 'A', mood: 'jump' }); s.snd.push([5.35, 'net'], [5.35, 'roar'])
    } else {
      mv(taker, [[0, 64, 30], [3.2, 76.4, 38.8], [4.0, 76.4, 38.8], [4.45, 79.4, 36.6], [5, 80.5, 36]]); ps(taker, 4.38, 4.6, 'kick'); ps(taker, 6, 99, 'head')
      s.ball.push([4.5, 80, 36, 0.1], [4.9, 89.2, 34.6, 2.7], [5.3, 103.6, 31.8, 1.9], [5.75, 100, 41, 0.4], [6.2, 97, 45, 0.11])
      s.fx.push({ t0: 5.9, t1: 7.6, type: 'banner', title: fk?.scored === false && fk?.keeper ? 'تصدٍّ رائع' : 'ضربة حرة ضائعة', sub: [k], team: 'B' })
      s.cuts.push({ t0: 7.6, t1: 8.6, type: 'coach', team: 'A', mood: 'head' }); s.snd.push([5.3, 'kick'], [5.35, 'groan'])
    }
    s.slow.push([4.55, 5.6, 0.4])
    s.cam = [[0, 72, 37, 15], [1.3, 79, 37, 19], [2.2, 79, 37, 19], [3.2, 86, 35, 16], [4.3, 86, 35, 16], [5.4, 98, 34, 20], [6.4, 99, 36, 19]]
    s.fx.push({ t0: 1.2, t1: 1.8, type: 'whistle' }, { t0: 3.3, t1: 4.4, type: 'tag', text: 'ضربة حرة مباشرة', team: 'A' }, { t0: 4.0, t1: 4.4, type: 'whistle' })
    s.cuts.push({ t0: 2.2, t1: 3.2, type: 'crowd', team: 'A', mood: 'quiet' })
    s.snd.push([0.05, 'kick'], [1.0, 'thud'], [1.2, 'whistle'], [4.0, 'whistle'], [4.45, 'kick'])
    say(0.3, `${P(victim)} drives forward, and he's taken down!`)
    say(2.3, ['Free kick, right on the edge of the box.', 'A great chance from the free kick here.'])
    say(3.4, [`${P(taker)} stands over it...`, `${P(taker)} fancies this one...`])
    say(5.35, goal ? [`Over the wall, and IN! A stunning free kick from ${P(taker)}!`, `GOAL! ${P(taker)} curls it into the top corner!`] : fk?.scored === false && fk?.keeper ? `Over the wall, but ${P(k)} gets across! Great save!` : 'Over the wall... and just wide!', 1)
    return goal ? 9.4 : 8.6
  }
  T.penalty = () => {
    const goal = !!goalEv
    const taker = valid(pen?.taker, A) ?? near(A, [90, 35], 1)[0], k = gk(B)
    const victim = valid(foul?.victim, A) ?? near(A, [93, 45], 1, [taker])[0], fouler = valid(foul?.player, B) ?? near(B, [92, 46], 1)[0]
    s.ball = [[0, 86, 50.5, 0], [1.1, 93.2, 45.3, 0], [1.5, 94, 44, 0], [3.0, 94, 44, 0], [4.0, 94, 34, 0], [6.2, 94, 34, 0]]
    mv(victim, [[0, 86, 50], [1.1, 93, 45], [3.0, 93, 45.4], [4.0, 88, 44]]); ps(victim, 1.1, 2.6, 'fall')
    mv(fouler, [[0, 92, 52], [1.05, 92.7, 45.8], [3.0, 92, 47], [4.0, 87.5, 41]]); ps(fouler, 0.9, 1.5, 'slide'); ps(fouler, 2.0, 3.0, 'argue')
    mv('ref', [[0, 80, 40], [1.6, 85, 42], [3, 86, 41], [4, 88, 46]]); ps('ref', 1.9, 3.0, 'point')
    ;[...near(A, [87, 34], 2, [taker, victim]).map((id, i) => [id, 87, i ? 40 : 28]), ...near(B, [87, 34], 3, [fouler]).map((id, i) => [id, 87.5, 31 + i * 3])].forEach(([id, x, y]) => mv(id, [[0, x - 8, y], [3.0, x - 4, y], [4.0, x, y]]))
    const tk = [[0, 84, 34], [3.0, 88, 38], [4.0, 90.3, 35.6], [5.6, 90.3, 35.6], [6.2, 93.6, 34.4], [6.8, 96, 34]]
    if (goal) {
      mv(k, [[0, 101, 34], [4.0, 104.6, 34], [6.2, 104.6, 34], [6.5, 104.4, 37.6]]); ps(k, 6.25, 7.4, 'dive'); ps(k, 7.4, 99, 'down')
      s.ball.push([6.2, 94, 34, 0.1], [6.55, 105, 31.4, 0.7], [6.8, 106.4, 31.3, 0.4], [7.1, 106.4, 31.3, 0.11])
      mv(taker, [...tk, [8.6, 101, 58]]); ps(taker, 6.9, 99, 'celebrate')
      s.cues.push([6.55, 'goal'])
      s.fx.push({ t0: 6.55, t1: 7.6, type: 'ripple', x: 105 }, { t0: 6.7, t1: 8.0, type: 'center', text: 'هدف!', team: 'A' }, { t0: 7.8, t1: 9.5, type: 'banner', title: taker, sub: ['ركلة جزاء ·', min], team: 'A', goal: true })
      s.cuts.push({ t0: 9.5, t1: 10.6, type: 'coach', team: 'A', mood: 'celebrate' }); s.snd.push([6.55, 'net'], [6.55, 'roar'])
    } else {
      mv(k, [[0, 101, 34], [4.0, 104.6, 34], [6.2, 104.6, 34], [6.5, 104.4, 31.6], [7.6, 104, 32]]); ps(k, 6.25, 7.2, 'dive'); ps(k, 7.6, 99, 'celebrate')
      s.ball.push([6.2, 94, 34, 0.1], [6.5, 104.2, 31.7, 0.6], [6.9, 100, 24, 0.2], [7.3, 98, 19, 0.11])
      mv(taker, tk); ps(taker, 6.9, 99, 'head')
      s.fx.push({ t0: 7.0, t1: 8.8, type: 'banner', title: 'تصدّى لركلة الجزاء', sub: [k], team: 'B' })
      s.cuts.push({ t0: 8.8, t1: 10, type: 'crowd', team: 'B', mood: 'jump' }); s.snd.push([6.5, 'kick'], [6.55, 'roar'])
    }
    ps(taker, 6.12, 6.35, 'kick')
    s.slow.push([6.05, 6.85, 0.35])
    s.cam = [[0, 86, 46, 15], [1.2, 92, 45, 20], [3.0, 90, 42, 20], [4.0, 98, 34, 30], [6.0, 98, 34, 30], [6.6, 101, 34, 32], [8, 100, 44, 22]]
    s.fx.push({ t0: 1.6, t1: 2.4, type: 'whistle' }, { t0: 2.0, t1: 3.0, type: 'center', text: 'ركلة جزاء!', team: 'A', small: true }, { t0: 5.6, t1: 6.0, type: 'whistle' })
    s.cuts.push({ t0: 3.0, t1: 4.0, type: 'crowd', team: 'B', mood: 'quiet' })
    s.snd.push([0.05, 'kick'], [1.1, 'thud'], [1.6, 'whistle-long'], [3.0, 'hush'], [5.6, 'whistle'], [6.2, 'kick'])
    say(0.4, `${P(victim)} into the area...`)
    say(1.15, 'Down he goes!')
    say(1.9, 'And the referee points to the spot! Penalty!', 1)
    say(4.2, [`${P(taker)} to take it. The stadium goes quiet...`, `${P(taker)} steps up. Big moment.`])
    say(5.9, 'Here it comes...')
    say(goal ? 6.6 : 6.55, goal ? [`GOAL! ${P(taker)} sends the keeper the wrong way!`, `GOAL! Cool as you like from ${P(taker)}!`] : [`Saved! ${P(k)} guesses right! What a moment!`, `${P(k)} saves it! Incredible!`], 1)
    return goal ? 10.6 : 10
  }
  T.corner = () => {
    const taker = valid(corner?.taker, A) ?? near(A, [100, 2], 1)[0], top = R() < 0.5
    const cy = top ? 0.6 : 67.4, header = valid(attack?.shooter, A) ?? outfield(A).find((id) => players[id].slot_line === 'def') ?? near(A, [97, 35], 1, [taker])[0]
    const k = gk(B), won = corner?.won !== false
    s.ball = [[0, 104.6, cy, 0], [1.0, 104.6, cy, 0], [1.35, 101, top ? 18 : 50, 6.5], [1.75, 98.6, 35.6, 2.3]]
    mv(taker, [[0, 102.6, top ? -1.2 : 69.2], [0.9, 104.2, top ? 0.1 : 67.9], [1.4, 104.4, top ? 1.2 : 66.8]]); ps(taker, 0.85, 1.1, 'kick')
    mv(header, [[0, 95, 41], [1.6, 98.5, 35.6], [2.4, 99, 35]]); ps(header, 1.5, 1.95, 'jump')
    near(A, [96, 34], 3, [taker, header]).forEach((id, i) => mv(id, [[0, 94 + i, 30 + i * 4], [1.6, 96 + i, 31 + i * 4]]))
    near(B, [98, 34], 4).forEach((id, i) => mv(id, [[0, 97 + (i % 2) * 2, 31 + i * 3], [1.6, 98 + (i % 2), 31.5 + i * 3]]))
    mv(k, [[0, 103.5, 34.5], [1.6, 103.4, 34]])
    if (won) { s.ball.push([2.2, 105, 33, 3.2], [2.6, 108, 32, 1]); ps(header, 2.4, 99, 'head') }
    else { s.ball.push([2.1, 103.2, 34, 2.2], [2.6, 103.4, 34, 1.2]); ps(k, 1.75, 2.3, 'jump') }
    s.cam = [[0, 98, top ? 18 : 50, 16], [1.0, 100, top ? 22 : 46, 17], [1.7, 99, 33, 21], [2.4, 100, 33, 21]]
    s.fx.push({ t0: 0, t1: 1.0, type: 'tag', text: 'ركنية', team: 'A' }, { t0: 2.6, t1: 4.5, type: 'banner', title: won ? 'رأسية فوق العارضة' : 'الحارس يمسك العرضية', sub: [won ? header : k], team: won ? 'A' : 'B' })
    s.cuts.push({ t0: 4.5, t1: 5.6, type: 'coach', team: 'A', mood: 'shout' })
    s.snd.push([1.0, 'kick'], [1.75, 'kick'], [2.1, won ? 'groan' : 'murmur'])
    say(0.1, ['Corner for {A}. Bodies in the box.', 'A corner to {A}.'])
    say(0.9, `${P(taker)} swings it in...`)
    if (won) { say(1.65, `${P(header)} rises highest...`); say(2.25, ['Just over the bar!', 'Over! Inches away!'], 1) }
    else say(2.1, `Comfortable for ${P(k)}. He claims it.`)
    return 5.6
  }
  T.sub = () => {
    const out = valid(sub?.out, A) ?? outfield(A)[0], inId = String(sub?.in ?? '')
    const ob = base[out] ?? [52, 60]
    s.ball = [[0, 52, 30, 0]]
    mv(out, [[0, ...ob], [2.6, 52, 66], [5.6, 52, 69.4]]); ps(out, 0, 99, 'walk')
    if (inId && players[inId]) { s.extraIn = { id: inId, side: A }; mv(inId, [[0, 51, 70.8], [2.6, 51, 70.8], [5.6, 58, 60]]) }
    s.cam = [[0, 52, 54, 16], [5.6, 54, 58, 17]]
    s.cuts.push({ t0: 0, t1: 2.6, type: 'board', team: 'A', out: players[out]?.no, in: players[inId]?.no })
    s.fx.push({ t0: 2.8, t1: 5.4, type: 'banner', title: 'تبديل', sub: [inId, 'بدلاً من', out], team: 'A' })
    s.snd.push([0.1, 'beep'])
    say(0.3, 'A change for {A}.')
    say(2.9, inId && players[inId] ? `${P(inId)} comes on, replacing ${P(out)}.` : `${P(out)} makes way.`)
    return 5.6
  }
  T.injury = () => {
    const who = valid(injury?.player, A) ?? outfield(A)[0], b = base[who] ?? [60, 40]
    s.ball = [[0, b[0] - 3, b[1], 0], [0.6, b[0], b[1], 0], [1.2, b[0] + 4, b[1] + 3, 0]]
    mv(who, [[0, b[0] - 4, b[1]], [0.6, b[0], b[1]]]); ps(who, 0.6, 99, 'fall')
    mv('ref', [[0, b[0] - 10, b[1] - 6], [2.4, b[0] - 2, b[1] - 2]])
    s.cam = [[0, b[0] - 3, b[1], 15], [2, b[0], b[1], 21]]
    s.fx.push({ t0: 0.9, t1: 1.4, type: 'whistle' }, { t0: 1.6, t1: 4.0, type: 'banner', title: 'إصابة', sub: [who], team: 'A' })
    const sb = ev.find((e) => e.type === 'sub' && e.team === A)
    if (sb) s.cuts.push({ t0: 4.0, t1: 6.0, type: 'board', team: 'A', out: players[sb.out]?.no, in: players[sb.in]?.no })
    else s.cuts.push({ t0: 4.0, t1: 6.0, type: 'coach', team: 'A', mood: 'head' })
    s.snd.push([0.6, 'thud'], [0.9, 'whistle'])
    say(1.0, `${P(who)} is down, and he looks in some discomfort.`)
    say(3.6, sb ? `He can't carry on. ${P(sb.in)} will replace him.` : 'The medical team are on.')
    return 6
  }
  T.stoppage = () => { s.ball = [[0, 52, 34, 0]]; s.cam = [[0, 52, 50, 14]]; s.cuts.push({ t0: 0, t1: 2.4, type: 'board', team: 'A', plus: stoppage?.added ?? 3 }); s.snd.push([0.1, 'beep']); say(0.2, (stoppage?.added ?? 3) === 1 ? 'One minute of added time.' : `${stoppage?.added ?? 3} minutes of added time.`); return 2.4 }
  // Minor attacks, quiet minutes and the shootout run on the mini-map, from the server frames.
  const mini = (label) => { s.ball = [[0, 52.5, 34, 0]]; s.cam = [[0, 52.5, 34, 9]]; s.cuts.push({ t0: 0, t1: 99, type: 'minimap', label }); return s.dur }
  const ATTACK_LINES = { lost: ['{A} try to build, but {B} win it back.', 'Good pressing from {B}. They take it away.'], cleared: ['{A} press forward, but the {B} defence clears.', 'Cleared! {B} deal with it.'], foul: ['Foul on the {A} attack.', 'The referee stops play. Free kick to {A}.'] }
  T.attack = () => {
    if (attack) say(0.2, ATTACK_LINES[attack.result] ?? '{A} on the attack.')
    return mini(attack ? { text: attack.result === 'foul' ? 'خطأ على ' : 'هجمة ', team: 'A', end: { lost: 'ضاعت الكرة', cleared: 'أبعدها الدفاع', foul: '', penalty: '' }[attack.result] ?? '' } : null)
  }
  T.quiet = () => {
    if (RS() < 0.4) say(0.3, ['Patient build up from {A}.', '{B} sitting deep, waiting for a mistake.', 'Nice and calm on the ball from {A}.', '{B} keeping their shape well.'])
    return mini(null)
  }
  T.shootout = () => { say(0.2, 'Penalties. Nerves of steel needed now.'); return mini({ text: 'ركلات الترجيح', team: 'A', end: '' }) }

  const nominal = (T[kind] ?? T.quiet)()
  // Fit the shot to the server's length for this minute.
  const k = s.dur / nominal
  if (Math.abs(k - 1) > 0.01 && !s.cuts.some((c) => c.type === 'minimap')) {
    const sc = (t) => t * k
    for (const id in s.over) s.over[id] = s.over[id].map(([t, ...r]) => [sc(t), ...r])
    for (const id in s.poses) s.poses[id] = s.poses[id].map(([a, b, p]) => [sc(a), sc(b), p])
    s.ball = s.ball.map(([t, ...r]) => [sc(t), ...r]); s.cam = s.cam.map(([t, ...r]) => [sc(t), ...r])
    s.fx.forEach((f) => { f.t0 = sc(f.t0); f.t1 = sc(f.t1) }); s.cuts.forEach((c) => { c.t0 = sc(c.t0); c.t1 = sc(c.t1); if (c.from !== undefined) { c.from = sc(c.from); c.to = sc(c.to) } if (c.at !== undefined) c.at = sc(c.at) })
    s.slow = s.slow.map(([a, b, r]) => [sc(a), sc(b), r]); s.snd = s.snd.map(([t, n]) => [sc(t), n]); s.cues = s.cues.map(([t, n]) => [sc(t), n]); s.say = s.say.map(([t, l, e]) => [sc(t), l, e])
  }

  const period = first(ev, 'period')
  if (tick.minute[0] === 1 && !tick.minute[1] && !s.say.some((l) => l[0] < 1.5)) s.say.unshift([0.1, "And we're under way!", 0])
  if (period) s.say.push([Math.max(0, s.dur - 1.2), { halftime: 'The referee blows for half time.', fulltime: "And that's full time!", extra_time: "We're going to extra time!", penalties: "It's going to penalties!" }[period.name] ?? '', 1])
  s.say = s.say.filter((l) => l[1])

  // ---------------------------------------------------------------- actors: scripted ones plus everybody drifting with the ball
  const ballAt = (t) => lerpKeys(s.ball, t) ?? [52.5, 34, 0]
  const actors = []
  const add = (id, side, keys, b) => {
    if (!keys) {
      keys = []
      const g = players[id]?.slot_line === 'gk'
      for (let t = 0; t <= s.dur + 0.01; t += 0.5) { const [bx, by] = ballAt(t); keys.push([t, b[0] + (bx - 60) * (g ? 0.06 : 0.3) + Math.sin(t * 1.2 + +id) * 0.5, b[1] + (by - 34) * (g ? 0.22 : 0.18) + Math.cos(t + +id * 2) * 0.5]) }
    }
    actors.push({ id: String(id), side, keys, poses: s.poses[id] || [] })
  }
  for (const id of Object.keys(base)) add(id, players[id].side, s.over[id], base[id])
  if (s.extraIn) add(s.extraIn.id, s.extraIn.side, s.over[s.extraIn.id], [51, 70.8])
  add('ref', 'ref', s.over.ref, [66, 40])
  add('lin', 'lin', s.over.lin, [70, 69.6])
  if (!s.over.lin) { const ln = actors[actors.length - 1]; ln.keys = ln.keys.map(([t, x]) => [t, Math.max(52, Math.min(100, x)), 69.6]) }

  // Real direction on screen: the owning side attacks +x when D = 1.
  const D = (A === 'home' ? 1 : -1) * (ctx.dirHome || 1)
  if (D < 0) {
    const mx = (x) => 105 - x, my = (y) => 68 - y
    actors.forEach((a) => { a.keys = a.keys.map(([t, x, y]) => [t, mx(x), a.side === 'lin' ? y : my(y)]) })
    s.ball = s.ball.map(([t, x, y, z]) => [t, mx(x), my(y), z]); s.cam = s.cam.map(([t, x, y, z]) => [t, mx(x), my(y), z])
    s.fx.forEach((f) => { if (f.x !== undefined) f.x = mx(f.x) })
    s.cuts.forEach((c) => { if (c.cam) c.cam = [mx(c.cam[0]), my(c.cam[1]), c.cam[2]]; if (c.lines) c.lines = c.lines.map(([x, col, l]) => [mx(x), col, l]) })
  }
  actors.forEach((a) => { a.dist = []; let d = 0, prev = lerpKeys(a.keys, 0); for (let t = 0; t <= s.dur + 0.05; t += 0.05) { const p = lerpKeys(a.keys, t); d += Math.hypot(p[0] - prev[0], p[1] - prev[1]); a.dist.push(d); prev = p } })
  return { ...s, D, actors, sideOf: (team) => (team === 'A' ? A : B), players }
}
