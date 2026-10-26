<script setup lang="ts">
// The coach's home screen [X18], rebuilt by updates1 UP7 (2026-10-26): the coach's card on top (picture, name, level,
// cash and coins) and the ten club slots right under it, all in one screen without scrolling; the announcements, the
// record, the trophies and the rankings below. A guest sees the way in.
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError } from '../api/client'
import type { components } from '../api/schema'
import BrandMark from '../components/BrandMark.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import HelpTip from '../components/ui/HelpTip.vue'
import { money } from '../lib/format'
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
const greeting = computed(() => (new Date().getHours() < 12 ? 'صباح الخير يا كوتش' : new Date().getHours() < 18 ? 'نهارك سعيد يا كوتش' : 'مساء الخير يا كوتش'))
const nextUp = computed(() => home.value?.slots.filter((s) => s.next_match).sort((a, b) => (a.next_match!.live ? -1 : 0) - (b.next_match!.live ? -1 : 0) || a.next_match!.scheduled_at.localeCompare(b.next_match!.scheduled_at))[0] ?? null)
// The cash shown on the card: the club of the soonest match, else the first club.
const cashClub = computed(() => nextUp.value?.club ?? home.value?.slots.find((s) => s.club)?.club ?? null)
const when = (iso: string) => new Intl.DateTimeFormat('ar-EG-u-nu-latn', { weekday: 'short', hour: 'numeric', minute: '2-digit' }).format(new Date(iso))

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

