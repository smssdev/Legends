<script setup lang="ts">
// [Sprint 29] The live draw (docs/design/legends-ui/Sprint29Drafts.html, 5), filling the screen. Before it: the
// countdown and the hash announced in advance. At its time every screen plays the same ball at the same moment on the
// server's clock: a ball leaves the bowl, is held under a drum roll, opens on the team's crest with a crash, its name
// is said aloud, and its card flies to its group (or slot, or tie). Whoever missed it replays it exactly as it was,
// from its first ball. The order comes from the server (TournamentPlan); this screen only plays it.
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { paths } from '../../api/schema'
import { intlLocale, t } from '../../lib/i18n'
import { nm } from '../../lib/names'
import { announce, drumRoll, reveal, soundOff, soundOn } from '../../lib/drawSound'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import { STAGES } from './labels'

type Draw = paths['/tournaments/{league}/draw']['get']['responses']['200']['content']['application/json']
type Step = Draw['steps'][number]
type Card = { id: number; name: string; code: string; crest_url: string; colors?: string[]; coach?: string | null }
const props = defineProps<{ id: string }>()
const draw = ref<Draw | null>(null)
const error = ref('')
const sound = ref(false)
const when = ref('')
const message = ref('')
let skew = 0
const now = ref(Date.now())
/** A replay starts from the viewer's own tap; the live draw from drawn_at. */
const replayFrom = ref<number | null>(null)
const skipped = ref(false)
const reduced = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
let frame = 0
let poll = 0

