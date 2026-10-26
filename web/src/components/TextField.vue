<script setup lang="ts">
// A labelled input with its Arabic error under it. Email, password and codes are left to right [CLAUDE.md].
// A password has an eye button that shows or hides what was typed [X7].
import { computed, ref, useId } from 'vue'

const props = defineProps<{ label: string; type?: string; error?: string; autocomplete?: string; placeholder?: string; hint?: string }>()
const model = defineModel<string>({ default: '' })
const id = useId()
const ltr = computed(() => ['email', 'password', 'code', 'username'].includes(props.type ?? ''))
const isPassword = computed(() => props.type === 'password')
const shown = ref(false)
const inputType = computed(() => {
  if (props.type === 'code' || props.type === 'username') return 'text'
  if (isPassword.value && shown.value) return 'text'
  return props.type ?? 'text'
})
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <div class="flex items-center justify-between gap-2">
      <label :for="id" class="text-sm font-bold">{{ label }}</label>
      <slot name="aside" />
    </div>
    <div class="relative">
      <input
        :id="id"
        v-model="model"
        :type="inputType"
        :dir="ltr ? 'ltr' : undefined"
        :autocomplete="autocomplete"
        :placeholder="placeholder"
        :spellcheck="isPassword ? false : undefined"
        :autocapitalize="isPassword ? 'off' : undefined"
        :aria-invalid="!!error"
        :aria-describedby="error ? id + '-err' : hint ? id + '-hint' : undefined"
        class="h-12 w-full rounded-lg border bg-surface-sunk px-4 text-base outline-none focus:border-gold"
        :class="[error ? 'border-live' : 'border-text/10', ltr ? 'text-left' : '', isPassword ? 'pr-12' : '']"
      />
      <button
        v-if="isPassword"
        type="button"
        class="absolute inset-y-0 right-0 flex w-12 items-center justify-center rounded-e-lg text-text-muted hover:text-text focus-visible:text-gold"
        :aria-label="shown ? $t('إخفاء كلمة المرور') : $t('إظهار كلمة المرور')"
        :aria-pressed="shown"
        :aria-controls="id"
        @click="shown = !shown"
      >
        <svg v-if="!shown" viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z" /><circle cx="12" cy="12" r="3" />
        </svg>
        <svg v-else viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M3 3l18 18" /><path d="M10.6 5.1A10.4 10.4 0 0 1 12 5c6.5 0 10 7 10 7a17.6 17.6 0 0 1-3.2 4.1M6.6 6.6C3.7 8.4 2 12 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.4-1.6" /><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" />
        </svg>
      </button>
    </div>
    <p v-if="error" :id="id + '-err'" class="text-sm text-[#FF8A8A]">{{ error }}</p>
    <p v-else-if="hint" :id="id + '-hint'" class="text-xs text-text-muted">{{ hint }}</p>
  </div>
</template>
