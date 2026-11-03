<template>
  <div ref="host" class="mc theme-night" :class="{ smooth, scene: sceneOn }" dir="rtl" :style="{ '--H': kits.home.kit, '--A': kits.away.kit }">
    <div class="atmo" aria-hidden="true" />

    <div class="sb">
      <div class="sb-in">
        <div class="side" :style="{ '--c': kits.home.kit }"><span class="crest" v-html="crestOf('home')" /><span class="nm"><b>{{ $nm(clubs.home) }}</b><small>{{ coachLine('home') }}</small></span></div>
        <div class="mid"><span class="score" :class="{ pop }" dir="ltr"><FlipNumber :value="score.away" /> - <FlipNumber :value="score.home" /></span><span class="live" :class="{ frozen }" dir="ltr"><i />{{ clock || minute }}</span></div>
        <div class="side away" :style="{ '--c': kits.away.kit }"><span class="crest" v-html="crestOf('away')" /><span class="nm"><b>{{ $nm(clubs.away) }}</b><small>{{ coachLine('away') }}</small></span></div>
      </div>
      <div class="mom" dir="ltr"><i :style="{ width: 100 - mom + '%', background: kits.away.kit }" /><i :style="{ width: mom + '%', background: kits.home.kit }" /></div>
    </div>

    <!-- [Sprint 42 G1] The owner's (2026-11-03): no live pitch. Between the moments only the match clock runs; at a
         moment it stops dead and the cartoon clip plays over it, then it runs on. -->
    <!-- [Sprint 42 H1] As on TV: the studio, two commentators at their desk and the clock on the LED wall; at a moment
         the picture cuts to the clip. -->
    <div class="clockface tv" :class="{ frozen }">
      <div ref="studioHost" class="studio" aria-hidden="true" />
      <span class="bug" dir="ltr">GLM TV</span>
      <span class="onair"><i />{{ $t('مباشر') }}</span>
      <span class="strap"><b>{{ half }}</b><span dir="ltr">{{ clock || minute }}</span><em>{{ frozen ? $t('توقف الوقت · لقطة') : $t('الوقت يمشي') }}</em></span>
      <span class="prog" dir="ltr" aria-hidden="true"><i :style="{ width: progress + '%' }" /></span>
    </div>

    <div class="tl" :aria-label="$t('مجريات المباراة')" aria-live="polite">
      <div class="spine" />
      <TransitionGroup name="row" tag="div" class="list">
        <div v-for="it in items" :key="it.key" class="row" :class="it.center ? 'home' : it.side">
          <div class="card" :class="{ goal: it.goal }" :style="{ '--c': it.center ? '#F5B82E' : kits[it.side].kit }">
            <span class="ico" v-html="ICON[it.icon]" />
            <span class="tx"><b dir="auto">{{ $nm(it.name) }}</b><span>{{ it.label }}</span></span>
            <span v-if="it.goal && it.score" class="chip" dir="ltr">{{ it.score }}</span>
          </div>
          <div class="node" dir="ltr">{{ it.minute }}</div>
        </div>
      </TransitionGroup>
    </div>

    <div class="moment" :class="{ on: sceneOn, tense }">
      <div class="mbox">
        <div ref="stage" class="stage" :class="{ shake }" />
        <span v-if="replaying" class="replay">{{ replayAngle === 2 ? $t('إعادة · زاوية أخرى') : $t('إعادة') }}</span>
        <!-- The goal: the scorer's name in his colours and confetti, after the ball is in. -->
        <div v-if="party" class="party" :style="{ '--c': kits[party.side].kit, '--t': kits[party.side].trim }" aria-hidden="true">
          <i v-for="c in (smooth ? confetti.slice(0, 14) : confetti)" :key="c.i" :style="c.style" />
          <span class="burst"><b>{{ party.who }}</b><small>{{ $nm(clubs[party.side]) }}</small></span>
        </div>
        <div class="lower" :style="{ '--c': barKit }">
          <span class="ev">{{ bar?.head }}</span>
          <span class="who"><b dir="auto">{{ bar?.who }}</b><span>{{ bar?.sub }}</span></span>
          <span class="min" dir="ltr">{{ cur?.minute }}</span>
        </div>
      </div>
    </div>

    <!-- The coaches' reactions in a match between friends, rising from each side. -->
    <div class="reacts" aria-live="polite">
      <TransitionGroup name="rx">
        <div v-for="r in reacts" :key="r.id" class="rx" :class="r.side" :style="{ '--c': kits[r.side].kit, '--x': r.x + '%' }">
          <span class="e">{{ r.emoji }}</span><span v-if="r.text || r.who" class="t"><small>{{ r.who }}</small>{{ r.text }}</span>
        </div>
      </TransitionGroup>
    </div>

    <div class="mic" :class="{ on: bubbleOn }">
      <span class="m" aria-hidden="true"><svg viewBox="0 0 24 24" fill="#071733"><rect x="8" y="2" width="8" height="13" rx="4" /><path d="M5 11a7 7 0 0 0 14 0" fill="none" stroke="#071733" stroke-width="2" /><rect x="11" y="18" width="2" height="4" /></svg></span>
      <span class="wave" aria-hidden="true"><i v-for="n in 7" :key="n" /></span>
      <span class="tx"><b>{{ bubble }}</b><span v-if="lang === 'en' && enLine" dir="ltr">{{ enLine }}</span></span>
    </div>

    <div v-if="intro" class="preview">
      <span class="kick">{{ live ? $t('مباراة بين صديقين') : $t('ما قبل المباراة') }}</span>
      <span v-if="live && countdown > 0" class="plan">{{ $t('الصافرة بعد') }} <b dir="ltr">{{ countdown }}</b> {{ $t('ثانية · عدّل تشكيلتك وخطتك من لوحة المدرب الآن') }}</span>
      <div class="teams">
        <div class="team"><span class="crest" v-html="crestOf('home')" /><b>{{ $nm(clubs.home) }}</b><small>{{ coachLine('home') }}</small></div>
        <span class="vs">VS</span>
        <div class="team"><span class="crest" v-html="crestOf('away')" /><b>{{ $nm(clubs.away) }}</b><small>{{ coachLine('away') }}</small></div>
      </div>
      <div class="stats">
        <div v-for="r in compare" :key="r.label" class="st"><span>{{ r.h }}</span><span class="bar"><i :style="{ width: r.hp + '%', background: kits.home.kit }" /><i :style="{ width: 100 - r.hp + '%', background: kits.away.kit }" /></span><span>{{ r.a }}</span><span class="lbl">{{ $t(r.label) }}</span></div>
      </div>
      <div class="keys">
        <div v-for="s in (['home', 'away'] as const)" :key="s" class="key" :style="{ '--c': kits[s].kit }"><span class="no">{{ star(s)?.no }}</span><span><b>{{ $nm(star(s)?.name) }}</b><span>{{ $t('مفتاح {v0} · {v1}', { v0: $nm(clubs[s]), v1: star(s)?.ovr }) }}</span></span></div>
      </div>
      <button type="button" class="go" @click="$emit('introDone')">{{ live ? (countdown > 0 ? $t('البداية بعد {v0}', { v0: countdown }) : $t('شغّل الصوت وانتظر البداية')) : $t('ابدأ البث') }}</button>
    </div>
  </div>
