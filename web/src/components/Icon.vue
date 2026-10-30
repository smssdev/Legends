<script setup lang="ts">
// Line icons for the navigation (24px grid, drawn for Legends, stroke follows the text colour).
defineProps<{ name: keyof typeof PATHS; size?: number }>()
</script>

<script lang="ts">
export const PATHS = {
  home: 'M3 10.5 12 3l9 7.5M5 9v11h5v-6h4v6h5V9',
  // [Sprint 20] The club board, the timers, the to-do list, the friendlies and the quests.
  club: 'M12 2.5 20 5v6.5c0 5-3.4 8.6-8 10-4.6-1.4-8-5-8-10V5Z',
  clock: 'M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm0-12v4l3 2M9 2h6',
  todo: 'M9 6h11M9 12h11M9 18h11M3.5 6l1 1 2-2M3.5 12l1 1 2-2M3.5 18l1 1 2-2',
  friendly: 'M7 4h10M12 4v4M5 20a7 7 0 0 1 14 0M8.5 13a3.5 3.5 0 1 0 7 0 3.5 3.5 0 0 0-7 0',
  quest: 'M12 3.5 14.6 9l6 .8-4.4 4.2 1.1 6-5.3-2.9-5.3 2.9 1.1-6L3.4 9.8l6-.8Z',
  // [X54] The announcements.
  megaphone: 'M3 10v4h3l7 4V6L6 10ZM16 9.5a3.5 3.5 0 0 1 0 5M18.5 7a7 7 0 0 1 0 10',
  // [Sprint 28] The development ideas: a light bulb.
  idea: 'M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3Z',
  match: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm0 5 3.8 2.8-1.5 4.4H9.7l-1.5-4.4Z',
  team: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7 10v-1a6 6 0 0 1 12 0v1M16 3.5a4 4 0 0 1 0 7.5M22 21v-1a6 6 0 0 0-4-5.6',
  lineup: 'M3 5h18v14H3zM12 5v14M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5ZM3 9h3v6H3M21 9h-3v6h3',
  tactics: 'M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0M14 4v4M8 10v4M16 16v4',
  training: 'M6 7v10M3 9v6M18 7v10M21 9v6M6 12h12',
  market: 'M4 8h14l-4-4M20 16H6l4 4',
  staff: 'M12 3v4M10 5h4M7 21v-6a5 5 0 0 1 10 0v6M12 15v6M9.5 10a2.5 2.5 0 1 0 5 0',
  scout: 'M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14ZM21 21l-5-5',
  stadium: 'M3 9c0-2.2 4-4 9-4s9 1.8 9 4-4 4-9 4-9-1.8-9-4ZM3 9v6c0 2.2 4 4 9 4s9-1.8 9-4V9',
  finance: 'M3 7h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7Zm0 0 2-3h12v3M16 13.5h2',
  leagues: 'M12 3 4 6v5c0 5 3.4 8.6 8 10 4.6-1.4 8-5 8-10V6l-8-3ZM9 12l2 2 4-4',
  league: 'M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4ZM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4',
  inbox: 'M3 6h18v12H3zM3 7l9 6 9-6',
  more: 'M5 12h.01M12 12h.01M19 12h.01',
  sim: 'M5 4h14v10H5zM9 20h6M12 14v6M10 7.5v3l3-1.5z',
  bell: 'M6 16V11a6 6 0 1 1 12 0v5l2 2H4zM10 21h4',
  close: 'M6 6l12 12M18 6 6 18',
  menu: 'M4 6h16M4 12h16M4 18h16',
  news: 'M4 5h13v14H6a2 2 0 0 1-2-2V5Zm13 4h3v8a2 2 0 0 1-2 2M7 8h7M7 12h7M7 16h4',
  predict: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM12 7v5l3 2',
} as const
</script>

<template>
  <svg :width="size ?? 22" :height="size ?? 22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path :d="PATHS[name]" />
  </svg>
</template>