function openSlot(s: Home['slots'][number]) {
  if (s.state === 'free') return router.push('/leagues')
  if (s.state === 'waiting') return router.push(`/leagues/${s.league!.id}`)
  rememberLeague(s.league!.id)
  router.push('/team')
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
    <h1 class="font-display text-3xl font-extrabold">درّب ناديك المفضل مع أصحابك</h1>
    <p class="max-w-md text-text-soft">دوريات خاصة، ومباريات تديرها مباشرة، وحتى عشرة أندية في وقت واحد.</p>
    <div class="flex gap-3">
      <RouterLink to="/register" class="flex h-12 items-center rounded-lg bg-gold px-6 font-bold text-on-gold">أنشئ حساباً</RouterLink>
      <RouterLink to="/login" class="flex h-12 items-center rounded-lg bg-surface px-6 font-bold">دخول</RouterLink>
    </div>
  </div>

  <div v-else class="flex flex-col gap-4">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ error }}</p>
    <div v-if="home" class="relative flex flex-col gap-4">
      <!-- [UP7] The coach's card on top: the picture, the name, the level, the club's cash and the coins. -->
      <section class="coach-card" aria-label="ملف المدرب">
        <RouterLink to="/profile" class="shrink-0" aria-label="حسابي">
          <img v-if="home.coach.avatar_url" :src="home.coach.avatar_url" alt="" class="size-14 rounded-full border-2 border-gold object-cover md:size-16" />
          <span v-else class="grid size-14 place-items-center rounded-full border-2 border-gold bg-surface-raised font-display text-2xl font-extrabold md:size-16">{{ home.coach.name.charAt(0) }}</span>
        </RouterLink>
        <div class="flex min-w-0 flex-1 flex-col gap-1">
          <span class="text-xs font-bold text-gold">{{ greeting }}</span>
          <b class="truncate font-display text-lg leading-tight md:text-xl">{{ home.coach.name }} <OfficialBadge v-if="home.coach.official" /></b>
          <div class="flex items-center gap-2">
            <span class="grid size-7 shrink-0 place-items-center rounded-md bg-[#B4692A] font-numbers text-sm font-extrabold text-white" :title="`المستوى ${home.coach.level.level}`">{{ home.coach.level.level }}</span>
            <div class="h-1.5 max-w-40 flex-1 overflow-hidden rounded-pill bg-surface-sunk" role="progressbar" :aria-valuenow="home.coach.level.progress_bp / 100" aria-valuemin="0" aria-valuemax="100" aria-label="التقدم إلى المستوى التالي">
              <div class="h-full rounded-pill bg-success" :style="{ width: home.coach.level.progress_bp / 100 + '%' }" />
            </div>
            <span class="font-numbers text-[11px] text-text-muted" dir="ltr">{{ home.coach.level.xp }}/{{ home.coach.level.next }}</span>
          </div>
        </div>
        <div class="flex shrink-0 flex-col items-end gap-1.5">
          <RouterLink to="/wallet" class="flex items-center gap-1 rounded-pill bg-gold/15 px-2.5 py-1 text-sm font-bold" aria-label="الكوينز">
            <img src="/brand/coin.svg" alt="" class="size-4" /><span class="font-numbers" dir="ltr">{{ home.coach.coins }}</span>
          </RouterLink>
          <span v-if="cashClub" class="flex items-center gap-1 rounded-pill bg-brand/25 px-2.5 py-1 text-sm font-bold" :title="`أموال ${$nm(cashClub.name)}`" :aria-label="`أموال ${$nm(cashClub.name)}`">
            <span aria-hidden="true">💵</span><span class="font-numbers" dir="ltr">{{ money(cashClub.cash) }}</span>
          </span>
        </div>
      </section>

      <!-- The slots, the screen's heart, right under the card: all ten without scrolling. -->
      <section class="flex flex-col gap-2" aria-label="فتحات المدرب">
        <h2 class="flex items-center text-sm font-bold text-text-muted">فتحات المدرب <HelpTip label="الفتحات" text="لك عشر فتحات: في كل واحدة نادٍ في دوري. اضغط فتحة ناديك لتدخلها، أو فتحة فارغة لتنضم إلى دوري أو تنشئ دوريك." /></h2>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-5">
          <!-- [X32] Each slot a card: a band with its number and league (blue for a club), the crest on a ivory disc,
               and the next match at its foot. -->
          <button v-for="s in home.slots" :key="s.slot" type="button" class="slot-card group" :class="`is-${s.state}`"
            :aria-label="s.state === 'free' ? `الفتحة ${s.slot}: دوري جديد` : `الفتحة ${s.slot}: ${s.league?.name}`" @click="openSlot(s)">
            <span class="slot-band">
              <b class="font-numbers text-sm">{{ s.slot }}</b>
              <span class="min-w-0 flex-1 truncate text-start text-[11px] font-bold">{{ s.state === 'free' ? 'فتحة فارغة' : s.league!.name }}</span>
              <span v-if="s.position" class="rounded bg-black/30 px-1 font-numbers text-[11px]" dir="ltr">{{ s.position }}/{{ s.teams }}</span>
            </span>
            <span class="flex flex-1 items-center justify-center gap-2 px-2 py-1.5">
              <template v-if="s.state === 'club'">
                <span class="slot-disc"><img :src="s.club!.crest_url" alt="" class="size-8" /></span>
                <b class="line-clamp-2 min-w-0 text-start font-display text-sm leading-tight">{{ $nm(s.club!.name) }}</b>
              </template>
              <template v-else-if="s.state === 'waiting'">
                <span class="text-xl" aria-hidden="true">⏳</span>
                <span class="text-[11px] text-text-muted">ينتظر موافقة المنشئ</span>
              </template>
              <template v-else>
                <span class="grid size-9 place-items-center rounded-full bg-gradient-to-b from-brand-light to-brand text-xl font-extrabold text-white" aria-hidden="true">+</span>
                <b class="font-display text-sm">دوري جديد</b>
              </template>
            </span>
            <span v-if="s.state === 'club'" class="slot-foot" :class="s.next_match?.live ? 'is-live' : ''">
              <template v-if="s.next_match">{{ s.next_match.live ? '● مباشر الآن' : when(s.next_match.scheduled_at) }} · {{ s.next_match.venue === 'home' ? 'ضد' : 'عند' }} {{ $nm(s.next_match.opponent) }}</template>
              <template v-else>لا مباريات قادمة</template>
            </span>
          </button>
        </div>
      </section>

      <!-- Below the slots: the announcements, the record, the trophies and the rankings. -->
      <div class="grid gap-3 lg:grid-cols-2">
        <!-- The developers' announcements: updates and news [X11, X18]. -->
        <section class="flex flex-col gap-1 rounded-xl bg-gradient-to-l from-[#B4692A]/60 via-surface-raised to-surface p-3" aria-label="الإعلانات">
          <div class="flex items-center gap-2 text-sm font-bold"><svg viewBox="0 0 24 24" class="size-5 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1ZM16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14" /></svg>الإعلانات
            <span v-if="home.announcements.length > 1" class="ms-auto flex gap-1">
              <button v-for="(a, i) in home.announcements" :key="a.id" type="button" class="size-touch rounded-full" :aria-label="`الإعلان ${i + 1}`" @click="announcement = i"><span class="mx-auto block size-2 rounded-full" :class="i === announcement ? 'bg-gold' : 'bg-text/30'" /></button>
            </span>
          </div>
          <template v-if="latest">
            <RouterLink to="/inbox" class="flex flex-col gap-0.5">
              <b class="font-display">{{ latest.title }}</b>
              <span class="line-clamp-2 text-sm text-text-soft">{{ latest.body }}</span>
              <span class="text-xs text-text-muted">{{ latest.sender?.name }} <OfficialBadge v-if="latest.sender?.official" /> · {{ when(latest.created_at) }}</span>
            </RouterLink>
          </template>
          <p v-else class="text-sm text-text-muted">لا إعلانات بعد. هنا تصلك تحديثات اللعبة وأخبارها من فريق التطوير.</p>
        </section>

        <div class="grid grid-cols-4 gap-2">
          <div class="home-tile">
            <b class="font-numbers text-xl" dir="ltr">{{ home.coach.record.won }}<span class="text-xs text-text-muted">/{{ home.coach.record.played }}</span></b>
            <span class="text-[11px] text-text-muted">فوز</span>
          </div>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <b class="font-numbers text-xl text-gold">{{ home.trophies.total }}</b>
            <span class="text-[11px] text-text-muted">الكؤوس</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('trophies')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4ZM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4" /></svg>
            <span class="text-[11px] font-bold">لوحة الشرف</span>
          </button>
          <button type="button" class="home-tile" @click="openRanking('level')">
            <svg viewBox="0 0 24 24" class="size-6 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" /></svg>
            <span class="text-[11px] font-bold">المستويات</span>
          </button>
        </div>
      </div>
    </div>
    <p v-else-if="!error" class="text-text-muted">جارٍ التحميل...</p>

    <!-- The global ranking [X18]. -->
    <div v-if="ranking || rankingBusy" class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 p-3 md:items-center" role="dialog" aria-modal="true" aria-label="لوحة شرف المدربين" @click.self="ranking = null">
      <div class="flex max-h-[85dvh] w-full max-w-lg flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-4">
        <div class="flex items-center gap-2">
          <h2 class="flex-1 font-display text-xl font-extrabold">{{ ranking?.by === 'level' ? 'ترتيب المستويات' : 'لوحة شرف المدربين' }}</h2>
          <button type="button" class="size-touch rounded-md bg-surface-raised" aria-label="إغلاق" @click="ranking = null">✕</button>
        </div>
        <p v-if="rankingBusy" class="text-text-muted">جارٍ التحميل...</p>
        <template v-else-if="ranking">
          <div class="flex gap-2">
            <button v-for="[k, l] in ([['trophies', 'بالكؤوس'], ['level', 'بالمستوى']] as const)" :key="k" type="button" class="h-touch rounded-pill px-4 text-sm font-bold" :class="ranking.by === k ? 'bg-gold text-on-gold' : 'bg-surface-raised'" @click="openRanking(k)">{{ l }}</button>
          </div>
          <div v-for="r in ranking.coaches" :key="r.coach.id" class="flex min-h-touch items-center gap-3 border-t border-text/5" :class="r.coach.id === auth.user?.id ? 'text-gold' : ''">
            <span class="w-7 text-center font-numbers text-text-muted">{{ r.position }}</span>
            <RouterLink :to="{ name: 'coach', params: { id: r.coach.id } }" class="min-w-0 flex-1 truncate font-bold">{{ r.coach.name }} <OfficialBadge v-if="r.coach.official" /></RouterLink>
            <span class="text-xs text-text-muted">م{{ r.level }}</span>
            <b class="font-numbers">🏆 {{ r.trophies.total }}</b>
          </div>
          <p v-if="ranking.me && ranking.me.position > 50" class="border-t border-gold/40 pt-2 text-sm">مركزك: <b class="font-numbers">{{ ranking.me.position }}</b></p>
          <p v-if="!ranking.coaches.length" class="text-text-muted">لا مدربين بعد.</p>
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
  min-height: 6.25rem;
  overflow: hidden;
  border-radius: 0.85rem;
  text-align: center;
  background: color-mix(in srgb, var(--color-panel) 88%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 22%, transparent);
  box-shadow: 0 14px 30px -18px rgb(0 0 0 / 0.8);
  transition: transform 0.15s ease;
}
.slot-card:hover { transform: scale(1.03); border-color: var(--color-brand-light); }
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
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 0.85rem;
  background: linear-gradient(120deg, color-mix(in srgb, var(--color-gold) 22%, var(--color-panel)), var(--color-panel) 60%);
  border: 1px solid color-mix(in srgb, var(--color-gold) 25%, transparent);
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
