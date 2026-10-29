<template>
  <main class="mx-auto flex min-h-dvh max-w-6xl flex-col gap-5 px-4 py-5 md:px-6">
    <header class="flex flex-wrap items-center gap-3">
      <RouterLink :to="league ? '/match' : '/sim'" class="flex items-center gap-3">
        <BrandMark />
      </RouterLink>
      <span class="rounded-pill bg-brand px-3 py-1 text-sm font-bold text-white">{{ $t('تقرير المباراة') }}</span>
      <div v-if="view && !league" role="radiogroup" :aria-label="$t('التقرير من وجهة نظر')" class="ms-auto flex gap-1 rounded-md bg-surface p-1">
        <button v-for="s in sides" :key="s" type="button" role="radio" :aria-checked="side === s" class="h-10 rounded-sm px-3 text-sm font-bold" :class="side === s ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="load(s)">
          {{ $nm(view.clubs[s].name) }}
        </button>
      </div>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]">{{ $t(error) }}</p>
    <p v-else-if="!report || !view" class="text-text-muted">{{ $t('جارٍ تحميل التقرير...') }}</p>

    <template v-if="report && view">
      <!-- [X32] The scoreboard as a broadcast's, in Legends' signature: an emerald band, the crests on ivory discs with a
           glow in each club's colour, and the score that never breaks across lines. -->
      <section class="score-board relative overflow-hidden rounded-2xl" :aria-label="$t('النتيجة')">
        <div class="score-band px-4 py-1.5 text-center text-xs font-extrabold tracking-wide text-white">{{ $t('نهاية المباراة') }}</div>
        <div class="relative flex items-center justify-center gap-3 p-5 md:gap-8 md:p-8">
          <span class="pointer-events-none absolute -start-10 top-1/2 size-40 -translate-y-1/2 rounded-full opacity-30 blur-3xl" :style="{ background: color('home') }" aria-hidden="true" />
          <span class="pointer-events-none absolute -end-10 top-1/2 size-40 -translate-y-1/2 rounded-full opacity-30 blur-3xl" :style="{ background: color('away') }" aria-hidden="true" />
          <div class="flex min-w-0 flex-1 flex-col items-center gap-2 text-center">
            <span class="score-disc"><Crest :logo="view.clubs.home.logo" :code="view.clubs.home.code" :primary="color('home')" :secondary="clubColors(view.clubs.home).secondary" :size="52" /></span>
            <span class="line-clamp-2 font-display text-base font-extrabold md:text-lg">{{ $nm(view.clubs.home.name) }}</span>
          </div>
          <div class="flex shrink-0 flex-col items-center gap-1.5">
            <span class="whitespace-nowrap rounded-xl bg-black/45 px-4 py-1 font-numbers text-4xl shadow-inner md:text-6xl" dir="ltr">{{ report.score.away }} – {{ report.score.home }}</span>
            <span v-if="report.shootout" class="text-sm text-text-soft">{{ $t('ركلات الترجيح') }} <b class="font-numbers" dir="ltr">{{ report.shootout.away }} – {{ report.shootout.home }}</b></span>
            <span class="rounded-pill px-3 py-1 text-sm font-bold" :class="resultClass">{{ $t(resultLabel) }}</span>
          </div>
          <div class="flex min-w-0 flex-1 flex-col items-center gap-2 text-center">
            <span class="score-disc"><Crest :logo="view.clubs.away.logo" :code="view.clubs.away.code" :primary="color('away')" :secondary="clubColors(view.clubs.away).secondary" :size="52" /></span>
            <span class="line-clamp-2 font-display text-base font-extrabold md:text-lg">{{ $nm(view.clubs.away.name) }}</span>
          </div>
        </div>
      </section>

      <section aria-labelledby="why" class="flex flex-col gap-3">
        <h2 id="why" class="font-display text-2xl font-extrabold">{{ report.result === 'loss' ? $t('لماذا خسرنا') : report.result === 'win' ? $t('لماذا فزنا') : $t('لماذا تعادلنا') }}</h2>
        <div class="grid gap-3 md:grid-cols-3">
          <article v-for="r in report.reasons" :key="r.title" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <div class="flex items-baseline gap-2">
              <span class="font-numbers text-4xl text-gold" dir="ltr">{{ r.big }}</span>
              <span class="text-sm text-text-muted">{{ r.unit }}</span>
            </div>
            <h3 class="font-bold">{{ $t(r.title) }}</h3>
            <p class="text-sm text-text-soft">{{ $t(r.text) }}</p>
          </article>
        </div>
        <article v-if="report.improve" class="flex flex-col gap-1 rounded-xl border border-gold/40 bg-gold/10 p-4">
          <span class="text-sm font-bold text-gold">{{ $t('نقطة للتحسين') }}</span>
          <h3 class="font-bold">{{ $t(report.improve.title) }}</h3>
          <p class="text-sm text-text-soft">{{ $t(report.improve.text) }}</p>
        </article>
      </section>

      <div class="grid gap-4 md:grid-cols-[2fr_1fr]">
        <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="verdict">
          <h2 id="verdict" class="font-display text-xl font-extrabold">{{ $t('رأي المدرب المساعد') }}</h2>
          <p v-for="v in report.verdict" :key="v.text" class="flex items-start gap-2 text-sm">
            <span class="shrink-0 rounded-sm px-2 py-0.5 text-xs font-bold" :class="v.tag === 'ممتاز' ? 'bg-pitch/25 text-[#7BE0A0]' : 'bg-live/20 text-[#FF8A8A]'">{{ $t(v.tag) }}</span>
            <span>{{ $t(v.text) }}</span>
          </p>
        </section>
        <section v-if="report.man_of_the_match" class="relative flex flex-col items-center justify-center gap-1 overflow-hidden rounded-xl border border-gold/50 bg-gradient-to-b from-[#3a2c07] to-[#10284F] p-4 text-center shadow-lg shadow-black/40" aria-labelledby="motm">
          <span class="absolute inset-x-0 top-0 h-1 bg-gold" aria-hidden="true" />
          <span class="text-2xl" aria-hidden="true">⭐</span>
          <h2 id="motm" class="text-sm font-bold text-gold">{{ $t('رجل المباراة') }}</h2>
          <span class="font-display text-2xl font-extrabold">{{ $nm(report.man_of_the_match.name) }}</span>
          <span class="text-sm text-text-muted">{{ view.clubs[report.man_of_the_match.team as Side].name }}</span>
          <span class="font-numbers text-4xl text-gold">{{ rating(report.man_of_the_match.rating) }}</span>
        </section>
      </div>

      <section v-if="report.readings?.length" class="flex flex-col gap-2 rounded-xl bg-surface p-4" aria-labelledby="readings">
        <h2 id="readings" class="font-display text-xl font-extrabold">{{ $t('ما قاله المساعد أثناء المباراة') }}</h2>
        <p v-for="r in report.readings" :key="r.minute + r.kind" class="flex gap-3 text-sm">
          <span class="w-10 shrink-0 font-numbers text-base text-gold">{{ r.minute }}'</span><span>{{ $t(r.text) }}</span>
        </p>
      </section>

      <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="stats">
        <h2 id="stats" class="font-display text-xl font-extrabold">{{ $t('الإحصائيات') }}</h2>
        <StatsGrid :home="report.stats.home" :away="report.stats.away" :home-color="color('home')" />
      </section>

      <div class="grid gap-4 md:grid-cols-2">
        <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="thirds">
          <h2 id="thirds" class="font-display text-xl font-extrabold">{{ $t('أين لُعبت الكرة') }}</h2>
          <div class="flex h-24 overflow-hidden rounded-md" dir="ltr">
            <div v-for="(v, i) in thirdsLtr" :key="i" class="flex flex-col items-center justify-center bg-pitch" :style="{ flex: Math.max(v, 8), opacity: 0.45 + v / 160 }">
              <span class="font-numbers text-2xl">{{ v }}%</span>
            </div>
          </div>
          <div class="flex justify-between text-xs text-text-muted" dir="ltr"><span>{{ $t('ثلث {v0}', { v0: $nm(view.clubs.home.name) }) }}</span><span>{{ $t('الوسط') }}</span><span>{{ $t('ثلث {v0}', { v0: $nm(view.clubs.away.name) }) }}</span></div>
        </section>
        <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="momentum">
          <h2 id="momentum" class="font-display text-xl font-extrabold">{{ $t('الزخم') }}</h2>
          <div class="h-24"><Momentum :values="report.momentum" :home-color="color('home')" /></div>
          <div class="flex justify-between text-xs text-text-muted"><span>{{ $t('البداية') }}</span><span>{{ $t('النهاية') }}</span></div>
        </section>
      </div>

      <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="timeline">
        <h2 id="timeline" class="font-display text-xl font-extrabold">{{ $t('أحداث المباراة') }}</h2>
        <p v-if="!events.length" class="text-sm text-text-muted">{{ $t('لا أحداث بارزة.') }}</p>
        <ol class="flex flex-col gap-1">
          <li v-for="(e, i) in events" :key="i" class="flex min-h-10 items-center gap-3 rounded-md px-2" :class="e.team === 'home' ? '' : 'flex-row-reverse text-end'">
            <span class="w-12 shrink-0 text-center font-numbers text-lg text-gold" dir="ltr">{{ $t(e.label) }}</span>
            <span class="text-lg" aria-hidden="true">{{ e.icon }}</span>
            <span class="text-sm">{{ $t(e.text) }}</span>
          </li>
        </ol>
      </section>

      <section class="grid gap-4 md:grid-cols-2" :aria-label="$t('تقييم اللاعبين')">
        <div v-for="s in sides" :key="s" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
          <h2 class="font-display text-lg font-extrabold">{{ $nm(view.clubs[s].name) }}</h2>
          <div v-for="p in report.ratings[s]" :key="p.id" class="flex min-h-9 items-center gap-2 text-sm">
            <span class="w-7 text-center font-numbers text-text-muted">{{ p.no }}</span>
            <span class="flex-1 truncate">{{ $nm(p.name) }}</span>
            <span v-if="p.goals" class="text-xs" :aria-label="$t('{v0} هدف', { v0: p.goals })">⚽{{ p.goals > 1 ? p.goals : '' }}</span>
            <span v-if="p.assists" class="text-xs text-text-muted">{{ $t('صناعة {v0}', { v0: p.assists }) }}</span>
            <span class="w-10 rounded-sm text-center font-numbers text-lg" :class="p.rating >= 750 ? 'bg-pitch/30 text-[#7BE0A0]' : p.rating < 600 ? 'bg-live/20 text-[#FF8A8A]' : 'bg-surface-raised'">{{ rating(p.rating) }}</span>
          </div>
        </div>
      </section>

      <div class="flex flex-wrap gap-3">
        <template v-if="league">
          <RouterLink to="/match" class="flex h-14 items-center rounded-lg bg-gold px-8 font-display text-lg font-extrabold text-on-gold">{{ $t('المباراة القادمة') }}</RouterLink>
          <RouterLink :to="{ name: 'league-match', params: { id } }" class="flex h-14 items-center rounded-lg bg-surface px-6">{{ $t('العودة إلى المباراة') }}</RouterLink>
        </template>
        <RouterLink v-else to="/sim" class="flex h-14 items-center rounded-lg bg-gold px-8 font-display text-lg font-extrabold text-on-gold">{{ $t('مباراة جديدة') }}</RouterLink>
        <span v-if="!league" class="self-center text-sm text-text-muted">{{ $t('البذرة') }} <b class="font-numbers" dir="ltr">{{ view.seed }}</b></span>
      </div>
    </template>
    <!-- [Sprint 22] The Assistant Coach, back after the live match: he reads this report too. -->
    <ManagerBot v-if="league" />
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import Crest from '../components/Crest.vue'
import ManagerBot from '../components/assistant/ManagerBot.vue'
import Momentum from '../components/Momentum.vue'
import StatsGrid from '../components/StatsGrid.vue'
import { clubColors, leagueMatch, sim, type MatchView, type Side } from '../api/sim'

