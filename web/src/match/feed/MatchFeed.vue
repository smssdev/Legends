<template>
  <div ref="host" class="mc" dir="rtl" :style="{ '--H': kits.home.kit, '--A': kits.away.kit }">
    <div class="atmo" aria-hidden="true" />

    <div class="sb">
      <div class="sb-in">
        <div class="side" :style="{ '--c': kits.home.kit }"><span class="crest" v-html="crestOf('home')" /><span class="nm"><b>{{ clubs.home }}</b><small>{{ coachLine('home') }}</small></span></div>
        <div class="mid"><span class="score" :class="{ pop }" dir="ltr">{{ score.away }} - {{ score.home }}</span><span class="live" dir="ltr"><i />{{ minute }}</span></div>
        <div class="side away" :style="{ '--c': kits.away.kit }"><span class="crest" v-html="crestOf('away')" /><span class="nm"><b>{{ clubs.away }}</b><small>{{ coachLine('away') }}</small></span></div>
      </div>
      <div class="mom" dir="ltr"><i :style="{ width: 100 - mom + '%', background: kits.away.kit }" /><i :style="{ width: mom + '%', background: kits.home.kit }" /></div>
    </div>

    <div class="tl" aria-label="مجريات المباراة" aria-live="polite">
      <div class="spine" />
      <TransitionGroup name="row" tag="div" class="list">
        <div v-for="it in items" :key="it.key" class="row" :class="it.center ? 'home' : it.side">
          <div class="card" :class="{ goal: it.goal }" :style="{ '--c': it.center ? '#F5B82E' : kits[it.side].kit }">
            <span class="ico" v-html="ICON[it.icon]" />
            <span class="tx"><b dir="auto">{{ it.name }}</b><span>{{ it.label }}</span></span>
            <span v-if="it.goal && it.score" class="chip" dir="ltr">{{ it.score }}</span>
          </div>
          <div class="node" dir="ltr">{{ it.minute }}</div>
        </div>
      </TransitionGroup>
    </div>

    <div class="moment" :class="{ on: sceneOn, tense }">
      <div class="mbox">
        <div ref="stage" class="stage" :class="{ shake }" />
        <!-- The goal: the scorer's name in his colours and confetti, after the ball is in. -->
        <div v-if="party" class="party" :style="{ '--c': kits[party.side].kit, '--t': kits[party.side].trim }" aria-hidden="true">
          <i v-for="c in confetti" :key="c.i" :style="c.style" />
          <span class="burst"><b>{{ party.who }}</b><small>{{ clubs[party.side] }}</small></span>
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
      <span class="kick">{{ live ? 'مباراة بين صديقين' : 'ما قبل المباراة' }}</span>
      <span v-if="live && countdown > 0" class="plan">الصافرة بعد <b dir="ltr">{{ countdown }}</b> ثانية · عدّل تشكيلتك وخطتك من لوحة المدرب الآن</span>
      <div class="teams">
        <div class="team"><span class="crest" v-html="crestOf('home')" /><b>{{ clubs.home }}</b><small>{{ coachLine('home') }}</small></div>
        <span class="vs">VS</span>
        <div class="team"><span class="crest" v-html="crestOf('away')" /><b>{{ clubs.away }}</b><small>{{ coachLine('away') }}</small></div>
      </div>
      <div class="stats">
        <div v-for="r in compare" :key="r.label" class="st"><span>{{ r.h }}</span><span class="bar"><i :style="{ width: r.hp + '%', background: kits.home.kit }" /><i :style="{ width: 100 - r.hp + '%', background: kits.away.kit }" /></span><span>{{ r.a }}</span><span class="lbl">{{ r.label }}</span></div>
      </div>
      <div class="keys">
        <div v-for="s in (['home', 'away'] as const)" :key="s" class="key" :style="{ '--c': kits[s].kit }"><span class="no">{{ star(s)?.no }}</span><span><b>{{ star(s)?.name }}</b><span>مفتاح {{ clubs[s] }} · {{ star(s)?.ovr }}</span></span></div>
      </div>
      <button type="button" class="go" @click="$emit('introDone')">{{ live ? (countdown > 0 ? `البداية بعد ${countdown}` : 'شغّل الصوت وانتظر البداية') : 'ابدأ البث' }}</button>
    </div>
  </div>
</template>

