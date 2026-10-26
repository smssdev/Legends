<script setup lang="ts">
// The squad (Sprint 16 W1), after the draft MobileSquad: count, strength and value, filters by line, and
// each player with his line, status, fitness, value and rating. A tap opens his card.
import { computed, onMounted, ref } from 'vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import RatingRing from '../../components/ui/RatingRing.vue'
import HelpTip from '../../components/ui/HelpTip.vue'
import { useGlossary } from '../../lib/glossary'
import { LINES, money, strength, type Line } from '../../lib/format'
import PlayerCard from './PlayerCard.vue'
import { useTeam, type SquadPlayer } from './team'

const { team, error, loaded, load } = useTeam()
const g = useGlossary()
// Morale [X25]: green from 75, red under 50.
const moraleColor = (v: number) => (v >= 75 ? 'var(--color-success)' : v < 50 ? 'var(--color-live)' : 'var(--color-gold)')
const line = ref<'all' | Line>('all')
const open = ref<SquadPlayer | null>(null)
// The list or the cards, remembered on this device [X29].
const view = ref<'list' | 'cards'>((() => { try { return localStorage.getItem('legends.squadView') === 'cards' ? 'cards' : 'list' } catch { return 'list' } })())
function setView(v: 'list' | 'cards') {
  view.value = v
  try { localStorage.setItem('legends.squadView', v) } catch {}
}
onMounted(load)

const players = computed(() => (team.value?.players ?? []).filter((p) => line.value === 'all' || p.line === line.value))
const count = (l: Line) => (team.value?.players ?? []).filter((p) => p.line === l).length
const captain = computed(() => team.value?.takers.captain?.player_id)