</template>

<script setup lang="ts">
// @ts-nocheck
// The match feed (docs/MATCH_VIEW.md 4.6): each minute plays its scene first,
// then its card joins the timeline and the commentator sums it up on the mic
// bar. The parent calls play(tick) per minute; the minute's length is the
// server's (tick.moment.ms).
import { scoreText } from '../../lib/format'
import { t as tr } from '../../lib/i18n'
import FlipNumber from '../../components/ui/FlipNumber.vue'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { ICON, SCENES, crest, setKits, setRain, setSmooth, studio } from './art'
import { noteFrame, smooth, tier } from '../perf'
import { sample } from '../frames'
import { SCENE_TIME, story } from './story'
import { director } from './director'
import { voiceLine, type Lang } from '../voice'

const props = defineProps<{ kits: any; clubs: { home: string; away: string }; codes: { home: string; away: string }; logos?: { home?: string | null; away?: string | null }; strength: { home: number; away: number }; coaches: any; teams: any; seed: number; kickoff?: string | null; looks?: Partial<Record<'home' | 'away', string>> | null; speed: number; minute: string; score: { home: number; away: number }; mine: string | null; lang: Lang | 'off'; intro: boolean; live: boolean; countdown: number }>()
const emit = defineEmits<{ cue: [name: string]; sound: [name: string]; say: [line: any]; near: [closeness: number]; introDone: [] }>()

const host = ref<HTMLElement>(), stage = ref<HTMLElement>(), studioHost = ref<HTMLElement>()
// [X35] The broadcast clock, minutes and seconds running through each minute as on TV ('' between minutes: the parent's).
const clock = ref('')
// [Sprint 42 E1] The owner's (2026-11-03): the clock runs, and at the moment's second it stops dead while the cartoon
// plays (and its cutaways), then runs on to the end of the minute.
const frozen = ref(false)
// [Sprint 42 G1] The half and how far the match has gone, under the clock.
const half = ref(''), progress = ref(0)
const items = ref<any[]>([])
const cur = ref<any>(null)
const sceneOn = ref(false), bubbleOn = ref(false), shake = ref(false), pop = ref(false), replaying = ref(false)
// Until the key moment the lower bar tells only what is happening (a shot, a penalty), never how it ends.
const revealed = ref(true), tense = ref(false)
const bar = computed(() => (revealed.value || !cur.value?.pre ? cur.value : cur.value.pre))
const party = ref(null)
const confetti = Array.from({ length: 42 }, (_, i) => ({ i, style: { left: ((i * 37) % 100) + '%', animationDelay: ((i * 53) % 90) / 100 + 's', animationDuration: 1.6 + ((i * 29) % 10) / 10 + 's', background: ['var(--c)', 'var(--t)', '#F5B82E', '#fff'][i % 4], transform: `rotate(${(i * 47) % 360}deg)` } }))
const reacts = ref([])
let reactSeq = 0
/** A coach's reaction (live): an emoji and a short word, rising from his side for a few seconds. */
function react(side, emoji, text, who) {
  const id = ++reactSeq
  reacts.value.push({ id, side, emoji, text, who, x: 8 + ((id * 23) % 22) })
  if (reacts.value.length > 6) reacts.value.shift()
  setTimeout(() => (reacts.value = reacts.value.filter((r) => r.id !== id)), 3200)
}
const bubble = ref(''), enLine = ref('')
const mom = ref(50)
const barKit = computed(() => {
  const k = props.kits[cur.value?.side === 'away' ? 'away' : 'home'].kit, n = parseInt(k.slice(1), 16)
  return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) > 150 ? '#3A5F9E' : k
})
// [UP3] The club's real logo where it has one, else its drawn badge.
const crestOf = (s) => (props.logos?.[s] ? `<img src="${props.logos[s]}" alt="" decoding="async">` : crest([props.kits[s].kit, props.kits[s].trim, props.codes[s] || '']))
const coachLine = (s) => [props.coaches?.[s] ?? (props.mine === s ? tr('أنت') : props.live ? '' : props.mine ? tr('الحاسوب') : ''), props.teams?.[s]?.formation].filter(Boolean).join(' · ')
watch(() => props.kits, (k) => setKits(k), { immediate: true, deep: true })
// The smooth mode for weak phones [X30]: the scenes drawn from now on leave out the costly parts.
watch(smooth, (v) => setSmooth(v), { immediate: true })
watch(() => [props.score.home, props.score.away], () => { pop.value = false; requestAnimationFrame(() => (pop.value = true)) })

// Every player of the match by id, for names and shirt numbers.
const players = computed(() => {
  const m = {}
  for (const side of ['home', 'away']) for (const p of props.teams?.[side]?.players ?? []) m[p.id] = { name: p.name, no: p.no, side }
  return m
})
// The pre-match card: strength, average rating of the starters, and each side's key player.
const star = (s) => [...(props.teams?.[s]?.players ?? [])].filter((p) => p.on).sort((a, b) => b.ovr - a.ovr)[0]
const avg = (s) => { const on = (props.teams?.[s]?.players ?? []).filter((p) => p.on); return on.length ? Math.round(on.reduce((t, p) => t + p.ovr, 0) / on.length) : 0 }
const compare = computed(() => [
  { label: 'القوة', h: Math.round(props.strength.home / 100), a: Math.round(props.strength.away / 100) },
  { label: 'متوسط التشكيلة', h: avg('home'), a: avg('away') },
].map((r) => ({ ...r, hp: r.h + r.a ? (r.h / (r.h + r.a)) * 100 : 50 })))

