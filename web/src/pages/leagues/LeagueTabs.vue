<script setup lang="ts">
// The league's three tabs (Sprint 15 W1), after the draft MobileLeague: the table (with "played" and
// "rests" when the count is odd), the calendar in the device's own time, and the cup's bracket.
import { intlLocale } from '../../lib/i18n'
import { computed, onMounted, ref } from 'vue'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import UiChip from '../../components/ui/UiChip.vue'

type Fixture = components['schemas']['Fixture']
type Season = components['schemas']['SeasonCalendar']
type Row = { position: number; id: number; name: string; code: string; crest_url: string; coach?: string | null; played: number; goal_difference: number; points: number; rests_next: boolean }
type Stage = { stage: string; scheduled_at: string; ties: { id: number; slot: number; home?: { name: string; code: string; crest_url: string } | null; away?: { name: string; code: string; crest_url: string } | null; next?: { slot: number; side: string } | null }[] }

const props = defineProps<{ leagueId: number; myClubId?: number | null; teamCount: number }>()
const PODIUM: Record<number, string> = { 1: 'bg-gradient-to-b from-gold-light to-gold text-on-gold shadow shadow-gold/30', 2: 'bg-gradient-to-b from-[#E4E9F2] to-[#A9B6CC] text-on-gold', 3: 'bg-gradient-to-b from-[#E0A06A] to-[#B4692A] text-white' }
const tab = ref<'table' | 'fixtures' | 'cup' | 'honours'>('table')
// The hall of fame (Sprint 33): loaded when its tab is opened.
type Honours = components['schemas']['Honours']
const honours = ref<Honours | null>(null)
async function openHonours() {
  tab.value = 'honours'
  if (honours.value) return
  try {
    honours.value = (await api.GET('/leagues/{league}/honours', { params: { path: { league: props.leagueId } } })).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const MEDALS = ['', 'الأول', 'الثاني', 'الثالث']
const table = ref<Row[]>([])
const fixtures = ref<Fixture[]>([])
const stages = ref<Stage[]>([])
const season = ref<Season | null>(null)
const error = ref('')
const squadOf = ref<number | null>(null)

const STAGES: Record<string, string> = { preliminary: 'الدور التمهيدي', r16: 'دور الـ16', qf: 'ربع النهائي', sf: 'نصف النهائي', final: 'النهائي' }

onMounted(async () => {
  const path = { league: props.leagueId }
  try {
    const [t, f, c] = await Promise.all([
      api.GET('/leagues/{league}/standings', { params: { path } }),
      api.GET('/leagues/{league}/fixtures', { params: { path } }),
      api.GET('/leagues/{league}/cup', { params: { path } }),
    ])
    table.value = t.data!.table as Row[]
    season.value = t.data!.season
    fixtures.value = f.data!.fixtures
    stages.value = c.data!.stages as Stage[]
  } catch (e) {
    error.value = asApiError(e).message
  }
})

const day = { format: (d: Date) => new Intl.DateTimeFormat(intlLocale(), { weekday: 'long', day: 'numeric', month: 'long' }).format(d) }
const time = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' })
const dayKey = (iso: string) => new Date(iso).toDateString()

/** The calendar by the device's own days; the winter day shows as a day with no matches. */
const days = computed(() => {
  const out: { key: string; label: string; items: Fixture[] }[] = []
  for (const f of fixtures.value) {
    const key = dayKey(f.scheduled_at)
    if (out[out.length - 1]?.key !== key) out.push({ key, label: day.format(new Date(f.scheduled_at)), items: [] })
    out[out.length - 1].items.push(f)
  }
  return out
})
const winter = computed(() => (season.value?.winter_break_on ? day.format(new Date(season.value.winter_break_on + 'T12:00:00')) : ''))
const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
</script>

<template>
  <section class="flex flex-col gap-3 rounded-xl bg-surface p-3 md:p-5" :aria-label="$t('الدوري')">
    <div class="grid grid-cols-4 gap-1 rounded-xl bg-surface-sunk p-1" role="tablist">
      <button
        v-for="(label, key) in { table: 'الترتيب', fixtures: 'المباريات', cup: 'الكأس' }"
        :key="key"
        type="button"
        role="tab"
        class="h-12 rounded-lg font-display text-base font-extrabold md:text-lg"
        :class="tab === key ? 'bg-gold text-on-gold' : 'text-text-soft'"
        :aria-selected="tab === key"
        @click="tab = key"
      >{{ $t(label) }}</button>
      <button type="button" role="tab" class="h-12 rounded-lg font-display text-base font-extrabold md:text-lg" :class="tab === 'honours' ? 'bg-gold text-on-gold' : 'text-text-soft'"
        :aria-selected="tab === 'honours'" @click="openHonours">{{ $t('الشرف') }}</button>
    </div>
    <p v-if="error" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>

    <!-- [Sprint 21 E3.5] Until the table comes, a row per club holds its place, so the page does not jump. -->
    <div v-if="!season && !error && tab === 'table'" class="flex flex-col gap-1.5" aria-hidden="true">
      <div class="h-5 w-2/3 animate-pulse rounded bg-surface-sunk" />
      <div v-for="i in teamCount + 1" :key="i" class="h-9 animate-pulse rounded-md bg-surface-sunk" />
    </div>
    <template v-else-if="tab === 'table'">
      <p v-if="season" class="text-sm text-text-muted">
        {{ $t('الجولة') }} <span class="font-numbers">{{ season.rounds_played }}</span> {{ $t('من') }} <span class="font-numbers">{{ season.rounds }}</span> {{ $t('· منطقة القفل من الجولة') }}
        <span class="font-numbers">{{ season.lock_from_round }}</span>
      </p>
      <table class="w-full text-sm">
        <thead class="text-text-muted">
          <tr>
            <th class="w-8 py-2 text-start font-normal">#</th>
            <th class="py-2 text-start font-normal">{{ $t('النادي') }}</th>
            <th class="w-10 py-2 font-normal">{{ $t('لعب') }}</th>
            <th class="w-10 py-2 font-normal">+/-</th>
            <th class="w-12 py-2 font-normal">{{ $t('نقاط') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in table" :key="r.id" class="relative" :class="r.id === myClubId ? 'is-mine' : ''">
            <!-- [X29] The podium: gold, silver and bronze places, as the sports tables mark them. -->
            <td class="py-2"><span class="grid size-7 place-items-center rounded-md font-numbers text-base font-bold" :class="PODIUM[r.position] ?? 'text-text-soft'">{{ r.position }}</span></td>
            <td class="py-2">
              <!-- [Sprint 21 E4.1] Any club in the table opens its squad (never its tactics). -->
              <button type="button" class="flex min-h-touch w-full items-center gap-2 text-start hover:text-gold" :aria-label="$t('لاعبو {v0}', { v0: $nm(r.name) })" @click="squadOf = r.id">
                <ClubCrest :url="r.crest_url" :code="r.code" :size="28" />
                <span class="truncate font-bold">{{ $nm(r.name) }}</span>
                <span class="truncate text-xs text-text-muted">{{ r.id === myClubId ? $t('أنت') : r.coach }}</span>
                <UiChip v-if="r.rests_next" tone="neutral">{{ $t('استراحة') }}</UiChip>
              </button>
            </td>
            <td class="text-center font-numbers text-base">{{ r.played }}</td>
            <td class="text-center font-numbers text-base" dir="ltr">{{ r.goal_difference > 0 ? '+' : '' }}{{ r.goal_difference }}</td>
            <td class="text-center font-numbers text-lg font-bold text-gold">{{ r.points }}</td>
          </tr>
        </tbody>
      </table>
    </template>

    <template v-else-if="tab === 'fixtures'">
      <p class="text-xs text-text-muted">{{ $t('بتوقيت جهازك ({v0}).', { v0: zone }) }}<template v-if="winter"> {{ $t('يوم الراحة الشتوي بلا مباريات: {v0}.', { v0: winter }) }}</template></p>
      <div v-for="d in days" :key="d.key" class="flex flex-col gap-1">
        <h3 class="mt-2 font-bold text-text-soft">{{ $t(d.label) }}</h3>
        <div v-for="f in d.items" :key="f.id" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm" :class="(f.home?.id === myClubId || f.away?.id === myClubId) && myClubId ? 'border border-gold/40' : ''">
          <span class="w-12 shrink-0 font-numbers text-base" dir="ltr">{{ time.format(new Date(f.scheduled_at)) }}</span>
          <UiChip :tone="f.competition === 'cup' ? 'gold' : 'neutral'">
            {{ f.competition === 'cup' ? STAGES[f.stage ?? ''] : f.competition === 'alliance' ? $t('التحالفات {v0}', { v0: f.round }) : $t('الجولة {v0}', { v0: f.round }) }}{{ f.slot === 2 ? $t(' · السهرة') : '' }}
          </UiChip>
          <UiChip v-if="f.match_of_day" tone="gold">{{ $t('⭐ قمة الجولة') }}</UiChip>
          <span v-if="f.is_bye" class="text-text-muted">{{ $t('استراحة: {v0}', { v0: $nm(f.home?.name) }) }}</span>
          <span v-else class="flex min-w-0 flex-1 items-center justify-center gap-2">
            <span class="flex-1 text-end">{{ f.home?.name ?? $t('يتحدد') }}</span>
            <span class="font-numbers text-text-muted">{{ f.status === 'finished' ? `${f.home_goals} - ${f.away_goals}` : '-' }}</span>
            <span class="flex-1">{{ f.away?.name ?? $t('يتحدد') }}</span>
          </span>
          <UiChip v-if="f.competition === 'league' && season && f.round >= season.lock_from_round" tone="warning">{{ $t('قفل') }}</UiChip>
        </div>
      </div>
    </template>

    <template v-else-if="tab === 'honours'">
      <p v-if="!honours" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
      <div v-for="s in honours?.seasons ?? []" :key="s.number" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <h3 class="font-display text-lg font-extrabold">{{ $t('الموسم {v0}', { v0: s.number }) }} <UiChip v-if="s.status !== 'finished'" tone="neutral">{{ $t('يجري الآن') }}</UiChip></h3>
        <p v-if="!s.titles.length" class="text-sm text-text-muted">{{ $t('لم يُحسم بعد.') }}</p>
        <div v-for="t in s.titles" :key="t.competition + t.position" class="flex min-h-touch items-center gap-2 text-sm">
          <UiChip :tone="t.position === 1 ? 'gold' : 'neutral'">{{ t.competition === 'cup' ? (t.position === 1 ? $t('بطل الكأس') : $t('وصيف الكأس')) : (t.position === 1 ? $t('بطل الدوري') : MEDALS[t.position]) }}</UiChip>
          <ClubCrest :url="t.club.crest_url" :code="t.club.name.slice(0, 3)" :size="24" />
          <span class="flex-1 truncate font-bold">{{ $nm(t.club.name) }}</span>
          <RouterLink v-if="t.coach" :to="{ name: 'coach', params: { id: t.coach.id } }" class="text-gold">{{ t.coach.name }}</RouterLink>
          <span v-else class="text-text-muted">{{ $t('الحاسوب') }}</span>
        </div>
      </div>
    </template>

    <template v-else>
      <div class="flex gap-3 overflow-x-auto pb-2">
        <div v-for="s in stages" :key="s.stage" class="flex min-w-48 flex-col gap-2">
          <h3 class="font-display font-extrabold text-gold">{{ $t(STAGES[s.stage]) }}</h3>
          <p class="text-xs text-text-muted">{{ day.format(new Date(s.scheduled_at)) }} · <span dir="ltr">{{ time.format(new Date(s.scheduled_at)) }}</span></p>
          <div class="flex flex-1 flex-col justify-around gap-2">
            <div v-for="t in s.ties" :key="t.id" class="flex flex-col gap-1 rounded-lg bg-surface-sunk p-2 text-sm">
              <span v-for="side in ['home', 'away'] as const" :key="side" class="flex items-center gap-2">
                <ClubCrest v-if="t[side]" :url="t[side]!.crest_url" :code="t[side]!.code" :size="22" />
                <span :class="t[side] ? 'font-bold' : 'text-text-muted'" class="truncate">{{ t[side]?.name ?? $t('الفائز من الدور السابق') }}</span>
              </span>
            </div>
          </div>
        </div>
      </div>
    </template>
    <ClubSquadDialog v-if="squadOf" :league-id="leagueId" :club-id="squadOf" @close="squadOf = null" />
  </section>
</template>
