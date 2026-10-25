<script setup lang="ts">
// The coach's home screen [X18], after the owner's sketch (2026-10-25): the club slots (up to ten) are the screen, next to
// the profile card (level and progress), the coaches met, the developers' announcements and the trophies, with the
// global ranking a tap away. A guest sees the way in.
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError } from '../api/client'
import type { components } from '../api/schema'
import BrandMark from '../components/BrandMark.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
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
    <div v-if="home" class="grid gap-4 lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
      <!-- Right (first in RTL): the coach. -->
      <div class="flex flex-col gap-3">
        <h2 class="text-sm font-bold text-text-muted">ملف المدرب</h2>
        <div class="grid grid-cols-[minmax(0,2fr)_minmax(0,1fr)] gap-3">
          <section class="relative flex flex-col gap-3 overflow-hidden rounded-xl bg-gradient-to-bl from-gold/25 via-surface to-surface p-4" aria-label="ملف المدرب">
            <div class="absolute end-3 top-3 flex flex-col gap-2">
              <RouterLink to="/profile" class="grid size-touch place-items-center rounded-full bg-surface-raised/80" aria-label="الإعدادات"><svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" /></svg></RouterLink>
              <RouterLink to="/inbox" class="grid size-touch place-items-center rounded-full bg-surface-raised/80" aria-label="الرسائل"><svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12Z" /></svg></RouterLink>
            </div>
            <div class="flex flex-col items-center gap-2 pt-2">
              <img v-if="home.coach.avatar_url" :src="home.coach.avatar_url" alt="" class="size-20 rounded-full border-4 border-gold object-cover" />
              <span v-else class="grid size-20 place-items-center rounded-full border-4 border-gold bg-surface-raised font-display text-3xl font-extrabold">{{ home.coach.name.charAt(0) }}</span>
              <b class="font-display text-xl">{{ home.coach.name }} <OfficialBadge v-if="home.coach.official" /></b>
              <span class="text-xs text-text-muted" dir="ltr">@{{ home.coach.username }}</span>
            </div>
            <div class="flex items-center gap-3">
              <span class="grid size-12 shrink-0 place-items-center rounded-lg bg-[#B4692A] font-numbers text-2xl font-extrabold text-white" :title="`المستوى ${home.coach.level.level}`">{{ home.coach.level.level }}</span>
              <div class="flex min-w-0 flex-1 flex-col gap-1">
                <span class="text-xs text-text-muted">المستوى · <span class="font-numbers" dir="ltr">{{ home.coach.level.xp }}/{{ home.coach.level.next }}</span> نقطة</span>
                <div class="h-2 overflow-hidden rounded-pill bg-surface-sunk" role="progressbar" :aria-valuenow="home.coach.level.progress_bp / 100" aria-valuemin="0" aria-valuemax="100" aria-label="التقدم إلى المستوى التالي">
                  <div class="h-full rounded-pill bg-success" :style="{ width: home.coach.level.progress_bp / 100 + '%' }" />
                </div>
              </div>
            </div>
          </section>
          <div class="flex flex-col gap-3">
            <div class="flex flex-1 flex-col items-center justify-center gap-1 rounded-xl bg-surface p-3 text-center">
              <b class="font-numbers text-2xl" dir="ltr">{{ home.coach.record.won }}<span class="text-sm text-text-muted">/{{ home.coach.record.played }}</span></b>
              <span class="text-xs text-text-muted">فوز من مبارياتك</span>
            </div>
            <div class="flex flex-1 flex-col items-center justify-center gap-1 rounded-xl bg-surface p-3 text-center">
              <b class="font-numbers text-2xl">{{ home.colleagues }}</b>
              <span class="text-xs text-text-muted">مدربون لعبت معهم</span>
            </div>
          </div>
        </div>

        <!-- The developers' announcements: updates and news [X11, X18]. -->
        <section class="flex min-h-28 flex-col gap-1 rounded-xl bg-gradient-to-l from-[#B4692A]/60 via-surface-raised to-surface p-4" aria-label="الإعلانات">
          <div class="flex items-center gap-2 text-sm font-bold"><svg viewBox="0 0 24 24" class="size-5 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1ZM16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14" /></svg>الإعلانات
            <span v-if="home.announcements.length > 1" class="ms-auto flex gap-1">
              <button v-for="(a, i) in home.announcements" :key="a.id" type="button" class="size-touch rounded-full" :aria-label="`الإعلان ${i + 1}`" @click="announcement = i"><span class="mx-auto block size-2 rounded-full" :class="i === announcement ? 'bg-gold' : 'bg-text/30'" /></button>
            </span>
          </div>
          <template v-if="latest">
            <RouterLink to="/inbox" class="flex flex-col gap-0.5">
              <b class="font-display text-lg">{{ latest.title }}</b>
              <span class="line-clamp-2 text-sm text-text-soft">{{ latest.body }}</span>
              <span class="text-xs text-text-muted">{{ latest.sender?.name }} <OfficialBadge v-if="latest.sender?.official" /> · {{ when(latest.created_at) }}</span>
            </RouterLink>
          </template>
          <p v-else class="text-sm text-text-muted">لا إعلانات بعد. هنا تصلك تحديثات اللعبة وأخبارها من فريق التطوير.</p>
        </section>

        <div class="grid grid-cols-3 gap-3">
          <button type="button" class="flex flex-col items-center justify-center gap-1 rounded-xl bg-surface p-3" @click="openRanking('trophies')">
            <span class="text-xs text-text-muted">الكؤوس</span>
            <b class="font-numbers text-3xl text-gold">{{ home.trophies.total }}</b>
            <span class="text-[11px] text-text-muted">دوري {{ home.trophies.league }} · كأس {{ home.trophies.cup }}</span>
          </button>
          <button type="button" class="flex flex-col items-center justify-center gap-1 rounded-xl bg-surface p-3 font-bold" @click="openRanking('trophies')">
            <svg viewBox="0 0 24 24" class="size-7 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4ZM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4" /></svg>
            <span class="text-sm">لوحة الشرف</span>
          </button>
          <button type="button" class="flex flex-col items-center justify-center gap-1 rounded-xl bg-surface p-3 font-bold" @click="openRanking('level')">
            <svg viewBox="0 0 24 24" class="size-7 text-gold" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" /></svg>
            <span class="text-sm">ترتيب المستويات</span>
          </button>
        </div>
      </div>

      <!-- Left: the four slots, the screen's heart (first on the phone). -->
      <div class="order-first flex flex-col gap-3 lg:order-none">
        <h2 class="text-sm font-bold text-text-muted">فتحات المدرب</h2>
        <div class="grid grid-cols-2 gap-3 xl:grid-cols-3">
          <button v-for="s in home.slots" :key="s.slot" type="button" class="relative flex aspect-[5/4] flex-col items-center justify-center gap-2 overflow-hidden rounded-xl border p-3 text-center transition hover:border-gold/60"
            :class="s.state === 'club' ? 'border-gold/30 bg-gradient-to-b from-surface-raised to-surface' : 'border-text/10 bg-[repeating-linear-gradient(135deg,var(--color-surface)_0_14px,var(--color-surface-raised)_14px_15px)]'"
            :aria-label="s.state === 'free' ? `الفتحة ${s.slot}: دوري جديد` : `الفتحة ${s.slot}: ${s.league?.name}`" @click="openSlot(s)">
            <span class="absolute end-0 top-0 grid h-12 w-10 place-items-center rounded-es-lg bg-bg/80 font-numbers text-2xl font-extrabold" :class="s.slot === 1 ? 'text-gold' : ''">{{ s.slot }}</span>
            <template v-if="s.state === 'club'">
              <img :src="s.club!.crest_url" alt="" class="size-14 drop-shadow" />
              <b class="font-display text-lg leading-tight">{{ s.club!.name }}</b>
              <span class="text-xs text-text-muted">{{ s.league!.name }}<template v-if="s.position"> · المركز <span class="font-numbers">{{ s.position }}</span>/{{ s.teams }}</template></span>
              <span v-if="s.next_match" class="rounded-pill px-2 py-0.5 text-[11px]" :class="s.next_match.live ? 'bg-live/20 text-[#FF8A8A]' : 'bg-surface-sunk text-text-soft'">
                {{ s.next_match.live ? 'مباشر الآن' : when(s.next_match.scheduled_at) }} · {{ s.next_match.venue === 'home' ? 'ضد' : 'عند' }} {{ s.next_match.opponent }}
              </span>
            </template>
            <template v-else-if="s.state === 'waiting'">
              <span class="grid size-14 place-items-center rounded-full bg-warning/20 text-2xl" aria-hidden="true">⏳</span>
              <b class="font-display">{{ s.league!.name }}</b>
              <span class="text-xs text-text-muted">طلب الانضمام ينتظر موافقة المنشئ</span>
            </template>
            <template v-else>
              <span class="grid size-16 place-items-center rounded-full border-4 border-bg/60 bg-gradient-to-b from-[#5FD4FF] to-[#1E88E5] text-4xl font-extrabold text-white shadow-lg" aria-hidden="true">+</span>
              <b class="font-display text-lg" :class="s.slot === 1 ? 'text-gold' : ''">دوري جديد</b>
            </template>
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
