<script setup lang="ts">
// The game's mark: the emblem with الأساطير and LEGENDS under it (brand/README.md).
withDefaults(defineProps<{ size?: 'sm' | 'md' }>(), { size: 'md' })
</script>

<template>
  <span class="inline-flex items-center gap-2.5">
    <img src="/brand/emblem.svg" alt="" :class="size === 'sm' ? 'size-9' : 'size-11'" />
    <span class="flex flex-col leading-none">
      <span class="font-display font-extrabold text-gold" :class="size === 'sm' ? 'text-lg' : 'text-xl'">الأساطير</span>
      <span class="font-display text-[0.62rem] font-bold tracking-[0.3em] text-text-soft" dir="ltr">LEGENDS</span>
    </span>
  </span>
</template>