// ---------------------------------------------------------------- playing a minute
// [Sprint 36 F4] The replay's angle (1, then 2 at the full tier), and the frame that turns the scene round for it.
const replayAngle = ref(1)
let angleWrap: any = null
// [Sprint 35 C1] The minute's own scene (for its replay) and the cutaway playing now.
let mainScene: any = null, cutScene: any = null
let raf = 0, last = 0, t = 0, plan: any = null, scene: any = null, keySeq = 0, drawn = 0
// startAt (live): when the minute starts on performance.now(). The scene follows that clock
// instead of counting frames, so two screens stay on the same instant even if one is slow.
function play(tick, startAt = null) {
  finish()
  const s = story(tick, { players: players.value, clubs: props.clubs, seed: props.seed, mine: props.mine })
  const total = (tick.moment?.ms ?? 3000) / 1000
  const nominal = s.scene ? SCENE_TIME[s.scene][0] : 0
  // The scene takes most of the minute; the commentator sums it up after.
  // At the broadcast's fixed pace a minute is 3.3 s [X35]: the scene takes up to nine tenths of it, a little faster.
  const sceneT = s.scene ? Math.min(nominal, total * (tick.moment?.ms <= 3400 ? 0.9 : 0.72)) : 0
  // [Sprint 35 C1] The director's cutaways after the scene (the crowd, the coaches), as many as the tier and the
  // minute's length allow; then [X41] a goal's replay in slow motion, as on TV.
  const cuts = director(s, tick, total, sceneT, { tier: tier.value, looks: props.looks, seed: props.seed }), cutT = cuts.reduce((a, c) => a + c.dur, 0)
  const at = sceneT + (cuts.length ? cutT + 0.5 : 2.6), room = total - at - 0.8
  // [Sprint 33 Q1] No replay at the lowest tier. Too little room for the whole scene slowed: its last part, the shot.
  const rate = s.goal && s.scene && room > 1.6 && !smooth.value ? Math.max(0.4, Math.min(0.8, nominal / room)) : 0
  const replay = rate ? { at, rate, off: Math.max(0, nominal - room * rate) } : null
  plan = { s, total, sceneT, cuts, cutT, rate: s.scene ? nominal / sceneT : 1, replay, fired: new Set(), itemsAdded: false, score: scoreText(tick.score.home, tick.score.away), startAt, tick }
  mom.value = Math.max(15, Math.min(85, 50 + (tick.danger ?? 0) * 7))
  cur.value = s
  revealed.value = !s.pre
  // The stadium holds its breath before a penalty or a free kick on the edge of the box.
  tense.value = s.scene === 'penalty' || s.scene === 'freekick'
  party.value = null
  t = startAt === null ? 0 : Math.max(0, (performance.now() - startAt) / 1000)
  let made: any = null
  // A scene that breaks is skipped with its minute's cards still shown: the match never stops on one drawing.
  if (s.scene) try {
    made = SCENES[s.scene]({ ...s.data, side: s.side })
    made.update(0)
  } catch (e) { console.error(e); made = null }
  angleWrap = null; replayAngle.value = 1
  if (made) {
    scene = made
    mainScene = made
    stage.value.replaceChildren(scene.svg)
    sceneOn.value = true
  } else {
    scene = null
    addItems()
    if (s.bubble && s.items.length) showBubble()
  }
}
// One frame of the scene; a frame that throws ends the scene there and the minute goes on without it.
function draw(u) {
  try { scene.update(u) } catch (e) { console.error(e); scene = null; sceneOn.value = false; addItems(); showBubble() }
}
// The scene is over: its cards join the timeline, and the page may tell the result (cue 'reveal').
function addItems(tell = true) {
  if (!plan || plan.itemsAdded) return
  plan.itemsAdded = true
  if (tell) emit('cue', 'reveal')
  for (const it of plan.s.items) items.value.unshift({ ...it, key: ++keySeq, score: it.goal ? plan.score : null })
  // A long timeline is kept short: the oldest cards leave (fewer on a weak phone).
  const keep = smooth.value ? 16 : 30
  if (items.value.length > keep) items.value.length = keep
}
function showBubble() {
  const s = plan.s
  bubble.value = s.bubble
  const l = s.lines.find((l) => l.x) ?? s.lines[0]
  enLine.value = l?.en ? voiceLine('en', { ...l, x: false }, players.value, props.clubs)?.text ?? '' : ''
  bubbleOn.value = !!s.bubble
}
// Finish the minute at once: the next one is starting, or the viewer skipped.
function finish() {
  if (!plan) return
  frozen.value = false
  sceneOn.value = false
  replaying.value = false
  cutScene = null
  tense.value = false
  party.value = null
  addItems(false)
  bubbleOn.value = false
  plan = null
}
function skip() { finish() }
defineExpose({ play, skip, react })

