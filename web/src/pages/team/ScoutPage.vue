<script setup lang="ts">
// The scout (Sprint 26 W1, docs/features/scout.md): the criteria with the cost and the time, the search under
// way with its countdown, and the reports with their players to buy. No draft of its own: the market's table
// and the design system's cards; the market's header links here ("اطلب تقرير الكشاف").
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { count, money, type Line } from '../../lib/format'

type View = components['schemas']['ScoutView']
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref(false)
const form = reactive({ line: 'att', position: '', min_overall: 70, max_overall: 85, max_age: 30, max_value: null as number | null, nationality: '', league: '' })
const now = ref(Date.now())
let tick = 0
const searching = computed(() => v.value?.requests.find((r) => r.status === 'searching'))
const left = computed(() => {
  if (!searching.value) return ''
  const s = Math.max(0, Math.floor((new Date(searching.value.finishes_at).getTime() - now.value) / 1000))
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
})
const LINE_NAMES: Record<string, string> = { gk: 'حارس', def: 'دفاع', mid: 'وسط', att: 'هجوم' }
const describe = (c: Record<string, any>) => [c.line && LINE_NAMES[c.line], c.position, `قوة ${c.min_overall}${c.max_overall ? '–' + c.max_overall : '+'}`,
  c.max_age && `حتى ${c.max_age} سنة`, c.max_value && `حتى ${money(c.max_value)}`, c.nationality, c.league].filter(Boolean).join(' · ')

