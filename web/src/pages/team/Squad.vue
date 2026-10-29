<script setup lang="ts">
// The squad (Sprint 16 W1), after the draft MobileSquad: count, strength and value, filters by line, and
// each player with his line, status, fitness, value and rating. A tap opens his card. [Sprint 20 W11] Its header also
// says the eleven's average, the place against the objective, the formation, the strongest player and the next
// opponent, and «فريق نادٍ آخر» opens any club's squad of the league (without its tactics).
import { computed, onMounted, ref } from 'vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import RatingRing from '../../components/ui/RatingRing.vue'
import { LINES, money, strength, type Line } from '../../lib/format'
import PlayerCard from './PlayerCard.vue'
import { useTeam, type SquadPlayer } from './team'
import { t } from '../../lib/i18n'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'
import { api } from '../../api/client'
import { useBoard } from '../../stores/board'

const board = useBoard()
const others = ref<{ id: number; name: string }[]>([])
const otherClub = ref<number | null>(null)
async function loadOthers() {
  if (others.value.length || !board.league) return
  const data = (await api.GET('/leagues/{league}/clubs', { params: { path: { league: board.league } } })).data
  others.value = (data?.clubs ?? []).filter((c) => c.id !== board.board?.club.id).map((c) => ({ id: c.id, name: c.name }))
}

const { team, error, loaded, load } = useTeam()
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
const starters = computed(() => (team.value?.players ?? []).filter((p) => p.role === 'starter'))
const average = computed(() => (starters.value.length ? Math.round(starters.value.reduce((n, p) => n + p.overall, 0) / starters.value.length) : null))
const best = computed(() => [...(team.value?.players ?? [])].sort((a, b) => b.overall - a.overall)[0] ?? null)
// [Sprint 21 E3.5] The list by line, each under its own heading: keepers, defenders, midfield, attack.
const groups = computed(() => (['gk', 'def', 'mid', 'att'] as const).map((l) => ({ line: l, players: players.value.filter((p) => p.line === l) })).filter((g) => g.players.length))

