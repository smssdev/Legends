<script setup lang="ts">
// The coach's home screen [X18], rebuilt by updates1 UP7 (2026-10-26): the coach's card on top (picture, name, level,
// cash and coins) and the eight club slots right under it, all in one screen without scrolling; the announcements, the
// record, the trophies and the rankings below. A guest sees the way in ([X59] the landing page).
import { storage } from '../lib/storage'
import AsyncState from '../components/ui/AsyncState.vue'
import InstallPrompt from '../components/InstallPrompt.vue'
import ReminderPrompt from '../components/ReminderPrompt.vue'
import UiDialog from '../components/ui/UiDialog.vue'
import UiTabs from '../components/ui/UiTabs.vue'
import { countdown, useNow } from '../lib/clock'
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import Icon from '../components/Icon.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import VerifiedBadge from '../components/VerifiedBadge.vue'
import ChalkBackdrop from '../components/ChalkBackdrop.vue'
import Landing from './Landing.vue'
import OnboardingChecklist from '../components/OnboardingChecklist.vue'
import AdSlot from '../components/ads/AdSlot.vue'
import { intlLocale, t } from '../lib/i18n'
import { rememberLeague } from '../lib/currentLeague'
import { useAuth } from '../stores/auth'
import { useWallet } from '../stores/wallet'
import { chime } from '../lib/chime'
import UiButton from '../components/ui/UiButton.vue'
import RatingBadge from '../components/RatingBadge.vue'
import { divisionName, signed, tierName } from '../lib/rating'

type Home = components['schemas']['HomeScreen']
type Ranked = components['schemas']['RankedCoach']
const auth = useAuth()
const router = useRouter()
const home = ref<Home | null>(null)
const error = ref('')
const announcement = ref(0)
type By = 'rating' | 'trophies' | 'level'
const ranking = ref<{ by: By; coaches: Ranked[]; me: Ranked | null } | null>(null)
// [Sprint 25] The rating's sheet: the tier, the ladder and the latest changes.
const ratingOpen = ref(false)
const rating = computed(() => home.value?.coach.rating ?? null)
const rankingBusy = ref(false)

const latest = computed(() => home.value?.announcements[announcement.value] ?? null)
// The hero's greeting by the device's hour, and the soonest match among the slots.
const greeting = computed(() => (new Date().getHours() < 12 ? t('صباح الخير يا كوتش') : new Date().getHours() < 18 ? t('نهارك سعيد يا كوتش') : t('مساء الخير يا كوتش')))
const nextUp = computed(() => home.value?.slots.filter((s) => s.next_match).sort((a, b) => (a.next_match!.live ? -1 : 0) - (b.next_match!.live ? -1 : 0) || a.next_match!.scheduled_at.localeCompare(b.next_match!.scheduled_at))[0] ?? null)
// The cash shown on the card: the club of the soonest match, else the first club.
const when = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { weekday: 'short', hour: 'numeric', minute: '2-digit' }).format(new Date(iso))

