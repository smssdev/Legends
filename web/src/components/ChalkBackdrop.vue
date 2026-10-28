<script setup lang="ts">
// [Sprint 21 E3.4] The home screen's chalkboard: a coach's training drawings in faint white, as if chalked on the
// board behind the page (the owner's request, 2026-10-28). Drawn here (no outside picture): the pitch's lines, the
// noughts and crosses of a set piece with their runs, cones and a ladder, a ball, a whistle and a stopwatch.
// A rough edge filter gives the chalk's grain. Decoration only: hidden from screen readers and from clicks.
</script>

<template>
  <div class="pointer-events-none fixed inset-0 z-[-1] overflow-hidden" aria-hidden="true">
    <svg class="absolute inset-0 size-full" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice" fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round">
      <defs>
        <filter id="chalk" x="-5%" y="-5%" width="110%" height="110%">
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="grain" />
          <feDisplacementMap in="SourceGraphic" in2="grain" scale="3.2" />
        </filter>
        <marker id="chalk-arrow" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
          <path d="M1 1 L8 5 L1 9" stroke="#fff" stroke-width="1.6" fill="none" />
        </marker>
      </defs>
      <g filter="url(#chalk)" class="chalk" stroke-width="3">
        <!-- Half a pitch, top start: the box, the six-yard box, the arc and the spot. -->
        <g opacity="0.55">
          <path d="M60 60 H560 V420 H60 Z" />
          <path d="M60 150 H230 V330 H60" />
          <path d="M60 205 H120 V275 H60" />
          <path d="M230 205 A80 80 0 0 1 230 275" />
          <circle cx="175" cy="240" r="3" fill="#fff" />
        </g>
        <!-- A corner: crosses run, noughts mark, and the ball's flight curls in. -->
        <g opacity="0.7">
          <path d="M320 120 l16 16 m0 -16 l-16 16" />
          <path d="M380 190 l16 16 m0 -16 l-16 16" />
          <path d="M300 300 l16 16 m0 -16 l-16 16" />
          <circle cx="270" cy="150" r="10" />
          <circle cx="260" cy="260" r="10" />
          <circle cx="330" cy="240" r="10" />
          <path d="M336 136 C300 170 260 190 220 215" marker-end="url(#chalk-arrow)" />
          <path d="M396 206 C360 230 300 240 250 238" marker-end="url(#chalk-arrow)" />
          <path d="M540 70 C470 110 360 150 245 235" stroke-dasharray="10 12" marker-end="url(#chalk-arrow)" />
        </g>
        <!-- A 4-3-3 on a little board, bottom end. -->
        <g opacity="0.6" transform="translate(1110 560)">
          <rect x="0" y="0" width="420" height="320" rx="10" />
          <path d="M210 0 V320 M0 160 H420" opacity="0.5" />
          <circle cx="210" cy="160" r="40" opacity="0.5" />
          <circle cx="210" cy="292" r="9" />
          <circle cx="70" cy="240" r="9" /><circle cx="160" cy="250" r="9" /><circle cx="260" cy="250" r="9" /><circle cx="350" cy="240" r="9" />
          <circle cx="120" cy="180" r="9" /><circle cx="210" cy="190" r="9" /><circle cx="300" cy="180" r="9" />
          <circle cx="90" cy="90" r="9" /><circle cx="210" cy="70" r="9" /><circle cx="330" cy="90" r="9" />
          <path d="M90 80 C90 50 120 35 150 30" marker-end="url(#chalk-arrow)" />
          <path d="M330 80 C330 50 300 35 270 30" marker-end="url(#chalk-arrow)" />
          <path d="M210 180 V110" stroke-dasharray="8 10" marker-end="url(#chalk-arrow)" />
        </g>
        <!-- Cones and an agility ladder. -->
        <g opacity="0.6">
          <path d="M700 820 l14 -34 l14 34 z M780 820 l14 -34 l14 34 z M860 820 l14 -34 l14 34 z M940 820 l14 -34 l14 34 z" />
          <path d="M714 840 C760 880 820 800 874 840 C920 870 940 830 954 840" stroke-dasharray="6 9" />
          <path d="M120 640 H420 M120 690 H420" />
          <path d="M160 640 V690 M200 640 V690 M240 640 V690 M280 640 V690 M320 640 V690 M360 640 V690" />
        </g>
        <!-- A ball. -->
        <g opacity="0.6" transform="translate(1340 200)">
          <circle r="54" />
          <path d="M0 -20 l19 14 l-7 22 h-24 l-7 -22 z" />
          <path d="M0 -20 V-54 M19 -6 L50 -18 M12 16 L32 44 M-12 16 L-32 44 M-19 -6 L-50 -18" />
        </g>
        <!-- A whistle, and a stopwatch. -->
        <g opacity="0.55" transform="translate(860 140)">
          <path d="M0 30 a30 30 0 1 0 60 0 a30 30 0 1 0 -60 0 M45 6 h70 v22 h-48" />
          <path d="M-10 0 C-40 -30 -70 -20 -90 10" stroke-dasharray="4 8" />
        </g>
        <g opacity="0.55" transform="translate(640 480)">
          <circle r="46" /><path d="M0 -46 v-14 M-12 -64 h24 M0 0 L22 -18" /><path d="M36 -36 l10 -10" />
        </g>
        <!-- The coach's notes: «press», «pass», «go!» as squiggles and ticks. -->
        <g opacity="0.45">
          <path d="M1000 420 c20 -30 40 30 60 0 s40 30 60 0 s40 30 60 0" />
          <path d="M1250 460 l12 12 l26 -30" />
          <path d="M520 560 c30 10 60 -10 90 0 c30 10 60 -10 90 0" />
        </g>
      </g>
    </svg>
  </div>
</template>

<style scoped>
.chalk { opacity: 0.08; }
@media (min-width: 1024px) { .chalk { opacity: 0.1; } }
</style>