// league (Sprint 20 W1): a league match's report, the coach's own side only (the server knows which).
const props = defineProps<{ league?: boolean }>()
const route = useRoute()
const id = String(route.params.id)
const sides: Side[] = ['home', 'away']
const view = ref<MatchView | null>(null)
const report = ref<any>(null)
const error = ref('')
const side = ref<Side>((route.query.side as Side) || 'home')

const color = (s: Side) => (view.value ? clubColors(view.value.clubs[s]).primary : '#163360')
const rating = (r: number) => (r / 100).toFixed(1)

const resultLabel = computed(() => ({ win: 'فوز', loss: 'خسارة', draw: 'تعادل' })[report.value?.result as 'win'] ?? '')
const resultClass = computed(() =>
  report.value?.result === 'win' ? 'bg-pitch/30 text-[#7BE0A0]' : report.value?.result === 'loss' ? 'bg-live/20 text-[#FF8A8A]' : 'bg-surface-raised text-text-soft',
)
// Thirds come home-defence first; the pitch is drawn with home attacking left to right.
const thirdsLtr = computed<number[]>(() => report.value?.thirds ?? [33, 34, 33])

const names = computed(() => {
  const map: Record<string, string> = {}
  for (const s of sides) for (const p of view.value?.teams[s].players ?? []) map[p.id] = p.name
  return map
})

