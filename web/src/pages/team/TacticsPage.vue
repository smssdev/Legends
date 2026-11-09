<script setup lang="ts">
import { REFEREE } from '../../lib/format'
// Tactics (Sprint 17 W1). [Sprint 20 S1] Laid out as the owner's picture, in our colours and drawings: the match on
// top (both sides, their strength and last five, the formations and the referee), then a board of cards: the three
// sliders with their word and number, the trap and the marking on the right; the plan on its pitch, the tackling, and
// the three lines' positions on theirs on the left; each choice between two arrows. Then the expected effect, quick
// presets, the tactics book and the scenarios. Tips explain how the engine plays them; they change no number
// [PLAN 2.14]. Only tackling, marking, plan and trap are ever shown to the opponent. [Sprint 27 W6, the owner asked
// for OSM's ease] Every change saves itself a moment later: no «حفظ» to remember.
import UiSlider from '../../components/ui/UiSlider.vue'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components, paths } from '../../api/schema'
import TacticIcon from '../../components/tactics/TacticIcon.vue'
import TacticCycler from '../../components/tactics/TacticCycler.vue'
import PlanPitch from '../../components/tactics/PlanPitch.vue'
import LinesPitch from '../../components/tactics/LinesPitch.vue'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import ScenariosPanel from './ScenariosPanel.vue'
import { currentLeague } from '../../lib/currentLeague'

type T = Required<components['schemas']['TacticsSet']>
const leagueId = ref<number | null>(null)
const t = ref<T | null>(null)
const saved = ref('')
const tips = ref<string[]>([])
const referee = ref<string | null>(null)
const message = ref('')
const loaded = ref(false)
// The pre-match scenarios [X23], saved on their own.
const scenarios = ref<components['schemas']['Scenario'][] | null>(null)
// [Sprint 21 E5.4] The tactics book, from the engine's own table: what each plan beats, and what beats each shape.
type Book = components['responses']['Tactics']['content']['application/json']['book']
const book = ref<Book | null>(null)
const bookOpen = ref(false)
const SHAPES = { high: 'دفاع متقدم وضغط عالٍ', mid: 'دفاع متوسط', low: 'دفاع متأخر' } as const
const SHAPE_SHORT = { high: 'متقدم', mid: 'متوسط', low: 'متأخر' } as const
const kinds = ref<components['responses']['Tactics']['content']['application/json']['scenario_kinds']>([])
// [S1] The match the tactics are for (null between seasons): the header.
type Next = NonNullable<paths['/leagues/{league}/team/next-match']['get']['responses'][200]['content']['application/json']['match']>
const next = ref<Next | null>(null)

