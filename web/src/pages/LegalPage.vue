<script setup lang="ts">
// [X57] The privacy policy and the terms (src/content/legal.ts): open to everyone, signed in or not, as Google
// AdSense and the stores ask, in the coach's language, with the way to reach us at the bottom.
import { computed } from 'vue'
import BrandMark from '../components/BrandMark.vue'
import LanguageSwitch from '../components/LanguageSwitch.vue'
import SupportLinks from '../components/SupportLinks.vue'
import { LEGAL, UPDATED, type LegalKind } from '../content/legal'
import { locale } from '../lib/i18n'

const props = defineProps<{ kind: LegalKind }>()
const doc = computed(() => LEGAL[props.kind][locale.value])
</script>

<template>
  <div class="min-h-dvh bg-bg">
    <header class="sticky top-0 z-10 flex items-center gap-3 border-b border-text/10 bg-bg/95 px-4 py-2 backdrop-blur">
      <RouterLink to="/" class="flex min-h-touch items-center" :aria-label="$t('الرئيسية')"><BrandMark size="sm" /></RouterLink>
      <span class="flex-1" />
      <LanguageSwitch />
    </header>
    <main class="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
      <div class="flex flex-col gap-2">
        <h1 class="font-display text-3xl font-extrabold">{{ doc.title }}</h1>
        <p class="text-sm text-text-muted">{{ $t('آخر تحديث:') }} <span class="font-numbers" dir="ltr">{{ UPDATED }}</span></p>
        <p class="leading-relaxed text-text-soft">{{ doc.intro }}</p>
      </div>
      <section v-for="(s, i) in doc.sections" :key="s.h" class="flex flex-col gap-2" :aria-labelledby="`legal-${i}`">
        <h2 :id="`legal-${i}`" class="font-display text-xl font-extrabold text-gold">{{ s.h }}</h2>
        <p v-for="p in s.p" :key="p" class="leading-relaxed">{{ p }}</p>
      </section>
      <SupportLinks />
      <nav class="flex flex-wrap gap-4 border-t border-text/10 pt-4 text-sm font-bold" :aria-label="$t('روابط')">
        <RouterLink :to="kind === 'privacy' ? '/terms' : '/privacy'" class="flex min-h-touch items-center text-gold">{{ kind === 'privacy' ? $t('الشروط والأحكام') : $t('سياسة الخصوصية') }}</RouterLink>
        <RouterLink to="/" class="flex min-h-touch items-center text-text-muted">{{ $t('العودة إلى اللعبة') }}</RouterLink>
      </nav>
    </main>
  </div>
</template>