const events = computed(() =>
  (report.value?.timeline ?? []).filter((e: any) => !(e.type === 'penalty' && e.scored)).map((e: any) => {
    const n = (pid: number) => names.value[pid] ?? ''
    const [m, extra] = Array.isArray(e.minute) ? e.minute : [e.minute, 0]
    const label = extra ? `${m}+${extra}` : `${m}'`
    switch (e.type) {
      case 'goal':
        return { ...e, label, icon: '⚽', text: `${n(e.scorer)}${e.kind === 'penalty' ? ' (جزاء)' : e.kind === 'free_kick' ? ' (ركلة حرة)' : ''}${e.assist ? ` · صناعة ${n(e.assist)}` : ''}` }
      case 'card':
        return { ...e, label, icon: e.color === 'red' ? '🟥' : '🟨', text: `${n(e.player)}${e.second_yellow ? ' (إنذار ثانٍ)' : ''}` }
      case 'sub':
        return { ...e, label, icon: '🔁', text: `دخل ${n(e.in)} وخرج ${n(e.out)}` }
      case 'injury':
        return { ...e, label, icon: '🩹', text: `إصابة ${n(e.player)}` }
      default:
        return { ...e, label, icon: '🎯', text: `ركلة جزاء ${e.scored ? 'سجلها' : 'أضاعها'} ${n(e.taker)}` }
    }
  }),
)

