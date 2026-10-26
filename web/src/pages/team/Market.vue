<script setup lang="ts">
// The market (Sprint 24 W1, [UP11] the owner's spec 5): four sections (the transfer list, the negotiations, the scout,
// the transfers made) and my players to sell. The list is one per line (GK, DEF, MID, ATT, no search), renewed every
// few hours with a countdown, each player with his seller: a club and its coach, a computer's club, or his own club
// outside the league. A tap opens his card and the deal: the price and 1 or 2 coins to register it, or, short of cash
// with half the price at least, the cash and coins for the rest. Prices and rules come from the API.
import { useGlossary } from '../../lib/glossary'
import HelpTip from '../../components/ui/HelpTip.vue'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import Trades from './Trades.vue'
import ScoutPage from './ScoutPage.vue'
import { useWallet } from '../../stores/wallet'
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
type Tab = 'list' | 'offers' | 'scout' | 'done' | 'sell'
const tab = ref<Tab>((['list', 'offers', 'scout', 'done', 'sell'].includes(String(route.query.tab)) ? route.query.tab : 'list') as Tab)
const line = ref<Line>('gk')
const wallet = useWallet()
const tabs = computed(() => [
  { id: 'list' as const, label: 'قائمة الانتقالات', n: null },
  { id: 'offers' as const, label: 'المفاوضات', n: null },
  { id: 'scout' as const, label: 'الكشاف', n: null },
  { id: 'done' as const, label: 'الانتقالات التي تمت', n: null },
  { id: 'sell' as const, label: 'بيع لاعبيّ', n: m.value?.mine.length ?? 0 },
])
const LINES: { id: Line; label: string }[] = [{ id: 'gk', label: 'حراس المرمى GK' }, { id: 'def', label: 'المدافعون DEF' }, { id: 'mid', label: 'لاعبو الوسط MID' }, { id: 'att', label: 'المهاجمون ATT' }]

