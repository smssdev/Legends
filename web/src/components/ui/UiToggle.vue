<script setup lang="ts">
// A toggle switch in place of the old tick boxes [X19]: the whole row is the target (44px at least), the knob slides,
// and screen readers hear a switch. v-model is true or false; tone colours the "on" side.
// [X61] On Headless UI's Switch: the label, the hint and the keyboard are its own.
import { Switch, SwitchDescription, SwitchGroup, SwitchLabel } from '@headlessui/vue'

withDefaults(defineProps<{ label?: string; hint?: string; tone?: 'gold' | 'success' | 'live'; disabled?: boolean }>(), { tone: 'gold' })
const model = defineModel<boolean>({ default: false })
const ON = { gold: 'bg-gold', success: 'bg-success', live: 'bg-live' }
</script>

<template>
  <SwitchGroup as="div" class="flex min-h-touch items-center gap-3" :class="disabled ? 'pointer-events-none opacity-50' : ''">
    <Switch
      v-model="model"
      :disabled="disabled"
      class="relative h-7 w-12 shrink-0 rounded-pill transition-colors duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70 focus-visible:ring-offset-2 focus-visible:ring-offset-bg"
      :class="model ? ON[tone] : 'bg-surface-raised ring-1 ring-text/15'"
    >
      <span class="absolute start-1 top-1 size-5 rounded-full bg-white shadow transition-transform duration-200 ease-soft" :class="model ? 'translate-x-5 rtl:-translate-x-5' : ''" />
      <span v-if="label && !$slots.default" class="sr-only">{{ $t(label) }}</span>
    </Switch>
    <span v-if="label || $slots.default" class="flex-1 text-sm">
      <SwitchLabel class="block cursor-pointer"><slot>{{ $t(label) }}</slot></SwitchLabel>
      <SwitchDescription v-if="hint" class="block text-xs text-text-muted">{{ $t(hint) }}</SwitchDescription>
    </span>
  </SwitchGroup>
</template>
