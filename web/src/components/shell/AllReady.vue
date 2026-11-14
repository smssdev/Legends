<script setup lang="ts">
// [Sprint 64 W4] Nothing waits: «all ready», the next match's countdown, and a button that turns the «match soon»
// notifications on (the existing kind, App\Notify) when they are off. The full settings stay in the profile.
import { computed, onMounted, ref } from 'vue'
import { api, ensureCsrf } from '../../api/client'
import { countdown, useNow } from '../../lib/clock'
import { act } from '../../lib/action'
import { t } from '../../lib/i18n'
import { useBoard } from '../../stores/board'
import Character from '../characters/Character.vue'
import UiButton from '../ui/UiButton.vue'

const board = useBoard()
const now = useNow()
const reminded = ref<boolean | null>(null)
const at = computed(() => board.board?.match?.scheduled_at ?? null)
onMounted(async () => {
  try {
    const s = (await api.GET('/notifications')).data
    reminded.value = !!s?.kinds.find((k) => k.kind === 'match_soon')?.on
  } catch {
    reminded.value = null
  }
})
const remind = () =>
  act(
    'remind',
    async () => {
      await ensureCsrf()
      await api.PUT('/notifications', { body: { kinds: { match_soon: true } } })
      reminded.value = true
    },
    { success: t('سنذكّرك بتشكيلتك قبل المباراة بساعة، وبالمباراة قبلها بنصف ساعة.') },
  )
</script>

<template>
  <div class="ready" role="status">
    <Character model="A1" mood="joy" class="ready-face" />
    <b>{{ $t('كل شيء جاهز') }}</b>
    <span v-if="at && countdown(at, now)" class="ready-when"
      >{{ $t('مباراتك بعد') }} <bdi class="font-numbers" dir="ltr">{{ countdown(at, now) }}</bdi></span
    >
    <UiButton v-if="reminded === false" size="sm" variant="outline" @click="remind">{{ $t('ذكّرني قبل المباراة') }}</UiButton>
  </div>
</template>

<style scoped>
.ready {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-xs);
  padding-block: var(--space-md);
  text-align: center;
}
.ready-face {
  inline-size: 56px;
}
.ready-when {
  font-size: var(--text-caption);
  color: var(--color-text-muted);
}
</style>
