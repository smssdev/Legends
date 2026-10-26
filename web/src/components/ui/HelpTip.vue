<script setup lang="ts">
// A "?" beside a setting [X5]: a tap opens what it does, in words from the server. [UP7] In a small window over the
// screen, closed by «لقد فهمت» (or Esc, or a tap outside), instead of text printed in the page.
import { nextTick, ref, useId } from 'vue'

defineProps<{ text?: string; label: string }>()
const open = ref(false)
const id = useId()
const ok = ref<HTMLButtonElement | null>(null)
async function show() {
  open.value = true
  await nextTick()
  ok.value?.focus()
}
</script>

<template>
  <span v-if="text" class="inline-flex">
    <button
      type="button"
      class="help-q inline-flex size-touch shrink-0 items-center justify-center rounded-full text-text-muted hover:text-gold"
      :aria-expanded="open"
      :aria-controls="id"
      :aria-label="$t('ما هو {v0}؟', { v0: label })"
      @click.stop.prevent="show"
    ><span class="flex size-5 items-center justify-center rounded-full border-2 border-current text-xs font-bold leading-none">{{ $t('؟') }}</span></button>
  </span>
  <Teleport to="body">
    <div v-if="text && open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" @click.self="open = false" @keydown.esc="open = false">
      <div :id="id" role="dialog" aria-modal="true" :aria-label="label" class="flex w-full max-w-sm flex-col gap-3 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-extrabold">{{ $t(label) }}</h2>
        <p class="text-sm leading-relaxed text-text-soft">{{ text }}</p>
        <button ref="ok" type="button" class="h-touch rounded-lg bg-gold font-bold text-on-gold" @click="open = false">{{ $t('لقد فهمت') }}</button>
      </div>
    </div>
  </Teleport>
</template>
