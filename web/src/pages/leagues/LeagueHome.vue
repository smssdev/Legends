<script setup lang="ts">
// One league (Sprints 13 to 15): the table, calendar and cup (LeagueTabs), its card, the invite to share, my club, my presence and holiday,
// the coaches (the owner can send one away with a reason), who left and why, and the join requests.
// Sprint 14's parts have no draft yet: built with the same cards, waiting for approval like Sprint 10's. The table, fixtures and cup of the draft MobileLeague come with the schedule (Sprint 15).
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { budget, END_MODES, STATUS, when, type JoinRequest, type League, type LeagueClub } from '../../api/leagues'
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
    const { data } = await api.GET('/leagues/{league}', { params: { path: { league: leagueId.value } } })
    league.value = data!.league
    if (league.value.my_club_id) rememberLeague(league.value.id)
    if (league.value.is_owner || league.value.my_request === 'approved') {
      clubs.value = (await api.GET('/leagues/{league}/clubs', { params: { path: { league: leagueId.value } } })).data!.clubs
    }
    if (league.value.is_owner) {
      requests.value = (await api.GET('/leagues/{league}/requests', { params: { path: { league: leagueId.value } } })).data!.requests ?? []
    }
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
const inviteText = computed(() => (league.value ? `انضم لدوري «${league.value.name}» في الأساطير واختر ناديك: ${league.value.invite_url}` : ''))
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