<script setup lang="ts">
// @ts-nocheck
// The match feed (docs/MATCH_VIEW.md 4.6): each minute plays its scene first,
// then its card joins the timeline and the commentator sums it up on the mic
// bar. The parent calls play(tick) per minute; the minute's length is the
// server's (tick.moment.ms).
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { ICON, SCENES, crest, setKits } from './art'
import { SCENE_TIME, story } from './story'
import { voiceLine, type Lang } from '../voice'

const props = defineProps<{ kits: any; clubs: { home: string; away: string }; codes: { home: string; away: string }; strength: { home: number; away: number }; coaches: any; teams: any; seed: number; speed: number; minute: string; score: { home: number; away: number }; mine: string | null; lang: Lang | 'off'; intro: boolean; live: boolean; countdown: number }>()
const emit = defineEmits<{ cue: [name: string]; sound: [name: string]; say: [line: any]; introDone: [] }>()

const host = ref<HTMLElement>(), stage = ref<HTMLElement>()
const items = ref<any[]>([])
const cur = ref<any>(null)
const sceneOn = ref(false), bubbleOn = ref(false), shake = ref(false), pop = ref(false)
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
const crestOf = (s) => crest([props.kits[s].kit, props.kits[s].trim, props.codes[s] || ''])
const coachLine = (s) => [props.coaches?.[s] ?? (props.mine === s ? 'أنت' : props.live ? '' : props.mine ? 'الحاسوب' : ''), props.teams?.[s]?.formation].filter(Boolean).join(' · ')
watch(() => props.kits, (k) => setKits(k), { immediate: true, deep: true })
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
let raf = 0, last = 0, t = 0, plan: any = null, scene: any = null, keySeq = 0
// startAt (live): when the minute starts on performance.now(). The scene follows that clock
// instead of counting frames, so two screens stay on the same instant even if one is slow.
function play(tick, startAt = null) {
  finish()
  const s = story(tick, { players: players.value, clubs: props.clubs, seed: props.seed, mine: props.mine })
  const total = (tick.moment?.ms ?? 3000) / 1000
  const nominal = s.scene ? SCENE_TIME[s.scene][0] : 0
  // The scene takes most of the minute; the commentator sums it up after.
  const sceneT = s.scene ? Math.min(nominal, total * 0.72) : 0
  plan = { s, total, sceneT, rate: s.scene ? nominal / sceneT : 1, fired: new Set(), itemsAdded: false, score: `${tick.score.away} - ${tick.score.home}`, startAt }
  mom.value = Math.max(15, Math.min(85, 50 + (tick.danger ?? 0) * 7))
  cur.value = s
  revealed.value = !s.pre
  // The stadium holds its breath before a penalty or a free kick on the edge of the box.
  tense.value = s.scene === 'penalty' || s.scene === 'freekick'
  party.value = null
  t = startAt === null ? 0 : Math.max(0, (performance.now() - startAt) / 1000)
  if (s.scene) {
    scene = SCENES[s.scene]({ ...s.data, side: s.side })
    stage.value.replaceChildren(scene.svg)
    scene.update(0)
    sceneOn.value = true
  } else {
    scene = null
    addItems()
    if (s.bubble && s.items.length) showBubble()
  }
}
// The scene is over: its cards join the timeline, and the page may tell the result (cue 'reveal').
function addItems(tell = true) {
  if (!plan || plan.itemsAdded) return
  plan.itemsAdded = true
  if (tell) emit('cue', 'reveal')
  for (const it of plan.s.items) items.value.unshift({ ...it, key: ++keySeq, score: it.goal ? plan.score : null })
  if (items.value.length > 40) items.value.length = 40
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
  card: [[0.05, 'whistle'], ['key', 'murmur']], offside: [['key', 'whistle']], corner: [[0.35, 'kick'], ['key', 'kick']], whistle: [[0.1, 'whistle']], sub: [[0.1, 'beep']], board: [[0.1, 'beep']], injury: [[0.1, 'whistle']],
}
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000) * (props.speed || 1)
  last = now
  if (plan) {
    t = plan.startAt === null ? t + dt : Math.max(0, (now - plan.startAt) / 1000)
    const { s, total, sceneT, rate, fired } = plan
    const fire = (k, fn) => { if (!fired.has(k)) { fired.add(k); fn() } }
    // A line or a sound long past (the screen joined late) is dropped, not played out of time.
    const cue = (k, at, fn) => fire(k, () => t - at < 0.6 && fn())
    if (scene && t < sceneT) scene.update(t * rate)
    const keyT = s.keyAt * sceneT
    // Commentary: line times are fractions of the scene (or of the minute when there is none).
    for (const [i, l] of s.lines.entries()) { const at = l.at * (sceneT || total * 0.5); if (t >= at) cue('l' + i, at, () => props.lang !== 'off' && emit('say', voiceLine(props.lang, l, players.value, props.clubs))) }
    for (const [i, [at, name]] of (SOUNDS[s.scene] ?? []).entries()) { const when = at === 'key' ? keyT : at * sceneT; if (t >= when) cue('s' + i, when, () => emit('sound', name)) }
    if (s.scene === 'miss' && s.data.how === 'post' && t >= keyT) cue('post', keyT, () => emit('sound', 'post'))
    if (t >= keyT) fire('key', () => { revealed.value = true; tense.value = false })
    if (s.goal && t >= keyT) fire('goal', () => {
      emit('cue', 'goal'); shake.value = true; setTimeout(() => (shake.value = false), 500)
      party.value = { side: s.side, who: s.who }
    })
    if (scene && t >= sceneT) fire('end', () => { sceneOn.value = false; party.value = null; addItems(); showBubble() })
    // The commentator's bubble leaves before the minute ends: a calm pause on the timeline before the next scene.
    if (t >= (scene ? Math.min(total, sceneT + 2.8) : total)) fire('done', () => { bubbleOn.value = false })
  }
  raf = requestAnimationFrame(frame)
}

