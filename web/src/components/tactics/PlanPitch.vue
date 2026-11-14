<script setup lang="ts">
// [Sprint 20 S1] The attack plan drawn on a pitch in perspective: how the ball travels to the far goal for each plan.
// Ours alone (no picture from elsewhere): the pitch in our greens, the ball's path in gold, the runs in mint.
defineProps<{ plan: string }>()
const PATHS: Record<string, { ball: string; runs?: string }> = {
  counter: { ball: 'M40 70 Q120 10 205 48', runs: 'M70 74 Q110 66 150 70 M150 70 Q180 64 205 60' },
  long: { ball: 'M40 70 Q85 0 125 52 M125 52 Q170 4 210 46' },
  passing: { ball: 'M40 70 L75 56 L108 68 L140 54 L172 64 L208 50' },
  wings: { ball: 'M40 70 Q70 92 120 92 Q178 92 205 58', runs: 'M60 34 Q120 26 190 34' },
  shots: { ball: 'M40 70 Q100 60 150 58', runs: 'M150 58 L214 48' },
}
</script>

<template>
  <svg viewBox="0 0 240 110" class="h-auto w-full" aria-hidden="true">
    <path d="M30 22 H210 L232 98 H8 Z" fill="var(--color-pitch-dark)" stroke="var(--color-brand-light)" stroke-width="1.5" />
    <path d="M120 22 L120 98 M41 60 H199" stroke="rgba(255,255,255,.35)" stroke-width="1" fill="none" />
    <ellipse cx="120" cy="60" rx="20" ry="9" fill="none" stroke="rgba(255,255,255,.35)" />
    <path d="M20 45 h14 l3 30 h-17 Z M220 45 h-14 l-3 30 h17 Z" fill="none" stroke="rgba(255,255,255,.35)" />
    <path d="M30 98 l-6 10 h192 l-6 -10" fill="var(--color-brand-dark)" />
    <path
      v-if="PATHS[plan]?.runs"
      :d="PATHS[plan].runs"
      fill="none"
      stroke="var(--color-brand-light)"
      stroke-width="3"
      stroke-dasharray="6 5"
      stroke-linecap="round"
    />
    <path
      :d="(PATHS[plan] ?? PATHS.passing).ball"
      fill="none"
      stroke="var(--color-gold)"
      stroke-width="3.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <circle cx="40" cy="70" r="4" fill="var(--color-text)" />
  </svg>
</template>
