<template>
  <!-- [Sprint 56 W7, Sprint 57 W2] A drawer over the match's picture, from one edge (never moving the picture). -->
  <aside class="match-drawer" :class="[side === 'end' ? 'is-end' : 'is-start', open ? 'is-open' : '']" :aria-label="$t(label)" :inert="!open">
    <button type="button" class="match-close" :aria-label="$t('إغلاق')" @click="emit('close')">✕</button>
    <slot />
  </aside>
</template>

<script setup lang="ts">
defineProps<{ open: boolean; side: 'start' | 'end'; label: string }>()
const emit = defineEmits<{ close: [] }>()
</script>

<style scoped>
.match-drawer { position: absolute; z-index: 47; top: 2.75rem; bottom: 0; display: flex; width: min(22rem, 46vw); flex-direction: column; gap: var(--space-sm); padding: var(--space-sm); overflow-y: auto; overscroll-behavior: contain; background: color-mix(in srgb, var(--color-bg) 96%, transparent); box-shadow: var(--shadow-overlay); transition: transform var(--duration-base) var(--ease-soft), visibility var(--duration-base); visibility: hidden; }
.match-drawer.is-end { inset-inline-end: 0; border-inline-start: 1px solid color-mix(in srgb, var(--color-gold) 30%, transparent); transform: translateX(-100%); }
.match-drawer.is-start { inset-inline-start: 0; border-inline-end: 1px solid color-mix(in srgb, var(--color-gold) 30%, transparent); transform: translateX(100%); }
[dir='ltr'] .match-drawer.is-end { transform: translateX(100%); }
[dir='ltr'] .match-drawer.is-start { transform: translateX(-100%); }
.match-drawer.is-open { visibility: visible; transform: none !important; }
.match-close { align-self: flex-end; display: grid; width: var(--spacing-touch); height: var(--spacing-touch); flex: none; place-items: center; border-radius: var(--radius-lg); background: var(--color-surface-raised); }
@media (max-width: 560px) { .match-drawer { width: 100%; } }
</style>
