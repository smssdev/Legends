<script setup lang="ts">
// [Sprint 64 W5] Every number a coach may ask about (the chemistry, the strength, the morale, the coach's points) is a
// button: a tap opens «where it came from», its parts as the server counts them (GET team/explain/{what}), and its
// guide topic. One component for every screen; without a league (no club to read) it is only the number.
import { ref } from 'vue'
import { api } from '../../api/client'
import type { components } from '../../api/schema'
import UiDialog from './UiDialog.vue'
import UiButton from './UiButton.vue'

type What = components['schemas']['Explain']['what']
const props = defineProps<{ what: What; leagueId?: number | null }>()
const TITLE: Record<What, string> = { chemistry: 'من أين جاءت الكيمياء؟', strength: 'من أين جاءت قوة فريقك؟', morale: 'من أين جاءت المعنويات؟', rating: 'من أين جاءت نقاطك؟' }
const open = ref(false)
const data = ref<components['schemas']['Explain'] | null>(null)
const failed = ref(false)

async function show() {
  open.value = true
  if (data.value || !props.leagueId) return
  try {
    data.value = (await api.GET('/leagues/{league}/team/explain/{what}', { params: { path: { league: props.leagueId, what: props.what } } })).data ?? null
  } catch { failed.value = true }
}
</script>

<template>
  <button v-if="leagueId" type="button" class="explain" :aria-label="$t(TITLE[what])" @click="show"><slot /></button>
  <slot v-else />
  <UiDialog :open="open" :title="TITLE[what]" closable @close="open = false">
    <p v-if="failed" class="explain-muted">{{ $t('تعذّر جلب التفاصيل الآن.') }}</p>
    <p v-else-if="!data" class="explain-muted">{{ $t('جارٍ التحميل...') }}</p>
    <template v-else>
      <b class="explain-value font-numbers" dir="ltr">{{ data.value }}</b>
      <dl class="explain-parts">
        <div v-for="(p, i) in data.parts" :key="i" class="explain-part"><dt>{{ p.label }}</dt><dd class="font-numbers" dir="ltr">{{ p.value }}</dd></div>
      </dl>
      <UiButton size="sm" variant="quiet" :to="`/guide#${data.topic}`">{{ $t('اقرأ أكثر في الدليل') }}</UiButton>
    </template>
  </UiDialog>
</template>

<style scoped>
.explain { display: inline-flex; align-items: center; min-block-size: 44px; min-inline-size: 44px; margin-block: -12px; justify-content: center; border-radius: var(--radius-md, 8px); text-decoration: underline dotted; text-underline-offset: 4px; }
.explain:focus-visible { outline: 2px solid var(--color-gold); }
.explain-muted { color: var(--color-text-muted); }
.explain-value { display: block; font-size: 32px; color: var(--ink-gold); text-align: center; }
.explain-parts { display: flex; flex-direction: column; gap: var(--space-xs); margin-block: var(--space-md); }
.explain-part { display: flex; justify-content: space-between; gap: var(--space-sm); padding: var(--space-sm); border-radius: var(--radius-lg); background: var(--color-surface-sunk); font-size: var(--text-body); }
</style>
