<script setup lang="ts">
// One league (Sprints 13 to 15): the table, calendar and cup (LeagueTabs), its card, the invite to share, my club, my presence and holiday,
// the coaches (the owner can send one away with a reason), who left and why, and the join requests.
// Sprint 14's parts have no draft yet: built with the same cards, waiting for approval like Sprint 10's. The table, fixtures and cup of the draft MobileLeague come with the schedule (Sprint 15).
import OfficialBadge from '../../components/OfficialBadge.vue'
import VerifiedBadge from '../../components/VerifiedBadge.vue'
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { budget, cupGoal, END_MODES, leagueGoal, STATUS, when, type JoinRequest, type League, type LeagueClub } from '../../api/leagues'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import LeagueTabs from './LeagueTabs.vue'
import { rememberLeague } from '../../lib/currentLeague'
import UiButton from '../../components/ui/UiButton.vue'
import UiCard from '../../components/ui/UiCard.vue'
import UiChip from '../../components/ui/UiChip.vue'
import { money, strength } from '../../lib/format'

const props = defineProps<{ id: string }>()
const route = useRoute()
const league = ref<League | null>(null)
const clubs = ref<LeagueClub[]>([])
const requests = ref<JoinRequest[]>([])
const error = ref('')
const copied = ref(false)
const isDev = import.meta.env.DEV

const leagueId = computed(() => Number(props.id))
const mine = computed(() => clubs.value.find((c) => c.id === league.value?.my_club_id) ?? null)
const coaches = computed(() => clubs.value.filter((c) => !c.bot))
const waiting = computed(() => requests.value.filter((r) => r.status === 'pending'))

async function load() {
  try {
    // [Sprint 21 E3.5] The league and its clubs together, shown at once: the page builds in one go instead of
    // growing twice. The clubs answer 403 to a coach still waiting; then there are none to show.
    const path = { params: { path: { league: leagueId.value } } }
    const [l, c] = await Promise.all([api.GET('/leagues/{league}', path), api.GET('/leagues/{league}/clubs', path).catch(() => null)])
    const data = l.data!.league
    if (data.my_club_id) rememberLeague(data.id)
    clubs.value = data.is_owner || data.my_request === 'approved' ? (c?.data?.clubs ?? []) : []
    league.value = data
    if (data.is_owner) requests.value = (await api.GET('/leagues/{league}/requests', path)).data!.requests ?? []
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function decide(r: JoinRequest, approve: boolean) {
  error.value = ''
  try {
    await ensureCsrf()
    const path = { league: leagueId.value, request: r.id }
    const { data } = approve
      ? await api.POST('/leagues/{league}/requests/{request}/approve', { params: { path } })
      : await api.POST('/leagues/{league}/requests/{request}/reject', { params: { path } })
    r.status = data!.request.status
  } catch (e) {
    error.value = asApiError(e).message
  }
}

// The invite (Sprint 14 B2): the link opens the join screen with the code, and WhatsApp shows its card.
const inviteText = computed(() => (league.value ? `انضم لدوري «${league.value.name}» في لعبة المدرب الأسطورة واختر ناديك: ${league.value.invite_url}` : ''))
const whatsapp = computed(() => `https://wa.me/?text=${encodeURIComponent(inviteText.value)}`)
async function share() {
  if (!league.value?.invite_url) return
  try {
    if (navigator.share) await navigator.share({ text: inviteText.value })
    else {
      await navigator.clipboard.writeText(league.value.invite_url)
      copied.value = true
      window.setTimeout(() => (copied.value = false), 2000)
    }
  } catch {
    // The share sheet was closed: nothing to do.
  }
}

// A holiday in this league alone: up to 7 days, once a season, with a reason its owner approves [X4].
// The account's holiday (every league, no asking) is on the profile page.
const days = ref(3)
const holidayReason = ref('')
async function holiday(start: boolean) {
  error.value = ''
  try {
    await ensureCsrf()
    const path = { league: leagueId.value }
    const { data } = start
      ? await api.POST('/leagues/{league}/vacation', { params: { path }, body: { days: days.value, reason: holidayReason.value.trim() } })
      : await api.DELETE('/leagues/{league}/vacation', { params: { path } })
    league.value = data!.league
  } catch (e) {
    error.value = asApiError(e).message
  }
}

// Resigning [PLAN 2.2, Sprint 32]: asked twice, since the club goes back to a bot for the rest of the season.
const router = useRouter()
const confirmResign = ref(false)
const resignError = ref('')
async function resign() {
  resignError.value = ''
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/resign', { params: { path: { league: leagueId.value } } })
    router.push({ name: 'leagues' })
  } catch (e) {
    resignError.value = asApiError(e).message
    confirmResign.value = false
  }
}

// The owner answers a coach's holiday request [X4].
async function answerHoliday(membership: number, approve: boolean) {
  error.value = ''
  try {
    await ensureCsrf()
    const params = { path: { league: leagueId.value, membership } }
    const { data } = approve
      ? await api.POST('/leagues/{league}/members/{membership}/vacation/approve', { params })
      : await api.POST('/leagues/{league}/members/{membership}/vacation/reject', { params })
    league.value = data!.league
  } catch (e) {
    error.value = asApiError(e).message
  }
}

// The owner sends a coach away with a reason every member sees [PLAN 2.1].
const kicking = ref<number | null>(null)
const reason = ref('')
const reasonError = ref('')
async function kick(membership: number) {
  reasonError.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues/{league}/members/{membership}/kick', {
      params: { path: { league: leagueId.value, membership } },
      body: { reason: reason.value.trim() },
    })
    league.value = data!.league
    kicking.value = null
    reason.value = ''
    await load()
  } catch (e) {
    const err = asApiError(e)
    reasonError.value = err.field('reason') || err.message
  }
}

