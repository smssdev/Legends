<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// The market (Sprint 24 W1, [UP11] the owner's spec 5): four sections (the transfer list, the negotiations, the scout,
// the transfers made) and my players to sell. The list is one per line (GK, DEF, MID, ATT, no search), renewed every
// few hours with a countdown, each player with his seller: a club and its coach, a computer's club, or his own club
// outside the league. A tap opens his card and the deal: the price and 1 or 2 coins to register it, or, short of cash
// with half the price at least, the cash and coins for the rest. Prices and rules come from the API.
import AsyncState from '../../components/ui/AsyncState.vue'
import UiButton from '../../components/ui/UiButton.vue'
import { uuid } from '../../lib/uuid'
import { useEscape } from '../../lib/escape'
import UiDialog from '../../components/ui/UiDialog.vue'
import EmptyState from '../../components/ui/EmptyState.vue'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api, asApiError } from '../../api/client'
import { act, busy as isBusy } from '../../lib/action'
import { nm } from '../../lib/names'
import { t } from '../../lib/i18n'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import EventsBar from '../../components/ui/EventsBar.vue'
import UiTabs from '../../components/ui/UiTabs.vue'
import AcademyPanel from './market/AcademyPanel.vue'
import LoansPanel from './market/LoansPanel.vue'
import SellPanel from './market/SellPanel.vue'
import Trades from './Trades.vue'
import ScoutPage from './ScoutPage.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { money, type Line } from '../../lib/format'

type Market = components['schemas']['Market']
// The "?" texts [X19].
const leagueId = ref<number | null>(null)
const m = ref<Market | null>(null)
const loaded = ref(false)
const error = ref('')
const busy = computed(() => (picked.value && isBusy(`buy:${picked.value.id}`) ? picked.value.id : null))
const route = useRoute()
type Tab = 'list' | 'offers' | 'loans' | 'academy' | 'scout' | 'done' | 'sell'
const tab = ref<Tab>((['list', 'offers', 'loans', 'academy', 'scout', 'done', 'sell'].includes(String(route.query.tab)) ? route.query.tab : 'list') as Tab)
const line = ref<Line>('gk')
const wallet = useWallet()
const tabs = computed(() => [
  { id: 'list' as const, label: 'قائمة الانتقالات', n: null },
  { id: 'offers' as const, label: 'المفاوضات', n: null },
  { id: 'loans' as const, label: 'الإعارات', n: null },
  { id: 'academy' as const, label: 'الأكاديمية', n: null },
  { id: 'scout' as const, label: 'الكشاف', n: null },
  { id: 'done' as const, label: 'الانتقالات التي تمت', n: null },
  { id: 'sell' as const, label: 'بيع لاعبيّ', n: m.value?.mine.length ?? 0 },
])
const LINES: { id: Line; label: string }[] = [{ id: 'gk', label: 'حراس المرمى GK' }, { id: 'def', label: 'المدافعون DEF' }, { id: 'mid', label: 'لاعبو الوسط MID' }, { id: 'att', label: 'المهاجمون ATT' }]

