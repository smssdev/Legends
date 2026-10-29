<script setup lang="ts">
// The game's mark: the crest with its name beside it (tools/brand/logo.py, X44). [SEO] In Arabic the name is
// «المدرب الأسطورة», in English GLM · GAME LEGEND MANAGER.
import { emblemSrc, locale } from '../lib/i18n'

withDefaults(defineProps<{ size?: 'sm' | 'md' }>(), { size: 'md' })
</script>

<template>
  <span v-if="locale === 'ar'" class="inline-flex items-center gap-2.5" dir="rtl">
    <img :src="emblemSrc" alt="" :class="size === 'sm' ? 'size-9' : 'size-11'" />
    <span class="flex flex-col leading-tight">
      <span class="font-extrabold text-text" :class="size === 'sm' ? 'text-base' : 'text-lg'">المدرب <span class="text-gold">الأسطورة</span></span>
      <span class="text-[0.6rem] font-bold text-text-soft">لعبة إدارة كرة القدم</span>
    </span>
  </span>
  <span v-else class="inline-flex items-center gap-2.5" dir="ltr">
    <img src="/brand/emblem.svg" alt="" :class="size === 'sm' ? 'size-9' : 'size-11'" />
    <span class="flex flex-col leading-none">
      <span class="font-display font-extrabold tracking-wide text-text" :class="size === 'sm' ? 'text-lg' : 'text-xl'">GL<span class="text-gold">M</span></span>
      <span class="font-display text-[0.55rem] font-bold tracking-[0.18em] text-text-soft">GAME LEGEND MANAGER</span>
    </span>
  </span>
</template>
