<script setup lang="ts">
// A labelled input with its Arabic error under it. Email, password and codes are left to right [CLAUDE.md].
import { computed, useId } from 'vue'

const props = defineProps<{ label: string; type?: string; error?: string; autocomplete?: string; placeholder?: string; hint?: string }>()
const model = defineModel<string>({ default: '' })
const id = useId()
const ltr = computed(() => ['email', 'password', 'code', 'username'].includes(props.type ?? ''))
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <div class="flex items-center justify-between gap-2">
      <label :for="id" class="text-sm font-bold">{{ label }}</label>
      <slot name="aside" />
    </div>
    <input
      :id="id"
      v-model="model"
      :type="type === 'code' || type === 'username' ? 'text' : (type ?? 'text')"
      :dir="ltr ? 'ltr' : undefined"
      :autocomplete="autocomplete"
      :placeholder="placeholder"
      :aria-invalid="!!error"
      :aria-describedby="error ? id + '-err' : hint ? id + '-hint' : undefined"
      class="h-12 rounded-lg border bg-surface-sunk px-4 text-base outline-none focus:border-gold"
      :class="[error ? 'border-live' : 'border-text/10', ltr ? 'text-left' : '']"
    />
    <p v-if="error" :id="id + '-err'" class="text-sm text-[#FF8A8A]">{{ error }}</p>
    <p v-else-if="hint" :id="id + '-hint'" class="text-xs text-text-muted">{{ hint }}</p>
  </div>
</template>
