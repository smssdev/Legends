<template>
  <div ref="host" class="feed-root" dir="rtl">
    <canvas ref="bg" class="bg" aria-hidden="true" />

    <div class="board">
      <div class="club"><span class="crest" v-html="crestOf('home')" /><b>{{ clubs.home }}</b></div>
      <div class="mid">
        <span class="score" :class="{ pop }" dir="ltr">{{ score.home }} - {{ score.away }}</span>
        <span class="clock" dir="ltr">{{ minute }}</span>
      </div>
      <div class="club away"><span class="crest" v-html="crestOf('away')" /><b>{{ clubs.away }}</b></div>
    </div>

    <div class="feed" aria-label="مجريات المباراة" aria-live="polite">
      <div class="spine" />
      <TransitionGroup name="row" tag="div" class="list">
        <div v-for="it in items" :key="it.key" class="row" :class="it.center ? 'center' : it.side">
          <div v-if="it.center" class="ev mid-ev"><span class="ic" v-html="ICON[it.icon]" /><span class="tx"><b>{{ it.name }}</b><span>{{ it.label }}</span></span></div>
          <template v-else>
            <div class="ev" :class="[it.side, { goal: it.goal }]"><span class="ic" v-html="ICON[it.icon]" /><span class="tx"><b dir="auto">{{ it.name }}</b><span>{{ it.label }}</span></span></div>
            <div class="node" dir="ltr">{{ it.minute }}</div>
          </template>
        </div>
      </TransitionGroup>
    </div>

    <div class="scene" :class="{ on: sceneOn }">
      <div class="sbox">
        <div ref="stage" class="stage" :class="{ shake }" />
        <div class="sbar" :style="{ '--kit': barKit }">
          <span class="big">{{ cur?.head }}</span>
          <span class="who"><b dir="auto">{{ cur?.who }}</b><span>{{ cur?.sub }}</span></span>
          <span class="min" dir="ltr">{{ cur?.minute }}</span>
        </div>
      </div>
    </div>

    <div class="caster" :class="{ on: bubbleOn }">
      <div class="bubble"><span>{{ bubble }}</span><span v-if="lang === 'en' && enLine" class="en" dir="ltr">{{ enLine }}</span></div>
      <div class="who" v-html="casterSvg" />
    </div>

    <div v-if="intro" class="studio">
      <div class="screen">LEGENDS</div>
      <div class="desk" />
      <div class="host a" v-html="hostA" />
      <div class="host b" v-html="hostB" />
      <div class="sbubble">{{ introLine }}</div>
      <button type="button" class="go" @click="$emit('introDone')">{{ live ? 'بانتظار صافرة البداية' : 'ابدأ المباراة' }}</button>
    </div>
  </div>
</template>

<script setup lang="ts">
// @ts-nocheck
// The match feed (docs/MATCH_VIEW.md 4.6): each minute plays its scene first,
// then its card joins the timeline and the commentator sums it up. The parent
// calls play(tick) per minute; the minute's length is the server's (tick.moment.ms).
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { CASTER, HOST_A, HOST_B, ICON, SCENES, crest, paintBg, person, setKits } from './art'
import { SCENE_TIME, story } from './story'
import { voiceLine, type Lang } from '../voice'

const props = defineProps<{ kits: any; clubs: { home: string; away: string }; codes: { home: string; away: string }; teams: any; seed: number; speed: number; minute: string; score: { home: number; away: number }; mine: string | null; lang: Lang | 'off'; intro: boolean; live: boolean }>()
const emit = defineEmits<{ cue: [name: string]; sound: [name: string]; say: [line: any]; introDone: [] }>()

const host = ref<HTMLElement>(), bg = ref<HTMLCanvasElement>(), stage = ref<HTMLElement>()
const items = ref<any[]>([])
const cur = ref<any>(null)
const sceneOn = ref(false), bubbleOn = ref(false), shake = ref(false), pop = ref(false)
const bubble = ref(''), enLine = ref('')
const casterSvg = person(CASTER), hostA = person(HOST_A), hostB = person(HOST_B)
// The caption bar takes the kit colour, unless it is too light for white text.
const barKit = computed(() => {
  const k = props.kits[cur.value?.side === 'away' ? 'away' : 'home'].kit, n = parseInt(k.slice(1), 16)
  return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) > 150 ? '#3A5F9E' : k
})
const crestOf = (s) => crest([props.kits[s].kit, props.kits[s].trim, props.codes[s] || ''])
watch(() => props.kits, (k) => setKits(k), { immediate: true, deep: true })
watch(() => props.score, () => { pop.value = false; requestAnimationFrame(() => (pop.value = true)) }, { deep: true })