const LEFT = { resigned: 'استقال', absent: 'غاب 3 أيام', kicked: 'طرده المنشئ', deleted: 'حذف حسابه' } as const
const since = (iso?: string | null) => (iso ? when(iso) : '—')

async function startNow() {
  try {
    await ensureCsrf()
    league.value = (await api.POST('/leagues/{league}/start', { params: { path: { league: leagueId.value } } })).data!.league
  } catch (e) {
    error.value = asApiError(e).message
  }
}

onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-5">
    <p v-if="route.query.welcome && mine" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">
      {{ $t('أهلاً بك مدرباً لـ{v0}. {v1}', { v0: $nm(mine.name), v1: league?.is_owner ? $t('شارك الكود مع أصحابك ليختاروا فرقهم.') : $t('بالتوفيق في الموسم!') }) }}
    </p>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>

    <!-- [Sprint 21 E3.5] Until the league comes, its outline holds the page. -->
    <div v-if="!league && !error" class="flex flex-col gap-5" aria-hidden="true">
      <div class="h-16 w-2/3 animate-pulse rounded-xl bg-surface" />
      <div class="h-[32rem] animate-pulse rounded-xl bg-surface" />
    </div>
    <template v-if="league">
      <header class="flex flex-wrap items-end justify-between gap-3">
        <div class="min-w-0">
          <h1 class="font-display text-3xl font-extrabold">{{ $nm(league.name) }}</h1>
          <p class="text-text-muted">
            {{ $ln(league.template) }} · <span class="font-numbers">{{ league.season?.rounds }}</span> {{ $t('جولة · منطقة القفل من الجولة') }}
            <span class="font-numbers">{{ league.season?.lock_from_round }}</span>
          </p>
        </div>
        <div class="flex flex-wrap gap-2">
          <UiChip :tone="league.status === 'running' ? 'win' : 'neutral'">{{ $t(STATUS[league.status]) }}</UiChip>
          <UiChip v-if="league.fair_league" tone="win">{{ $t('دوري نزيه') }}</UiChip>
          <UiChip v-if="league.integrity" tone="loss">{{ $t('منظومة النزاهة') }}</UiChip>
          <UiChip v-if="league.is_dev" tone="gold">{{ $t('للتطوير') }}</UiChip>
          <!-- [Sprint 21 E2.2] Every member invites from the top of the league: shared on the phone, copied elsewhere. -->
          <button v-if="league.invite_url" type="button" class="flex h-touch items-center gap-2 rounded-pill bg-gold px-4 font-bold text-on-gold" @click="share">
            <svg viewBox="0 0 24 24" class="size-4" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M16 11a4 4 0 1 0-8 0M12 15c-4 0-7 2-7 4v1h9M19 14v6M16 17h6" /></svg>
            {{ copied ? $t('نُسخ الرابط') : $t('ادعُ مدرباً') }}
          </button>
        </div>
      </header>

      <!-- The FA's verdicts of the last day: a breaking headline for everyone in the league [X28]. -->
      <p v-for="(h, i) in league.headlines ?? []" :key="i" class="flex items-start gap-2 rounded-xl bg-live px-4 py-3 text-sm font-bold text-white" role="alert">
        <span class="shrink-0 rounded bg-white/20 px-1.5 text-xs">{{ $t('📰 عاجل') }}</span><span>{{ $t(h.text) }} <span class="font-normal">{{ $t('(خصم {v0} نقاط)', { v0: h.points }) }}</span></span>
      </p>

      <section v-if="mine?.objectives" :aria-label="$t('هدف الإدارة')" class="flex flex-wrap items-center gap-x-4 gap-y-1 rounded-xl border border-gold/30 bg-gold/10 px-4 py-3 text-sm">
        <b class="text-gold">{{ $t('هدف الإدارة هذا الموسم') }}</b>
        <span>{{ $t('الدوري: {v0}', { v0: leagueGoal(mine.objectives.league) }) }}</span>
        <span>{{ $t('الكأس: {v0}', { v0: cupGoal(mine.objectives.cup.target) }) }}</span>
      </section>

      <LeagueTabs v-if="clubs.length" :league-id="leagueId" :my-club-id="league.my_club_id" :team-count="league.team_count" />

      <div class="grid gap-4 md:grid-cols-2">
        <UiCard v-if="league.code" :title="$t('ادعُ أصحابك')">
          <p class="text-sm text-text-muted">{{ $t('الرابط يفتح صفحة الانضمام بالكود جاهزاً: يرسلون طلباً، وتوافق أنت، ثم يختارون فرقهم.') }}</p>
          <span class="rounded-lg bg-surface-sunk px-4 py-3 text-center font-numbers text-3xl font-bold tracking-[0.3em] text-gold" dir="ltr">{{ league.code }}</span>
          <div class="grid grid-cols-2 gap-2">
            <a :href="whatsapp" target="_blank" rel="noopener" class="flex h-12 items-center justify-center rounded-lg bg-success font-display font-extrabold text-on-gold">{{ $t('واتساب') }}</a>
            <UiButton variant="outline" @click="share">{{ copied ? $t('نُسخ الرابط') : $t('شارك الرابط') }}</UiButton>
          </div>
        </UiCard>

        <UiCard :title="$t('الموسم')">
          <dl class="grid grid-cols-2 gap-2 text-sm">
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">{{ $t('البداية') }}</dt><dd class="font-bold">{{ when(league.starts_at) }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">{{ $t('الإعداد') }}</dt><dd class="font-bold">{{ ['يوم', $t('يومان'), '3 أيام'][league.prep_days - 1] }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3">
              <dt class="text-text-muted">{{ $t('الجولات') }}</dt>
              <dd class="font-bold" dir="ltr">{{ league.round_times.join(' · ') }}</dd>
            </div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">{{ $t('الميزانية') }}</dt><dd class="font-bold">{{ budget(league.starting_budget) }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">{{ $t('المدربون') }}</dt><dd class="font-bold"><span class="font-numbers">{{ league.coaches }}</span> {{ $t('من') }} <span class="font-numbers">{{ league.team_count }}</span></dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">{{ $t('نهاية الموسم') }}</dt><dd class="font-bold">{{ $t(END_MODES[league.season_end_mode]) }}</dd></div>
          </dl>
          <p class="text-xs text-text-muted">{{ $t('{v0} ساعات الجولات بتوقيت القاهرة.', { v0: league.locked ? $t('الإعدادات مقفلة منذ بداية الموسم.') : $t('الإعدادات تُقفل عند بداية الموسم.') }) }}</p>
          <UiButton v-if="isDev && league.is_owner && !league.locked" variant="quiet" @click="startNow">{{ $t('ابدأ الآن (للتطوير)') }}</UiButton>
        </UiCard>
      </div>

      <UiCard v-if="league.me" :title="$t('حضورك')">
        <p v-if="league.me.on_holiday" class="rounded-lg bg-gold/15 px-3 py-2 text-sm">
          {{ $t('أنت في إجازة حتى {v0}. لا يُحسب غيابك، والمساعد يدير فريقك.', { v0: since(league.me.vacation_until) }) }}
        </p>
        <p v-else-if="league.me.away_deadline" class="text-sm text-text-muted">
          {{ $t('كل دخول للدوري يُحسب حضوراً. لو غبت 3 أيام متواصلة يعود فريقك للحاسوب: آخر موعد الآن {v0}.', { v0: since(league.me.away_deadline) }) }}
        </p>
        <p v-else class="text-sm text-text-muted">{{ $t('عداد الغياب يبدأ مع بداية الموسم.') }}</p>
        <UiButton v-if="league.me.on_holiday && !league.me.account_vacation" variant="quiet" @click="holiday(false)">{{ $t('عدت مبكراً، أنهِ الإجازة') }}</UiButton>
        <p v-if="league.me.account_vacation" class="text-sm text-text-muted">{{ $t('إجازة حسابك تشمل هذا الدوري. تنهيها من') }} <RouterLink to="/profile" class="font-bold text-gold">{{ $t('حسابي') }}</RouterLink>.</p>
        <p v-else-if="league.me.vacation_requested" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm">{{ $t('طلبت إجازة في هذا الدوري، وتنتظر موافقة مسؤوله.') }}</p>
        <form v-else-if="!league.me.vacation_used && !league.me.on_holiday" class="flex flex-col gap-2" @submit.prevent="holiday(true)">
          <p class="text-sm text-text-muted">{{ $t('إجازة في هذا الدوري وحده (مرة في الموسم) تحتاج سبباً يوافق عليه مسؤول الدوري. ولإجازة تشمل كل دورياتك بلا طلب:') }} <RouterLink to="/profile" class="font-bold text-gold">{{ $t('إجازة الحساب') }}</RouterLink>.</p>
          <label class="flex flex-col gap-1.5">
            <span class="text-sm font-bold">{{ $t('المدة') }}</span>
            <select v-model.number="days" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4">
              <option v-for="d in 7" :key="d" :value="d">{{ d === 1 ? $t('يوم') : d === 2 ? $t('يومان') : $t('{v0} أيام', { v0: d }) }}</option>
            </select>
          </label>
          <label class="flex flex-col gap-1.5">
            <span class="text-sm font-bold">{{ $t('السبب (يراه مسؤول الدوري)') }}</span>
            <textarea v-model="holidayReason" rows="2" maxlength="300" class="rounded-lg border border-text/10 bg-surface-sunk p-3" />
          </label>
          <UiButton type="submit" variant="outline" :disabled="holidayReason.trim().length < 5">{{ league.is_owner ? $t('فعّل الإجازة') : $t('اطلب الإجازة') }}</UiButton>
        </form>
        <p v-else-if="league.me.vacation_used && !league.me.on_holiday" class="text-sm text-text-muted">{{ $t('استخدمت إجازة هذا الموسم.') }}</p>
        <div v-if="!league.is_owner" class="flex flex-col gap-2 border-t border-text/10 pt-3">
          <p v-if="resignError" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]" role="alert">{{ $t(resignError) }}</p>
          <UiButton v-if="!confirmResign" variant="quiet" @click="confirmResign = true">{{ $t('الاستقالة من الدوري') }}</UiButton>
          <template v-else>
            <p class="rounded-lg bg-live/15 px-3 py-2 text-sm">{{ $t('يعود فريقك للحاسوب بحالته، ولا تعود لهذا الدوري قبل الموسم الجديد. متأكد؟') }}</p>
            <div class="flex gap-2">
              <UiButton variant="danger" @click="resign">{{ $t('نعم، أستقيل') }}</UiButton>
              <UiButton variant="quiet" @click="confirmResign = false">{{ $t('تراجع') }}</UiButton>
            </div>
          </template>
        </div>
      </UiCard>

      <UiCard v-if="league.members.length" :title="$t('المدربون')">
        <ul class="flex flex-col gap-2">
          <li v-for="m in league.members" :key="m.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
            <div class="flex min-h-touch flex-wrap items-center gap-3">
              <img v-if="m.user.avatar_url" :src="m.user.avatar_url" alt="" class="size-10 rounded-full object-cover" />
              <span v-else class="flex size-10 items-center justify-center rounded-full bg-surface-raised font-display font-extrabold">{{ m.user.name.charAt(0) }}</span>
              <span class="min-w-0 flex-1">
                <span class="block truncate font-bold"><RouterLink :to="{ name: 'coach', params: { id: m.user.id } }">{{ m.user.name }}</RouterLink> <OfficialBadge v-if="m.user.official" /><VerifiedBadge v-else-if="m.user.verified" /> <UiChip v-if="m.is_owner" tone="gold">{{ $t('المنشئ') }}</UiChip> <UiChip v-if="m.on_holiday" tone="warning">{{ $t('في إجازة') }}</UiChip></span>
                <span class="block text-sm text-text-muted">{{ $nm(m.club?.name) }}<template v-if="league.is_owner && m.last_active_at"> {{ $t('· آخر دخول {v0}', { v0: since(m.last_active_at) }) }}</template></span>
              </span>
              <UiButton v-if="league.is_owner && !m.is_owner && kicking !== m.id" variant="quiet" @click="(kicking = m.id), (reason = ''), (reasonError = '')">{{ $t('اطرد') }}</UiButton>
            </div>
            <div v-if="m.vacation_request" class="flex flex-col gap-2 rounded-lg bg-gold/10 p-3 text-sm">
              <p>{{ $t('يطلب إجازة {v0} أيام. السبب: «{v1}»', { v0: m.vacation_request.days, v1: m.vacation_request.reason }) }}</p>
              <div class="flex gap-2">
                <UiButton variant="outline" @click="answerHoliday(m.id, true)">{{ $t('وافق') }}</UiButton>
                <UiButton variant="quiet" @click="answerHoliday(m.id, false)">{{ $t('ارفض') }}</UiButton>
              </div>
            </div>
            <form v-if="kicking === m.id" class="flex flex-col gap-2" @submit.prevent="kick(m.id)">
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-bold">{{ $t('سبب الطرد (يراه كل أعضاء الدوري)') }}</span>
                <textarea v-model="reason" rows="2" maxlength="200" class="rounded-lg border border-text/10 bg-surface p-3" :aria-invalid="!!reasonError" />
              </label>
              <p v-if="reasonError" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(reasonError) }}</p>
              <p class="text-xs text-text-muted">{{ $t('يعود فريقه للحاسوب بحالته، ولا يعود للدوري هذا الموسم.') }}</p>
              <div class="flex gap-2">
                <UiButton type="submit" variant="danger">{{ $t('اطرد {v0}', { v0: m.user.name }) }}</UiButton>
                <UiButton variant="quiet" @click="kicking = null">{{ $t('إلغاء') }}</UiButton>
              </div>
            </form>
          </li>
        </ul>
      </UiCard>

      <UiCard v-if="league.departures.length" :title="$t('غادروا هذا الموسم')">
        <ul class="flex flex-col gap-2 text-sm">
          <li v-for="(d, i) in league.departures" :key="i" class="rounded-lg bg-surface-sunk p-3">
            <span class="font-bold">{{ d.user }}</span><span v-if="d.club" class="text-text-muted"> ({{ d.club }})</span>: {{ $t(LEFT[d.reason]) }}
            <span v-if="d.kick_reason" class="mt-1 block">{{ $t('السبب: «{v0}»', { v0: d.kick_reason }) }}</span>
            <span class="block text-xs text-text-muted">{{ since(d.left_at) }}</span>
          </li>
        </ul>
      </UiCard>

      <UiCard v-if="league.is_owner" :title="$t('طلبات الانضمام')">
        <template #action><UiChip v-if="waiting.length" tone="live">{{ $t('{v0} بانتظارك', { v0: waiting.length }) }}</UiChip></template>
        <p v-if="!requests.length" class="text-sm text-text-muted">{{ $t('لا طلبات بعد. شارك الكود ليصل أصحابك.') }}</p>
        <ul v-else class="flex flex-col gap-2">
          <li v-for="r in requests" :key="r.id" class="flex min-h-touch flex-wrap items-center gap-3 rounded-lg bg-surface-sunk p-3">
            <span class="flex size-10 items-center justify-center rounded-full bg-surface-raised font-display font-extrabold">{{ r.user?.name.charAt(0) }}</span>
            <span class="min-w-0 flex-1 truncate font-bold">{{ r.user?.name }}</span>
            <template v-if="r.status === 'pending'">
              <UiButton @click="decide(r, true)">{{ $t('وافق') }}</UiButton>
              <UiButton variant="quiet" @click="decide(r, false)">{{ $t('ارفض') }}</UiButton>
            </template>
            <UiChip v-else :tone="r.status === 'approved' ? 'win' : 'loss'">{{ r.status === 'approved' ? $t('وافقت') : $t('رفضت') }}</UiChip>
          </li>
        </ul>
      </UiCard>

      <RouterLink v-if="league.draw_at || (league.is_owner && league.status === 'waiting')" :to="{ name: 'league-draw', params: { id } }"
        class="flex min-h-touch items-center justify-between gap-3 rounded-xl border border-gold/30 bg-surface px-4 py-3">
        <span><b class="block">{{ $t('القرعة المباشرة') }}</b><span class="text-sm text-text-muted">{{ league.drawn_at ? $t('سُحبت: شاهد النتيجة') : league.draw_at ? $t('موعدها محدد: تابعها حية') : $t('حدد موعدها قبل البداية') }}</span></span>
        <span class="font-bold text-gold">←</span>
      </RouterLink>

      <!-- [UP12] The league's media. -->
      <div class="grid gap-2 sm:grid-cols-2">
        <RouterLink :to="{ name: 'league-newspaper', params: { id } }" class="flex min-h-touch items-center justify-between gap-3 rounded-xl bg-surface px-4 py-3">
          <span><b class="block">{{ $t('جريدة الدوري') }}</b><span class="text-sm text-text-muted">{{ $t('تقرير كل جولة وتشكيلتها المثالية ومقالات المدربين') }}</span></span><span class="font-bold text-gold">←</span>
        </RouterLink>
        <RouterLink :to="{ name: 'league-predictions', params: { id } }" class="flex min-h-touch items-center justify-between gap-3 rounded-xl bg-surface px-4 py-3">
          <span><b class="block">{{ $t('توقعات المدربين') }}</b><span class="text-sm text-text-muted">{{ $t('توقع فائزي الجولة واربح مكافأة لناديك') }}</span></span><span class="font-bold text-gold">←</span>
        </RouterLink>
      </div>

      <RouterLink :to="{ name: 'league-alliance', params: { id } }" class="flex min-h-touch items-center justify-between gap-3 rounded-xl bg-surface px-4 py-3">
        <span><b class="block">{{ $t('بطولة التحالفات') }}</b><span class="text-sm text-text-muted">{{ $t('تحالفان من مدربي الدوري بقائد لكل منهما') }}</span></span>
        <span class="font-bold text-gold">←</span>
      </RouterLink>

      <UiCard v-if="clubs.length" :title="$t('الأندية')">
        <template #action>
          <RouterLink v-if="!league.my_club_id" :to="{ name: 'pick-team', params: { id } }" class="font-bold text-gold">{{ $t('اختر فريقك') }}</RouterLink>
        </template>
        <ul class="flex flex-col gap-1">
          <li
            v-for="c in clubs"
            :key="c.id"
            class="flex min-h-touch items-center gap-3 rounded-lg px-2 py-1.5"
            :class="c.id === league.my_club_id ? 'bg-surface-raised' : ''"
          >
            <ClubCrest :url="c.crest_url" :code="c.code" :size="32" />
            <span class="min-w-0 flex-1 truncate font-bold">{{ $nm(c.name) }}</span>
            <span class="text-sm text-text-muted">{{ c.id === league.my_club_id ? $t('أنت') : c.coach?.name ?? $t('الحاسوب') }}</span>
            <span class="hidden w-16 text-end font-numbers sm:block">{{ money(c.balance) }}</span>
            <span class="w-12 text-end font-numbers text-lg font-bold text-gold">{{ strength(c.strength_cp) }}</span>
          </li>
        </ul>
        <p class="text-xs text-text-muted"><span class="font-numbers">{{ coaches.length }}</span> {{ $t('مدربين، والباقي يديره الحاسوب.') }}</p>
      </UiCard>
    </template>
    <p v-else-if="!error" class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
  </div>
</template>