async function load() {
  try {
    const { data } = await api.GET('/tournaments/{league}/draw', { params: { path: { league: Number(props.id) } } })
    draw.value = data!
    skew = data!.server_now - Date.now()
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const tick = () => { now.value = Date.now(); frame = requestAnimationFrame(tick) }
onMounted(async () => {
  await load()
  frame = requestAnimationFrame(tick)
  // Waiting for the draw: ask again around its time (the server draws it within the minute).
  poll = window.setInterval(() => {
    const d = draw.value
    if (d && !d.drawn_at && d.draw_at && new Date(d.draw_at).getTime() <= serverNow() + 2000) void load()
  }, 4000)
})
onBeforeUnmount(() => { cancelAnimationFrame(frame); window.clearInterval(poll); soundOff() })
const serverNow = () => now.value + skew

const ms = computed(() => draw.value?.reveal_ms ?? 3500)
/** The moments inside one ball: it rises, is held, then opens. */
const RISE = 0.22
const OPEN = 0.55
const origin = computed(() => replayFrom.value ?? (draw.value?.drawn_at ? new Date(draw.value.drawn_at).getTime() : null))
const elapsed = computed(() => (origin.value === null ? -1 : serverNow() - origin.value))
const total = computed(() => draw.value?.steps.length ?? 0)
const index = computed(() => (skipped.value ? total.value : elapsed.value < 0 ? -1 : Math.min(total.value, Math.floor(elapsed.value / ms.value))))
const phase = computed(() => (index.value < 0 || index.value >= total.value ? 1 : (elapsed.value % ms.value) / ms.value))
const done = computed(() => total.value > 0 && index.value >= total.value)
const current = computed<Step | null>(() => (index.value >= 0 && index.value < total.value ? draw.value!.steps[index.value] : null))
const opened = computed(() => phase.value >= OPEN)
const held = computed(() => phase.value >= RISE && !opened.value)
/** The steps placed on the board: every one before, and this one once it has opened. */
const placed = computed(() => (draw.value?.steps ?? []).slice(0, Math.max(0, index.value + (opened.value && current.value ? 1 : 0))))
const card = (s: Step | null) => (s?.club ?? null) as Card | null
const letter = (g?: number) => (g ? String.fromCharCode(64 + g) : '')

const where = (s: Step) => {
  if (s.type === 'group') return t('المجموعة {v0}', { v0: letter(s.group) })
  if (s.type === 'slot') return t('الخانة {v0}', { v0: s.slot ?? '' })
  return t(STAGES[s.stage ?? ''] ?? '') + ' · ' + t('المواجهة {v0}', { v0: s.slot ?? '' })
}

// The sound follows the shared clock: a roll as each ball is held, the crash and the name as it opens.
watch(index, (i) => { if (sound.value && i >= 0 && i < total.value && !reduced) drumRoll((OPEN - RISE) * ms.value / 1000) })
watch(opened, (o) => {
  if (!o || !sound.value || !current.value) return
  reveal()
  const c = card(current.value)
  if (c) announce(`${nm(c.name)}. ${where(current.value)}`)
})
function toggleSound() {
  sound.value = sound.value ? (soundOff(), false) : soundOn()
}
function replay() {
  skipped.value = false
  replayFrom.value = serverNow()
  if (!sound.value) sound.value = soundOn()
}

const groupCount = computed(() => draw.value?.group_count ?? 0)
const boardGroups = computed(() => Array.from({ length: groupCount.value }, (_, g) => ({
  letter: letter(g + 1), teams: placed.value.filter((s) => s.group === g + 1).sort((a, b) => (a.position ?? 0) - (b.position ?? 0)),
})))
const boardSlots = computed(() => placed.value.filter((s) => s.type === 'slot'))
const boardTies = computed(() => {
  const map = new Map<string, { stage: string; slot: number; home?: Step; away?: Step }>()
  for (const s of placed.value.filter((x) => x.type === 'tie')) {
    const k = `${s.stage}:${s.slot}`
    const tie: { stage: string; slot: number; home?: Step; away?: Step } = map.get(k) ?? { stage: s.stage!, slot: s.slot! }
    tie[s.side as 'home' | 'away'] = s
    map.set(k, tie)
  }
  return [...map.values()]
})
const isNew = (s: Step) => opened.value && current.value === s

const countdown = computed(() => {
  if (!draw.value?.draw_at || draw.value.drawn_at) return ''
  const s = Math.max(0, Math.ceil((new Date(draw.value.draw_at).getTime() - serverNow()) / 1000))
  const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
  return (d ? `${d}d ` : '') + (h || d ? `${String(h).padStart(2, '0')}:` : '') + `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
})
const local = (iso: string) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'long', day: 'numeric', month: 'long', hour: 'numeric', minute: '2-digit' })
const liveNow = computed(() => !!draw.value?.drawn_at && replayFrom.value === null && !done.value && !skipped.value)
const confetti = Array.from({ length: 14 }, (_, i) => ({ x: Math.cos((i / 14) * Math.PI * 2) * (90 + (i % 3) * 30), y: Math.sin((i / 14) * Math.PI * 2) * (70 + (i % 4) * 20), r: i * 37 }))

async function schedule() {
  message.value = ''
  try {
    await ensureCsrf()
    await api.PUT('/leagues/{league}/draw', { params: { path: { league: Number(props.id) } }, body: { draw_at: new Date(when.value).toISOString() } })
    await load()
    message.value = t('حُدد موعد القرعة.')
  } catch (e) {
    message.value = asApiError(e).message
  }
}
</script>

<template>
  <main class="draw-bg relative flex min-h-dvh flex-col overflow-hidden text-text">
    <header class="z-10 flex items-center justify-between gap-2 px-4 pt-[max(0.75rem,env(safe-area-inset-top))]">
      <RouterLink :to="{ name: 'tournament', params: { id } }" class="flex min-h-touch items-center gap-1 text-sm font-bold text-text-muted">‹ {{ draw?.name }}</RouterLink>
      <div class="flex items-center gap-2">
        <span v-if="liveNow" class="flex items-center gap-1.5 rounded-full bg-live px-3 py-1 text-xs font-extrabold"><span class="size-2 animate-pulse rounded-full bg-text" />{{ $t('مباشر') }}</span>
        <span v-else-if="replayFrom !== null && !done" class="rounded-full bg-surface-raised px-3 py-1 text-xs font-bold">{{ $t('إعادة') }}</span>
        <button class="min-h-touch rounded-full bg-surface/70 px-3 text-sm font-bold" :aria-pressed="sound" @click="toggleSound">{{ sound ? '🔊 ' + $t('الصوت') : '🔇 ' + $t('شغّل الصوت') }}</button>
      </div>
    </header>
    <p v-if="error" class="m-4 rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <template v-if="draw">
      <!-- Before the draw -->
      <section v-if="!draw.drawn_at" class="flex flex-1 flex-col items-center justify-center gap-4 px-4 text-center">
        <div class="bowl"><span v-for="i in 8" :key="i" class="ball idle" :style="{ '--i': i }" /></div>
        <template v-if="draw.draw_at">
          <p class="text-text-muted">{{ $t('تُسحب القرعة {v0}', { v0: local(draw.draw_at) }) }}</p>
          <p class="font-numbers text-6xl font-bold text-gold" dir="ltr" aria-live="polite">{{ countdown }}</p>
          <p v-if="countdown === '00:00'" class="animate-pulse font-bold">{{ $t('القرعة تبدأ الآن…') }}</p>
        </template>
        <p v-else class="max-w-sm text-text-muted">{{ $t('تُسحب القرعة عند بداية البطولة {v0}، وتستطيع مشاهدتها بعدها كما كانت.', { v0: local(draw.starts_at) }) }}</p>
        <p v-if="draw.commit" class="w-full max-w-md break-all rounded-lg bg-surface-sunk/80 px-3 py-2 text-start text-xs text-text-muted">
          {{ $t('بصمة القرعة المعلنة قبلها (SHA-256):') }} <code dir="ltr" class="block font-numbers text-text">{{ draw.commit }}</code></p>
        <form v-if="draw.can_schedule" class="flex w-full max-w-md flex-col gap-2 rounded-xl bg-surface/80 p-4 text-start" @submit.prevent="schedule">
          <label for="draw-at" class="font-bold">{{ draw.draw_at ? $t('غيّر موعد القرعة') : $t('حدد موعد القرعة') }}</label>
          <div class="flex gap-2">
            <input id="draw-at" v-model="when" type="datetime-local" required dir="ltr" class="h-touch min-w-0 flex-1 rounded-lg bg-surface-sunk px-3" />
            <button type="submit" class="min-h-touch rounded-lg bg-gold px-4 font-extrabold text-on-gold">{{ $t('حفظ') }}</button>
          </div>
          <p v-if="message" class="text-sm" role="status">{{ $t(message) }}</p>
        </form>
      </section>

      <!-- The draw -->
      <template v-else>
        <section class="relative flex h-[42vh] min-h-[300px] flex-col items-center justify-center" aria-live="assertive">
          <div v-if="!done" class="bowl transition-all duration-300" :class="{ shake: held && !reduced, 'scale-75 opacity-0': opened }">
            <span v-for="i in 8" :key="i" class="ball" :class="reduced ? '' : 'spin'" :style="{ '--i': i }" />
          </div>
          <span v-if="current && !opened && !reduced" :key="'b' + index" class="ball out" :class="{ held }" />
          <div v-if="current && opened" :key="'r' + index" class="reveal absolute inset-0 flex flex-col items-center justify-center gap-2 text-center">
            <span v-for="(c, i) in reduced ? [] : confetti" :key="i" class="confetti" :style="{ '--x': c.x + 'px', '--y': c.y + 'px', '--r': c.r + 'deg' }" />
            <div class="crest-glow rounded-full p-2"><ClubCrest :url="card(current)!.crest_url" :code="card(current)!.code" :size="104" /></div>
            <b class="font-display text-4xl font-extrabold drop-shadow">{{ $nm(card(current)!.name) }}</b>
            <span class="text-lg font-extrabold text-gold-light">← {{ where(current) }}<template v-if="current.pot"> · {{ $t('الوعاء {v0}', { v0: current.pot }) }}</template></span>
          </div>
          <div v-if="done" class="flex flex-col items-center gap-3 text-center">
            <span class="text-6xl">🏆</span>
            <b class="font-display text-3xl font-extrabold">{{ $t('انتهت القرعة') }}</b>
            <div class="flex flex-wrap justify-center gap-2">
              <button class="min-h-touch rounded-xl bg-gold px-5 font-extrabold text-on-gold" @click="replay">{{ $t('أعد مشاهدة القرعة') }}</button>
              <RouterLink :to="{ name: 'tournament', params: { id } }" class="flex min-h-touch items-center rounded-xl bg-surface px-5 font-bold">{{ $t('صفحة البطولة') }}</RouterLink>
            </div>
          </div>
          <p v-if="!done && current" class="absolute bottom-2 font-numbers text-xs text-text-muted" dir="ltr">{{ index + 1 }} / {{ total }}</p>
        </section>

        <section class="z-10 flex-1 rounded-t-3xl bg-panel/90 px-3 pb-6 pt-4 backdrop-blur">
          <div v-if="draw.format === 'groups'" class="grid grid-cols-2 gap-2 sm:grid-cols-4">
            <div v-for="g in boardGroups" :key="g.letter" class="rounded-xl bg-surface-sunk p-2">
              <h3 class="mb-1 text-sm font-extrabold text-gold">{{ $t('المجموعة {v0}', { v0: g.letter }) }}</h3>
              <p v-for="s in g.teams" :key="card(s)!.id" class="flex min-h-[30px] items-center gap-1.5 text-sm" :class="isNew(s) ? 'land font-extrabold text-gold-light' : ''">
                <ClubCrest :url="card(s)!.crest_url" :code="card(s)!.code" :size="20" /><span class="truncate">{{ $nm(card(s)!.name) }}</span></p>
            </div>
          </div>
          <ol v-else-if="draw.format === 'league'" class="grid grid-cols-1 gap-1.5 sm:grid-cols-2">
            <li v-for="s in boardSlots" :key="s.slot" class="flex min-h-touch items-center gap-2 rounded-xl bg-surface-sunk px-3" :class="isNew(s) ? 'land ring-1 ring-gold' : ''">
              <span class="grid size-8 place-items-center rounded-full bg-gold/15 font-numbers font-bold text-gold">{{ s.slot }}</span>
              <ClubCrest :url="card(s)!.crest_url" :code="card(s)!.code" :size="26" /><b class="truncate">{{ $nm(card(s)!.name) }}</b></li>
          </ol>
          <div v-else class="grid grid-cols-1 gap-2 sm:grid-cols-2">
            <div v-for="tie in boardTies" :key="tie.stage + tie.slot" class="flex items-center justify-between gap-2 rounded-xl bg-surface-sunk px-3 py-2 text-sm">
              <span class="text-xs text-text-muted">{{ $t(STAGES[tie.stage] ?? tie.stage) }}</span>
              <b class="truncate" :class="tie.home && isNew(tie.home) ? 'land text-gold-light' : ''">{{ tie.home ? $nm(card(tie.home)!.name) : '؟' }}</b>
              <span class="text-text-muted">{{ $t('ضد') }}</span>
              <b class="truncate" :class="tie.away && isNew(tie.away) ? 'land text-gold-light' : ''">{{ tie.away ? $nm(card(tie.away)!.name) : '؟' }}</b>
            </div>
          </div>
          <div class="mt-4 flex flex-wrap items-center justify-between gap-2">
            <button v-if="!done" class="min-h-touch rounded-lg px-3 text-sm font-bold text-text-muted" @click="skipped = true">{{ $t('تخطَّ إلى النتيجة') }}</button>
            <p v-if="done" class="w-full rounded-lg bg-surface-sunk px-3 py-2 text-xs text-text-muted">
              {{ $t('البذرة') }} <b class="font-numbers text-text" dir="ltr">{{ draw.seed }}</b>{{ $t('. تحقق بنفسك: SHA-256 للنص') }}
              <code dir="ltr" class="font-numbers text-text">legends-draw:{{ id }}:{{ draw.seed }}</code> {{ $t('يساوي البصمة المعلنة أعلاه.') }}</p>
          </div>
        </section>
      </template>
    </template>
  </main>
</template>

<style scoped>
.draw-bg { background: radial-gradient(ellipse at 50% 25%, var(--color-surface-raised) 0%, var(--color-bg) 45%, var(--color-bg-deep) 100%); }
.bowl { position: relative; width: 180px; height: 180px; border-radius: 9999px; border: 2px solid color-mix(in srgb, var(--color-text) 25%, transparent);
  background: radial-gradient(circle at 35% 28%, color-mix(in srgb, var(--color-text) 22%, transparent), color-mix(in srgb, var(--color-text) 4%, transparent) 60%);
  box-shadow: inset 0 -12px 30px color-mix(in srgb, var(--color-shade) 45%, transparent), 0 0 60px color-mix(in srgb, var(--color-brand-light) 15%, transparent); }
.ball { position: absolute; width: 34px; height: 34px; border-radius: 9999px; left: 73px; top: 73px;
  background: radial-gradient(circle at 35% 30%, var(--color-text), var(--color-gold-light) 45%, var(--color-gold));
  box-shadow: 0 4px 10px color-mix(in srgb, var(--color-shade) 55%, transparent); }
.ball.idle, .ball.spin { transform: rotate(calc(var(--i) * 45deg)) translateX(48px); }
.ball.spin { animation: orbit 1.6s linear infinite; animation-delay: calc(var(--i) * -0.2s); }
.ball.idle { animation: orbit 6s linear infinite; animation-delay: calc(var(--i) * -0.75s); }
@keyframes orbit { from { transform: rotate(0deg) translateX(48px) rotate(0deg); } to { transform: rotate(360deg) translateX(48px) rotate(-360deg); } }
.bowl.shake { animation: shake 0.12s linear infinite; }
@keyframes shake { 0%, 100% { transform: translate(0, 0); } 25% { transform: translate(-2px, 1px); } 75% { transform: translate(2px, -1px); } }
.ball.out { left: calc(50% - 17px); top: calc(50% - 17px); animation: rise 0.8s cubic-bezier(.2, .9, .3, 1.2) forwards; z-index: 5; }
.ball.out.held { animation: hold 0.35s ease-in-out infinite alternate; transform: translateY(-130px) scale(2.4); box-shadow: 0 0 40px var(--color-gold); }
@keyframes rise { from { transform: translateY(0) scale(1); } to { transform: translateY(-130px) scale(2.4); } }
@keyframes hold { from { transform: translateY(-130px) scale(2.4); } to { transform: translateY(-134px) scale(2.55); } }
.reveal { animation: pop 0.5s cubic-bezier(.2, .9, .3, 1.3); }
@keyframes pop { from { opacity: 0; transform: scale(0.4); } to { opacity: 1; transform: scale(1); } }
.crest-glow { background: radial-gradient(circle, color-mix(in srgb, var(--color-gold) 45%, transparent), transparent 70%); animation: glow 1.4s ease-in-out infinite alternate; }
@keyframes glow { from { box-shadow: 0 0 20px var(--color-gold); } to { box-shadow: 0 0 60px var(--color-gold-light); } }
.confetti { position: absolute; left: 50%; top: 45%; width: 8px; height: 14px; border-radius: 2px; background: var(--color-gold);
  animation: burst 1.2s ease-out forwards; }
.confetti:nth-child(3n) { background: var(--color-brand-light); }
.confetti:nth-child(3n + 1) { background: var(--color-text); }
@keyframes burst { from { transform: translate(0, 0) rotate(0); opacity: 1; } to { transform: translate(var(--x), var(--y)) rotate(var(--r)); opacity: 0; } }
.land { animation: land 0.6s cubic-bezier(.2, .9, .3, 1.3); }
@keyframes land { from { transform: translateY(-40px) scale(1.3); opacity: 0; } to { transform: none; opacity: 1; } }
@media (prefers-reduced-motion: reduce) { .ball, .bowl, .reveal, .land, .crest-glow { animation: none !important; } }
</style>
