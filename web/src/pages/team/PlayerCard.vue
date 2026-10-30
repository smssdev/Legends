<script setup lang="ts">
// A player's card (Sprint 16 W1), after the draft MobilePlayer: rating and line, the attributes with bars,
// fitness, room to grow and value. [Sprint 20 W9] A sheet from the bottom on the phone, a panel from the side on the
// computer, so the list behind stays where it was; and its actions: train him, or sell him.
import UiDialog from '../../components/ui/UiDialog.vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import UiChip from '../../components/ui/UiChip.vue'
import { money, type Line } from '../../lib/format'
import { ATTRIBUTES, barColor, type SquadPlayer } from './team'

defineProps<{ player: SquadPlayer }>()
defineEmits<{ close: [] }>()
const ROLE = { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' } as const
</script>

<template>
  <UiDialog :open="true" bare @close="$emit('close')">
    <section class="flex max-h-[92dvh] w-full max-w-lg flex-col gap-4 overflow-y-auto rounded-t-xxl bg-bg p-4 md:max-h-none md:w-[28rem] md:rounded-none md:border-s md:border-text/10" :aria-label="player.name">
      <header class="flex items-center justify-between gap-3">
        <h2 class="font-display text-2xl font-extrabold">{{ $t('بطاقة اللاعب') }}</h2>
        <div class="flex items-center gap-2">
          <UiChip :tone="player.role === 'starter' ? 'win' : 'neutral'">{{ $t(ROLE[player.role]) }}</UiChip>
          <button type="button" class="flex size-touch items-center justify-center rounded-lg bg-surface text-xl" :aria-label="$t('إغلاق')" @click="$emit('close')">×</button>
        </div>
      </header>

      <div class="flex flex-col gap-4 rounded-xl border border-gold/30 bg-surface p-4">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="font-display text-2xl font-extrabold">{{ $nm(player.name) }}</p>
            <p class="text-sm text-text-muted">
              {{ player.position }}<template v-if="player.alt_positions"> ({{ player.alt_positions }})</template><template v-if="player.nationality"> · {{ player.nationality }}</template>
            </p>
            <p class="text-sm text-text-muted"><span class="font-numbers">{{ player.age }}</span> {{ $t('سنة') }}<template v-if="player.foot"> {{ $t('· القدم {v0}', { v0: player.foot === 'Left' ? $t('اليسرى') : $t('اليمنى') }) }}</template></p>
          </div>
          <div class="flex flex-col items-center gap-1">
            <span class="font-numbers text-5xl font-bold text-gold">{{ player.overall }}</span>
            <LineBadge :line="player.line as Line" />
          </div>
        </div>
        <dl class="grid grid-cols-2 gap-x-4 gap-y-3">
          <div v-for="(v, k) in player.attributes" :key="k">
            <dt class="flex justify-between text-sm"><span>{{ $t(ATTRIBUTES[k]) }}</span><span class="font-numbers text-base">{{ v ?? '—' }}</span></dt>
            <dd class="mt-1 h-1.5 rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="barColor(v ?? 0)" :style="{ width: `${v ?? 0}%` }" /></dd>
          </div>
        </dl>
      </div>

      <dl class="grid grid-cols-3 gap-2 text-center">
        <div class="rounded-xl bg-surface p-3"><dt class="text-sm text-text-muted">{{ $t('اللياقة') }}</dt><dd class="font-numbers text-2xl" :class="player.fitness >= 75 ? 'text-success' : player.fitness >= 55 ? 'text-warning' : 'text-danger'">{{ player.fitness }}%</dd></div>
        <div class="rounded-xl bg-surface p-3"><dt class="text-sm text-text-muted">{{ $t('سقف التطور') }}</dt><dd class="font-numbers text-2xl">{{ player.potential }}</dd></div>
        <div class="rounded-xl bg-surface p-3"><dt class="text-sm text-text-muted">{{ $t('القيمة') }}</dt><dd class="font-numbers text-2xl">{{ money(player.value) }}</dd></div>
      </dl>
      <p v-if="!player.available" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger">
        {{ player.injured_matches ? $t('مصاب: يغيب {v0} مباريات', { v0: player.injured_matches }) : $t('موقوف: {v0} مباريات', { v0: player.suspended_matches }) }}
      </p>
      <!-- Selling one's own players [X6]: at once, at his value, or at my price up to his cap. -->
      <div class="grid grid-cols-2 gap-2">
        <RouterLink :to="{ name: 'training' }" class="flex h-12 items-center justify-center rounded-lg bg-gold font-bold text-on-gold" @click="$emit('close')">{{ $t('درّبه') }}</RouterLink>
        <RouterLink :to="{ name: 'market', query: { tab: 'sell' } }" class="flex h-12 items-center justify-center rounded-lg border border-warning/60 font-bold text-warning" @click="$emit('close')">{{ $t('بيع اللاعب') }}</RouterLink>
      </div>
    </section>
  </UiDialog>
</template>
