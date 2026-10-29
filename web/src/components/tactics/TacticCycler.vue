<script setup lang="ts" generic="K extends string | number">
// [Sprint 20 S1] One choice between two arrows, as the owner's tactics picture: the arrows step through the options
// (and wrap), the chosen one is written large between them. 44px arrows; the label is read with the value.
import { computed } from 'vue'

const props = defineProps<{ options: { value: K; label: string }[]; label: string }>()
const model = defineModel<K>({ required: true })
const at = computed(() => Math.max(0, props.options.findIndex((o) => o.value === model.value)))
const step = (d: number) => (model.value = props.options[(at.value + d + props.options.length) % props.options.length].value)
</script>

<template>
  <div class="flex items-center justify-between gap-1" role="group" :aria-label="label">
    <!-- In Arabic the start is on the right: the right arrow goes back. -->
    <button type="button" class="grid size-11 shrink-0 place-items-center rounded-lg text-2xl text-text hover:bg-surface-raised" :aria-label="$t('السابق')" @click="step(-1)">
      <span aria-hidden="true" class="rtl:rotate-180">‹</span>
    </button>
    <output class="line-clamp-2 min-w-0 flex-1 text-center font-display text-base leading-tight font-bold sm:text-lg" aria-live="polite">{{ $t(options[at]?.label ?? '') }}</output>
    <button type="button" class="grid size-11 shrink-0 place-items-center rounded-lg text-2xl text-text hover:bg-surface-raised" :aria-label="$t('التالي')" @click="step(1)">
      <span aria-hidden="true" class="rtl:rotate-180">›</span>
    </button>
  </div>
</template>
