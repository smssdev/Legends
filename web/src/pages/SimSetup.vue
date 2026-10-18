<template>
  <main class="mx-auto flex min-h-dvh max-w-6xl flex-col gap-5 px-4 py-5 md:px-6">
    <header class="flex flex-wrap items-center gap-3">
      <img src="/icon-192.png" alt="" class="size-10 rounded-md" />
      <span class="font-display text-xl font-extrabold tracking-wide text-gold" dir="ltr">LEGENDS</span>
      <span class="rounded-pill bg-gold/15 px-3 py-1 text-sm font-bold text-gold">المحاكي</span>
    </header>

    <div>
      <h1 class="font-display text-3xl font-extrabold">مباراة في المحاكي</h1>
      <p class="mt-1 text-text-muted">اختر ناديين حقيقيين، وحدد من يدير كل فريق، ثم شاهد المباراة وأدرها.</p>
    </div>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]">{{ error }}</p>

    <div class="grid gap-4 md:grid-cols-2">
      <section v-for="side in sides" :key="side" class="flex flex-col gap-3 rounded-xl bg-surface p-4" :aria-label="side === 'home' ? 'الفريق الأول' : 'الفريق الثاني'">
        <div class="flex items-center justify-between text-sm">
          <span class="font-bold text-gold">{{ side === 'home' ? 'الفريق 1 · صاحب الأرض' : 'الفريق 2 · الضيف' }}</span>
        </div>
        <div class="flex gap-2">
          <label class="sr-only" :for="`league-${side}`">الدوري</label>
          <select :id="`league-${side}`" v-model="pick[side].league" class="h-touch flex-1 rounded-md border border-text/10 bg-surface-sunk px-3" @change="search(side)">
            <option value="">كل الدوريات</option>
            <option v-for="l in leagues" :key="l.name" :value="l.name">{{ l.name }} ({{ l.clubs }})</option>
          </select>
          <label class="sr-only" :for="`q-${side}`">ابحث عن نادٍ</label>
          <input :id="`q-${side}`" v-model="pick[side].q" type="search" placeholder="ابحث عن نادٍ" class="h-touch w-36 rounded-md border border-text/10 bg-surface-sunk px-3" @input="search(side)" />
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
            <Crest :code="c.code" :primary="clubColors(c).primary" :secondary="clubColors(c).secondary" :size="28" />
            <span class="flex-1 truncate font-semibold">{{ c.name }}</span>
            <span class="text-xs text-text-muted">{{ c.league_name }}</span>
            <span class="w-10 text-start font-numbers text-lg text-gold">{{ ((c.strength_cp ?? 0) / 100).toFixed(1) }}</span>
          </button>
        </div>

        <div v-if="pick[side].squad" class="flex flex-col gap-3 rounded-lg bg-surface-sunk p-3">
          <div class="flex items-center gap-3">
            <Crest :code="pick[side].club!.code" :primary="clubColors(pick[side].club!).primary" :secondary="clubColors(pick[side].club!).secondary" :size="44" />
            <div class="flex-1">
              <div class="font-display text-xl font-extrabold">{{ pick[side].club!.name }}</div>
              <div class="text-sm text-text-soft" dir="ltr">{{ pick[side].squad!.formation }}</div>
            </div>
            <span class="font-numbers text-3xl text-gold">{{ ((pick[side].club!.strength_cp ?? 0) / 100).toFixed(1) }}</span>
          </div>
          <div class="flex flex-wrap gap-1.5 text-xs text-text-soft">
            <span v-for="p in stars(side)" :key="p.id" class="rounded-sm bg-surface px-2 py-1">{{ p.name }} <b class="font-numbers text-gold">{{ p.ovr }}</b></span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <div v-if="settings.mode === 'solo'" role="radiogroup" :aria-label="`من يدير ${side === 'home' ? 'الفريق الأول' : 'الفريق الثاني'}`" class="grid grid-cols-2 gap-1 rounded-md bg-surface-sunk p-1">
            <button v-for="c in controls" :key="c.v" type="button" role="radio" :aria-checked="pick[side].control === c.v" class="h-10 rounded-sm text-sm font-bold" :class="pick[side].control === c.v ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="pick[side].control = c.v">{{ c.label }}</button>
          </div>
          <label class="sr-only" :for="`plan-${side}`">خطة اللعب</label>
          <select :id="`plan-${side}`" v-model="pick[side].plan" class="h-12 rounded-md border border-text/10 bg-surface-sunk px-3 text-sm">
            <option v-for="p in plans" :key="p.v" :value="p.v">{{ p.label }}</option>
          </select>
        </div>
      </section>
    </div>

    <section class="grid gap-4 rounded-xl bg-surface p-4 md:grid-cols-3" aria-label="إعدادات المباراة">
      <div v-for="g in groups" :key="g.key" class="flex flex-col gap-2">
        <span class="text-sm text-text-soft">{{ g.label }}</span>
        <div role="radiogroup" :aria-label="g.label" class="flex gap-1 rounded-md bg-surface-sunk p-1">
          <button v-for="o in g.options" :key="String(o.v)" type="button" role="radio" :aria-checked="settings[g.key] === o.v" class="h-touch flex-1 rounded-sm text-sm font-bold" :class="settings[g.key] === o.v ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="settings[g.key] = o.v">{{ o.label }}</button>
        </div>
      </div>
      <div class="flex flex-col gap-2">
        <label for="seed" class="text-sm text-text-soft">البذرة (نفس البذرة = نفس المباراة)</label>
        <div class="flex gap-1">
          <input id="seed" v-model.number="settings.seed" type="number" min="1" dir="ltr" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers text-xl" />
          <button type="button" class="h-touch rounded-md bg-surface-raised px-3 text-sm" @click="settings.seed = Math.floor(Math.random() * 999999) + 1">عشوائية</button>
        </div>
      </div>
    </section>

    <div class="flex flex-wrap items-center gap-3">
      <button type="button" class="flex h-14 items-center gap-2 rounded-lg bg-gold px-8 font-display text-lg font-extrabold text-on-gold disabled:opacity-50" :disabled="!ready || busy" @click="start">
        {{ busy ? 'جارٍ التجهيز...' : 'ابدأ المباراة' }}
      </button>
      <span class="text-sm text-text-muted">{{ settings.mode === 'live' ? 'كل مدرب يدير فريقه من جهازه، والمباراة بسرعة ×1' : 'حوالي 5 دقائق بسرعة ×1' }}</span>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Crest from '../components/Crest.vue'
