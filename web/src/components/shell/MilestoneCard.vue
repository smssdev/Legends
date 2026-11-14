<script setup lang="ts">
// [Sprint 64 W11] A player's milestone with the club (App\Experience\PlayerMilestones): a small celebration card on
// the office until the coach has seen it (the message stays in the inbox).
import { api, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { useBoard } from '../../stores/board'
import Character from '../characters/Character.vue'
import UiButton from '../ui/UiButton.vue'

const props = defineProps<{ items: components['schemas']['PlayerMilestone'][]; leagueId: number }>()
const board = useBoard()
const line = (m: components['schemas']['PlayerMilestone']) =>
  m.kind === 'goals'
    ? ['هدفه رقم {v0}', m.value]
    : m.kind === 'matches'
      ? ['مباراته رقم {v0}', m.value]
      : m.value === 1
        ? ['رجل المباراة لأول مرة', 0]
        : ['رجل المباراة للمرة {v0}', m.value]
async function seen() {
  await ensureCsrf()
  await api.POST('/leagues/{league}/team/milestones/seen', { params: { path: { league: props.leagueId } } })
  board.refresh()
}
</script>

<template>
  <section class="milestone" :aria-label="$t('لحظات اللاعبين')">
    <Character model="A3" mood="cheer" class="milestone-face" />
    <ul class="milestone-list">
      <li v-for="m in items" :key="m.id">
        <b
          ><bdi>{{ $nm(m.name) }}</bdi></b
        >
        · {{ $t(line(m)[0] as string, { v0: line(m)[1] }) }}
      </li>
    </ul>
    <UiButton size="sm" variant="quiet" @click="seen">{{ $t('رائع') }}</UiButton>
  </section>
</template>

<style scoped>
.milestone {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  padding: var(--space-sm);
  margin-block-end: var(--space-sm);
  border: 1px solid color-mix(in srgb, var(--color-gold) 45%, transparent);
  border-radius: var(--radius-lg);
  background: color-mix(in srgb, var(--color-gold) 10%, transparent);
}
.milestone-face {
  inline-size: 44px;
  flex-shrink: 0;
}
.milestone-list {
  display: flex;
  min-inline-size: 0;
  flex: 1;
  flex-direction: column;
  gap: var(--space-xs);
  font-size: var(--text-body);
}
</style>
