<script setup lang="ts">
// Make a league (Sprint 13 W1), after the drafts WebCreateLeague and MobileCreateLeague: the basics, the
// times, the money and rules, and the season's summary; then "أنشئ الدوري واختر فريقك" shows the copied
// clubs to choose the owner's own. The server makes it all in one step [PLAN 2.1, 2.3].
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

type Template = { name: string; clubs: number; top_strength_cp: number }
type Club = components['schemas']['DataClub']

const router = useRouter()
const templates = ref<Template[]>([])
const name = ref('')
const template = ref('')
const teams = ref(16)
const startsAt = ref(defaultStart())
const prepDays = ref(2)
const roundsPerDay = ref(1)
const times = ref(['21:00', '18:00'])
const startingBudget = ref(3_000_000)
const fair = ref(true)
// The integrity system: bribes, spies and the FA [X28], off unless the owner wants it.
const integrity = ref(false)
// Each round in two time slots [X31]: off, or the second slot this many minutes after the round's time.
const staggered = ref(false)
const slotGap = ref(240)
const endMode = ref<'renew' | 'end'>('renew')

const step = ref<'settings' | 'club'>('settings')
const clubs = ref<Club[]>([])
const club = ref<Club | null>(null)
const error = ref<ApiError | null>(null)
const loadError = ref('')
const sending = ref(false)

