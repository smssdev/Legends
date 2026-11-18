<template>
  <div
    ref="host"
    class="mc theme-night"
    :class="{ smooth, scene: sceneOn, day: theme === 'light' }"
    dir="rtl"
    :style="{ '--H': kits.home.kit, '--A': kits.away.kit }"
  >
    <div class="atmo" aria-hidden="true" />

    <div class="sb">
      <div class="sb-in">
        <div class="side" :style="{ '--c': kits.home.kit }">
          <span class="crest" v-html="crestOf('home')" /><span class="nm"
            ><b>{{ $nm(clubs.home) }}</b
            ><small>{{ coachLine('home') }}</small></span
          >
        </div>
        <div class="mid">
          <span class="score" :class="{ pop }" dir="ltr"><FlipNumber :value="score.away" /> - <FlipNumber :value="score.home" /></span
          ><span class="live" :class="{ frozen }" dir="ltr"><i /><span ref="clockA" class="ct" /></span>
        </div>
        <div class="side away" :style="{ '--c': kits.away.kit }">
          <span class="crest" v-html="crestOf('away')" /><span class="nm"
            ><b>{{ $nm(clubs.away) }}</b
            ><small>{{ coachLine('away') }}</small></span
          >
        </div>
      </div>
      <div class="mom" dir="ltr">
        <i :style="{ width: 100 - mom + '%', background: kits.away.kit }" /><i :style="{ width: mom + '%', background: kits.home.kit }" />
      </div>
    </div>

    <!-- [Sprint 42 G1] The owner's (2026-11-03): no live pitch. Between the moments only the match clock runs; at a
         moment it stops dead and the cartoon clip plays over it, then it runs on. -->
    <!-- [Sprint 42 H1] As on TV: the studio, two commentators at their desk and the clock on the LED wall; at a moment
         the picture cuts to the clip. -->
    <div class="clockface tv" :class="{ frozen }">
      <div ref="studioHost" class="studio" aria-hidden="true" />
      <span class="bug" dir="ltr">GLM TV</span>
      <span class="onair"><i />{{ $t('مباشر') }}</span>
      <span class="strap"
        ><b>{{ half }}</b
        ><span ref="clockB" class="ct" dir="ltr" /><em>{{ frozen ? $t('توقف الوقت · لقطة') : $t('الوقت يمشي') }}</em></span
      >
      <span class="prog" dir="ltr" aria-hidden="true"><i ref="progBar" /></span>
    </div>

    <div class="tl" :aria-label="$t('مجريات المباراة')" aria-live="polite">
      <div class="spine" />
      <TransitionGroup name="row" tag="div" class="list">
        <div v-for="it in items" :key="it.key" class="row" :class="it.center ? 'home' : it.side">
          <div class="card" :class="{ goal: it.goal }" :style="{ '--c': it.center ? '#F5B82E' : kits[it.side].kit }">
            <span class="ico" v-html="ICON[it.icon]" />
            <span class="tx"
              ><b dir="auto">{{ $nm(it.name) }}</b
              ><span>{{ it.label }}</span></span
            >
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
          <i v-for="c in tier === 'high' ? confetti : confetti.slice(0, 12)" :key="c.i" :style="c.style" />
          <span class="burst"
            ><b>{{ party.who }}</b
            ><small>{{ $nm(clubs[party.side]) }}</small></span
          >
        </div>
        <div class="lower" :style="{ '--c': barKit }">
          <span class="ev">{{ bar?.head }}</span>
          <span class="who"
            ><b dir="auto">{{ bar?.who }}</b
            ><span>{{ bar?.sub }}</span></span
          >
          <span class="min" dir="ltr">{{ cur?.minute }}</span>
        </div>
      </div>
    </div>

    <!-- The coaches' reactions in a match between friends, rising from each side. -->
    <div class="reacts" aria-live="polite">
      <TransitionGroup name="rx">
        <div v-for="r in reacts" :key="r.id" class="rx" :class="r.side" :style="{ '--c': kits[r.side].kit, '--x': r.x + '%' }">
          <span class="e">{{ r.emoji }}</span><span v-if="r.text || r.who" class="t"
            ><small>{{ r.who }}</small
            >{{ r.text }}</span
          >
        </div>
      </TransitionGroup>
    </div>

    <div class="mic" :class="{ on: bubbleOn }">
      <span class="m" aria-hidden="true"
        ><svg viewBox="0 0 24 24" fill="#071733">
          <rect x="8" y="2" width="8" height="13" rx="4" />
          <path d="M5 11a7 7 0 0 0 14 0" fill="none" stroke="#071733" stroke-width="2" />
          <rect x="11" y="18" width="2" height="4" /></svg
      ></span>
      <span class="wave" aria-hidden="true"><i v-for="n in 7" :key="n" /></span>
      <span class="tx"
        ><b>{{ bubble }}</b
        ><span v-if="lang === 'en' && enLine" dir="ltr">{{ enLine }}</span></span
      >
    </div>

    <div v-if="intro" class="preview">
      <span class="kick">{{ live ? $t('مباراة بين صديقين') : $t('ما قبل المباراة') }}</span>
      <span v-if="live && countdown > 0" class="plan"
        >{{ $t('الصافرة بعد') }} <b dir="ltr">{{ countdown }}</b> {{ $t('ثانية · عدّل تشكيلتك وخطتك من لوحة المدرب الآن') }}</span
      >
      <div class="teams">
        <div class="team">
          <span class="crest" v-html="crestOf('home')" /><b>{{ $nm(clubs.home) }}</b
          ><small>{{ coachLine('home') }}</small>
        </div>
        <span class="vs">VS</span>
        <div class="team">
          <span class="crest" v-html="crestOf('away')" /><b>{{ $nm(clubs.away) }}</b
          ><small>{{ coachLine('away') }}</small>
        </div>
      </div>
      <div class="stats">
        <div v-for="r in compare" :key="r.label" class="st">
          <span>{{ r.h }}</span><span class="bar"
            ><i :style="{ width: r.hp + '%', background: kits.home.kit }" /><i
              :style="{ width: 100 - r.hp + '%', background: kits.away.kit }" /></span
          ><span>{{ r.a }}</span
          ><span class="lbl">{{ $t(r.label) }}</span>
        </div>
      </div>
      <div class="keys">
        <div v-for="s in ['home', 'away'] as const" :key="s" class="key" :style="{ '--c': kits[s].kit }">
          <span class="no">{{ star(s)?.no }}</span><span
            ><b>{{ $nm(star(s)?.name) }}</b
            ><span>{{ $t('مفتاح {v0} · {v1}', { v0: $nm(clubs[s]), v1: star(s)?.ovr }) }}</span></span
          >
        </div>
      </div>
      <button type="button" class="go" @click="$emit('introDone')">
        {{ live ? (countdown > 0 ? $t('البداية بعد {v0}', { v0: countdown }) : $t('شغّل الصوت وانتظر البداية')) : $t('ابدأ البث') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
// The match feed (docs/MATCH_VIEW.md 4.6): each minute plays its scene first,
// then its card joins the timeline and the commentator sums it up on the mic
// bar. The parent calls play(tick) per minute; the minute's length is the
// server's (tick.moment.ms). [Sprint 57 W3] Typed; the sounds (cues.ts), the clock (useBroadcastClock.ts), the studio
// (useStudio.ts) and the look (MatchFeed.css) apart.
import { scoreText } from '../../lib/format'
import { t as tr } from '../../lib/i18n'
import FlipNumber from '../../components/ui/FlipNumber.vue'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { theme } from '../../lib/theme'
import { ICON, SCENES, crest, esc, setKits, setLight, setRain, setRich, setSmooth } from './art'
import type { Kit, Scene, Side } from './kit'
import { noteFrame, smooth, tier } from '../perf'
import { SCENE_TIME } from './timing'
import { planMinute } from './plan'
// [Sprint 57 B2] The minute's story is the server's (tick.story); told() writes it for this screen.
import { told, untold, type Item, type Story } from './told'
import type { Cut } from './director'
import { soundsOf } from './cues'
import { useBroadcastClock } from './useBroadcastClock'
import { useStudio } from './useStudio'
import { voiceLine, type Lang } from '../voice'
import type { TeamSnapshot, Tick } from '../../api/sim'

const props = defineProps<{
  kits: Record<Side, Kit>
  clubs: Record<Side, string>
  codes: Record<Side, string>
  logos?: { home?: string | null; away?: string | null }
  strength: Record<Side, number>
  coaches?: Partial<Record<Side, string>> | null
  teams?: Partial<Record<Side, TeamSnapshot>> | null
  seed: number
  kickoff?: string | null
  looks?: Partial<Record<Side, string>> | null
  speed: number
  minute: string
  score: Record<Side, number>
  mine: Side | null
  lang: Lang | 'off'
  intro: boolean
  live: boolean
  countdown: number
}>()
const emit = defineEmits<{
  cue: [name: string]
  sound: [name: string]
  say: [line: ReturnType<typeof voiceLine>]
  near: [closeness: number]
  introDone: []
}>()

const host = ref<HTMLElement>(),
  stage = ref<HTMLElement>(),
  studioHost = ref<HTMLElement>()
// [X35, Sprint 42 E1, G1] The broadcast clock, frozen at the moment's second while the clip plays, and the half.
const clockA = ref<HTMLElement>(),
  clockB = ref<HTMLElement>(),
  progBar = ref<HTMLElement>()
const bclock = useBroadcastClock(
  { a: clockA, b: clockB, bar: progBar },
  () => props.minute,
  (c) => emit('near', c),
)
const { frozen, half } = bclock
const items = ref<(Item & { key: number; score: string | null })[]>([])
const cur = ref<Story | null>(null)
const sceneOn = ref(false),
  bubbleOn = ref(false),
  shake = ref(false),
  pop = ref(false),
  replaying = ref(false)
// Until the key moment the lower bar tells only what is happening (a shot, a penalty), never how it ends.
const revealed = ref(true),
  tense = ref(false)
const bar = computed(() => (revealed.value || !cur.value?.pre ? cur.value : cur.value.pre))
const party = ref<{ side: Side; who: string } | null>(null)
const confetti = Array.from({ length: 42 }, (_, i) => ({
  i,
  style: {
    left: ((i * 37) % 100) + '%',
    animationDelay: ((i * 53) % 90) / 100 + 's',
    animationDuration: 1.6 + ((i * 29) % 10) / 10 + 's',
    background: ['var(--c)', 'var(--t)', '#F5B82E', '#fff'][i % 4],
    transform: `rotate(${(i * 47) % 360}deg)`,
  },
}))
const reacts = ref<{ id: number; side: Side; emoji: string; text: string; who: string; x: number }[]>([])
let reactSeq = 0
/** A coach's reaction (live): an emoji and a short word, rising from his side for a few seconds. */
function react(side: Side, emoji: string, text: string, who: string) {
  const id = ++reactSeq
  reacts.value.push({ id, side, emoji, text, who, x: 8 + ((id * 23) % 22) })
  if (reacts.value.length > 6) reacts.value.shift()
  setTimeout(() => (reacts.value = reacts.value.filter((r) => r.id !== id)), 3200)
}
const bubble = ref(''),
  enLine = ref('')
const mom = ref(50)
const barKit = computed(() => {
  const k = props.kits[cur.value?.side === 'away' ? 'away' : 'home'].kit,
    n = parseInt(k.slice(1), 16)
  return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) > 150 ? '#3A5F9E' : k
})
// [UP3] The club's real logo where it has one, else its drawn badge (the logo's address escaped [2026-11-09]).
const crestOf = (s: Side) =>
  props.logos?.[s]
    ? `<img src="${esc(props.logos[s])}" alt="" decoding="async">`
    : crest([props.kits[s].kit, props.kits[s].trim, props.codes[s] || ''])
const coachLine = (s: Side) =>
  [props.coaches?.[s] ?? (props.mine === s ? tr('أنت') : props.live ? '' : props.mine ? tr('الحاسوب') : ''), props.teams?.[s]?.formation]
    .filter(Boolean)
    .join(' · ')
watch(
  () => props.kits,
  (k) => setKits(k),
  { immediate: true, deep: true },
)
// The smooth mode for weak phones [X30]: the scenes drawn from now on leave out the costly parts.
watch(smooth, (v) => setSmooth(v), { immediate: true })
watch(tier, (v) => setRich(v === 'high'), { immediate: true })
watch(
  () => [props.score.home, props.score.away],
  () => {
    pop.value = false
    requestAnimationFrame(() => (pop.value = true))
  },
)

// Every player of the match by id, for names and shirt numbers.
const players = computed(() => {
  const m: Record<string, { name: string; no: number; side: Side }> = {}
  for (const side of ['home', 'away'] as const)
    for (const p of props.teams?.[side]?.players ?? []) m[p.id] = { name: p.name, no: p.no, side }
  return m
})
// The pre-match card: strength, average rating of the starters, and each side's key player.
const starters = (s: Side) => (props.teams?.[s]?.players ?? []).filter((p) => p.on)
const star = (s: Side) => [...starters(s)].sort((a, b) => b.ovr - a.ovr)[0]
const avg = (s: Side) => {
  const on = starters(s)
  return on.length ? Math.round(on.reduce((t, p) => t + p.ovr, 0) / on.length) : 0
}
const compare = computed(() =>
  [
    { label: 'القوة', h: Math.round(props.strength.home / 100), a: Math.round(props.strength.away / 100) },
    { label: 'متوسط التشكيلة', h: avg('home'), a: avg('away') },
  ].map((r) => ({ ...r, hp: r.h + r.a ? (r.h / (r.h + r.a)) * 100 : 50 })),
)

// ---------------------------------------------------------------- playing a minute
/** A minute being played: its story, its timing, its cutaways and replay, and what has been done of it. */
type Plan = {
  s: Story
  total: number
  sceneT: number
  cuts: Cut[]
  cutT: number
  rate: number
  replay: { at: number; rate: number; off: number } | null
  fired: Set<string>
  built: Scene[]
  itemsAdded: boolean
  score: string
  startAt: number | null
  tick: Tick
}
// [Sprint 36 F4] The replay's angle (1, then 2 at the full tier), and the frame that turns the scene round for it.
const replayAngle = ref(1)
let angleWrap: SVGGElement | null = null
// [Sprint 35 C1] The minute's own scene (for its replay) and the cutaway playing now.
let mainScene: Scene | null = null,
  cutScene: Scene | null = null
let raf = 0,
  last = 0,
  t = 0,
  plan: Plan | null = null,
  scene: Scene | null = null,
  keySeq = 0,
  drawn = 0
const story = (tick: Tick) => told(tick.story, { players: players.value, clubs: props.clubs })
const build = (s: Story) => SCENES[s.scene!]({ ...s.data, side: s.side })
// startAt (live): when the minute starts on performance.now(). The scene follows that clock
// instead of counting frames, so two screens stay on the same instant even if one is slow.
function play(tick: Tick, startAt: number | null = null) {
  finish()
  const s = story(tick) ?? untold()
  // [Sprint 09 G1] The minute's timeline (plan.ts, shared with Unity through its golden vectors).
  const { total, sceneT, cuts, cutT, rate, replay } = planMinute(s, tick, {
    tier: tier.value,
    looks: props.looks as Record<string, string> | null,
    seed: props.seed,
    smooth: smooth.value,
  })
  const p: Plan = {
    s,
    total,
    sceneT,
    cuts,
    cutT,
    rate,
    replay,
    fired: new Set(),
    built: [],
    itemsAdded: false,
    score: scoreText(tick.score.home, tick.score.away),
    startAt,
    tick,
  }
  plan = p
  mom.value = Math.max(15, Math.min(85, 50 + (tick.danger ?? 0) * 7))
  cur.value = s
  revealed.value = !s.pre
  // The stadium holds its breath before a penalty or a free kick on the edge of the box.
  tense.value = s.scene === 'penalty' || s.scene === 'freekick'
  party.value = null
  t = startAt === null ? 0 : Math.max(0, (performance.now() - startAt) / 1000)
  let made: Scene | null = null
  // A scene that breaks is skipped with its minute's cards still shown: the match never stops on one drawing.
  if (s.scene)
    try {
      // [Sprint 42 I1] Drawn ahead by prepare() when the minute was known early (the same story: the same scene).
      made = ready?.tick === tick.tick && ready.scene === s.scene && ready.made ? ready.made : build(s)
      dropStashed(made.svg)
      ready = null
      made.update(0)
    } catch (e) {
      console.error(e)
      made = null
    }
  angleWrap = null
  replayAngle.value = 1
  // [Sprint 42 I1] The cutaways are drawn ahead, in idle time while the scene plays, not at the instant they start.
  cuts.forEach((c, i) =>
    idle(
      () => {
        if (plan !== p || p.built[i]) return
        try {
          p.built[i] = SCENES[c.name](c.data as never)
          p.built[i].update(0)
          stash(p.built[i].svg)
        } catch (e) {
          console.error(e)
        }
      },
      400 + i * 300,
    ),
  )
  if (made) {
    scene = mainScene = made
    showSvg(made.svg)
    sceneOn.value = true
  } else {
    scene = null
    dropStashed(null)
    addItems()
    if (s.bubble && s.items.length) showBubble()
  }
}
// [Sprint 42 I1] A scene drawn ahead waits in the stage, hidden: showing it is only making it visible. Showing one
// takes away the one shown before (the hidden ones stay).
function stash(svg: SVGElement) {
  if (!stage.value || svg.parentNode === stage.value) return
  svg.dataset.stash = '1'
  svg.style.visibility = 'hidden'
  stage.value.appendChild(svg)
}
function showSvg(svg: SVGElement) {
  if (!stage.value) return
  for (const c of [...stage.value.children] as HTMLElement[]) if (c !== (svg as Element) && !c.dataset?.stash) c.remove()
  delete svg.dataset.stash
  svg.style.visibility = ''
  if (svg.parentNode !== stage.value) stage.value.appendChild(svg)
}
// Hidden scenes no longer wanted (another minute came): away, so the stage holds only what may still be shown.
function dropStashed(keep: SVGElement | null) {
  if (stage.value)
    for (const c of [...stage.value.children] as HTMLElement[]) if (c.dataset?.stash && c !== (keep as Element | null)) c.remove()
}
// Work for the browser's idle time (or after a while at the latest, so it is done before it is needed).
const idle = (fn: () => void, timeout: number) =>
  window.requestIdleCallback ? window.requestIdleCallback(fn, { timeout }) : setTimeout(fn, 50)
// One frame of the scene; a frame that throws ends the scene there and the minute goes on without it.
function draw(u: number) {
  try {
    scene?.update(u)
  } catch (e) {
    console.error(e)
    scene = null
    sceneOn.value = false
    addItems()
    showBubble()
  }
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
  if (!plan) return
  const s = plan.s
  bubble.value = s.bubble
  const l = s.lines.find((l) => l.x) ?? s.lines[0]
  enLine.value = l?.en ? (voiceLine('en', { ...l, x: false }, players.value, props.clubs)?.text ?? '') : ''
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
function skip() {
  finish()
}
// [Sprint 42 I1] The next minute, known before it plays: its scene is built now, in idle time, so starting it costs
// nothing. The minute's story is the server's, so play() gets the same scene.
let ready: { tick: number; scene: string | null; made: Scene | null } | null = null
function prepare(tick: Tick) {
  if (!tick || ready?.tick === tick.tick) return
  const job: NonNullable<typeof ready> = { tick: tick.tick, scene: null, made: null }
  ready = job
  idle(() => {
    if (ready !== job) return
    try {
      const s = story(tick)
      if (!s?.scene) return
      job.scene = s.scene
      job.made = build(s)
      job.made.update(0)
      stash(job.made.svg)
    } catch (e) {
      console.error(e)
    }
  }, 800)
}
defineExpose({ play, skip, react, prepare })

// [X41] A hidden page gets no animation frames, but the broadcast plays on (the commentator and the crowd): a timer
// steps the minute instead, so its lines and sounds still come on time. Browsers let a page that plays sound run.
let bgTimer = 0
function frame(now: number) {
  step(now)
  raf = requestAnimationFrame(frame)
}
function step(now: number) {
  // [Sprint 33 Q1] Frames that fall behind while the match plays lower the auto tier, one at a time [X30]. A hidden
  // page (stepped by the timer, not by frames) says nothing of the device.
  if (plan && !document.hidden) noteFrame(now - last)
  const dt = Math.min(0.05, (now - last) / 1000) * (props.speed || 1)
  last = now
  if (!plan) return void studio.draw(now)
  const p = plan
  t = p.startAt === null ? t + dt : Math.max(0, (now - p.startAt) / 1000)
  const { s, total, sceneT, rate, fired } = p
  bclock.tick(p.tick, Math.min(1, t / total), { total: p.total, sceneT: p.sceneT, cutT: p.cutT, scene: !!p.s.scene })
  studio.draw(now)
  const fire = (k: string, fn: () => void) => {
    if (!fired.has(k)) {
      fired.add(k)
      fn()
    }
  }
  // A line or a sound long past (the screen joined late) is dropped, not played out of time.
  const cue = (k: string, at: number, fn: () => void) => fire(k, () => t - at < 0.6 && fn())
  // The scene follows the clock, so drawing it 30 times a second in the smooth mode only skips frames, never time.
  if (scene && t < sceneT && (!smooth.value || now - drawn >= 32)) {
    drawn = now
    draw(t * rate)
  }
  const keyT = s.keyAt * sceneT
  // Commentary: line times are fractions of the scene (or of the minute when there is none).
  for (const [i, l] of s.lines.entries()) {
    const at = l.at * (sceneT || total * 0.5)
    if (t >= at)
      cue('l' + i, at, () => {
        studio.talk()
        if (props.lang !== 'off') emit('say', voiceLine(props.lang, l, players.value, props.clubs))
      })
  }
  for (const [i, [at, name]] of soundsOf(s).entries()) {
    const when = at === 'key' ? keyT : at * sceneT
    if (t >= when) cue('s' + i, when, () => emit('sound', name))
  }
  if (s.scene === 'miss' && s.data.how === 'post' && t >= keyT) cue('post', keyT, () => emit('sound', 'post'))
  if (t >= keyT)
    fire('key', () => {
      revealed.value = true
      tense.value = false
    })
  if (s.goal && t >= keyT)
    fire('goal', () => {
      emit('cue', 'goal')
      shake.value = true
      setTimeout(() => (shake.value = false), 500)
      studio.hype()
      party.value = { side: s.side, who: s.who }
    })
  // [Sprint 35 C1] After the scene, the director cuts away (each cutaway built as it starts), then the cards.
  if (scene && t >= sceneT) {
    let c0 = sceneT,
      cut: Cut | null = null,
      n = 0
    for (const [i, c] of p.cuts.entries()) {
      if (t >= c0 && t < c0 + c.dur) {
        cut = c
        n = i
        break
      }
      c0 += c.dur
    }
    if (cut) {
      const c = cut
      fire('cut' + n, () => {
        party.value = null
        try {
          cutScene = p.built[n] ?? SCENES[c.name](c.data as never)
          cutScene.update(0)
          showSvg(cutScene.svg)
          sceneOn.value = true
        } catch (e) {
          console.error(e)
          cutScene = null
        }
      })
      if (cutScene && (!smooth.value || now - drawn >= 32)) {
        drawn = now
        try {
          cutScene.update(t - c0)
        } catch (e) {
          console.error(e)
          cutScene = null
        }
      }
    } else if (t >= sceneT + p.cutT)
      fire('end', () => {
        sceneOn.value = false
        party.value = null
        cutScene = null
        addItems()
        showBubble()
        if (!p.replay) studio.reactTo(p.s, p.tick.tick)
      })
  }
  const rp = p.replay
  if (scene && rp && t >= rp.at) {
    const u = (rp.off ?? 0) + (t - rp.at) * rp.rate
    const len = SCENE_TIME[s.scene!][0]
    // [Sprint 42 G1] The replay is the clip again, slowed down. None at the lowest tier.
    if (u < len) {
      fire('replay', () => {
        bubbleOn.value = false
        replaying.value = true
        sceneOn.value = true
        if (mainScene) {
          scene = mainScene
          showSvg(mainScene.svg)
          // The scene's world in a frame the second angle can turn round.
          const w = mainScene.svg.world as SVGElement | undefined
          if (w?.parentNode && !angleWrap) {
            angleWrap = document.createElementNS('http://www.w3.org/2000/svg', 'g')
            w.parentNode.insertBefore(angleWrap, w)
            angleWrap.appendChild(w)
          }
        }
      })
      // [Sprint 36 F4] Two angles at the full tier: halfway through, the director cuts to the reverse angle, closer.
      const angle = tier.value === 'high' && (u - (rp.off ?? 0)) / Math.max(0.01, len - (rp.off ?? 0)) > 0.5 ? 2 : 1
      if (angle !== replayAngle.value) {
        replayAngle.value = angle
        if (angleWrap) angleWrap.setAttribute('transform', angle === 2 ? 'translate(320 130) scale(-1.3 1.3) translate(-320 -130)' : '')
      }
      if (!smooth.value || now - drawn >= 32) {
        drawn = now
        draw(u)
      }
    } else
      fire('replay-end', () => {
        replaying.value = false
        sceneOn.value = false
        replayAngle.value = 1
        showBubble()
        studio.reactTo(p.s, p.tick.tick)
      })
  }
  // The commentator's bubble leaves before the minute ends: a calm pause on the timeline before the next scene.
  if (!p.replay && t >= (scene ? Math.min(total, sceneT + p.cutT + 2.8) : total))
    fire('done', () => {
      bubbleOn.value = false
    })
}

// ---------------------------------------------------------------- [Sprint 42 H1] the studio
const studio = useStudio(
  studioHost,
  () => props.kits,
  () => props.seed,
  () => ({
    clock: bclock.shown(),
    score: `${props.score.away} - ${props.score.home}`,
    frozen: frozen.value,
    covered: sceneOn.value,
    talking: bubbleOn.value,
  }),
)
watch(
  () => [props.kits, props.seed],
  () => studio.build(),
  { deep: true },
)
// [Sprint 43 C7, Hamza 2026-11-05] The broadcast's light follows the coach's look: day by day, night at night.
const lightOf = () => (theme.value === 'light' ? 'day' : 'night')
watch(theme, () => {
  setLight(lightOf())
  studio.build()
})
watch(
  () => [props.kickoff, props.seed],
  () => setLight(lightOf()),
  { immediate: true },
)
onMounted(studio.build)

// [Sprint 36 F3] The rain falls in the scenes (from the seed; MomentClock::rainy on the server, keep the two in step).
const rainy = () => (Number(props.seed) || 0) % 6 === 1
watch(
  () => props.seed,
  () => setRain(rainy()),
  { immediate: true },
)
onMounted(() => {
  raf = requestAnimationFrame((n) => {
    last = n
    frame(n)
  })
  bgTimer = window.setInterval(() => {
    if (document.hidden) step(performance.now())
  }, 200)
})
onBeforeUnmount(() => {
  cancelAnimationFrame(raf)
  clearInterval(bgTimer)
})
</script>

<style scoped src="./MatchFeed.css"></style>
