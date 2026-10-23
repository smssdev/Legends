<script setup lang="ts">
// The market (Sprint 24 W1), after the drafts WebMarket and MobileMarket: the pool and the bot clubs as tabs,
// filters, the players with their value and price, and my players to sell to the pool. Prices and every rule
// come from the API; offers between coaches join in Sprint 25.
import { computed, onMounted, ref, watch } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import { currentLeague } from '../../lib/currentLeague'
import { count, money, type Line } from '../../lib/format'

type Market = components['schemas']['Market']
const leagueId = ref<number | null>(null)
const m = ref<Market | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref<number | null>(null)
const tab = ref<'pool' | 'bots' | 'sell'>('pool')
const line = ref<'' | Line>('')
const bot = ref<number | ''>('')
const maxPrice = ref<number | ''>('')
const q = ref('')

const tabs = computed(() => [
  { id: 'pool' as const, label: 'المجموعة', n: m.value?.counts.pool ?? 0 },
  { id: 'bots' as const, label: 'أندية الحاسوب', n: m.value?.counts.bots ?? 0 },
  { id: 'sell' as const, label: 'بيع لاعبيّ', n: m.value?.mine.length ?? 0 },
])
const PRICES = [500_000, 1_000_000, 2_000_000, 5_000_000, 10_000_000]

