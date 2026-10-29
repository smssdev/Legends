<script setup lang="ts">
// Make a league (Sprint 13 W1), after the drafts WebCreateLeague and MobileCreateLeague, then choose the owner's club.
// [UP9] The owner's spec (4, 2026-10-26): the standard league is free (every club of the real league, two days to get
// ready, one round a day at the owner's evening, the integrity system and the press conferences on, one season).
// Changing anything makes it a customized league, paid once: the clubs × 20 coins, shown with the coin, never as a "price".
import UiToggle from '../../components/ui/UiToggle.vue'
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf, type ApiError } from '../../api/client'
import { budget, END_MODES, lockFromRound, roundsFor } from '../../api/leagues'
import type { components } from '../../api/schema'
import TextField from '../../components/TextField.vue'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import UiButton from '../../components/ui/UiButton.vue'
import { strength } from '../../lib/format'
import { useWallet } from '../../stores/wallet'

type Template = { name: string; clubs: number; top_strength_cp: number }
type Club = components['schemas']['DataClub']

const COINS_PER_CLUB = 20
const FREE = { prep: 2, budget: 3_000_000, time: '21:00', end: 'end' as const }

const router = useRouter()
const wallet = useWallet()
const templates = ref<Template[]>([])
const name = ref('')
const template = ref('')
const startsAt = ref(defaultStart())
// The customized league's settings, from the free ones.
const custom = ref(false)
const teams = ref(20)
const prepDays = ref(FREE.prep)
const time = ref(FREE.time)
const customTime = ref(false)
const startingBudget = ref(FREE.budget)
const fair = ref(false)
const integrity = ref(true)
const press = ref(true)
const staggered = ref(false)
const slotGap = ref(240)
const endMode = ref<'renew' | 'end'>(FREE.end)

const step = ref<'settings' | 'club'>('settings')
const clubs = ref<Club[]>([])
const club = ref<Club | null>(null)
const error = ref<ApiError | null>(null)
const loadError = ref('')
const sending = ref(false)

const fullTeams = computed(() => Math.min(20, templates.value.find((t) => t.name === template.value)?.clubs ?? 20))
/** At least half the real league's clubs [UP9]. */
const minTeams = computed(() => Math.min(fullTeams.value, Math.max(4, Math.ceil(fullTeams.value / 2))))
const count = computed(() => (custom.value ? teams.value : fullTeams.value))
const rounds = computed(() => roundsFor(count.value))
const lockFrom = computed(() => lockFromRound(rounds.value))
watch(fullTeams, (m) => (teams.value = m))

/** What differs from the free league: none, and it stays free. */
const changes = computed(() => {
  if (!custom.value) return {}
  const c: Record<string, unknown> = {}
  if (teams.value !== fullTeams.value) c.team_count = teams.value
  if (prepDays.value !== FREE.prep) c.prep_days = prepDays.value
  if (customTime.value) c.round_times = [time.value]
  if (startingBudget.value !== FREE.budget) c.starting_budget = startingBudget.value
  if (fair.value) c.fair_league = true
  if (!integrity.value) c.integrity = false
  if (!press.value) c.press_conferences = false
  if (staggered.value) c.second_slot_minutes = slotGap.value
  if (endMode.value !== FREE.end) c.season_end_mode = endMode.value
  return c
})
const customized = computed(() => Object.keys(changes.value).length > 0)
const coins = computed(() => (customized.value ? count.value * COINS_PER_CLUB : 0))
const short = computed(() => customized.value && (wallet.view?.balance ?? 0) < coins.value)

