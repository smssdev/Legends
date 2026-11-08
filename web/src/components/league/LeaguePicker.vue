<script setup lang="ts">
// [Sprint 48 D1] Choosing the league to copy, as the manager games' «اختيار دوري» (the owner's screenshots,
// 2026-11-08), in our own look: region tabs over a grid of pitch tiles, each a country's flag in the game's gold
// hexagon, the league's name, its clubs and how strong it is in stars. A tap chooses it.
import { computed, ref } from 'vue'
import Icon from '../Icon.vue'
import LeagueFlag from './LeagueFlag.vue'
import { placeOf, REGIONS, type Region } from '../../content/leagueAtlas'
import { locale } from '../../lib/i18n'

export interface Template { name: string; clubs: number; top_strength_cp: number; avg_strength_cp?: number }

const props = defineProps<{ templates: Template[]; modelValue: string }>()
const emit = defineEmits<{ pick: [name: string] }>()

const tab = ref<Region | 'top'>('top')
const query = ref('')
const searching = ref(false)

const rows = computed(() => props.templates.map((t, i) => ({ ...t, place: placeOf(t.name), rank: i })))
const strongest = computed(() => Math.max(1, ...rows.value.map((r) => r.avg_strength_cp ?? r.top_strength_cp)))
/** One to five stars: the league's average club against the strongest league's. */
const stars = (r: Template) => Math.max(1, Math.min(5, Math.round(((r.avg_strength_cp ?? r.top_strength_cp) / strongest.value) * 5 - 0.4)))
const tabs = computed(() => REGIONS.filter((r) => r.key === 'top' || rows.value.some((x) => x.place.region === r.key)))
const shown = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (searching.value && q) return rows.value.filter((r) => [r.name, r.place.ar, r.place.en].some((s) => s.toLowerCase().includes(q)))
  if (tab.value === 'top') return rows.value.filter((r) => r.place.tier === 1).slice(0, 8)
  return rows.value.filter((r) => r.place.region === tab.value)
})
const country = (r: { place: { ar: string; en: string } }) => (locale.value === 'ar' ? r.place.ar : r.place.en)
</script>

<template>
  <section class="flex flex-col gap-4" :aria-label="$t('اختيار دوري')">
    <div class="flex flex-wrap items-center gap-2">
      <div class="picker-tabs" role="tablist" :aria-label="$t('المناطق')">
        <button v-for="r in tabs" :key="r.key" type="button" role="tab" class="picker-tab" :class="!searching && tab === r.key ? 'is-active' : ''"
          :aria-selected="!searching && tab === r.key" @click="tab = r.key; searching = false">{{ $t(r.label) }}</button>
      </div>
      <label class="picker-search" :class="searching ? 'is-open' : ''">
        <Icon name="scout" :size="18" />
        <input v-model="query" type="search" :placeholder="$t('ابحث عن دولة أو دوري')" :aria-label="$t('ابحث عن دولة أو دوري')" class="min-w-0 flex-1 bg-transparent outline-none placeholder:text-white/70" @focus="searching = true" />
      </label>
    </div>

    <p v-if="!shown.length" class="rounded-xl bg-surface p-6 text-center text-text-muted">{{ $t('لا دوري بهذا الاسم.') }}</p>
    <ul class="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4 md:gap-3">
      <li v-for="r in shown" :key="r.name">
        <button type="button" class="league-tile" :class="modelValue === r.name ? 'is-picked' : ''" :aria-pressed="modelValue === r.name" @click="emit('pick', r.name)">
          <span v-if="r.rank < 4 && r.place.tier === 1" class="tile-crown" :title="$t('من أقوى الدوريات')" aria-hidden="true">
            <Icon name="trophy" :size="16" />
          </span>
          <span v-if="r.place.tier > 1" class="tile-tier">{{ $t('الدرجة {v0}', { v0: r.place.tier }) }}</span>
          <LeagueFlag :country="r.place.country" :label="country(r)" :size="72" class="tile-flag" />
          <b class="font-display text-lg leading-tight text-white drop-shadow md:text-xl">{{ country(r) }}</b>
          <span class="max-w-full truncate text-xs font-semibold text-white/70" dir="ltr">{{ r.name }}</span>
          <span class="mt-1 flex items-center gap-2 text-xs font-bold">
            <span class="rounded-pill bg-black/30 px-2 py-0.5 text-white/90">{{ $t('{v0} نادياً', { v0: r.clubs }) }}</span>
            <span class="tile-stars" :aria-label="$t('القوة {v0} من 5', { v0: stars(r) })"><i v-for="n in 5" :key="n" :class="n <= stars(r) ? 'on' : ''">★</i></span>
          </span>
        </button>
      </li>
    </ul>
  </section>