function status(p: SquadPlayer) {
  if (p.injured_matches) return { text: t('مصاب · {n} مباريات', { n: p.injured_matches }), tone: 'text-danger' }
  if (p.suspended_matches) return { text: t('موقوف · {n}', { n: p.suspended_matches }), tone: 'text-danger' }
  if (p.id === captain.value) return { text: 'القائد', tone: 'text-gold' }
  // The fatigue lines [X21]: from 75% full, from 55% slower, under 55% a sharp drop and three times the injuries.
  if (p.fitness < 55) return { text: 'مرهق: خطر إصابة', tone: 'text-danger' }
  if (p.fitness < 75) return { text: 'متعب', tone: 'text-warning' }
  return { text: { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' }[p.role], tone: p.role === 'starter' ? 'text-success' : 'text-text-muted' }
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
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
        <RatingRing v-for="l in (['att', 'mid', 'def', 'gk'] as const)" :key="l" :value="team.lines[l]" :label="LINES[l].plural === 'حراس' ? $t('الحارس') : $t(LINES[l].plural)" :color="`var(--color-line-${l})`" />
      </section>
      <!-- [Sprint 20 W11] The team at a glance, and any other club's squad. -->
      <section class="flex flex-wrap items-center gap-x-4 gap-y-2 rounded-xl bg-surface px-4 py-3 text-sm" :aria-label="$t('الفريق في سطر')">
        <span v-if="average">{{ $t('المعدل') }} <b class="font-numbers text-base">{{ average }}</b></span>
        <span v-if="board.board">{{ $t('الطريقة') }} <b class="font-numbers text-base" dir="ltr">{{ board.board.lineup.formation.replace(/^custom:.*/, '') || $t('خطتي') }}</b></span>
        <span v-if="board.board?.standings.position">{{ $t('المركز') }} <b class="font-numbers text-base">{{ board.board.standings.position }}</b><template v-if="board.board.board"> · {{ $t('الهدف {v0}', { v0: board.board.board.target }) }}</template></span>
        <span v-if="best">{{ $t('الأعلى قوة') }}: <b><bdi>{{ $nm(best.name) }}</bdi></b> <span class="font-numbers text-gold">{{ best.overall }}</span></span>
        <span v-if="board.board?.match">{{ $t('الخصم القادم') }}: <b>{{ $nm(board.board.match.opponent.name) }}</b></span>
        <label class="ms-auto flex items-center gap-2">
          <span class="sr-only">{{ $t('فريق نادٍ آخر') }}</span>
          <select class="h-10 rounded-lg bg-surface-sunk px-2 text-sm" :value="''" @focus="loadOthers" @pointerdown="loadOthers" @change="otherClub = Number(($event.target as HTMLSelectElement).value) || null; ($event.target as HTMLSelectElement).value = ''">
            <option value="">{{ $t('فريق نادٍ آخر ▾') }}</option>
            <option v-for="c in others" :key="c.id" :value="c.id">{{ $nm(c.name) }}</option>
          </select>
        </label>
      </section>
      <section v-if="team.morale" class="flex items-center gap-3 rounded-xl bg-surface px-4 py-3" :aria-label="$t('المعنويات')">
        <span class="flex items-center gap-1 font-bold">{{ $t('المعنويات') }}</span>
        <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk" role="meter" :aria-valuenow="team.morale.value" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('المعنويات')">
          <span class="block h-full rounded-full" :style="{ width: `${team.morale.value}%`, background: moraleColor(team.morale.value) }" />
        </span>
        <b class="font-numbers text-lg" :style="{ color: moraleColor(team.morale.value) }">{{ team.morale.value }}</b>
        <span v-if="team.morale.winless_run >= 2" class="text-xs text-danger">{{ $t('{v0} بلا فوز', { v0: team.morale.winless_run }) }}</span>
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
          {{ l === 'all' ? $t('الكل') : $t(LINES[l].plural) }} <span class="font-numbers">{{ l === 'all' ? team.players.length : count(l) }}</span>
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

      <!-- [Sprint 21 E3.5] The list: by line, compact rows that read across, and on a computer columns with their
           headings (position, age, fitness, status, value, rating). -->
      <div v-else class="flex flex-col gap-4">
        <div class="hidden grid-cols-[2.5rem_minmax(0,1fr)_3.5rem_8rem_9rem_5.5rem_3.5rem] items-center gap-3 px-3 text-xs font-bold text-text-muted md:grid">
          <span /><span>{{ $t('اللاعب') }}</span><span class="text-center">{{ $t('العمر') }}</span><span>{{ $t('اللياقة') }}</span><span>{{ $t('الحالة') }}</span><span class="text-end">{{ $t('القيمة') }}</span><span class="text-center">{{ $t('القوة') }}</span>
        </div>
        <section v-for="grp in groups" :key="grp.line" class="flex flex-col gap-1.5" :aria-label="$t(LINES[grp.line].plural)">
          <h2 class="flex items-center gap-2 px-1 text-sm font-bold">
            <span class="h-4 w-1 rounded-full" :style="{ background: `var(--color-line-${grp.line})` }" />{{ $t(LINES[grp.line].plural) }}
            <span class="font-numbers text-text-muted">{{ grp.players.length }}</span>
          </h2>
          <ul class="flex flex-col overflow-hidden rounded-xl bg-surface">
            <li v-for="p in grp.players" :key="p.id" class="v-row border-b border-text/5 last:border-0">
              <button type="button" class="grid min-h-16 w-full grid-cols-[2.5rem_minmax(0,1fr)_3rem] items-center gap-3 px-3 py-2 text-start transition-colors hover:bg-surface-raised md:grid-cols-[2.5rem_minmax(0,1fr)_3.5rem_8rem_9rem_5.5rem_3.5rem]" @click="open = p">
                <LineBadge :line="p.line as Line" />
                <span class="min-w-0">
                  <span class="block truncate font-display text-base font-extrabold md:text-lg">{{ $nm(p.name) }}</span>
                  <span class="flex items-center gap-2 text-xs text-text-muted">
                    <span dir="ltr">{{ p.position }}</span>
                    <span class="md:hidden">· {{ $t('{n} سنة', { n: p.age }) }}</span>
                    <span class="md:hidden" :class="status(p).tone">· {{ $t(status(p).text) }}</span>
                  </span>
                </span>
                <span class="hidden text-center font-numbers text-text-soft md:block">{{ p.age }}</span>
                <span class="hidden items-center gap-2 md:flex">
                  <span class="h-1.5 flex-1 rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="p.fitness >= 75 ? 'bg-success' : p.fitness >= 55 ? 'bg-gold' : 'bg-live'" :style="{ width: `${p.fitness}%` }" /></span>
                  <span class="w-8 text-end font-numbers text-xs text-text-soft">{{ p.fitness }}</span>
                </span>
                <span class="hidden truncate text-sm md:block" :class="status(p).tone">{{ $t(status(p).text) }}</span>
                <span class="hidden text-end font-numbers text-sm text-text-soft md:block">{{ money(p.value) }}</span>
                <span class="flex size-11 items-center justify-center justify-self-center rounded-lg bg-surface-sunk font-numbers text-xl font-bold" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</span>
              </button>
            </li>
          </ul>
        </section>
      </div>
    </template>
    <p v-else class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
    <PlayerCard v-if="open" :player="open" @close="open = null" />
    <ClubSquadDialog v-if="otherClub && board.league" :league-id="board.league" :club-id="otherClub" @close="otherClub = null" />
  </div>
</template>