const PLANS = { counter: 'هجوم مرتد', shots: 'تسديد عن بعد', long: 'كرات طويلة', passing: 'تمريرات', wings: 'لعب على الأجنحة' } as const
const TACKLING = ['قانوني', 'عادي', 'حماس', 'خشونة']
const SLIDERS = [
  { key: 'pressing', label: 'الضغط على الخصم', low: 'منخفض', high: 'عالٍ' },
  { key: 'style', label: 'الأسلوب', low: 'دفاعي', high: 'هجومي' },
  { key: 'tempo', label: 'إيقاع اللعب', low: 'هادئ', high: 'سريع' },
] as const
const LINES = [
  { key: 'att', label: 'الهجوم', color: 'bg-line-att', options: { back: 'ارتداد', support: 'مساندة الوسط', only: 'هجوم فقط' } },
  { key: 'mid', label: 'الوسط', color: 'bg-line-mid', options: { def: 'مساندة الدفاع', stay: 'بقاء', push: 'اندفاع' } },
  { key: 'def', label: 'الدفاع', color: 'bg-line-def', options: { stay: 'بقاء', fullbacks: 'هجوم الظهيرين', mid: 'مساندة الوسط' } },
] as const
// [UP16] The quick presets of the spec (10): each sets the knobs the engine plays with.
const MENTALITY = [
  { id: 'all_out', label: 'الهجوم الكاسح', style: 95 }, { id: 'attacking', label: 'هجومي', style: 75 }, { id: 'balanced', label: 'متوازن', style: 50 },
  { id: 'defensive', label: 'دفاعي', style: 25 }, { id: 'park_bus', label: 'ركن الحافلة', style: 5 },
] as const
const PASSING = [
  { id: 'short', label: 'قصيرة وسريعة', plan: 'passing', tempo: 40 }, { id: 'through', label: 'بينية في المساحة', plan: 'counter', tempo: 70 },
  { id: 'long', label: 'طولية وعالية', plan: 'long', tempo: 55 }, { id: 'direct', label: 'مباشرة', plan: 'long', tempo: 85 },
] as const
const PRESSING = [{ id: 'press_low', label: 'منخفض', value: 20 }, { id: 'press_mid', label: 'متوسط', value: 50 }, { id: 'press_high', label: 'خنق الخصم', value: 85 }] as const
const near = (a: number, b: number) => Math.abs(a - b) <= 10
// [S1] The board's words: each slider's value in five bands, and every choice for the arrows.
const BANDS: Record<string, string[]> = {
  pressing: ['منخفض جداً', 'منخفض', 'طبيعي', 'عالٍ', 'خنق الخصم'],
  style: ['ركن الحافلة', 'دفاعي', 'متوازن', 'هجومي', 'هجوم كاسح'],
  tempo: ['بطيء', 'هادئ', 'متوسط', 'سريع', 'سريع جداً'],
}
const band = (key: string, v: number) => BANDS[key][Math.min(4, Math.floor(v / 20.0001))]
const opts = <K extends string | number>(o: Record<K, string> | readonly string[]) =>
  (Array.isArray(o) ? o.map((label, i) => ({ value: i as K, label })) : (Object.entries(o) as [K, string][]).map(([value, label]) => ({ value, label })))
const PLAN_OPTS = opts(PLANS as Record<keyof typeof PLANS, string>)
const TACKLING_OPTS = opts<number>(TACKLING)
const TRAP_OPTS = [{ value: 1, label: 'نعم' }, { value: 0, label: 'لا' }]
const MARKING_OPTS = [{ value: 'zone', label: 'دفاع المنطقة' }, { value: 'man', label: 'رجل لرجل' }]
const LINE_LABEL = { att: 'المهاجمون', mid: 'لاعبو الوسط', def: 'المدافعون' } as const
const LINE_TEXT = { att: 'text-line-att', mid: 'text-text', def: 'text-line-def' } as const
const FORM: Record<string, { label: string; cls: string }> = { W: { label: 'ف', cls: 'bg-success text-on-gold' }, D: { label: 'ت', cls: 'bg-surface-raised text-text' }, L: { label: 'خ', cls: 'bg-live text-white' } }
const strength = (cp: number) => Math.round(cp / 100)
const mentality = computed(() => MENTALITY.reduce((best, m) => (Math.abs(m.style - (t.value?.style ?? 50)) < Math.abs(best.style - (t.value?.style ?? 50)) ? m : best)).id)
const dirty = computed(() => !!t.value && JSON.stringify(t.value) !== saved.value)