const SOUNDS = {
  goal: [[0.3, 'kick'], ['key', 'kick'], ['key', 'roar']], save: [[0.3, 'kick'], ['key', 'groan']], miss: [[0.3, 'kick'], ['key', 'groan']], blocked: [['key', 'thud'], ['key', 'groan']],
  penalty: [[0.03, 'whistle-long'], [0.34, 'heart'], [0.42, 'heart'], [0.51, 'heart'], ['key', 'kick'], ['key', 'roar']], freekick: [[0.05, 'whistle'], [0.25, 'heart'], [0.37, 'heart'], ['key', 'kick'], ['key', 'roar']],
  // [Sprint 42] The cartoon clips: the tackle's thud and the whistle, the card, the injury's whistle, the sub's beeps.
  card: [[0.12, 'thud'], [0.14, 'whistle'], ['key', 'whistle'], ['key', 'murmur']], foul: [[0.29, 'thud'], [0.31, 'whistle'], [0.57, 'whistle']],
  // [Sprint 42 F] The second set: the shot and the kick off the line, the trap's whistle, the megaphone's murmur, the slip.
  clearance: [[0.1, 'kick'], ['key', 'thud'], [0.66, 'groan']], trap: [['key', 'whistle']], rant: [[0.1, 'murmur']], slip: [['key', 'thud'], [0.4, 'groan']], var: [[0.32, 'kick'], [0.37, 'roar'], [0.52, 'whistle'], ['key', 'whistle'], ['key', 'groan']], offside: [['key', 'whistle']], corner: [[0.35, 'kick'], ['key', 'kick']], whistle: [[0.1, 'whistle']], sub: [[0.06, 'beep'], [0.2, 'beep'], [0.52, 'thud']], board: [[0.1, 'beep']], injury: [[0.04, 'whistle'], [0.2, 'groan']],
}
// [Sprint 42] And each card's drama: the whistles round the swarm, the thumps in the fight, the bottle kicked.
const DRAMA_SOUNDS = { swarm: [[0.31, 'whistle'], [0.35, 'whistle'], [0.39, 'whistle'], [0.43, 'whistle']], brawl: [[0.3, 'thud'], [0.34, 'thud'], [0.38, 'thud'], [0.42, 'whistle']], spit: [[0.39, 'murmur'], [0.4, 'groan']] }
function soundsOf(s) {
  const base = SOUNDS[s.scene] ?? []
  if (s.scene === 'foul' && s.data.drama === 'dive') return [[0.25, 'groan'], [0.8, 'whistle']]
  // [Sprint 42 F2] The double save's second shot and second block; the blackout's dark silence, then the roar.
  if (s.scene === 'save' && s.data.drama === 'double') return [...base, [0.69, 'kick'], [0.79, 'thud'], [0.8, 'roar']]
  if (s.scene !== 'card') return base
  return [...base, ...(DRAMA_SOUNDS[s.data.drama] ?? []), ...(s.data.type === 'red' ? [[0.78, 'kick']] : [])]
}
// [X41] A hidden page gets no animation frames, but the broadcast plays on (the commentator and the crowd): a timer
// steps the minute instead, so its lines and sounds still come on time. Browsers let a page that plays sound run.
let bgTimer = 0
function frame(now) { step(now); raf = requestAnimationFrame(frame) }
function step(now) {
  // [Sprint 33 Q1] Frames that fall behind while the match plays lower the auto tier, one at a time [X30]. A hidden
  // page (stepped by the timer, not by frames) says nothing of the device.
  if (plan && !document.hidden) noteFrame(now - last)
  const dt = Math.min(0.05, (now - last) / 1000) * (props.speed || 1)
  last = now
  if (!plan) drawStudio(now)
  if (plan) {
    t = plan.startAt === null ? t + dt : Math.max(0, (now - plan.startAt) / 1000)
    const { s, total, sceneT, rate, fired } = plan
    tickClock(plan.tick, Math.min(1, t / total), plan)
    near(plan.tick, Math.min(1, t / total))
    drawStudio(now)
    const fire = (k, fn) => { if (!fired.has(k)) { fired.add(k); fn() } }
    // A line or a sound long past (the screen joined late) is dropped, not played out of time.
    const cue = (k, at, fn) => fire(k, () => t - at < 0.6 && fn())
    // The scene follows the clock, so drawing it 30 times a second in the smooth mode only skips frames, never time.
    if (scene && t < sceneT && (!smooth.value || now - drawn >= 32)) { drawn = now; draw(t * rate) }
    const keyT = s.keyAt * sceneT
    // Commentary: line times are fractions of the scene (or of the minute when there is none).
    for (const [i, l] of s.lines.entries()) { const at = l.at * (sceneT || total * 0.5); if (t >= at) cue('l' + i, at, () => { talkAt(); if (props.lang !== 'off') emit('say', voiceLine(props.lang, l, players.value, props.clubs)) }) }
    for (const [i, [at, name]] of soundsOf(s).entries()) { const when = at === 'key' ? keyT : at * sceneT; if (t >= when) cue('s' + i, when, () => emit('sound', name)) }
    if (s.scene === 'miss' && s.data.how === 'post' && t >= keyT) cue('post', keyT, () => emit('sound', 'post'))
    if (t >= keyT) fire('key', () => { revealed.value = true; tense.value = false })
    if (s.goal && t >= keyT) fire('goal', () => {
      emit('cue', 'goal'); shake.value = true; setTimeout(() => (shake.value = false), 500)
      hypeTill = performance.now() + 6000
      party.value = { side: s.side, who: s.who }
    })
    // [Sprint 35 C1] After the scene, the director cuts away (each cutaway built as it starts), then the cards.
    if (scene && t >= sceneT) {
      let c0 = sceneT, cut = null, n = 0
      for (const [i, c] of plan.cuts.entries()) { if (t >= c0 && t < c0 + c.dur) { cut = c; n = i; break } c0 += c.dur }
      if (cut) {
        fire('cut' + n, () => {
          party.value = null
          try { cutScene = SCENES[cut.name](cut.data); cutScene.update(0); stage.value.replaceChildren(cutScene.svg); sceneOn.value = true } catch (e) { console.error(e); cutScene = null }
        })
        if (cutScene && (!smooth.value || now - drawn >= 32)) { drawn = now; try { cutScene.update(t - c0) } catch (e) { console.error(e); cutScene = null } }
      } else if (t >= sceneT + plan.cutT) fire('end', () => { sceneOn.value = false; party.value = null; cutScene = null; addItems(); showBubble() })
    }
    const rp = plan.replay
    if (scene && rp && t >= rp.at) {
      const u = (rp.off ?? 0) + (t - rp.at) * rp.rate
      const len = SCENE_TIME[s.scene][0]
      // [Sprint 42 G1] The replay is the clip again, slowed down (the live pitch is gone). None at the lowest tier.
      if (u < len) {
        fire('replay', () => {
          bubbleOn.value = false; replaying.value = true; sceneOn.value = true
          if (mainScene) {
            scene = mainScene; stage.value.replaceChildren(mainScene.svg)
            // The scene's world in a frame the second angle can turn round.
            const w = mainScene.svg.world
            if (w && !angleWrap) { angleWrap = document.createElementNS('http://www.w3.org/2000/svg', 'g'); w.parentNode.insertBefore(angleWrap, w); angleWrap.appendChild(w) }
          }
        })
        // [Sprint 36 F4] Two angles at the full tier: halfway through, the director cuts to the reverse angle, closer
        // (the scene turned round about the goal).
        const angle = tier.value === 'high' && (u - (rp.off ?? 0)) / Math.max(0.01, len - (rp.off ?? 0)) > 0.5 ? 2 : 1
        if (angle !== replayAngle.value) {
          replayAngle.value = angle
          if (angleWrap) angleWrap.setAttribute('transform', angle === 2 ? 'translate(320 130) scale(-1.3 1.3) translate(-320 -130)' : '')
        }
        if (!smooth.value || now - drawn >= 32) { drawn = now; draw(u) }
      } else fire('replay-end', () => { replaying.value = false; sceneOn.value = false; replayAngle.value = 1; showBubble() })
    }
    // The commentator's bubble leaves before the minute ends: a calm pause on the timeline before the next scene.
    if (!plan.replay && t >= (scene ? Math.min(total, sceneT + plan.cutT + 2.8) : total)) fire('done', () => { bubbleOn.value = false })
  }
}

