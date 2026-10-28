<script setup lang="ts">
// Any club's squad in the league [X17; Sprint 21 E4.1]: what every member may see (the players, their age, rating,
// value and availability), never its tactics or its next lineup. Opened from a club's name in the table, the
// statistics, the fixtures and the news.
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../api/client'
import { count, money } from '../lib/format'

const props = defineProps<{ leagueId: number; clubId: number }>()
const emit = defineEmits<{ close: [] }>()
const squad = ref<any | null>(null)
const error = ref('')
onMounted(async () => {
  try {
    squad.value = (await api.GET('/leagues/{league}/clubs/{club}', { params: { path: { league: props.leagueId, club: props.clubId } } })).data
  } catch (e) {
    error.value = asApiError(e).message
  }
})
</script>

<template>
  <div class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 p-3 md:items-center" role="dialog" aria-modal="true" :aria-label="$t('تشكيلة النادي')" @click.self="emit('close')" @keydown.esc="emit('close')">
    <div class="flex max-h-[85dvh] w-full max-w-xl flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-4">
      <p v-if="error" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
      <p v-else-if="!squad" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
      <template v-else>
        <div class="flex items-center gap-3">
          <img :src="squad.crest_url" alt="" class="size-10" />
          <div class="min-w-0 flex-1"><h2 class="truncate font-display text-xl font-extrabold">{{ $nm(squad.name) }}</h2><p class="text-xs text-text-muted">{{ $t('{v0} · {v1} لاعباً', { v0: squad.coach?.name ?? $t('الحاسوب'), v1: count(squad.players.length) }) }}</p></div>
          <button type="button" class="size-touch rounded-md bg-surface-raised" :aria-label="$t('إغلاق')" @click="emit('close')">✕</button>
        </div>
        <div v-for="p in squad.players" :key="p.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 text-sm">
          <span class="w-10 font-numbers text-xs text-text-muted" dir="ltr">{{ p.position }}</span>
          <span class="min-w-0 flex-1 truncate"><bdi>{{ $nm(p.name) }}</bdi> <span class="text-xs text-text-muted">{{ $t('· {v0} سنة', { v0: p.age }) }}</span><span v-if="p.injured_matches" class="text-xs text-[#FF8A8A]"> {{ $t('· مصاب') }}</span><span v-if="p.suspended_matches" class="text-xs text-warning"> {{ $t('· موقوف') }}</span></span>
          <b class="font-numbers">{{ p.overall }}</b>
          <span class="w-16 text-end font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.value) }}</span>
        </div>
      </template>
    </div>
  </div>
</template>
