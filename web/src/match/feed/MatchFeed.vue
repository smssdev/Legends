<template>
  <div ref="host" class="mc theme-night" :class="{ smooth, scene: sceneOn }" dir="rtl" :style="{ '--H': kits.home.kit, '--A': kits.away.kit }">
    <div class="atmo" aria-hidden="true" />

    <div class="sb">
      <div class="sb-in">
        <div class="side" :style="{ '--c': kits.home.kit }"><span class="crest" v-html="crestOf('home')" /><span class="nm"><b>{{ $nm(clubs.home) }}</b><small>{{ coachLine('home') }}</small></span></div>
        <div class="mid"><span class="score" :class="{ pop }" dir="ltr"><FlipNumber :value="score.away" /> - <FlipNumber :value="score.home" /></span><span class="live" dir="ltr"><i />{{ clock || minute }}</span></div>
        <div class="side away" :style="{ '--c': kits.away.kit }"><span class="crest" v-html="crestOf('away')" /><span class="nm"><b>{{ $nm(clubs.away) }}</b><small>{{ coachLine('away') }}</small></span></div>
      </div>
      <div class="mom" dir="ltr"><i :style="{ width: 100 - mom + '%', background: kits.away.kit }" /><i :style="{ width: mom + '%', background: kits.home.kit }" /></div>
    </div>

    <!-- [X35] The whole match on a pitch seen from above: all 22 and the ball moving through every minute from the
         server's keyframes, never only the key moments. -->
    <div class="pitch">
      <div ref="pitchHost" class="pitch-in" aria-hidden="true" />
      <span v-if="replaying && !sceneOn" class="replay">{{ replayAngle === 2 ? $t('إعادة · زاوية أخرى') : $t('إعادة') }}</span>
      <button type="button" class="cam" :aria-label="camera === 'tv' ? $t('عرض الخطة من أعلى') : $t('كاميرا البث')" @click="setCamera(camera === 'tv' ? 'top' : 'tv')">{{ camera === 'tv' ? $t('الخطة') : $t('البث') }}</button>
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
import { ICON, SCENES, crest, keeperKit, officialKit, setKits, setRain, setSmooth } from './art'
import { figure } from './figure'
import { noteFrame, smooth, tier } from '../perf'
import { sample } from '../frames'
import { SCENE_TIME, story } from './story'
import { director } from './director'
import { pitchActions } from './actions'
import { voiceLine, type Lang } from '../voice'

const props = defineProps<{ kits: any; clubs: { home: string; away: string }; codes: { home: string; away: string }; logos?: { home?: string | null; away?: string | null }; strength: { home: number; away: number }; coaches: any; teams: any; seed: number; kickoff?: string | null; looks?: Partial<Record<'home' | 'away', string>> | null; speed: number; minute: string; score: { home: number; away: number }; mine: string | null; lang: Lang | 'off'; intro: boolean; live: boolean; countdown: number }>()
const emit = defineEmits<{ cue: [name: string]; sound: [name: string]; say: [line: any]; near: [closeness: number]; introDone: [] }>()

const host = ref<HTMLElement>(), stage = ref<HTMLElement>(), pitchHost = ref<HTMLElement>()
// [X35] The live pitch's camera: the broadcast's (the cartoon players, following the ball) or the plan from above.
const camera = ref((() => { try { return localStorage.getItem('legends.camera') === 'top' ? 'top' : 'tv' } catch { return 'tv' } })())
function setCamera(c) { camera.value = c; try { localStorage.setItem('legends.camera', c) } catch {} ; buildPitch(); if (plan) drawPitch(plan.tick, 0) }
// [X35] The broadcast clock, minutes and seconds running through each minute as on TV ('' between minutes: the parent's).
const clock = ref('')
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
// [Sprint 34 V4] The goal's replay is playing on the live pitch (0 no; 1 or 2: its angle, Sprint 36 F4).
let pitchReplay = 0
// [Sprint 36 F4] The replay's angle (1, then 2 at the full tier), and the frame that turns the scene round for it.
const replayAngle = ref(1)
let angleWrap: any = null
// [Sprint 35 C1] The minute's own scene (for its replay) and the cutaway playing now.
let mainScene: any = null, cutScene: any = null
let raf = 0, last = 0, t = 0, plan: any = null, scene: any = null, keySeq = 0, drawn = 0, pitchDrawn = 0
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
    sceneAt = performance.now()
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
  sceneOn.value = false
  replaying.value = false
  pitchReplay = 0
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
  penalty: [[0.05, 'whistle-long'], [0.2, 'heart'], [0.3, 'heart'], [0.4, 'heart'], ['key', 'kick'], ['key', 'roar']], freekick: [[0.05, 'whistle'], [0.25, 'heart'], [0.37, 'heart'], ['key', 'kick'], ['key', 'roar']],
  card: [[0.05, 'whistle'], ['key', 'murmur']], var: [[0.32, 'kick'], [0.37, 'roar'], [0.52, 'whistle'], ['key', 'whistle'], ['key', 'groan']], offside: [['key', 'whistle']], corner: [[0.35, 'kick'], ['key', 'kick']], whistle: [[0.1, 'whistle']], sub: [[0.1, 'beep']], board: [[0.1, 'beep']], injury: [[0.1, 'whistle']],
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
  if (plan) {
    t = plan.startAt === null ? t + dt : Math.max(0, (now - plan.startAt) / 1000)
    const { s, total, sceneT, rate, fired } = plan
    tickClock(plan.tick, Math.min(1, t / total))
    if (!pitchReplay && (!smooth.value || now - pitchDrawn >= 32)) { pitchDrawn = now; drawPitch(plan.tick, Math.min(1, t / total)) }
    const fire = (k, fn) => { if (!fired.has(k)) { fired.add(k); fn() } }
    // A line or a sound long past (the screen joined late) is dropped, not played out of time.
    const cue = (k, at, fn) => fire(k, () => t - at < 0.6 && fn())
    // The scene follows the clock, so drawing it 30 times a second in the smooth mode only skips frames, never time.
    if (scene && t < sceneT && (!smooth.value || now - drawn >= 32)) { drawn = now; draw(t * rate) }
    const keyT = s.keyAt * sceneT
    // Commentary: line times are fractions of the scene (or of the minute when there is none).
    for (const [i, l] of s.lines.entries()) { const at = l.at * (sceneT || total * 0.5); if (t >= at) cue('l' + i, at, () => props.lang !== 'off' && emit('say', voiceLine(props.lang, l, players.value, props.clubs))) }
    for (const [i, [at, name]] of (SOUNDS[s.scene] ?? []).entries()) { const when = at === 'key' ? keyT : at * sceneT; if (t >= when) cue('s' + i, when, () => emit('sound', name)) }
    if (s.scene === 'miss' && s.data.how === 'post' && t >= keyT) cue('post', keyT, () => emit('sound', 'post'))
    if (t >= keyT) fire('key', () => { revealed.value = true; tense.value = false })
    if (s.goal && t >= keyT) fire('goal', () => {
      cheerAt = performance.now()
      emit('cue', 'goal'); shake.value = true; setTimeout(() => (shake.value = false), 500)
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
      // [Sprint 34 V4] At the middle and full tiers the replay is the live pitch itself: the last Keyframes before the
      // ball went in, slower and closer, then back. The lowest tier has no replay (Sprint 33 Q1).
      const frames = plan.tick?.frames ?? []
      let g = 0
      frames.forEach((x, n) => { if (Math.abs(x.b[0] - 525) > Math.abs(frames[g].b[0] - 525)) g = n })
      const onPitch = frames.length > 2 && Math.abs(frames[g].b[0] - 525) > 470
      if (u < len) {
        fire('replay', () => {
          bubbleOn.value = false; replaying.value = true; sceneOn.value = !onPitch; pitchReplay = onPitch ? 1 : 0
          if (!onPitch && mainScene) {
            scene = mainScene; stage.value.replaceChildren(mainScene.svg)
            // The scene's world in a frame the second angle can turn round.
            const w = mainScene.svg.world
            if (w && !angleWrap) { angleWrap = document.createElementNS('http://www.w3.org/2000/svg', 'g'); w.parentNode.insertBefore(angleWrap, w); angleWrap.appendChild(w) }
          }
        })
        // [Sprint 36 F4] Two angles at the full tier: halfway through, the director cuts to the reverse angle, closer
        // (the scene turned round about the goal; on the live pitch, a tighter camera).
        const angle = tier.value === 'high' && (u - (rp.off ?? 0)) / Math.max(0.01, len - (rp.off ?? 0)) > 0.5 ? 2 : 1
        if (angle !== replayAngle.value) {
          replayAngle.value = angle
          if (onPitch) pitchReplay = angle
          else if (angleWrap) angleWrap.setAttribute('transform', angle === 2 ? 'translate(320 130) scale(-1.3 1.3) translate(-320 -130)' : '')
        }
        if (onPitch) {
          const n = frames.length - 1, from = Math.max(0, g - 3) / n, to = Math.min(1, (g + 0.4) / n)
          if (!smooth.value || now - pitchDrawn >= 32) { pitchDrawn = now; drawPitch(plan.tick, from + (to - from) * (u / len)) }
        } else if (!smooth.value || now - drawn >= 32) { drawn = now; draw(u) }
      } else fire('replay-end', () => { replaying.value = false; sceneOn.value = false; pitchReplay = 0; replayAngle.value = 1; showBubble() })
    }
    // The commentator's bubble leaves before the minute ends: a calm pause on the timeline before the next scene.
    if (!plan.replay && t >= (scene ? Math.min(total, sceneT + plan.cutT + 2.8) : total)) fire('done', () => { bubbleOn.value = false })
  }
}