onMounted(() => { raf = requestAnimationFrame((n) => { last = n; frame(n) }) })
onBeforeUnmount(() => cancelAnimationFrame(raf))
</script>

<style scoped>
/* Brand navy and gold; each team's colour is light from its side. */
.mc { position: absolute; inset: 0; overflow: hidden; isolation: isolate; color: #F7F4EA; font-family: 'IBM Plex Sans Arabic', system-ui, sans-serif; container-type: size; background: #050D1F }
.atmo { position: absolute; inset: 0; z-index: -1; background:
  radial-gradient(60% 50% at 100% 20%, color-mix(in srgb, var(--H) 22%, transparent), transparent 70%),
  radial-gradient(60% 50% at 0% 20%, color-mix(in srgb, var(--A) 26%, transparent), transparent 70%),
  radial-gradient(90% 70% at 50% 110%, rgba(245,184,46,.14), transparent 60%),
  linear-gradient(180deg, #0B2149, #050D1F 70%) }
.atmo::before { content: ''; position: absolute; inset: -20%; background: repeating-linear-gradient(115deg, transparent 0 120px, rgba(255,255,255,.035) 120px 180px, transparent 180px 300px); animation: beams 18s linear infinite }
@keyframes beams { to { transform: translateX(300px) } }

.sb { position: absolute; top: 10px; left: 10px; right: 10px; z-index: 6 }
.sb-in { display: grid; grid-template-columns: 1fr auto 1fr; align-items: stretch; border-radius: 16px; overflow: hidden; background: rgba(16,40,79,.62); backdrop-filter: blur(14px); border: 1px solid rgba(255,255,255,.09); box-shadow: 0 18px 40px rgba(0,0,0,.45) }
.side { display: flex; align-items: center; gap: 10px; padding: 8px 12px; min-width: 0; position: relative }
.side::before { content: ''; position: absolute; inset: 0; opacity: .22; background: linear-gradient(90deg, transparent, var(--c)) }
.side.away { flex-direction: row-reverse; text-align: left }
.side.away::before { background: linear-gradient(270deg, transparent, var(--c)) }
.nm { position: relative; min-width: 0; display: grid }
.nm b { font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: clamp(13px, 3.4cqw, 21px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.nm small { color: #93A3BF; font-size: 12px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.crest { width: clamp(32px, 6cqw, 50px); flex: none; position: relative; filter: drop-shadow(0 4px 10px rgba(0,0,0,.5)) }
.crest :deep(svg) { display: block; width: 100%; height: auto }
.mid { display: grid; justify-items: center; align-content: center; padding: 4px 14px; background: linear-gradient(180deg, rgba(5,13,31,.75), rgba(5,13,31,.95)); border-inline: 1px solid rgba(255,255,255,.09) }
.score { font-family: 'Barlow Condensed', 'Alexandria', sans-serif; font-weight: 800; font-size: clamp(30px, 7.5cqw, 50px); line-height: .95; letter-spacing: .04em; color: #fff; font-variant-numeric: tabular-nums }
.score.pop { animation: pop .7s }
@keyframes pop { 25% { transform: scale(1.25); color: #FFD36B; text-shadow: 0 0 18px #F5B82E } }
.live { display: flex; align-items: center; gap: 6px; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 16px; letter-spacing: .06em; color: #FFD36B }
.live i { width: 7px; height: 7px; border-radius: 50%; background: #EF4444; animation: ping 1.4s infinite }
@keyframes ping { 0% { box-shadow: 0 0 0 0 rgba(239,68,68,.7) } 70% { box-shadow: 0 0 0 7px rgba(239,68,68,0) } }
.mom { height: 3px; display: flex; margin: 0 14px; border-radius: 2px; overflow: hidden }
.mom i { display: block; height: 100%; transition: width .8s }

.tl { position: absolute; top: clamp(84px, 16cqw, 106px); bottom: 70px; left: 0; right: 0; overflow: hidden; mask-image: linear-gradient(180deg, transparent, #000 26px, #000 82%, transparent) }
.spine { position: absolute; top: 0; bottom: 0; left: 50%; width: 2px; transform: translateX(-50%); background: linear-gradient(180deg, transparent, rgba(245,184,46,.55) 10%, rgba(245,184,46,.15)) }
.list { position: relative; padding: 22px 10px 0; display: grid; gap: 10px }
.row { display: grid; grid-template-columns: 1fr 54px 1fr; align-items: center }
.row .node { grid-column: 2; grid-row: 1 }
.row .card { grid-row: 1; grid-column: 1 }
.row.away .card { grid-column: 3; flex-direction: row-reverse; text-align: left; border-inline-start: 1px solid rgba(255,255,255,.09); border-inline-end: 3px solid var(--c) }
.row-enter-active { transition: all .55s cubic-bezier(.2,.9,.25,1.15) }
.row-enter-from { opacity: 0; transform: translateY(-14px) scale(.97) }
.node { margin: auto; min-width: 46px; height: 26px; padding: 0 6px; border-radius: 13px; display: grid; place-items: center; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 16px; color: #FFD36B; background: #071733; border: 1px solid rgba(245,184,46,.55); box-shadow: 0 0 14px rgba(245,184,46,.18) }
.card { display: flex; align-items: center; gap: 10px; min-width: 0; padding: 7px 11px; border-radius: 14px; background: rgba(16,40,79,.62); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,.09); border-inline-start: 3px solid var(--c); box-shadow: 0 10px 24px rgba(0,0,0,.35) }
.ico { width: 36px; height: 36px; flex: none; border-radius: 11px; display: grid; place-items: center; background: linear-gradient(160deg, rgba(255,255,255,.1), rgba(255,255,255,.02)); border: 1px solid rgba(255,255,255,.09) }
.ico :deep(svg) { width: 22px; height: 22px }
.card .tx { min-width: 0; display: grid }
.card .tx b { font-family: 'Alexandria', sans-serif; font-weight: 700; font-size: clamp(13px, 2.7cqw, 16px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
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

.moment { position: absolute; inset: 0; z-index: 8; display: grid; place-items: center; opacity: 0; pointer-events: none; transition: opacity .35s }
.moment.on { opacity: 1 }
.moment::before { content: ''; position: absolute; inset: 0; background: rgba(3,8,20,.7); backdrop-filter: blur(6px) }
.mbox { position: relative; width: min(94cqw, 780px, calc((100cqh - 30px) * 1.5)); border-radius: 20px; overflow: hidden; background: #040B1C; border: 1px solid rgba(245,184,46,.28); box-shadow: 0 30px 80px rgba(0,0,0,.7); transform: translateY(14px) scale(.96); transition: transform .45s cubic-bezier(.2,.9,.25,1.15) }
.moment.on .mbox { transform: none }
.stage :deep(svg) { display: block; width: 100%; height: auto }
.stage.shake { animation: shake .45s }
@keyframes shake { 20% { transform: translate(-6px, 3px) } 40% { transform: translate(5px, -4px) } 60% { transform: translate(-4px, 2px) } 80% { transform: translate(3px, -1px) } }
.lower { display: flex; align-items: center; gap: 14px; padding: 10px 16px; background: linear-gradient(90deg, color-mix(in srgb, var(--c) 55%, #071733), #071733 55%); border-top: 1px solid rgba(255,255,255,.08) }
.lower .ev { font-family: 'Alexandria', sans-serif; font-weight: 900; font-size: clamp(17px, 4cqw, 27px); color: #FFD36B }
.lower .who { display: grid; min-width: 0 }
.lower .who b { font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: clamp(14px, 3cqw, 18px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.lower .who span { color: #C9D2E1; font-size: 12px }
.lower .min { margin-inline-start: auto; font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 22px; opacity: .9 }

.mic { position: absolute; z-index: 9; left: 10px; right: 10px; bottom: 10px; display: flex; align-items: center; gap: 12px; padding: 9px 13px; border-radius: 16px; background: linear-gradient(90deg, rgba(10,31,66,.94), rgba(7,23,51,.94)); border: 1px solid rgba(245,184,46,.35); box-shadow: 0 14px 30px rgba(0,0,0,.5); backdrop-filter: blur(10px); transform: translateY(140%); transition: transform .45s cubic-bezier(.2,.9,.25,1.1) }
.mic.on { transform: none }
.mic .m { width: 38px; height: 38px; flex: none; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle at 35% 30%, #FFD36B, #C08A0C) }
.mic .m svg { width: 19px; height: 19px }
.wave { display: flex; align-items: center; gap: 3px; height: 24px; flex: none }
.wave i { width: 3px; border-radius: 2px; background: #F5B82E; height: 30%; animation: w .9s ease-in-out infinite }
.wave i:nth-child(2n) { animation-delay: -.3s } .wave i:nth-child(3n) { animation-delay: -.6s } .wave i:nth-child(5n) { animation-delay: -.15s }
@keyframes w { 50% { height: 100% } }
.mic .tx { min-width: 0; display: grid; gap: 1px }
.mic .tx b { font-weight: 600; font-size: clamp(13px, 2.8cqw, 16px); line-height: 1.55 }
.mic .tx span { text-align: left; color: #FFD36B; font-size: 12px; font-weight: 600 }

.preview { position: absolute; inset: 0; z-index: 12; display: grid; align-content: center; justify-items: center; gap: 16px; padding: 16px; overflow-y: auto; background: radial-gradient(70% 60% at 50% 40%, rgba(245,184,46,.12), transparent 70%), linear-gradient(180deg, #0B2149, #050D1F) }
.plan { font-size: 14px; color: #C9D2E1; text-align: center }
.plan b { font-family: 'Barlow Condensed', sans-serif; font-size: 22px; color: #FFD36B }
.kick { font-family: 'Alexandria', sans-serif; font-weight: 700; color: #FFD36B; letter-spacing: .06em; font-size: 13px }
.teams { display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: clamp(10px, 4cqw, 40px); width: min(100%, 720px) }
.team { display: grid; justify-items: center; gap: 6px; text-align: center; min-width: 0 }
.team .crest { width: clamp(64px, 15cqw, 116px) }
.team b { font-family: 'Alexandria', sans-serif; font-weight: 900; font-size: clamp(17px, 4.4cqw, 28px) }
.team small { color: #93A3BF; font-weight: 600 }
.vs { font-family: 'Barlow Condensed', sans-serif; font-style: italic; font-weight: 800; font-size: clamp(32px, 9cqw, 62px); color: #F5B82E; text-shadow: 0 0 24px rgba(245,184,46,.35) }
.stats { width: min(100%, 560px); display: grid; gap: 10px; padding: 12px 16px; border-radius: 16px; background: rgba(16,40,79,.62); border: 1px solid rgba(255,255,255,.09) }
.st { display: grid; grid-template-columns: 44px 1fr 44px; align-items: center; gap: 10px; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 20px; text-align: center }
.st > * { grid-row: 2 }
.st .lbl { grid-column: 1 / -1; grid-row: 1; font-family: 'IBM Plex Sans Arabic', sans-serif; font-size: 12px; color: #93A3BF; margin-bottom: -6px }
.st .bar { height: 6px; border-radius: 3px; background: rgba(255,255,255,.08); display: flex; overflow: hidden }
.st .bar i { display: block; height: 100% }
.keys { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; width: min(100%, 560px) }
.key { display: flex; align-items: center; gap: 10px; padding: 9px 12px; border-radius: 14px; background: rgba(16,40,79,.62); border: 1px solid rgba(255,255,255,.09); border-inline-start: 3px solid var(--c); min-width: 0 }
.key .no { font-family: 'Barlow Condensed', sans-serif; font-weight: 800; font-size: 28px; color: var(--c); width: 32px; text-align: center }
.key b { font-family: 'Alexandria', sans-serif; font-size: 14px; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.key span span { color: #93A3BF; font-size: 12px }
.go { min-height: 50px; padding: 0 34px; border-radius: 14px; border: 0; font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: 17px; color: #050D1F; background: linear-gradient(180deg, #FFD36B, #F5B82E); box-shadow: 0 10px 30px rgba(245,184,46,.35); cursor: pointer }
.go:focus-visible { outline: 3px solid #fff; outline-offset: 2px }
@container (max-width: 560px) { .keys { grid-template-columns: 1fr } }

/* Tension: the edges darken and pulse like a heartbeat until the kick. */
.moment.tense .mbox { box-shadow: 0 30px 80px rgba(0,0,0,.7), 0 0 0 2px rgba(239,68,68,.35); animation: beat 1.1s ease-in-out infinite }
.moment.tense::after { content: ''; position: absolute; inset: 0; pointer-events: none; background: radial-gradient(70% 70% at 50% 50%, transparent 55%, rgba(120,10,10,.45)); animation: beat 1.1s ease-in-out infinite }
@keyframes beat { 0%, 100% { opacity: 1 } 15% { opacity: .65 } 30% { opacity: 1 } 45% { opacity: .8 } }

.party { position: absolute; inset: 0 0 auto; aspect-ratio: 640 / 340; overflow: hidden; pointer-events: none }
.party i { position: absolute; top: -12px; width: 8px; height: 13px; border-radius: 2px; animation: fall linear forwards }
@keyframes fall { to { top: 105%; transform: rotate(540deg) translateX(30px) } }
.party .burst { position: absolute; left: 50%; bottom: 10%; transform: translateX(-50%); display: grid; justify-items: center; padding: 6px 18px; border-radius: 12px; background: color-mix(in srgb, var(--c) 80%, #071733); border: 2px solid #F5B82E; box-shadow: 0 10px 30px rgba(0,0,0,.5); animation: burst .6s cubic-bezier(.2,.9,.25,1.4) .35s both }
.party .burst b { font-family: 'Alexandria', sans-serif; font-weight: 900; font-size: clamp(16px, 4cqw, 26px); white-space: nowrap }
.party .burst small { color: #FFD36B; font-weight: 700; font-size: 12px }
@keyframes burst { from { opacity: 0; transform: translateX(-50%) scale(.4) } }

.reacts { position: absolute; inset: 0; z-index: 11; pointer-events: none; overflow: hidden }
.rx { position: absolute; bottom: 70px; display: flex; align-items: center; gap: 6px; padding: 4px 12px 4px 6px; border-radius: 999px; background: rgba(7,23,51,.9); border: 1px solid color-mix(in srgb, var(--c) 70%, #fff); box-shadow: 0 8px 22px rgba(0,0,0,.45); animation: rise 3.2s ease-out forwards }
.rx.home { right: var(--x) }
.rx.away { left: var(--x) }
.rx .e { font-size: 30px; line-height: 1 }
.rx .t { display: grid; font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: 14px; line-height: 1.25 }
.rx .t small { color: #93A3BF; font-size: 11px; font-weight: 600 }
@keyframes rise { 0% { opacity: 0; transform: translateY(20px) scale(.6) } 12% { opacity: 1; transform: translateY(0) scale(1.08) } 20% { transform: scale(1) } 80% { opacity: 1 } 100% { opacity: 0; transform: translateY(-160px) } }
.rx-leave-active { transition: opacity .3s }
.rx-leave-to { opacity: 0 }

@media (prefers-reduced-motion: reduce) { .atmo::before, .wave i, .live i, .moment.tense .mbox, .moment.tense::after, .party i { animation: none } .party i { display: none } }
</style>
