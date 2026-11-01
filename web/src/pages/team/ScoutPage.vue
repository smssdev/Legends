<script setup lang="ts">
// The scout (Sprint 26 W1, docs/features/scout.md): the criteria with the cost and the time, the search under
// way with its countdown, and the reports with their players to buy. No draft of its own: the market's table
// and the design system's cards; the market's header links here ("اطلب تقرير الكشاف").
import UiSelect from '../../components/ui/UiSelect.vue'
import { t } from '../../lib/i18n'
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { count, money, type Line } from '../../lib/format'

type View = components['schemas']['ScoutView']
// The "?" texts [X19].
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
const describe = (c: Record<string, any>) => [c.line && t(LINE_NAMES[c.line] ?? ''), c.position, t('قوة {v0}', { v0: `${c.min_overall}${c.max_overall ? '–' + c.max_overall : '+'}` }),
  c.max_age && t('حتى {v0} سنة', { v0: c.max_age }), c.max_value && t('حتى {v0}', { v0: money(c.max_value) }), c.nationality, c.league].filter(Boolean).join(' · ')

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
      <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">{{ $t('الكشاف') }}</h1></span>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ $t(notice) }}</p>
    <p v-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('ليس لديك فريق بعد.') }} <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink></p>

    <template v-else-if="v">
      <section v-if="searching" :aria-label="$t('الكشاف يبحث')" class="flex flex-wrap items-center gap-4 rounded-xl border border-gold/40 bg-surface p-4">
        <div class="flex-1"><b class="block">{{ $t('الكشاف يبحث') }}</b><span class="text-sm text-text-muted">{{ describe(searching.criteria) }}</span></div>
        <span class="font-numbers text-3xl text-gold" dir="ltr" aria-live="off">{{ left }}</span>
        <button v-if="wallet.open(leagueId)" type="button" class="flex h-touch items-center gap-1 rounded-md bg-gold/15 px-3 text-sm font-bold text-gold" :disabled="busy" @click="finish">
          {{ $t('أنهِ الآن ·') }} <PriceTag :amount="wallet.price('finish_scout')" currency="coins" /></button>
      </section>

      <section v-else :aria-label="$t('طلب جديد')" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('طلب جديد') }}</h2>
        <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <!-- [X61] Headless UI's Listbox and Combobox in place of the browser's selects. -->
          <div class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('الخط') }}
            <UiSelect v-model="form.line" label="الخط" none="أي خط" :options="Object.entries(LINE_NAMES).map(([k, n]) => ({ value: k, label: $t(n) }))" />
          </div>
          <div class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('المركز') }}
            <UiSelect v-model="form.position" label="المركز" none="أي مركز" ltr :options="v.options.positions.map((p) => ({ value: p, label: p }))" />
          </div>
          <div class="flex gap-2">
            <label class="flex flex-1 flex-col gap-1 text-sm text-text-muted">{{ $t('القوة من') }}<input v-model.number="form.min_overall" type="number" min="40" max="99" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
            <label class="flex flex-1 flex-col gap-1 text-sm text-text-muted">{{ $t('إلى') }}<input v-model.number="form.max_overall" type="number" min="40" max="99" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          </div>
          <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('أكبر عمر') }}<input v-model.number="form.max_age" type="number" min="16" max="45" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('أعلى سعر (اختياري)') }}<input v-model.number="form.max_value" type="number" min="1" step="100000" :placeholder="$t('بلا حد')" class="h-touch rounded-md bg-surface-sunk px-2 font-numbers text-text" dir="ltr" /></label>
          <div class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('الجنسية') }}
            <UiSelect v-model="form.nationality" label="الجنسية" none="أي جنسية" searchable :options="v.options.nationalities.map((n) => ({ value: n, label: $nm(n) }))" />
          </div>
          <div class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('من دوري') }}
            <UiSelect v-model="form.league" label="من دوري" none="أي دوري" searchable :options="v.options.leagues.map((l) => ({ value: l, label: l }))" />
          </div>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <button type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || v.balance < v.cost" @click="ask">{{ $t('اطلب التقرير ·') }} <span class="font-numbers" dir="ltr">{{ money(v.cost) }}</span></button>
          <span class="text-sm text-text-muted">{{ $t('رحلة {v0} ساعة، ثم 5 خيارات مطابقة لطلبك كرسالة، ولو لم يجد أحداً يُرد لك المبلغ.', { v0: v.hours }) }}</span>
        </div>
      </section>

      <section v-for="r in v.requests.filter((r) => r.status !== 'searching')" :key="r.id" :aria-label="$t('تقرير الكشاف')" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
        <div class="flex flex-wrap items-center gap-2 px-1"><b>{{ $t('تقرير') }}</b><span class="text-sm text-text-muted">{{ describe(r.criteria) }}</span><span class="ms-auto font-numbers text-sm text-text-muted" dir="ltr">−{{ count(r.cost) }}</span></div>
        <p v-if="r.status === 'empty'" class="px-1 text-sm text-text-muted">{{ $t('لم يجد أحداً بهذه المعايير، فرُد المبلغ.') }}</p>
        <div v-for="p in r.players" :key="p.id" class="flex items-center gap-3 rounded-lg bg-surface-sunk px-2 py-2">
          <LineBadge :line="p.line as Line" />
          <span class="min-w-0 flex-1"><b class="block truncate" dir="auto">{{ $nm(p.name) }}</b><span class="text-xs text-text-muted">{{ $t('{v0} · {v1} سنة · {v2} · إمكانية {v3}', { v0: p.position, v1: p.age, v2: $nm(p.nationality), v3: p.potential }) }}</span></span>
          <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
          <span class="w-20 text-end font-numbers text-lg" dir="ltr">{{ money(p.value) }}</span>
          <button v-if="p.state === 'available'" type="button" class="h-touch min-w-20 rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-40" :disabled="busy || (p.price ?? 0) > v.balance" @click="buy(p.id, p.name)">{{ $t('شراء') }}</button>
          <span v-else class="min-w-20 text-center text-sm text-text-muted">{{ p.state === 'mine' ? $t('في فريقك') : $t('ذهب') }}</span>
        </div>
      </section>
    </template>
  </div>
</template>
