<script setup lang="ts">
// [UP14] The developers' page (the owner's spec 8): a card for each, with their role, a word about them, their
// skills and their CV. The content is in src/content/developers.ts, to edit and add to later.
import OfficialBadge from '../components/OfficialBadge.vue'
import { DEVELOPERS } from '../content/developers'
</script>

<template>
  <div class="flex flex-col gap-5">
    <header class="flex flex-col items-center gap-2 text-center">
      <img src="/brand/emblem.svg" alt="" class="size-20" />
      <h1 class="font-display text-3xl font-extrabold">فريق التطوير</h1>
      <p class="max-w-xl text-text-soft">من صنع لعبة المدرب الأسطورة، ومن يعتني بها كل يوم.</p>
    </header>
    <div class="grid gap-4 md:grid-cols-2">
      <article v-for="d in DEVELOPERS" :key="d.username" class="dev-card flex flex-col gap-4 rounded-2xl border border-gold/30 bg-surface p-5">
        <div class="flex items-center gap-4">
          <span class="flex size-20 shrink-0 items-center justify-center rounded-full bg-gold font-display text-4xl font-extrabold text-on-gold ring-4 ring-brand/40">{{ d.avatar }}</span>
          <div class="min-w-0">
            <h2 class="flex flex-wrap items-center gap-2 font-display text-2xl font-extrabold">{{ d.name }} <OfficialBadge /></h2>
            <p dir="ltr" class="text-start text-sm text-text-muted">@{{ d.username }}</p>
            <p class="font-bold text-brand-light">{{ d.role }}</p>
          </div>
        </div>
        <p class="text-text-soft">{{ d.bio }}</p>
        <ul class="flex flex-wrap gap-1.5" aria-label="المهارات">
          <li v-for="s in d.skills" :key="s" class="rounded-pill bg-surface-raised px-3 py-1 text-xs font-bold">{{ s }}</li>
        </ul>
        <section aria-label="السيرة الذاتية">
          <h3 class="mb-2 font-bold">السيرة الذاتية</h3>
          <ol class="flex flex-col gap-2 border-s-2 border-gold/40 ps-4">
            <li v-for="c in d.cv" :key="c.title" class="relative">
              <span class="absolute -start-[1.4rem] top-1.5 size-2.5 rounded-full bg-gold" aria-hidden="true" />
              <span class="font-numbers text-xs text-gold">{{ c.year }}</span>
              <b class="block">{{ c.title }}</b>
              <span class="text-sm text-text-muted">{{ c.text }}</span>
            </li>
          </ol>
        </section>
      </article>
    </div>
  </div>
</template>

<style scoped>
.dev-card { transition: transform 0.2s ease, box-shadow 0.2s ease }
.dev-card:hover { transform: scale(1.02); box-shadow: 0 10px 30px -18px var(--color-gold) }
@media (prefers-reduced-motion: reduce) { .dev-card, .dev-card:hover { transition: none; transform: none } }
</style>