const maxTeams = computed(() => Math.min(20, templates.value.find((t) => t.name === template.value)?.clubs ?? 20))
const rounds = computed(() => roundsFor(teams.value))
const lockFrom = computed(() => lockFromRound(rounds.value))
watch(maxTeams, (m) => (teams.value = Math.min(Math.max(teams.value, 4), m)))

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
    clubs.value = (data as { clubs: Club[] }).clubs.slice(0, teams.value)
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
        team_count: teams.value,
        rounds_per_day: roundsPerDay.value,
        round_times: times.value.slice(0, roundsPerDay.value),
        prep_days: prepDays.value,
        season_end_mode: endMode.value,
        starts_at: new Date(startsAt.value).toISOString(),
        starting_budget: startingBudget.value,
        fair_league: fair.value,
        integrity: integrity.value,
        second_slot_minutes: staggered.value ? slotGap.value : null,
        is_dev: import.meta.env.DEV,
        club_id: club.value.id,
      },
    })
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
        aria-label="رجوع للإعدادات"
        @click="step = 'settings'"
      >›</button>
      <div>
        <h1 class="font-display text-3xl font-extrabold">{{ step === 'settings' ? 'أنشئ دوريك' : 'اختر فريقك' }}</h1>
        <p class="text-sm text-text-muted">{{ step === 'settings' ? 'كل الإعدادات تُقفل عند بداية الموسم' : 'باقي الفرق يديرها الحاسوب حتى ينضم أصحابك' }}</p>
      </div>
    </header>

    <p v-if="loadError" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ loadError }}</p>
    <p v-if="error && !Object.keys(error.errors).length" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error.message }}</p>

    <form v-if="step === 'settings'" class="grid gap-4 lg:grid-cols-[1fr_22rem]" @submit.prevent="toClubs">
      <div class="flex flex-col gap-4">
        <section class="flex flex-col gap-4 rounded-xl bg-surface p-4 md:p-5" aria-labelledby="h-basics">
          <h2 id="h-basics" class="font-display text-xl font-extrabold">الأساسيات</h2>
          <TextField v-model="name" label="اسم الدوري" placeholder="فارغ: اسم القالب والكود" :error="field('name')" />
          <div class="grid gap-4 md:grid-cols-2">
            <label class="flex flex-col gap-1.5">
              <span class="text-sm font-bold">القالب</span>
              <select v-model="template" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4" :aria-invalid="!!field('template')">
                <option v-for="t in templates" :key="t.name" :value="t.name">{{ $nm(t.name) }} · {{ t.clubs }} نادياً</option>
              </select>
              <span v-if="field('template')" class="text-sm text-[#FF8A8A]">{{ field('template') }}</span>
            </label>
            <div class="flex flex-col gap-1.5">
              <span id="l-teams" class="text-sm font-bold">عدد الفرق</span>
              <div class="flex items-center justify-between gap-2" role="group" aria-labelledby="l-teams">
                <button type="button" class="flex size-12 items-center justify-center rounded-lg bg-surface-raised text-2xl" aria-label="أقل" :disabled="teams <= 4" @click="teams--">−</button>
                <output class="font-numbers text-4xl font-bold text-gold" aria-live="polite">{{ teams }}</output>
                <button type="button" class="flex size-12 items-center justify-center rounded-lg bg-surface-raised text-2xl" aria-label="أكثر" :disabled="teams >= maxTeams" @click="teams++">+</button>
              </div>
              <span class="text-xs text-text-muted">من 4 إلى {{ maxTeams }} · أقوى {{ teams }} نادياً في القالب</span>
            </div>
          </div>
        </section>

        <section class="flex flex-col gap-4 rounded-xl bg-surface p-4 md:p-5" aria-labelledby="h-times">
          <h2 id="h-times" class="font-display text-xl font-extrabold">المواعيد</h2>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="flex flex-col gap-1.5">
              <span class="text-sm font-bold">بداية الموسم (بتوقيتك)</span>
              <input v-model="startsAt" type="datetime-local" :min="minStart" :max="maxStart" required class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4" />
              <span v-if="field('starts_at')" class="text-sm text-[#FF8A8A]">{{ field('starts_at') }}</span>
            </label>
            <fieldset class="flex flex-col gap-1.5">
              <legend class="mb-1.5 text-sm font-bold">فترة الإعداد</legend>
              <div class="grid grid-cols-3 gap-1 rounded-lg bg-surface-sunk p-1">
                <button v-for="d in [1, 2, 3]" :key="d" type="button" class="h-11 rounded-md font-bold" :class="prepDays === d ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="prepDays === d" @click="prepDays = d">
                  {{ ['يوم', 'يومان', '3 أيام'][d - 1] }}
                </button>
              </div>
            </fieldset>
            <fieldset class="flex flex-col gap-1.5">
              <legend class="mb-1.5 text-sm font-bold">الجولات يومياً</legend>
              <div class="grid grid-cols-2 gap-1 rounded-lg bg-surface-sunk p-1">
                <button v-for="n in [1, 2]" :key="n" type="button" class="h-11 rounded-md font-bold" :class="roundsPerDay === n ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="roundsPerDay === n" @click="roundsPerDay = n">
                  {{ n === 1 ? 'جولة' : 'جولتان' }}
                </button>
              </div>
            </fieldset>
            <div class="flex flex-col gap-1.5">
              <span class="text-sm font-bold">{{ roundsPerDay === 1 ? 'ساعة الجولة' : 'ساعتا الجولتين' }} (القاهرة)</span>
              <div class="grid gap-2" :class="roundsPerDay === 2 ? 'grid-cols-2' : ''">
                <input
                  v-for="i in roundsPerDay"
                  :key="i"
                  v-model="times[i - 1]"
                  type="time"
                  required
                  dir="ltr"
                  :aria-label="`ساعة الجولة ${i}`"
                  class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4 font-numbers text-lg"
                />
              </div>
              <span v-if="field('round_times') || field('round_times.1')" class="text-sm text-[#FF8A8A]">{{ field('round_times') || field('round_times.1') }}</span>
            </div>
          </div>
        </section>

        <section class="flex flex-col gap-4 rounded-xl bg-surface p-4 md:p-5" aria-labelledby="h-money">
          <h2 id="h-money" class="font-display text-xl font-extrabold">الاقتصاد والقواعد</h2>
          <label class="flex flex-col gap-2">
            <span class="flex items-center justify-between text-sm font-bold">ميزانية البداية لكل نادٍ <span class="font-numbers text-lg text-gold">{{ budget(startingBudget) }}</span></span>
            <input v-model.number="startingBudget" type="range" min="1000000" max="10000000" step="500000" class="accent-gold" />
            <span class="flex justify-between text-xs text-text-muted"><span>مليون</span><span>10 ملايين</span></span>
          </label>
          <UiToggle v-model="fair" tone="success" class="rounded-lg bg-surface-sunk p-3" hint="يقفل صرف العملة المميزة داخل هذا الدوري"><b>دوري نزيه</b></UiToggle>
          <UiToggle v-model="integrity" class="rounded-lg bg-surface-sunk p-3" hint="رشوة الحكم والفار والجواسيس المزدوجون ولجنة الانضباط والفضائح"><b>منظومة النزاهة والمؤامرات</b></UiToggle>
          <UiToggle v-model="staggered" class="rounded-lg bg-surface-sunk p-3" hint="نصف مباريات الجولة في موعدها والنصف الآخر في سهرة بعدها، بقفل موحد وتدوير عادل، والجولة الأخيرة متزامنة"><b>الجولة على فترتين</b></UiToggle>
          <label v-if="staggered" class="flex items-center justify-between gap-3 rounded-lg bg-surface-sunk p-3 text-sm">الفترة الثانية بعد موعد الجولة بـ
            <select v-model.number="slotGap" class="h-touch rounded-md bg-surface px-2 font-bold">
              <option v-for="m in [60, 120, 180, 240, 300, 360]" :key="m" :value="m">{{ m / 60 }} {{ m === 60 ? 'ساعة' : m === 120 ? 'ساعتين' : 'ساعات' }}</option>
            </select>
          </label>
          <fieldset class="flex flex-col gap-2">
            <legend class="mb-1.5 text-sm font-bold">في نهاية الموسم</legend>
            <div class="grid gap-2 md:grid-cols-2">
              <label
                v-for="(label, mode) in END_MODES"
                :key="mode"
                class="flex min-h-touch cursor-pointer items-center gap-3 rounded-lg border p-3"
                :class="endMode === mode ? 'border-gold bg-surface-raised' : 'border-text/10'"
              >
                <input v-model="endMode" type="radio" name="end" :value="mode" class="size-5 accent-gold" />{{ label }}
              </label>
            </div>
          </fieldset>
        </section>
      </div>

      <aside class="flex h-fit flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4 lg:sticky lg:top-4" aria-labelledby="h-summary">
        <h2 id="h-summary" class="font-display text-xl font-extrabold">ملخص الموسم</h2>
        <dl class="flex flex-col divide-y divide-text/5 text-sm">
          <div class="flex justify-between py-2"><dt class="text-text-muted">جولات الدوري</dt><dd class="font-bold"><span class="font-numbers">{{ rounds }}</span> جولة</dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">منطقة القفل</dt><dd class="font-bold">من الجولة <span class="font-numbers">{{ lockFrom }}</span></dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">مقاعد المدربين</dt><dd class="font-bold"><span class="font-numbers">{{ teams }}</span> · مقعدك و<span class="font-numbers">{{ teams - 1 }}</span> لأصحابك</dd></div>
          <div class="flex justify-between py-2"><dt class="text-text-muted">الميزانية</dt><dd class="font-bold">{{ budget(startingBudget) }}</dd></div>
        </dl>
        <p class="text-xs text-text-muted">بعد الإنشاء تختار فريقك، وتحصل على كود تشاركه. الفرق الأخرى يديرها الحاسوب حتى ينضم أصحابك. ولا ينضم أحد في آخر ربع من الجولات.</p>
        <UiButton type="submit" block :disabled="!template">أنشئ الدوري واختر فريقك</UiButton>
      </aside>
    </form>

    <section v-else class="flex flex-col gap-3 pb-36 md:pb-0" aria-label="أندية الدوري">
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
      <div class="fixed inset-x-0 bottom-20 z-10 border-t border-text/10 bg-bg-deep/95 p-4 backdrop-blur md:static md:border-0 md:bg-transparent md:p-0">
        <UiButton block :disabled="!club || sending" @click="create">{{ club ? `أنشئ الدوري بـ${club.name}` : 'اختر فريقك' }}</UiButton>
      </div>
    </section>
  </div>
</template>
