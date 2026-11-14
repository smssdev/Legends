<template>
  <!-- [Sprint 57 W2] What happened: the feed (newest first), the momentum, the stats, and the developers' panel. -->
  <section class="flex max-h-[420px] flex-col gap-1 overflow-y-auto rounded-xl bg-surface p-3" :aria-label="$t('مجريات المباراة')">
    <h2 class="mb-1 font-display text-base font-bold">{{ $t('مجريات المباراة') }}</h2>
    <div v-for="(f, i) in feed" :key="i" class="flex gap-3 border-b border-text/5 py-2 text-sm">
      <span class="w-10 shrink-0 font-numbers text-base" :class="f.important ? 'text-gold' : 'text-text-muted'">{{ f.minute }}</span>
      <span :class="f.important ? 'font-bold' : ''">{{ $t(f.text) }}</span>
    </div>
  </section>
  <section class="rounded-xl bg-surface px-4 py-3" :aria-label="$t('الزخم')">
    <div class="mb-1 flex justify-between text-xs text-text-muted">
      <span class="font-display text-sm font-bold text-text">{{ $t('الزخم') }}</span><span>{{
        $t('أعلى: {v0} · أسفل: {v1}', { v0: $nm(view.clubs.home.name), v1: $nm(view.clubs.away.name) })
      }}</span>
    </div>
    <div class="h-20"><Momentum :values="momentum" :home-color="homeColor" /></div>
  </section>
  <section class="rounded-xl bg-surface p-4" :aria-label="$t('الإحصائيات')">
    <StatsGrid :home="teams.home.stats" :away="teams.away.stats" :home-color="homeColor" />
  </section>
  <section
    v-if="dev"
    class="rounded-xl border border-gold/40 bg-surface-sunk p-4 font-mono text-xs leading-6"
    dir="ltr"
    :aria-label="$t('لوحة المطور')"
  >
    <div>
      tick {{ last?.tick }} · period {{ last?.period }} · danger {{ last?.danger }} · rate {{ last?.debug?.initiative?.rate }} · home share
      {{ last?.debug?.initiative?.home_share }}
    </div>
    <div v-for="(a, i) in attacks" :key="i">
      {{ a.team }} {{ a.plan }}{{ a.counter ? ' (counter)' : '' }} → {{ a.result }} ·
      {{ a.phases.map((p: any) => `${p.n}:${p.p ?? '-'}${p.ok ? '+' : '-'}`).join(' ') }}
    </div>
    <div>home tactics {{ JSON.stringify(teams.home.tactics) }}</div>
    <div>away tactics {{ JSON.stringify(teams.away.tactics) }}</div>
  </section>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Momentum from '../Momentum.vue'
import StatsGrid from '../StatsGrid.vue'
import type { MatchView } from '../../api/sim'
import type { MatchPlayer } from '../../match/useMatchPlayer'

const props = defineProps<{ player: MatchPlayer; view: MatchView; homeColor: string; dev: boolean }>()
const { feed, momentum, teams, last } = props.player
const attacks = computed(() => (last.value?.events ?? []).filter((e) => e.type === 'attack'))
</script>
