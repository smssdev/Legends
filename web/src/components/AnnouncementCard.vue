<script setup lang="ts">
// [X54] A developers' announcement as a card, after the owner's picture (2026-10-29), in our colours: the title and its
// date on top, the wide picture, the text in its paragraphs, and the button across the card (a page of the game opens
// here, a site in a new tab). The same card on the coaches' page and in the panel's preview.
import { computed } from 'vue'

const props = defineProps<{ title: string; body: string; at?: string | null; imageUrl?: string | null; cta?: { label: string; url: string } | null }>()
const paragraphs = computed(() => props.body.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean))
// Day-month-year as the owner's picture (23-10-26), in the device's time; written by hand, so no direction can scramble it.
const when = computed(() => {
  if (!props.at) return ''
  const d = new Date(props.at)
  return [d.getDate(), d.getMonth() + 1, d.getFullYear() % 100].map((n) => String(n).padStart(2, '0')).join('-')
})
// The text is the developers' own, in the language they wrote it (not the game's): marked so, for screen readers.
const lang = computed(() => (/[\u0600-\u06FF]/.test(props.title + props.body) ? 'ar' : 'en'))
const internal = computed(() => !!props.cta && props.cta.url.startsWith('/'))
</script>

<template>
  <article class="ann-card" :lang="lang" :dir="lang === 'ar' ? 'rtl' : 'ltr'">
    <header class="flex items-start gap-3">
      <h2 class="min-w-0 flex-1 font-display text-xl font-extrabold leading-snug md:text-2xl">{{ title }}</h2>
      <time v-if="at" :datetime="at" class="shrink-0 pt-1 font-numbers text-sm opacity-70" dir="ltr">{{ when }}</time>
    </header>
    <!-- A banner's shape held before the picture comes, so nothing under it moves. -->
    <img v-if="imageUrl" :src="imageUrl" alt="" class="aspect-[16/5] w-full rounded-lg object-cover" loading="lazy" />
    <p v-for="(p, i) in paragraphs" :key="i" class="whitespace-pre-line text-base leading-relaxed">{{ p }}</p>
    <template v-if="cta">
      <RouterLink v-if="internal" :to="cta.url" class="ann-cta">{{ cta.label }}</RouterLink>
      <a v-else :href="cta.url" target="_blank" rel="noopener noreferrer nofollow" class="ann-cta">{{ cta.label }}</a>
    </template>
  </article>
</template>

<style scoped>
.ann-card {
  display: flex;
  flex-direction: column;
  gap: 0.9rem;
  padding: 1.1rem 1.25rem 1.25rem;
  border-radius: 1rem;
  color: var(--color-on-chrome);
  background: var(--color-chrome);
  box-shadow: 0 10px 28px -16px rgb(0 0 0 / 0.8);
}
.ann-cta {
  display: flex;
  min-height: 2.75rem;
  align-items: center;
  justify-content: center;
  border-radius: 0.6rem;
  font-weight: 700;
  color: #fff;
  background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand));
  box-shadow: 0 6px 14px -8px var(--color-brand);
}
.ann-cta:hover { filter: brightness(1.06); }
</style>
