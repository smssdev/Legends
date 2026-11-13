<script setup lang="ts">
// [Sprint 63 G3] The game's line icons from their one source (brand/icons/*.svg, tools/brand/icons.py): the app draws
// the same drawings (mobile/lib/ui/widgets/glm_icons.g.dart). A 24 grid, the stroke in the text's colour.
import { PATHS, STROKE } from './icons.g'

defineProps<{ name: keyof typeof PATHS; size?: number }>()
</script>

<script lang="ts">
export { PATHS } from './icons.g'
</script>

<template>
  <svg :width="size ?? 22" :height="size ?? 22" viewBox="0 0 24 24" fill="none" stroke="currentColor" :stroke-width="STROKE" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path :d="PATHS[name]" />
  </svg>
</template>