// ---------------------------------------------------------------- [Sprint 42 H1] the studio
// Two commentators take turns: each line said makes the next one talk for a while; a goal puts them on their feet.
let studioView: any = null, talkTill = 0, talker = 1, hypeTill = 0, studioDrawn = 0
function talkAt() { talker = talker === 1 ? 2 : 1; talkTill = performance.now() + 2600 }
function buildStudio() {
  if (!studioHost.value) return
  try { studioView = studio(props.kits); studioHost.value.replaceChildren(studioView.svg); drawStudio(performance.now(), true) } catch (e) { console.error(e); studioView = null }
}
function drawStudio(now, force = false) {
  // Behind a clip nobody sees it: not drawn then. At 30 a second in the smooth mode.
  if (!studioView || (sceneOn.value && !force) || (!force && smooth.value && now - studioDrawn < 32)) return
  studioDrawn = now
  const hype = Math.max(0, Math.min(1, (hypeTill - now) / 1000))
  try { studioView.update(now / 1000, { clock: clock.value || props.minute, score: `${props.score.away} - ${props.score.home}`, frozen: frozen.value, talk: now < talkTill || bubbleOn.value ? talker : 0, hype }) } catch (e) { console.error(e); studioView = null }
}
watch(() => props.kits, () => buildStudio(), { deep: true })
onMounted(buildStudio)

