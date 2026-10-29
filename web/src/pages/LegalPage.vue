<script setup lang="ts">
// [X57] The privacy policy and the terms (src/content/legal.ts): open to everyone, signed in or not, as Google
// AdSense and the stores ask, in the coach's language, with the way to reach us at the bottom. [X58] The public
// pages' header and footer.
import { computed, watchEffect } from 'vue'
import PublicFooter from '../components/PublicFooter.vue'
import PublicHeader from '../components/PublicHeader.vue'
import { LEGAL, UPDATED, type LegalKind } from '../content/legal'
import { locale } from '../lib/i18n'

const props = defineProps<{ kind: LegalKind }>()
const doc = computed(() => LEGAL[props.kind][locale.value])
watchEffect(() => { document.title = `${doc.value.title} · GLM` })
</script>

<template>
  <div class="min-h-dvh bg-bg">
    <PublicHeader />
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
      <RouterLink to="/" class="flex min-h-touch items-center self-start font-bold text-gold">{{ $t('العودة إلى اللعبة') }}</RouterLink>
    </main>
    <PublicFooter />
  </div>
</template>