// Every player of the match by id, for names and shirt numbers.
const players = computed(() => {
  const m = {}
  for (const side of ['home', 'away']) for (const p of props.teams?.[side]?.players ?? []) m[p.id] = { name: p.name, no: p.no, side }
  return m
})

// ---------------------------------------------------------------- playing a minute
let raf = 0, last = 0, t = 0, plan: any = null, scene: any = null, keySeq = 0
function play(tick) {
  finish()
  const s = story(tick, { players: players.value, clubs: props.clubs, seed: props.seed, mine: props.mine })
  const total = (tick.moment?.ms ?? 3000) / 1000
  const nominal = s.scene ? SCENE_TIME[s.scene][0] : 0
  // The scene takes most of the minute; the commentator sums it up after.
  const sceneT = s.scene ? Math.min(nominal, total * 0.72) : 0
  plan = { s, total, sceneT, rate: s.scene ? nominal / sceneT : 1, fired: new Set(), itemsAdded: false }
  cur.value = s
  t = 0
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
function addItems() {
  if (!plan || plan.itemsAdded) return
  plan.itemsAdded = true
  for (const it of plan.s.items) items.value.unshift({ ...it, key: ++keySeq })
  if (items.value.length > 40) items.value.length = 40
}
function showBubble() {
  const s = plan.s
  bubble.value = s.bubble
  const en = s.lines.find((l) => l.x)?.en ?? s.lines[0]?.en
  enLine.value = en ? voiceLine('en', { en, ar: null, x: false, vars: s.lines[0]?.vars ?? {} }, players.value, props.clubs)?.text ?? '' : ''
  bubbleOn.value = !!s.bubble
}
// Finish the minute at once: the next one is starting, or the viewer skipped.
function finish() {
  if (!plan) return
  sceneOn.value = false
  addItems()
  bubbleOn.value = false
  plan = null
}
function skip() { finish() }
defineExpose({ play, skip })

const SOUNDS = {
  goal: [[0.3, 'kick'], ['key', 'kick'], ['key', 'roar']], save: [[0.3, 'kick'], ['key', 'groan']], miss: [[0.3, 'kick'], ['key', 'groan']], blocked: [['key', 'thud'], ['key', 'groan']],
  penalty: [[0.05, 'whistle-long'], [0.35, 'hush'], ['key', 'kick'], ['key', 'roar']], freekick: [[0.05, 'whistle'], ['key', 'kick'], ['key', 'roar']],
  card: [[0.05, 'whistle'], ['key', 'murmur']], offside: [['key', 'whistle']], corner: [[0.35, 'kick'], ['key', 'kick']], whistle: [[0.15, 'whistle']], sub: [[0.1, 'beep']], board: [[0.1, 'beep']], injury: [[0.1, 'whistle']],
}
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000) * (props.speed || 1)
  last = now
  if (plan) {
    t += dt
    const { s, total, sceneT, rate, fired } = plan
    const fire = (k, fn) => { if (!fired.has(k)) { fired.add(k); fn() } }
    if (scene && t < sceneT) scene.update(t * rate)
    const keyT = s.keyAt * sceneT
    // Commentary: line times are fractions of the scene (or of the minute when there is none).
    for (const [i, l] of s.lines.entries()) if (t >= l.at * (sceneT || total * 0.5)) fire('l' + i, () => props.lang !== 'off' && emit('say', voiceLine(props.lang, l, players.value, props.clubs)))
    for (const [i, [at, name]] of (SOUNDS[s.scene] ?? []).entries()) if (t >= (at === 'key' ? keyT : at * sceneT)) fire('s' + i, () => emit('sound', name))
    if (s.goal && t >= keyT) fire('goal', () => { emit('cue', 'goal'); shake.value = true; setTimeout(() => (shake.value = false), 500) })
    if (scene && t >= sceneT) fire('end', () => { sceneOn.value = false; addItems(); showBubble() })
    if (t >= total) fire('done', () => { bubbleOn.value = false })
  }
  raf = requestAnimationFrame(frame)
}

// ---------------------------------------------------------------- studio intro
const INTRO = computed(() => [
  `مساء الخير! الأجواء رائعة والمدرجات ممتلئة، والجميع ينتظر مواجهة ${props.clubs.home} و${props.clubs.away}.`,
  'مواجهة بين مدربين يعرف كل منهما أسلوب الآخر. التكتيك سيحسم هذه المباراة.',
  'كل شيء جاهز. لنذهب إلى الملعب!',
])
const introLine = ref('')
let introTimer = 0, introI = 0
function nextIntro() { introLine.value = INTRO.value[introI++ % INTRO.value.length]; introTimer = window.setTimeout(nextIntro, 3600) }
watch(() => props.intro, (on) => { clearTimeout(introTimer); if (on) { introI = 0; nextIntro() } }, { immediate: true })

