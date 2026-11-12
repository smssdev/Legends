<script setup lang="ts">
// [Sprint 27 B3, the owner's request 2026-10-30] The friendly's quick simulation, played in its own page as a quick
// match should be: about fifteen seconds of a minute ring, a little pitch where the ball goes where the server says
// each minute went (an attack, a chance saved or missed, a corner, a goal), the score turning and the moments in a
// list, then the result. The server played it (report.timeline); this only draws it. "تخطَّ" goes to the end.
import { scoreText } from '../../lib/format'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

type Moment = { m: number; x?: number; k: string; s?: 'home' | 'away'; name?: string | null; score: number[] }
const props = defineProps<{ timeline: Moment[]; home: { name: string; crest: string }; away: { name: string; crest: string } }>()
const emit = defineEmits<{ done: [] }>()

const MS_PER_MINUTE = 150
// A goal holds the picture a moment, a red card or a big chance a little.
const HOLD: Record<string, number> = { goal: 1100, red: 500, penalty: 450, saved: 280, missed: 220, blocked: 160 }
const reduced = typeof window !== 'undefined' && window.matchMedia?.('(prefers-reduced-motion: reduce)').matches

const i = ref(-1)
const now = computed<Moment | null>(() => props.timeline[i.value] ?? null)
const minute = computed(() => now.value?.m ?? 0)
const shownMinute = (m: Moment | null) => (m ? (m.x ? `${m.m}+${m.x}` : `${m.m}`) : '0')
const score = computed(() => now.value?.score ?? [0, 0])
const last = computed(() => props.timeline[props.timeline.length - 1]?.m ?? 90)
// Where the ball is: x across the pitch (0 my goal, 100 theirs), y up and down. My club attacks to the right.
const ball = ref({ x: 50, y: 50 })
const flash = ref<{ text: string; side?: string } | null>(null)
const feed = ref<Moment[]>([])
const KIND: Record<string, string> = { goal: '⚽', red: '🟥', yellow: '🟨', penalty: '🎯', saved: '🧤', missed: '↗', blocked: '⛔', corner: '⚑' }
const WORD: Record<string, string> = { goal: 'هدف!', red: 'طرد', penalty: 'ضربة جزاء', saved: 'تصدٍّ', missed: 'فرصة ضائعة' }

let timer = 0
function place(m: Moment) {
  const toward = m.s === 'away' ? -1 : 1
  const r = ((m.m * 37) % 100) / 100
  const deep: Record<string, number> = { goal: 47, saved: 42, missed: 40, blocked: 34, penalty: 38, corner: 46, attack: 22 }
  const d = deep[m.k]
  if (d === undefined) {
    ball.value = { x: 50 + (r - 0.5) * 24, y: 30 + r * 40 }
    return
  }
  ball.value = { x: 50 + toward * d, y: m.k === 'corner' ? (r > 0.5 ? 6 : 94) : m.k === 'goal' ? 50 : 25 + r * 50 }
}
function step() {
  i.value++
  const m = now.value
  if (!m) return finish()
  place(m)
  if (m.k !== 'quiet' && m.k !== 'attack' && m.k !== 'corner') feed.value = [m, ...feed.value].slice(0, 6)
  flash.value = WORD[m.k] ? { text: WORD[m.k], side: m.s } : null
  timer = window.setTimeout(step, MS_PER_MINUTE + (HOLD[m.k] ?? 0))
}
function finish() {
  clearTimeout(timer)
  i.value = props.timeline.length - 1
  emit('done')
}
onMounted(() => {
  if (reduced || !props.timeline.length) return finish()
  timer = window.setTimeout(step, 400)
})
onBeforeUnmount(() => clearTimeout(timer))

// The ring: the minute against the match's length.
const R = 34
const C = 2 * Math.PI * R
const dash = computed(() => `${(Math.min(1, minute.value / Math.max(90, last.value)) * C).toFixed(1)} ${C.toFixed(1)}`)
const sideName = (s?: string) => (s === 'away' ? props.away.name : props.home.name)
</script>

