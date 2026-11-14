<script setup lang="ts">
// [Sprint 48 D1] A country's flag in the game's own badge: a hexagon in a gold ring with a light from above (the league
// picker's tiles). The flags are drawn here in simple shapes (the game has no flag pictures); an unknown country shows
// its league's first letter on the emerald.
import { computed, useId } from 'vue'

const props = withDefaults(defineProps<{ country: string; label?: string; size?: number }>(), { size: 64 })
const id = useId()

// Each flag on a 96 × 64 field, its middle under the badge.
const H = (...c: string[]) =>
  c.map((f, i) => `<rect y="${(64 / c.length) * i}" width="96" height="${64 / c.length + 0.5}" fill="${f}"/>`).join('')
const V = (...c: string[]) =>
  c.map((f, i) => `<rect x="${(96 / c.length) * i}" width="${96 / c.length + 0.5}" height="64" fill="${f}"/>`).join('')
const nordic = (bg: string, cross: string, inner?: string) =>
  `<rect width="96" height="64" fill="${bg}"/><rect x="30" width="12" height="64" fill="${cross}"/><rect y="26" width="96" height="12" fill="${cross}"/>` +
  (inner ? `<rect x="33" width="6" height="64" fill="${inner}"/><rect y="29" width="96" height="6" fill="${inner}"/>` : '')
const star = (cx: number, cy: number, r: number, fill: string) => {
  const p = Array.from({ length: 10 }, (_, i) => {
    const a = -Math.PI / 2 + (i * Math.PI) / 5
    const rr = i % 2 ? r * 0.42 : r
    return `${(cx + rr * Math.cos(a)).toFixed(1)},${(cy + rr * Math.sin(a)).toFixed(1)}`
  })
  return `<polygon points="${p.join(' ')}" fill="${fill}"/>`
}
const crescent = (cx: number, cy: number, r: number, fg: string, bg: string, dx = 0.28) =>
  `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${fg}"/><circle cx="${cx + r * dx}" cy="${cy}" r="${r * 0.8}" fill="${bg}"/>`

const FLAGS: Record<string, string> = {
  es: `<rect width="96" height="64" fill="#c60b1e"/><rect y="16" width="96" height="32" fill="#ffc400"/>`,
  'gb-eng': `<rect width="96" height="64" fill="#fff"/><rect x="41" width="14" height="64" fill="#ce1124"/><rect y="25" width="96" height="14" fill="#ce1124"/>`,
  'gb-sct': `<rect width="96" height="64" fill="#005eb8"/><path d="M0 0L96 64M96 0L0 64" stroke="#fff" stroke-width="11"/>`,
  fr: V('#0055a4', '#fff', '#ef4135'),
  de: H('#000', '#dd0000', '#ffce00'),
  it: V('#009246', '#fff', '#ce2b37'),
  nl: H('#ae1c28', '#fff', '#21468b'),
  be: V('#000', '#fdda24', '#ef3340'),
  ie: V('#169b62', '#fff', '#ff883e'),
  ro: V('#002b7f', '#fcd116', '#ce1126'),
  at: H('#c8102e', '#fff', '#c8102e'),
  pl: H('#fff', '#dc143c'),
  gr: `${H('#0d5eaf', '#fff', '#0d5eaf', '#fff', '#0d5eaf', '#fff', '#0d5eaf', '#fff', '#0d5eaf')}<rect width="36" height="36" fill="#0d5eaf"/><rect x="14" width="8" height="36" fill="#fff"/><rect y="14" width="36" height="8" fill="#fff"/>`,
  cz: `${H('#fff', '#d7141a')}<path d="M0 0L44 32L0 64Z" fill="#11457e"/>`,
  dk: nordic('#c8102e', '#fff'),
  se: nordic('#006aa7', '#fecc00'),
  no: nordic('#ba0c2f', '#fff', '#00205b'),
  ch: `<rect width="96" height="64" fill="#da291c"/><rect x="42" y="14" width="12" height="36" fill="#fff"/><rect x="30" y="26" width="36" height="12" fill="#fff"/>`,
  tr: `<rect width="96" height="64" fill="#e30a17"/>${crescent(40, 32, 16, '#fff', '#e30a17')}${star(60, 32, 7, '#fff')}`,
  pt: `${V('#006600', '#ff0000', '#ff0000')}<circle cx="32" cy="32" r="12" fill="#ffcc00"/><circle cx="32" cy="32" r="7" fill="#fff" stroke="#ff0000" stroke-width="3"/>`,
  sa: `<rect width="96" height="64" fill="#006c35"/><rect x="24" y="22" width="48" height="5" rx="2" fill="#fff"/><rect x="28" y="38" width="40" height="3" fill="#fff"/>`,
  eg: `${H('#ce1126', '#fff', '#000')}<circle cx="48" cy="32" r="7" fill="#c09300"/>`,
  qa: `<rect width="96" height="64" fill="#8a1538"/><path d="M0 0H34L42 3.6L34 7.1L42 10.7L34 14.2L42 17.8L34 21.3L42 24.9L34 28.4L42 32L34 35.6L42 39.1L34 42.7L42 46.2L34 49.8L42 53.3L34 56.9L42 60.4L34 64H0Z" fill="#fff"/>`,
  ae: `${H('#00732f', '#fff', '#000')}<rect width="26" height="64" fill="#ff0000"/>`,
  ma: `<rect width="96" height="64" fill="#c1272d"/><path d="M48 18L56 43L35 27.5H61L40 43Z" fill="none" stroke="#006233" stroke-width="2.5" stroke-linejoin="round"/>`,
  tn: `<rect width="96" height="64" fill="#e70013"/><circle cx="48" cy="32" r="16" fill="#fff"/>${crescent(48, 32, 11, '#e70013', '#fff', 0.3)}${star(52, 32, 5.5, '#e70013')}`,
  dz: `${V('#006233', '#fff')}${crescent(48, 32, 15, '#d21034', '#fff', 0.3)}${star(54, 32, 6, '#d21034')}`,
  iq: `${H('#ce1126', '#fff', '#000')}<path d="M34 34h28" stroke="#007a3d" stroke-width="4" stroke-linecap="round"/>`,
  ar: `${H('#74acdf', '#fff', '#74acdf')}<circle cx="48" cy="32" r="6" fill="#f6b40e"/>`,
  us: `${H('#b22234', '#fff', '#b22234', '#fff', '#b22234', '#fff', '#b22234')}<rect width="44" height="34" fill="#3c3b6e"/>${[10, 22, 34].map((x) => star(x, 10, 3.4, '#fff') + star(x, 24, 3.4, '#fff')).join('')}`,
  kr: `<rect width="96" height="64" fill="#fff"/><path d="M48 18a14 14 0 0 1 0 28a7 7 0 0 1 0-14a7 7 0 0 0 0-14z" fill="#003478"/><path d="M48 18a14 14 0 0 0 0 28a7 7 0 0 0 0-14a7 7 0 0 1 0-14z" fill="#cd2e3a"/>`,
  cn: `<rect width="96" height="64" fill="#ee1c25"/>${star(30, 22, 10, '#ffff00')}${star(46, 12, 3, '#ffff00')}${star(50, 22, 3, '#ffff00')}${star(46, 32, 3, '#ffff00')}`,
  au: `<rect width="96" height="64" fill="#012169"/><path d="M0 0L40 26M40 0L0 26" stroke="#fff" stroke-width="5"/><path d="M20 0V26M0 13H40" stroke="#fff" stroke-width="8"/><path d="M20 0V26M0 13H40" stroke="#c8102e" stroke-width="4"/>${star(66, 46, 6, '#fff')}${star(78, 20, 4, '#fff')}${star(56, 26, 4, '#fff')}`,
  in: `${H('#ff9933', '#fff', '#138808')}<circle cx="48" cy="32" r="7" fill="none" stroke="#000080" stroke-width="2"/>`,
}

