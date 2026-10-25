<script setup lang="ts">
// The squad (Sprint 16 W1), after the draft MobileSquad: count, strength and value, filters by line, and
// each player with his line, status, fitness, value and rating. A tap opens his card.
import { computed, onMounted, ref } from 'vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import { LINES, money, strength, type Line } from '../../lib/format'
import PlayerCard from './PlayerCard.vue'
import { useTeam, type SquadPlayer } from './team'

const { team, error, loaded, load } = useTeam()
const line = ref<'all' | Line>('all')
const open = ref<SquadPlayer | null>(null)
onMounted(load)

const players = computed(() => (team.value?.players ?? []).filter((p) => line.value === 'all' || p.line === line.value))
const count = (l: Line) => (team.value?.players ?? []).filter((p) => p.line === l).length
const captain = computed(() => team.value?.takers.captain?.player_id)

function status(p: SquadPlayer) {
  if (p.injured_matches) return { text: `مصاب · ${p.injured_matches} مباريات`, tone: 'text-[#FF8A8A]' }
  if (p.in_camp) return { text: 'في المعسكر', tone: 'text-gold' }
  if (p.suspended_matches) return { text: `موقوف · ${p.suspended_matches}`, tone: 'text-[#FF8A8A]' }
  if (p.id === captain.value) return { text: 'القائد', tone: 'text-gold' }
  if (p.fitness < 70) return { text: 'مرهق', tone: 'text-warning' }
  return { text: { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' }[p.role], tone: p.role === 'starter' ? 'text-success' : 'text-text-muted' }
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <div v-else-if="loaded && !team" class="flex flex-col items-center gap-3 rounded-xl bg-surface p-8 text-center">
      <h1 class="font-display text-2xl font-extrabold">ليس لديك فريق بعد</h1>
      <p class="text-text-muted">انضم لدوري أو أنشئ دورياً واختر فريقك.</p>
      <RouterLink :to="{ name: 'leagues' }" class="flex h-12 items-center rounded-lg bg-gold px-5 font-display font-extrabold text-on-gold">دورياتي</RouterLink>
    </div>
    <template v-else-if="team">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">الفريق</h1>
          <p class="text-text-muted">
            <span class="font-numbers">{{ team.players.length }}</span> لاعباً · القوة <span class="font-numbers text-gold">{{ strength(team.club.strength_cp) }}</span> · القيمة
            <span class="font-numbers">{{ money(team.squad_value) }}</span>
          </p>
        </div>
        <RouterLink :to="{ name: 'lineup' }" class="flex h-12 shrink-0 items-center rounded-lg bg-surface-raised px-4 font-display font-extrabold text-gold">التشكيلة</RouterLink>
      </header>

      <div class="flex gap-2 overflow-x-auto pb-1" role="tablist" aria-label="الخطوط">
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
          {{ l === 'all' ? 'الكل' : LINES[l].plural }} <span class="font-numbers">{{ l === 'all' ? team.players.length : count(l) }}</span>
        </button>
      </div>

      <ul class="flex flex-col gap-2">
        <li v-for="p in players" :key="p.id">
          <button type="button" class="flex min-h-20 w-full items-center gap-3 rounded-xl bg-surface p-3 text-start hover:bg-surface-raised" @click="open = p">
            <LineBadge :line="p.line as Line" />
            <span class="min-w-0 flex-1">
              <span class="block truncate font-display text-lg font-extrabold">{{ p.name }}</span>
              <span class="flex items-center gap-2 text-sm">
                <span class="h-1.5 w-16 rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="p.fitness >= 80 ? 'bg-success' : p.fitness >= 60 ? 'bg-gold' : 'bg-warning'" :style="{ width: `${p.fitness}%` }" /></span>
                <span :class="status(p).tone">{{ status(p).text }}</span>
              </span>
            </span>
            <span class="font-numbers text-text-soft">{{ money(p.value) }}</span>
            <span class="flex size-12 items-center justify-center rounded-lg bg-surface-sunk font-numbers text-2xl font-bold" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</span>
          </button>
        </li>
      </ul>
    </template>
    <p v-else class="text-text-muted">جارٍ التحميل…</p>
    <PlayerCard v-if="open" :player="open" @close="open = null" />
  </div>
</template>