</template>

<style scoped>
/* The region tabs: dark chips on the stadium, the current one gold, as the manager games' tab row. */
.picker-tabs { display: flex; gap: 0.35rem; overflow-x: auto; scrollbar-width: none; max-width: 100%; }
.picker-tab {
  min-height: 2.75rem;
  flex: none;
  padding: 0 1rem;
  border-radius: 0.6rem;
  font-weight: 800;
  color: var(--color-text);
  background: color-mix(in srgb, var(--color-bg-deep) 75%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent);
}
.picker-tab:hover { border-color: color-mix(in srgb, var(--color-gold) 50%, transparent); }
.picker-tab.is-active { color: var(--color-gold-light); border-color: var(--color-gold); box-shadow: inset 0 -3px 0 var(--color-gold); }
.picker-search {
  display: flex;
  min-height: 2.75rem;
  flex: 1 1 12rem;
  max-width: 20rem;
  align-items: center;
  gap: 0.5rem;
  padding: 0 0.9rem;
  border-radius: 0.6rem;
  color: #fff;
  font-weight: 700;
  background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand));
  box-shadow: 0 1px 0 rgb(255 255 255 / 0.3) inset;
}
.picker-search.is-open { outline: 2px solid var(--color-gold); }
/* A tile: a slice of night pitch (mown stripes and a centre circle) under a dark glass, the flag in its gold hexagon. */
.league-tile {
  position: relative;
  display: flex;
  width: 100%;
  min-height: 12.5rem;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  padding: 1.25rem 0.75rem 1rem;
  overflow: hidden;
  border-radius: 1rem;
  text-align: center;
  background:
    radial-gradient(circle at 50% 38%, transparent 0 3.6rem, rgb(255 255 255 / 0.07) 3.6rem 3.7rem, transparent 3.75rem),
    repeating-linear-gradient(90deg, rgb(255 255 255 / 0.035) 0 2.5rem, transparent 2.5rem 5rem),
    linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 55%, #0b1d33) 0%, #0d2a3c 60%, var(--color-bg-deep) 100%);
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 25%, transparent);
  box-shadow: 0 12px 26px -18px var(--color-shade);
  transition: transform 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
}
.league-tile::after {
  content: "";
  position: absolute;
  inset-inline: 15%;
  bottom: 0;
  height: 3px;
  border-radius: 3px 3px 0 0;
  background: linear-gradient(90deg, transparent, var(--color-brand-light), transparent);
  opacity: 0.8;
}
.league-tile:hover { transform: translateY(-3px); border-color: color-mix(in srgb, var(--color-gold) 60%, transparent); box-shadow: 0 18px 30px -16px var(--color-shade); }
.league-tile:hover .tile-flag { transform: scale(1.07) rotate(-3deg); }
.league-tile.is-picked { border-color: var(--color-gold); box-shadow: 0 0 0 2px var(--color-gold), 0 18px 30px -16px var(--color-shade); }
.league-tile.is-picked::after { background: linear-gradient(90deg, transparent, var(--color-gold-light), transparent); }
.tile-flag { transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1); }
.tile-crown {
  position: absolute;
  top: 0.6rem;
  inset-inline-start: 0.6rem;
  display: grid;
  width: 2rem;
  height: 2rem;
  place-items: center;
  border-radius: 999px;
  color: var(--color-on-gold);
  background: radial-gradient(circle at 35% 30%, var(--color-gold-light), var(--color-gold) 60%, var(--color-gold-dark));
  box-shadow: 0 3px 8px rgb(0 0 0 / 0.4);
}
.tile-tier {
  position: absolute;
  top: 0.7rem;
  inset-inline-end: 0.6rem;
  padding: 0.1rem 0.5rem;
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 800;
  color: #fff;
  background: color-mix(in srgb, var(--color-brand-light) 45%, transparent);
}
.tile-stars { display: flex; letter-spacing: -1px; color: rgb(255 255 255 / 0.22); }
.tile-stars i { font-style: normal; }
.tile-stars i.on { color: var(--color-gold-light); text-shadow: 0 0 6px color-mix(in srgb, var(--color-gold) 60%, transparent); }
@media (max-width: 639px) { .league-tile { min-height: 11rem; } }
</style>
