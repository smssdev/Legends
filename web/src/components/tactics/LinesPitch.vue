<script setup lang="ts">
// [Sprint 20 S1] The three lines' positioning on a pitch seen from above (attacking upwards): an arrow for each line
// shows where its players go: forward, stay, back, or out to the wings. Drawn here, ours alone.
// [Sprint 56 W4] `fill`: the tactics screen's big pitch, at the lineup pitch's size.
defineProps<{ att: string; mid: string; def: string; fill?: boolean }>()
// Arrows from each line's spot (y: forwards 34, midfield 70, defence 104), in the line's colour (the midfield in white, on the green).
const ARROWS: Record<string, string> = {
  att_only: 'M60 34 V12 M54 18 L60 11 L66 18',
  att_support: 'M60 32 V50 M54 44 L60 51 L66 44',
  att_back: 'M60 32 V60 M54 54 L60 61 L66 54',
  mid_push: 'M60 70 V48 M54 54 L60 47 L66 54',
  mid_stay: 'M48 70 H72 M52 66 L47 70 L52 74 M68 66 L73 70 L68 74',
  mid_def: 'M60 70 V92 M54 86 L60 93 L66 86',
  def_stay: 'M48 104 H72',
  def_fullbacks: 'M40 104 L24 82 M24 90 V81 H32 M80 104 L96 82 M96 90 V81 H88',
  def_mid: 'M60 104 V84 M54 90 L60 83 L66 90',
}
</script>

<template>
  <svg viewBox="0 0 120 140" :class="fill ? 'size-full' : 'h-auto w-full max-w-48'" aria-hidden="true">
    <rect x="2" y="2" width="116" height="136" rx="4" fill="var(--color-pitch-dark)" stroke="var(--color-brand-light)" stroke-width="1.5" />
    <path d="M2 70 H118" stroke="rgba(255,255,255,.35)" />
    <circle cx="60" cy="70" r="14" fill="none" stroke="rgba(255,255,255,.35)" />
    <path d="M34 2 V20 H86 V2 M34 138 V120 H86 V138" fill="none" stroke="rgba(255,255,255,.35)" />
    <g stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" fill="none">
      <path :d="ARROWS[`att_${att}`]" stroke="var(--color-line-att)" />
      <path :d="ARROWS[`mid_${mid}`]" stroke="var(--color-text)" />
      <path :d="ARROWS[`def_${def}`]" stroke="var(--color-line-def)" />
    </g>
    <circle cx="60" cy="34" r="4" fill="var(--color-line-att)" />
    <circle cx="60" cy="70" r="4" fill="var(--color-text)" />
    <circle cx="60" cy="104" r="4" fill="var(--color-line-def)" />
  </svg>
</template>