let ro: ResizeObserver | null = null
onMounted(() => {
  ro = new ResizeObserver(() => bg.value && paintBg(bg.value))
  ro.observe(host.value!)
  raf = requestAnimationFrame((n) => { last = n; frame(n) })
})
onBeforeUnmount(() => { cancelAnimationFrame(raf); ro?.disconnect(); clearTimeout(introTimer) })
</script>

<style scoped>
.feed-root { position: absolute; inset: 0; overflow: hidden; isolation: isolate; color: #F7F4EA; font-family: 'IBM Plex Sans Arabic', system-ui, sans-serif; container-type: size }
.bg { position: absolute; inset: 0; width: 100%; height: 100%; z-index: -2; filter: blur(2px) saturate(1.1) }
.feed-root::before { content: ''; position: absolute; inset: 0; z-index: -1; background: radial-gradient(ellipse at 50% 40%, rgba(5,12,28,.25), rgba(5,12,28,.82) 75%) }

.board { position: absolute; top: 8px; left: 8px; right: 8px; z-index: 5; display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; gap: 8px; background: linear-gradient(180deg, rgba(10,31,66,.96), rgba(7,23,51,.9)); border: 1px solid #23406E; border-radius: 16px; padding: 8px 12px; box-shadow: 0 10px 30px rgba(0,0,0,.45) }
.club { display: flex; align-items: center; gap: 8px; min-width: 0 }
.club.away { flex-direction: row-reverse }
.club b { font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: clamp(13px, 3.4cqw, 22px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.crest { width: clamp(30px, 6cqw, 50px); flex: none; filter: drop-shadow(0 3px 6px rgba(0,0,0,.5)) }
.crest :deep(svg) { display: block; width: 100%; height: auto }
.mid { display: grid; justify-items: center; gap: 2px }
.score { font-family: 'Alexandria', sans-serif; font-weight: 900; font-size: clamp(24px, 6cqw, 40px); line-height: 1; font-variant-numeric: tabular-nums }
.score.pop { animation: pop .6s }
@keyframes pop { 30% { transform: scale(1.35); color: #F5B82E } }
.clock { font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: 13px; background: #1B4FB8; border: 2px solid #8EB2F0; border-radius: 999px; padding: 1px 10px }

.feed { position: absolute; top: clamp(76px, 15cqw, 104px); bottom: 0; left: 0; right: 0; overflow: hidden; mask-image: linear-gradient(180deg, transparent 0, #000 24px, #000 80%, transparent) }
.spine { position: absolute; top: 0; bottom: 0; left: 50%; width: 6px; transform: translateX(-50%); background: linear-gradient(180deg, #1B4FB8, #0D2C66); border-radius: 3px; opacity: .9 }
.list { position: relative; padding: 24px 10px 0; display: grid; gap: 12px }
.row { display: grid; grid-template-columns: 1fr 46px 1fr; align-items: center }
.row.home .ev { grid-column: 1; grid-row: 1 }
.row.away .ev { grid-column: 3; grid-row: 1; flex-direction: row-reverse; text-align: left }
.row .node { grid-column: 2; grid-row: 1 }
.row.center { grid-template-columns: 1fr }
.row.center .ev { justify-self: center; z-index: 1 }
.row-enter-active { transition: all .5s cubic-bezier(.2,.9,.3,1.2) }
.row-enter-from { opacity: 0; transform: translateY(-16px) }
.node { width: 40px; height: 40px; margin: auto; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle at 35% 30%, #3F7EF0, #163F94); border: 2px solid #8EB2F0; font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: 12px; box-shadow: 0 4px 10px rgba(0,0,0,.4) }
.ev { display: flex; align-items: center; gap: 8px; min-width: 0; background: rgba(10,31,66,.86); border: 1px solid #23406E; padding: 6px 10px; border-radius: 999px; box-shadow: 0 6px 18px rgba(0,0,0,.35) }
.ev .ic { width: 40px; height: 40px; flex: none; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle at 35% 30%, #1E4A8F, #0B2350); border: 2px solid rgba(255,255,255,.12) }
.ev .ic :deep(svg) { width: 26px; height: 26px }
.ev .tx { min-width: 0; display: grid }
.ev .tx b { font-family: 'Alexandria', sans-serif; font-weight: 700; font-size: clamp(13px, 2.6cqw, 16px); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.ev .tx span { color: #A9B6CC; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.ev.goal { border-color: #F5B82E; background: linear-gradient(90deg, rgba(245,184,46,.22), rgba(10,31,66,.9)) }
.ev.goal .tx span { color: #F5B82E; font-weight: 700 }
.mid-ev { border-color: #8EB2F0 }

.scene { position: absolute; inset: 0; z-index: 8; display: grid; place-items: center; pointer-events: none; opacity: 0; transition: opacity .3s }
.scene.on { opacity: 1 }
.scene::before { content: ''; position: absolute; inset: 0; background: rgba(3,8,20,.62); backdrop-filter: blur(3px) }
.sbox { position: relative; width: min(94cqw, 620px, calc((100cqh - 60px) * 1.55)); border-radius: 20px; overflow: hidden; border: 1px solid rgba(255,255,255,.14); box-shadow: 0 24px 60px rgba(0,0,0,.6); transform: scale(.92); transition: transform .35s cubic-bezier(.2,.9,.3,1.25) }
.scene.on .sbox { transform: none }
.stage :deep(svg) { display: block; width: 100%; height: auto; background: #0B1730 }
.stage.shake { animation: shake .45s }
@keyframes shake { 20% { transform: translate(-6px, 3px) } 40% { transform: translate(5px, -4px) } 60% { transform: translate(-4px, 2px) } 80% { transform: translate(3px, -1px) } }
.sbar { display: flex; align-items: center; gap: 12px; padding: 8px 14px 10px; background: linear-gradient(90deg, var(--kit, #1B4FB8), rgba(10,31,66,.98) 45%) }
.sbar .big { font-family: 'Alexandria', sans-serif; font-weight: 900; font-size: clamp(18px, 4.4cqw, 28px) }
.sbar .who { display: grid; min-width: 0 }
.sbar .who b { font-family: 'Alexandria', sans-serif; font-weight: 700; font-size: 16px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
.sbar .who span { color: #A9B6CC; font-size: 12px }
.sbar .min { margin-inline-start: auto; font-family: 'Alexandria', sans-serif; font-weight: 800; color: #F5B82E }

.caster { position: absolute; z-index: 9; bottom: 6px; right: 6px; left: 6px; display: flex; align-items: flex-end; justify-content: flex-start; pointer-events: none; transform: translateY(120%); transition: transform .45s cubic-bezier(.2,.9,.3,1.15) }
.caster.on { transform: none }
.caster .who { width: clamp(84px, 20cqw, 150px); flex: none; order: -1 }
.caster .who :deep(svg) { display: block; width: 100%; height: auto }
.bubble { margin-bottom: clamp(40px, 10cqw, 90px); margin-inline-start: -4px; max-width: min(520px, 70cqw); background: #fff; color: #172033; border-radius: 20px; padding: 10px 16px; font-size: clamp(13px, 2.8cqw, 17px); font-weight: 600; line-height: 1.7; box-shadow: 0 10px 28px rgba(0,0,0,.45) }
.bubble .en { display: block; text-align: left; color: #9A6A00; font-size: .82em }

.studio { position: absolute; inset: 0; z-index: 12; background: radial-gradient(ellipse at 50% 85%, #1D4E9E 0, #0B214A 45%, #050C1C 80%) }
.screen { position: absolute; left: 50%; top: 16%; transform: translateX(-50%); width: min(46%, 380px); aspect-ratio: 16/9; border-radius: 12px; background: linear-gradient(160deg, #10306A, #071733); border: 3px solid #2B4F8C; display: grid; place-items: center; font-family: 'Alexandria', sans-serif; font-weight: 900; color: #F5B82E; font-size: clamp(18px, 5cqw, 34px); box-shadow: 0 0 40px rgba(43,79,140,.6) }
.desk { position: absolute; left: -10%; right: -10%; bottom: 0; height: 22%; background: radial-gradient(ellipse at 50% 0, #2C6BD8 0, #0F2E6B 40%, #071733 75%); border-top: 3px solid #5FA0FF; border-radius: 50% 50% 0 0 / 30% 30% 0 0 }
.host { position: absolute; bottom: 4%; height: min(62%, 52cqw); aspect-ratio: 200 / 260 }
.host :deep(svg) { width: 100%; height: 100% }
.host.a { right: 4% }
.host.b { left: 4% }
.sbubble { position: absolute; top: 4%; left: 50%; transform: translateX(-50%); width: min(70%, 520px); background: #fff; color: #172033; border-radius: 20px; padding: 10px 16px; font-weight: 600; line-height: 1.7; font-size: clamp(13px, 2.8cqw, 17px); box-shadow: 0 10px 28px rgba(0,0,0,.45) }
.go { position: absolute; left: 50%; bottom: 5%; transform: translateX(-50%); z-index: 2; min-height: 48px; padding: 0 28px; border-radius: 12px; background: linear-gradient(180deg, #5FB0FF, #2F7BE0); color: #fff; font-family: 'Alexandria', sans-serif; font-weight: 800; font-size: 17px; border: 0; box-shadow: 0 8px 22px rgba(47,123,224,.45) }
</style>
