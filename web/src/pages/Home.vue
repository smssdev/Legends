<script setup lang="ts">
// The coach's home screen [X18], rebuilt by updates1 UP7 (2026-10-26): the coach's card on top (picture, name, level,
// cash and coins) and the ten club slots right under it, all in one screen without scrolling; the announcements, the
// record, the trophies and the rankings below. A guest sees the way in.
import { countdown, useNow } from '../lib/clock'
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError } from '../api/client'
import type { components } from '../api/schema'
import BrandMark from '../components/BrandMark.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import VerifiedBadge from '../components/VerifiedBadge.vue'
import ChalkBackdrop from '../components/ChalkBackdrop.vue'
import HelpTip from '../components/ui/HelpTip.vue'
import { money } from '../lib/format'
import { intlLocale, t } from '../lib/i18n'
import { rememberLeague } from '../lib/currentLeague'
import { useAuth } from '../stores/auth'

type Home = components['schemas']['HomeScreen']
type Ranked = components['schemas']['RankedCoach']
const auth = useAuth()
const router = useRouter()
const home = ref<Home | null>(null)
const error = ref('')
const announcement = ref(0)
const ranking = ref<{ by: 'trophies' | 'level'; coaches: Ranked[]; me: Ranked | null } | null>(null)
const rankingBusy = ref(false)

const latest = computed(() => home.value?.announcements[announcement.value] ?? null)
// The hero's greeting by the device's hour, and the soonest match among the slots.
const greeting = computed(() => (new Date().getHours() < 12 ? t('صباح الخير يا كوتش') : new Date().getHours() < 18 ? t('نهارك سعيد يا كوتش') : t('مساء الخير يا كوتش')))
const nextUp = computed(() => home.value?.slots.filter((s) => s.next_match).sort((a, b) => (a.next_match!.live ? -1 : 0) - (b.next_match!.live ? -1 : 0) || a.next_match!.scheduled_at.localeCompare(b.next_match!.scheduled_at))[0] ?? null)
// The cash shown on the card: the club of the soonest match, else the first club.
const cashClub = computed(() => nextUp.value?.club ?? home.value?.slots.find((s) => s.club)?.club ?? null)
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
function openSlot(s: Home['slots'][number]) {
  if (s.state === 'waiting') return router.push(`/leagues/${s.league!.id}`)
  rememberLeague(s.league!.id)
  // [Sprint 20 W1] A club's slot opens its club board.
  router.push('/club')
}