async function load(s: Side) {
  side.value = s
  try {
    report.value = props.league ? await leagueMatch.report(id) : await sim.report(id, s)
    if (props.league) side.value = report.value.side
  } catch (e: any) {
    error.value = e.message
  }
}

onMounted(async () => {
  try {
    view.value = props.league ? await leagueMatch.show(id) : await sim.show(id)
    await load(side.value)
  } catch (e: any) {
    error.value = e.message
  }
})
</script>

<style scoped>
.score-board {
  background: linear-gradient(180deg, color-mix(in srgb, var(--color-bg-deep) 40%, transparent), var(--color-panel)), url("/art/stadium-blur.jpg") center / cover;
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 30%, transparent);
  box-shadow: 0 24px 50px -24px rgb(0 0 0 / 0.9);
}
.score-band {
  background: url("/art/pattern-star.svg") center / 40px 40px repeat, linear-gradient(180deg, var(--color-brand), var(--color-brand-dark));
  background-blend-mode: soft-light, normal;
}
.score-disc {
  display: grid;
  place-items: center;
  width: 4.75rem;
  height: 4.75rem;
  border-radius: 999px;
  background: radial-gradient(circle at 50% 30%, #ffffff, var(--color-chrome) 55%, var(--color-chrome-dark));
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-brand-light) 55%, transparent), 0 12px 24px -10px rgb(0 0 0 / 0.8);
}
</style>
