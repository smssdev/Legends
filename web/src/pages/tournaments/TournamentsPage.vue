<script setup lang="ts">
// [Sprint 29] The tournaments on the game: those waiting for their draw first, with its time, so anyone can watch it
// live; and "a new tournament".
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { when } from '../../api/leagues'
import EmptyState from '../../components/ui/EmptyState.vue'
import { TEMPLATES, FORMATS } from './labels'

type Tournament = components['schemas']['Tournament']
const list = ref<Tournament[]>([])
const loaded = ref(false)
const error = ref('')
onMounted(async () => {
  try {
    const { data } = await api.GET('/tournaments')
    list.value = data!.tournaments
  } catch (e) {
    error.value = asApiError(e).message
  } finally {
    loaded.value = true
  }
})
const drawLive = (x: Tournament) => !!x.draw_at && !x.drawn_at && new Date(x.draw_at).getTime() - Date.now() < 3_600_000
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <header class="flex items-center justify-between gap-3">
      <h1 class="font-display text-3xl font-extrabold">{{ $t('البطولات') }}</h1>
      <RouterLink :to="{ name: 'create-tournament' }" class="flex min-h-touch items-center rounded-xl bg-gold px-4 font-extrabold text-on-gold">{{ $t('بطولة جديدة') }}</RouterLink>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <EmptyState v-if="loaded && !list.length" icon="trophy" :title="$t('لا بطولات بعد')" :text="$t('أنشئ كأس عالم مع أصدقائك، أو بطولة من فريقين فأكثر.')"
      :cta="{ label: $t('بطولة جديدة'), to: '/tournaments/new' }" />
    <ul class="grid gap-3 sm:grid-cols-2">
      <li v-for="x in list" :key="x.id" class="flex flex-col gap-2 rounded-2xl bg-surface p-4">
        <div class="flex items-start justify-between gap-2">
          <RouterLink :to="{ name: 'tournament', params: { id: x.id } }" class="min-w-0">
            <b class="block truncate text-lg">{{ x.name }}</b>
            <span class="text-sm text-text-muted">{{ $t(TEMPLATES[x.template ?? 'custom'] ?? 'بطولة مخصصة') }} · {{ $t('{n} فريقاً', { n: x.team_count }) }} · {{ $t(FORMATS[x.format ?? 'groups']) }}</span>
          </RouterLink>
          <span v-if="drawLive(x)" class="shrink-0 rounded-full bg-live px-2 py-0.5 text-xs font-extrabold">{{ $t('قرعة قريباً') }}</span>
        </div>
        <p class="text-sm text-text-muted">
          <template v-if="x.drawn_at">{{ $t('سُحبت القرعة') }}</template>
          <template v-else-if="x.draw_at">{{ $t('القرعة {v0}', { v0: when(x.draw_at) }) }}</template>
          <template v-else>{{ $t('تُسحب القرعة عند البداية {v0}', { v0: when(x.starts_at) }) }}</template>
        </p>
        <RouterLink :to="{ name: 'tournament-draw', params: { id: x.id } }" class="flex min-h-touch items-center justify-center rounded-xl bg-surface-sunk font-bold text-gold">
          {{ x.drawn_at ? $t('شاهد القرعة كما كانت') : $t('شاهد القرعة') }}</RouterLink>
      </li>
    </ul>
  </div>
</template>