async function load() {
  leagueId.value = await currentLeague()
  if (!leagueId.value) {
    loaded.value = true
    return
  }
  const path = { params: { path: { league: leagueId.value } } }
  const [{ data }, nm] = await Promise.all([api.GET('/leagues/{league}/team/tactics', path), api.GET('/leagues/{league}/team/next-match', path).catch(() => null)])
  next.value = nm?.data?.match ?? null
  apply(data!)
  scenarios.value = data!.scenarios
  book.value = data!.book
  kinds.value = data!.scenario_kinds
  loaded.value = true
}
function apply(d: { tactics: components['schemas']['TacticsSet']; tips: string[]; referee?: string | null }) {
  t.value = { ...(d.tactics as T) }
  saved.value = JSON.stringify(t.value)
  tips.value = d.tips
  referee.value = d.referee ?? null
}
async function save() {
  if (!leagueId.value || !t.value) return
  message.value = ''
  saving.value = true
  const sent = { ...t.value }
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/tactics', { params: { path: { league: leagueId.value } }, body: sent })
    // A change made while saving keeps its place on the screen and saves next.
    const mine = JSON.stringify(t.value)
    if (mine === JSON.stringify(sent)) apply(data!)
    else saved.value = JSON.stringify(data!.tactics)
    book.value = data!.book
  } catch (e) {
    message.value = asApiError(e).message
  }
  saving.value = false
}
const saving = ref(false)
let timer = 0
let waiting = false
watch(t, () => {
  if (!dirty.value) return
  window.clearTimeout(timer)
  waiting = true
  timer = window.setTimeout(() => {
    waiting = false
    save()
  }, 700)
}, { deep: true })
// [2026-11-09] Leaving the page before the save's moment: the change is saved now, not by a page that is gone.
onBeforeUnmount(() => {
  window.clearTimeout(timer)
  if (waiting) {
    waiting = false
    void save()
  }
})
onMounted(() => load().catch((e) => ((message.value = asApiError(e).message), (loaded.value = true))))
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <div v-if="loaded && !leagueId" class="rounded-xl bg-surface p-8 text-center">
      <p class="mb-3 text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
      <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink>
    </div>
    <template v-else-if="t">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="flex flex-wrap items-center gap-2 font-display text-3xl font-extrabold">{{ $t('التكتيك') }}<!-- [Sprint 20 W12] --><RouterLink :to="{ name: 'lineup' }" class="flex h-9 items-center rounded-pill bg-surface px-3 font-body text-xs font-bold text-brand-light">{{ $t('التشكيلة ›') }}</RouterLink></h1>
          <p class="text-sm text-text-muted">{{ $t('الحكم: {v0}', { v0: referee ? REFEREE[referee] : $t('يُعيَّن قبل المباراة بنصف ساعة') }) }}</p>
        </div>
        <span class="text-xs text-text-muted" role="status">{{ saving || dirty ? $t('يحفظ…') : $t('محفوظ ✓') }}</span>
      </header>
      <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>

      <!-- [S1] The match: my side at the start, the opponent at the end, their strength and the referee between. -->
      <section v-if="next" class="overflow-hidden rounded-xl border border-text/10 bg-panel" :aria-label="$t('المباراة القادمة')">
        <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 p-3 sm:p-4">
          <div class="flex min-w-0 items-center gap-2 sm:gap-3">
            <ClubCrest :url="next.club.crest_url" :code="next.club.code" :size="44" class="shrink-0" />
            <span class="min-w-0"><b class="block truncate font-display text-base sm:text-xl">{{ $nm(next.club.name) }}</b><span class="block truncate text-xs text-text-muted">{{ next.club.coach }}</span></span>
          </div>
          <div class="flex items-center gap-1.5 sm:gap-3">
            <span class="grid size-11 place-items-center rounded-full border-2 border-ring font-numbers text-xl sm:size-14 sm:text-2xl" :title="$t('القوة')">{{ strength(next.club.strength_cp) }}</span>
            <span class="font-numbers text-2xl font-extrabold italic text-gold sm:text-4xl" dir="ltr">VS</span>
            <span class="grid size-11 place-items-center rounded-full border-2 border-ring font-numbers text-xl sm:size-14 sm:text-2xl" :title="$t('القوة')">{{ strength(next.opponent.strength_cp) }}</span>
          </div>
          <div class="flex min-w-0 flex-row-reverse items-center gap-2 text-end sm:gap-3">
            <ClubCrest :url="next.opponent.crest_url" :code="next.opponent.code" :size="44" class="shrink-0" />
            <span class="min-w-0"><b class="block truncate font-display text-base sm:text-xl">{{ $nm(next.opponent.name) }}</b><span class="block truncate text-xs text-text-muted">{{ next.opponent.coach ?? $t('الكمبيوتر') }}</span></span>
          </div>
        </div>
        <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 bg-bg-deep px-3 py-2 text-sm">
          <div class="flex min-w-0 items-center gap-1">
            <span v-for="(r, i) in next.club.form" :key="i" class="grid size-6 place-items-center rounded-full text-xs font-bold" :class="FORM[r].cls" :title="$t(FORM[r].label)">{{ $t(FORM[r].label) }}</span>
            <span class="ms-1 truncate font-numbers text-base" dir="ltr">{{ next.club.formation.replace(/^custom:.*/, '') || $t('خطتي') }}</span>
          </div>
          <span class="whitespace-nowrap text-xs text-text-soft">{{ $t('الحكم: {v0}', { v0: next.referee ? $t(REFEREE[next.referee]) : '؟' }) }}</span>
          <div class="flex min-w-0 flex-row-reverse items-center gap-1">
            <span v-for="(r, i) in next.opponent.form" :key="i" class="grid size-6 place-items-center rounded-full text-xs font-bold" :class="FORM[r].cls" :title="$t(FORM[r].label)">{{ $t(FORM[r].label) }}</span>
            <!-- His formation only after the lock; before it, a question mark. -->
            <span class="me-1 truncate font-numbers text-base" dir="ltr">{{ next.opponent.sheet?.formation ?? '?' }}</span>
          </div>
        </div>
      </section>

      <!-- [S1] The board: the sliders, the trap and the marking first (the right in Arabic); the plan, the tackling and
           the positions second. One column on a phone. -->
      <div class="grid gap-3 md:grid-cols-2">
        <div class="flex flex-col gap-3">
          <section v-for="sl in SLIDERS" :key="sl.key" class="flex flex-col gap-2 rounded-xl border border-text/10 bg-surface p-4">
            <span class="flex items-center justify-center gap-1 text-sm font-bold text-ring"><label :for="`t-${sl.key}`">{{ $t(sl.label) }}</label></span>
            <b class="text-center font-display text-lg">{{ $t(band(sl.key, t[sl.key])) }}</b>
            <div class="flex items-center gap-3">
              <output :for="`t-${sl.key}`" class="grid h-9 w-12 shrink-0 place-items-center rounded-md bg-bg-deep font-numbers text-lg">{{ t[sl.key] }}</output>
              <!-- [Sprint 30 Q4] reka-ui's Slider: smooth under the finger, the right way in Arabic. -->
              <UiSlider :id="`t-${sl.key}`" v-model="t[sl.key]" :step="5" :label="sl.label" :value-text="$t(band(sl.key, t[sl.key]))" class="flex-1" />
            </div>
          </section>
          <div class="grid grid-cols-2 gap-3">
            <section class="flex flex-col items-center gap-2 rounded-xl border border-text/10 bg-surface p-3">
              <span class="flex items-center gap-1 text-sm font-bold text-ring">{{ $t('مصيدة التسلل') }}</span>
              <TacticCycler v-model="t.trap" :options="TRAP_OPTS" :label="$t('مصيدة التسلل')" class="w-full" />
              <TacticIcon :name="t.trap === 1 ? 'trap_on' : 'trap_off'" :active="true" class="!size-14" />
              <span class="text-xs text-text-muted">{{ $t('يراها الخصم بعد القفل') }}</span>
            </section>
            <section class="flex flex-col items-center gap-2 rounded-xl border border-text/10 bg-surface p-3">
              <span class="flex items-center gap-1 text-sm font-bold text-ring">{{ $t('الرقابة') }}</span>
              <TacticCycler v-model="t.marking" :options="MARKING_OPTS" :label="$t('الرقابة')" class="w-full" />
              <TacticIcon :name="t.marking" :active="true" class="!size-14" />
              <span class="text-xs text-text-muted">{{ $t('يراها الخصم بعد القفل') }}</span>
            </section>
          </div>
        </div>
        <div class="flex flex-col gap-3">
          <div class="grid gap-3 sm:grid-cols-2">
            <section class="flex flex-col gap-2 rounded-xl border border-text/10 bg-surface p-3">
              <span class="flex items-center justify-center gap-1 text-sm font-bold text-ring">{{ $t('خطة اللعب') }}</span>
              <TacticCycler v-model="t.plan" :options="PLAN_OPTS" :label="$t('خطة اللعب')" />
              <PlanPitch :plan="t.plan" />
            </section>
            <section class="flex flex-col items-center gap-2 rounded-xl border border-text/10 bg-surface p-3">
              <span class="flex items-center gap-1 text-sm font-bold text-ring">{{ $t('قطع الكرة') }}</span>
              <TacticCycler v-model="t.tackling" :options="TACKLING_OPTS" :label="$t('قطع الكرة')" class="w-full" />
              <TacticIcon :name="`tackle_${t.tackling}`" :active="true" class="!size-20 flex-1" />
            </section>
          </div>
          <section class="flex flex-col gap-3 rounded-xl border border-text/10 bg-surface p-4">
            <span class="flex items-center justify-center gap-1 text-sm font-bold text-ring">{{ $t('التمركز') }}</span>
            <div class="grid grid-cols-[6rem_1fr] items-center gap-2 sm:grid-cols-[minmax(0,10rem)_1fr] sm:gap-4">
              <LinesPitch :att="t.att" :mid="t.mid" :def="t.def" />
              <div class="flex min-w-0 flex-col gap-2">
                <div v-for="l in LINES" :key="l.key" class="flex flex-col">
                  <span class="text-center text-xs font-bold" :class="LINE_TEXT[l.key]">{{ $t(LINE_LABEL[l.key]) }}</span>
                  <TacticCycler v-model="(t as unknown as Record<string, string>)[l.key]" :options="opts(l.options as Record<string, string>)" :label="$t(LINE_LABEL[l.key])" />
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>

      <section class="flex flex-col gap-2 rounded-xl border border-gold/30 bg-surface p-4" aria-labelledby="h-tips">
        <div class="flex flex-wrap items-center justify-between gap-x-2">
          <h2 id="h-tips" class="text-sm text-text-muted">{{ $t('الأثر المتوقع في المباراة{v0}', { v0: dirty ? $t(' (يتحدث بعد الحفظ)') : '' }) }}</h2>
        </div>
        <ul class="flex flex-col gap-1.5 text-sm">
          <li v-for="(tip, i) in tips" :key="i" class="rounded-lg bg-surface-sunk px-3 py-2">{{ tip }}</li>
        </ul>
      </section>

      <!-- Quick presets [UP16]: each sets the knobs above. -->
      <details class="rounded-xl bg-surface p-4">
        <summary class="min-h-touch cursor-pointer content-center font-bold">{{ $t('قوالب سريعة') }}</summary>
        <div class="mt-3 flex flex-col gap-4">
      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('العقلية') }}</legend>
        <div class="grid grid-cols-5 gap-1">
          <button v-for="m in MENTALITY" :key="m.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="mentality === m.id ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="mentality === m.id" @click="t.style = m.style">
            <TacticIcon :name="m.id" :active="mentality === m.id" />{{ $t(m.label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('أسلوب التمرير') }}</legend>
        <div class="grid grid-cols-4 gap-1">
          <button v-for="ps in PASSING" :key="ps.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="t.plan === ps.plan && near(t.tempo, ps.tempo) ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="t.plan === ps.plan && near(t.tempo, ps.tempo)"
            @click="t.plan = ps.plan; t.tempo = ps.tempo"><TacticIcon :name="ps.id" :active="t.plan === ps.plan && near(t.tempo, ps.tempo)" />{{ $t(ps.label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('درجة الضغط') }}</legend>
        <div class="grid grid-cols-3 gap-1">
          <button v-for="pr in PRESSING" :key="pr.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="near(t.pressing, pr.value) ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="near(t.pressing, pr.value)" @click="t.pressing = pr.value">
            <TacticIcon :name="pr.id" :active="near(t.pressing, pr.value)" />{{ $t(pr.label) }}</button>
        </div>
      </fieldset>

        </div>
      </details>

      <!-- [Sprint 21 E5.4] The tactics book: each plan against each defensive shape, and the answer to each shape. -->
      <section v-if="book" class="flex flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4" aria-labelledby="h-book">
        <button type="button" class="flex min-h-touch items-center justify-between gap-2 text-start" :aria-expanded="bookOpen" aria-controls="book-body" @click="bookOpen = !bookOpen">
          <span>
            <h2 id="h-book" class="font-display text-xl font-extrabold">{{ $t('كتاب التكتيك') }}</h2>
            <span class="text-xs text-text-muted">{{ $t('لكل خطة خطة تتفوق عليها: الأضعف يرد بالخطة المناسبة. التفوق في الفرص، لا في قوة اللاعبين.') }}</span>
          </span>
          <span class="text-xl text-gold" aria-hidden="true">{{ bookOpen ? '−' : '+' }}</span>
        </button>
        <div v-if="bookOpen" id="book-body" class="flex flex-col gap-3">
          <p v-if="book.mine" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm">
            {{ $t('تكتيكك المحفوظ يصنع: {v0}.', { v0: $t(SHAPES[book.mine]) }) }}
            <template v-if="book.shapes.find((x) => x.shape === book!.mine)?.beaten_by.length">
              {{ $t('يتفوق عليه: {v0}.', { v0: book.shapes.find((x) => x.shape === book!.mine)!.beaten_by.map((p) => $t(PLANS[p])).join('، ') }) }}
            </template>
          </p>
          <ul class="grid gap-2 sm:grid-cols-3">
            <li v-for="sh in book.shapes" :key="sh.shape" class="flex flex-col gap-1 rounded-lg bg-surface-sunk p-3 text-sm">
              <b>{{ $t('ضد {v0}', { v0: $t(SHAPES[sh.shape]) }) }}</b>
              <span v-if="sh.beaten_by.length" class="text-success">{{ $t('العب: {v0}', { v0: sh.beaten_by.map((p) => $t(PLANS[p])).join('، ') }) }}</span>
              <span v-if="sh.stops.length" class="text-danger">{{ $t('تجنّب: {v0}', { v0: sh.stops.map((p) => $t(PLANS[p])).join('، ') }) }}</span>
            </li>
          </ul>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[20rem] text-sm">
              <caption class="sr-only">{{ $t('كل خطة أمام كل شكل دفاعي') }}</caption>
              <thead class="text-xs text-text-muted">
                <tr><th scope="col" class="py-1 text-start">{{ $t('خطة اللعب') }}</th><th v-for="(label, k) in SHAPE_SHORT" :key="k" scope="col" class="py-1">{{ $t(label) }}</th></tr>
              </thead>
              <tbody>
                <tr v-for="p in book.plans" :key="p.plan" class="border-t border-text/10" :class="p.plan === t.plan ? 'text-gold' : ''">
                  <th scope="row" class="py-2 text-start font-bold">{{ $t(PLANS[p.plan]) }}</th>
                  <td v-for="(_, k) in SHAPES" :key="k" class="py-2 text-center">
                    <span v-if="p.edge[k] > 0" class="font-bold text-success" :title="$t('تتفوق')">▲</span>
                    <span v-else-if="p.edge[k] < 0" class="font-bold text-danger" :title="$t('تتعثر')">▼</span>
                    <span v-else class="text-text-muted" :title="$t('متعادلة')">●</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <ScenariosPanel v-if="leagueId && scenarios" :league-id="leagueId" :scenarios="scenarios" :kinds="kinds" />
    </template>
    <p v-else class="text-text-muted">{{ message || $t('جارٍ التحميل…') }}</p>
  </div>
</template>
