<script setup lang="ts">
// The game's mark: the crest with its name beside it (tools/brand/logo.py, X44). [Sprint 38 B1] The official name,
// GAME LEGEND MANAGER, in every language (MANAGER in gold, as on the logo); in Arabic «المدرب الأسطورة» under it, in
// English what the game is.
import { emblemSrc, locale } from '../lib/i18n'

withDefaults(defineProps<{ size?: 'sm' | 'md' }>(), { size: 'md' })
</script>

<template>
  <span class="inline-flex items-center gap-2.5" :dir="locale === 'ar' ? 'rtl' : 'ltr'">
    <img :src="locale === 'ar' ? emblemSrc : '/brand/emblem.svg'" alt="" :class="size === 'sm' ? 'size-9' : 'size-11'" />
    <span class="flex flex-col leading-tight">
      <span class="whitespace-nowrap font-display font-extrabold uppercase tracking-wide text-text" :class="size === 'sm' ? 'text-sm' : 'text-base'" dir="ltr">
        Game Legend <span class="text-gold">Manager</span>
      </span>
      <span v-if="locale === 'ar'" class="text-[0.65rem] font-bold text-text-soft" :class="size === 'sm' ? 'max-sm:hidden' : ''">المدرب الأسطورة · لعبة إدارة كرة القدم</span>
      <span v-else :class="size === 'sm' ? 'max-sm:hidden' : ''" class="font-display text-[0.55rem] font-bold tracking-[0.18em] text-text-soft">ONLINE FOOTBALL MANAGER</span>
    </span>
  </span>
</template>
