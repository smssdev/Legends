<template>
  <div class="flex flex-col gap-5">

    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('مباراة في المحاكي') }}</h1>
      <p class="mt-1 text-text-muted">{{ $t('اختر ناديين حقيقيين، وحدد من يدير كل فريق، ثم شاهد المباراة وأدرها.') }}</p>
    </div>

    <div role="radiogroup" :aria-label="$t('نوع المباراة')" class="grid grid-cols-2 gap-3">
      <button v-for="m in modes" :key="m.v" type="button" role="radio" :aria-checked="settings.mode === m.v" class="flex min-h-20 flex-col items-start gap-1 rounded-xl border-2 p-4 text-start" :class="settings.mode === m.v ? 'border-gold bg-gold/10' : 'border-transparent bg-surface'" @click="m.v === 'live' ? router.push({ name: 'sim-room-new' }) : (settings.mode = m.v)">
        <span class="font-display text-lg font-extrabold" :class="settings.mode === m.v ? 'text-gold' : ''">{{ $t(m.label) }}</span>
        <span class="text-xs text-text-muted">{{ $t(m.hint) }}</span>
      </button>
    </div>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger">{{ $t(error) }}</p>

    <div class="grid gap-4 md:grid-cols-2">
      <section v-for="side in sides" :key="side" class="flex flex-col gap-3 rounded-xl bg-surface p-4" :aria-label="side === 'home' ? $t('الفريق الأول') : $t('الفريق الثاني')">
        <div class="flex items-center justify-between text-sm">
          <span class="font-bold text-gold">{{ side === 'home' ? $t('الفريق 1 · صاحب الأرض') : $t('الفريق 2 · الضيف') }}</span>
        </div>
        <div class="flex gap-2">
          <label class="sr-only" :for="`league-${side}`">{{ $t('الدوري') }}</label>
          <select :id="`league-${side}`" v-model="pick[side].league" class="h-touch flex-1 rounded-md border border-text/10 bg-surface-sunk px-3" @change="search(side)">
            <option value="">{{ $t('كل الدوريات') }}</option>
            <option v-for="l in leagues" :key="l.name" :value="l.name">{{ $nm(l.name) }} ({{ l.clubs }})</option>
          </select>
          <label class="sr-only" :for="`q-${side}`">{{ $t('ابحث عن نادٍ') }}</label>
          <input :id="`q-${side}`" v-model="pick[side].q" type="search" :placeholder="$t('ابحث عن نادٍ')" class="h-touch w-36 rounded-md border border-text/10 bg-surface-sunk px-3" @input="search(side)" />
        </div>
        <div class="flex max-h-44 flex-col gap-1 overflow-y-auto pe-1">
          <button
            v-for="c in pick[side].results"
            :key="c.id"
            type="button"
            class="flex min-h-touch items-center gap-3 rounded-md px-2 text-start"
            :class="pick[side].club?.id === c.id ? 'bg-gold/15 ring-1 ring-gold' : 'hover:bg-surface-raised'"
            @click="choose(side, c)"
          >
            <Crest :logo="c.logo" :code="c.code" :primary="clubColors(c).primary" :secondary="clubColors(c).secondary" :size="28" />
            <span class="flex-1 truncate font-semibold">{{ $nm(c.name) }}</span>
            <span class="text-xs text-text-muted">{{ $ln(c.league_name) }}</span>
            <span class="w-10 text-start font-numbers text-lg text-gold">{{ ((c.strength_cp ?? 0) / 100).toFixed(1) }}</span>
          </button>
        </div>

        <div v-if="pick[side].squad" class="flex flex-col gap-3 rounded-lg bg-surface-sunk p-3">
          <div class="flex items-center gap-3">
            <Crest :logo="pick[side].club!.logo" :code="pick[side].club!.code" :primary="clubColors(pick[side].club!).primary" :secondary="clubColors(pick[side].club!).secondary" :size="44" />
            <div class="flex-1">
              <div class="font-display text-xl font-extrabold">{{ $nm(pick[side].club!.name) }}</div>
              <div class="text-sm text-text-soft" dir="ltr">{{ pick[side].squad!.formation }}</div>
            </div>
            <span class="font-numbers text-3xl text-gold">{{ ((pick[side].club!.strength_cp ?? 0) / 100).toFixed(1) }}</span>
          </div>
          <div class="flex flex-wrap gap-1.5 text-xs text-text-soft">
            <span v-for="p in stars(side)" :key="p.id" class="rounded-sm bg-surface px-2 py-1">{{ $nm(p.name) }} <b class="font-numbers text-gold">{{ p.ovr }}</b></span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <div v-if="settings.mode === 'solo'" role="radiogroup" :aria-label="$t('من يدير {v0}', { v0: side === 'home' ? $t('الفريق الأول') : $t('الفريق الثاني') })" class="grid grid-cols-2 gap-1 rounded-md bg-surface-sunk p-1">
            <button v-for="c in controls" :key="c.v" type="button" role="radio" :aria-checked="pick[side].control === c.v" class="h-10 rounded-sm text-sm font-bold" :class="pick[side].control === c.v ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="pick[side].control = c.v">{{ $t(c.label) }}</button>
          </div>
          <label class="sr-only" :for="`plan-${side}`">{{ $t('خطة اللعب') }}</label>
          <select :id="`plan-${side}`" v-model="pick[side].plan" class="h-12 rounded-md border border-text/10 bg-surface-sunk px-3 text-sm">
            <option v-for="p in plans" :key="p.v" :value="p.v">{{ $t(p.label) }}</option>
          </select>
        </div>
      </section>
    </div>

    <section class="grid gap-4 rounded-xl bg-surface p-4 md:grid-cols-3" :aria-label="$t('إعدادات المباراة')">
      <div v-for="g in groups.filter((g) => settings.mode === 'solo' || g.key !== 'speed')" :key="g.key" class="flex flex-col gap-2">
        <span class="text-sm text-text-soft">{{ $t(g.label) }}</span>
        <div role="radiogroup" :aria-label="g.label" class="flex gap-1 rounded-md bg-surface-sunk p-1">
          <button v-for="o in g.options" :key="String(o.v)" type="button" role="radio" :aria-checked="settings[g.key] === o.v" class="h-touch flex-1 rounded-sm text-sm font-bold" :class="settings[g.key] === o.v ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="settings[g.key] = o.v">{{ $t(o.label) }}</button>
        </div>
      </div>
      <div class="flex flex-col gap-2">
        <label for="seed" class="text-sm text-text-soft">{{ $t('البذرة (نفس البذرة = نفس المباراة)') }}</label>
        <div class="flex gap-1">
          <input id="seed" v-model.number="settings.seed" type="number" min="1" dir="ltr" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers text-xl" />
          <button type="button" class="h-touch rounded-md bg-surface-raised px-3 text-sm" @click="settings.seed = Math.floor(Math.random() * 999999) + 1">{{ $t('عشوائية') }}</button>
        </div>
      </div>
    </section>

    <div class="sticky bottom-0 -mx-4 flex flex-wrap items-center gap-3 bg-bg/95 px-4 py-3 md:static md:mx-0 md:bg-transparent md:p-0">
      <button type="button" class="flex h-14 items-center gap-2 rounded-lg bg-gold px-8 font-display text-lg font-extrabold text-on-gold disabled:opacity-50" :disabled="!ready || busy" @click="start">
        {{ busy ? $t('جارٍ التجهيز...') : $t('ابدأ المباراة') }}
      </button>
      <span v-if="notReady" class="text-sm font-bold text-warning">{{ notReady }}</span>
      <span v-else class="text-sm text-text-muted">{{ settings.mode === 'live' ? $t('كل مدرب يدير فريقه من جهازه، والمباراة بسرعة ×1') : $t('حوالي 7 دقائق بسرعة ×1') }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Crest from '../components/Crest.vue'
import { clubColors, seats, sim, type Club, type Side } from '../api/sim'

const router = useRouter()
const sides: Side[] = ['home', 'away']
const leagues = ref<{ name: string; clubs: number }[]>([])
const error = ref('')
const busy = ref(false)
const controls = [{ v: 'me', label: 'أنا' }, { v: 'cpu', label: 'الحاسوب' }] as const
const plans = [
  { v: 'passing', label: 'تمريرات' }, { v: 'wings', label: 'الأجنحة' }, { v: 'counter', label: 'هجوم مرتد' },
  { v: 'long', label: 'كرات طويلة' }, { v: 'shots', label: 'تسديد من بعيد' },
]
const blank = () => ({ league: '', q: '', results: [] as Club[], club: null as Club | null, squad: null as any, control: 'cpu' as 'me' | 'cpu', plan: 'passing' })
const pick = reactive({ home: { ...blank(), control: 'me' as 'me' | 'cpu' }, away: blank() })
const settings = reactive<Record<string, any>>({ mode: 'solo', referee: 1, competition: 'league', venue: 'home', speed: 1, seed: Math.floor(Math.random() * 999999) + 1 })
const modes = [
  { v: 'solo', label: 'ضد الحاسوب', hint: 'على هذا الجهاز، مع السرعة والإيقاف والتخطي' },
  { v: 'live', label: 'ضد صديق', hint: 'غرفة: تكتب اسمك وتختار فريقك، وصديقك كذلك من جهازه' },
] as const
const groups = [
  { key: 'referee', label: 'الحكم', options: [{ v: 0, label: 'متساهل' }, { v: 1, label: 'متوسط' }, { v: 2, label: 'صارم' }] },
  { key: 'competition', label: 'المسابقة', options: [{ v: 'league', label: 'دوري' }, { v: 'cup', label: 'كأس' }] },
  { key: 'venue', label: 'الملعب', options: [{ v: 'home', label: 'أرض الفريق 1' }, { v: 'neutral', label: 'محايد' }] },
  { key: 'speed', label: 'السرعة', options: [{ v: 1, label: '×1' }, { v: 2, label: '×2' }, { v: 4, label: '×4' }] },
]
const ready = computed(() => pick.home.club && pick.away.club && pick.home.club.id !== pick.away.club.id)
const notReady = computed(() =>
  !pick.home.club || !pick.away.club ? 'اختر نادياً لكل فريق من القائمتين.' : pick.home.club.id === pick.away.club.id ? 'اختر ناديين مختلفين.' : '',
)

let timers: Record<Side, number> = { home: 0, away: 0 }
async function load(side: Side) {
  try {
    pick[side].results = await sim.clubs({ q: pick[side].q, league: pick[side].league })
  } catch (e: any) {
    error.value = e.message
  }
}
function search(side: Side) {
  clearTimeout(timers[side])
  timers[side] = window.setTimeout(() => load(side), 200)
}

async function choose(side: Side, club: Club) {
  pick[side].club = club
  pick[side].squad = null
  try {
    pick[side].squad = await sim.squad(club.id)
  } catch (e: any) {
    error.value = e.message
  }
}

function stars(side: Side) {
  const s = pick[side].squad
  if (!s) return []
  return s.players.filter((p: any) => s.starters.includes(p.id)).sort((a: any, b: any) => b.ovr - a.ovr).slice(0, 4)
}

async function start() {
  busy.value = true
  error.value = ''
  try {
    const match = await sim.create({
      home_id: pick.home.club!.id, away_id: pick.away.club!.id, seed: settings.seed, referee: settings.referee,
      competition: settings.competition, venue: settings.venue, mode: settings.mode,
      control: { home: pick.home.control, away: pick.away.control },
      home: { tactics: { plan: pick.home.plan } }, away: { tactics: { plan: pick.away.plan } },
    })
    // A live match: this device holds home; the away seat goes in the friend's link.
    if (match.seats) { seats.set(match.id, match.seats.home); seats.set(`${match.id}.friend`, match.seats.away) }
    router.push({ name: 'sim-match', params: { id: match.id }, query: settings.mode === 'live' ? {} : { speed: settings.speed } })
  } catch (e: any) {
    error.value = e.message
    busy.value = false
  }
}

onMounted(async () => {
  try {
    leagues.value = await sim.leagues()
    if (!leagues.value.length) error.value = 'لا توجد أندية في قاعدة البيانات. شغّل من مجلد backend: php artisan data:import'
    pick.home.league = leagues.value[0]?.name ?? ''
    pick.away.league = pick.home.league
    await Promise.all([load('home'), load('away')])
    // Start with the league's two strongest clubs so the match can begin at once.
    const [a, b] = pick.home.results
    await Promise.all([a && choose('home', a), b && choose('away', b)])
  } catch (e: any) {
    error.value = 'تعذر الاتصال بالـ API. شغّل composer dev من مجلد backend.'
  }
})
</script>
