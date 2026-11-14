<script setup lang="ts">
// [UP16] The tactics' own icons (the owner's spec 10): one drawing per choice, in a 32 box, with its colour; the
// chosen one glows. Drawn here, ours alone.
defineProps<{ name: string; active?: boolean }>()

type Art = { color: string; d: string; fill?: string }
const ART: Record<string, Art> = {
  // The mentality
  all_out: {
    color: 'var(--color-live)',
    d: 'M4 22l6-6-6-6M12 22l6-6-6-6M20 22l6-6-6-6',
    fill: 'M24 6c1 2 3 3 3 5a3 3 0 0 1-6 0c0-1 1-2 1-3 1 1 2 1 2-2z',
  },
  attacking: { color: 'var(--color-warning)', d: 'M7 22l7-6-7-6M16 22l7-6-7-6' },
  balanced: { color: 'var(--color-line-def)', d: 'M16 5v22M8 27h16M6 10h20M6 10l-3 7h6zM26 10l-3 7h6z' },
  defensive: { color: 'var(--color-line-def)', d: 'M16 4l10 4v7c0 7-5 11-10 13C11 26 6 22 6 15V8zM20 16h-8m3-3-3 3 3 3' },
  park_bus: {
    color: 'var(--color-text-muted)',
    d: 'M4 9h24v13H4zM4 15h24M10 9v6M16 9v6M22 9v6',
    fill: 'M9 24a2 2 0 1 0 0 .1zM23 24a2 2 0 1 0 0 .1z',
  },
  counter: { color: 'var(--color-gold)', d: 'M18 3L8 17h7l-2 12 11-16h-7z' },
  wings: { color: 'var(--color-brand-light)', d: 'M4 4v24M28 4v24M6 24c6-2 8-8 8-14M26 24c-6-2-8-8-8-14M12 12l2-3 2 3M16 12l2-3 2 3' },
  shots: { color: 'var(--color-live)', d: 'M10 8h12v6H10zM16 22v-6M8 26l6-8M24 26l-6-8M16 30v-4', fill: 'M16 22a2 2 0 1 0 0 .1z' },
  tiki_taka: { color: 'var(--color-brand-light)', d: 'M16 6L6 24h20zM16 6a4 4 0 1 1 0 .1M6 24a3 3 0 1 1 0 .1M26 24a3 3 0 1 1 0 .1' },
  long_balls: { color: 'var(--color-warning)', d: 'M4 26C8 6 24 6 28 22M24 18l4 4 1-5' },
  // The passing
  short: { color: 'var(--color-brand-light)', d: 'M10 16h12M18 13l4 3-4 3', fill: 'M7 16a3 3 0 1 0 0 .1zM25 16a3 3 0 1 0 0 .1z' },
  through: { color: 'var(--color-gold)', d: 'M4 26L26 6M20 6h6v6M12 10v4M18 18v4', fill: 'M26 6a3 3 0 1 0 0 .1z' },
  long: { color: 'var(--color-warning)', d: 'M4 26C10 4 22 4 28 26', fill: 'M28 26a2 2 0 1 0 0 .1z' },
  direct: { color: 'var(--color-live)', d: 'M4 16h22M20 10l6 6-6 6M4 10v12' },
  // The lines
  att_only: { color: 'var(--color-live)', d: 'M6 16h18M18 10l6 6-6 6', fill: 'M7 9a3 3 0 1 0 0 .1z' },
  att_support: { color: 'var(--color-warning)', d: 'M24 8c-8 0-12 6-12 14M9 18l3 4 3-4', fill: 'M25 7a3 3 0 1 0 0 .1z' },
  att_back: { color: 'var(--color-line-def)', d: 'M24 6v16M19 17l5 5 5-5M6 26h20', fill: 'M24 4a3 3 0 1 0 0 .1z' },
  mid_stay: { color: 'var(--color-brand-light)', d: 'M16 6v18M10 20c0 4 12 4 12 0M12 10h8', fill: 'M16 5a3 3 0 1 0 0 .1z' },
  mid_push: { color: 'var(--color-warning)', d: 'M8 24L22 10M16 10h6v6M4 6h8' },
  mid_def: { color: 'var(--color-line-def)', d: 'M16 4l9 4v6c0 6-4 9-9 11-5-2-9-5-9-11V8zM8 28h16' },
  def_stay: { color: 'var(--color-line-def)', d: 'M4 20h24M8 20v-6M16 20v-6M24 20v-6M12 26h8v-4h-8z' },
  def_fullbacks: { color: 'var(--color-brand-light)', d: 'M6 26V8M26 26V8M3 11l3-3 3 3M23 11l3-3 3 3M10 20h12' },
  def_mid: { color: 'var(--color-warning)', d: 'M4 24h24M16 24V8M11 13l5-5 5 5' },
  // The pressing
  press_low: { color: 'var(--color-line-def)', d: 'M4 26h24M6 22h20M8 18h16', fill: '' },
  press_mid: { color: 'var(--color-gold)', d: 'M4 16h24M16 6v20', fill: 'M16 16a6 6 0 1 0 0 .1z' },
  press_high: { color: 'var(--color-live)', d: 'M4 8c4-4 8 4 12 0s8 4 12 0M4 14c4-4 8 4 12 0s8 4 12 0M4 20c4-4 8 4 12 0s8 4 12 0' },
  // The tackling
  tackle_0: { color: 'var(--color-success)', d: 'M6 14h12a4 4 0 0 1 0 8H8zM18 14l6-4M24 10v8' },
  tackle_1: { color: 'var(--color-brand-light)', d: 'M6 24l8-8M14 16l6 2M20 8a3 3 0 1 0 0 .1', fill: 'M24 22a3 3 0 1 0 0 .1z' },
  tackle_2: { color: 'var(--color-gold)', d: 'M4 24h14l6-6M10 18l4 6', fill: 'M22 6h6v8h-6z' },
  tackle_3: { color: 'var(--color-live)', d: 'M24 4c2 3 4 4 4 7a4 4 0 0 1-8 0c0-2 1-3 2-4', fill: 'M6 8h10v14H6z' },
  // The marking and the trap
  zone: { color: 'var(--color-line-def)', d: 'M4 4h24v24H4zM12 4v24M20 4v24M4 12h24M4 20h24' },
  man: {
    color: 'var(--color-warning)',
    d: 'M11 26v-8M21 26v-8M14 14h4M14 12v-2a2 2 0 0 1 4 0v2',
    fill: 'M11 9a3 3 0 1 0 0 .1zM21 9a3 3 0 1 0 0 .1z',
  },
  trap_on: { color: 'var(--color-success)', d: 'M8 28V4', fill: 'M8 4h16l-4 5 4 5H8z' },
  trap_off: { color: 'var(--color-text-muted)', d: 'M8 28V12M18 22l8 8M26 22l-8 8', fill: 'M8 12l14 6-14 4z' },
}
</script>

<template>
  <svg viewBox="0 0 32 32" class="tactic-icon" :class="{ active }" :style="{ '--c': (ART[name] ?? ART.balanced).color }" aria-hidden="true">
    <path v-if="ART[name]?.fill" :d="ART[name].fill" fill="currentColor" />
    <path
      :d="(ART[name] ?? ART.balanced).d"
      fill="none"
      stroke="currentColor"
      stroke-width="2.2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  </svg>
</template>

<style scoped>
.tactic-icon {
  width: 2rem;
  height: 2rem;
  color: var(--color-text-muted);
  transition:
    color 0.2s,
    transform 0.2s;
  flex: none;
}
.tactic-icon.active {
  color: var(--c);
  filter: drop-shadow(0 0 6px color-mix(in srgb, var(--c) 65%, transparent));
  transform: scale(1.06);
}
/* [X56] On paper the bright accents (the mint, the gold) take some of the ink, so the icon keeps its contrast. */
:global(html.light .tactic-icon.active) {
  color: color-mix(in srgb, var(--c) 72%, var(--color-text));
  filter: none;
}
</style>
