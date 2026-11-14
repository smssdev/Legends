<script setup lang="ts">
// [X59] The top of the public pages (the guide, the privacy policy, the terms): the brand home, the guide, the
// language, and the way in for a visitor.
import BrandMark from './BrandMark.vue'
import LanguageSwitch from './LanguageSwitch.vue'
import { useAuth } from '../stores/auth'

const auth = useAuth()
</script>

<template>
  <header class="sticky top-0 z-10 border-b border-text/10 bg-bg/95 backdrop-blur">
    <div class="mx-auto flex max-w-5xl items-center gap-3 px-4 py-2">
      <RouterLink to="/" class="flex min-h-touch items-center" :aria-label="$t('الرئيسية')"><BrandMark size="sm" /></RouterLink>
      <span class="flex-1" />
      <RouterLink to="/guide" class="hidden min-h-touch items-center px-2 text-sm font-bold sm:flex">{{ $t('طريقة اللعب') }}</RouterLink>
      <LanguageSwitch />
      <RouterLink v-if="!auth.user" to="/login" class="flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">{{
        $t('دخول')
      }}</RouterLink>
    </div>
  </header>
</template>