async function load() {
  if (!auth.user) return
  try {
    home.value = (await api.GET('/home')).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
}
onMounted(load)
watch(() => auth.user?.id, load)

const now = useNow()
const soon = (iso: string) => new Date(iso).getTime() - now.value < 86400000
// [Sprint 24 B3] A locked slot counts down to the day it opens; when the next one is due, the slots come again.
watch(now, (t) => {
  if (home.value?.next_slot_at && new Date(home.value.next_slot_at).getTime() <= t) {
    home.value.next_slot_at = null
    load()
  }
})
// [Sprint 24 B3] Opening a locked slot at once for coins: confirmed first, then the slot lights up with a chime.
const buying = ref<Home['slots'][number] | null>(null)
const buyBusy = ref(false)
const buyError = ref('')
const opened = ref<number[]>([])
async function unlock() {
  if (!buying.value) return
  buyBusy.value = true
  buyError.value = ''
  try {
    await ensureCsrf()
    const slot = buying.value.slot
    const locked = home.value!.slots.filter((x) => x.state === 'locked' && x.slot <= slot).map((x) => x.slot)
    home.value = (await api.POST('/home/slots/{slot}/unlock', { params: { path: { slot } } })).data!
    buying.value = null
    opened.value = locked
    chime()
    useWallet().load()
    setTimeout(() => (opened.value = []), 1600)
  } catch (e) {
    buyError.value = asApiError(e).message
  } finally {
    buyBusy.value = false
  }
}
// [Sprint 30 P6] «استلم مكافأتك»: the new coach's first coins, once, with the coin chime.
const claiming = ref(false)
async function claimStarter() {
  if (!home.value || claiming.value) return
  claiming.value = true
  try {
    await ensureCsrf()
    const d = (await api.POST('/home/starter-gift')).data!
    home.value.starter_gift = d.starter_gift
    home.value.coach.coins = d.coins
    chime()
    useWallet().load()
  } catch (e) {
    error.value = asApiError(e).message
  } finally {
    claiming.value = false
  }
}
// [Sprint 30 G4] The badges (worked out on the server), with their emblem and name here.
type Badge = { key: string; goal: number; progress: number; earned: boolean; tier: 'beginner' | 'intermediate' | 'pro'; reward: number }
const badges = ref<Badge[]>([])
const BADGES: Record<string, [string, string]> = {
  first_win: ['🥇', 'أول فوز'], matches: ['🏟️', '100 مباراة'], wins: ['⚽', '25 فوزاً'], first_title: ['🏆', 'أول لقب'],
  league_title: ['👑', 'بطل الدوري'], cup_title: ['🏅', 'بطل الكأس'], professional: ['🎖️', 'درجة المحترف'], legend: ['🌟', 'درجة الأسطورة'],
  friendlies: ['🤝', '10 وديات'], idea: ['💡', 'فكرة اعتُمدت'], invites: ['📨', '3 أصدقاء'],
  matches_10: ['👟', '10 مباريات'], wins_100: ['💯', '100 فوز'], titles_5: ['🏛️', '5 ألقاب'],
}
// [Sprint 40 A1] The three levels, each with its badges and the coins one gives once (from the server).
const TIERS = [
  { key: 'beginner', label: 'المبتدئ' },
  { key: 'intermediate', label: 'المتوسط' },
  { key: 'pro', label: 'المحترف' },
] as const
const byTier = computed(() => TIERS.map((t) => ({ ...t, badges: badges.value.filter((b) => b.tier === t.key) })).filter((t) => t.badges.length))
onMounted(async () => {
  try { badges.value = ((await api.GET('/home/achievements')).data?.achievements ?? []).filter((b) => BADGES[b.key]) } catch { /* the badges are a bonus */ }
})
// [Sprint 30 Q9] The clubs with something waiting, the most first; and into a club's screen from the home page.
// [X86] The slots: all the open ones, and of the locked only the next one, until the coach asks for all.
const allSlots = ref(false)
const shownSlots = computed(() => {
  const slots = home.value?.slots ?? []
  if (allSlots.value) return slots
  const firstLocked = slots.find((s) => s.state === 'locked')
  return slots.filter((s) => s.state !== 'locked' || s === firstLocked)
})
const lockedHidden = computed(() => (home.value?.slots.length ?? 0) - shownSlots.value.length)
// [X86] «المزيد» (the news, the badges, the poll, the ranking, the ways in), closed until the coach opens it, remembered here.
const moreOpen = ref((() => { try { return storage.get('home.more') === 'open' } catch { return false } })())
function setMore(open: boolean) {
  moreOpen.value = open
  try { storage.set('home.more', open ? 'open' : 'closed') } catch {}
}
function goClub(s: Home['slots'][number], to: string) {
  if (s.league) rememberLeague(s.league.id)
  router.push(to)
}
function openSlot(s: Home['slots'][number]) {
  if (s.state === 'waiting') return router.push(`/leagues/${s.league!.id}`)
  rememberLeague(s.league!.id)
  // [Sprint 20 W1] A club's slot opens its club board.
  router.push('/club')
}

// [Sprint 54 W5] The three orders as the design system's tabs.
const RANK_TABS: { key: By; label: string }[] = [{ key: 'rating', label: 'بالنقاط' }, { key: 'trophies', label: 'بالكؤوس' }, { key: 'level', label: 'بالمستوى' }]

async function openRanking(by: By) {
  rankingBusy.value = true
  try {
    ranking.value = (await api.GET('/rankings/coaches', { params: { query: { by } } })).data as any
  } catch (e) {
    error.value = asApiError(e).message
  }
  rankingBusy.value = false
}
</script>

<template>
  <!-- [X59] A visitor sees the whole game before signing in. -->
  <Landing v-if="!auth.user" />

  <div v-else class="flex flex-col gap-4">
    <!-- [Sprint 21 E3.4] The coach's chalkboard behind the home screen. -->
    <ChalkBackdrop />
    <AsyncState v-if="error && !home" :error="error" @retry="load" />
    <p v-else-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <!-- [Sprint 21 E3.4] On a computer two columns fill the screen: the card and the slots, and beside them the
         announcements, the record and quick ways in. On a phone the same in one column. -->
    <!-- [X86] The home screen simplified (the owner's request 2026-11-02): the coach, the next match and the slots; the
         rest (the news, the badges, the poll, the ranking, the ways in, the install and the reminder) under «المزيد». -->
    <!-- [Sprint 56 W8] The slots first, each with its club's next match (Home.html); on a computer two columns: the
         coach, the slots and the next match, and beside them the gift, the verification, the first steps and «المزيد». -->
    <div v-if="home" class="home-grid relative mx-auto w-full">
      <div class="home-main flex min-w-0 flex-col gap-4">
      <!-- [UP7] The coach's card on top: the picture, the name, the level, the club's cash and the coins. -->
      <section class="coach-card" :aria-label="$t('ملف المدرب')">
        <RouterLink to="/profile" class="shrink-0" :aria-label="$t('حسابي')">
          <AppImage v-if="home.coach.avatar_url" :src="home.coach.avatar_url" alt="" class="size-14 rounded-full border-2 border-gold object-cover md:size-20" :size="80" />
          <span v-else class="grid size-14 place-items-center rounded-full border-2 border-gold bg-surface-raised font-display text-2xl font-extrabold md:size-20 md:text-3xl">{{ home.coach.name.charAt(0) }}</span>
        </RouterLink>
        <div class="flex min-w-0 flex-1 flex-col gap-1">
          <span class="text-xs font-bold text-gold">{{ greeting }}</span>
          <b class="truncate font-display text-lg leading-tight md:text-xl">{{ home.coach.name }} <OfficialBadge v-if="home.coach.official" /><VerifiedBadge v-else-if="home.coach.verified" /></b>
          <!-- [Sprint 25] The rating: the tier's emblem, its name and division, and the points; opens the sheet. -->
          <button type="button" class="rating-chip" :aria-label="$t('نقاط المدرب ودرجته')" @click="ratingOpen = true">
            <RatingBadge :tier="home.coach.rating.tier.key" :division="home.coach.rating.tier.division" :size="22" />
            <span class="truncate text-xs font-extrabold">{{ tierName(home.coach.rating.tier.key) }} <span class="font-numbers" dir="ltr">{{ divisionName(home.coach.rating.tier.division) }}</span></span>
            <b class="font-numbers text-xs text-gold" dir="ltr">{{ home.coach.rating.points }}</b>
            <span v-if="home.coach.rating.recent[0]" class="font-numbers text-caption font-bold" :class="home.coach.rating.recent[0].delta >= 0 ? 'text-success' : 'text-danger'" dir="ltr">{{ signed(home.coach.rating.recent[0].delta) }}</span>
          </button>
        </div>
        <div class="flex shrink-0 flex-col items-end gap-1.5">
          <RouterLink to="/wallet" class="flex min-h-touch items-center gap-1 rounded-pill bg-gold/15 px-2.5 py-1 text-sm font-bold" :aria-label="$t('الكوينز')">
            <AppImage src="/brand/coin.svg" alt="" class="size-4" :size="16" /><span class="font-numbers" dir="ltr">{{ home.coach.coins }}</span>
          </RouterLink>
        </div>
      </section>

      <!-- [X86] «المطلوب منك اليوم» is gone: each slot's card counts what waits in it. -->

      <!-- The slots, the screen's heart, right under the card: all eight without scrolling. -->
      <section class="flex flex-col gap-2" :aria-label="$t('فتحات المدرب')">
        <h2 class="flex items-center gap-2 text-sm font-bold text-text-muted">{{ $t('فتحات المدرب') }}<span class="font-numbers text-xs" dir="ltr">{{ home.slots_open }}/{{ home.slots.length }}</span></h2>
        <!-- [X61] The slots come in one after the other. -->
        <div class="stagger grid grid-cols-2 gap-2 sm:grid-cols-4 lg:gap-3">
          <!-- [X32] Each slot a card: a band with its number and league (blue for a club), the crest on a ivory disc,
               and the next match at its foot. -->
          <template v-for="s in shownSlots" :key="s.slot">
          <!-- [Sprint 20 W1] An empty slot: «أنشئ دورياً» at once, and «انضم بكود». -->
          <div v-if="s.state === 'free'" class="slot-card is-free" :class="opened.includes(s.slot) ? 'is-opened' : ''" role="group" :aria-label="$t('الفتحة {n}: دوري جديد', { n: s.slot })">
            <span class="slot-band"><b class="font-numbers text-sm">{{ s.slot }}</b><span class="min-w-0 flex-1 truncate text-start text-caption font-bold">{{ $t('فتحة فارغة') }}</span></span>
            <span class="flex flex-1 flex-col justify-center gap-1.5 p-2">
              <UiButton to="/leagues/new" size="sm" block>{{ $t('أنشئ دورياً') }}</UiButton>
              <UiButton to="/join" variant="quiet" size="sm" block>{{ $t('انضم بكود') }}</UiButton>
            </span>
          </div>
          <!-- [Sprint 24 B3] A locked slot: it opens with the account's age (the countdown and the bar of the wait), or
               the first one at once for coins. -->
          <div v-else-if="s.state === 'locked'" class="slot-card is-locked" :class="s.unlock_coins ? 'is-next' : ''" role="group" :aria-label="$t('الفتحة {n}: مقفلة', { n: s.slot })">
            <span class="slot-band"><b class="font-numbers text-sm">{{ s.slot }}</b><span class="min-w-0 flex-1 truncate text-start text-caption font-bold">🔒 {{ $t('مقفلة') }}</span></span>
            <span class="flex flex-1 flex-col items-center justify-center gap-1 p-2 text-center">
              <span class="text-caption text-text-muted">{{ $t('تُفتح مجاناً بعد') }}</span>
              <b class="font-numbers text-sm" dir="ltr">{{ countdown(s.opens_at, now) || $t('الآن') }}</b>
              <span class="h-1 w-full overflow-hidden rounded-pill bg-surface-sunk" aria-hidden="true"><span class="block h-full bg-brand-light" :style="{ width: (s.progress_bp ?? 0) / 100 + '%' }" /></span>
              <UiButton v-if="s.unlock_coins" size="sm" block class="mt-1 !px-2 !text-xs" @click="buying = s">{{ $t('فتح فوري ({v0} كوينز)', { v0: s.unlock_coins }) }}</UiButton>
            </span>
          </div>
          <button v-else type="button" class="slot-card group" :class="`is-${s.state}`"
            :aria-label="$t('الفتحة {n}: {league}', { n: s.slot, league: s.league?.name ?? '' }) + (s.pending ? ' · ' + $t('ما ينتظرك: {n}', { n: s.pending }) : '')" @click="openSlot(s)">
            <span class="slot-band">
              <b class="font-numbers text-sm">{{ s.slot }}</b>
              <span class="min-w-0 flex-1 truncate text-start text-caption font-bold">{{ s.league!.name }}</span>
              <span v-if="s.position" class="rounded bg-shade/30 px-1 font-numbers text-caption" dir="ltr">{{ s.position }}/{{ s.teams }}</span>
              <span v-if="s.pending" class="min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-caption text-white" :title="$t('ما ينتظرك')">{{ s.pending }}</span>
            </span>
            <span class="flex flex-1 items-center justify-center gap-2 px-2 py-1.5">
              <template v-if="s.state === 'club'">
                <span class="slot-disc"><AppImage :src="s.club!.crest_url" alt="" class="size-8" :size="32" crest /></span>
                <b class="line-clamp-2 min-w-0 text-start font-display text-sm leading-tight">{{ $nm(s.club!.name) }}</b>
              </template>
              <template v-else-if="s.state === 'waiting'">
                <span class="text-xl" aria-hidden="true">⏳</span>
                <span class="text-caption text-text-muted">{{ $t('ينتظر موافقة المنشئ') }}</span>
              </template>
            </span>
            <span v-if="s.state === 'club'" class="slot-foot" :class="s.next_match?.live ? 'is-live' : ''">
              <!-- [Sprint 20 W1] Within a day, the countdown itself. -->
              <template v-if="s.next_match">{{ s.next_match.live ? '● ' + $t('مباشر الآن') : soon(s.next_match.scheduled_at) ? countdown(s.next_match.scheduled_at, now) : when(s.next_match.scheduled_at) }} · {{ $t(s.next_match.venue === 'home' ? $t('ضد') : $t('عند')) }} {{ $nm(s.next_match.opponent) }}</template>
              <template v-else>{{ $t('لا مباريات قادمة') }}</template>
            </span>
          </button>
          </template>
        </div>
        <!-- [X86] Only the next locked slot shows; the others behind one line. -->
        <button v-if="lockedHidden" type="button" class="flex min-h-touch items-center justify-center gap-2 rounded-xl border border-dashed border-text/15 text-sm text-text-muted hover:text-text" @click="allSlots = true">
          🔒 {{ $t('و{v0} فتحات مقفلة أخرى', { v0: lockedHidden }) }} <span aria-hidden="true">▾</span>
        </button>
      </section>
      <!-- [Sprint 30 Q9, Sprint 56 W8] The next match, under the slots: who, when (counting down), and the way to get ready. -->
      <section v-if="nextUp?.next_match" class="next-hero flex flex-col gap-3 rounded-2xl border border-gold/30 p-4" :aria-label="$t('مباراتك القادمة')">
        <div class="flex items-center justify-between gap-2 text-sm">
          <b class="text-gold">{{ nextUp.next_match.live ? '● ' + $t('مباشر الآن') : $t('مباراتك القادمة') }}</b>
          <span class="text-text-muted">{{ when(nextUp.next_match.scheduled_at) }}</span>
        </div>
        <div class="flex items-center gap-3">
          <AppImage v-if="nextUp.club" :src="nextUp.club.crest_url" alt="" class="size-12 shrink-0" :size="48" crest />
          <span class="min-w-0 flex-1">
            <b class="block truncate font-display text-lg">{{ $nm(nextUp.club?.name) }}</b>
            <span class="block truncate text-sm text-text-muted">{{ $t(nextUp.next_match.venue === 'home' ? 'ضد' : 'عند') }} {{ $nm(nextUp.next_match.opponent) }}</span>
          </span>
          <b v-if="!nextUp.next_match.live" class="shrink-0 font-numbers text-3xl text-gold" dir="ltr">{{ countdown(nextUp.next_match.scheduled_at, now) || $t('الآن') }}</b>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <UiButton @click="goClub(nextUp, '/lineup')">{{ $t('التشكيلة') }}</UiButton>
          <UiButton variant="outline" @click="goClub(nextUp, '/tactics')">{{ $t('التكتيك') }}</UiButton>
        </div>
      </section>


      </div>

      <div class="home-side flex min-w-0 flex-col gap-4">
      <!-- [Sprint 30 P6] The starter coins, until claimed; and the first friendly is free. -->
      <section v-if="!home.starter_gift.claimed" class="flex animate-fade-up items-center gap-3 rounded-2xl border border-gold/40 bg-gold/10 p-4" :aria-label="$t('هدية البداية')">
        <span class="pulse-ring size-12 shrink-0 rounded-full"><AppImage src="/brand/coin.svg" alt="" class="size-12" :size="48" /></span>
        <span class="min-w-0 flex-1">
          <b class="block font-display text-lg">{{ $t('هدية البداية: {v0} كوينز', { v0: home.starter_gift.coins }) }}</b>
          <span class="text-sm text-text-muted">{{ $t('وأول ودية لك مجانية. استلمها وابدأ.') }}</span>
        </span>
        <UiButton :loading="claiming" @click="claimStarter">{{ $t('استلم مكافأتك') }}</UiButton>
      </section>

      <!-- [X61] A new coach's first steps, until they are all done (or hidden). -->
      <!-- [Sprint 55 W3] The verification: a card here (and a dot on the account), no longer a strip across every screen. -->
      <RouterLink v-if="auth.user && !auth.user.verification?.verified" to="/profile" class="ui-card verify-card flex min-h-touch items-center gap-3 rounded-xl px-4 py-3">
        <span class="text-2xl" aria-hidden="true">🎁</span>
        <span class="min-w-0 flex-1"><b class="block">{{ $t('وثّق حسابك') }}</b>
          <span class="text-caption text-text-muted">{{ $t('مكافأة {n} كوينز تنتظرك.', { n: auth.user.verification?.welcome_coins ?? 0 }) }}</span></span>
        <span class="font-bold text-gold">{{ $t('وثّق') }} ›</span>
      </RouterLink>
      <OnboardingChecklist :has-club="home.slots.some((s) => s.state === 'club')" :steps="home.onboarding" />

      <details class="home-more" :open="moreOpen" @toggle="(e: Event) => setMore((e.target as HTMLDetailsElement).open)">
        <summary class="ui-card flex min-h-touch cursor-pointer list-none items-center justify-between gap-2 rounded-xl px-4 font-bold">
          <span>{{ $t('المزيد') }} <span class="text-xs font-normal text-text-muted">{{ $t('الإعلانات والأوسمة والترتيب') }}</span></span>
          <span class="more-chevron text-text-muted" aria-hidden="true">▾</span>
        </summary>
      <aside class="mt-3 grid gap-3 md:grid-cols-2" :aria-label="$t('آخر الأخبار')">
        <!-- [Sprint 30 G7] The game as an app on the home screen. -->
        <InstallPrompt />
        <!-- [Sprint 30 G1] The match reminder: allowed from here, once. -->
        <ReminderPrompt v-if="home.slots.some((s) => s.state === 'club')" />

        <!-- The developers' announcements: updates and news [X11, X18]. -->
        <section class="flex flex-col gap-1 rounded-xl bg-gradient-to-l from-bronze/60 via-surface-raised to-surface p-3" :aria-label="$t('الإعلانات')">
          <div class="flex items-center gap-2 text-sm font-bold"><svg viewBox="0 0 24 24" class="size-5 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1ZM16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14" /></svg>{{ $t('الإعلانات') }}
            <span v-if="home.announcements.length > 1" class="ms-auto flex gap-1">
              <button v-for="(a, i) in home.announcements" :key="a.id" type="button" class="size-touch rounded-full" :aria-label="$t('الإعلان {n}', { n: i + 1 })" @click="announcement = i"><span class="mx-auto block size-2 rounded-full" :class="i === announcement ? 'bg-gold' : 'bg-text/30'" /></button>
            </span>
          </div>
          <template v-if="latest">
            <!-- [X54] The announcements page, each as a card. -->
            <RouterLink to="/announcements" class="flex flex-col gap-0.5">
              <b class="font-display">{{ $t(latest.title) }}</b>
              <span class="line-clamp-2 text-sm text-text-soft">{{ latest.body }}</span>
              <span class="text-xs text-text-muted">{{ latest.sender?.name }} <OfficialBadge v-if="latest.sender?.official" /> · {{ when(latest.created_at) }}</span>
            </RouterLink>
          </template>
          <p v-else class="text-sm text-text-muted">{{ $t('لا إعلانات بعد. هنا تصلك تحديثات اللعبة وأخبارها من فريق التطوير.') }}</p>
          <RouterLink v-if="latest" to="/announcements" class="self-end text-xs font-bold text-gold">{{ $t('كل الإعلانات ›') }}</RouterLink>
        </section>

        <!-- [Sprint 30 G4] The badges: earned ones lit, the rest with how far there is to go. -->
        <section v-if="badges.length" class="ui-card flex flex-col gap-2 rounded-xl p-3" :aria-label="$t('أوسمتي')">
          <h2 class="flex items-center justify-between px-1 font-display text-base font-extrabold">{{ $t('أوسمتي') }}
            <span class="font-numbers text-sm text-gold">{{ badges.filter((b) => b.earned).length }}/{{ badges.length }}</span></h2>
          <div v-for="tier in byTier" :key="tier.key" class="flex flex-col gap-1.5">
          <h3 class="flex items-center gap-2 px-1 text-xs font-bold text-text-soft">{{ $t('مستوى {v0}', { v0: $t(tier.label) }) }}
            <span class="rounded-pill bg-gold/15 px-2 font-numbers text-gold">{{ $t('{v0} كوينز للوسام', { v0: tier.badges[0].reward }) }}</span></h3>
          <ul class="grid grid-cols-4 gap-2">
            <li v-for="b in tier.badges" :key="b.key" class="flex flex-col items-center gap-1 rounded-lg p-1.5 text-center" :class="b.earned ? 'bg-gold/15' : 'bg-surface-sunk opacity-70'"
              :title="$t(BADGES[b.key][1]) + ' · ' + b.progress + '/' + b.goal">
              <span class="text-2xl" :class="b.earned ? '' : 'grayscale'" aria-hidden="true">{{ BADGES[b.key][0] }}</span>
              <span class="line-clamp-2 text-caption font-bold leading-tight">{{ $t(BADGES[b.key][1]) }}</span>
              <span v-if="!b.earned" class="h-1 w-full overflow-hidden rounded-pill bg-bg/50" role="progressbar" :aria-valuenow="b.progress" :aria-valuemax="b.goal" :aria-label="$t(BADGES[b.key][1])">
                <span class="block h-full rounded-pill bg-gold" :style="{ width: `${Math.round((b.progress / b.goal) * 100)}%` }" /></span>
            </li>
          </ul>
          </div>
        </section>
        <!-- [Sprint 28] An open poll waiting for this coach's vote, else the way to suggest a feature. -->
        <RouterLink to="/ideas" class="flex min-h-touch items-center gap-3 rounded-xl p-3" :class="home.polls_waiting ? 'bg-gold/15 ring-1 ring-gold/40' : 'bg-surface'">
          <Icon name="idea" :size="22" class="shrink-0 text-gold" />
          <span class="min-w-0 flex-1 text-sm"><b class="block">{{ home.polls_waiting ? $t('تصويت مفتوح على الميزة القادمة') : $t('اقتراحات التطوير') }}</b>
            <span class="text-xs text-text-muted">{{ home.polls_waiting ? $t('صوتك يحدد ما نبنيه أولاً') : $t('اقترح فكرة، وقد تأخذ مكافأة كوينز') }}</span></span>
          <span v-if="home.polls_waiting" class="rounded-pill bg-live px-2 font-numbers text-xs font-bold text-white">{{ home.polls_waiting }}</span>
        </RouterLink>

        <div class="grid grid-cols-4 gap-2 xl:grid-cols-2">
          <div class="home-tile">
            <b class="font-numbers text-xl" dir="ltr">{{ home.coach.record.won }}<span class="text-xs text-text-muted">/{{ home.coach.record.played }}</span></b>
            <span class="text-caption text-text-muted">{{ $t('فوز') }}</span>
          </div>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <b class="font-numbers text-xl text-gold">{{ home.trophies.total }}</b>
            <span class="text-caption text-text-muted">{{ $t('الكؤوس') }}</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4ZM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4" /></svg>
            <span class="text-caption font-bold">{{ $t('لوحة الشرف') }}</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('rating')">
            <RatingBadge :tier="home.coach.rating.tier.key" :division="home.coach.rating.tier.division" :size="22" />
            <span class="text-caption font-bold">{{ $t('ترتيب النقاط') }}</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('level')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" /></svg>
            <span class="text-caption font-bold">{{ $t('المستويات') }}</span>
          </button>
        </div>
        <!-- Quick ways in. -->
        <nav class="grid grid-cols-2 gap-2" :aria-label="$t('اختصارات')">
          <RouterLink to="/leagues/new" class="home-tile"><span class="text-xl" aria-hidden="true">🏟️</span><span class="text-xs font-bold">{{ $t('أنشئ دورياً') }}</span></RouterLink>
          <RouterLink :to="{ name: 'join' }" class="home-tile"><span class="text-xl" aria-hidden="true">🔑</span><span class="text-xs font-bold">{{ $t('انضم بكود') }}</span></RouterLink>
          <RouterLink to="/wallet" class="home-tile"><AppImage src="/brand/coin.svg" alt="" class="size-6" :size="24" /><span class="text-xs font-bold">{{ $t('المحفظة') }}</span></RouterLink>
          <RouterLink to="/profile" class="home-tile"><span class="text-xl" aria-hidden="true">🎁</span><span class="text-xs font-bold">{{ $t('ادعُ أصدقاءك') }}</span></RouterLink>
        </nav>
      </aside>
      </details>
      </div>
    </div>
    <!-- [Sprint 56 W11] The slots' shape while the home screen loads. -->
    <AsyncState v-else-if="!error" loading skeleton="card" :rows="2" />
    <!-- [X57] One Google ad at the bottom of the home screen, away from the slots' buttons. -->
    <AdSlot v-if="home" class="relative mt-4" />

    <!-- The global ranking [X18]. -->
    <UiDialog :open="!!(ranking || rankingBusy)" wide closable :title="ranking?.by === 'level' ? 'ترتيب المستويات' : ranking?.by === 'rating' ? 'ترتيب النقاط' : 'لوحة شرف المدربين'" @close="ranking = null"><div v-if="ranking || rankingBusy" class="flex flex-col gap-3">
        <p v-if="rankingBusy" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
        <template v-else-if="ranking">
          <UiTabs :model-value="ranking.by" :items="RANK_TABS" label="ترتيب المدربين" fill size="sm" @update:model-value="openRanking" />
          <div v-for="r in ranking.coaches" :key="r.coach.id" class="flex min-h-touch items-center gap-3 border-t border-text/5" :class="r.coach.id === auth.user?.id ? 'text-gold' : ''">
            <span class="w-7 text-center font-numbers text-text-muted">{{ r.position }}</span>
            <RouterLink :to="{ name: 'coach', params: { id: r.coach.id } }" class="min-w-0 flex-1 truncate font-bold">{{ r.coach.name }} <OfficialBadge v-if="r.coach.official" /><VerifiedBadge v-else-if="r.coach.verified" /></RouterLink>
            <template v-if="ranking.by === 'rating'">
              <RatingBadge :tier="r.rating.tier" :division="r.rating.division" :size="20" />
              <b class="font-numbers" dir="ltr">{{ r.rating.points }}</b>
            </template>
            <template v-else>
              <span class="text-xs text-text-muted">{{ $t('م{n}', { n: r.level }) }}</span>
              <b class="font-numbers">🏆 {{ r.trophies.total }}</b>
            </template>
          </div>
          <p v-if="ranking.me && ranking.me.position > 50" class="border-t border-gold/40 pt-2 text-sm">{{ $t('مركزك:') }} <b class="font-numbers">{{ ranking.me.position }}</b></p>
          <p v-if="!ranking.coaches.length" class="text-text-muted">{{ $t('لا مدربين بعد.') }}</p>
        </template>
    </div></UiDialog>

    <!-- [Sprint 25] The rating's sheet: the emblem and the points, the way to the next division, the seven tiers, and
         the latest changes. How the points are counted is in the assistant's guide. -->
    <UiDialog :open="!!(ratingOpen && rating && home)" wide closable title="نقاط المدرب ودرجته" @close="ratingOpen = false"><div v-if="ratingOpen && rating && home" class="flex flex-col gap-4">
        <div class="rating-hero" :class="`is-${rating.tier.key}`">
          <RatingBadge :tier="rating.tier.key" :division="rating.tier.division" :size="72" />
          <div class="flex min-w-0 flex-1 flex-col gap-1">
            <b class="font-display text-2xl leading-tight">{{ tierName(rating.tier.key) }} <span class="font-numbers" dir="ltr">{{ divisionName(rating.tier.division) }}</span></b>
            <span class="text-sm text-text-soft"><b class="font-numbers text-lg text-gold" dir="ltr">{{ rating.points }}</b> {{ $t('نقطة') }}</span>
            <template v-if="rating.tier.next !== null">
              <div class="h-2 overflow-hidden rounded-pill bg-surface-sunk" role="progressbar" :aria-valuenow="rating.tier.progress_bp / 100" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('التقدم إلى الدرجة التالية')">
                <div class="h-full rounded-pill bg-gold" :style="{ width: rating.tier.progress_bp / 100 + '%' }" />
              </div>
              <span class="text-caption text-text-muted">{{ $t('{n} نقطة للمستوى التالي', { n: rating.tier.next - rating.points }) }}</span>
            </template>
            <span v-else class="text-xs font-bold text-gold">{{ $t('بلغت القمة') }}</span>
          </div>
        </div>
        <p class="text-caption text-text-muted">{{ $t('أعلى ما بلغت: {n} نقطة', { n: rating.peak }) }}</p>

        <!-- The ladder, top tier first: those reached in colour, the current one marked. -->
        <ol class="flex flex-col gap-1.5" :aria-label="$t('الدرجات')">
          <li v-for="tier in [...home.rating_tiers].reverse()" :key="tier.key" class="flex min-h-touch items-center gap-3 rounded-lg px-2"
            :class="tier.key === rating.tier.key ? 'bg-gold/15 ring-1 ring-gold/60' : ''">
            <RatingBadge :tier="tier.key" :division="tier.key === rating.tier.key ? rating.tier.division : null" :size="28" :dim="tier.min > rating.points" />
            <span class="flex-1 font-bold" :class="tier.min > rating.points ? 'text-text-muted' : ''">{{ tierName(tier.key) }}</span>
            <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ tier.min }}+</span>
          </li>
        </ol>

        <div class="flex flex-col gap-1">
          <h3 class="font-bold">{{ $t('آخر التغييرات') }}</h3>
          <p v-if="!rating.recent.length" class="text-sm text-text-muted">{{ $t('تبدأ نقاطك مع أول مباراة لناديك.') }}</p>
          <div v-for="(c, i) in rating.recent" :key="i" class="flex min-h-touch items-center gap-3 border-t border-text/5 text-sm">
            <b class="w-11 text-center font-numbers" :class="c.delta > 0 ? 'text-success' : c.delta < 0 ? 'text-danger' : 'text-text-muted'" dir="ltr">{{ signed(c.delta) }}</b>
            <span v-if="c.kind === 'trophy'" class="flex-1">🏆 {{ c.competition === 'cup' ? $t('الكأس: المركز {n}', { n: c.position ?? 0 }) : $t('الدوري: المركز {n}', { n: c.position ?? 0 }) }}</span>
            <template v-else>
              <span class="min-w-0 flex-1 truncate">{{ $t(c.result === 'win' ? 'فوز على {o}' : c.result === 'draw' ? 'تعادل مع {o}' : 'خسارة أمام {o}', { o: c.opponent ?? '' }) }}</span>
              <b class="font-numbers" dir="ltr">{{ c.for }}-{{ c.against }}</b>
            </template>
            <span v-if="c.competition === 'cup' && c.kind === 'match'" class="text-caption text-text-muted">{{ $t('الكأس') }}</span>
          </div>
        </div>
    </div></UiDialog>

    <!-- [Sprint 24 B3] The confirmation before the coins go, or the way to more coins when they are short. -->
    <UiDialog :open="!!(buying && home)" title="فتح فوري" @close="buying = null"><div v-if="buying && home" class="flex flex-col gap-4 text-center">
      <span class="text-4xl" aria-hidden="true">🔓</span>
      <p class="font-bold">{{ $t('هل أنت متأكد من فتح الفتحة رقم {v0} فوراً مقابل {v1} كوينز؟', { v0: buying.slot, v1: buying.unlock_coins }) }}</p>
      <p class="text-sm text-text-muted">{{ $t('رصيدك') }}: <b class="font-numbers" dir="ltr">{{ home.coach.coins }}</b></p>
      <p v-if="buyError" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger">{{ $t(buyError) }}</p>
      <div class="flex gap-2">
        <UiButton v-if="home.coach.coins >= (buying.unlock_coins ?? 0)" class="flex-1" :loading="buyBusy" @click="unlock">{{ $t('افتحها الآن') }}</UiButton>
        <UiButton v-else to="/wallet" class="flex-1">{{ $t('رصيدك لا يكفي: اشحن الكوينز') }}</UiButton>
        <UiButton variant="quiet" class="flex-1" @click="buying = null">{{ $t('إلغاء') }}</UiButton>
      </div>
    </div></UiDialog>
  </div>