// ---------------------------------------------------------------- the live pitch and the clock [X35]
// [Sprint 31 P1] The live pitch is one canvas (it was SVG, hundreds of attributes a frame): the broadcast camera and
// the plan from above are painted afresh every frame, nearer things over farther ones. The look is the same.
let cv: HTMLCanvasElement | null = null, ctx: CanvasRenderingContext2D | null = null, cw = 0, ch = 0, dpr = 1
let topBg: HTMLCanvasElement | null = null, dots = new Map(), lastTick = null, lastU = 0
// The canvas follows its box and the screen's density: at most 2 pixels a point, 1.5 at the middle tier and 1 at the
// lowest (a quarter of the pixels to paint) [Sprint 33 Q1].
function fit() {
  if (!cv || !pitchHost.value) return false
  const r = pitchHost.value.getBoundingClientRect(), d = Math.min(tier.value === 'low' ? 1 : tier.value === 'mid' ? 1.5 : 2, window.devicePixelRatio || 1)
  const w = Math.max(1, Math.round(r.width * d)), h = Math.max(1, Math.round(r.height * d))
  if (w !== cw || h !== ch || d !== dpr) { cw = cv.width = w; ch = cv.height = h; dpr = d; topBg = null }
  return true
}
function buildCanvas() {
  if (!pitchHost.value) return
  cv = document.createElement('canvas')
  cv.style.width = '100%'; cv.style.height = '100%'; cv.style.display = 'block'
  ctx = cv.getContext('2d', { alpha: false })
  pitchHost.value.replaceChildren(cv)
  cw = ch = 0; topBg = null; dots = new Map(); tvPlayers = new Map()
  fit()
}
let resizer: ResizeObserver | null = null
onMounted(() => {
  if (typeof ResizeObserver !== 'undefined' && pitchHost.value) { resizer = new ResizeObserver(() => { if (fit()) drawPitch(lastTick, lastU) }); resizer.observe(pitchHost.value) }
  // The numbers are painted once into each player's sprite: once the match's fonts arrive, they are painted again.
  document.fonts?.ready.then(() => { tvPlayers = new Map(); dots = new Map(); for (const k in boards) delete boards[k]; tvBg = null })
})
onBeforeUnmount(() => resizer?.disconnect())

