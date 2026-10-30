<script setup lang="ts">
// [X61] A link that leads nowhere (a mistyped address, an old link): the shell stays, with a way home, never a white
// screen. The address itself is shown so the coach sees what was wrong. [Sprint 26 W3] The ball (A3), surprised.
import { useRoute } from 'vue-router'
import Character from '../components/characters/Character.vue'

const route = useRoute()
</script>

<template>
  <div class="flex animate-fade-up flex-col items-center gap-3 rounded-xl bg-surface px-4 py-14 text-center">
    <Character model="A3" mood="surprise" class="w-28" />
    <h1 class="font-display text-2xl font-extrabold">{{ $t('الصفحة غير موجودة') }}</h1>
    <p class="max-w-sm text-text-muted">{{ $t('ربما تغيّر الرابط أو كُتب خطأ.') }}</p>
    <code class="max-w-full truncate rounded bg-surface-sunk px-2 py-1 text-xs text-text-muted" dir="ltr">{{ route.fullPath }}</code>
    <div class="mt-2 flex flex-wrap justify-center gap-2">
      <RouterLink to="/" class="flex min-h-touch items-center rounded-lg bg-gold px-5 font-bold text-on-gold">{{ $t('العودة للرئيسية') }}</RouterLink>
      <RouterLink to="/leagues" class="flex min-h-touch items-center rounded-lg border border-text/25 px-5 font-bold">{{ $t('دورياتي') }}</RouterLink>
    </div>
  </div>
</template>