const art = computed(() => FLAGS[props.country] ?? '')
const letter = computed(() => (props.label ?? '?').trim().charAt(0).toUpperCase())
// A rounded hexagon, point up.
const HEX = 'M32 3.5L56.7 17.75V46.25L32 60.5L7.3 46.25V17.75Z'
</script>

<template>
  <svg :width="size" :height="size" viewBox="0 0 64 64" class="league-flag shrink-0" role="img" :aria-label="label">
    <defs>
      <clipPath :id="`c${id}`"><path :d="HEX" /></clipPath>
      <linearGradient :id="`g${id}`" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#fff3c4" />
        <stop offset="0.45" stop-color="#e9b949" />
        <stop offset="1" stop-color="#8a5a12" />
      </linearGradient>
      <linearGradient :id="`l${id}`" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#fff" stop-opacity="0.45" />
        <stop offset="0.5" stop-color="#fff" stop-opacity="0" />
      </linearGradient>
    </defs>
    <path :d="HEX" fill="#062a22" transform="translate(0 1.5)" opacity="0.6" />
    <g :clip-path="`url(#c${id})`">
      <g v-if="art" transform="translate(-16 0)" v-html="art" />
      <template v-else>
        <rect width="64" height="64" fill="#0b6b52" />
        <text x="32" y="41" text-anchor="middle" font-size="26" font-weight="800" fill="#f4d27a">{{ letter }}</text>
      </template>
      <rect width="64" height="34" :fill="`url(#l${id})`" />
    </g>
    <path :d="HEX" fill="none" :stroke="`url(#g${id})`" stroke-width="4" stroke-linejoin="round" />
    <path
      :d="HEX"
      fill="none"
      stroke="#3a2606"
      stroke-opacity="0.5"
      stroke-width="0.8"
      stroke-linejoin="round"
      transform="translate(32 32) scale(0.88) translate(-32 -32)"
    />
  </svg>
</template>

<style scoped>
.league-flag {
  filter: drop-shadow(0 4px 6px rgb(0 0 0 / 0.45));
}
</style>
