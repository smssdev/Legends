<script setup lang="ts">
// [X59] «طريقة اللعب»: the game's guide for everyone (GET /guide), the Assistant Coach's own explanations in sections,
// open to visitors and search engines so the site shows the whole game before signing in. A search narrows it, the
// contents jump to a section, and Google's ads (when the owner's account is on) sit between sections, not in them.
import { computed, ref, watch } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'
import AdSlot from '../components/ads/AdSlot.vue'
import PublicFooter from '../components/PublicFooter.vue'
import PublicHeader from '../components/PublicHeader.vue'
import { locale } from '../lib/i18n'
import { useAuth } from '../stores/auth'

type Section = components['schemas']['GuideSection']
const auth = useAuth()
const sections = ref<Section[] | null>(null)
const failed = ref(false)
const query = ref('')

async function load() {
  failed.value = false
  try {
    sections.value = ((await api.GET('/guide')).data?.sections ?? []) as Section[]
  } catch {
    failed.value = true
  }
}
watch(locale, load, { immediate: true })

const shown = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!sections.value || !q) return sections.value ?? []
  return sections.value
    .map((s) => ({ ...s, topics: s.topics.filter((x) => (x.q + ' ' + x.a).toLowerCase().includes(q)) }))
    .filter((s) => s.topics.length)
})
const count = computed(() => sections.value?.reduce((n, s) => n + s.topics.length, 0) ?? 0)
</script>

<template>
  <div class="min-h-dvh bg-bg">
    <PublicHeader />
    <main class="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
      <header class="flex flex-col gap-2">
        <h1 class="font-display text-3xl font-extrabold md:text-4xl">{{ $t('طريقة اللعب') }}</h1>
        <p class="max-w-2xl leading-relaxed text-text-soft">
          {{
            $t(
              'دليل لعبة المدرب الأسطورة كاملاً: كيف تبني ناديك، وتختار تكتيكك، وتدرّب لاعبيك، وتدير مبارياتك مباشرة. وهو نفسه ما يجيب منه المدرب المساعد داخل اللعبة.',
            )
          }}
        </p>
        <label class="mt-2 flex max-w-md flex-col gap-1">
          <span class="text-sm font-bold">{{ $t('ابحث في الدليل') }}</span>
          <input
            v-model="query"
            type="search"
            class="h-touch rounded-lg border border-text/15 bg-surface px-3"
            :placeholder="$t('مثلاً: الضغط، التدريب، الكأس')"
          />
        </label>
      </header>

      <p v-if="failed" class="text-danger">
        {{ $t('تعذر تحميل الدليل.') }}
        <button type="button" class="min-h-touch font-bold underline" @click="load">{{ $t('إعادة المحاولة') }}</button>
      </p>
      <p v-else-if="!sections" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
      <template v-else>
        <nav v-if="!query" class="flex flex-wrap gap-2" :aria-label="$t('المحتويات')">
          <a
            v-for="s in sections"
            :key="s.id"
            :href="`#${s.id}`"
            class="flex min-h-touch items-center rounded-pill bg-surface px-4 text-sm font-bold hover:bg-surface-raised"
            >{{ s.title }} <span class="ms-1.5 font-numbers text-xs text-text-muted">{{ s.topics.length }}</span></a
          >
        </nav>
        <p v-if="query && !shown.length" class="text-text-muted">{{ $t('لا نتائج لهذا البحث.') }}</p>
        <template v-for="(s, i) in shown" :key="s.id">
          <section :id="s.id" class="flex scroll-mt-20 flex-col gap-3" :aria-labelledby="`h-${s.id}`">
            <h2 :id="`h-${s.id}`" class="font-display text-2xl font-extrabold text-gold">{{ s.title }}</h2>
            <article v-for="x in s.topics" :id="x.id" :key="x.id" class="scroll-mt-20 rounded-xl border border-text/10 bg-surface p-4">
              <h3 class="mb-1.5 font-bold">{{ x.q }}</h3>
              <p class="whitespace-pre-line leading-relaxed text-text-soft">{{ x.a }}</p>
            </article>
          </section>
          <AdSlot v-if="!query && i % 3 === 2 && i < shown.length - 1" />
        </template>
        <p class="text-sm text-text-muted">{{ $t('{n} شرحاً في الدليل.', { n: count }) }}</p>
        <div v-if="!auth.user" class="flex flex-col items-center gap-3 rounded-2xl border border-gold/30 bg-surface p-6 text-center">
          <b class="font-display text-2xl">{{ $t('جاهز لتجرب بنفسك؟') }}</b>
          <RouterLink to="/register" class="flex h-12 items-center rounded-lg bg-gold px-6 font-bold text-on-gold">{{
            $t('ابدأ مجاناً')
          }}</RouterLink>
        </div>
      </template>
    </main>
    <PublicFooter />
  </div>
</template>