/** Tomorrow at 21:00 on this device: the field shows and sends the device's own time. */
function defaultStart() {
  const d = new Date()
  d.setDate(d.getDate() + 1)
  d.setHours(21, 0, 0, 0)
  return local(d)
}
function local(d: Date) {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`
}
const minStart = local(new Date())
const maxStart = local(new Date(Date.now() + 7 * 86400000))

onMounted(async () => {
  void wallet.load()
  try {
    const { data } = await api.GET('/data/templates')
    templates.value = (data as { templates: Template[] }).templates.filter((t) => t.clubs >= 4)
    template.value = templates.value[0]?.name ?? ''
  } catch (e) {
    loadError.value = asApiError(e).message
  }
})

/** Step two: the clubs this league will copy, to choose the owner's own. */
async function toClubs() {
  error.value = null
  try {
    const { data } = await api.GET('/data/clubs', { params: { query: { league: template.value } } })
    clubs.value = (data as { clubs: Club[] }).clubs.slice(0, count.value)
    club.value = null
    step.value = 'club'
    window.scrollTo({ top: 0 })
  } catch (e) {
    error.value = asApiError(e)
  }
}

async function create() {
  if (!club.value) return
  error.value = null
  sending.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues', {
      body: {
        name: name.value.trim() || null,
        template: template.value,
        starts_at: new Date(startsAt.value).toISOString(),
        // The free league plays at this owner's evening, in their own time zone.
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        ...changes.value,
        is_dev: import.meta.env.DEV,
        club_id: club.value.id,
      },
    })
    void wallet.load()
    router.push({ name: 'league-home', params: { id: data!.league.id }, query: { welcome: '1' } })
  } catch (e) {
    error.value = asApiError(e)
    // A wrong setting sends the owner back to the form, where its message shows under the field.
    if (Object.keys(error.value.errors).some((k) => k !== 'club_id')) step.value = 'settings'
  }
  sending.value = false
}

const field = (name: string) => error.value?.field(name) ?? ''
</script>

<template>
  <div class="flex flex-col gap-5">
    <header class="flex items-center gap-3">
      <button
        v-if="step === 'club'"
        type="button"
        class="flex size-touch items-center justify-center rounded-lg bg-surface text-xl"
        :aria-label="$t('رجوع للإعدادات')"
        @click="step = 'settings'"
      >›</button>
      <div>
        <h1 class="font-display text-3xl font-extrabold">{{ step === 'settings' ? $t('أنشئ دوريك') : $t('اختر فريقك') }}</h1>
        <p class="text-sm text-text-muted">{{ step === 'settings' ? $t('كل الإعدادات تُقفل عند بداية الموسم') : $t('باقي الفرق يديرها الحاسوب حتى ينضم أصحابك') }}</p>
      </div>
    </header>

    <p v-if="loadError" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(loadError) }}</p>
    <p v-if="error && !Object.keys(error.errors).length" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error.message) }}</p>

    <form v-if="step === 'settings'" class="grid gap-4 lg:grid-cols-[1fr_22rem]" @submit.prevent="toClubs">
      <div class="flex flex-col gap-4">
        <section class="flex flex-col gap-4 rounded-xl bg-surface p-4 md:p-5" aria-labelledby="h-basics">
          <h2 id="h-basics" class="font-display text-xl font-extrabold">{{ $t('الأساسيات') }}</h2>
          <TextField v-model="name" :label="$t('اسم الدوري')" :placeholder="$t('فارغ: اسم الدوري والكود')" :error="field('name')" />
          <div class="grid gap-4 md:grid-cols-2">
            <label class="flex flex-col gap-1.5">
              <span class="text-sm font-bold">{{ $t('الدوري') }}</span>
              <select v-model="template" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4" :aria-invalid="!!field('template')">
                <option v-for="t in templates" :key="t.name" :value="t.name">{{ $t('{v0} · {v1} نادياً', { v0: $nm(t.name), v1: t.clubs }) }}</option>
              </select>
              <span v-if="field('template')" class="text-sm text-danger">{{ field('template') }}</span>
            </label>
            <label class="flex flex-col gap-1.5">
              <span class="text-sm font-bold">{{ $t('بداية الموسم (بتوقيتك)') }}</span>
              <input v-model="startsAt" type="datetime-local" :min="minStart" :max="maxStart" required class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4" />
              <span v-if="field('starts_at')" class="text-sm text-danger">{{ field('starts_at') }}</span>
            </label>
          </div>
        </section>

        <!-- The free league, as it comes. -->
        <section class="flex flex-col gap-3 rounded-xl bg-surface p-4 md:p-5" aria-labelledby="h-free">
          <h2 id="h-free" class="font-display text-xl font-extrabold">{{ $t('الدوري القياسي') }} <span class="rounded-pill bg-success/15 px-2.5 py-0.5 align-middle text-xs text-success">{{ $t('مجاني') }}</span></h2>
          <ul class="grid gap-2 text-sm text-text-soft md:grid-cols-2">
            <li>{{ $t('⚽ كل أندية الدوري الأصلي ({v0})', { v0: fullTeams }) }}</li>
            <li>{{ $t('🕘 جولة واحدة يومياً في التاسعة مساءً بتوقيتك') }}</li>
            <li>{{ $t('📅 يومان للإعداد قبل أول جولة') }}</li>
            <li>{{ $t('🎙️ المؤتمرات الصحفية ومنظومة النزاهة مفعّلتان') }}</li>
            <li>{{ $t('🏁 موسم واحد ثم ينتهي الدوري') }}</li>
            <li>{{ $t('⚖️ لا دوري نزيه ولا جولة على فترتين') }}</li>
          </ul>
          <UiToggle v-model="custom" class="rounded-lg bg-surface-sunk p-3" :hint="$t('عدد الأندية، والإعداد، والساعة، والميزانية، والمزايا، والتجديد')"><b>{{ $t('أريد تخصيص الدوري') }}</b></UiToggle>
        </section>

        <template v-if="custom">
          <section class="flex flex-col gap-4 rounded-xl border border-gold/30 bg-surface p-4 md:p-5" aria-labelledby="h-custom">
            <h2 id="h-custom" class="font-display text-xl font-extrabold">{{ $t('التخصيص') }}</h2>
            <div class="grid gap-4 md:grid-cols-2">
              <div class="flex flex-col gap-1.5">
                <span id="l-teams" class="text-sm font-bold">{{ $t('عدد الأندية') }}</span>
                <div class="flex items-center justify-between gap-2" role="group" aria-labelledby="l-teams">
                  <button type="button" class="flex size-12 items-center justify-center rounded-lg bg-surface-raised text-2xl" :aria-label="$t('أقل')" :disabled="teams <= minTeams" @click="teams--">−</button>
                  <output class="font-numbers text-4xl font-bold text-gold" aria-live="polite">{{ teams }}</output>
                  <button type="button" class="flex size-12 items-center justify-center rounded-lg bg-surface-raised text-2xl" :aria-label="$t('أكثر')" :disabled="teams >= fullTeams" @click="teams++">+</button>
                </div>
                <span class="text-xs text-text-muted">{{ $t('من {v0} (نصف أندية الدوري) إلى {v1}', { v0: minTeams, v1: fullTeams }) }}</span>
                <span v-if="field('team_count')" class="text-sm text-danger">{{ field('team_count') }}</span>
              </div>
              <fieldset class="flex flex-col gap-1.5">
                <legend class="mb-1.5 text-sm font-bold">{{ $t('فترة الإعداد') }}</legend>
                <div class="grid grid-cols-3 gap-1 rounded-lg bg-surface-sunk p-1">
                  <button v-for="d in [2, 4, 6]" :key="d" type="button" class="h-11 rounded-md font-bold" :class="prepDays === d ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="prepDays === d" @click="prepDays = d">
                    {{ d === 2 ? $t('يومان') : $t('{v0} أيام', { v0: d }) }}
                  </button>
                </div>
              </fieldset>
              <div class="flex flex-col gap-1.5">
                <UiToggle v-model="customTime" class="rounded-lg bg-surface-sunk p-3"><b>{{ $t('ساعة مباريات محددة') }}</b></UiToggle>
                <input v-if="customTime" v-model="time" type="time" required dir="ltr" :aria-label="$t('ساعة المباريات بتوقيت القاهرة')" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4 font-numbers text-lg" />
                <span v-if="customTime" class="text-xs text-text-muted">{{ $t('بتوقيت القاهرة، كل مباريات الجولة معاً') }}</span>
                <span v-if="field('round_times')" class="text-sm text-danger">{{ field('round_times') }}</span>
              </div>
              <label class="flex flex-col gap-2">
                <span class="flex items-center justify-between text-sm font-bold">{{ $t('ميزانية البداية لكل نادٍ') }} <span class="font-numbers text-lg text-gold">{{ budget(startingBudget) }}</span></span>
                <input v-model.number="startingBudget" type="range" min="1000000" max="10000000" step="500000" class="accent-gold" />
                <span class="flex justify-between text-xs text-text-muted"><span>{{ $t('مليون') }}</span><span>{{ $t('10 ملايين') }}</span></span>
              </label>
            </div>
            <UiToggle v-model="fair" tone="success" class="rounded-lg bg-surface-sunk p-3" :hint="$t('يقفل صرف الكوينز داخل هذا الدوري')"><b>{{ $t('دوري نزيه') }}</b></UiToggle>
            <UiToggle v-model="integrity" class="rounded-lg bg-surface-sunk p-3" :hint="$t('رشوة الحكم والفار والجواسيس المزدوجون ولجنة الانضباط والفضائح')"><b>{{ $t('منظومة النزاهة') }}</b></UiToggle>
            <UiToggle v-model="press" class="rounded-lg bg-surface-sunk p-3" :hint="$t('تصريح قبل كل مباراة يرفع المعنويات')"><b>{{ $t('المؤتمرات الصحفية') }}</b></UiToggle>
            <UiToggle v-model="staggered" class="rounded-lg bg-surface-sunk p-3" :hint="$t('نصف مباريات الجولة في موعدها والنصف الآخر بعدها، بقفل موحد وتدوير عادل')"><b>{{ $t('الجولة على فترتين') }}</b></UiToggle>
            <label v-if="staggered" class="flex items-center justify-between gap-3 rounded-lg bg-surface-sunk p-3 text-sm">{{ $t('الفترة الثانية بعد موعد الجولة بـ') }}
              <select v-model.number="slotGap" class="h-touch rounded-md bg-surface px-2 font-bold">
                <option v-for="m in [60, 120, 180, 240, 300, 360]" :key="m" :value="m">{{ m / 60 }} {{ m === 60 ? $t('ساعة') : m === 120 ? $t('ساعتين') : $t('ساعات') }}</option>
              </select>
            </label>
            <fieldset class="flex flex-col gap-2">
              <legend class="mb-1.5 text-sm font-bold">{{ $t('في نهاية الموسم') }}</legend>
              <div class="grid gap-2 md:grid-cols-2">
                <label
                  v-for="(label, mode) in END_MODES"
                  :key="mode"
                  class="flex min-h-touch cursor-pointer items-center gap-3 rounded-lg border p-3"
                  :class="endMode === mode ? 'border-gold bg-surface-raised' : 'border-text/10'"
                >
                  <input v-model="endMode" type="radio" name="end" :value="mode" class="size-5 accent-gold" />{{ $t(label) }}
                </label>
              </div>
            </fieldset>
          </section>
        </template>
      </div>

      <aside class="flex h-fit flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4 lg:sticky lg:top-4" aria-labelledby="h-summary">
        <h2 id="h-summary" class="font-display text-xl font-extrabold">{{ $t('ملخص الموسم') }}</h2>
        <dl class="flex flex-col divide-y divide-text/5 text-sm">
          <div class="flex justify-between py-2"><dt class="text-text-muted">{{ $t('جولات الدوري') }}</dt><dd class="font-bold"><span class="font-numbers">{{ rounds }}</span> {{ $t('جولة') }}</dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">{{ $t('منطقة القفل') }}</dt><dd class="font-bold">{{ $t('من الجولة') }} <span class="font-numbers">{{ lockFrom }}</span></dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">{{ $t('مقاعد المدربين') }}</dt><dd class="font-bold"><span class="font-numbers">{{ count }}</span> {{ $t('· مقعدك و') }}<span class="font-numbers">{{ count - 1 }}</span> {{ $t('لأصحابك') }}</dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">{{ $t('الميزانية') }}</dt><dd class="font-bold">{{ budget(custom ? startingBudget : FREE.budget) }}</dd></div>
        </dl>
        <p class="text-xs text-text-muted">{{ $t('بعد الإنشاء تختار فريقك، وتحصل على كود تشاركه. الفرق الأخرى يديرها الحاسوب حتى ينضم أصحابك.') }}</p>
        <p v-if="short" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="alert">{{ $t('رصيدك {v0} كوينز، والدوري المخصص يحتاج {v1}.', { v0: wallet.view?.balance ?? 0, v1: coins }) }}</p>
        <UiButton type="submit" block :disabled="!template || short">
          <template v-if="customized">{{ $t('إنشاء الدوري المخصص ·') }} <img src="/brand/coin.svg" alt="" class="inline size-5 align-[-4px]" /> <span class="font-numbers">{{ coins }}</span> {{ $t('كوينز') }}</template>
          <template v-else>{{ $t('أنشئ الدوري واختر فريقك') }}</template>
        </UiButton>
      </aside>
    </form>

    <section v-else class="flex flex-col gap-3 pb-36 md:pb-0" :aria-label="$t('أندية الدوري')">
      <ul class="grid gap-2 md:grid-cols-2">
        <li v-for="c in clubs" :key="c.id">
          <button
            type="button"
            class="flex min-h-20 w-full items-center gap-3 rounded-xl border p-3 text-start"
            :class="club?.id === c.id ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface hover:bg-surface-raised'"
            :aria-pressed="club?.id === c.id"
            @click="club = c"
          >
            <ClubCrest :url="c.crest_url" :code="c.code" :size="48" />
            <span class="min-w-0 flex-1 truncate font-display text-lg font-extrabold">{{ $nm(c.name) }}</span>
            <span class="font-numbers text-3xl font-bold text-gold">{{ strength(c.strength_cp) }}</span>
          </button>
        </li>
      </ul>
      <div class="fixed inset-x-0 bottom-20 z-10 border-t border-text/10 bg-bg-deep p-4 md:static md:border-0 md:bg-transparent md:p-0">
        <UiButton block :disabled="!club || sending" @click="create">{{ club ? $t('أنشئ الدوري بـ{v0}', { v0: club.name }) + (coins ? $t(' · {v0} كوينز', { v0: coins }) : '') : $t('اختر فريقك') }}</UiButton>
      </div>
    </section>
  </div>
</template>