async function load() {
  error.value = ''
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const query: Record<string, string | number> = { source: tab.value === 'bots' ? 'bots' : 'pool' }
      if (line.value) query.line = line.value
      if (bot.value && tab.value === 'bots') query.club = bot.value
      if (maxPrice.value) query.max_price = maxPrice.value
      if (q.value.trim()) query.q = q.value.trim()
      const { data } = await api.GET('/leagues/{league}/market', { params: { path: { league: leagueId.value }, query: query as any } })
      m.value = data!
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function act(kind: 'buy' | 'sell', id: number, name: string) {
  if (!leagueId.value) return
  busy.value = id
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const body = { player_id: id, idempotency_key: crypto.randomUUID() }
    const { data } = kind === 'buy'
      ? await api.POST('/leagues/{league}/market/buy', { params: { path: { league: leagueId.value } }, body })
      : await api.POST('/leagues/{league}/market/sell', { params: { path: { league: leagueId.value } }, body })
    notice.value = kind === 'buy' ? `انضم ${name} إلى فريقك.` : `بِيع ${name} للمجموعة.`
    await load()
    if (m.value) m.value.balance = data!.balance
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = null
}

let typing = 0
watch([tab, line, bot, maxPrice], () => load())
watch(q, () => { clearTimeout(typing); typing = window.setTimeout(load, 300) })
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-center gap-3">
      <div class="flex-[1_1_240px]">
        <h1 class="font-display text-3xl font-extrabold">السوق</h1>
        <p class="mt-1 text-sm text-text-muted">
          <template v-if="m?.closed">{{ m.closed }}</template>
          <template v-else-if="m">مفتوح حتى الجولة {{ m.open_until_round }} · تتجدد المجموعة في كل نافذة انتقالات</template>
        </p>
      </div>
      <span v-if="m" class="flex h-11 items-center gap-2 rounded-lg bg-surface px-4 text-sm"><span class="text-text-muted">أموال النادي</span><b class="font-numbers text-lg" :class="m.balance < 0 ? 'text-warning' : ''" dir="ltr">{{ money(Math.abs(m.balance)) }}</b></span>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <template v-else-if="m">
      <div role="tablist" aria-label="مصادر اللاعبين" class="flex flex-wrap gap-1 self-start rounded-xl bg-surface p-1">
        <button v-for="t in tabs" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="flex h-11 items-center gap-2 rounded-lg px-4 text-sm font-semibold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">
          {{ t.label }}<span class="min-w-6 rounded-pill px-1.5 font-numbers" :class="tab === t.id ? 'bg-on-gold/15' : 'bg-text/10'">{{ t.n }}</span>
        </button>
      </div>

      <template v-if="tab !== 'sell'">
        <div class="flex flex-wrap items-center gap-2">
          <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">المركز
            <select v-model="line" class="h-8 bg-transparent font-semibold text-text"><option value="">الكل</option><option value="gk">حارس</option><option value="def">دفاع</option><option value="mid">وسط</option><option value="att">هجوم</option></select>
          </label>
          <label v-if="tab === 'bots'" class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">النادي
            <select v-model="bot" class="h-8 max-w-40 bg-transparent font-semibold text-text"><option value="">الكل</option><option v-for="b in m.bots" :key="b.id" :value="b.id">{{ b.name }}</option></select>
          </label>
          <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">حتى
            <select v-model="maxPrice" class="h-8 bg-transparent font-semibold text-text"><option value="">أي سعر</option><option v-for="p in PRICES" :key="p" :value="p">{{ money(p) }}</option></select>
          </label>
          <input v-model="q" type="search" placeholder="ابحث بالاسم" aria-label="ابحث بالاسم" class="h-11 min-w-0 flex-[1_1_160px] rounded-lg bg-surface px-3 text-sm" />
          <span class="text-xs text-text-muted md:ms-auto">{{ tab === 'pool' ? 'سعر المجموعة = القيمة' : 'سعر ثابت 125% من القيمة · نفس السعر لكل المدربين' }}</span>
        </div>

        <section :aria-label="tab === 'pool' ? 'لاعبو المجموعة' : 'لاعبو أندية الحاسوب'" class="rounded-xl bg-surface p-2">
          <p v-if="!m.players.length" class="p-4 text-sm text-text-muted">لا لاعبين بهذه التصفية.</p>
          <ul class="flex flex-col">
            <li v-for="p in m.players" :key="p.id" class="flex items-center gap-3 border-t border-text/5 px-2 py-2 first:border-0">
              <LineBadge :line="p.line as Line" />
              <span class="min-w-0 flex-1">
                <b class="block truncate" dir="auto">{{ p.name }}</b>
                <span class="text-xs text-text-muted">{{ p.position }} · {{ p.age }} سنة<template v-if="p.club"> · {{ p.club.name }} · بوت</template></span>
              </span>
              <span class="w-10 text-center font-numbers text-xl" :class="p.overall >= 80 ? 'text-success' : p.overall >= 70 ? 'text-gold' : ''">{{ p.overall }}</span>
              <span class="hidden w-20 text-end font-numbers text-text-muted sm:block" dir="ltr">{{ money(p.value) }}</span>
              <span class="w-20 text-end font-numbers text-lg font-bold" dir="ltr">{{ money(p.price) }}</span>
              <button type="button" class="h-touch min-w-20 rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-40" :disabled="!!m.closed || busy !== null || p.price > m.balance" @click="act('buy', p.id, p.name)">{{ busy === p.id ? '...' : 'شراء' }}</button>
            </li>
          </ul>
        </section>
        <p v-if="tab === 'bots'" class="text-xs text-text-muted">البوت لا يبيع لو نزل فريقه عن 18 لاعباً أو حارسين.</p>
      </template>

      <section v-else aria-label="بيع لاعبيّ للمجموعة" class="flex flex-col gap-2 rounded-xl bg-surface p-2">
        <p class="px-2 pt-2 text-sm text-text-muted">المجموعة تشتري بـ 70% من القيمة الأصلية، بلا أثر التدريب. والبيع لمدرب آخر يأتي مع قائمة الانتقالات.</p>
        <ul class="flex flex-col">
          <li v-for="p in m.mine" :key="p.id" class="flex items-center gap-3 border-t border-text/5 px-2 py-2">
            <LineBadge :line="p.line as Line" />
            <span class="min-w-0 flex-1"><b class="block truncate" dir="auto">{{ p.name }}</b><span class="text-xs text-text-muted">{{ p.position }} · قيمته {{ money(p.value) }}</span></span>
            <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
            <span class="w-24 text-end font-numbers text-lg text-success" dir="ltr">+{{ count(p.pool_pays) }}</span>
            <button type="button" class="h-touch min-w-20 rounded-md border border-warning/60 px-3 font-bold text-warning disabled:opacity-40" :disabled="!!m.closed || busy !== null" @click="act('sell', p.id, p.name)">{{ busy === p.id ? '...' : 'بيع' }}</button>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>
