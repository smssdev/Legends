<script setup lang="ts">
// [Sprint 30 Q1, Q4] A value on a scale on reka-ui's Slider (the Vue Radix): one smooth thumb that follows the finger,
// the arrows and Home/End on the keyboard, and the right direction in Arabic (the provider in App.vue). `marks` names
// the stops under it (the tactics' «منخفض … عالٍ»).
import { SliderRange, SliderRoot, SliderThumb, SliderTrack } from 'reka-ui'
import { computed } from 'vue'

withDefaults(defineProps<{ min?: number; max?: number; step?: number; label: string; marks?: string[]; disabled?: boolean; valueText?: string; dir?: 'ltr' | 'rtl' }>(), { min: 0, max: 100, step: 1 })
const model = defineModel<number>({ required: true })
const value = computed({ get: () => [model.value], set: (v: number[] | undefined) => { if (v?.length) model.value = v[0] } })
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <SliderRoot v-model="value" :dir="dir" :min="min" :max="max" :step="step" :disabled="disabled" class="relative flex h-touch w-full touch-none select-none items-center data-[disabled]:opacity-50">
      <SliderTrack class="relative h-2 grow overflow-hidden rounded-pill bg-surface-sunk">
        <SliderRange class="absolute h-full rounded-pill bg-gradient-to-l from-gold to-brand-light rtl:bg-gradient-to-r" />
      </SliderTrack>
      <SliderThumb :aria-label="$t(label)" :aria-valuetext="valueText" class="block size-6 rounded-full border-2 border-gold bg-text shadow-lg transition-transform focus:outline-none focus-visible:ring-4 focus-visible:ring-gold/40 active:scale-110" />
    </SliderRoot>
    <div v-if="marks?.length" class="flex justify-between text-xs text-text-muted" aria-hidden="true">
      <span v-for="m in marks" :key="m">{{ $t(m) }}</span>
    </div>
  </div>
</template>