<template>
  <section class="flex flex-col gap-3 rounded-xl border border-gold/40 bg-panel p-4" :aria-label="$t('الودية تُلعب الآن')" aria-live="polite">
    <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2">
      <span class="flex min-w-0 items-center gap-2"><AppImage :src="home.crest" alt="" class="size-10 shrink-0" :size="40" crest /><b class="truncate text-sm">{{ $nm(home.name) }}</b></span>
      <span class="relative grid size-20 place-items-center" role="timer" :aria-label="$t('الدقيقة {v0}', { v0: minute })">
        <svg viewBox="0 0 80 80" class="absolute inset-0 size-full -rotate-90" aria-hidden="true">
          <circle cx="40" cy="40" :r="R" fill="none" stroke="var(--color-surface-sunk)" stroke-width="6" />
          <circle cx="40" cy="40" :r="R" fill="none" stroke="var(--color-gold)" stroke-width="6" stroke-linecap="round" :stroke-dasharray="dash" class="transition-[stroke-dasharray] duration-150" />
        </svg>
        <span class="flex flex-col items-center leading-none">
          <b class="font-numbers text-2xl" dir="ltr">{{ scoreText(score[0], score[1]) }}</b>
          <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ shownMinute(now) }}'</span>
        </span>
      </span>
      <span class="flex min-w-0 items-center justify-end gap-2"><b class="truncate text-sm">{{ $nm(away.name) }}</b><AppImage :src="away.crest" alt="" class="size-10 shrink-0" :size="40" crest /></span>
    </div>

    <!-- The little pitch: my goal on the left, theirs on the right, whatever the language. -->
    <div class="quick-pitch relative aspect-[2/1] w-full overflow-hidden rounded-lg" dir="ltr" aria-hidden="true">
      <div class="absolute inset-2 rounded-sm border-2 border-white/40" />
      <div class="absolute inset-y-2 left-1/2 border-l-2 border-white/40" />
      <div class="absolute left-1/2 top-1/2 size-12 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white/40" />
      <div class="absolute inset-y-[30%] left-2 w-[12%] border-2 border-l-0 border-white/40" />
      <div class="absolute inset-y-[30%] right-2 w-[12%] border-2 border-r-0 border-white/40" />
      <span class="ball absolute size-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white shadow" :style="{ left: `${ball.x}%`, top: `${ball.y}%` }" />
      <span v-if="flash" :key="i" class="flash absolute inset-x-0 top-2 mx-auto w-fit rounded-pill px-3 py-1 text-sm font-extrabold" :class="flash.text === 'هدف!' ? 'bg-gold text-on-gold' : 'bg-bg/80 text-text'">
        {{ $t(flash.text) }}
      </span>
    </div>

    <ul class="flex min-h-[4.5rem] flex-col gap-1 text-sm">
      <li v-for="m in feed" :key="`${m.m}-${m.x ?? 0}-${m.k}`" class="flex items-center gap-2" :class="m.s === 'away' ? 'text-text-muted' : ''">
        <span class="font-numbers w-10 text-text-muted" dir="ltr">{{ shownMinute(m) }}'</span>
        <span aria-hidden="true">{{ KIND[m.k] }}</span>
        <span class="min-w-0 flex-1 truncate"><bdi>{{ m.name ? $nm(m.name) : $nm(sideName(m.s)) }}</bdi></span>
      </li>
    </ul>

    <button type="button" class="h-touch rounded-lg bg-surface-raised font-bold" @click="finish">{{ $t('تخطَّ إلى النتيجة') }}</button>
  </section>
</template>

<style scoped>
.quick-pitch {
  background: repeating-linear-gradient(90deg, var(--color-pitch-dark) 0, var(--color-pitch-dark) 10%, var(--color-pitch) 10%, var(--color-pitch) 20%);
}
.ball {
  transition: left 140ms ease-out, top 140ms ease-out;
}
.flash {
  animation: pop 0.5s ease-out;
}
@keyframes pop {
  from { transform: scale(0.6); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
@media (prefers-reduced-motion: reduce) {
  .ball, .flash { transition: none; animation: none; }
}
</style>