// ---------------------------------------------------------------- the clock [X35, Sprint 42 G1]
// [Sprint 42 G1] The live pitch is gone (the owner's, 2026-11-03): only the clock between the moments. The server still
// sends the Keyframes (Unity draws them); here they only tell the crowd how close the ball is to a goal.
// [Sprint 36 F3] The rain falls in the scenes (from the seed; MomentClock::rainy on the server, keep the two in step).
const rainy = () => (Number(props.seed) || 0) % 6 === 1
// [Sprint 31 D4] How close the ball is to a goal, in tenths, for the crowd's sound (sent only when it changes).
let nearSent = -1
function near(tick, u) {
  const f = tick?.frames
  if (!f?.length) return
  const bx = sample(f, u).ball[0], c = Math.round(Math.max(0, Math.min(1, (Math.abs(bx - 525) - 200) / 300)) * 10) / 10
  if (c !== nearSent) { nearSent = c; emit('near', c) }
}
function tickClock(tick, u, p = null) {
  const m = tick?.minute
  if (!m || (tick.moment?.kind === 'shootout')) { clock.value = ''; frozen.value = false; return }
  const base = m[0] - 1 + (m[1] || 0)
  let sec = Math.min(59, Math.floor(u * 60))
  // [Sprint 42 E1] A minute with a scene: the clock runs up to the moment's second (from the minute, the same on every
  // screen) in the first 0.4 s, stands still through the scene, then runs on.
  const hold = p?.s?.scene && p.total ? Math.min(0.95, (p.sceneT + p.cutT) / p.total) : 0
  const stop = hold > 0 && u < hold && u * p.total >= 0.4
  if (hold > 0) {
    const at = 12 + ((tick.tick ?? 1) * 37) % 40, run = Math.min(hold, 0.4 / p.total)
    sec = Math.min(59, Math.floor(u < run ? (at * u) / run : u < hold ? at : at + ((59 - at) * (u - hold)) / (1 - hold)))
  }
  if (frozen.value !== stop) frozen.value = stop
  const mm = m[0] + (m[1] || 0)
  half.value = m[0] > 120 ? tr('ركلات الترجيح') : m[0] > 90 ? tr('الوقت الإضافي') : m[0] > 45 ? tr('الشوط الثاني') : tr('الشوط الأول')
  progress.value = Math.min(100, Math.round(((mm - 1 + u) / 90) * 100))
  const text = `${String(base).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  if (clock.value !== text) clock.value = text
}
watch(() => props.seed, () => setRain(rainy()), { immediate: true })
onMounted(() => {
  raf = requestAnimationFrame((n) => { last = n; frame(n) })
  bgTimer = window.setInterval(() => { if (document.hidden) step(performance.now()) }, 200)
})
onBeforeUnmount(() => { cancelAnimationFrame(raf); clearInterval(bgTimer) })
</script>

<style scoped>
/* Brand navy and gold; each team's colour is light from its side. */
.mc { position: absolute; inset: 0; overflow: hidden; isolation: isolate; contain: strict; will-change: transform; color: #F7F4EA; font-family: 'IBM Plex Sans Arabic', system-ui, sans-serif; container-type: size; background: #050D1F }
.atmo { position: absolute; inset: 0; z-index: -1; background:
  radial-gradient(60% 50% at 100% 20%, color-mix(in srgb, var(--H) 22%, transparent), transparent 70%),
  radial-gradient(60% 50% at 0% 20%, color-mix(in srgb, var(--A) 26%, transparent), transparent 70%),
  radial-gradient(90% 70% at 50% 110%, rgba(245,184,46,.14), transparent 60%),
  linear-gradient(180deg, #0B2149, #050D1F 70%) }
.atmo::before { content: ''; position: absolute; inset: -20%; background: repeating-linear-gradient(115deg, transparent 0 120px, rgba(255,255,255,.035) 120px 180px, transparent 180px 300px); animation: beams 18s linear infinite }
@keyframes beams { to { transform: translateX(300px) } }

.sb { position: absolute; top: 10px; left: 10px; right: 10px; z-index: 6 }
.sb-in { display: grid; grid-template-columns: 1fr auto 1fr; align-items: stretch; border-radius: 16px; overflow: hidden; background: rgba(16,40,79,.86); border: 1px solid rgba(255,255,255,.09); box-shadow: 0 18px 40px rgba(0,0,0,.45) }
.side { display: flex; align-items: center; gap: 10px; padding: 8px 12px; min-width: 0; position: relative }
.side::before { content: ''; position: absolute; inset: 0; opacity: .22; background: linear-gradient(90deg, transparent, var(--c)) }
.side.away { flex-direction: row-reverse; text-align: left }
.side.away::before { background: linear-gradient(270deg, transparent, var(--c)) }
.nm { position: relative; min-width: 0; display: grid }
.nm b { font-family: 'Amin', sans-serif; font-weight: 800; font-size: clamp(13px, 3.4cqw, 21px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.nm small { color: #93A3BF; font-size: 12px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.crest { width: clamp(32px, 6cqw, 50px); flex: none; position: relative; filter: drop-shadow(0 4px 10px rgba(0,0,0,.5)) }
.crest :deep(svg), .crest :deep(img) { display: block; width: 100%; height: auto }
.mid { display: grid; justify-items: center; align-content: center; padding: 4px 14px; background: linear-gradient(180deg, rgba(5,13,31,.75), rgba(5,13,31,.95)); border-inline: 1px solid rgba(255,255,255,.09) }
.score { font-family: 'Barlow Condensed', 'Amin', sans-serif; font-weight: 800; font-size: clamp(30px, 7.5cqw, 50px); line-height: .95; letter-spacing: .04em; color: #fff; font-variant-numeric: tabular-nums }
.score.pop { animation: pop .7s }
@keyframes pop { 25% { transform: scale(1.25); color: #FFD36B; text-shadow: 0 0 18px #F5B82E } }
.live { display: flex; align-items: center; gap: 6px; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 16px; letter-spacing: .06em; color: #FFD36B }
/* The live dot's ring grows by transform and fades by opacity: no repaint on every frame [X30]. */
.live i { position: relative; width: 7px; height: 7px; border-radius: 50%; background: #EF4444 }
.live i::after { content: ''; position: absolute; inset: 0; border-radius: 50%; background: rgba(239,68,68,.7); animation: ping 1.4s infinite }
/* [Sprint 42 E1] The clock stopped for the scene: the dot turns gold and the time blinks. */
.live.frozen { animation: clockstop .8s steps(2, jump-none) infinite }
.live.frozen i { background: #F5B82E }
.live.frozen i::after { animation: none; background: transparent }
@keyframes clockstop { 50% { opacity: .45 } }
@keyframes ping { 0% { transform: scale(1); opacity: .9 } 70%, 100% { transform: scale(3); opacity: 0 } }
.mom { height: 3px; display: flex; margin: 0 14px; border-radius: 2px; overflow: hidden }
.mom i { display: block; height: 100%; transition: width .8s }

.clockface { position: absolute; z-index: 1; top: clamp(84px, 16cqw, 106px); left: 10px; right: 10px; height: min(40cqh, 62cqw); border-radius: 14px; overflow: hidden; background: #040B1C; box-shadow: 0 0 0 2px rgba(255,255,255,.08), 0 16px 30px rgba(0,0,0,.45) }
.studio { position: absolute; inset: 0 }
.studio :deep(svg) { width: 100%; height: 100%; display: block }
/* The TV's own graphics over the studio: the channel's mark, ON AIR, and the strap with the half and the clock. */
.clockface .bug { position: absolute; top: 8px; left: 10px; font-family: 'Barlow Condensed', sans-serif; font-weight: 900; font-size: 13px; letter-spacing: .12em; color: #FFD36B; padding: 2px 8px; border-radius: 4px; background: rgba(4,11,28,.7); border: 1px solid rgba(245,184,46,.5) }
.clockface .onair { position: absolute; top: 8px; right: 10px; display: inline-flex; align-items: center; gap: 5px; padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: 800; color: #fff; background: #D21F1F }
.clockface .onair i { width: 6px; height: 6px; border-radius: 50%; background: #fff; animation: ping 1.4s infinite }
.clockface .strap { position: absolute; left: 10px; right: 10px; bottom: 16px; display: flex; align-items: center; gap: 10px; padding: 4px 10px; border-radius: 6px; background: linear-gradient(90deg, rgba(7,23,51,.92), rgba(7,23,51,.75)); border-inline-start: 3px solid #F5B82E; font-size: 12px; color: #C9D2E1 }
.clockface .strap b { color: #fff; font-weight: 800 }
.clockface .strap span { font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 16px; color: #FFD36B; font-variant-numeric: tabular-nums }
.clockface .strap em { font-style: normal; margin-inline-start: auto }
.clockface .prog { position: absolute; left: 10px; right: 10px; bottom: 8px; height: 3px; border-radius: 3px; background: rgba(255,255,255,.12); overflow: hidden }
.clockface .prog i { display: block; height: 100%; background: #F5B82E; transition: width .3s linear }
/* Stopped for the clip: the clock on the strap blinks. */
.clockface.frozen .strap span { animation: clockstop .8s steps(2, jump-none) infinite }
/* [Sprint 42 H1] The cut from the studio to the clip: a gold and navy wipe across the picture, as a broadcast's sting. */
.moment.on .mbox::after { content: ''; position: absolute; inset: 0; z-index: 6; pointer-events: none; background: linear-gradient(105deg, transparent 0 32%, #F5B82E 32% 38%, #071733 38% 62%, #F5B82E 62% 66%, transparent 66%); background-size: 320% 100%; animation: sting .6s ease-in forwards }
@keyframes sting { from { background-position: 100% 0 } to { background-position: 0 0; opacity: 0 } }
.tl { position: absolute; top: calc(clamp(84px, 16cqw, 106px) + min(40cqh, 62cqw) + 6px); bottom: 70px; left: 0; right: 0; overflow: hidden; mask-image: linear-gradient(180deg, transparent, #000 26px, #000 82%, transparent) }
.spine { position: absolute; top: 0; bottom: 0; left: 50%; width: 2px; transform: translateX(-50%); background: linear-gradient(180deg, transparent, rgba(245,184,46,.55) 10%, rgba(245,184,46,.15)) }
.list { position: relative; padding: 22px 10px 0; display: grid; gap: 10px }
.row { display: grid; grid-template-columns: 1fr 54px 1fr; align-items: center }
.row .node { grid-column: 2; grid-row: 1 }
.row .card { grid-row: 1; grid-column: 1 }
.row.away .card { grid-column: 3; flex-direction: row-reverse; text-align: left; border-inline-start: 1px solid rgba(255,255,255,.09); border-inline-end: 3px solid var(--c) }
.row-enter-active { transition: all .55s cubic-bezier(.2,.9,.25,1.15) }
.row-enter-from { opacity: 0; transform: translateY(-14px) scale(.97) }
.node { margin: auto; min-width: 46px; height: 26px; padding: 0 6px; border-radius: 13px; display: grid; place-items: center; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 16px; color: #FFD36B; background: #071733; border: 1px solid rgba(245,184,46,.55); box-shadow: 0 0 14px rgba(245,184,46,.18) }
.card { display: flex; align-items: center; gap: 10px; min-width: 0; padding: 7px 11px; border-radius: 14px; background: rgba(16,40,79,.86); border: 1px solid rgba(255,255,255,.09); border-inline-start: 3px solid var(--c); box-shadow: 0 10px 24px rgba(0,0,0,.35) }
.ico { width: 36px; height: 36px; flex: none; border-radius: 11px; display: grid; place-items: center; background: linear-gradient(160deg, rgba(255,255,255,.1), rgba(255,255,255,.02)); border: 1px solid rgba(255,255,255,.09) }
.ico :deep(svg) { width: 22px; height: 22px }
.card .tx { min-width: 0; display: grid }
.card .tx b { font-family: 'Amin', sans-serif; font-weight: 700; font-size: clamp(13px, 2.7cqw, 16px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.card .tx span { color: #93A3BF; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.card.goal { background: linear-gradient(100deg, rgba(245,184,46,.28), rgba(16,40,79,.7) 60%); border-color: rgba(245,184,46,.5) }
.card.goal .tx span { color: #FFD36B; font-weight: 700 }
.chip { margin-inline-start: auto; font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 18px; color: #050D1F; background: #F5B82E; border-radius: 8px; padding: 0 8px }
/* Phones: one column of full-width cards, minute first. */
@container (max-width: 560px) {
  .spine { left: auto; right: 36px }
  .row, .row.away { grid-template-columns: 52px 1fr }
  .row .node { grid-column: 1 }
  .row .card, .row.away .card { grid-column: 2; flex-direction: row; text-align: right; border-inline-start: 3px solid var(--c); border-inline-end: 1px solid rgba(255,255,255,.09) }
}

.moment { position: absolute; inset: 0; z-index: 8; display: grid; place-items: center; opacity: 0; pointer-events: none; transition: opacity .45s ease-out }
.moment.on { opacity: 1 }
.moment::before { content: ''; position: absolute; inset: 0; background: rgba(3,8,20,.7) }
.mbox { position: relative; width: min(94cqw, 780px, calc((100cqh - 30px) * 1.5)); border-radius: 20px; overflow: hidden; background: #040B1C; border: 1px solid rgba(245,184,46,.28); box-shadow: 0 30px 80px rgba(0,0,0,.7); transform: translateY(10px) scale(.9); transition: transform .55s cubic-bezier(.2,.9,.25,1.1) }
.moment.on .mbox { transform: none }
/* The scene is walled off from the page [X30]: its every frame lays out and paints only itself, on its own layer. */
.stage { aspect-ratio: 640 / 340; contain: strict; will-change: transform }
.stage :deep(svg) { display: block; width: 100%; height: 100% }
.stage.shake { animation: shake .45s }
@keyframes shake { 20% { transform: translate(-6px, 3px) } 40% { transform: translate(5px, -4px) } 60% { transform: translate(-4px, 2px) } 80% { transform: translate(3px, -1px) } }
.lower { display: flex; align-items: center; gap: 14px; padding: 10px 16px; background: linear-gradient(90deg, color-mix(in srgb, var(--c) 55%, #071733), #071733 55%); border-top: 1px solid rgba(255,255,255,.08) }
.lower .ev { font-family: 'Amin', sans-serif; font-weight: 900; font-size: clamp(17px, 4cqw, 27px); color: #FFD36B }
.lower .who { display: grid; min-width: 0 }
.lower .who b { font-family: 'Amin', sans-serif; font-weight: 800; font-size: clamp(14px, 3cqw, 18px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.lower .who span { color: #C9D2E1; font-size: 12px }
.lower .min { margin-inline-start: auto; font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 22px; opacity: .9 }

.mic { position: absolute; z-index: 9; left: 10px; right: 10px; bottom: 10px; display: flex; align-items: center; gap: 12px; padding: 9px 13px; border-radius: 16px; background: linear-gradient(90deg, rgba(10,31,66,.94), rgba(7,23,51,.94)); border: 1px solid rgba(245,184,46,.35); box-shadow: 0 14px 30px rgba(0,0,0,.5); transform: translateY(140%); transition: transform .45s cubic-bezier(.2,.9,.25,1.1) }
.mic.on { transform: none }
.mic .m { width: 38px; height: 38px; flex: none; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle at 35% 30%, #FFD36B, #C08A0C) }
.mic .m svg { width: 19px; height: 19px }
.wave { display: flex; align-items: center; gap: 3px; height: 24px; flex: none }
/* The mic's bars grow by transform, not by height: no layout on every frame [X30]. */
.wave i { width: 3px; border-radius: 2px; background: #F5B82E; height: 100%; transform: scaleY(.3); animation: w .9s ease-in-out infinite }
.wave i:nth-child(2n) { animation-delay: -.3s } .wave i:nth-child(3n) { animation-delay: -.6s } .wave i:nth-child(5n) { animation-delay: -.15s }
@keyframes w { 50% { transform: scaleY(1) } }
.mic .tx { min-width: 0; display: grid; gap: 1px }
.mic .tx b { font-weight: 600; font-size: clamp(13px, 2.8cqw, 16px); line-height: 1.55 }
.mic .tx span { text-align: left; color: #FFD36B; font-size: 12px; font-weight: 600 }

.preview { position: absolute; inset: 0; z-index: 12; display: grid; align-content: center; justify-items: center; gap: 16px; padding: 16px; overflow-y: auto; background: radial-gradient(70% 60% at 50% 40%, rgba(245,184,46,.12), transparent 70%), linear-gradient(180deg, #0B2149, #050D1F) }
.plan { font-size: 14px; color: #C9D2E1; text-align: center }
.plan b { font-family: 'Barlow Condensed', sans-serif; font-size: 22px; color: #FFD36B }
.kick { font-family: 'Amin', sans-serif; font-weight: 700; color: #FFD36B; letter-spacing: .06em; font-size: 13px }
.teams { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: clamp(10px, 4cqw, 40px); width: min(100%, 720px) }
.team { display: grid; justify-items: center; gap: 6px; text-align: center; min-width: 0 }
.team .crest { width: clamp(64px, 15cqw, 116px) }
.team b { font-family: 'Amin', sans-serif; font-weight: 900; font-size: clamp(17px, 4.4cqw, 28px) }
.team small { color: #93A3BF; font-weight: 600 }
.vs { font-family: 'Barlow Condensed', sans-serif; font-style: italic; font-weight: 800; font-size: clamp(32px, 9cqw, 62px); color: #F5B82E; text-shadow: 0 0 24px rgba(245,184,46,.35) }
.stats { width: min(100%, 560px); display: grid; gap: 10px; padding: 12px 16px; border-radius: 16px; background: rgba(16,40,79,.86); border: 1px solid rgba(255,255,255,.09) }
.st { display: grid; grid-template-columns: 44px 1fr 44px; align-items: center; gap: 10px; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 20px; text-align: center }
.st > * { grid-row: 2 }
.st .lbl { grid-column: 1 / -1; grid-row: 1; font-family: 'IBM Plex Sans Arabic', sans-serif; font-size: 12px; color: #93A3BF; margin-bottom: -6px }
.st .bar { height: 6px; border-radius: 3px; background: rgba(255,255,255,.08); display: flex; overflow: hidden }
.st .bar i { display: block; height: 100% }
.keys { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; width: min(100%, 560px) }
.key { display: flex; align-items: center; gap: 10px; padding: 9px 12px; border-radius: 14px; background: rgba(16,40,79,.86); border: 1px solid rgba(255,255,255,.09); border-inline-start: 3px solid var(--c); min-width: 0 }
.key .no { font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 28px; color: var(--c); width: 32px; text-align: center }
.key b { font-family: 'Amin', sans-serif; font-size: 14px; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.key span span { color: #93A3BF; font-size: 12px }
.go { min-height: 50px; padding: 0 34px; border-radius: 14px; border: 0; font-family: 'Amin', sans-serif; font-weight: 800; font-size: 17px; color: #050D1F; background: linear-gradient(180deg, #FFD36B, #F5B82E); box-shadow: 0 10px 30px rgba(245,184,46,.35); cursor: pointer }
.go:focus-visible { outline: 3px solid #fff; outline-offset: 2px }
@container (max-width: 560px) { .keys { grid-template-columns: 1fr } }

/* Tension: the edges darken and pulse like a heartbeat until the kick. */
.moment.tense .mbox { box-shadow: 0 30px 80px rgba(0,0,0,.7), 0 0 0 2px rgba(239,68,68,.35); animation: beat 1.1s ease-in-out infinite }
.moment.tense::after { content: ''; position: absolute; inset: 0; pointer-events: none; background: radial-gradient(70% 70% at 50% 50%, transparent 55%, rgba(120,10,10,.45)); animation: beat 1.1s ease-in-out infinite }
@keyframes beat { 0%, 100% { opacity: 1 } 15% { opacity: .65 } 30% { opacity: 1 } 45% { opacity: .8 } }

.replay { position: absolute; top: 10px; inset-inline-start: 10px; padding: 3px 10px; border-radius: 6px; font-weight: 800; font-size: 13px; color: #fff; background: rgba(0,0,0,.55); border: 1px solid rgba(255,255,255,.35); letter-spacing: .5px; pointer-events: none }
.party { position: absolute; inset: 0 0 auto; aspect-ratio: 640 / 340; overflow: hidden; pointer-events: none }
/* [Sprint 30 Q8] The confetti falls from under the headline band (its top 64 of 300), never over «هدف!» (it hid the «ه», «فد»). */
.party i { position: absolute; top: 22%; width: 8px; height: 13px; border-radius: 2px; animation: fall linear forwards; will-change: transform }
/* Falling by transform, not by top: no layout on every frame [X30]. */
@keyframes fall { to { transform: translate3d(30px, 420px, 0) rotate(540deg) } }
.party .burst { position: absolute; left: 50%; bottom: 10%; transform: translateX(-50%); display: grid; justify-items: center; padding: 6px 18px; border-radius: 12px; background: color-mix(in srgb, var(--c) 80%, #071733); border: 2px solid #F5B82E; box-shadow: 0 10px 30px rgba(0,0,0,.5); animation: burst .6s cubic-bezier(.2,.9,.25,1.4) .35s both }
.party .burst b { font-family: 'Amin', sans-serif; font-weight: 900; font-size: clamp(16px, 4cqw, 26px); white-space: nowrap }
.party .burst small { color: #FFD36B; font-weight: 700; font-size: 12px }
@keyframes burst { from { opacity: 0; transform: translateX(-50%) scale(.4) } }

.reacts { position: absolute; inset: 0; z-index: 11; pointer-events: none; overflow: hidden }
.rx { position: absolute; bottom: 70px; display: flex; align-items: center; gap: 6px; padding: 4px 12px 4px 6px; border-radius: 999px; background: rgba(7,23,51,.9); border: 1px solid color-mix(in srgb, var(--c) 70%, #fff); box-shadow: 0 8px 22px rgba(0,0,0,.45); animation: rise 3.2s ease-out forwards }
.rx.home { right: var(--x) }
.rx.away { left: var(--x) }
.rx .e { font-size: 30px; line-height: 1 }
.rx .t { display: grid; font-family: 'Amin', sans-serif; font-weight: 800; font-size: 14px; line-height: 1.25 }
.rx .t small { color: #93A3BF; font-size: 11px; font-weight: 600 }
@keyframes rise { 0% { opacity: 0; transform: translateY(20px) scale(.6) } 12% { opacity: 1; transform: translateY(0) scale(1.08) } 20% { transform: scale(1) } 80% { opacity: 1 } 100% { opacity: 0; transform: translateY(-160px) } }
.rx-leave-active { transition: opacity .3s }
.rx-leave-to { opacity: 0 }

/* While a scene plays, what is under its dark glass stands still, so the glass is not blurred afresh every frame [X30]. */
.mc.scene .atmo::before, .mc.scene .wave i, .mc.scene .live i::after { animation-play-state: paused }
/* The smooth mode for weak phones [X30]: solid panels instead of blurred glass, no moving beams, lighter shadows. */
.smooth .atmo::before { display: none }
.smooth .sb-in { background: rgba(16,40,79,.94); box-shadow: 0 8px 18px rgba(0,0,0,.35) }
.smooth .card { background: #10284F; box-shadow: none }
.smooth .card.goal { background: linear-gradient(100deg, #4a3a12, #10284F 60%) }
.smooth .mic { background: #0A1F42 }
.smooth .moment::before { background: rgba(3,8,20,.9) }
.smooth .crest { filter: none }
.smooth .node { box-shadow: none }
.smooth .tl { mask-image: none }
.smooth .row-enter-active { transition: opacity .3s }
.smooth .row-enter-from { transform: none }
.smooth .mbox { box-shadow: 0 12px 30px rgba(0,0,0,.6) }
@media (prefers-reduced-motion: reduce) { .moment.on .mbox::after { animation: none; opacity: 0 } .clockface.frozen .strap span, .clockface .onair i, .live.frozen, .atmo::before, .wave i, .live i::after, .moment.tense .mbox, .moment.tense::after, .party i { animation: none } .party i { display: none } }
</style>
