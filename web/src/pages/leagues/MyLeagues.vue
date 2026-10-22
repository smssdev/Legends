<script setup lang="ts">
// My leagues (Sprint 13 W1): the ones I made, coach in, or asked to join, and the way to make or join one.
// No draft of its own: the cards of WebHome and the "دورياتي (1 من 4)" of the design's top bar.
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import { STATUS, when, type League } from '../../api/leagues'
import UiChip from '../../components/ui/UiChip.vue'

const leagues = ref<League[]>([])
const active = ref(0)
const max = ref(4)
const loaded = ref(false)
const error = ref('')

onMounted(async () => {
  try {
    const { data } = await api.GET('/leagues')
    leagues.value = data!.leagues
    active.value = data!.active_teams
    max.value = data!.max_active_teams
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
})

/** Where a league's card leads: the club list once approved and still without a club, the league otherwise. */
function link(l: League) {
  if (l.my_request === 'pending') return { name: 'join', query: { league: l.id } }
  if (!l.my_club_id && (l.is_owner || l.my_request === 'approved')) return { name: 'pick-team', params: { id: l.id } }
  return { name: 'league-home', params: { id: l.id } }
}
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="font-display text-3xl font-extrabold">دورياتي</h1>
        <p class="mt-1 text-text-muted">
          <span class="font-numbers">{{ active }}</span> من <span class="font-numbers">{{ max }}</span> فرق نشطة
        </p>
      </div>
      <div class="flex gap-2">
        <RouterLink :to="{ name: 'join' }" class="flex h-12 items-center rounded-lg border border-gold/70 px-5 font-display font-extrabold text-gold hover:bg-gold/10">انضم بكود</RouterLink>
        <RouterLink
          v-if="active < max"
          :to="{ name: 'create-league' }"
          class="flex h-12 items-center rounded-lg bg-gold px-5 font-display font-extrabold text-on-gold hover:bg-gold-light"
        >
          أنشئ دورياً
        </RouterLink>
      </div>
    </div>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-else-if="!loaded" class="text-text-muted">جارٍ التحميل…</p>

    <div v-else-if="leagues.length === 0" class="flex flex-col items-center gap-3 rounded-xl bg-surface p-8 text-center">
      <h2 class="font-display text-xl font-extrabold">لا دوريات بعد</h2>
      <p class="max-w-md text-text-muted">أنشئ دورياً وشارك كوده مع أصحابك، أو اطلب من صاحبك كود دوريه وانضم إليه.</p>
    </div>

    <div v-else class="grid gap-3 md:grid-cols-2">
      <RouterLink v-for="l in leagues" :key="l.id" :to="link(l)" class="flex flex-col gap-3 rounded-xl bg-surface p-4 hover:bg-surface-raised">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h2 class="truncate font-display text-xl font-extrabold">{{ l.name }}</h2>
            <p class="text-sm text-text-muted">{{ l.template }} · <span class="font-numbers">{{ l.team_count }}</span> فريقاً</p>
          </div>
          <UiChip :tone="l.status === 'running' ? 'win' : 'neutral'">{{ STATUS[l.status] }}</UiChip>
        </div>
        <p v-if="l.me?.absence_warning" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]" role="alert">
          لم تدخل هذا الدوري منذ يومين. ادخله قبل {{ l.me.away_deadline ? when(l.me.away_deadline) : 'نهاية اليوم الثالث' }} وإلا يعود فريقك للحاسوب.
        </p>
        <div class="flex flex-wrap items-center gap-2 text-sm">
          <UiChip v-if="l.is_owner" tone="gold">أنشأته</UiChip>
          <UiChip v-if="l.my_request === 'pending'" tone="warning">بانتظار الموافقة</UiChip>
          <UiChip v-else-if="!l.my_club_id" tone="gold">اختر فريقك</UiChip>
          <UiChip v-if="l.is_owner && l.pending_requests" tone="live">{{ l.pending_requests }} طلبات</UiChip>
          <UiChip v-if="l.me?.on_holiday" tone="warning">في إجازة</UiChip>
          <span class="text-text-muted">البداية: {{ when(l.starts_at) }}</span>
        </div>
      </RouterLink>
    </div>
  </div>
</template>
