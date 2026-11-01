// @ts-nocheck
// What one minute becomes on the match feed (docs/MATCH_VIEW.md 4.6): the scene
// to play and who is in it, the commentary lines (English with names, Arabic
// without), the commentator's Arabic bubble, and the timeline cards written
// once the scene has played. Pure and seeded by the match and minute.
// The scene kind and the minute's length come from the server (tick.moment).
// The commentator's line comes from the server (tick.voice, Sprint 35). TODO(Flutter, Sprint 41): move the rest of
// the director (scene, cards) to the server too [MATCH_VIEW 4.3].
import VOICE_LINES from '../../../../backend/resources/commentary/voice.json'
import { locale, t } from '../../lib/i18n'
import { cn } from '../../lib/names'
import { scoreText } from '../../lib/format'

// Commentary. {p} the main player, {q} the second one (assist, keeper, defender),
// {A} the club the moment belongs to, {B} the other one, {n} a number.
// x: the excited voice. Each slot has English and Arabic variants; the Arabic
// voice never says names, the bubble does.
// The table lives with the server, which draws each minute's line and variants from the match's seed and sends
// them as tick.voice [Sprint 35 B1]: the same words on every screen, in the replay, and in the app.
export const LINES = VOICE_LINES

function rng(seed) {
  let a = seed >>> 0
  return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296 }
}
const first = (events, type) => events.find((e) => e.type === type)
// The scene's own length in seconds, and when its key moment happens (see art.ts).
export const SCENE_TIME = {
  goal: [6.0, 3.0], save: [5.4, 2.9], penalty: [5.6, 2.85], freekick: [5.2, 2.65], card: [4.4, 1.1], coach: [4.6, 1.0], sub: [4.2, 0.8],
  offside: [4.2, 1.5], corner: [4.6, 1.75], injury: [3.8, 0.4], whistle: [3.6, 0.6], miss: [5.0, 2.9], blocked: [4.8, 2.6], board: [3.0, 0.5],
}
const TACTIC_NAMES = { pressing: 'الضغط', style: 'الأسلوب', tempo: 'الإيقاع', plan: 'خطة اللعب', att: 'تمركز المهاجمين', mid: 'تمركز الوسط', def: 'تمركز الدفاع', trap: 'مصيدة التسلل', marking: 'الرقابة', tackling: 'قطع الكرة' }

/**
 * tick: the minute from the API. ctx: { players: {id: {name, no, side}}, clubs: {home, away} (names),
 * seed, mine (the side this screen manages, or null) }.
 * Returns { scene, data, head, who, sub, pre, items, lines, bubble, keyAt, goal }.
 * pre: what the lower bar says until the key moment (the shot, the kick), so the
 * result is not told before the ball gets there; null when there is nothing to hide.
 */