</template>

<style scoped>
.home-grid { display: grid; gap: var(--space-lg); grid-template-columns: minmax(0, 1fr); max-width: 56rem; }
@media (min-width: 1200px) { .home-grid { max-width: none; grid-template-columns: minmax(0, 1.6fr) minmax(0, 1fr); align-items: start; } }
.verify-card { border: 1px solid color-mix(in srgb, var(--color-warning) 45%, transparent); }
/* [X86] «المزيد»: its arrow turns when open. */
.home-more summary::-webkit-details-marker { display: none; }
.more-chevron { transition: transform 0.2s; }
.home-more[open] .more-chevron { transform: rotate(180deg); }
.rating-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  align-self: flex-start;
  max-width: 100%;
  min-height: 2.75rem;
  padding: 0 0.6rem;
  border-radius: 999px;
  background: color-mix(in srgb, var(--color-surface-raised) 80%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-gold) 35%, transparent);
}
.rating-hero {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-radius: 1rem;
  background: radial-gradient(circle at 15% 40%, color-mix(in srgb, var(--tier) 35%, transparent), transparent 65%), var(--color-surface-raised);
  border: 1px solid color-mix(in srgb, var(--tier) 50%, transparent);
}
.rating-hero.is-prospect { --tier: var(--color-text-muted); }
.rating-hero.is-tactician { --tier: var(--color-bronze); }
.rating-hero.is-professional { --tier: var(--color-silver); }
.rating-hero.is-elite { --tier: var(--color-gold); }
.rating-hero.is-mastermind { --tier: var(--color-brand); }
.rating-hero.is-icon { --tier: var(--color-live); }
.rating-hero.is-legend { --tier: var(--color-gold-light); animation: legend-glow 2.4s ease-in-out infinite alternate; }
@keyframes legend-glow { to { box-shadow: 0 0 26px 2px color-mix(in srgb, var(--color-gold) 45%, transparent); } }
@media (prefers-reduced-motion: reduce) { .rating-hero.is-legend { animation: none; } }
.slot-card {
  position: relative;
  display: flex;
  flex-direction: column;
  min-height: 5.25rem;
  overflow: hidden;
  border-radius: 0.85rem;
  text-align: center;
  background: color-mix(in srgb, var(--color-panel) 88%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 22%, transparent);
  box-shadow: 0 14px 30px -18px color-mix(in srgb, var(--color-shade) 80%, transparent);
  transition: transform 0.15s ease;
}
.slot-card:hover { transform: scale(1.03); border-color: var(--color-brand-light); }
@media (min-width: 1024px) { .slot-card { min-height: 8.5rem; } }
@media (min-width: 1536px) { .slot-card { min-height: 10.5rem; } .slot-disc { width: 3.5rem; height: 3.5rem; } }
.slot-card.is-free { border-style: dashed; background: color-mix(in srgb, var(--color-panel) 60%, transparent); }
.slot-card.is-locked { opacity: 0.75; background: color-mix(in srgb, var(--color-panel) 45%, transparent); }
.slot-card.is-locked.is-next { opacity: 1; border-color: color-mix(in srgb, var(--color-gold) 55%, transparent); }
.slot-card.is-opened { animation: slot-open 1.5s ease-out; }
@keyframes slot-open {
  0% { transform: scale(0.9); box-shadow: 0 0 0 0 color-mix(in srgb, var(--color-gold) 80%, transparent); }
  40% { transform: scale(1.06); box-shadow: 0 0 28px 6px color-mix(in srgb, var(--color-gold) 60%, transparent); }
  100% { transform: scale(1); box-shadow: none; }
}
@media (prefers-reduced-motion: reduce) { .slot-card.is-opened { animation: none; } }
.slot-card.is-locked:hover { transform: none; border-color: color-mix(in srgb, var(--color-brand-light) 22%, transparent); }
.slot-band {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.3rem 0.6rem;
  color: var(--color-text);
  background: color-mix(in srgb, var(--color-text) 10%, transparent);
}
.slot-card.is-club .slot-band { color: var(--color-broadcast-white); background: url("/art/pattern-star.svg") center / 40px 40px repeat, linear-gradient(180deg, var(--color-brand), var(--color-brand-dark)); background-blend-mode: soft-light, normal; }
.slot-card.is-waiting .slot-band { background: color-mix(in srgb, var(--color-warning) 35%, transparent); }
.slot-disc {
  display: grid;
  place-items: center;
  flex-shrink: 0;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: 999px;
  background: radial-gradient(circle at 50% 30%, var(--color-broadcast-white), var(--color-chrome) 55%, var(--color-chrome-dark));
  box-shadow: 0 8px 18px -8px color-mix(in srgb, var(--color-shade) 80%, transparent);
}
.slot-foot {
  padding: 0.35rem 0.5rem;
  font-size: var(--text-caption);
  font-weight: 700;
  color: var(--color-on-chrome);
  background: linear-gradient(180deg, var(--color-broadcast-white), var(--color-chrome));
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.slot-foot.is-live { color: var(--color-broadcast-white); background: var(--color-live); }
.coach-card {
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 1rem;
  background: linear-gradient(120deg, color-mix(in srgb, var(--color-gold) 22%, var(--color-panel)), var(--color-panel) 60%);
  border: 1px solid color-mix(in srgb, var(--color-gold) 25%, transparent);
}
@media (min-width: 768px) { .coach-card { gap: 1.25rem; padding: 1.25rem 1.5rem; } }
.coach-card::after {
  content: "";
  position: absolute;
  inset-inline-end: -3rem;
  top: -3rem;
  width: 11rem;
  height: 11rem;
  border-radius: 999px;
  background: color-mix(in srgb, var(--color-gold) 10%, transparent);
  pointer-events: none;
}
.home-tile {
  display: flex;
  min-height: 4.25rem;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.15rem;
  border-radius: 0.75rem;
  text-align: center;
  background: color-mix(in srgb, var(--color-panel) 88%, transparent);
  transition: transform 0.15s ease;
}
button.home-tile:hover { transform: scale(1.03); box-shadow: 0 8px 18px -12px color-mix(in srgb, var(--color-shade) 80%, transparent); }
/* [Sprint 30 Q9] The next match's card: the night pitch's green under the gold, our signature. */
.next-hero { background: linear-gradient(160deg, color-mix(in srgb, var(--color-brand) 30%, var(--color-surface)), var(--color-surface) 70%); }
</style>