import { clubColors, sim, type Club, type Side } from '../api/sim'

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
const groups = [
  { key: 'mode', label: 'طريقة اللعب', options: [{ v: 'solo', label: 'هذا الجهاز' }, { v: 'live', label: 'مع صديق' }] },
  { key: 'referee', label: 'الحكم', options: [{ v: 0, label: 'متساهل' }, { v: 1, label: 'متوسط' }, { v: 2, label: 'صارم' }] },
  { key: 'competition', label: 'المسابقة', options: [{ v: 'league', label: 'دوري' }, { v: 'cup', label: 'كأس' }] },
  { key: 'venue', label: 'الملعب', options: [{ v: 'home', label: 'أرض الفريق 1' }, { v: 'neutral', label: 'محايد' }] },
  { key: 'speed', label: 'السرعة', options: [{ v: 1, label: '×1' }, { v: 2, label: '×2' }, { v: 4, label: '×4' }] },
]
const ready = computed(() => pick.home.club && pick.away.club && pick.home.club.id !== pick.away.club.id)

let timers: Record<Side, number> = { home: 0, away: 0 }
function search(side: Side) {
  clearTimeout(timers[side])
  timers[side] = window.setTimeout(async () => {
    try {
      pick[side].results = await sim.clubs({ q: pick[side].q, league: pick[side].league })
    } catch (e: any) {
      error.value = e.message
    }
  }, 200)
}

async function choose(side: Side, club: Club) {
  pick[side].club = club
  pick[side].squad = await sim.squad(club.id)
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
    router.push({ name: 'sim-match', params: { id: match.id }, query: settings.mode === 'live' ? { side: 'home' } : { speed: settings.speed } })
  } catch (e: any) {
    error.value = e.message
    busy.value = false
  }
}

onMounted(async () => {
  try {
    leagues.value = await sim.leagues()
    pick.home.league = leagues.value[0]?.name ?? ''
    pick.away.league = pick.home.league
    await Promise.all([search('home'), search('away')])
    window.setTimeout(async () => {
      const [a, b] = pick.home.results
      if (a) await choose('home', a)
      if (b) await choose('away', b)
    }, 450)
  } catch (e: any) {
    error.value = 'تعذر الاتصال بالـ API. شغّل composer dev من مجلد backend.'
  }
})
</script>
