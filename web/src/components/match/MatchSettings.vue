<template>
  <!-- [Sprint 56 W7, Sprint 57 W2] The view's settings: the sound, the commentator, the simulator, the drawing's tier. -->
  <UiDialog :open="open" side closable title="إعدادات العرض" @close="emit('close')">
    <div class="flex flex-col gap-2">
      <button type="button" class="ui-choice px-3 text-sm" :aria-pressed="soundOn" @click="audio.toggleSound">
        {{ soundOn ? $t('الصوت: يعمل') : $t('تشغيل الصوت') }}
      </button>
      <button type="button" class="ui-choice px-3 text-sm" @click="audio.toggleCommentary">
        {{ $t('التعليق: {v0}', { v0: commentary === 'off' ? $t('متوقف') : 'English' }) }}
      </button>
      <button type="button" class="ui-choice px-3 text-sm" :aria-pressed="chosenView === 'unity'" @click="switchView">
        {{ $t('العرض: {v0}', { v0: chosenView === 'unity' ? $t('المطوّر') : $t('الكرتوني') }) }}
      </button>
      <button type="button" class="ui-choice px-3 text-sm" :title="PERF_HINT" @click="nextPerf">
        {{
          $t('الأداء: {v0}{v1}', {
            v0: PERF_NAMES[perfPref],
            v1: perfPref === 'auto' ? (tier === 'low' ? $t(' (سلس)') : tier === 'mid' ? $t(' (متوازن)') : $t(' (كامل)')) : '',
          })
        }}
      </button>
      <!-- [Sprint 30 Q8] The developers' panel: the admins' only. -->
      <button
        v-if="admin"
        type="button"
        class="ui-choice px-3 text-sm text-text-muted"
        :aria-pressed="dev"
        @click="emit('update:dev', !dev)"
      >
        {{ $t('لوحة المطور') }}
      </button>
    </div>
  </UiDialog>
</template>

<script setup lang="ts">
import UiDialog from '../ui/UiDialog.vue'
import { perfPref, setPerfPref, tier, type PerfPref } from '../../match/perf'
import { useViewing } from '../../match/viewing'
import type { useMatchAudio } from '../../match/useMatchAudio'

const props = defineProps<{ open: boolean; audio: ReturnType<typeof useMatchAudio>; admin: boolean; dev: boolean }>()
const emit = defineEmits<{ close: []; 'update:dev': [on: boolean] }>()
const { soundOn, commentary } = props.audio
const viewing = useViewing()
const chosenView = viewing.chosenView
// The smooth mode for weak phones [X30]: automatic by default, or forced either way by the coach.
const PERF_NAMES: Record<PerfPref, string> = { auto: 'تلقائي', smooth: 'سلس', balanced: 'متوازن', full: 'كامل' }
const PERF_HINT = 'سلس: رسوم أخف وحركة أنعم على الجوالات الضعيفة. متوازن: للجوالات المتوسطة. كامل: كل المؤثرات. تلقائي: يختار حسب جهازك.'
const nextPerf = () => setPerfPref(({ auto: 'smooth', smooth: 'balanced', balanced: 'full', full: 'auto' } as const)[perfPref.value])
// The simulator: cartoon or Unity, switched here or in the account [X10].
const switchView = () => void viewing.save({ match_view: chosenView.value === 'unity' ? 'cartoon' : 'unity' }).catch(() => {})
</script>
