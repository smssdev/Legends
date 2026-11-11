<script setup lang="ts">
// [Sprint 54 W3] A place held while it loads (W-D15: `.skeleton` was defined and never used): lines of text, cards or
// table rows in the shape of what comes, with the soft light passing over them. Hidden from screen readers; the
// AsyncState around it says it is loading.
// `hero` holds the big card at the head of a board (the next match).
withDefaults(defineProps<{ kind?: 'line' | 'card' | 'row' | 'hero'; count?: number }>(), { kind: 'line', count: 3 })
</script>

<template>
  <div class="flex flex-col gap-2" aria-hidden="true">
    <span
      v-for="i in count"
      :key="i"
      class="skeleton block"
      :class="{ line: 'h-4', card: 'h-40 rounded-xl', row: 'h-11 rounded-lg', hero: 'h-56 rounded-2xl' }[kind]"
      :style="kind === 'line' ? { width: `${100 - ((i * 17) % 40)}%` } : undefined"
    />
  </div>
</template>
