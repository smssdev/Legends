<script setup lang="ts">
// [Sprint 27 B1, the owner's request 2026-10-30] The league's days off: weekdays with no matches (Friday, say), three
// at most, free. ISO weekdays as the server keeps them (1 Monday to 7 Sunday), shown from Saturday.
const model = defineModel<number[]>({ required: true })
defineProps<{ error?: string }>()
const DAYS: [number, string][] = [
  [6, 'السبت'],
  [7, 'الأحد'],
  [1, 'الاثنين'],
  [2, 'الثلاثاء'],
  [3, 'الأربعاء'],
  [4, 'الخميس'],
  [5, 'الجمعة'],
]
const MAX = 3
function toggle(d: number) {
  model.value = model.value.includes(d)
    ? model.value.filter((x) => x !== d)
    : model.value.length < MAX
      ? [...model.value, d].sort()
      : model.value
}
</script>

<template>
  <fieldset class="flex flex-col gap-1.5">
    <legend class="mb-1.5 text-sm font-bold">{{ $t('أيام إجازة بلا مباريات') }}</legend>
    <div class="grid grid-cols-4 gap-1 rounded-lg bg-surface-sunk p-1 sm:grid-cols-7">
      <button
        v-for="[d, label] in DAYS"
        :key="d"
        type="button"
        class="h-11 rounded-md text-sm font-bold"
        :class="model.includes(d) ? 'bg-gold text-on-gold' : 'text-text-soft'"
        :aria-pressed="model.includes(d)"
        :disabled="!model.includes(d) && model.length >= MAX"
        @click="toggle(d)"
      >
        {{ $t(label) }}
      </button>
    </div>
    <span v-if="error" class="text-sm text-danger">{{ error }}</span>
  </fieldset>
</template>