async function openRanking(by: 'trophies' | 'level') {
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
  <div v-if="!auth.user" class="flex flex-col items-center gap-5 py-10 text-center">
    <BrandMark />
    <h1 class="font-display text-3xl font-extrabold">{{ $t('درّب ناديك المفضل مع أصحابك') }}</h1>
    <p class="max-w-md text-text-soft">{{ $t('دوريات خاصة، ومباريات تديرها مباشرة، وحتى عشرة أندية في وقت واحد.') }}</p>
    <div class="flex gap-3">
      <RouterLink to="/register" class="flex h-12 items-center rounded-lg bg-gold px-6 font-bold text-on-gold">{{ $t('أنشئ حساباً') }}</RouterLink>
      <RouterLink to="/login" class="flex h-12 items-center rounded-lg bg-surface px-6 font-bold">{{ $t('دخول') }}</RouterLink>
    </div>
  </div>

  <div v-else class="flex flex-col gap-4">
    <!-- [Sprint 21 E3.4] The coach's chalkboard behind the home screen. -->
    <ChalkBackdrop />
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ $t(error) }}</p>
    <!-- [Sprint 21 E3.4] On a computer two columns fill the screen: the card and the slots, and beside them the
         announcements, the record and quick ways in. On a phone the same in one column. -->
    <div v-if="home" class="relative grid gap-4 xl:grid-cols-[minmax(0,1fr)_22rem] xl:gap-6">
      <div class="flex min-w-0 flex-col gap-4">
      <!-- [UP7] The coach's card on top: the picture, the name, the level, the club's cash and the coins. -->
      <section class="coach-card" :aria-label="$t('ملف المدرب')">
        <RouterLink to="/profile" class="shrink-0" :aria-label="$t('حسابي')">
          <img v-if="home.coach.avatar_url" :src="home.coach.avatar_url" alt="" class="size-14 rounded-full border-2 border-gold object-cover md:size-20" />
          <span v-else class="grid size-14 place-items-center rounded-full border-2 border-gold bg-surface-raised font-display text-2xl font-extrabold md:size-20 md:text-3xl">{{ home.coach.name.charAt(0) }}</span>
        </RouterLink>
        <div class="flex min-w-0 flex-1 flex-col gap-1">
          <span class="text-xs font-bold text-gold">{{ greeting }}</span>
          <b class="truncate font-display text-lg leading-tight md:text-xl">{{ home.coach.name }} <OfficialBadge v-if="home.coach.official" /><VerifiedBadge v-else-if="home.coach.verified" /></b>
          <div class="flex items-center gap-2">
            <span class="grid size-7 shrink-0 place-items-center rounded-md bg-[#B4692A] font-numbers text-sm font-extrabold text-white" :title="$t('المستوى {n}', { n: home.coach.level.level })">{{ home.coach.level.level }}</span>
            <div class="h-1.5 max-w-40 flex-1 overflow-hidden rounded-pill bg-surface-sunk" role="progressbar" :aria-valuenow="home.coach.level.progress_bp / 100" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('التقدم إلى المستوى التالي')">
              <div class="h-full rounded-pill bg-success" :style="{ width: home.coach.level.progress_bp / 100 + '%' }" />
            </div>
            <span class="font-numbers text-[11px] text-text-muted" dir="ltr">{{ home.coach.level.xp }}/{{ home.coach.level.next }}</span>
          </div>
        </div>
        <div class="flex shrink-0 flex-col items-end gap-1.5">
          <RouterLink to="/wallet" class="flex items-center gap-1 rounded-pill bg-gold/15 px-2.5 py-1 text-sm font-bold" :aria-label="$t('الكوينز')">
            <img src="/brand/coin.svg" alt="" class="size-4" /><span class="font-numbers" dir="ltr">{{ home.coach.coins }}</span>
          </RouterLink>
          <span v-if="cashClub" class="flex items-center gap-1 rounded-pill bg-brand/25 px-2.5 py-1 text-sm font-bold" :title="$t('أموال {club}', { club: $nm(cashClub.name) })" :aria-label="$t('أموال {club}', { club: $nm(cashClub.name) })">
            <span aria-hidden="true">💵</span><span class="font-numbers" dir="ltr">{{ money(cashClub.cash) }}</span>
          </span>
        </div>
      </section>

      <!-- The slots, the screen's heart, right under the card: all ten without scrolling. -->
      <section class="flex flex-col gap-2" :aria-label="$t('فتحات المدرب')">
        <h2 class="flex items-center text-sm font-bold text-text-muted">{{ $t('فتحات المدرب') }} <HelpTip :label="$t('الفتحات')" :text="$t('لك عشر فتحات: في كل واحدة نادٍ في دوري. اضغط فتحة ناديك لتدخلها، أو فتحة فارغة لتنضم إلى دوري أو تنشئ دوريك.')" /></h2>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-5 lg:gap-3">
          <!-- [X32] Each slot a card: a band with its number and league (blue for a club), the crest on a ivory disc,
               and the next match at its foot. -->
          <template v-for="s in home.slots" :key="s.slot">
          <!-- [Sprint 20 W1] An empty slot: «أنشئ دورياً» at once, and «انضم بكود». -->
          <div v-if="s.state === 'free'" class="slot-card is-free" role="group" :aria-label="$t('الفتحة {n}: دوري جديد', { n: s.slot })">
            <span class="slot-band"><b class="font-numbers text-sm">{{ s.slot }}</b><span class="min-w-0 flex-1 truncate text-start text-[11px] font-bold">{{ $t('فتحة فارغة') }}</span></span>
            <span class="flex flex-1 flex-col justify-center gap-1.5 p-2">
              <RouterLink to="/leagues/new" class="flex min-h-10 items-center justify-center rounded-lg bg-gold text-sm font-bold text-on-gold">{{ $t('أنشئ دورياً') }}</RouterLink>
              <RouterLink to="/join" class="flex min-h-10 items-center justify-center rounded-lg bg-surface-raised text-sm font-bold">{{ $t('انضم بكود') }}</RouterLink>
            </span>
          </div>
          <button v-else type="button" class="slot-card group" :class="`is-${s.state}`"
            :aria-label="$t('الفتحة {n}: {league}', { n: s.slot, league: s.league?.name ?? '' }) + (s.pending ? ' · ' + $t('ما ينتظرك: {n}', { n: s.pending }) : '')" @click="openSlot(s)">
            <span class="slot-band">
              <b class="font-numbers text-sm">{{ s.slot }}</b>
              <span class="min-w-0 flex-1 truncate text-start text-[11px] font-bold">{{ s.league!.name }}</span>
              <span v-if="s.position" class="rounded bg-black/30 px-1 font-numbers text-[11px]" dir="ltr">{{ s.position }}/{{ s.teams }}</span>
              <span v-if="s.pending" class="min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-[11px] text-white" :title="$t('ما ينتظرك')">{{ s.pending }}</span>
            </span>
            <span class="flex flex-1 items-center justify-center gap-2 px-2 py-1.5">
              <template v-if="s.state === 'club'">
                <span class="slot-disc"><img :src="s.club!.crest_url" alt="" class="size-8" /></span>
                <b class="line-clamp-2 min-w-0 text-start font-display text-sm leading-tight">{{ $nm(s.club!.name) }}</b>
              </template>
              <template v-else-if="s.state === 'waiting'">
                <span class="text-xl" aria-hidden="true">⏳</span>
                <span class="text-[11px] text-text-muted">{{ $t('ينتظر موافقة المنشئ') }}</span>
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
      </section>
      </div>

      <aside class="flex flex-col gap-3" :aria-label="$t('آخر الأخبار')">

        <!-- The developers' announcements: updates and news [X11, X18]. -->
        <section class="flex flex-col gap-1 rounded-xl bg-gradient-to-l from-[#B4692A]/60 via-surface-raised to-surface p-3" :aria-label="$t('الإعلانات')">
          <div class="flex items-center gap-2 text-sm font-bold"><svg viewBox="0 0 24 24" class="size-5 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1ZM16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14" /></svg>{{ $t('الإعلانات') }}
            <span v-if="home.announcements.length > 1" class="ms-auto flex gap-1">
              <button v-for="(a, i) in home.announcements" :key="a.id" type="button" class="size-touch rounded-full" :aria-label="$t('الإعلان {n}', { n: i + 1 })" @click="announcement = i"><span class="mx-auto block size-2 rounded-full" :class="i === announcement ? 'bg-gold' : 'bg-text/30'" /></button>
            </span>
          </div>
          <template v-if="latest">
            <RouterLink to="/inbox" class="flex flex-col gap-0.5">
              <b class="font-display">{{ $t(latest.title) }}</b>
              <span class="line-clamp-2 text-sm text-text-soft">{{ latest.body }}</span>
              <span class="text-xs text-text-muted">{{ latest.sender?.name }} <OfficialBadge v-if="latest.sender?.official" /> · {{ when(latest.created_at) }}</span>
            </RouterLink>
          </template>
          <p v-else class="text-sm text-text-muted">{{ $t('لا إعلانات بعد. هنا تصلك تحديثات اللعبة وأخبارها من فريق التطوير.') }}</p>
        </section>

        <div class="grid grid-cols-4 gap-2 xl:grid-cols-2">
          <div class="home-tile">
            <b class="font-numbers text-xl" dir="ltr">{{ home.coach.record.won }}<span class="text-xs text-text-muted">/{{ home.coach.record.played }}</span></b>
            <span class="text-[11px] text-text-muted">{{ $t('فوز') }}</span>
          </div>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <b class="font-numbers text-xl text-gold">{{ home.trophies.total }}</b>
            <span class="text-[11px] text-text-muted">{{ $t('الكؤوس') }}</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4ZM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4" /></svg>
            <span class="text-[11px] font-bold">{{ $t('لوحة الشرف') }}</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('level')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" /></svg>
            <span class="text-[11px] font-bold">{{ $t('المستويات') }}</span>
          </button>
        </div>
        <!-- Quick ways in. -->
        <nav class="grid grid-cols-2 gap-2" :aria-label="$t('اختصارات')">
          <RouterLink to="/leagues/new" class="home-tile"><span class="text-xl" aria-hidden="true">🏟️</span><span class="text-xs font-bold">{{ $t('أنشئ دورياً') }}</span></RouterLink>
          <RouterLink :to="{ name: 'join' }" class="home-tile"><span class="text-xl" aria-hidden="true">🔑</span><span class="text-xs font-bold">{{ $t('انضم بكود') }}</span></RouterLink>
          <RouterLink to="/wallet" class="home-tile"><img src="/brand/coin.svg" alt="" class="size-6" /><span class="text-xs font-bold">{{ $t('المحفظة') }}</span></RouterLink>
          <RouterLink to="/profile" class="home-tile"><span class="text-xl" aria-hidden="true">🎁</span><span class="text-xs font-bold">{{ $t('ادعُ أصدقاءك') }}</span></RouterLink>
        </nav>
      </aside>
    </div>
    <p v-else-if="!error" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>

    <!-- The global ranking [X18]. -->
    <div v-if="ranking || rankingBusy" class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 p-3 md:items-center" role="dialog" aria-modal="true" :aria-label="$t('لوحة شرف المدربين')" @click.self="ranking = null">
      <div class="flex max-h-[85dvh] w-full max-w-lg flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-4">
        <div class="flex items-center gap-2">
          <h2 class="flex-1 font-display text-xl font-extrabold">{{ $t(ranking?.by === 'level' ? $t('ترتيب المستويات') : $t('لوحة شرف المدربين')) }}</h2>
          <button type="button" class="size-touch rounded-md bg-surface-raised" :aria-label="$t('إغلاق')" @click="ranking = null">✕</button>
        </div>
        <p v-if="rankingBusy" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
        <template v-else-if="ranking">
          <div class="flex gap-2">
            <button v-for="[k, l] in ([['trophies', 'بالكؤوس'], ['level', 'بالمستوى']] as const)" :key="k" type="button" class="h-touch rounded-pill px-4 text-sm font-bold" :class="ranking.by === k ? 'bg-gold text-on-gold' : 'bg-surface-raised'" @click="openRanking(k)">{{ $t(l) }}</button>
          </div>
          <div v-for="r in ranking.coaches" :key="r.coach.id" class="flex min-h-touch items-center gap-3 border-t border-text/5" :class="r.coach.id === auth.user?.id ? 'text-gold' : ''">
            <span class="w-7 text-center font-numbers text-text-muted">{{ r.position }}</span>
            <RouterLink :to="{ name: 'coach', params: { id: r.coach.id } }" class="min-w-0 flex-1 truncate font-bold">{{ r.coach.name }} <OfficialBadge v-if="r.coach.official" /><VerifiedBadge v-else-if="r.coach.verified" /></RouterLink>
            <span class="text-xs text-text-muted">{{ $t('م{n}', { n: r.level }) }}</span>
            <b class="font-numbers">🏆 {{ r.trophies.total }}</b>
          </div>
          <p v-if="ranking.me && ranking.me.position > 50" class="border-t border-gold/40 pt-2 text-sm">{{ $t('مركزك:') }} <b class="font-numbers">{{ ranking.me.position }}</b></p>
          <p v-if="!ranking.coaches.length" class="text-text-muted">{{ $t('لا مدربين بعد.') }}</p>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
  box-shadow: 0 14px 30px -18px rgb(0 0 0 / 0.8);
  transition: transform 0.15s ease;
}
.slot-card:hover { transform: scale(1.03); border-color: var(--color-brand-light); }
@media (min-width: 1024px) { .slot-card { min-height: 8.5rem; } }
@media (min-width: 1536px) { .slot-card { min-height: 10.5rem; } .slot-disc { width: 3.5rem; height: 3.5rem; } }
.slot-card.is-free { border-style: dashed; background: color-mix(in srgb, var(--color-panel) 60%, transparent); }
.slot-band {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.3rem 0.6rem;
  color: #fff;
  background: color-mix(in srgb, var(--color-text) 10%, transparent);
}
.slot-card.is-club .slot-band { background: url("/art/pattern-star.svg") center / 40px 40px repeat, linear-gradient(180deg, var(--color-brand), var(--color-brand-dark)); background-blend-mode: soft-light, normal; }
.slot-card.is-waiting .slot-band { background: color-mix(in srgb, var(--color-warning) 35%, transparent); }
.slot-disc {
  display: grid;
  place-items: center;
  flex-shrink: 0;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: 999px;
  background: radial-gradient(circle at 50% 30%, #ffffff, var(--color-chrome) 55%, var(--color-chrome-dark));
  box-shadow: 0 8px 18px -8px rgb(0 0 0 / 0.8);
}
.slot-foot {
  padding: 0.35rem 0.5rem;
  font-size: 0.7rem;
  font-weight: 700;
  color: var(--color-on-chrome);
  background: linear-gradient(180deg, #ffffff, var(--color-chrome));
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.slot-foot.is-live { color: #fff; background: var(--color-live); }
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
button.home-tile:hover { transform: scale(1.03); box-shadow: 0 8px 18px -12px rgb(0 0 0 / 0.8); }
</style>