function status(p: SquadPlayer) {
  if (p.injured_matches) return { text: `مصاب · ${p.injured_matches} مباريات`, tone: 'text-[#FF8A8A]' }
  if (p.suspended_matches) return { text: `موقوف · ${p.suspended_matches}`, tone: 'text-[#FF8A8A]' }
  if (p.id === captain.value) return { text: 'القائد', tone: 'text-gold' }
  // The fatigue lines [X21]: from 75% full, from 55% slower, under 55% a sharp drop and three times the injuries.
  if (p.fitness < 55) return { text: 'مرهق: خطر إصابة', tone: 'text-[#FF8A8A]' }
  if (p.fitness < 75) return { text: 'متعب', tone: 'text-warning' }
  return { text: { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' }[p.role], tone: p.role === 'starter' ? 'text-success' : 'text-text-muted' }
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <div v-else-if="loaded && !team" class="flex flex-col items-center gap-3 rounded-xl bg-surface p-8 text-center">
      <h1 class="font-display text-2xl font-extrabold">{{ $t('ليس لديك فريق بعد') }}</h1>
      <p class="text-text-muted">{{ $t('انضم لدوري أو أنشئ دورياً واختر فريقك.') }}</p>
      <RouterLink :to="{ name: 'leagues' }" class="flex h-12 items-center rounded-lg bg-gold px-5 font-display font-extrabold text-on-gold">{{ $t('دورياتي') }}</RouterLink>
    </div>
    <template v-else-if="team">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">{{ $t('الفريق') }}</h1>
          <p class="text-text-muted">
            <span class="font-numbers">{{ team.players.length }}</span> {{ $t('لاعباً · القوة') }} <span class="font-numbers text-gold">{{ strength(team.club.strength_cp) }}</span> {{ $t('· القيمة') }}
            <span class="font-numbers">{{ money(team.squad_value) }}</span>
          </p>
        </div>
        <RouterLink :to="{ name: 'lineup' }" class="flex h-12 shrink-0 items-center rounded-lg bg-surface-raised px-4 font-display font-extrabold text-gold">{{ $t('التشكيلة') }}</RouterLink>
      </header>

      <!-- [X29] The team's strength by line, four rings as in the classic manager games. -->
      <section v-if="team.lines" class="grid grid-cols-4 gap-2 rounded-2xl bg-surface p-3 md:p-4" :aria-label="$t('قوة الفريق بالخطوط')">
        <RatingRing v-for="l in (['att', 'mid', 'def', 'gk'] as const)" :key="l" :value="team.lines[l]" :label="LINES[l].plural === 'حراس' ? $t('الحارس') : LINES[l].plural" :color="`var(--color-line-${l})`" />
      </section>
      <section v-if="team.morale" class="flex items-center gap-3 rounded-xl bg-surface px-4 py-3" :aria-label="$t('المعنويات')">
        <span class="flex items-center gap-1 font-bold">{{ $t('المعنويات') }}<HelpTip :text="g.morale" :label="$t('المعنويات')" /></span>
        <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk" role="meter" :aria-valuenow="team.morale.value" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('المعنويات')">
          <span class="block h-full rounded-full" :style="{ width: `${team.morale.value}%`, background: moraleColor(team.morale.value) }" />
        </span>
        <b class="font-numbers text-lg" :style="{ color: moraleColor(team.morale.value) }">{{ team.morale.value }}</b>
        <span v-if="team.morale.winless_run >= 2" class="text-xs text-[#FF8A8A]">{{ $t('{v0} بلا فوز', { v0: team.morale.winless_run }) }}</span>
      </section>

      <div class="flex items-center gap-2">
      <div class="flex min-w-0 flex-1 gap-2 overflow-x-auto pb-1" role="tablist" :aria-label="$t('الخطوط')">
        <button
          v-for="l in ['all', 'gk', 'def', 'mid', 'att'] as const"
          :key="l"
          type="button"
          role="tab"
          class="h-12 shrink-0 rounded-xl px-4 font-bold"
          :class="line === l ? 'bg-gold text-on-gold' : 'bg-surface text-text-soft'"
          :aria-selected="line === l"
          @click="line = l"
        >
          {{ l === 'all' ? $t('الكل') : LINES[l].plural }} <span class="font-numbers">{{ l === 'all' ? team.players.length : count(l) }}</span>
        </button>
      </div>
      <div class="flex shrink-0 gap-1 rounded-xl bg-surface p-1" role="group" :aria-label="$t('طريقة العرض')">
        <button v-for="[k, label, icon] in ([['list', 'قائمة', 'M4 6h16M4 12h16M4 18h16'], ['cards', 'بطاقات', 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z']] as const)" :key="k" type="button" class="grid size-10 place-items-center rounded-lg" :class="view === k ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="view === k" :aria-label="label" @click="setView(k)">
          <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path :d="icon" /></svg>
        </button>
      </div>
      </div>

      <!-- The cards, five or six a row on the computer. -->
      <ul v-if="view === 'cards'" class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
        <li v-for="p in players" :key="p.id" class="v-card">
          <button type="button" class="block w-full text-start" :aria-label="p.name" @click="open = p">
            <PlayerTile :name="p.name" :line="p.line as Line" :position="p.position" :overall="p.overall" :value="p.value" :fitness="p.fitness" :status="status(p).text" :status-tone="status(p).tone" :attributes="p.attributes as Record<string, number | null>" />
          </button>
        </li>
      </ul>

      <ul v-else class="flex flex-col gap-2">
        <li v-for="p in players" :key="p.id" class="v-row">
          <button type="button" class="flex min-h-20 w-full items-center gap-3 rounded-xl bg-surface p-3 text-start hover:bg-surface-raised" @click="open = p">
            <LineBadge :line="p.line as Line" />
            <span class="min-w-0 flex-1">
              <span class="block truncate font-display text-lg font-extrabold">{{ $nm(p.name) }}</span>
              <span class="flex items-center gap-2 text-sm">
                <span class="h-1.5 w-16 rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="p.fitness >= 75 ? 'bg-success' : p.fitness >= 55 ? 'bg-gold' : 'bg-live'" :style="{ width: `${p.fitness}%` }" /></span>
                <span :class="status(p).tone">{{ status(p).text }}</span>
              </span>
            </span>
            <span class="font-numbers text-text-soft">{{ money(p.value) }}</span>
            <span class="flex size-12 items-center justify-center rounded-lg bg-surface-sunk font-numbers text-2xl font-bold" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</span>
          </button>
        </li>
      </ul>
    </template>
    <p v-else class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
    <PlayerCard v-if="open" :player="open" @close="open = null" />
  </div>
</template>
