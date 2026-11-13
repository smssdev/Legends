<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// A coach's profile (Sprint 33 W1, PLAN 2.11): his record as a coach, his titles and the objectives he was judged
// on, in every league. What stays from season to season. No draft of its own: the design system's cards.
import OfficialBadge from '../../components/OfficialBadge.vue'
import VerifiedBadge from '../../components/VerifiedBadge.vue'
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { cupGoal, cupStage, leagueGoal } from '../../api/leagues'

const props = defineProps<{ id: string }>()
const coach = ref<components['schemas']['CoachProfile'] | null>(null)
const error = ref('')
const TITLES: Record<string, string[]> = { league: ['', 'بطل الدوري', 'المركز الثاني', 'المركز الثالث'], cup: ['', 'بطل الكأس', 'وصيف الكأس'] }

onMounted(async () => {
  try {
    coach.value = (await api.GET('/coaches/{user}', { params: { path: { user: Number(props.id) } } })).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
})
</script>

<template>
  <div class="flex flex-col gap-4">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-else-if="!coach" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <template v-else>
      <header class="flex items-center gap-3">
        <span class="grid size-14 place-items-center rounded-full bg-gold font-display text-2xl font-extrabold text-on-gold">{{ coach.coach.name.slice(0, 1) }}</span>
        <div><h1 class="font-display text-3xl font-extrabold">{{ coach.coach.name }} <OfficialBadge v-if="coach.coach.official" /><VerifiedBadge v-else-if="coach.coach.verified" /></h1><p class="text-sm text-text-muted">{{ $t('ملف المدرب') }}</p></div>
      </header>

      <section :aria-label="$t('السجل')" class="grid grid-cols-3 gap-2 sm:grid-cols-6">
        <div v-for="[k, label] in [['seasons', 'مواسم'], ['played', 'مباريات'], ['won', 'فوز'], ['drawn', 'تعادل'], ['lost', 'خسارة']] as const" :key="k" class="rounded-xl bg-surface p-3 text-center">
          <b class="block font-numbers text-2xl">{{ coach.record[k] }}</b><span class="text-xs text-text-muted">{{ $t(label) }}</span>
        </div>
        <div class="rounded-xl bg-surface p-3 text-center">
          <b class="block font-numbers text-2xl text-gold" dir="ltr">{{ coach.objectives.met }}/{{ coach.objectives.total }}</b><span class="text-xs text-text-muted">{{ $t('أهداف تحققت') }}</span>
        </div>
      </section>

      <section :aria-label="$t('الألقاب')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-xl font-extrabold">{{ $t('الألقاب') }}</h2>
        <p v-if="!coach.titles.length" class="text-sm text-text-muted">{{ $t('لا ألقاب بعد.') }}</p>
        <div v-for="(t, i) in coach.titles" :key="i" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm">
          <b :class="t.position === 1 ? 'text-gold' : ''">{{ $t(TITLES[t.competition]![t.position]) }}</b>
          <span class="flex-1 truncate">{{ $cn(t.club) }} · {{ t.league }}</span>
          <span class="text-text-muted">{{ $t('الموسم {v0}', { v0: t.season }) }}</span>
        </div>
      </section>

      <section :aria-label="$t('الأهداف')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-xl font-extrabold">{{ $t('الأهداف') }}</h2>
        <p v-if="!coach.objectives.list.length" class="text-sm text-text-muted">{{ $t('لم يُقيَّم على هدف بعد.') }}</p>
        <div v-for="(o, i) in coach.objectives.list" :key="i" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm">
          <span class="grid size-7 shrink-0 place-items-center rounded-full text-xs font-bold" :class="o.achieved ? 'bg-success text-on-gold' : 'bg-live text-white'"><Icon :name="o.achieved ? 'check' : 'close'" :size="14" /></span>
          <span class="min-w-0 flex-1">
            <b class="block truncate">{{ o.competition === 'league' ? leagueGoal({ target: Number(o.target), kind: o.kind }) : cupGoal(o.target) }}</b>
            <span class="text-xs text-text-muted">{{ $t('{v0} · {v1} · الموسم {v2}', { v0: $cn(o.club), v1: o.league, v2: o.season }) }}</span>
          </span>
          <span class="text-text-muted">{{ o.competition === 'league' ? $t('المركز {v0}', { v0: o.result }) : cupStage(o.result) }}</span>
        </div>
      </section>
    </template>
  </div>
</template>
