<script setup lang="ts">
// The game's mark: the GLM crest with its name beside it (tools/brand/logo.py, X44).
withDefaults(defineProps<{ size?: 'sm' | 'md' }>(), { size: 'md' })
</script>

<template>
  <span class="inline-flex items-center gap-2.5" dir="ltr">
    <img src="/brand/emblem.svg" alt="" :class="size === 'sm' ? 'size-9' : 'size-11'" />
    <span class="flex flex-col leading-none">
      <span class="font-display font-extrabold tracking-wide text-text" :class="size === 'sm' ? 'text-lg' : 'text-xl'">GL<span class="text-gold">M</span></span>
      <span class="font-display text-[0.55rem] font-bold tracking-[0.18em] text-text-soft">GAME LEGEND MANAGER</span>
    </span>
  </span>
</template>
