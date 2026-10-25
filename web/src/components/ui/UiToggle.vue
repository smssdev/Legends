<script setup lang="ts">
// A toggle switch in place of the old tick boxes [X19]: the whole row is the target (44px at least), the knob slides,
// and screen readers hear a switch. v-model is true or false; tone colours the "on" side.
import { useId } from 'vue'

const props = withDefaults(defineProps<{ label?: string; hint?: string; tone?: 'gold' | 'success' | 'live'; disabled?: boolean }>(), { tone: 'gold' })
const model = defineModel<boolean>({ default: false })
const id = useId()
const ON = { gold: 'bg-gold', success: 'bg-success', live: 'bg-live' }
function flip() {
  if (!props.disabled) model.value = !model.value
}
</script>

<template>
  <div class="flex min-h-touch items-center gap-3" :class="disabled ? 'opacity-50' : ''">
    <button
      :id="id"
      type="button"
      role="switch"
      :aria-checked="model"
      :aria-describedby="hint ? id + '-hint' : undefined"
      :disabled="disabled"
      class="relative h-7 w-12 shrink-0 rounded-pill transition-colors"
      :class="model ? ON[tone] : 'bg-surface-raised ring-1 ring-text/15'"
      @click="flip"
    >
      <span class="absolute top-1 size-5 rounded-full bg-white shadow transition-all" :class="model ? 'start-6' : 'start-1'" />
      <span class="sr-only">{{ label }}</span>
    </button>
    <label v-if="label || $slots.default" :for="id" class="flex-1 cursor-pointer text-sm" @click.prevent="flip">
      <slot>{{ label }}</slot>
      <span v-if="hint" :id="id + '-hint'" class="block text-xs text-text-muted">{{ hint }}</span>
    </label>
  </div>
</template>
