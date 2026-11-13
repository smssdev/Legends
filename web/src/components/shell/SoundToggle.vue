<script setup lang="ts">
// [Sprint 63 G13] The game's sound in three levels, the app's same settings: the interface (the notification tone,
// the taps and chimes), the stadium (the match's crowd and ball) and the commentator. Kept on this device
// (lib/soundLevels.ts); each moved plays a sample of it, so the coach hears what he set.
import UiSlider from '../ui/UiSlider.vue'
import { levels, uiSound } from '../../lib/soundLevels'

const rows = [
  { key: 'ui', label: 'الواجهة', hint: 'النغمات والنقرات والإشعارات' },
  { key: 'stadium', label: 'الملعب', hint: 'الجمهور والكرة في المباراة' },
  { key: 'voice', label: 'المعلق', hint: 'صوت المعلق في المباراة' },
] as const

function sample(key: (typeof rows)[number]['key']) {
  uiSound(key === 'ui' ? 'confirm' : key === 'stadium' ? 'whistle' : 'tap', key)
}
</script>

<template>
  <fieldset class="flex flex-col gap-3 rounded-lg px-1">
    <legend class="mb-1 font-bold">{{ $t('مستوى الصوت') }}</legend>
    <div v-for="r in rows" :key="r.key" class="flex flex-col gap-0.5">
      <div class="flex items-baseline justify-between gap-2">
        <span class="font-bold">{{ $t(r.label) }}</span>
        <span class="font-numbers text-caption text-text-muted" dir="ltr">{{ levels[r.key] }}%</span>
      </div>
      <UiSlider v-model="levels[r.key]" :label="r.label" :value-text="`${levels[r.key]}%`" :step="5" @pointerup="sample(r.key)" @keyup="sample(r.key)" />
      <span class="text-caption text-text-muted">{{ $t(r.hint) }}</span>
    </div>
  </fieldset>
</template>
