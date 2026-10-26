<script setup lang="ts">
// The market (Sprint 24 W1), after the drafts WebMarket and MobileMarket: the pool and the bot clubs as tabs,
// filters, the players with their value and price, and my players to sell: at once for a fee, at their value, or
// at my own price up to their cap for a buyer from outside [X6]. Prices, caps and waits come from the API.
import { useGlossary } from '../../lib/glossary'
import HelpTip from '../../components/ui/HelpTip.vue'
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import Trades from './Trades.vue'
import { currentLeague } from '../../lib/currentLeague'
import { money, type Line } from '../../lib/format'

type Market = components['schemas']['Market']
// The "?" texts [X19].
const g = useGlossary()
const leagueId = ref<number | null>(null)
const m = ref<Market | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref<number | null>(null)
const route = useRoute()
type Tab = 'pool' | 'bots' | 'sell' | 'list' | 'offers'
const tab = ref<Tab>((['pool', 'bots', 'sell', 'list', 'offers'].includes(String(route.query.tab)) ? route.query.tab : 'pool') as Tab)
const line = ref<'' | Line>('')
const bot = ref<number | ''>('')
const maxPrice = ref<number | ''>('')
const q = ref('')
// The list or the cards, remembered on this device [X29].
const view = ref<'list' | 'cards'>((() => { try { return localStorage.getItem('legends.marketView') === 'cards' ? 'cards' : 'list' } catch { return 'list' } })())
function setView(v: 'list' | 'cards') {
  view.value = v
  try { localStorage.setItem('legends.marketView', v) } catch {}
}