// [UP11] The transfer list of one line, its renewal countdown, a player's deal and the celebration.
type Seller = { kind: 'world' | 'bot' | 'coach'; club_id: number | null; club: string | null; coach: string | null; logo: string | null }
// [Sprint 23] special: an admin's event's player (an offer, a player of the week, a legend); was_price: before a discount.
type Row = Market['players'][number] & { seller: Seller; star?: boolean; special?: 'offer' | 'in_form' | 'legend' | null; was_price?: number | null; fits?: boolean }
type ListView = { closed: string | null; line: Line; balance: number; renews_at: string | null; events?: components['schemas']['TimedEventNow'][]; players: Row[] }
const SPECIAL = { offer: '🎁 عرض خاص', in_form: '🔥 نجم الأسبوع', legend: '👑 أسطورة' } as const
type Quote = { price: number; cash: number; doc_coins: number; short: number; compensate: { cash: number; coins: number } | null; can: boolean; why: string | null }
const list = ref<ListView | null>(null)
// [X61] The transfer list a page at a time, back to the first page with each line or renewal.
const PAGE = 30
const page = ref(0)
// [Sprint 30 Q6] The list's search, filters and order (what the server sent, only shown differently), and two players
// side by side. «يناسب تشكيلتك» (fits) comes from the server.
const query = ref('')
const maxAge = ref(0)
const minOvr = ref(0)
const maxPrice = ref(0)
const onlyFits = ref(false)
const sortBy = ref<'default' | 'overall' | 'age' | 'price'>('default')
const AGES = [0, 21, 25, 29, 33]
const OVRS = [0, 65, 70, 75, 80, 85]
const PRICES = [0, 1_000_000, 3_000_000, 5_000_000, 10_000_000, 20_000_000]
const fold = (x: string) => x.toLocaleLowerCase().normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
const shown = computed(() => {
  const q = fold(query.value.trim())
  const rows = (list.value?.players ?? []).filter((p) => (!q || fold(p.name).includes(q))
    && (!maxAge.value || p.age <= maxAge.value) && (!minOvr.value || p.overall >= minOvr.value)
    && (!maxPrice.value || p.price <= maxPrice.value) && (!onlyFits.value || p.fits))
  const by = { overall: (a: Row, b: Row) => b.overall - a.overall, age: (a: Row, b: Row) => a.age - b.age, price: (a: Row, b: Row) => a.price - b.price }
  return sortBy.value === 'default' ? rows : [...rows].sort(by[sortBy.value])
})
const filtersOpen = ref(false)
// [Sprint 56 W5] How many filters are on, on the drawer's button.
const filterCount = computed(() => [query.value, maxAge.value, minOvr.value, maxPrice.value, onlyFits.value].filter(Boolean).length)
const filtering = computed(() => !!(query.value || maxAge.value || minOvr.value || maxPrice.value || onlyFits.value))
function clearFilters() {
  query.value = ''
  maxAge.value = minOvr.value = maxPrice.value = 0
  onlyFits.value = false
}
const comparing = ref<Row[]>([])
const compareOpen = ref(false)
function toggleCompare(p: Row) {
  comparing.value = comparing.value.some((x) => x.id === p.id) ? comparing.value.filter((x) => x.id !== p.id) : [...comparing.value, p].slice(-2)
}
const ATTR_LABELS: Record<string, string> = { pac: 'سرعة', sho: 'تسديد', pas: 'تمرير', dri: 'مراوغة', def: 'دفاع', phy: 'بدنية', diving: 'طيران', handling: 'إمساك', kicking: 'ركل', positioning: 'تمركز', reflexes: 'ردة فعل' }
const pages = computed(() => Math.ceil(shown.value.length / PAGE))
watch([line, () => shown.value.length], () => (page.value = 0))
const now = ref(Date.now())
const renewsIn = computed(() => {
  const s = list.value?.renews_at ? Math.max(0, Math.floor((new Date(list.value.renews_at).getTime() - now.value) / 1000)) : 0
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
})
const picked = ref<Row | null>(null)
const deal = ref<Quote | null>(null)
const celebrate = ref('')
useEscape(() => (celebrate.value = ''), () => !!celebrate.value)
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
// [X92] Through lib/action: the deal's button waits; an offer to a coach is said in a toast with «تراجع» (withdrawn),
// a purchase with the celebration; an error in a toast.
async function buy(compensate: boolean) {
  const p = picked.value
  if (!p || !leagueId.value) return
  const league = leagueId.value
  let offer = 0
  const r = p.seller.kind === 'coach'
    // A coach's listed player: an offer at his price, for his coach to accept (the negotiations).
    ? await act(`buy:${p.id}`, async () => {
        const res = await api.POST('/leagues/{league}/transfers/offers', { params: { path: { league } },
          body: { to_club_id: p.seller.club_id!, money: p.price, in: [p.id], idempotency_key: uuid() } as any })
        offer = (res.data as { offer?: { id: number } } | undefined)?.offer?.id ?? 0
        return res
      }, {
        success: t('أُرسل عرضك لمدرب {v0}. تابعه في المفاوضات.', { v0: nm(p.seller.club ?? '') }),
        undo: () => (offer ? api.POST('/leagues/{league}/transfers/offers/{offer}/cancel' as any, { params: { path: { league, offer } } }) : Promise.resolve()),
      })
    : await act(`buy:${p.id}`, () => api.POST('/leagues/{league}/market/buy', { params: { path: { league } }, body: { player_id: p.id, idempotency_key: uuid(), compensate } }))
  if (r === undefined) return
  if (p.seller.kind !== 'coach') { celebrate.value = p.name; void wallet.load() }
  picked.value = null
  await Promise.all([load(), loadList()])
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
      // source=pool answers Market (source=list answers TransferList).
      m.value = data as Market
      if (tab.value === 'list') await loadList()
      if (tab.value === 'done') await loadDone()
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

// Selling [X6]: one open player at a time, in the shared panel (market/SellPanel.vue).
type Mine = Market['mine'][number]
const open = ref<number | null>(null)
function openSell(p: Mine) {
  open.value = open.value === p.id ? null : p.id
}
// The panel says its own result in a toast (lib/action); the market only loads again.
async function sold() {
  error.value = ''
  open.value = null
  await load()
}

watch(line, () => loadList())
watch(tab, (t) => { if (t === 'list') void loadList(); if (t === 'done') void loadDone() })
let clock = 0
onMounted(() => { void load(); clock = window.setInterval(() => { now.value = Date.now(); if (list.value?.renews_at && new Date(list.value.renews_at).getTime() <= now.value - 3000 && tab.value === 'list') { list.value.renews_at = null; void loadList() } }, 1000) })
onBeforeUnmount(() => clearInterval(clock))
// [X87] A change made from a toast's «تراجع» after the panel closed: the market again.
let again = 0
const changed = () => { clearTimeout(again); again = window.setTimeout(() => load(), 450) }
onMounted(() => window.addEventListener('glm:league-changed', changed))
onBeforeUnmount(() => window.removeEventListener('glm:league-changed', changed))
</script>

<template>
  <!-- [Sprint 56 W5] Market.html: one row of tabs, the players first (the line, the clock and the filters in one row
       above them, the filters in a drawer), and every tab's content scrolling inside the screen. -->
  <div class="market">
    <h1 class="sr-only">{{ $t('السوق') }}</h1>

    <!-- [Sprint 56 W11] The states as every screen's: a skeleton in the list's shape, the error with a retry, no team. -->
    <p v-if="error && loaded && m" class="rounded-lg bg-live/15 px-4 py-2 text-caption text-danger" role="alert">{{ $t(error) }}</p>
    <AsyncState v-if="!loaded || (!m && error)" :loading="!loaded" :error="error || null" skeleton="row" :rows="6" @retry="load" />
    <AsyncState v-else-if="!leagueId" empty empty-icon="market" empty-title="ليس لديك فريق بعد." :empty-cta="{ label: 'دورياتي', to: '/leagues' }" />

    <template v-else-if="m">
      <UiTabs v-model="tab" :items="tabs.map((t) => ({ key: t.id, label: t.label, n: t.n }))" label="مصادر اللاعبين" size="sm" class="max-w-full self-start" />
      <div v-if="tab !== 'sell'" class="market-body">

      <Trades v-if="tab === 'offers'" :league-id="leagueId" view="offers" :mine="m.mine" @changed="load" />
      <LoansPanel v-else-if="tab === 'loans' && leagueId" :league-id="leagueId" @changed="load" />
      <AcademyPanel v-else-if="tab === 'academy' && leagueId" :league-id="leagueId" @changed="load" />
      <ScoutPage v-else-if="tab === 'scout'" />

      <section v-else-if="tab === 'done'" :aria-label="$t('الانتقالات التي تمت')" class="rounded-xl ui-card p-2">
        <EmptyState v-if="!done.length" icon="market" title="لا انتقالات بعد هذا الموسم." text="كل صفقة تتم في دوريك تظهر هنا." />
        <ul class="flex flex-col">
          <li v-for="(t, i) in done" :key="i" class="v-row flex flex-wrap items-center gap-2 border-t border-text/5 px-2 py-2 text-sm first:border-0">
            <b class="min-w-0 flex-1 truncate"><bdi>{{ $nm(t.player) }}</bdi></b>
            <span class="text-text-muted">{{ t.from ? $nm(t.from) : $t('من خارج الدوري') }} ← <b class="text-text">{{ $nm(t.to) }}</b></span>
            <span class="w-20 text-end font-numbers font-bold" dir="ltr">{{ money(t.price) }}</span>
          </li>
        </ul>
      </section>

      <template v-else-if="tab === 'list'">
        <div class="flex items-center gap-2">
          <UiTabs v-model="line" :items="LINES.map((l) => ({ key: l.id, label: l.label }))" label="المراكز" tone="brand" size="sm" class="min-w-0 flex-1" />
          <span v-if="list?.renews_at" class="flex h-touch shrink-0 items-center gap-1.5 rounded-lg border border-gold/40 bg-surface px-2 text-caption" :title="$t('الصفقات التالية بعد')"><span class="max-lg:hidden">{{ $t('الصفقات التالية بعد') }}</span><span aria-hidden="true" class="lg:hidden">⏱</span> <b class="font-numbers text-body-lg text-gold" dir="ltr">{{ renewsIn }}</b></span>
          <UiButton size="sm" :variant="filtering ? 'primary' : 'quiet'" class="shrink-0" :aria-expanded="filtersOpen" @click="filtersOpen = true">⚙ {{ $t('الفلاتر') }}<span v-if="filterCount" class="font-numbers">({{ filterCount }})</span></UiButton>
        </div>
        <!-- [Sprint 23] The admin's events running in this league. -->
        <EventsBar :events="list?.events" @ended="loadList" />
        <!-- [Sprint 30 Q6] Search, filters and order; [Sprint 56 W5] in a drawer at the side, the players first. -->
        <UiDialog :open="filtersOpen" side closable title="الفلاتر" @close="filtersOpen = false">
          <form class="flex flex-col gap-2" role="search" @submit.prevent="filtersOpen = false">
            <p class="text-caption text-text-muted">
              <template v-if="m?.closed">{{ m.closed }}</template>
              <template v-else-if="m">{{ $t('مفتوح حتى الجولة {v0} · صفقات جديدة كل بضع ساعات، من كل الدوريات وبقوة دوريك', { v0: m.open_until_round }) }}</template>
            </p>
            <input v-model="query" type="search" dir="auto" :placeholder="$t('ابحث بالاسم')" :aria-label="$t('ابحث بالاسم')" class="h-touch rounded-md bg-surface-sunk px-3" />
            <select v-model.number="minOvr" :aria-label="$t('القوة من')" class="h-touch rounded-md bg-surface-sunk px-2 text-body">
              <option v-for="o in OVRS" :key="o" :value="o">{{ o ? $t('القوة {v0}+', { v0: o }) : $t('كل القوى') }}</option></select>
            <select v-model.number="maxAge" :aria-label="$t('العمر حتى')" class="h-touch rounded-md bg-surface-sunk px-2 text-body">
              <option v-for="a in AGES" :key="a" :value="a">{{ a ? $t('حتى {v0} سنة', { v0: a }) : $t('كل الأعمار') }}</option></select>
            <select v-model.number="maxPrice" :aria-label="$t('السعر حتى')" class="h-touch rounded-md bg-surface-sunk px-2 text-body">
              <option v-for="x in PRICES" :key="x" :value="x">{{ x ? $t('حتى {v0}', { v0: money(x) }) : $t('كل الأسعار') }}</option></select>
            <select v-model="sortBy" :aria-label="$t('الترتيب')" class="h-touch rounded-md bg-surface-sunk px-2 text-body">
              <option value="default">{{ $t('الترتيب: المميزون أولاً') }}</option><option value="overall">{{ $t('الأقوى أولاً') }}</option>
              <option value="age">{{ $t('الأصغر أولاً') }}</option><option value="price">{{ $t('الأرخص أولاً') }}</option></select>
            <label class="flex min-h-touch items-center gap-2 text-body"><input v-model="onlyFits" type="checkbox" class="size-5 accent-gold" />{{ $t('من يناسب تشكيلتك فقط') }}</label>
            <div class="mt-2 grid grid-cols-2 gap-2">
              <UiButton type="submit" size="sm">{{ $t('اعرض اللاعبين') }}</UiButton>
              <UiButton size="sm" variant="quiet" :disabled="!filtering" @click="clearFilters">{{ $t('امسح البحث') }}</UiButton>
            </div>
          </form>
        </UiDialog>
        <!-- The comparison under the filters, never over the Assistant Coach's button. -->
        <div v-if="comparing.length" class="flex items-center gap-2">
          <UiButton :variant="comparing.length === 2 ? 'primary' : 'quiet'" class="min-w-0 flex-1"
            :disabled="comparing.length < 2" @click="compareOpen = true">
            <span class="truncate">{{ comparing.length === 2 ? $t('قارن بين {v0} و{v1}', { v0: comparing[0].name, v1: comparing[1].name }) : $t('اختر لاعباً آخر للمقارنة مع {v0}', { v0: comparing[0].name }) }}</span>
          </UiButton>
          <button type="button" class="grid size-12 shrink-0 place-items-center rounded-full bg-surface" :aria-label="$t('ابدأ مقارنة جديدة')" @click="comparing = []"><Icon name="close" :size="18" /></button>
        </div>
        <section :aria-label="$t('قائمة الانتقالات')" class="market-list rounded-xl ui-card p-2">
          <AsyncState v-if="!list" loading skeleton="row" :rows="5" />
          <p v-else-if="!list.players.length" class="p-4 text-sm text-text-muted">{{ $t('لا لاعبين في هذا المركز الآن.') }}</p>
          <p v-else-if="!shown.length" class="flex flex-wrap items-center gap-2 p-4 text-sm text-text-muted">{{ $t('لا لاعب يطابق البحث.') }}
            <button type="button" class="min-h-touch font-bold text-gold" @click="clearFilters">{{ $t('امسح البحث') }}</button></p>
          <!-- [Sprint 30 Q6] Fixed columns: their names stay over the list while it scrolls. -->
          <!-- [Sprint 48 T5] The columns' bar in the line's colour, as the squad's tables (the owner's screenshots, our own look). -->
          <div v-if="shown.length" class="market-head sticky top-0 z-10 max-md:hidden flex items-center gap-2 rounded-lg px-2 py-2 text-xs font-bold sm:gap-3" aria-hidden="true"
            :style="{ '--line': `var(--color-line-${list!.line})`, '--line-fg': `var(--color-line-${list!.line}-fg)` }">
            <span class="w-8 text-center sm:w-10">{{ $t('القوة') }}</span><span class="flex-1">{{ $t('اللاعب') }}</span>
            <span class="hidden w-12 text-center sm:block">{{ $t('المركز') }}</span><span class="hidden w-10 text-center sm:block">{{ $t('العمر') }}</span>
            <span class="hidden w-48 sm:block">{{ $t('النادي') }}</span><span class="w-16 text-end sm:w-20">{{ $t('السعر') }}</span>
          </div>
          <ul v-if="shown.length" class="flex flex-col">
            <li v-for="p in shown.slice(page * PAGE, (page + 1) * PAGE)" :key="p.id" class="v-row">
              <button type="button" class="flex min-h-touch w-full items-center gap-2 border-t border-text/5 px-2 py-1 text-start transition-transform first:border-0 hover:bg-surface-raised sm:gap-3" @click="pick(p)">
                <span class="w-8 text-center font-numbers text-lg sm:w-10 sm:text-xl" :class="p.overall >= 80 ? 'text-success' : p.overall >= 70 ? 'text-gold' : ''">{{ p.overall }}</span>
                <span class="min-w-0 flex-1">
                  <b class="flex items-center gap-1.5 truncate"><bdi class="truncate">{{ $nm(p.name) }}</bdi><span v-if="p.star" class="shrink-0 rounded-pill bg-gold px-1.5 text-caption font-bold text-on-gold">⭐ {{ $t('نجم') }}</span><span v-if="p.special" class="shrink-0 rounded-pill bg-brand px-1.5 text-caption font-bold text-white">{{ $t(SPECIAL[p.special]) }}</span></b>
                  <span v-if="p.fits" class="me-1 inline-block rounded-pill bg-success/15 px-1.5 text-caption font-bold text-success">{{ $t('يناسب تشكيلتك') }}</span>
                  <span class="block text-xs text-text-muted"><span class="sm:hidden">{{ $t('{v0} · {v1} سنة', { v0: p.position, v1: p.age }) }}<template v-if="p.nationality"> · </template></span><template v-if="p.nationality">{{ $nm(p.nationality) }}</template></span>
                </span>
                <span class="hidden w-12 text-center text-sm text-text-soft sm:block" dir="ltr">{{ p.position }}</span>
                <span class="hidden w-10 text-center font-numbers text-text-soft sm:block">{{ p.age }}</span>
                <span class="hidden w-48 min-w-0 items-center gap-1.5 text-xs sm:flex">
                  <AppImage v-if="p.seller.logo" :src="p.seller.logo" alt="" class="size-6 object-contain" :size="24" />
                  <span class="min-w-0"><span class="block truncate">{{ p.seller.club ? $nm(p.seller.club) : '' }}</span><span v-if="p.seller.coach" class="block truncate text-brand-light">{{ p.seller.coach }}</span></span>
                </span>
                <span class="flex w-16 flex-col items-end sm:w-20"><s v-if="p.was_price" class="font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.was_price) }}</s><span class="font-numbers text-base font-bold sm:text-lg" :class="p.was_price ? 'text-success' : ''" dir="ltr">{{ money(p.price) }}</span></span>
              </button>
            </li>
          </ul>
          <!-- [X61] Thirty a page: a long line stays quick on a phone. -->
          <nav v-if="list && pages > 1" class="flex items-center justify-center gap-2 border-t border-text/5 pt-2" :aria-label="$t('الصفحات')">
            <button type="button" class="grid size-11 place-items-center rounded-lg bg-surface-sunk disabled:opacity-40" :disabled="page === 0" :aria-label="$t('السابق')" @click="page--"><span aria-hidden="true" class="rtl:rotate-180">←</span></button>
            <span class="font-numbers text-sm" dir="ltr">{{ page + 1 }} / {{ pages }}</span>
            <button type="button" class="grid size-11 place-items-center rounded-lg bg-surface-sunk disabled:opacity-40" :disabled="page >= pages - 1" :aria-label="$t('التالي')" @click="page++"><span aria-hidden="true" class="rtl:rotate-180">→</span></button>
          </nav>
        </section>
      </template>
      </div>

      <!-- The player's card and the deal. -->
      <UiDialog :open="!!picked" bare @close="picked = null"><template v-if="picked">
        <div class="flex w-full max-w-md flex-col gap-3 rounded-2xl border border-gold/30 ui-card p-4">
          <PlayerTile :name="picked.name" :line="picked.line as Line" :position="picked.position" :overall="picked.overall" :value="picked.value" :price="picked.price"
            :attributes="picked.attributes" :status="$t('{v0} سنة · {v1}{v2}', { v0: picked.age, v1: picked.seller.club ? $nm(picked.seller.club) : '', v2: picked.seller.coach ? ' · ' + picked.seller.coach : '' })" status-tone="text-text-muted" />
          <template v-if="picked.seller.kind === 'coach'">
            <UiButton :disabled="busy !== null || !!list?.closed" @click="buy(false)">{{ $t('قدّم عرضاً بـ') }} <span dir="ltr" class="font-numbers">{{ money(picked.price) }}</span></UiButton>
          </template>
          <template v-else-if="deal">
            <dl class="flex flex-col divide-y divide-text/5 text-sm">
              <div class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('قيمة الصفقة') }}</dt><dd dir="ltr" class="font-numbers font-bold">{{ money(deal.price) }}</dd></div>
              <div class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('أموال ناديك') }}</dt><dd dir="ltr" class="font-numbers">{{ money(deal.cash) }}</dd></div>
              <div v-if="deal.doc_coins" class="flex justify-between py-1.5"><dt class="text-text-muted">{{ $t('توثيق الصفقة') }}</dt><dd><AppImage src="/brand/coin.svg" alt="" class="inline size-4" :size="16" /> <span class="font-numbers">{{ deal.doc_coins }}</span></dd></div>
            </dl>
            <p v-if="deal.why" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="alert">{{ deal.why }}</p>
            <UiButton variant="brand" v-if="!deal.short" :disabled="busy !== null || !!list?.closed" @click="buy(false)">
              {{ $t('شراء ·') }} <span dir="ltr" class="font-numbers">{{ money(deal.price) }}</span><template v-if="deal.doc_coins"> + <AppImage src="/brand/coin.svg" alt="" class="inline size-4" :size="16" /> {{ deal.doc_coins }}</template></UiButton>
            <UiButton v-else-if="deal.compensate" :disabled="busy !== null || !!list?.closed" @click="buy(true)">
              <span dir="ltr" class="font-numbers">{{ money(deal.compensate.cash) }}</span> + <AppImage src="/brand/coin.svg" alt="" class="inline size-4" :size="16" /> <span class="font-numbers">{{ deal.compensate.coins + deal.doc_coins }}</span> {{ $t('كوينز') }}</UiButton>
          </template>
          <button type="button" class="h-11 rounded-lg border border-gold/40 font-bold text-gold" @click="toggleCompare(picked)">
            {{ comparing.some((x) => x.id === picked!.id) ? $t('أزله من المقارنة') : $t('أضفه للمقارنة') }}</button>
          <button type="button" class="h-11 rounded-lg bg-surface-raised font-bold" @click="picked = null">{{ $t('إغلاق') }}</button>
        </div>
      </template></UiDialog>

      <!-- [Sprint 30 Q6] Two players side by side: each attribute, the higher in gold. -->
      <UiDialog :open="compareOpen && comparing.length === 2" title="مقارنة لاعبين" wide @close="compareOpen = false">
        <table class="w-full text-sm">
          <thead><tr><th class="text-start text-text-muted"></th><th v-for="c in comparing" :key="c.id" class="p-1 text-center"><bdi>{{ c.name }}</bdi></th></tr></thead>
          <tbody>
            <tr v-for="row in [{ k: 'overall', l: 'القوة' }, { k: 'potential', l: 'الإمكانية' }, { k: 'age', l: 'العمر', low: true }, { k: 'price', l: 'السعر', low: true, money: true }]" :key="row.k" class="border-t border-text/5">
              <th class="py-1.5 text-start font-normal text-text-muted">{{ $t(row.l) }}</th>
              <td v-for="c in comparing" :key="c.id" class="text-center font-numbers" dir="ltr"
                :class="(row.low ? (c as any)[row.k] < (comparing.find((x) => x.id !== c.id) as any)[row.k] : (c as any)[row.k] > (comparing.find((x) => x.id !== c.id) as any)[row.k]) ? 'font-bold text-gold' : ''">
                {{ row.money ? money((c as any)[row.k]) : (c as any)[row.k] }}</td>
            </tr>
            <tr v-for="k in Object.keys(comparing[0].attributes ?? {})" :key="k" class="border-t border-text/5">
              <th class="py-1.5 text-start font-normal text-text-muted">{{ $t(ATTR_LABELS[k] ?? k) }}</th>
              <td v-for="c in comparing" :key="c.id" class="text-center font-numbers" :class="((c.attributes as any)?.[k] ?? 0) > ((comparing.find((x) => x.id !== c.id)!.attributes as any)?.[k] ?? 0) ? 'font-bold text-gold' : ''">{{ (c.attributes as any)?.[k] ?? '-' }}</td>
            </tr>
          </tbody>
        </table>
        <UiButton variant="quiet" block class="mt-3" @click="comparing = []; compareOpen = false">{{ $t('ابدأ مقارنة جديدة') }}</UiButton>
      </UiDialog>

      <!-- The celebration. -->
      <div v-if="celebrate" class="fixed inset-0 z-50 flex items-center justify-center bg-bg-deep/85 p-4" role="alertdialog" :aria-label="$t('تمت الصفقة')" @click="celebrate = ''">
        <div class="celebrate flex max-w-sm flex-col items-center gap-3 rounded-2xl border border-gold/50 ui-card p-6 text-center">
          <span class="text-5xl" aria-hidden="true">🎉</span>
          <b class="font-display text-2xl text-gold"><bdi>{{ $nm(celebrate) }}</bdi></b>
          <p>{{ $t('تم شراء هذا اللاعب وإضافته للفريق بنجاح') }}</p>
          <UiButton @click="celebrate = ''">{{ $t('رائع') }}</UiButton>
        </div>
      </div>

      <!-- [X61] Its own tab only (it hung off the celebration's v-else, so it showed under every tab). -->
      <section v-if="tab === 'sell'" :aria-label="$t('بيع لاعبيّ')" class="market-sell flex flex-col gap-2 rounded-xl ui-card p-2">
        <!-- [Sprint 23] How many may be listed at once, and what outside buyers may still pay above the value this season. -->
        <p v-if="m.selling" class="flex flex-wrap gap-x-4 gap-y-1 px-2 pt-1 text-xs text-text-muted">
          <span>{{ $t('المعروضون: {v0} من {v1}', { v0: m.selling.listed, v1: m.selling.max_listings }) }}</span>
          <span>{{ $t('ربح البيع المتاح هذا الموسم:') }} <b dir="ltr" class="font-numbers text-text">{{ money(m.selling.room) }}</b></span>
        </p>
        <ul class="flex flex-col">
          <li v-for="p in m.mine" :key="p.id" class="flex flex-col border-t border-text/5 px-2 py-2">
            <div class="flex items-center gap-3">
              <LineBadge :line="p.line as Line" />
              <span class="min-w-0 flex-1">
                <b class="block truncate" dir="auto">{{ $nm(p.name) }}</b>
                <span class="text-xs text-text-muted">{{ $t('{v0} · قيمته {v1} · كلفته {v2} · سقفه {v3}', { v0: p.position, v1: money(p.value), v2: money(p.cost ?? p.value), v3: money(p.cap) }) }}</span>
                <span v-if="p.listed" class="mt-1 block w-fit rounded-pill bg-gold/15 px-2 text-xs text-gold">{{ $t('معروض بـ') }} <b dir="ltr" class="font-numbers">{{ money(p.listed.price) }}</b></span>
              </span>
              <span class="w-10 text-center font-numbers text-xl">{{ p.overall }}</span>
              <!-- [X84] A listed player shows it on his button; a tap opens withdraw or keep. -->
              <button v-if="p.listed" type="button" class="h-touch min-w-20 rounded-md bg-gold/15 px-3 text-sm font-bold text-gold" :aria-expanded="open === p.id" @click="openSell(p)">{{ $t('معروض للبيع ✓') }}</button>
              <button v-else type="button" class="h-touch min-w-20 rounded-md border border-warning/60 px-3 font-bold text-warning disabled:opacity-40" :aria-expanded="open === p.id" :disabled="!!m.closed" @click="openSell(p)">{{ $t('بيع') }}</button>
            </div>
            <!-- [Sprint 39 S1] The same panel as the player's card on the squad page. -->
            <SellPanel v-if="open === p.id" class="mt-2" :league-id="leagueId!" :player="p" @done="sold" @error="(e: string) => (error = e)" @keep="open = null" />
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>

<style scoped>
.market { display: flex; flex-direction: column; gap: var(--space-sm); }
.market-body { position: relative; display: flex; flex: 1; min-height: 0; flex-direction: column; gap: var(--space-sm); overflow-y: auto; overscroll-behavior: contain; }
.market-list { flex: 1; }
.market-sell { position: relative; flex: 1; min-height: 0; overflow-y: auto; }
.market-head { background: linear-gradient(90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line)); color: var(--line-fg); }
:dir(rtl) .market-head { background: linear-gradient(-90deg, color-mix(in srgb, var(--line) 82%, var(--color-shade)), var(--line)); }
/* [UP11] The deal done: the card pops in, on the GPU only. */
.celebrate { animation: pop 0.45s cubic-bezier(0.2, 0.8, 0.2, 1.2) both }
@keyframes pop { from { transform: scale(0.8); opacity: 0 } to { transform: scale(1); opacity: 1 } }
@media (prefers-reduced-motion: reduce) { .celebrate { animation: none } }
</style>