// [UP11] The transfer list of one line, its renewal countdown, a player's deal and the celebration.
type Seller = { kind: 'world' | 'bot' | 'coach'; club_id: number | null; club: string | null; coach: string | null; logo: string | null }
type Row = Market['players'][number] & { seller: Seller }
type ListView = { closed: string | null; line: Line; balance: number; renews_at: string | null; players: Row[] }
type Quote = { price: number; cash: number; doc_coins: number; short: number; compensate: { cash: number; coins: number } | null; can: boolean; why: string | null }
const list = ref<ListView | null>(null)
const now = ref(Date.now())
const renewsIn = computed(() => {
  const s = list.value?.renews_at ? Math.max(0, Math.floor((new Date(list.value.renews_at).getTime() - now.value) / 1000)) : 0
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
})
const picked = ref<Row | null>(null)
const deal = ref<Quote | null>(null)
const celebrate = ref('')
const done = ref<{ player: string; from: string | null; to: string; price: number; at: string }[]>([])
async function loadList() {
  if (!leagueId.value) return
  const { data } = await api.GET('/leagues/{league}/market', { params: { path: { league: leagueId.value }, query: { source: 'list', line: line.value } as any } })
  list.value = data as unknown as ListView
}
async function pick(p: Row) {
  picked.value = p
  deal.value = null
  if (p.seller.kind === 'coach' || !leagueId.value) return
  try {
    deal.value = (await api.GET('/leagues/{league}/market/buy-quote', { params: { path: { league: leagueId.value }, query: { player_id: p.id } } })).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
}
async function buy(compensate: boolean) {
  const p = picked.value
  if (!p || !leagueId.value) return
  busy.value = p.id
  error.value = ''
  try {
    await ensureCsrf()
    if (p.seller.kind === 'coach') {
      // A coach's listed player: an offer at his price, for his coach to accept (the negotiations).
      await api.POST('/leagues/{league}/transfers/offers', { params: { path: { league: leagueId.value } },
        body: { to_club_id: p.seller.club_id!, money: p.price, in: [p.id], idempotency_key: crypto.randomUUID() } as any })
      notice.value = `أُرسل عرضك لمدرب ${p.seller.club}. تابعه في المفاوضات.`
    } else {
      await api.POST('/leagues/{league}/market/buy', { params: { path: { league: leagueId.value } }, body: { player_id: p.id, idempotency_key: crypto.randomUUID(), compensate } })
      celebrate.value = p.name
      void wallet.load()
    }
    picked.value = null
    await Promise.all([load(), loadList()])
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = null
}
async function loadDone() {
  if (leagueId.value) done.value = (await api.GET('/leagues/{league}/market/done', { params: { path: { league: leagueId.value } } })).data!.transfers
}

async function load() {
  error.value = ''
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      // My players to sell, the balance and the season's limits.
      const { data } = await api.GET('/leagues/{league}/market', { params: { path: { league: leagueId.value }, query: { source: 'pool', line: 'gk' } as any } })
      m.value = data!
      if (tab.value === 'list') await loadList()
      if (tab.value === 'done') await loadDone()
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

watch(line, () => loadList())
watch(tab, (t) => { if (t === 'list') void loadList(); if (t === 'done') void loadDone() })
let clock = 0
onMounted(() => { void load(); clock = window.setInterval(() => { now.value = Date.now(); if (list.value?.renews_at && new Date(list.value.renews_at).getTime() <= now.value - 3000 && tab.value === 'list') { list.value.renews_at = null; void loadList() } }, 1000) })
onBeforeUnmount(() => clearInterval(clock))
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-center gap-3">
      <div class="flex-[1_1_240px]">
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">{{ $t('السوق') }}</h1><HelpTip :text="g.pool" :label="$t('مجموعة السوق')" /></span>
        <p class="mt-1 text-sm text-text-muted">
          <template v-if="m?.closed">{{ m.closed }}</template>
          <template v-else-if="m">{{ $t('مفتوح حتى الجولة {v0} · صفقات جديدة كل بضع ساعات، من كل الدوريات وبقوة دوريك', { v0: m.open_until_round }) }}</template>
        </p>
      </div>
      <span v-if="m" class="money-box flex h-11 items-center gap-2 px-4 text-sm"><span class="text-text-muted">{{ $t('أموال النادي') }}</span><b class="font-numbers text-lg" :class="m.balance < 0 ? 'text-warning' : ''" dir="ltr">{{ money(Math.abs(m.balance)) }}</b></span>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ $t(notice) }}</p>
    <p v-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('ليس لديك فريق بعد.') }} <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink></p>

    <template v-else-if="m">
      <div role="tablist" :aria-label="$t('مصادر اللاعبين')" class="flex flex-wrap gap-1 self-start rounded-xl bg-surface p-1">
        <button v-for="t in tabs" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="flex h-11 items-center gap-2 rounded-lg px-4 text-sm font-semibold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">
          {{ $t(t.label) }}<span v-if="t.n !== null" class="min-w-6 rounded-pill px-1.5 font-numbers" :class="tab === t.id ? 'bg-on-gold/15' : 'bg-text/10'">{{ t.n }}</span>
        </button>
      </div>

      <Trades v-if="tab === 'offers'" :league-id="leagueId" view="offers" :mine="m.mine" @changed="load" />
      <ScoutPage v-else-if="tab === 'scout'" />

      <section v-else-if="tab === 'done'" :aria-label="$t('الانتقالات التي تمت')" class="rounded-xl bg-surface p-2">
        <p v-if="!done.length" class="p-4 text-sm text-text-muted">{{ $t('لا انتقالات بعد هذا الموسم.') }}</p>
        <ul class="flex flex-col">
          <li v-for="(t, i) in done" :key="i" class="v-row flex flex-wrap items-center gap-2 border-t border-text/5 px-2 py-2 text-sm first:border-0">
            <b class="min-w-0 flex-1 truncate"><bdi>{{ $nm(t.player) }}</bdi></b>
            <span class="text-text-muted">{{ t.from ? $nm(t.from) : $t('من خارج الدوري') }} ← <b class="text-text">{{ $nm(t.to) }}</b></span>
            <span class="w-20 text-end font-numbers font-bold" dir="ltr">{{ money(t.price) }}</span>
          </li>
        </ul>
      </section>

      <template v-else-if="tab === 'list'">
        <div class="flex flex-wrap items-center gap-2">
          <div role="tablist" :aria-label="$t('المراكز')" class="grid flex-1 grid-cols-4 gap-1 rounded-xl bg-surface p-1">
            <button v-for="l in LINES" :key="l.id" type="button" role="tab" :aria-selected="line === l.id" class="min-h-touch rounded-lg px-2 text-xs font-bold sm:text-sm" :class="line === l.id ? 'bg-brand text-white' : 'text-text-soft'" @click="line = l.id">{{ $t(l.label) }}</button>
          </div>
          <span v-if="list?.renews_at" class="flex h-11 items-center gap-2 rounded-lg border border-gold/40 bg-surface px-3 text-sm">{{ $t('الصفقات التالية بعد') }} <b class="font-numbers text-lg text-gold" dir="ltr">{{ renewsIn }}</b></span>
        </div>
        <section :aria-label="$t('قائمة الانتقالات')" class="rounded-xl bg-surface p-2">
          <p v-if="!list" class="p-4 text-sm text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
          <p v-else-if="!list.players.length" class="p-4 text-sm text-text-muted">{{ $t('لا لاعبين في هذا المركز الآن.') }}</p>
          <ul v-else class="flex flex-col">
            <li v-for="p in list.players" :key="p.id" class="v-row">
              <button type="button" class="flex w-full items-center gap-2 border-t border-text/5 px-2 py-2 text-start transition-transform first:border-0 hover:bg-surface-raised sm:gap-3" @click="pick(p)">
                <span class="w-8 text-center font-numbers text-lg sm:w-10 sm:text-xl" :class="p.overall >= 80 ? 'text-success' : p.overall >= 70 ? 'text-gold' : ''">{{ p.overall }}</span>
                <span class="min-w-0 flex-1">
                  <b class="block truncate"><bdi>{{ $nm(p.name) }}</bdi></b>
                  <span class="block text-xs text-text-muted">{{ $t('{v0} · {v1} سنة', { v0: p.position, v1: p.age }) }}<template v-if="p.nationality"> · {{ p.nationality }}</template></span>
                </span>
                <span class="hidden min-w-0 max-w-48 items-center gap-1.5 text-xs sm:flex">
                  <img v-if="p.seller.logo" :src="p.seller.logo" alt="" class="size-6 object-contain" loading="lazy" />
                  <span class="min-w-0"><span class="block truncate">{{ p.seller.club ? $nm(p.seller.club) : '' }}</span><span v-if="p.seller.coach" class="block truncate text-brand-light">{{ p.seller.coach }}</span></span>
                </span>
                <span class="w-16 text-end font-numbers text-base font-bold sm:w-20 sm:text-lg" dir="ltr">{{ money(p.price) }}</span>
              </button>
            </li>
          </ul>
        </section>
      </template>

      <!-- The player's card and the deal. -->
      <div v-if="picked" class="fixed inset-0 z-40 flex items-end justify-center bg-bg-deep/80 p-3 sm:items-center" role="dialog" aria-modal="true" :aria-label="$t('شراء {v0}', { v0: picked.name })" @click.self="picked = null">
        <div class="flex w-full max-w-md flex-col gap-3 rounded-2xl border border-gold/30 bg-surface p-4">
          <PlayerTile :name="picked.name" :line="picked.line as Line" :position="picked.position" :overall="picked.overall" :value="picked.value" :price="picked.price"
            :attributes="picked.attributes" :status="$t('{v0} سنة · {v1}{v2}', { v0: picked.age, v1: picked.seller.club ? $nm(picked.seller.club) : '', v2: picked.seller.coach ? ' · ' + picked.seller.coach : '' })" status-tone="text-text-muted" />
          <template v-if="picked.seller.kind === 'coach'">
            <p class="text-sm text-text-muted">{{ $t('لاعب معروض من مدرب: يُرسل عرض بسعره، ويقبله مدربه أو يرده.') }}</p>
            <button type="button" class="h-12 rounded-lg bg-gold font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null || !!list?.closed" @click="buy(false)">{{ $t('قدّم عرضاً بـ') }} <span dir="ltr" class="font-numbers">{{ money(picked.price) }}</span></button>
          </template>
          <template v-else-if="deal">
            <dl class="flex flex-col divide-y divide-text/5 text-sm">
              <div class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('قيمة الصفقة') }}</dt><dd dir="ltr" class="font-numbers font-bold">{{ money(deal.price) }}</dd></div>
              <div class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('أموال ناديك') }}</dt><dd dir="ltr" class="font-numbers">{{ money(deal.cash) }}</dd></div>
              <div v-if="deal.doc_coins" class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('توثيق الصفقة') }}</dt><dd><img src="/brand/coin.svg" alt="" class="inline size-4" /> <span class="font-numbers">{{ deal.doc_coins }}</span></dd></div>
            </dl>
            <p v-if="deal.why" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="alert">{{ deal.why }}</p>
            <button v-if="!deal.short" type="button" class="h-12 rounded-lg bg-brand font-bold text-white disabled:opacity-40" :disabled="busy !== null || !!list?.closed" @click="buy(false)">
              {{ $t('شراء ·') }} <span dir="ltr" class="font-numbers">{{ money(deal.price) }}</span><template v-if="deal.doc_coins"> + <img src="/brand/coin.svg" alt="" class="inline size-4" /> {{ deal.doc_coins }}</template></button>
            <button v-else-if="deal.compensate" type="button" class="h-12 rounded-lg bg-gold font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null || !!list?.closed" @click="buy(true)">
              <span dir="ltr" class="font-numbers">{{ money(deal.compensate.cash) }}</span> + <img src="/brand/coin.svg" alt="" class="inline size-4" /> <span class="font-numbers">{{ deal.compensate.coins + deal.doc_coins }}</span> {{ $t('كوينز') }}</button>
          </template>
          <button type="button" class="h-11 rounded-lg bg-surface-raised font-bold" @click="picked = null">{{ $t('إغلاق') }}</button>
        </div>
      </div>

      <!-- The celebration. -->
      <div v-if="celebrate" class="fixed inset-0 z-50 flex items-center justify-center bg-bg-deep/85 p-4" role="alertdialog" :aria-label="$t('تمت الصفقة')" @click="celebrate = ''">
        <div class="celebrate flex max-w-sm flex-col items-center gap-3 rounded-2xl border border-gold/50 bg-surface p-6 text-center">
          <span class="text-5xl" aria-hidden="true">🎉</span>
          <b class="font-display text-2xl text-gold"><bdi>{{ $nm(celebrate) }}</bdi></b>
          <p>{{ $t('تم شراء هذا اللاعب وإضافته للفريق بنجاح') }}</p>
          <button type="button" class="h-12 rounded-lg bg-gold px-6 font-bold text-on-gold" @click="celebrate = ''">{{ $t('رائع') }}</button>
        </div>
      </div>

      <section v-else :aria-label="$t('بيع لاعبيّ')" class="flex flex-col gap-2 rounded-xl bg-surface p-2">
        <p class="px-2 pt-2 text-sm text-text-muted">{{ $t('بيع فوري بقيمة اللاعب الكاملة مقابل رسوم صغيرة، أو اعرضه بقيمته أو بسعرك حتى سقفه بلا رسوم: لو لم يشتره مدرب، يشتريه نادٍ من خارج الدوري، وكلما ارتفع السعر طال الانتظار. والتدريب يرفع قيمة اللاعب وسعره.') }}</p>
        <ul class="flex flex-col">
          <li v-for="p in m.mine" :key="p.id" class="flex flex-col border-t border-text/5 px-2 py-2">
            <div class="flex items-center gap-3">
              <LineBadge :line="p.line as Line" />
              <span class="min-w-0 flex-1">
                <b class="block truncate" dir="auto">{{ $nm(p.name) }}</b>
                <span class="text-xs text-text-muted">{{ $t('{v0} · قيمته {v1} · سقفه {v2}', { v0: p.position, v1: money(p.value), v2: money(p.cap) }) }}</span>
                <span v-if="p.listed" class="mt-1 block w-fit rounded-pill bg-gold/15 px-2 text-xs text-gold">{{ $t('معروض بـ') }} <b dir="ltr" class="font-numbers">{{ money(p.listed.price) }}</b></span>
              </span>
              <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
              <button type="button" class="h-touch min-w-20 rounded-md border border-warning/60 px-3 font-bold text-warning disabled:opacity-40" :aria-expanded="open === p.id" :disabled="!!m.closed" @click="openSell(p)">{{ $t('بيع') }}</button>
            </div>
            <div v-if="open === p.id" class="mt-2 flex flex-col gap-3 rounded-lg bg-surface-sunk p-3 text-sm">
              <div v-if="p.listed" class="flex flex-wrap items-center gap-2">
                <span>{{ $t('معروض بـ') }} <b dir="ltr" class="font-numbers">{{ money(p.listed.price) }}</b><template v-if="p.listed.sells_at">{{ $t('، ويُباع {v0} إن لم يشتره مدرب.', { v0: when(p.listed.sells_at) }) }}</template></span>
                <button type="button" class="h-touch rounded-md bg-surface-raised px-3" :disabled="busy !== null" @click="unlist(p)">{{ $t('اسحبه من البيع') }}</button>
              </div>
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span class="inline-flex flex-wrap items-center"><b>{{ $t('بيع فوري') }}</b><HelpTip :text="g.quick_sale" :label="$t('البيع الفوري')" /></span><span>{{ $t(': تحصل الآن على') }} <b dir="ltr" class="font-numbers text-success">{{ money(p.quick.pays) }}</b> {{ $t('مقابل {v0}.', { v0: fee(p) }) }}</span>
                <button type="button" class="h-touch rounded-md bg-warning px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null" @click="act('sell', p.id, p.name)">{{ busy === p.id ? '...' : $t('بع الآن') }}</button>
              </div>
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span><b>{{ $t('بقيمته') }}</b> <b dir="ltr" class="font-numbers">{{ money(p.value) }}</b> {{ $t('بلا رسوم، ويُباع خلال {v0}.', { v0: hours(p.wait_hours.value) }) }}</span>
                <button type="button" class="h-touch rounded-md border border-gold/60 px-4 font-bold text-gold disabled:opacity-40" :disabled="busy !== null" @click="listAt(p, p.value)">{{ $t('اعرضه بقيمته') }}</button>
                <HelpTip :text="g.listing" :label="$t('العرض في السوق')" />
              </div>
              <form class="flex flex-wrap items-end gap-2" @submit.prevent="price && listAt(p, Number(price))">
                <label class="flex flex-col gap-1"><b>{{ $t('بسعرك') }}</b> <span class="text-xs text-text-muted">{{ $t('من {v0} إلى {v1}', { v0: money(p.floor), v1: money(p.cap) }) }}</span>
                  <input v-model.number="price" type="number" inputmode="numeric" :min="p.floor" :max="p.cap" step="1000" class="h-touch w-40 rounded-md bg-surface px-2 font-numbers" dir="ltr" :aria-label="$t('سعر {v0}', { v0: p.name })" />
                </label>
                <button type="submit" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy !== null || !quote?.ok">{{ $t('اعرضه بهذا السعر') }}</button>
                <span v-if="quote" class="text-xs" :class="quote.ok ? 'text-text-muted' : 'text-[#FF8A8A]'">{{ quote.ok ? $t('يُباع خلال {v0}', { v0: hours(quote.wait_hours) }) : $t('خارج حدود سعره') }}</span>
              </form>
            </div>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>

<style scoped>
/* [UP11] The deal done: the card pops in, on the GPU only. */
.celebrate { animation: pop 0.45s cubic-bezier(0.2, 0.8, 0.2, 1.2) both }
@keyframes pop { from { transform: scale(0.8); opacity: 0 } to { transform: scale(1); opacity: 1 } }
@media (prefers-reduced-motion: reduce) { .celebrate { animation: none } }
</style>
