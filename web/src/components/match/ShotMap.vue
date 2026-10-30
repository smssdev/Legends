<script setup lang="ts">
// [X62 E10] The shot map: both sides' shots on one half pitch each, the goals in gold, the saves, blocks and misses
// faint, so the coach sees where his chances came from. Drawn here (SVG), the places from the server (App\League\ShotMap).
type Shot = { team: 'home' | 'away'; minute: number; result: string; quality: string; x: number; y: number }
const props = defineProps<{ shots: Shot[]; names: { home: string; away: string } }>()
const COLOR: Record<string, string> = { goal: 'var(--color-gold)', saved: 'var(--color-brand-light)', blocked: 'var(--color-text-muted)', missed: 'var(--color-live)' }
// The home side attacks to the right, the away side to the left: one pitch, both halves.
const px = (s: Shot) => (s.team === 'home' ? 100 + s.x : 100 - s.x)
const count = (team: string, result?: string) => props.shots.filter((s) => s.team === team && (!result || s.result === result)).length
</script>

<template>
  <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="shotmap">
    <h2 id="shotmap" class="font-display text-xl font-extrabold">{{ $t('خريطة التسديدات') }}</h2>
    <div class="flex justify-between text-xs text-text-muted" dir="ltr">
      <span>{{ $nm(names.away) }} · {{ count('away') }} ({{ count('away', 'goal') }})</span>
      <span>{{ $nm(names.home) }} · {{ count('home') }} ({{ count('home', 'goal') }})</span>
    </div>
    <svg viewBox="0 0 200 100" class="w-full rounded-lg bg-pitch" dir="ltr" role="img" :aria-label="$t('خريطة التسديدات')">
      <g fill="none" stroke="rgb(255 255 255 / 0.35)" stroke-width="0.6">
        <rect x="1" y="1" width="198" height="98" /><line x1="100" y1="1" x2="100" y2="99" /><circle cx="100" cy="50" r="12" />
        <rect x="1" y="22" width="16" height="56" /><rect x="183" y="22" width="16" height="56" />
        <rect x="1" y="38" width="6" height="24" /><rect x="193" y="38" width="6" height="24" />
      </g>
      <circle v-for="(s, i) in shots" :key="i" :cx="px(s)" :cy="s.y" :r="s.result === 'goal' ? 3.2 : 2.2" :fill="COLOR[s.result] ?? '#fff'"
        :fill-opacity="s.result === 'goal' ? 1 : 0.75" stroke="#0B1A2C" stroke-width="0.5" class="animate-pop-in">
        <title>{{ s.minute }}' · {{ $t({ goal: 'هدف', saved: 'تصدّى', blocked: 'صُدّت', missed: 'خارج المرمى' }[s.result] ?? s.result) }}</title>
      </circle>
    </svg>
    <div class="flex flex-wrap gap-3 text-xs">
      <span v-for="(c, r) in COLOR" :key="r" class="flex items-center gap-1"><i class="inline-block size-2.5 rounded-full" :style="{ background: c }" />{{ $t({ goal: 'هدف', saved: 'تصدّى', blocked: 'صُدّت', missed: 'خارج المرمى' }[r]) }}</span>
    </div>
  </section>
</template>