async function load() {
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/scout', { params: { path: { league: leagueId.value } } })
      v.value = data!
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function ask() {
  if (!leagueId.value) return
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const body: Record<string, unknown> = { min_overall: form.min_overall, max_overall: form.max_overall, max_age: form.max_age, idempotency_key: crypto.randomUUID() }
    for (const k of ['line', 'position', 'nationality', 'league'] as const) if (form[k]) body[k] = form[k]
    if (form.max_value) body.max_value = form.max_value
    const { data } = await api.POST('/leagues/{league}/scout', { params: { path: { league: leagueId.value } }, body: body as any })
    v.value = data!
    notice.value = 'انطلق الكشاف. يصلك تقريره كرسالة في موعده.'
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

// Finish the search now for coins [Sprint 34].
const wallet = useWallet()
async function finish() {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    v.value = (await api.POST('/leagues/{league}/scout/finish', { params: { path: { league: leagueId.value! } } })).data as any
    await load()
    wallet.load()
    notice.value = 'وصل تقرير الكشاف.'
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

async function buy(id: number, name: string) {
  if (!leagueId.value) return
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/market/buy', { params: { path: { league: leagueId.value } }, body: { player_id: id, idempotency_key: crypto.randomUUID() } })
    notice.value = `انضم ${name} إلى فريقك.`
    await load()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

onMounted(() => {
  load()
  tick = window.setInterval(() => {
    now.value = Date.now()
    if (searching.value && new Date(searching.value.finishes_at).getTime() <= now.value + 1000) load()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(tick))
</script>

<template>
  <div class="flex flex-col gap-4">
    <header>
      <h1 class="font-display text-3xl font-extrabold">الكشاف</h1>
      <p class="mt-1 text-sm text-text-muted">يبحث لك عن لاعبين من خارج أندية الدوري، وتشتريهم وحدك بسعر المجموعة حتى تتجدد</p>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <template v-else-if="v">
      <section v-if="searching" aria-label="الكشاف يبحث" class="flex flex-wrap items-center gap-4 rounded-xl border border-gold/40 bg-surface p-4">
        <div class="flex-1"><b class="block">الكشاف يبحث</b><span class="text-sm text-text-muted">{{ describe(searching.criteria) }}</span></div>
        <span class="font-numbers text-3xl text-gold" dir="ltr" aria-live="off">{{ left }}</span>
        <button v-if="wallet.open(leagueId)" type="button" class="flex h-touch items-center gap-1 rounded-md bg-gold/15 px-3 text-sm font-bold text-gold" :disabled="busy" @click="finish">
          أنهِ الآن · <PriceTag :amount="wallet.price('finish_scout')" currency="coins" /></button>
      </section>

      <section v-else aria-label="طلب جديد" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">طلب جديد</h2>
        <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <label class="flex flex-col gap-1 text-sm text-text-muted">الخط
            <select v-model="form.line" class="h-touch rounded-md bg-surface-sunk px-2 text-text"><option value="">أي خط</option><option v-for="(n, k) in LINE_NAMES" :key="k" :value="k">{{ n }}</option></select>
          </label>
          <label class="flex flex-col gap-1 text-sm text-text-muted">المركز
            <select v-model="form.position" class="h-touch rounded-md bg-surface-sunk px-2 text-text" dir="ltr"><option value="">أي مركز</option><option v-for="p in v.options.positions" :key="p" :value="p">{{ p }}</option></select>
          </label>
          <div class="flex gap-2">
            <label class="flex flex-1 flex-col gap-1 text-sm text-text-muted">القوة من<input v-model.number="form.min_overall" type="number" min="40" max="99" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
            <label class="flex flex-1 flex-col gap-1 text-sm text-text-muted">إلى<input v-model.number="form.max_overall" type="number" min="40" max="99" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          </div>
          <label class="flex flex-col gap-1 text-sm text-text-muted">أكبر عمر<input v-model.number="form.max_age" type="number" min="16" max="45" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          <label class="flex flex-col gap-1 text-sm text-text-muted">أعلى سعر (اختياري)<input v-model.number="form.max_value" type="number" min="1" step="100000" placeholder="بلا حد" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          <label class="flex flex-col gap-1 text-sm text-text-muted">الجنسية
            <select v-model="form.nationality" class="h-touch rounded-md bg-surface-sunk px-2 text-text"><option value="">أي جنسية</option><option v-for="n in v.options.nationalities" :key="n" :value="n">{{ n }}</option></select>
          </label>
          <label class="flex flex-col gap-1 text-sm text-text-muted">من دوري
            <select v-model="form.league" class="h-touch rounded-md bg-surface-sunk px-2 text-text"><option value="">أي دوري</option><option v-for="l in v.options.leagues" :key="l" :value="l">{{ l }}</option></select>
          </label>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <button type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || v.balance < v.cost" @click="ask">اطلب التقرير · <span class="font-numbers" dir="ltr">{{ money(v.cost) }}</span></button>
          <span class="text-sm text-text-muted">رحلة {{ v.hours }} ساعة، ثم 5 خيارات مطابقة لطلبك كرسالة، ولو لم يجد أحداً يُرد لك المبلغ.</span>
        </div>
      </section>

      <section v-for="r in v.requests.filter((r) => r.status !== 'searching')" :key="r.id" aria-label="تقرير الكشاف" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
        <div class="flex flex-wrap items-center gap-2 px-1"><b>تقرير</b><span class="text-sm text-text-muted">{{ describe(r.criteria) }}</span><span class="ms-auto font-numbers text-sm text-text-muted" dir="ltr">−{{ count(r.cost) }}</span></div>
        <p v-if="r.status === 'empty'" class="px-1 text-sm text-text-muted">لم يجد أحداً بهذه المعايير، فرُد المبلغ.</p>
        <div v-for="p in r.players" :key="p.id" class="flex items-center gap-3 rounded-lg bg-surface-sunk px-2 py-2">
          <LineBadge :line="p.line as Line" />
          <span class="min-w-0 flex-1"><b class="block truncate" dir="auto">{{ p.name }}</b><span class="text-xs text-text-muted">{{ p.position }} · {{ p.age }} سنة · {{ p.nationality }} · إمكانية {{ p.potential }}</span></span>
          <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
          <span class="w-20 text-end font-numbers text-lg" dir="ltr">{{ money(p.value) }}</span>
          <button v-if="p.state === 'available'" type="button" class="h-touch min-w-20 rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-40" :disabled="busy || (p.price ?? 0) > v.balance" @click="buy(p.id, p.name)">شراء</button>
          <span v-else class="min-w-20 text-center text-sm text-text-muted">{{ p.state === 'mine' ? 'في فريقك' : 'ذهب' }}</span>
        </div>
      </section>
    </template>
  </div>
</template>
