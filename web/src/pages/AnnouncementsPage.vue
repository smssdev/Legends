<script setup lang="ts">
// [X54] The developers' announcements, as the owner's picture: a bar with the megaphone, then each announcement as a
// card, newest first.
import { onMounted, ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'
import Icon from '../components/Icon.vue'
import AnnouncementCard from '../components/AnnouncementCard.vue'

const cards = ref<components['schemas']['AnnouncementCard'][] | null>(null)
onMounted(async () => {
  cards.value = (await api.GET('/announcements')).data?.announcements ?? []
})
</script>

<template>
  <div class="mx-auto flex w-full max-w-4xl flex-col gap-4">
    <h1 class="ann-bar"><Icon name="megaphone" :size="26" />{{ $t('الإعلانات') }}</h1>
    <div v-if="!cards" class="flex flex-col gap-4" aria-hidden="true"><div v-for="n in 2" :key="n" class="h-72 animate-pulse rounded-2xl bg-surface" /></div>
    <p v-else-if="!cards.length" class="rounded-xl bg-surface p-8 text-center text-text-muted">{{ $t('لا إعلانات بعد.') }}</p>
    <AnnouncementCard v-for="a in cards ?? []" :key="a.id" :title="a.title" :body="a.body" :at="a.at" :image-url="a.image_url" :cta="a.cta" />
  </div>
</template>

<style scoped>
.ann-bar {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.7rem 1rem;
  border-radius: 0.9rem;
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 800;
  color: #fff;
  background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand) 70%, var(--color-brand-dark));
  box-shadow: 0 6px 0 -2px var(--color-brand-dark);
}
</style>
