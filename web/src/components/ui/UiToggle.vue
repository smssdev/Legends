<script setup lang="ts">
// A toggle switch in place of the old tick boxes [X19]: the whole row is the target (44px at least), the knob slides,
// and screen readers hear a switch. v-model is true or false; tone colours the "on" side.
// [Sprint 54 W4] On reka-ui's Switch (Headless UI is gone): the label and the hint are tied to it by id.
import { SwitchRoot, SwitchThumb, useId } from 'reka-ui'

withDefaults(defineProps<{ label?: string; hint?: string; tone?: 'gold' | 'success' | 'live'; disabled?: boolean }>(), { tone: 'gold' })
const model = defineModel<boolean>({ default: false })
const ON = { gold: 'bg-gold', success: 'bg-success', live: 'bg-live' }
const id = useId(undefined, 'ui-toggle')
</script>

<template>
  <div class="flex min-h-touch items-center gap-3" :class="disabled ? 'pointer-events-none opacity-50' : ''">
    <SwitchRoot
      :id="id"
      v-model="model"
      :disabled="disabled"
      :aria-describedby="hint ? `${id}-hint` : undefined"
      class="relative h-7 w-12 shrink-0 rounded-pill transition-colors duration-200 after:absolute after:-inset-y-2 after:inset-x-0 after:content-[''] focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70 focus-visible:ring-offset-2 focus-visible:ring-offset-bg"
      :class="model ? ON[tone] : 'bg-surface-raised ring-1 ring-text/15'"
    >
      <SwitchThumb class="absolute start-1 top-1 block size-5 rounded-full bg-white shadow transition-transform duration-200 ease-soft" :class="model ? 'translate-x-5 rtl:-translate-x-5' : ''" />
      <span v-if="label && !$slots.default" class="sr-only">{{ $t(label) }}</span>
    </SwitchRoot>
    <span v-if="label || $slots.default" class="flex-1 text-sm">
      <label :for="id" class="block cursor-pointer"><slot>{{ $t(label) }}</slot></label>
      <span v-if="hint" :id="`${id}-hint`" class="block text-xs text-text-muted">{{ $t(hint) }}</span>
    </span>
  </div>
</template>