const tabs = computed(() => [
  { id: 'pool' as const, label: 'المجموعة', n: m.value?.counts.pool ?? 0 },
  { id: 'bots' as const, label: 'أندية الحاسوب', n: m.value?.counts.bots ?? 0 },
  { id: 'sell' as const, label: 'بيع لاعبيّ', n: m.value?.mine.length ?? 0 },
  { id: 'list' as const, label: 'قائمة الانتقالات', n: null },
  { id: 'offers' as const, label: 'العروض', n: null },
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
    notice.value = kind === 'buy' ? `انضم ${name} إلى فريقك.` : `بِيع ${name} الآن بقيمته الكاملة.`
    await load()
    if (m.value) m.value.balance = data!.balance
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = null
}

// Selling [X6]: one open player at a time, with his price and the server's estimate of the wait.
type Mine = Market['mine'][number]
const open = ref<number | null>(null)
const price = ref<number | ''>('')
const quote = ref<{ ok: boolean; wait_hours: number } | null>(null)
let quoting = 0
function openSell(p: Mine) {
  open.value = open.value === p.id ? null : p.id
  price.value = p.listed?.price ?? p.value
  quote.value = { ok: true, wait_hours: p.wait_hours.value }
}
watch(price, (v) => {
  clearTimeout(quoting)
  if (!leagueId.value || !open.value || !v) return (quote.value = null)
  quoting = window.setTimeout(async () => {
    const { data } = await api.GET('/leagues/{league}/market/quote', { params: { path: { league: leagueId.value! }, query: { player_id: open.value!, price: Number(v) } } })
    quote.value = data ?? null
  }, 250)
})
async function listAt(p: Mine, at: number) {
  if (!leagueId.value) return
  busy.value = p.id
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/transfers/listings', { params: { path: { league: leagueId.value } }, body: { player_id: p.id, price: at } })
    notice.value = `عُرض ${p.name} للبيع بـ ${money(at)}. لو لم يشتره مدرب، يشتريه نادٍ من خارج الدوري في موعده.`
    open.value = null
    await load()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = null
}
async function unlist(p: Mine) {
  if (!leagueId.value) return
  busy.value = p.id
  try {
    await ensureCsrf()
    await api.DELETE('/leagues/{league}/transfers/listings/{player}', { params: { path: { league: leagueId.value, player: p.id } } })
    notice.value = `سُحب ${p.name} من البيع.`
    await load()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = null
}
const fee = (p: Mine) => (p.quick.fee.currency === 'coins' ? `${p.quick.fee.amount} كوينز` : `${money(p.quick.fee.amount)} من أموال النادي`)
const when = (iso: string | null) => (iso ? new Date(iso).toLocaleString('ar-EG', { weekday: 'long', hour: 'numeric', minute: '2-digit' }) : '')
const hours = (h: number) => (h <= 1 ? 'ساعة تقريباً' : h === 2 ? 'ساعتين تقريباً' : h <= 10 ? `${h} ساعات تقريباً` : `${h} ساعة تقريباً`)

let typing = 0
watch([tab, line, bot, maxPrice], () => tab.value !== 'list' && tab.value !== 'offers' && load())
watch(q, () => { clearTimeout(typing); typing = window.setTimeout(load, 300) })
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-center gap-3">
      <div class="flex-[1_1_240px]">
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">السوق</h1><HelpTip :text="g.pool" label="مجموعة السوق" /></span>
        <p class="mt-1 text-sm text-text-muted">
          <template v-if="m?.closed">{{ m.closed }}</template>
          <template v-else-if="m">مفتوح حتى الجولة {{ m.open_until_round }} · لاعبون جدد في المجموعة كل 4 ساعات، من كل الدوريات وبقوة دوريك</template>
        </p>
      </div>
      <RouterLink :to="{ name: 'scout' }" class="flex h-11 items-center gap-2 rounded-lg bg-gold/15 px-4 text-sm font-bold">اطلب تقرير الكشاف</RouterLink>
      <span v-if="m" class="money-box flex h-11 items-center gap-2 px-4 text-sm"><span class="text-text-muted">أموال النادي</span><b class="font-numbers text-lg" :class="m.balance < 0 ? 'text-warning' : ''" dir="ltr">{{ money(Math.abs(m.balance)) }}</b></span>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <template v-else-if="m">
      <div role="tablist" aria-label="مصادر اللاعبين" class="flex flex-wrap gap-1 self-start rounded-xl bg-surface p-1">
        <button v-for="t in tabs" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="flex h-11 items-center gap-2 rounded-lg px-4 text-sm font-semibold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">
          {{ t.label }}<span v-if="t.n !== null" class="min-w-6 rounded-pill px-1.5 font-numbers" :class="tab === t.id ? 'bg-on-gold/15' : 'bg-text/10'">{{ t.n }}</span>
        </button>
      </div>

      <Trades v-if="tab === 'list' || tab === 'offers'" :league-id="leagueId" :view="tab" :mine="m.mine" @changed="load" />

      <template v-else-if="tab !== 'sell'">
        <div class="flex flex-wrap items-center gap-2">
          <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">المركز
            <select v-model="line" class="h-8 bg-transparent font-semibold text-text"><option value="">الكل</option><option value="gk">حارس</option><option value="def">دفاع</option><option value="mid">وسط</option><option value="att">هجوم</option></select>
          </label>
          <label v-if="tab === 'bots'" class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">النادي
            <select v-model="bot" class="h-8 max-w-40 bg-transparent font-semibold text-text"><option value="">الكل</option><option v-for="b in m.bots" :key="b.id" :value="b.id">{{ $nm(b.name) }}</option></select>
          </label>
          <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">حتى
            <select v-model="maxPrice" class="h-8 bg-transparent font-semibold text-text"><option value="">أي سعر</option><option v-for="p in PRICES" :key="p" :value="p">{{ money(p) }}</option></select>
          </label>
          <input v-model="q" type="search" placeholder="ابحث بالاسم" aria-label="ابحث بالاسم" class="h-11 min-w-0 flex-[1_1_160px] rounded-lg bg-surface px-3 text-sm" />
          <span class="text-xs text-text-muted md:ms-auto">{{ tab === 'pool' ? 'سعر المجموعة = القيمة' : 'سعر ثابت 125% من القيمة · نفس السعر لكل المدربين' }}</span>
          <div class="flex gap-1 rounded-lg bg-surface p-1" role="group" aria-label="طريقة العرض">
            <button v-for="(label, v) in { list: 'قائمة', cards: 'بطاقات' }" :key="v" type="button" class="h-9 rounded-md px-3 text-sm font-bold" :class="view === v ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="view === v" @click="setView(v)">{{ label }}</button>
          </div>
        </div>

        <section :aria-label="tab === 'pool' ? 'لاعبو المجموعة' : 'لاعبو أندية الحاسوب'" class="rounded-xl bg-surface p-2">
          <p v-if="!m.players.length" class="p-4 text-sm text-text-muted">لا لاعبين بهذه التصفية.</p>
          <div v-if="view === 'cards'" class="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3 lg:grid-cols-4">
            <PlayerTile v-for="p in m.players" :key="p.id" :name="p.name" :line="p.line as Line" :position="p.position" :overall="p.overall" :value="p.value" :price="p.price"
              :attributes="p.attributes" :status="p.club ? `${p.club.name} · بوت` : `${p.age} سنة`" status-tone="text-text-muted">
              <button type="button" class="h-10 rounded-md bg-brand font-bold disabled:opacity-40" :disabled="!!m.closed || busy !== null || p.price > m.balance" @click="act('buy', p.id, p.name)">{{ busy === p.id ? '...' : 'شراء' }}</button>
            </PlayerTile>
          </div>
          <ul v-else class="flex flex-col">
            <li v-for="p in m.players" :key="p.id" class="flex items-center gap-2 border-t sm:gap-3 border-text/5 px-2 py-2 first:border-0">
              <LineBadge :line="p.line as Line" />
              <span class="min-w-0 flex-1">
                <b class="block truncate"><bdi>{{ $nm(p.name) }}</bdi></b>
                <span class="block text-xs text-text-muted">{{ p.position }} · {{ p.age }} سنة<template v-if="p.club"> · {{ $nm(p.club.name) }} · بوت</template></span>
              </span>
              <span class="w-8 text-center font-numbers text-lg sm:w-10 sm:text-xl" :class="p.overall >= 80 ? 'text-success' : p.overall >= 70 ? 'text-gold' : ''">{{ p.overall }}</span>
              <span class="hidden w-20 text-end font-numbers text-text-muted sm:block" dir="ltr">{{ money(p.value) }}</span>
              <span class="w-14 text-end font-numbers text-base font-bold sm:w-20 sm:text-lg" dir="ltr">{{ money(p.price) }}</span>
              <button type="button" class="h-touch min-w-14 rounded-md bg-brand px-2 font-bold sm:min-w-20 sm:px-3 disabled:opacity-40" :disabled="!!m.closed || busy !== null || p.price > m.balance" @click="act('buy', p.id, p.name)">{{ busy === p.id ? '...' : 'شراء' }}</button>
            </li>
          </ul>
        </section>
        <p v-if="tab === 'bots'" class="text-xs text-text-muted">البوت لا يبيع لو نزل فريقه عن 18 لاعباً أو حارسين.</p>
      </template>

      <section v-else aria-label="بيع لاعبيّ" class="flex flex-col gap-2 rounded-xl bg-surface p-2">
        <p class="px-2 pt-2 text-sm text-text-muted">بيع فوري بقيمة اللاعب الكاملة مقابل رسوم صغيرة، أو اعرضه بقيمته أو بسعرك حتى سقفه بلا رسوم: لو لم يشتره مدرب، يشتريه نادٍ من خارج الدوري، وكلما ارتفع السعر طال الانتظار. والتدريب يرفع قيمة اللاعب وسعره.</p>
        <ul class="flex flex-col">
          <li v-for="p in m.mine" :key="p.id" class="flex flex-col border-t border-text/5 px-2 py-2">
            <div class="flex items-center gap-3">
              <LineBadge :line="p.line as Line" />
              <span class="min-w-0 flex-1">
                <b class="block truncate" dir="auto">{{ $nm(p.name) }}</b>
                <span class="text-xs text-text-muted">{{ p.position }} · قيمته {{ money(p.value) }} · سقفه {{ money(p.cap) }}</span>
                <span v-if="p.listed" class="mt-1 block w-fit rounded-pill bg-gold/15 px-2 text-xs text-gold">معروض بـ <b dir="ltr" class="font-numbers">{{ money(p.listed.price) }}</b></span>
              </span>
              <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
              <button type="button" class="h-touch min-w-20 rounded-md border border-warning/60 px-3 font-bold text-warning disabled:opacity-40" :aria-expanded="open === p.id" :disabled="!!m.closed" @click="openSell(p)">بيع</button>
            </div>
            <div v-if="open === p.id" class="mt-2 flex flex-col gap-3 rounded-lg bg-surface-sunk p-3 text-sm">
              <div v-if="p.listed" class="flex flex-wrap items-center gap-2">
                <span>معروض بـ <b dir="ltr" class="font-numbers">{{ money(p.listed.price) }}</b><template v-if="p.listed.sells_at">، ويُباع {{ when(p.listed.sells_at) }} إن لم يشتره مدرب.</template></span>
                <button type="button" class="h-touch rounded-md bg-surface-raised px-3" :disabled="busy !== null" @click="unlist(p)">اسحبه من البيع</button>
              </div>
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span class="inline-flex flex-wrap items-center"><b>بيع فوري</b><HelpTip :text="g.quick_sale" label="البيع الفوري" /></span><span>: تحصل الآن على <b dir="ltr" class="font-numbers text-success">{{ money(p.quick.pays) }}</b> مقابل {{ fee(p) }}.</span>
                <button type="button" class="h-touch rounded-md bg-warning px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null" @click="act('sell', p.id, p.name)">{{ busy === p.id ? '...' : 'بع الآن' }}</button>
              </div>
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span><b>بقيمته</b> <b dir="ltr" class="font-numbers">{{ money(p.value) }}</b> بلا رسوم، ويُباع خلال {{ hours(p.wait_hours.value) }}.</span>
                <button type="button" class="h-touch rounded-md border border-gold/60 px-4 font-bold text-gold disabled:opacity-40" :disabled="busy !== null" @click="listAt(p, p.value)">اعرضه بقيمته</button>
                <HelpTip :text="g.listing" label="العرض في السوق" />
              </div>
              <form class="flex flex-wrap items-end gap-2" @submit.prevent="price && listAt(p, Number(price))">
                <label class="flex flex-col gap-1"><b>بسعرك</b> <span class="text-xs text-text-muted">من {{ money(p.floor) }} إلى {{ money(p.cap) }}</span>
                  <input v-model.number="price" type="number" inputmode="numeric" :min="p.floor" :max="p.cap" step="1000" class="h-touch w-40 rounded-md bg-surface px-2 font-numbers" dir="ltr" :aria-label="`سعر ${p.name}`" />
                </label>
                <button type="submit" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null || !quote?.ok">اعرضه بهذا السعر</button>
                <span v-if="quote" class="text-xs" :class="quote.ok ? 'text-text-muted' : 'text-[#FF8A8A]'">{{ quote.ok ? `يُباع خلال ${hours(quote.wait_hours)}` : 'خارج حدود سعره' }}</span>
              </form>
            </div>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>