// A holiday of up to 7 days, once a season [PLAN 2.2].
const days = ref(3)
async function holiday(start: boolean) {
  error.value = ''
  try {
    await ensureCsrf()
    const path = { league: leagueId.value }
    const { data } = start
      ? await api.POST('/leagues/{league}/vacation', { params: { path }, body: { days: days.value } })
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
      أهلاً بك مدرباً لـ{{ mine.name }}. {{ league?.is_owner ? 'شارك الكود مع أصحابك ليختاروا فرقهم.' : 'بالتوفيق في الموسم!' }}
    </p>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>

    <template v-if="league">
      <header class="flex flex-wrap items-end justify-between gap-3">
        <div class="min-w-0">
          <h1 class="font-display text-3xl font-extrabold">{{ league.name }}</h1>
          <p class="text-text-muted">
            {{ league.template }} · <span class="font-numbers">{{ league.season?.rounds }}</span> جولة · منطقة القفل من الجولة
            <span class="font-numbers">{{ league.season?.lock_from_round }}</span>
          </p>
        </div>
        <div class="flex flex-wrap gap-2">
          <UiChip :tone="league.status === 'running' ? 'win' : 'neutral'">{{ STATUS[league.status] }}</UiChip>
          <UiChip v-if="league.fair_league" tone="win">دوري نزيه</UiChip>
          <UiChip v-if="league.is_dev" tone="gold">للتطوير</UiChip>
        </div>
      </header>

      <LeagueTabs v-if="clubs.length" :league-id="leagueId" :my-club-id="league.my_club_id" :team-count="league.team_count" />

      <div class="grid gap-4 md:grid-cols-2">
        <UiCard v-if="league.code" title="ادعُ أصحابك">
          <p class="text-sm text-text-muted">الرابط يفتح صفحة الانضمام بالكود جاهزاً: يرسلون طلباً، وتوافق أنت، ثم يختارون فرقهم.</p>
          <span class="rounded-lg bg-surface-sunk px-4 py-3 text-center font-numbers text-3xl font-bold tracking-[0.3em] text-gold" dir="ltr">{{ league.code }}</span>
          <div class="grid grid-cols-2 gap-2">
            <a :href="whatsapp" target="_blank" rel="noopener" class="flex h-12 items-center justify-center rounded-lg bg-success font-display font-extrabold text-on-gold">واتساب</a>
            <UiButton variant="outline" @click="share">{{ copied ? 'نُسخ الرابط' : 'شارك الرابط' }}</UiButton>
          </div>
        </UiCard>

        <UiCard title="الموسم">
          <dl class="grid grid-cols-2 gap-2 text-sm">
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">البداية</dt><dd class="font-bold">{{ when(league.starts_at) }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">الإعداد</dt><dd class="font-bold">{{ ['يوم', 'يومان', '3 أيام'][league.prep_days - 1] }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3">
              <dt class="text-text-muted">الجولات</dt>
              <dd class="font-bold" dir="ltr">{{ league.round_times.join(' · ') }}</dd>
            </div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">الميزانية</dt><dd class="font-bold">{{ budget(league.starting_budget) }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">المدربون</dt><dd class="font-bold"><span class="font-numbers">{{ league.coaches }}</span> من <span class="font-numbers">{{ league.team_count }}</span></dd></div>
            <div class="rounded-lg bg-surface-sunk p-3"><dt class="text-text-muted">نهاية الموسم</dt><dd class="font-bold">{{ END_MODES[league.season_end_mode] }}</dd></div>
          </dl>
          <p class="text-xs text-text-muted">{{ league.locked ? 'الإعدادات مقفلة منذ بداية الموسم.' : 'الإعدادات تُقفل عند بداية الموسم.' }} ساعات الجولات بتوقيت القاهرة.</p>
          <UiButton v-if="isDev && league.is_owner && !league.locked" variant="quiet" @click="startNow">ابدأ الآن (للتطوير)</UiButton>
        </UiCard>
      </div>

      <UiCard v-if="league.me" title="حضورك">
        <p v-if="league.me.on_holiday" class="rounded-lg bg-gold/15 px-3 py-2 text-sm">
          أنت في إجازة حتى {{ since(league.me.vacation_until) }}. لا يُحسب غيابك، والمساعد يدير فريقك.
        </p>
        <p v-else-if="league.me.away_deadline" class="text-sm text-text-muted">
          كل دخول للدوري يُحسب حضوراً. لو غبت 3 أيام متواصلة يعود فريقك للحاسوب: آخر موعد الآن {{ since(league.me.away_deadline) }}.
        </p>
        <p v-else class="text-sm text-text-muted">عداد الغياب يبدأ مع بداية الموسم.</p>
        <UiButton v-if="league.me.on_holiday" variant="quiet" @click="holiday(false)">عدت مبكراً، أنهِ الإجازة</UiButton>
        <form v-else-if="!league.me.vacation_used" class="flex flex-wrap items-end gap-2" @submit.prevent="holiday(true)">
          <label class="flex flex-col gap-1.5">
            <span class="text-sm font-bold">إجازة (مرة في الموسم)</span>
            <select v-model.number="days" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-4">
              <option v-for="d in 7" :key="d" :value="d">{{ d === 1 ? 'يوم' : d === 2 ? 'يومان' : `${d} أيام` }}</option>
            </select>
          </label>
          <UiButton type="submit" variant="outline">فعّل الإجازة</UiButton>
        </form>
        <p v-else class="text-sm text-text-muted">استخدمت إجازة هذا الموسم.</p>
        <div v-if="!league.is_owner" class="flex flex-col gap-2 border-t border-text/10 pt-3">
          <p v-if="resignError" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]" role="alert">{{ resignError }}</p>
          <UiButton v-if="!confirmResign" variant="quiet" @click="confirmResign = true">الاستقالة من الدوري</UiButton>
          <template v-else>
            <p class="rounded-lg bg-live/15 px-3 py-2 text-sm">يعود فريقك للحاسوب بحالته، ولا تعود لهذا الدوري قبل الموسم الجديد. متأكد؟</p>
            <div class="flex gap-2">
              <UiButton variant="danger" @click="resign">نعم، أستقيل</UiButton>
              <UiButton variant="quiet" @click="confirmResign = false">تراجع</UiButton>
            </div>
          </template>
        </div>
      </UiCard>

      <UiCard v-if="league.members.length" title="المدربون">
        <ul class="flex flex-col gap-2">
          <li v-for="m in league.members" :key="m.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
            <div class="flex min-h-touch flex-wrap items-center gap-3">
              <span class="flex size-10 items-center justify-center rounded-full bg-surface-raised font-display font-extrabold">{{ m.user.name.charAt(0) }}</span>
              <span class="min-w-0 flex-1">
                <span class="block truncate font-bold">{{ m.user.name }} <UiChip v-if="m.is_owner" tone="gold">المنشئ</UiChip> <UiChip v-if="m.on_holiday" tone="warning">في إجازة</UiChip></span>
                <span class="block text-sm text-text-muted">{{ m.club?.name }}<template v-if="league.is_owner && m.last_active_at"> · آخر دخول {{ since(m.last_active_at) }}</template></span>
              </span>
              <UiButton v-if="league.is_owner && !m.is_owner && kicking !== m.id" variant="quiet" @click="(kicking = m.id), (reason = ''), (reasonError = '')">اطرد</UiButton>
            </div>
            <form v-if="kicking === m.id" class="flex flex-col gap-2" @submit.prevent="kick(m.id)">
              <label class="flex flex-col gap-1.5">
                <span class="text-sm font-bold">سبب الطرد (يراه كل أعضاء الدوري)</span>
                <textarea v-model="reason" rows="2" maxlength="200" class="rounded-lg border border-text/10 bg-surface p-3" :aria-invalid="!!reasonError" />
              </label>
              <p v-if="reasonError" class="text-sm text-[#FF8A8A]" role="alert">{{ reasonError }}</p>
              <p class="text-xs text-text-muted">يعود فريقه للحاسوب بحالته، ولا يعود للدوري هذا الموسم.</p>
              <div class="flex gap-2">
                <UiButton type="submit" variant="danger">اطرد {{ m.user.name }}</UiButton>
                <UiButton variant="quiet" @click="kicking = null">إلغاء</UiButton>
              </div>
            </form>
          </li>
        </ul>
      </UiCard>

      <UiCard v-if="league.departures.length" title="غادروا هذا الموسم">
        <ul class="flex flex-col gap-2 text-sm">
          <li v-for="(d, i) in league.departures" :key="i" class="rounded-lg bg-surface-sunk p-3">
            <span class="font-bold">{{ d.user }}</span><span v-if="d.club" class="text-text-muted"> ({{ d.club }})</span>: {{ LEFT[d.reason] }}
            <span v-if="d.kick_reason" class="mt-1 block">السبب: «{{ d.kick_reason }}»</span>
            <span class="block text-xs text-text-muted">{{ since(d.left_at) }}</span>
          </li>
        </ul>
      </UiCard>

      <UiCard v-if="league.is_owner" title="طلبات الانضمام">
        <template #action><UiChip v-if="waiting.length" tone="live">{{ waiting.length }} بانتظارك</UiChip></template>
        <p v-if="!requests.length" class="text-sm text-text-muted">لا طلبات بعد. شارك الكود ليصل أصحابك.</p>
        <ul v-else class="flex flex-col gap-2">
          <li v-for="r in requests" :key="r.id" class="flex min-h-touch flex-wrap items-center gap-3 rounded-lg bg-surface-sunk p-3">
            <span class="flex size-10 items-center justify-center rounded-full bg-surface-raised font-display font-extrabold">{{ r.user?.name.charAt(0) }}</span>
            <span class="min-w-0 flex-1 truncate font-bold">{{ r.user?.name }}</span>
            <template v-if="r.status === 'pending'">
              <UiButton @click="decide(r, true)">وافق</UiButton>
              <UiButton variant="quiet" @click="decide(r, false)">ارفض</UiButton>
            </template>
            <UiChip v-else :tone="r.status === 'approved' ? 'win' : 'loss'">{{ r.status === 'approved' ? 'وافقت' : 'رفضت' }}</UiChip>
          </li>
        </ul>
      </UiCard>

      <UiCard v-if="clubs.length" title="الأندية">
        <template #action>
          <RouterLink v-if="!league.my_club_id" :to="{ name: 'pick-team', params: { id } }" class="font-bold text-gold">اختر فريقك</RouterLink>
        </template>
        <ul class="flex flex-col gap-1">
          <li
            v-for="c in clubs"
            :key="c.id"
            class="flex min-h-touch items-center gap-3 rounded-lg px-2 py-1.5"
            :class="c.id === league.my_club_id ? 'bg-surface-raised' : ''"
          >
            <ClubCrest :url="c.crest_url" :code="c.code" :size="32" />
            <span class="min-w-0 flex-1 truncate font-bold">{{ c.name }}</span>
            <span class="text-sm text-text-muted">{{ c.id === league.my_club_id ? 'أنت' : c.coach?.name ?? 'الحاسوب' }}</span>
            <span class="hidden w-16 text-end font-numbers sm:block">{{ money(c.balance) }}</span>
            <span class="w-12 text-end font-numbers text-lg font-bold text-gold">{{ strength(c.strength_cp) }}</span>
          </li>
        </ul>
        <p class="text-xs text-text-muted"><span class="font-numbers">{{ coaches.length }}</span> مدربين، والباقي يديره الحاسوب.</p>
      </UiCard>
    </template>
    <p v-else-if="!error" class="text-text-muted">جارٍ التحميل…</p>
  </div>
</template>
