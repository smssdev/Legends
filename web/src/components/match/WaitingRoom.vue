<script setup lang="ts">
// [Sprint 64 W6] Five minutes before the whistle of a league match: the waiting room. The two clubs, the two coaches
// as their characters, the league members' predictions of this match (the predictions page's own split), the chat a
// tap away, and the countdown; it turns into the match by itself at the whistle (the page drops it once started).
import { computed, onMounted, ref } from 'vue'
import { api } from '../../api/client'
import type { MatchView, Side } from '../../api/sim'
import { countdown, useNow } from '../../lib/clock'
import Character from '../characters/Character.vue'
import UiButton from '../ui/UiButton.vue'

const props = defineProps<{ view: MatchView }>()
const emit = defineEmits<{ chat: [] }>()
const now = useNow()
const split = ref<{ home: number; draw: number; away: number } | null>(null)
const total = computed(() => (split.value ? split.value.home + split.value.draw + split.value.away : 0))
const pct = (n: number) => (total.value ? Math.round((n * 100) / total.value) : 0)
onMounted(async () => {
  if (!props.view.league_id || !props.view.fixture_id) return
  try {
    const p = (await api.GET('/leagues/{league}/predictions', { params: { path: { league: props.view.league_id } } })).data
    split.value = p?.matches.find((m) => m.fixture_id === props.view.fixture_id)?.split ?? null
  } catch { /* no predictions to show */ }
})
const sides: Side[] = ['home', 'away']
</script>

<template>
  <div class="waiting" role="region" :aria-label="$t('غرفة الانتظار')">
    <section class="waiting-card">
      <small class="waiting-kicker">{{ $t('غرفة الانتظار') }}</small>
      <b v-if="view.kickoff_at && countdown(view.kickoff_at, now)" class="waiting-clock font-numbers" dir="ltr" role="timer">{{ countdown(view.kickoff_at, now) }}</b>
      <div class="waiting-sides">
        <div v-for="s in sides" :key="s" class="waiting-side">
          <Character v-if="view.coach_looks?.[s]" :model="view.coach_looks[s]!" mood="think" class="waiting-coach" />
          <b><bdi>{{ $nm(view.clubs[s].name) }}</bdi></b>
          <small v-if="view.coaches?.[s]"><bdi>{{ view.coaches[s] }}</bdi></small>
        </div>
      </div>
      <div v-if="split && total" class="waiting-split" :aria-label="$t('توقعات الأعضاء')">
        <span>{{ $t('توقعات الأعضاء') }}</span>
        <div class="waiting-bar">
          <i class="is-home" :style="{ inlineSize: pct(split.home) + '%' }" />
          <i class="is-draw" :style="{ inlineSize: pct(split.draw) + '%' }" />
          <i class="is-away" :style="{ inlineSize: pct(split.away) + '%' }" />
        </div>
        <small class="font-numbers" dir="ltr">{{ pct(split.home) }}% · {{ pct(split.draw) }}% · {{ pct(split.away) }}%</small>
      </div>
      <UiButton size="sm" variant="quiet" @click="emit('chat')">{{ $t('الدردشة') }}</UiButton>
    </section>
  </div>
</template>

<style scoped>
.waiting { position: absolute; inset: 0; z-index: 35; display: grid; place-items: center; padding: var(--space-md); background: color-mix(in srgb, var(--color-bg-deep) 80%, transparent); }
.waiting-card {
  display: flex; flex-direction: column; align-items: center; gap: var(--space-sm); inline-size: min(100%, 30rem); padding: var(--space-md);
  border: 1px solid color-mix(in srgb, var(--color-gold) 40%, transparent); border-radius: var(--radius-lg); background: var(--color-panel); text-align: center;
}
.waiting-kicker { font-size: var(--text-caption); color: var(--color-text-muted); }
.waiting-clock { font-size: 28px; color: var(--color-gold); }
.waiting-sides { display: flex; justify-content: space-between; gap: var(--space-md); inline-size: 100%; }
.waiting-side { display: flex; flex: 1; min-inline-size: 0; flex-direction: column; align-items: center; gap: var(--space-xs); font-size: var(--text-body); }
.waiting-coach { inline-size: 64px; }
.waiting-split { display: flex; flex-direction: column; gap: var(--space-xs); inline-size: 100%; font-size: var(--text-caption); }
.waiting-bar { display: flex; block-size: 8px; overflow: hidden; border-radius: var(--radius-pill); background: var(--color-surface-sunk); }
.waiting-bar .is-home { background: var(--color-success); }
.waiting-bar .is-draw { background: var(--color-text-muted); }
.waiting-bar .is-away { background: var(--color-danger); }
</style>