// The plan from above: the pitch in a 1090 x 720 box around it (as the SVG's viewBox), shown whole.
function topView() { const s = Math.min(cw / 1090, ch / 720); return { s, ox: (cw - 1090 * s) / 2 + 20 * s, oy: (ch - 720 * s) / 2 + 20 * s } }
function paintTopBg() {
  const { s, ox, oy } = topView()
  topBg = document.createElement('canvas'); topBg.width = cw; topBg.height = ch
  const c = topBg.getContext('2d')
  c.fillStyle = '#1a7d44'; c.fillRect(0, 0, cw, ch)
  c.setTransform(s, 0, 0, s, ox, oy)
  for (let i = 0; i < 10; i++) { c.fillStyle = i % 2 ? '#1d8a4b' : '#23994f'; c.fillRect(i * 105, 0, 105, 680) }
  c.strokeStyle = 'rgba(255,255,255,.55)'; c.lineWidth = 4
  c.strokeRect(0, 0, 1050, 680)
  c.beginPath(); c.moveTo(525, 0); c.lineTo(525, 680); c.stroke()
  c.beginPath(); c.arc(525, 340, 91, 0, Math.PI * 2); c.stroke()
  for (const x of [0, 1050]) {
    const d = x ? -1 : 1
    c.strokeRect(x ? x - 165 : 0, 138, 165, 404); c.strokeRect(x ? x - 55 : 0, 248, 55, 184)
    c.strokeStyle = '#fff'; c.strokeRect(x ? x : -18, 303, 18, 74); c.strokeStyle = 'rgba(255,255,255,.55)'
    c.fillStyle = 'rgba(255,255,255,.7)'; c.beginPath(); c.arc(x + d * 110, 340, 4, 0, Math.PI * 2); c.fill()
  }
}
// A player's disc with his number, drawn once.
function dotFor(id, side) {
  let d = dots.get(id)
  if (!d) {
    const k = props.kits[side], R = 2
    d = document.createElement('canvas'); d.width = d.height = 50 * R
    const c = d.getContext('2d')
    c.scale(R, R); c.translate(25, 25)
    c.fillStyle = k.kit; c.beginPath(); c.arc(0, 0, 22, 0, Math.PI * 2); c.fill()
    c.strokeStyle = k.trim || '#fff'; c.lineWidth = 3; c.stroke()
    c.fillStyle = k.ink || '#fff'; c.font = '800 22px "Barlow Condensed", sans-serif'; c.textAlign = 'center'
    c.fillText(String(players.value[id]?.no ?? ''), 0, 8)
    dots.set(id, d)
  }
  return d
}
function drawTop(tick, u) {
  if (!ctx || !fit()) return
  if (!topBg) paintTopBg()
  ctx.setTransform(1, 0, 0, 1, 0, 0)
  ctx.drawImage(topBg, 0, 0)
  const f = tick?.frames
  if (!f?.length) return
  const { s, ox, oy } = topView()
  ctx.setTransform(s, 0, 0, s, ox, oy)
  // [Sprint 31 M1] The shared curve between the keyframes (frames.ts), with the long ball's arc.
  const R = sample(f, u)
  for (const id in R.players) {
    const side = players.value[id]?.side
    if (!side) continue
    const [x, y] = R.players[id]
    ctx.drawImage(dotFor(id, side), x - 25, y - 25, 50, 50)
  }
  // [Sprint 31 D1] The officials: small discs in their colour.
  for (const o of R.officials ?? []) { ctx.fillStyle = officialKit(); ctx.strokeStyle = '#F5B82E'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(o[0], o[1], 13, 0, Math.PI * 2); ctx.fill(); ctx.stroke() }
  const [bx, by, bz] = R.ball, h = Math.min(1, bz / 60)
  // [Sprint 31 M2] The ball's shadow stays on the grass, smaller and fainter the higher it flies.
  ctx.fillStyle = `rgba(0,0,0,${(0.35 * (1 - h * 0.6)).toFixed(3)})`
  ctx.beginPath(); ctx.ellipse(bx + h * 10, by + 6, 9 * (1 - h * 0.5), 5 * (1 - h * 0.5), 0, 0, Math.PI * 2); ctx.fill()
  ctx.fillStyle = '#fff'; ctx.strokeStyle = '#111'; ctx.lineWidth = 2
  ctx.beginPath(); ctx.arc(bx, by - bz * 0.6, 8 + bz * 0.08, 0, Math.PI * 2); ctx.fill(); ctx.stroke()
}
// The broadcast camera [X35]: the pitch in perspective as the main TV camera sees it from the stand, panning with the
// ball, and the cartoon players (figure.ts, as art.ts's) running between the server's keyframes.
const TV = { far: 64, near: 292, span: 620 }
let refs = [], camX = 525, tvPlayers = new Map(), tvBg: HTMLCanvasElement | null = null, tvCam = -1, tvZoom = 0, tvFy = 0, zoom = 1, lead = 0, sceneAt = -1e9, cheerAt = -1e9, camFy = 180, lightCv: HTMLCanvasElement | null = null, lightKey = ''
const depth = (y) => Math.max(0, Math.min(1, y / 680))
const proj = (x, y) => { const d = depth(y), k = (640 / TV.span) * (0.62 + 0.38 * d); return [320 + (x - camX) * k, TV.far + (TV.near - TV.far) * d, 0.5 + 0.5 * d] }
// The 640 x 300 picture covers the box (as the SVG's "slice").
// [Sprint 32 V2] A box wider than the picture (a computer) shows more of the pitch across instead of cutting the
// stand and the near touchline off: the picture fits its height and runs on to the sides.
function tvView() { const s = cw / ch > 640 / 300 ? ch / 300 : Math.max(cw / 640, ch / 300); return { s, ox: (cw - 640 * s) / 2, oy: (ch - 300 * s) / 2 } }
// [Sprint 31 C2] Night or day from the hour in Cairo (the game's schedule zone) when the match plays: the same on
// every screen watching it together. Night from 18:00 to 05:59, under the floodlights.
// [Sprint 32 V3] The hour of its kick-off when the server sends it (a replay keeps its own light), else now.
function cairoHour() {
  const at = props.kickoff ? new Date(props.kickoff) : new Date()
  try { return Number(new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Cairo', hour: 'numeric', hourCycle: 'h23' }).format(isNaN(+at) ? new Date() : at)) } catch { return 20 }
}
let night = true
const LOOK = {
  night: { sky: '#0B1D2E', rows: ['#14304A', '#183A57'], grass: ['#1d8a4b', '#23994f'], tint: 'rgba(7,23,51,.18)' },
  day: { sky: '#7FB3D9', rows: ['#2C4A6B', '#35587D'], grass: ['#2a9a52', '#33aa5c'], tint: 'rgba(255,236,190,.06)' },
}
function paintTvPitch(c) {
  const L = night ? LOOK.night : LOOK.day
  c.fillStyle = rainy() ? '#33414F' : L.sky; c.fillRect(-900, -200, 2440, 700)
  // The stand behind the far touchline (its crowd is drawn every frame, crowd()).
  for (let r = 0; r < 4; r++) { c.fillStyle = L.rows[r % 2]; c.fillRect(-900, 8 + r * 13, 2440, 11) }
  c.fillStyle = '#0A1A2B'; c.fillRect(-900, 52, 2440, 12)
  const quad = (x0, x1, y0, y1, fill) => { const a = proj(x0, y0), b = proj(x1, y0), d = proj(x1, y1), e = proj(x0, y1); c.fillStyle = fill; c.beginPath(); c.moveTo(a[0], a[1]); c.lineTo(b[0], b[1]); c.lineTo(d[0], d[1]); c.lineTo(e[0], e[1]); c.closePath(); c.fill() }
  // The grass around the pitch, then the mown stripes, and finer cuts across them.
  quad(-900, 1950, -40, 680 + 400, L.grass[0])
  for (let i = 0; i < 10; i++) quad(i * 105, i * 105 + 105, 0, 680, L.grass[i % 2])
  if (rainy()) quad(-900, 1950, -40, 1080, 'rgba(10,30,40,.18)')
  for (let j = 0; j < 8; j++) if (j % 2) quad(0, 1050, j * 85, j * 85 + 85, 'rgba(255,255,255,.035)')
  // [Sprint 31 C3] The advertising boards along the far touchline: LEGENDS, navy and gold.
  const [b0x, b0y] = proj(-700, -26), [b1x] = proj(1750, -26), bh = 7
  c.fillStyle = '#071733'; c.fillRect(b0x, b0y - bh, b1x - b0x, bh)
  c.fillStyle = '#F5B82E'; c.fillRect(b0x, b0y - 1, b1x - b0x, 1)
  for (let x = -640; x <= 1700; x += 120) { const [px] = proj(x, -26); c.drawImage(boardSprite((x + 40) / 120 % 2 ? '#F5B82E' : '#FFFFFF'), px - 16, b0y - 7, 32, 6) }
  c.strokeStyle = 'rgba(255,255,255,.7)'; c.lineWidth = 1.6
  const line = (pts) => { c.beginPath(); pts.forEach(([x, y], i) => { const [px, py] = proj(x, y); i ? c.lineTo(px, py) : c.moveTo(px, py) }); c.stroke() }
  line([[0, 0], [1050, 0], [1050, 680], [0, 680], [0, 0]]); line([[525, 0], [525, 680]])
  line(Array.from({ length: 33 }, (_, i) => [525 + 91 * Math.cos(i * Math.PI / 16), 340 + 91 * Math.sin(i * Math.PI / 16)]))
  for (const [x, d] of [[0, 1], [1050, -1]]) {
    line([[x, 138], [x + d * 165, 138], [x + d * 165, 542], [x, 542]]); line([[x, 248], [x + d * 55, 248], [x + d * 55, 432], [x, 432]])
  }
  // [Sprint 34 V5] The stadium's details: the dugouts before the far stand with the substitutes in their kits, the
  // photographers crouched behind each goal line, and the four corner flags.
  for (const [side, x0] of [['home', 360], ['away', 600]]) {
    const [l, ty] = proj(x0, -34), [r] = proj(x0 + 90, -34)
    c.fillStyle = 'rgba(200,215,235,.35)'; c.fillRect(l, ty - 9, r - l, 2)
    c.fillStyle = '#0B1626'; c.fillRect(l, ty - 7, r - l, 7)
    c.fillStyle = props.kits[side]?.kit ?? '#fff'
    for (let k = 0; k < 7; k++) c.fillRect(l + 3 + k * (r - l - 6) / 7, ty - 5, 2.4, 3.2)
  }
  for (const [x, d] of [[0, -1], [1050, 1]]) for (let k = 0; k < 6; k++) {
    const [px, py, ps] = proj(x + d * 22, 170 + k * 68)
    c.fillStyle = '#121A28'; c.beginPath(); c.ellipse(px, py - 3 * ps, 2.6 * ps, 3.4 * ps, 0, 0, Math.PI * 2); c.fill()
    c.fillStyle = '#2A3446'; c.fillRect(px - 1.4 * ps, py - 6 * ps, 2.8 * ps, 1.6 * ps)
  }
  for (const [x, y] of [[0, 0], [1050, 0], [0, 680], [1050, 680]]) {
    const [px, py, ps] = proj(x, y), h = 12 * ps
    c.strokeStyle = '#F7F4EA'; c.lineWidth = 0.9; c.beginPath(); c.moveTo(px, py); c.lineTo(px, py - h); c.stroke()
    c.fillStyle = '#F5B82E'; c.beginPath(); c.moveTo(px, py - h); c.lineTo(px + 5 * ps, py - h + 2 * ps); c.lineTo(px, py - h + 4 * ps); c.closePath(); c.fill()
  }
}
// [Sprint 34 V5] The photographers' flashes when the play is dangerous or a goal has gone in (the same moments on
// every screen: from the clock of the page only for which camera flickers, never for what happens).
function flashes(c, now) {
  const hot = danger >= 3 || now - cheerAt < 2500
  if (!hot || smooth.value) return
  for (const [x, d] of [[0, -1], [1050, 1]]) for (let k = 0; k < 6; k++) {
    if (((Math.floor(now / 90) * 7 + k * 13 + x) % 23) !== 0) continue
    const [px, py, ps] = proj(x + d * 22, 170 + k * 68)
    c.fillStyle = 'rgba(255,255,255,.95)'; c.beginPath(); c.arc(px, py - 6 * ps, 2.2 * ps, 0, Math.PI * 2); c.fill()
    c.fillStyle = 'rgba(255,255,255,.25)'; c.beginPath(); c.arc(px, py - 6 * ps, 6 * ps, 0, Math.PI * 2); c.fill()
  }
}
// The word on the boards, painted once per colour (text is the slowest thing a canvas draws).
const boards = {}
function boardSprite(colour) {
  if (boards[colour]) return boards[colour]
  const b = document.createElement('canvas'); b.width = 128; b.height = 24
  const c = b.getContext('2d'); c.fillStyle = colour; c.font = '800 22px "Barlow Condensed", sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText('LEGENDS', 64, 13)
  return (boards[colour] = b)
}
// [Sprint 32 V2] One match in six is played in the rain: its streaks fall in front of everything.
const rainy = () => (Number(props.seed) || 0) % 6 === 1
let drops = [], dropsFor = ''
function rain(c, now) {
  const key = `${props.seed}|${tier.value}`
  if (key !== dropsFor) {
    dropsFor = key
    let r = (Number(props.seed) || 1) * 7 + 3
    const rnd = () => { r = (r * 1103515245 + 12345) & 0x7fffffff; return r / 0x7fffffff }
    drops = Array.from({ length: tier.value === 'low' ? 40 : tier.value === 'mid' ? 80 : 120 }, () => ({ x: rnd(), y: rnd(), v: 0.6 + rnd() * 0.5 }))
  }
  c.save(); c.setTransform(1, 0, 0, 1, 0, 0)
  c.strokeStyle = 'rgba(200,215,235,.35)'; c.lineWidth = Math.max(1, cw / 900); c.beginPath()
  for (const d of drops) {
    const y = ((d.y + now * 0.0012 * d.v) % 1) * ch, x = ((d.x + now * 0.0002) % 1) * cw
    c.moveTo(x, y); c.lineTo(x - cw * 0.004, y + ch * 0.05)
  }
  c.stroke(); c.restore()
}
// [Sprint 31 C3] The crowd: dots in the home side's colours (the away fans in a corner), the same seats on every screen
// (from the match's seed). They sway with the danger of the minute and jump at a goal.
let fans = [], fansFor = ''
function seatFans() {
  const key = `${props.seed}|${props.kits.home.kit}|${props.kits.away.kit}|${tier.value}|${props.strength?.home}`
  if (key === fansFor) return
  fansFor = key
  let r = (props.seed | 0) || 1
  const rnd = () => { r = (r * 1103515245 + 12345) & 0x7fffffff; return r / 0x7fffffff }
  const H = [props.kits.home.kit, props.kits.home.trim || '#fff'], A = [props.kits.away.kit, props.kits.away.trim || '#fff']
  // [Sprint 32 V2] As full as the home side is big: a strong club's stand is packed, a small one's half empty.
  const fill = Math.max(0.5, Math.min(1, 0.4 + (props.strength?.home ?? 6000) / 10000 * 0.6))
  const n = Math.round((tier.value === 'low' ? 260 : tier.value === 'mid' ? 500 : 900) * fill)
  fans = Array.from({ length: n }, (_, i) => {
    const x = -700 + rnd() * 2450, row = Math.floor(rnd() * 4), away = x > 1000 && rnd() < 0.8
    const pick = rnd(), colour = pick < 0.12 ? '#C9D2E1' : pick < 0.2 ? '#0A1F42' : (away ? A : H)[pick < 0.65 ? 0 : 1]
    return { x, y: 10 + row * 13 + rnd() * 8, c: colour, ph: rnd() * 6.28, w: 1.6 + rnd() * 0.8 }
  }).sort((a, b) => (a.c < b.c ? -1 : a.c > b.c ? 1 : 0))
}
let danger = 0, viewL = 0, viewR = 640
function crowd(c, now) {
  seatFans()
  const sway = smooth.value ? 0 : 0.15 + danger * 0.35, jump = Math.max(0, 1 - (now - cheerAt) / 2600) * 4
  // One path per colour (the fans are seated sorted by it): a few fills a frame, not hundreds.
  let colour = ''
  for (const f of fans) {
    if (f.c !== colour) { if (colour) c.fill(); colour = f.c; c.fillStyle = colour; c.beginPath() }
    // The stand is a little farther than the far touchline: it pans a little slower than the pitch.
    const sx = 320 + (f.x - camX) * (640 / TV.span) * 0.58
    if (sx < viewL - 4 || sx > viewR + 4) continue
    const dy = Math.sin(now * 0.006 + f.ph) * sway - Math.abs(Math.sin(now * 0.014 + f.ph)) * jump
    c.rect(sx, f.y + dy, f.w, f.w * 1.3)
  }
  if (colour) c.fill()
}
// The goals stand up from the line: drawn with the players, so one in front of them covers them.
// [Sprint 32 V1] Each with its net behind it, which ripples when the ball goes in.
let netHit = { 0: -1e9, 1050: -1e9 }
function goalAt(c, x, now = 0) {
  const d = x ? 1 : -1, back = x + d * 20
  const [p1x, p1y, s1] = proj(x, 303), [p2x, p2y, s2] = proj(x, 377)
  const shake = Math.max(0, 1 - (now - netHit[x]) / 900), w = Math.sin(now / 45) * 3 * shake
  const [b1x, b1y] = proj(back, 309), [b2x, b2y] = proj(back, 371)
  const B1 = [b1x + d * w, b1y - 16 * s1], B2 = [b2x + d * w, b2y - 16 * s2]
  // The smooth mode leaves the netting out.
  if (!smooth.value) {
  c.strokeStyle = 'rgba(230,236,245,.45)'; c.lineWidth = 0.6; c.beginPath()
  for (let j = 0; j <= 6; j++) {
    const t = j / 6
    // Lines across the back and down from the bar to the ground at the back.
    c.moveTo(p1x + (p2x - p1x) * t, p1y - 22 * s1 + (p2y - 22 * s2 - p1y + 22 * s1) * t); c.lineTo(B1[0] + (B2[0] - B1[0]) * t, B1[1] + (B2[1] - B1[1]) * t)
    c.moveTo(B1[0] + (B2[0] - B1[0]) * t, B1[1] + (B2[1] - B1[1]) * t); c.lineTo(b1x + (b2x - b1x) * t, b1y + (b2y - b1y) * t)
  }
  for (let j = 0; j <= 3; j++) { const t = j / 3; c.moveTo(B1[0], B1[1] + (b1y - B1[1]) * t); c.lineTo(B2[0], B2[1] + (b2y - B2[1]) * t) }
  c.stroke()
  }
  c.strokeStyle = '#fff'; c.lineWidth = 2.4; c.beginPath(); c.moveTo(p1x, p1y); c.lineTo(p1x, p1y - 22 * s1); c.lineTo(p2x, p2y - 22 * s2); c.lineTo(p2x, p2y); c.stroke()
}
function tvFor(id, side) {
  let t = tvPlayers.get(id)
  if (!t) {
    const info = (props.teams?.[side]?.players ?? []).find((p) => String(p.id) === String(id))
    const gk = info?.pos === 'GK'
    const kit = gk ? keeperKit(side) : props.kits[side].kit
    // [Sprint 31 D2] Build and height from his id (README 7.3): the same player looks the same on every screen.
    const n = Number(id) || 0
    // [Sprint 34 V3] His surname on his back, and the captain's armband.
    const surname = String(info?.name ?? '').trim().split(/\s+/).slice(-1)[0], captain = String(props.teams?.[side]?.captain ?? '') === String(id)
    const f = figure(kit, info?.no ?? '', { look: n % 42, gloves: gk ? '#E4FF5A' : undefined, trim: props.kits[side].trim, pattern: gk ? null : props.kits[side].pattern, name: surname, captain, build: (n * 7) % 3, tall: 0.94 + ((n * 13) % 13) / 100, hair: (n * 11 + 3) % 5 })
    t = { f, ph: Number(id) % 7, sx: 0, sy: 0, scale: 1, bob: 0, face: 'back', mirror: 1, lean: 0 }
    tvPlayers.set(id, t)
  }
  return t
}
// [Sprint 31 M4] Which way a player faces from where he goes on the pitch (dx, dy in decimetres): to his side when
// he runs across, his back when he runs towards the far touchline, his face when he comes towards the camera. A
// little hysteresis, so he does not flicker between two near a diagonal.
function facing(t, dx, dy) {
  const ax = Math.abs(dx), ay = Math.abs(dy) * 1.4
  const side = t.face === 'side' ? ax > ay * 0.8 : ax > ay * 1.3
  if (side) { t.face = 'side'; t.mirror = dx < 0 ? -1 : 1 } else t.face = dy < 0 ? 'back' : 'front'
}
// [Sprint 32 A1, A2] The moves this instant from the Keyframes, drawing only: who strikes the ball as it leaves him
// (a header when it is in the air), who heads it as it reaches him high, who slides in to take it from the other side
// (one turnover in three, chosen by the minute and the Keyframe, so every screen shows the same), the keeper of the
// goal a shot flies at, and the scoring side once the ball is in. And their sounds, once each, while no scene covers
// the pitch.
let gks = new Set<string>(), gksFor = null, heard = new Set(), heardTick = -1
function actions(tick, f, u) {
  if (gksFor !== props.teams) { gksFor = props.teams; gks = new Set(['home', 'away'].flatMap((s) => (props.teams?.[s]?.players ?? []).filter((p) => p.pos === 'GK').map((p) => String(p.id)))) }
  if (heardTick !== tick.tick) { heardTick = tick.tick; heard = new Set() }
  const out = pitchActions(tick, f, u, { gks, sideOf: (id) => players.value[id]?.side })
  for (const [key, name] of out.sounds) if (!heard.has(key)) { heard.add(key); if (!sceneOn.value) emit('sound', name) }
  return out
}
// [Sprint 33 L3] Where each player was last drawn (for the one taken off), and how much of the minute a substitution's
// walk takes.
const lastSeen = new Map(), SUB_WALK = 0.45
// [Sprint 34 K4] Each player's pace and fitness now (the minute's teams, else the match's), by id.
let fitFor = null, fitMap = new Map()
function fitness(tick) {
  const teams = tick?.teams ?? props.teams
  if (teams === fitFor) return fitMap
  fitFor = teams; fitMap = new Map()
  for (const side of ['home', 'away']) for (const p of teams?.[side]?.players ?? []) fitMap.set(String(p.id), { pac: Number(p.pac ?? 70), fit: Number(p.fit ?? 100) })
  return fitMap
}
let ballTurn = 0, lastBall = [525, 340], coaches = {}
// [Sprint 35 C1] The coaches' pictures, loaded once each (an animated picture: the browser plays it).
const coachPics = new Map()
function coachDrawer(look, mood) {
  const key = `${look}-${mood}`
  let img = coachPics.get(key)
  if (!img) { img = new Image(); img.decoding = 'async'; img.src = `/characters/${key}.webp`; coachPics.set(key, img) }
  const idle = coachPics.get(`${look}-idle`) ?? img
  return {
    draw(c, x, y, r, k) {
      const pic = img.complete && img.naturalWidth ? img : idle.complete && idle.naturalWidth ? idle : null
      if (!pic) return
      const h = 128 * k, w = (h * 340) / 442
      c.drawImage(pic, x - w / 2, y + 58 * k - h, w, h)
    },
  }
}
let tvLast = 0
function drawTv(tick, u) {
  if (!ctx || !fit()) return
  const { s: vs, ox, oy } = tvView()
  ctx.setTransform(vs, 0, 0, vs, ox, oy)
  const f = tick?.frames
  if (!f?.length) { paintTvPitch(ctx); goalAt(ctx, 0); goalAt(ctx, 1050); return }
  const now = performance.now(), dts = Math.min(0.05, Math.max(0, (now - tvLast) / 1000)) * (props.speed || 1)
  tvLast = now
  // [Sprint 31 M1] The shared curve between the keyframes; a moment later on it gives every player's speed and way.
  const R = sample(f, u), span = (tick.moment?.ms ?? 3000) / 1000, du = 0.02, R2 = sample(f, Math.min(1, u + du))
  const [bx, by, bz] = R.ball
  danger = tick.danger ?? 0
  // [Sprint 31 C1] The camera pans after the ball, a little ahead of it where the play goes, gently, and never past
  // the ends of the pitch.
  const bvx = u >= 1 ? 0 : (R2.ball[0] - bx) / (du * span)
  lead += (Math.max(-70, Math.min(70, bvx * 0.35)) - lead) * Math.min(1, dts * 1.5)
  camX += (Math.max(TV.span / 2 - 40, Math.min(1050 - TV.span / 2 + 40, bx + lead)) - camX) * 0.06
  // It closes in on the last third (up to 1.3), and punches in on the ball as a key moment's scene opens.
  const third = Math.max(0, Math.min(1, (Math.abs(bx - 525) - 175) / 250))
  const punch = pitchReplay === 2 ? 2.15 : pitchReplay ? 1.6 : now - sceneAt < 650 ? 1.75 : 0
  zoom += ((punch || 1 + 0.3 * third * third * (3 - 2 * third)) - zoom) * Math.min(1, dts * (punch ? 6 : 1.4))
  if (smooth.value) zoom = 1
  const [, bsy] = proj(bx, by), fx = 320
  camFy += (Math.max(90, Math.min(270, bsy)) - camFy) * Math.min(1, dts * 2)
  const fy = zoom < 1.003 ? camFy : Math.round(camFy)
  const T = [vs * zoom, ox + vs * fx * (1 - zoom), oy + vs * fy * (1 - zoom)]
  viewL = -T[1] / T[0]; viewR = (cw - T[1]) / T[0]
  // The pitch is painted again only when the camera has moved or zoomed: else its picture is copied.
  if (!tvBg || tvBg.width !== cw || tvBg.height !== ch || Math.abs(camX - tvCam) >= 0.8 || Math.abs(zoom - tvZoom) > 0.004 || (zoom > 1.003 && Math.abs(fy - tvFy) >= 1)) {
    if (!tvBg || tvBg.width !== cw || tvBg.height !== ch) { tvBg = document.createElement('canvas'); tvBg.width = cw; tvBg.height = ch }
    const b = tvBg.getContext('2d', { alpha: false })
    b.setTransform(T[0], 0, 0, T[0], T[1], T[2]); paintTvPitch(b); tvCam = camX; tvZoom = zoom; tvFy = fy
  }
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(tvBg, 0, 0); ctx.setTransform(T[0], 0, 0, T[0], T[1], T[2])
  crowd(ctx, now)
  flashes(ctx, now)
  const drawn = []
  let near = null, nearD = 1e9
  const act = actions(tick, f, u)
  const subs = (tick.events ?? []).filter((e) => e.type === 'sub'), subIn = new Set(subs.map((e) => String(e.in)))
  for (const id in R.players) {
    const side = players.value[id]?.side
    if (!side) continue
    let [wx, wy] = R.players[id]
    const t = tvFor(id, side)
    let nx = R2.players[id]?.[0] ?? wx, ny = R2.players[id]?.[1] ?? wy
    // [Sprint 33 L3] A substitute comes on from the near touchline over the first part of his minute.
    if (subIn.has(String(id)) && u < SUB_WALK) { const w = u / SUB_WALK; wy = 700 + (wy - 700) * w; ny = wy + 3 }
    lastSeen.set(String(id), [wx, wy])
    // His speed in decimetres a second of the broadcast (u runs over the minute's span), 0 once the minute holds.
    const vx = u >= 1 ? 0 : (nx - wx) / (du * span), vy = u >= 1 ? 0 : (ny - wy) / (du * span), speed = Math.hypot(vx, vy)
    const moving = speed > 12
    // [Sprint 31 M4] Facing where he runs; standing, he faces the ball.
    if (moving) facing(t, vx, vy); else if (Math.hypot(bx - wx, by - wy) > 20) facing(t, bx - wx, by - wy)
    const [sx, sy, sc] = proj(wx, wy)
    t.sx = sx; t.sy = sy; t.scale = sc * 0.48
    // [Sprint 31 M5] The faster he runs, the quicker his stride and the more he leans into it (sideways only on screen).
    // [Sprint 34 K4] His own stride: a quick player turns his legs over faster, a tired one (fitness under 60) runs
    // heavier, upright and lower in the knee.
    const me = fitness(tick).get(String(id)), pace = me ? 0.8 + me.pac / 250 : 1, tired = me && me.fit < 60 ? 0.75 : 1
    const amp = Math.min(1, speed / 70) * tired
    const lean = moving && t.face === 'side' ? t.mirror * Math.min(9, speed / 9) * tired : 0
    t.lean += (lean - t.lean) * Math.min(1, dts * 8)
    t.f.face(t.face, t.mirror)
    t.bob = 0
    if (!smooth.value) {
      if (moving) { t.ph += dts * (6 + 10 * amp) * pace; t.f.run(t.ph, 0.4 + 0.6 * amp); t.bob = Math.abs(Math.sin(t.ph)) * 2.2 * amp }
      else { t.ph += dts * 2.2; t.f.idle(t.ph); t.bob = (Math.sin(t.ph) + 1) * 0.35 }
    } else t.f.pose()
    // [Sprint 32 A1] A move takes over the stride: a strike, a header, a slide, a keeper's dive, a celebration.
    const a = act.by[id]
    if (a) {
      if (a.kind === 'kick') t.f.kick(a.f)
      else if (a.kind === 'head') { t.f.header(a.f); t.bob = Math.sin(a.f * Math.PI) * 9 }
      else if (a.kind === 'slide') { t.f.slide(); t.lean = (t.face === 'side' ? t.mirror : 1) * 62 * Math.min(1, a.f * 2.5); t.bob = -16 * Math.min(1, a.f * 2.5) }
      else if (a.kind === 'dive') { t.f.dive(a.f); t.lean = a.dir * 82 * Math.min(1, a.f * 1.4); t.bob = Math.sin(Math.min(1, a.f * 1.4) * Math.PI) * 10 - 18 * Math.min(1, a.f * 1.4) }
      else if (a.kind === 'party' && !smooth.value) { t.f.celebrate(now / 1000 + t.ph); t.bob = Math.abs(Math.sin(now / 180 + t.ph)) * 6 }
      // [Sprint 33 L1, L2, L4]
      else if (a.kind === 'down') t.f.hangHead()
      else if (a.kind === 'head-hands') t.f.handsOnHead()
      else if (a.kind === 'gather') t.f.gather()
      else if (a.kind === 'throw') t.f.throwOut(a.f)
      else if (a.kind === 'throwin') { const r = 165 - 60 * a.f; t.f.pose(4, -10, r, -r) }
      else if (a.kind === 'fallen') { const d = Math.min(1, a.f * 4); t.f.fallen(); t.lean = (t.face === 'side' ? t.mirror : 1) * 84 * d; t.bob = -20 * d }
    }
    drawn.push(t)
    const d = Math.hypot(wx - bx, wy - by)
    if (d < nearD) { nearD = d; near = t }
  }
  // [Sprint 31 D1] The referee and his assistants, where the server puts them, facing the ball.
  for (const [n, o] of (R.officials ?? []).entries()) {
    let t = refs[n]
    if (!t) t = refs[n] = { f: figure(officialKit(), '', { look: 9 + n * 11, flag: n ? '#F2E205' : undefined, shorts: '#111827', socks: '#111827', trim: '#F5B82E', build: 1 }), ph: n, sx: 0, sy: 0, scale: 1, bob: 0, face: 'front', mirror: 1, lean: 0 }
    const nx = R2.officials?.[n]?.[0] ?? o[0], ny = R2.officials?.[n]?.[1] ?? o[1], speed = u >= 1 ? 0 : Math.hypot(nx - o[0], ny - o[1]) / (du * span)
    if (speed > 12) facing(t, nx - o[0], ny - o[1]); else facing(t, bx - o[0], by - o[1])
    // [Sprint 33 L2] At a foul the referee runs over to it (stopping 3 m short) and holds up the card.
    let ox = o[0], oy = o[1]
    const call = n === 0 ? act.call : null, at = call ? R.players[call.at] : null
    if (at) { const w = Math.min(1, call.w * 2.2), d = Math.hypot(at[0] - ox, at[1] - oy) || 1, stop = Math.max(0, 1 - 30 / d); ox += (at[0] - ox) * stop * w; oy += (at[1] - oy) * stop * w; facing(t, at[0] - ox, at[1] - oy) }
    const [sx, sy, sc] = proj(ox, oy)
    t.sx = sx; t.sy = sy; t.scale = sc * 0.46; t.f.face(t.face, t.mirror); t.bob = 0
    t.f.showCard(null)
    if (!smooth.value) { if (speed > 12 || (at && call.w < 0.45)) { t.ph += dts * 9; t.f.run(t.ph, 0.6); t.bob = Math.abs(Math.sin(t.ph)) * 1.4 } else { t.ph += dts * 2; t.f.idle(t.ph) } } else t.f.pose()
    if (call?.card) t.f.showCard(call.card)
    drawn.push(t)
  }
  // [Sprint 34 V2, Sprint 35 C1] The two coaches in their technical areas on the near touchline: the approved 3D
  // models of their looks (C1 a suit and tie, C2 a tracksuit, C3 a jacket and hijab), each in the mood the server
  // gives (the minute's moods); the screen only shows it. The lowest tier keeps them calm (one picture each).
  for (const side of ['home', 'away']) {
    let c = coaches[side]
    if (!c) c = coaches[side] = { f: null, ph: side === 'home' ? 0 : 2, sx: 0, sy: 0, scale: 1, bob: 0, face: 'back', mirror: 1, lean: 0, side }
    const look = String(props.looks?.[side] ?? (side === 'home' ? 'C1' : 'C2')).toLowerCase()
    const mood = smooth.value ? 'idle' : (tick.moods?.[side] ?? 'idle'), pace = smooth.value ? 0 : Math.sin(now / 1400 + c.ph) * 14
    const [sx, sy, sc] = proj((side === 'home' ? 445 : 605) + pace, 712)
    c.sx = sx; c.sy = sy; c.scale = sc * 0.5; c.bob = 0; c.lean = 0
    c.f = coachDrawer(look, mood)
    drawn.push(c)
  }
  // [Sprint 33 L3] The player taken off walks from where he was to the near touchline, and leaves.
  for (const e of subs) {
    const last = lastSeen.get(String(e.out)), side = players.value[e.out]?.side
    if (!last || !side || R.players[e.out] || u >= SUB_WALK) continue
    const t = tvFor(String(e.out), side), w = u / SUB_WALK, ox = last[0], oy = last[1] + (700 - last[1]) * w
    const [sx, sy, sc] = proj(ox, oy)
    t.sx = sx; t.sy = sy; t.scale = sc * 0.48; t.lean = 0; facing(t, 0, 1); t.f.face(t.face, t.mirror)
    t.bob = 0
    if (!smooth.value) { t.ph += dts * 5; t.f.run(t.ph, 0.3) } else t.f.pose()
    drawn.push(t)
  }
  let [px, py, ps] = proj(bx, by)
  // [Sprint 31 M3] A ball on the grass close to a player sits in front of his foot (drawing only).
  if (near && bz < 4 && nearD < 26) {
    const w = (1 - nearD / 26) * (1 - bz / 4) * 0.85, s = near.scale
    const fx = near.sx + (near.face === 'side' ? near.mirror * 13 * s : 4 * s), fy = near.sy + (near.face === 'front' ? 3 * s : near.face === 'back' ? -2 * s : 1 * s)
    px += (fx - px) * w; py += (fy - py) * w
  }
  // [Sprint 31 C4] Nearer things over farther ones, sorted every frame: the players, the ball (by where it would
  // land) and the goals.
  const items = drawn.map((t) => ({ y: t.sy, t }))
  items.push({ y: py + 0.5, ball: true }, { y: proj(0, 377)[1], goal: 0 }, { y: proj(1050, 377)[1], goal: 1050 })
  items.sort((a, b) => a.y - b.y)
  const h = Math.min(1, bz / 60)
  // [Sprint 31 C4] Every player's shadow first, under them all: at night two faint ones from the floodlights in the
  // far corners, by day one from the sun.
  // The middle tier keeps one floodlight's shadow at night [Sprint 33 Q1].
  const lights = night ? (tier.value === 'high' ? [[-1, 0.2], [1, 0.2]] : [[1, 0.26]]) : [[1, 0.32]]
  for (const [dir, a] of lights) {
    ctx.fillStyle = `rgba(0,0,0,${a})`; ctx.beginPath()
    for (const t of drawn) {
      const k = t.scale, cx = t.sx + dir * 9 * k, cy = t.sy + 2 * k, r = dir * 0.35
      ctx.moveTo(cx + 17 * k * Math.cos(r), cy + 17 * k * Math.sin(r)); ctx.ellipse(cx, cy, 17 * k, 4 * k, r, 0, Math.PI * 2)
    }
    ctx.fill()
  }
  for (const it of items) {
    if (it.t) { const t = it.t; t.f.draw(ctx, t.sx, t.sy - 58 * t.scale - t.bob * t.scale, t.lean, t.scale, false) }
    else if (it.goal !== undefined) goalAt(ctx, it.goal, now)
    else {
      // [Sprint 31 M2] The ball flies in an arc; its shadow stays on the grass, smaller, fainter and further off the higher it goes.
      ctx.fillStyle = `rgba(0,0,0,${(0.35 * (1 - h * 0.6)).toFixed(3)})`
      ctx.beginPath(); ctx.ellipse(px + h * 6 * ps, py + 1, 6 * ps * (1 - h * 0.55), 2.5 * ps * (1 - h * 0.55), 0, 0, Math.PI * 2); ctx.fill()
      const ry = py - 3 * ps - bz * 0.35 * ps, rr = 4.5 * ps + bz * 0.02
      // [Sprint 32 V1] A fast ball leaves a short fading trail behind it.
      const [qx, qy, qs] = proj(R2.ball[0], R2.ball[1]), qz = R2.ball[2], dx = qx - px, dy = qy - 3 * qs - qz * 0.35 * qs - ry
      if (tier.value === 'high' && u < 1 && Math.hypot(dx, dy) > 6) for (let n = 3; n >= 1; n--) { ctx.fillStyle = `rgba(255,255,255,${0.12 * (4 - n)})`; ctx.beginPath(); ctx.arc(px - dx * n * 0.35, ry - dy * n * 0.35, rr * (1 - n * 0.12), 0, Math.PI * 2); ctx.fill() }
      ctx.fillStyle = '#fff'; ctx.strokeStyle = '#111'; ctx.lineWidth = 1
      ctx.beginPath(); ctx.arc(px, ry, rr, 0, Math.PI * 2); ctx.fill(); ctx.stroke()
      // [Sprint 33 V1] Its panels turn as it rolls or flies (by the way it has come), and the floodlights' glint.
      if (tier.value !== 'low') {
        ballTurn += Math.hypot(bx - lastBall[0], by - lastBall[1]) * 0.03 * (bx >= lastBall[0] ? 1 : -1); lastBall = [bx, by]
        ctx.fillStyle = '#1B2333'
        for (let n = 0; n < 3; n++) { const a = ballTurn + n * 2.09, x = px + Math.cos(a) * rr * 0.55; if (Math.sin(a) > -0.2) { ctx.beginPath(); ctx.arc(x, ry + Math.sin(a * 0.7) * rr * 0.25, rr * 0.28, 0, Math.PI * 2); ctx.fill() } }
        ctx.fillStyle = 'rgba(255,255,255,.9)'; ctx.beginPath(); ctx.arc(px - rr * 0.38, ry - rr * 0.4, rr * 0.22, 0, Math.PI * 2); ctx.fill()
      }
    }
  }
  // The ball in a net: it ripples.
  if (Math.abs(by - 340) < 40 && (bx <= 6 || bx >= 1044)) { const g = bx < 525 ? 0 : 1050; if (now - netHit[g] > 1200) netHit[g] = now }
  // [Sprint 32 V1] The name of the player on the ball over his head, as a broadcast's caption.
  const holderId = act.holder
  const ht = holderId != null ? tvPlayers.get(String(holderId)) : null
  const hname = holderId != null ? players.value[holderId]?.name : null
  if (ht && hname && !smooth.value) {
    const label = String(hname).split(' ').slice(-1)[0].slice(0, 14), tx = ht.sx, ty = ht.sy - (95 + ht.bob) * ht.scale - 3
    ctx.font = '700 7px "Barlow Condensed", sans-serif'; ctx.textAlign = 'center'
    const w = ctx.measureText(label).width + 8
    ctx.fillStyle = 'rgba(7,23,51,.82)'; ctx.fillRect(tx - w / 2, ty - 7, w, 9)
    ctx.fillStyle = '#F5B82E'; ctx.fillRect(tx - w / 2, ty + 1.2, w, 0.8)
    ctx.fillStyle = '#FFFFFF'; ctx.fillText(label, tx, ty)
  }
  // [Sprint 32 V2] Rain on some matches (from the seed: the same on every screen), the grass a little darker.
  if (rainy()) rain(ctx, now)
  // [Sprint 31 C2] The light: the floodlights' sheen on the grass at night (the sun's warmth by day), and the
  // picture's edges darkened as a camera's lens does. Painted once for the box's size, then laid over every frame.
  const key = `${cw}x${ch}|${night}|${tier.value}`
  if (!lightCv || lightKey !== key) {
    lightKey = key; lightCv = document.createElement('canvas'); lightCv.width = cw; lightCv.height = ch
    const l = lightCv.getContext('2d')
    if (!smooth.value) {
      const g = l.createRadialGradient(cw / 2, ch * 0.25, 0, cw / 2, ch * 0.25, cw * 0.6)
      g.addColorStop(0, night ? 'rgba(255,255,240,.10)' : 'rgba(255,240,200,.08)'); g.addColorStop(1, 'rgba(255,255,255,0)')
      l.fillStyle = g; l.fillRect(0, 0, cw, ch)
    }
    l.fillStyle = (night ? LOOK.night : LOOK.day).tint; l.fillRect(0, 0, cw, ch)
    const v = l.createRadialGradient(cw / 2, ch / 2, Math.min(cw, ch) * 0.35, cw / 2, ch / 2, Math.max(cw, ch) * 0.75)
    v.addColorStop(0, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(0,0,0,.42)')
    l.fillStyle = v; l.fillRect(0, 0, cw, ch)
  }
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(lightCv, 0, 0)
}
function buildPitch() { if (!pitchHost.value) return; const hr = cairoHour(); night = hr >= 18 || hr < 6; if (!cv) buildCanvas(); else { tvPlayers = new Map(); dots = new Map(); topBg = null; refs = []; coaches = {} } drawPitch(lastTick, lastU) }
function drawPitch(tick, u) {
  lastTick = tick; lastU = u
  camera.value === 'tv' ? drawTv(tick, u) : drawTop(tick, u)
  // [Sprint 31 D4] How close the ball is to a goal, in tenths, for the crowd's sound (sent only when it changes).
  const f = tick?.frames
  if (f?.length) { const bx = sample(f, u).ball[0], c = Math.round(Math.max(0, Math.min(1, (Math.abs(bx - 525) - 200) / 300)) * 10) / 10; if (c !== nearSent) { nearSent = c; emit('near', c) } }
}
let nearSent = -1
function tickClock(tick, u) {
  const m = tick?.minute
  if (!m || (tick.moment?.kind === 'shootout')) { clock.value = ''; return }
  const base = m[0] - 1 + (m[1] || 0), sec = Math.min(59, Math.floor(u * 60))
  const text = `${String(base).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  if (clock.value !== text) clock.value = text
}
watch(() => props.kits, () => buildPitch(), { deep: true })
watch(() => props.kickoff, () => buildPitch())
// [Sprint 36 F3] The rain of the live pitch falls in the scenes too.
watch(() => props.seed, () => setRain(rainy()), { immediate: true })
onMounted(buildPitch)
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
@keyframes ping { 0% { transform: scale(1); opacity: .9 } 70%, 100% { transform: scale(3); opacity: 0 } }
.mom { height: 3px; display: flex; margin: 0 14px; border-radius: 2px; overflow: hidden }
.mom i { display: block; height: 100%; transition: width .8s }

.pitch { position: absolute; z-index: 1; top: clamp(84px, 16cqw, 106px); left: 10px; right: 10px; height: min(40cqh, 62cqw); border-radius: 14px; overflow: hidden; background: #1a7d44; box-shadow: 0 0 0 2px rgba(255,255,255,.08), 0 16px 30px rgba(0,0,0,.45) }
.pitch-in { position: absolute; inset: 0 }
.pitch :deep(svg) { width: 100%; height: 100%; display: block }
.cam { position: absolute; z-index: 2; top: 8px; inset-inline-end: 8px; min-height: 36px; padding: 0 12px; border-radius: 999px; font-size: 13px; font-weight: 800; color: #fff; background: rgba(6,17,30,.7); border: 1px solid rgba(255,255,255,.18) }
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

.pitch .replay { z-index: 2 }
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
@media (prefers-reduced-motion: reduce) { .atmo::before, .wave i, .live i::after, .moment.tense .mbox, .moment.tense::after, .party i { animation: none } .party i { display: none } }
</style>
