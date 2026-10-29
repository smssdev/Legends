<script setup lang="ts">
// Choose a club (Sprint 13 W1), after the drafts MobilePickTeam and WebPickTeam: every club strongest first,
// those with a coach shown but locked, the chosen one's squad and money, and one button to take it.
// Someone faster gets 409 "الفريق أُخذ": the list comes back fresh and the coach picks again [PLAN 2.1].
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { League, LeagueClub, LeaguePlayer } from '../../api/leagues'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import UiButton from '../../components/ui/UiButton.vue'
import { money, strength } from '../../lib/format'
import { cupGoal, leagueGoal } from '../../api/leagues'
import type { Line } from '../../lib/format'

const props = defineProps<{ id: string }>()
const router = useRouter()
const league = ref<League | null>(null)
const clubs = ref<LeagueClub[]>([])
const chosen = ref<LeagueClub | null>(null)
const squad = ref<LeaguePlayer[]>([])
const error = ref('')
const taking = ref(false)

const free = computed(() => clubs.value.filter((c) => c.bot))
const leagueId = computed(() => Number(props.id))

async function load() {
  const [l, c] = await Promise.all([
    api.GET('/leagues/{league}', { params: { path: { league: leagueId.value } } }),
    api.GET('/leagues/{league}/clubs', { params: { path: { league: leagueId.value } } }),
  ])
  league.value = l.data!.league
  clubs.value = c.data!.clubs
  if (league.value.my_club_id) router.replace({ name: 'league-home', params: { id: props.id } })
}

async function choose(c: LeagueClub) {
  if (!c.bot) return
  chosen.value = c
  squad.value = []
  const { data } = await api.GET('/leagues/{league}/clubs/{club}', { params: { path: { league: leagueId.value, club: c.id } } })
  if (chosen.value?.id === c.id) squad.value = data!.players ?? []
}

async function take() {
  if (!chosen.value) return
  error.value = ''
  taking.value = true
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/clubs/{club}/claim', { params: { path: { league: leagueId.value, club: chosen.value.id } } })
    router.push({ name: 'league-home', params: { id: props.id }, query: { welcome: '1' } })
  } catch (e) {
    const err = asApiError(e)
    error.value = err.message
    if (err.status === 409) {
      chosen.value = null
      await load().catch(() => {})
    }
  }
  taking.value = false
}

onMounted(() => load().catch((e) => (error.value = asApiError(e).message)))
</script>

<template>
  <div class="flex flex-col gap-4 pb-36 md:pb-0">
    <header>
      <p v-if="league && !league.is_owner" class="text-sm font-bold text-success">{{ $t('وافق {v0} على طلبك', { v0: league.owner?.name }) }}</p>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('اختر فريقك') }}</h1>
      <p class="text-text-muted">
        <span class="font-numbers">{{ free.length }}</span> {{ $t('نادياً متاحاً · الأقوى أولاً') }}<span v-if="league"> · {{ $nm(league.name) }}</span>
      </p>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <div class="grid gap-4 md:grid-cols-[1fr_22rem]">
      <ul class="flex flex-col gap-2" :aria-label="$t('الأندية')">
        <li v-for="c in clubs" :key="c.id">
          <button
            type="button"
            class="flex min-h-20 w-full items-center gap-3 rounded-xl border p-3 text-start transition"
            :class="[
              chosen?.id === c.id ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface',
              c.bot ? 'hover:bg-surface-raised' : 'cursor-not-allowed opacity-50',
            ]"
            :disabled="!c.bot"
            :aria-pressed="chosen?.id === c.id"
            @click="choose(c)"
          >
            <ClubCrest :url="c.crest_url" :code="c.code" :size="48" />
            <span class="min-w-0 flex-1">
              <span class="block truncate font-display text-lg font-extrabold">{{ $nm(c.name) }}</span>
              <span v-if="c.bot" class="text-sm text-success">{{ $t('متاح') }}</span>
              <span v-else class="text-sm text-text-muted">{{ $t('مع {v0}', { v0: c.coach?.name }) }}</span>
            </span>
            <span class="hidden text-sm text-text-muted sm:block">
              <span class="block">{{ $t('الميزانية') }} <span class="font-numbers text-base text-text">{{ money(c.balance) }}</span></span>
              <span class="block">{{ $t('التشكيلة') }} <span class="font-numbers text-base text-text">{{ money(c.squad_value) }}</span></span>
            </span>
            <span class="font-numbers text-3xl font-bold text-gold">{{ strength(c.strength_cp) }}</span>
          </button>
        </li>
      </ul>

      <aside v-if="chosen" class="flex h-fit flex-col gap-3 rounded-xl bg-surface p-4 md:sticky md:top-4" aria-live="polite">
        <div class="flex items-center gap-3">
          <ClubCrest :url="chosen.crest_url" :code="chosen.code" :size="40" />
          <h2 class="font-display text-xl font-extrabold">{{ $nm(chosen.name) }}</h2>
        </div>
        <dl class="grid grid-cols-3 gap-2 text-center text-sm">
          <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-text-muted">{{ $t('القوة') }}</dt><dd class="font-numbers text-lg">{{ strength(chosen.strength_cp) }}</dd></div>
          <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-text-muted">{{ $t('الميزانية') }}</dt><dd class="font-numbers text-lg">{{ money(chosen.balance) }}</dd></div>
          <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-text-muted">{{ $t('اللاعبون') }}</dt><dd class="font-numbers text-lg">{{ chosen.players_count }}</dd></div>
        </dl>
        <div v-if="chosen.objectives" class="flex flex-col gap-1 rounded-lg border border-gold/30 bg-gold/10 p-3 text-sm" :aria-label="$t('هدف النادي')">
          <b class="text-gold">{{ $t('هدف الإدارة هذا الموسم') }}</b>
          <span>{{ $t('الدوري: {v0}', { v0: leagueGoal(chosen.objectives.league) }) }}</span>
          <span>{{ $t('الكأس: {v0}', { v0: cupGoal(chosen.objectives.cup.target) }) }}</span>
        </div>
        <ul class="flex max-h-80 flex-col gap-1 overflow-y-auto text-sm" :aria-label="$t('اللاعبون')">
          <li v-for="p in squad" :key="p.id" class="flex items-center gap-2 rounded-md px-2 py-1.5 odd:bg-surface-sunk">
            <LineBadge :line="p.line as Line" />
            <span class="min-w-0 flex-1 truncate">{{ $nm(p.name) }}</span>
            <span class="font-numbers text-text-muted">{{ p.age }}</span>
            <span class="w-8 text-center font-numbers text-base font-bold">{{ p.overall }}</span>
          </li>
        </ul>
      </aside>
    </div>

    <div class="fixed inset-x-0 bottom-20 z-10 border-t border-text/10 bg-bg-deep/95 p-4 md:static md:border-0 md:bg-transparent md:p-0">
      <UiButton block :disabled="!chosen || taking" @click="take">
        {{ chosen ? $t('استلم تدريب {v0}', { v0: chosen.name }) : $t('اختر نادياً متاحاً') }}
      </UiButton>
    </div>
  </div>
</template>