export function story(tick, ctx) {
  const ev = tick.events, R = rng((ctx.seed || 1) * 31 + tick.tick * 977)
  const pick = (a) => a[Math.floor(R() * a.length)]
  // The scene's own seed: where the shot goes, which way the keeper dives.
  const seed = () => Math.floor(R() * 1e9)
  const P = (id) => ctx.players[id]
  const nm = (id) => P(id)?.name ?? ''
  // [Sprint 30 Q8] The clubs as the coach reads them (Arabic when known); the English voice keeps the Latin ones.
  const club = (side) => cn(ctx.clubs[side])
  const no = (id) => P(id)?.no ?? ''
  const other = (s) => (s === 'home' ? 'away' : 'home')
  const minute = tick.minute[1] ? `${tick.minute[0]}+${tick.minute[1]}'` : `${tick.minute[0]}'`
  const out = { scene: null, data: {}, head: '', who: '', sub: '', pre: null, items: [], lines: [], bubble: '', keyAt: 0, goal: false, side: 'home', minute }
  const attack = first(ev, 'attack'), goal = first(ev, 'goal'), card = first(ev, 'card'), foul = first(ev, 'foul')
  const pen = first(ev, 'penalty'), fk = first(ev, 'free_kick'), corner = first(ev, 'corner'), sub = first(ev, 'sub'), injury = first(ev, 'injury')
  const period = first(ev, 'period'), stoppage = first(ev, 'stoppage'), shootout = first(ev, 'shootout')
  const action = ev.find((e) => e.type === 'action' && ['tactics', 'formation'].includes(e.action?.type))
  // The server's choice of line and variants (older replays have none: the seed picks here, as before).
  const served = tick.voice !== undefined, V = tick.voice ?? null

  // Fill a slot: the variants whose names we have, one chosen by the seed.
  const vars = { p: null, q: null, A: 'home', n: '' }
  const fill = (list) => {
    const ok = list.filter((l) => (!l.includes('{p}') || vars.p) && (!l.includes('{q}') || vars.q))
    return ok.length ? pick(ok) : null
  }
  // The key line is said the instant the scene reaches its key moment (the ball arriving), the
  // build-up line before it and the reaction after: the voice and the picture stay together.
  function speak(key, at = {}) {
    if (served && !V) return
    if (V) {
      key = V.line
      Object.assign(vars, { p: V.vars.p ?? null, q: V.vars.q ?? null, A: V.vars.A ?? vars.A })
    }
    const L = LINES[key]
    if (!L) return
    if (out.scene) {
      const k = SCENE_TIME[out.scene][1] / SCENE_TIME[out.scene][0]
      at = { key: k, post: Math.min(0.92, k + 0.16) }
    }
    const slot = (name, t) => {
      const s = L[name]
      if (!s) return
      const chosen = V?.pick?.[name]
      const en = V ? (chosen?.[0] != null ? s.en[chosen[0]] : null) : fill(s.en)
      const ar = V ? (chosen?.[1] != null ? s.ar[chosen[1]] : null) : pick(s.ar)
      if (en || ar) out.lines.push({ at: t, en, ar, x: !!s.x, vars: { ...vars }, m: key, s: name })
    }
    slot('pre', 0.05)
    slot('key', at.key ?? 0.4)
    slot('post', at.post ?? 0.75)
    const b = V ? (V.pick?.bubble != null ? L.bubble[V.pick.bubble] : null) : fill(L.bubble ?? [])
    out.bubble = b ? arabic(b) : ''
    // [UP2] In English the bubble says the commentator's English line, with the names.
    if (locale.value === 'en') {
      const said = out.lines.find((l) => l.s === 'key' && l.en) ?? out.lines.find((l) => l.en)
      out.bubble = said ? arabic(said.en) : ''
    }
  }
  const arabic = (t) => t.replace(/\{p\}/g, nm(vars.p)).replace(/\{q\}/g, nm(vars.q)).replace(/\{A\}/g, club(vars.A)).replace(/\{B\}/g, club(other(vars.A))).replace(/\{n\}/g, vars.n)
  const item = (side, icon, name, label, extra = {}) => out.items.push({ side, icon, name, label, minute, ...extra })
  const set = (scene, side, data, head, who, sub) => Object.assign(out, { scene, side, data: { side, ...data }, head, who, sub })
  const before = (head, who, sub) => (out.pre = { head, who, sub })

  const kind = tick.moment?.kind ?? 'quiet'
  if (kind === 'goal' && goal) {
    const s = goal.team, header = attack?.quality === 'header'
    Object.assign(vars, { p: goal.scorer, q: goal.assist ?? null, A: s })
    set('goal', s, { no: no(goal.scorer), passNo: goal.assist ? no(goal.assist) : '', defNo: no(attack?.defender), lane: attack?.lane, quality: attack?.quality, v: seed() }, t('هدف'), nm(goal.scorer), goal.assist ? t('صناعة {v0}', { v0: nm(goal.assist) }) : club(s))
    before(header ? t('عرضية') : t('هجمة خطيرة'), nm(goal.scorer), club(s))
    speak(header ? 'header' : 'goal', { key: 0.36, post: 0.62 })
    item(s, 'goal', nm(goal.scorer), goal.assist ? t('هدف · صناعة {v0}', { v0: nm(goal.assist) }) : header ? t('هدف · رأسية') : t('هدف'), { goal: true })
    out.goal = true
  } else if ((kind === 'penalty' || kind === 'free_kick') && (pen || fk)) {
    const sp = pen ?? fk, s = sp.team, scored = !!goal
    Object.assign(vars, { p: sp.taker, q: sp.keeper ?? null, A: s })
    const isPen = kind === 'penalty'
    const result = scored ? 'goal' : sp.keeper ? 'save' : 'miss'
    set(isPen ? 'penalty' : 'freekick', s, { no: no(sp.taker), scored, saved: result === 'save', v: seed() }, scored ? t('هدف') : isPen ? t('ركلة جزاء') : t('ضربة حرة'), nm(sp.taker), scored ? (isPen ? t('ركلة جزاء') : t('ضربة حرة مباشرة')) : result === 'save' ? t('تصدى {v0}', { v0: nm(sp.keeper) }) : t('خارج المرمى'))
    before(isPen ? t('ركلة جزاء') : t('ضربة حرة'), nm(sp.taker), t('المنفذ يستعد... والجميع ينتظر'))
    speak(isPen ? (scored ? 'penalty_goal' : 'penalty_save') : `free_kick_${result}`, { key: isPen ? 0.49 : 0.51, post: 0.72 })
    if (foul?.player) item(other(s), 'foul', nm(foul.player), isPen ? t('تسبب في ركلة جزاء') : t('خطأ'))
    item(s, scored ? 'goal' : isPen ? 'penalty' : 'miss', nm(sp.taker), scored ? (isPen ? t('هدف · ركلة جزاء') : t('هدف · ضربة حرة')) : result === 'save' ? (isPen ? t('ركلة جزاء ضائعة') : t('ضربة حرة · تصدٍّ')) : t('ضربة حرة ضائعة'), { goal: scored })
    out.goal = scored
  } else if ((kind === 'red' || kind === 'yellow') && card) {
    const s = card.team, red = kind === 'red'
    Object.assign(vars, { p: card.player, A: s })
    set('card', s, { no: no(card.player), type: red ? 'red' : 'yellow' }, red ? t('بطاقة حمراء') : t('بطاقة صفراء'), nm(card.player), card.second_yellow ? t('الإنذار الثاني') : club(s))
    before(t('خطأ'), nm(card.player), t('الحكم يقترب...'))
    speak(card.second_yellow ? 'second_yellow' : red ? 'red' : 'yellow', { key: 0.3, post: 0.65 })
    item(s, red ? 'red' : 'yellow', nm(card.player), red ? (card.second_yellow ? t('إنذار ثانٍ وطرد') : t('بطاقة حمراء')) : t('بطاقة صفراء'))
  } else if (kind === 'save' && attack) {
    const s = attack.team
    Object.assign(vars, { p: attack.shooter, q: attack.keeper ?? null, A: s })
    set('save', s, { no: no(attack.shooter), passNo: attack.creator !== attack.shooter ? no(attack.creator) : '', defNo: no(attack.defender), lane: attack.lane, quality: attack.quality, corner: attack.result === 'corner', v: seed() }, t('تصدٍّ رائع'), nm(attack.keeper) || t('الحارس'), t('أمام {v0}', { v0: nm(attack.shooter) }))
    before(t('تسديدة'), nm(attack.shooter), club(s))
    speak('save', { key: 0.35, post: 0.62 })
    item(other(s), 'save', nm(attack.keeper) || t('الحارس'), t('تصدٍّ أمام {v0}', { v0: nm(attack.shooter) }))
    if (attack.result === 'corner') item(s, 'corner', club(s), t('ركنية'))
  } else if (kind === 'miss' && attack) {
    const s = attack.team, blocked = attack.result === 'blocked'
    Object.assign(vars, { p: attack.shooter, q: attack.defender ?? null, A: s })
    const how = blocked ? null : V?.how ?? pick(['wide', 'wide', 'over', 'post'])
    const look = { passNo: attack.creator !== attack.shooter ? no(attack.creator) : '', lane: attack.lane, quality: attack.quality, v: seed() }
    if (blocked) set('blocked', s, { no: no(attack.shooter), defNo: no(attack.defender), ...look }, t('صدّها الدفاع'), nm(attack.shooter), nm(attack.defender) ? t('تدخل {v0}', { v0: nm(attack.defender) }) : club(other(s)))
    else set('miss', s, { no: no(attack.shooter), defNo: no(attack.defender), how, ...look }, how === 'post' ? t('القائم!') : t('فرصة ضائعة'), nm(attack.shooter), how === 'over' ? t('فوق العارضة') : how === 'post' ? t('ارتطمت بالقائم') : t('بجانب القائم'))
    before(t('تسديدة'), nm(attack.shooter), club(s))
    speak(blocked ? 'blocked' : how === 'post' ? 'post' : 'miss', { key: 0.4, post: 0.68 })
    item(s, 'miss', nm(attack.shooter), blocked ? t('تسديدة محجوبة') : how === 'post' ? t('القائم') : t('فرصة ضائعة'))
  } else if (kind === 'offside' && attack) {
    const s = attack.team, who = attack.receiver ?? attack.shooter
    Object.assign(vars, { p: who, A: s })
    set('offside', s, { no: no(who) }, t('تسلل'), nm(who), club(s))
    before(t('كرة خلف الدفاع'), nm(who), club(s))
    speak('offside', { key: 0.38, post: 0.66 })
    item(s, 'flag', nm(who), t('تسلل'))
  } else if (kind === 'corner' && corner) {
    const s = corner.team, won = corner.won !== false, header = attack?.shooter
    Object.assign(vars, { p: header ?? null, q: corner.taker, A: s })
    set('corner', s, { no: no(header ?? corner.taker), scored: false, claim: !won, v: seed() }, t('ركنية'), nm(won && header ? header : corner.taker), won ? t('رأسية فوق العارضة') : t('الحارس يمسك الكرة'))
    before(t('ركنية'), nm(corner.taker), club(s))
    speak(won ? 'corner_header' : 'corner_claim', { key: 0.4, post: 0.7 })
    item(s, 'corner', nm(won && header ? header : corner.taker), won ? t('ركنية · رأسية') : t('ركنية'))
  } else if (kind === 'sub' && sub) {
    const s = sub.team
    Object.assign(vars, { p: sub.in, q: sub.out, A: s })
    set('sub', s, { inNo: no(sub.in), outNo: no(sub.out) }, t('تبديل'), `${nm(sub.in)} ⇄ ${nm(sub.out)}`, club(s))
    speak('sub', { key: 0.2, post: 0.7 })
    item(s, 'sub', `${nm(sub.in)} ⇄ ${nm(sub.out)}`, sub.reason === 'injury' ? t('تبديل اضطراري') : t('تبديل'))
  } else if (kind === 'injury' && injury) {
    const s = injury.team
    Object.assign(vars, { p: injury.player, A: s })
    set('injury', s, { no: no(injury.player) }, t('إصابة'), nm(injury.player), club(s))
    speak('injury', { key: 0.15, post: 0.6 })
    item(s, 'injury', nm(injury.player), t('إصابة'))
    const sb = ev.find((e) => e.type === 'sub' && e.team === s)
    if (sb) item(s, 'sub', `${nm(sb.in)} ⇄ ${nm(sb.out)}`, t('تبديل اضطراري'))
  } else if (kind === 'coach' && action) {
    // The other side's instructions stay private: only "new instructions" (CLAUDE.md, privacy in a match).
    const s = action.team, own = ctx.mine === s || ctx.mine === null
    const a = action.action, what = a.type === 'formation' ? t('الطريقة {v0}', { v0: a.formation }) : own ? Object.keys(a.tactics ?? {}).map((k) => t(TACTIC_NAMES[k] ?? k)).slice(0, 2).join(t(' و')) : ''
    const tactic = own && what ? t('تعليمات: {v0}', { v0: what }) : t('تعليمات جديدة')
    Object.assign(vars, { p: null, A: s, n: tactic })
    set('coach', s, { tactic }, t('تعليمات المدرب'), t('مدرب {v0}', { v0: club(s) }), tactic)
    speak('coach', { key: 0.25, post: 0.7 })
    out.bubble = t('مدرب {v0} يتحرك: {v1}', { v0: club(s), v1: tactic })
    item(s, 'coach', t('مدرب {v0}', { v0: club(s) }), tactic)
  } else if (kind === 'whistle' && period) {
    const sc = `${club('home')} ${tick.score.home} - ${tick.score.away} ${club('away')}`
    const big = { halftime: t('استراحة'), fulltime: t('النهاية'), extra_time: t('وقت إضافي'), extra_time_half: t('استراحة قصيرة'), penalties: t('ركلات الترجيح') }[period.name] ?? ''
    const head = { halftime: t('نهاية الشوط الأول'), fulltime: t('نهاية المباراة'), extra_time: t('الوقت الإضافي'), extra_time_half: t('منتصف الوقت الإضافي'), penalties: t('ركلات الترجيح') }[period.name] ?? ''
    Object.assign(vars, { n: sc })
    const st = (side) => tick.teams?.[side]?.stats ?? {}
    const rows = [[t('الهجمات'), 'attacks'], [t('التسديدات'), 'shots'], [t('على المرمى'), 'on_target'], [t('الركنيات'), 'corners']].map(([l, k]) => [l, st('home')[k] ?? 0, st('away')[k] ?? 0])
    // The score reads left to right with home on the right, as on the scoreboard.
    set('whistle', 'home', { big: head, score: scoreText(tick.score.home, tick.score.away), stats: rows }, big, '', sc)
    speak({ halftime: 'halftime', fulltime: 'fulltime', extra_time: 'extra_time', penalties: 'penalties' }[period.name] ?? 'halftime', { key: 0.25 })
    item('home', 'whistle', head, sc, { center: true })
  } else if (kind === 'stoppage' && stoppage) {
    Object.assign(vars, { n: String(stoppage.added) })
    set('board', 'home', { plus: stoppage.added }, t('الوقت بدل الضائع'), `+${stoppage.added}`, t('دقائق'))
    speak('stoppage', { key: 0.15 })
  } else if (kind === 'shootout' && shootout) {
    const last = shootout.kicks?.[shootout.kicks.length - 1]
    Object.assign(vars, { n: `${shootout.score.home} - ${shootout.score.away}`, A: last?.team ?? 'home' })
    speak('shootout', { key: 0.1 })
    if (last) item(last.team, last.scored ? 'goal' : 'miss', nm(last.taker), last.scored ? t('ترجيح · سجّل') : t('ترجيح · أضاع'))
  } else if (attack && (served ? V?.line === 'attack' : R() < 0.45)) {
    Object.assign(vars, { A: attack.team })
    speak('attack', { key: 0.1 })
  }
  if (tick.tick === 1) {
    out.lines.unshift({ at: 0, en: LINES.kickoff.key.en[0], ar: LINES.kickoff.key.ar[0], x: false, vars: { ...vars } })
    out.items.unshift({ side: 'home', icon: 'whistle', name: t('انطلاق المباراة'), label: `${club('home')} - ${club('away')}`, minute: "1'", center: true })
    if (!out.bubble) out.bubble = LINES.kickoff.bubble[0]
  }
  // [X41] A small moment on the broadcast (tick.moment.brief): no scene, only its card and the commentator's one line.
  if (tick.moment?.brief) {
    Object.assign(out, { scene: null, pre: null })
    const key = out.lines.filter((l) => l.s === 'key')
    out.lines = (key.length ? key : out.lines.slice(0, 1)).map((l) => ({ ...l, at: 0.1 }))
  }
  out.keyAt = out.scene ? SCENE_TIME[out.scene][1] / SCENE_TIME[out.scene][0] : 0
  return out
}
