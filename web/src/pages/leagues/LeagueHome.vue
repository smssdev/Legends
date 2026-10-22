<script setup lang="ts">
// One league (Sprint 13 W1): its card, the code to share, my club, and for the owner the join requests
// to approve or reject. The table, fixtures and cup of the draft MobileLeague come with the schedule (Sprint 15).
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { budget, END_MODES, STATUS, when, type JoinRequest, type League, type LeagueClub } from '../../api/leagues'
import ClubCrest from '../../components/ui/ClubCrest.vue'
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

async function share() {
  if (!league.value?.code) return
  const text = `انضم لدوري «${league.value.name}» في الأساطير بالكود: ${league.value.code}`
  try {
    if (navigator.share) await navigator.share({ text })
    else {
      await navigator.clipboard.writeText(league.value.code)
      copied.value = true
      window.setTimeout(() => (copied.value = false), 2000)
    }
  } catch {
    // The share sheet was closed: nothing to do.
  }
}

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

      <div class="grid gap-4 md:grid-cols-2">
        <UiCard v-if="league.code" title="كود الدوري">
          <p class="text-sm text-text-muted">شاركه مع أصحابك: يرسلون طلباً، وتوافق أنت، ثم يختارون فرقهم.</p>
          <div class="flex items-center gap-3">
            <span class="flex-1 rounded-lg bg-surface-sunk px-4 py-3 text-center font-numbers text-3xl font-bold tracking-[0.3em] text-gold" dir="ltr">{{ league.code }}</span>
            <UiButton variant="outline" @click="share">{{ copied ? 'نُسخ' : 'شارك' }}</UiButton>
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
        <p class="text-xs text-text-muted"><span class="font-numbers">{{ coaches.length }}</span> مدربين، والباقي يديره الحاسوب. الترتيب والمباريات والكأس تأتي مع الجدول.</p>
      </UiCard>
    </template>
    <p v-else-if="!error" class="text-text-muted">جارٍ التحميل…</p>
  </div>
</template>
