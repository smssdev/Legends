<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// [UP12] The coaches' predictions (the owner's spec 6): the round's matches, a pick for each until its lock, and how
// the league picked. A right pick pays the predictor's club and counts on his career; the server decides it all.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { money } from '../../lib/format'

const props = defineProps<{ id: string }>()
type Round = {
  round: number | null
  reward?: number
  predictors?: number
  matches: {
    fixture_id: number
    status: string
    open: boolean
    home: { name: string }
    away: { name: string }
    mine: string | null
    split: Record<string, number>
  }[]
}
const r = ref<Round | null>(null)
const error = ref('')
const PICKS = [
  { id: 'home', label: 'فوز صاحب الأرض' },
  { id: 'draw', label: 'تعادل' },
  { id: 'away', label: 'فوز الضيف' },
]

async function load() {
  try {
    r.value = (await api.GET('/leagues/{league}/predictions', { params: { path: { league: Number(props.id) } } })).data as unknown as Round
  } catch (e) {
    error.value = asApiError(e).message
  }
}
async function pick(fixture: number, p: string) {
  error.value = ''
  try {
    await ensureCsrf()
    r.value = (
      await api.POST('/leagues/{league}/predictions', {
        params: { path: { league: Number(props.id) } },
        body: { fixture_id: fixture, pick: p as 'home' },
      })
    ).data as unknown as Round
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const pct = (split: Record<string, number>, k: string) => {
  const t = Object.values(split).reduce((a, b) => a + b, 0)
  return t ? Math.round((split[k] * 100) / t) : 0
}
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-4">
    <header>
      <RouterLink :to="{ name: 'league-home', params: { id } }" class="text-sm text-text-muted">{{ $t('› الدوري') }}</RouterLink>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('توقعات المدربين') }}</h1>
      <p v-if="r?.round" class="text-sm text-text-muted">
        {{ $t('الجولة {v0} · التوقع الصحيح يمنح ناديك', { v0: r.round }) }}
        <b dir="ltr" class="font-numbers text-gold">{{ money(r.reward ?? 0) }}</b> {{ $t('ونقطة خبرة') }}
      </p>
      <!-- [Sprint 21 E4.4] How many coaches have predicted this round. -->
      <p v-if="r?.round" class="mt-2 inline-flex items-center gap-2 rounded-pill bg-surface px-3 py-1.5 text-sm">
        <span aria-hidden="true"><Icon name="team" :size="18" class="inline-block align-[-3px]" /></span
        >{{ $t('توقّع {v0} من المدربين هذه الجولة', { v0: r.predictors ?? 0 }) }}
      </p>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="r && !r.round" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('لا جولة قادمة الآن.') }}</p>
    <ul v-if="r?.round" class="grid gap-3 md:grid-cols-2">
      <li v-for="m in r.matches" :key="m.fixture_id" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
        <div class="flex items-center justify-between gap-2 font-bold">
          <bdi>{{ $nm(m.home.name) }}</bdi><span class="text-text-muted">{{ $t('ضد') }}</span
          ><bdi>{{ $nm(m.away.name) }}</bdi>
        </div>
        <div
          class="grid grid-cols-3 gap-1"
          role="radiogroup"
          :aria-label="$t('توقعك لمباراة {v0} و{v1}', { v0: m.home.name, v1: m.away.name })"
        >
          <button
            v-for="p in PICKS"
            :key="p.id"
            type="button"
            role="radio"
            :aria-checked="m.mine === p.id"
            :disabled="!m.open"
            class="flex min-h-14 touch-manipulation flex-col items-center justify-center rounded-lg px-1 text-xs font-bold disabled:opacity-60"
            :class="m.mine === p.id ? 'bg-gold text-on-gold' : 'bg-surface-sunk text-text-soft'"
            @click="pick(m.fixture_id, p.id)"
          >
            {{ $t(p.label) }}<span class="font-numbers text-[0.7rem] opacity-80">{{ pct(m.split, p.id) }}%</span>
          </button>
        </div>
        <span v-if="!m.open" class="text-xs text-text-muted">{{ $t('أُغلق التوقع') }}</span>
      </li>
    </ul>
  </div>
</template>
