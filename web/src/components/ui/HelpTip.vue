<script setup lang="ts">
// A "?" beside a setting [X5]: a tap opens what it does, in words from the server; another tap (or Esc) closes it.
import { ref, useId } from 'vue'

defineProps<{ text?: string; label: string }>()
const open = ref(false)
const id = useId()
</script>

<template>
  <span v-if="text" class="inline-flex flex-col">
    <button
      type="button"
      class="inline-flex size-touch shrink-0 items-center justify-center rounded-full text-text-muted hover:text-gold"
      :aria-expanded="open"
      :aria-controls="id"
      :aria-label="`ما هو ${label}؟`"
      @click.stop.prevent="open = !open"
      @keydown.esc="open = false"
    ><span class="flex size-6 items-center justify-center rounded-full border-2 border-current font-bold leading-none">؟</span></button>
  </span>
  <p v-if="text && open" :id="id" class="basis-full rounded-lg bg-surface-sunk px-3 py-2 text-sm font-normal leading-relaxed text-text-soft" role="note">{{ text }}</p>
</template>
