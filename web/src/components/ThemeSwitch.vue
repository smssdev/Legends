<script setup lang="ts">
// [X56] The look switch: the night (our own), the day, or as the device is set. On this device, beside the language.
import { setThemePref, themePref, type ThemePref } from '../lib/theme'

const LOOKS: [ThemePref, string, string][] = [
  ['dark', '🌙', 'ليلي'],
  ['light', '☀️', 'نهاري'],
  ['auto', '📱', 'تلقائي'],
]
</script>

<template>
  <div class="inline-flex rounded-lg bg-surface-sunk p-1" role="radiogroup" :aria-label="$t('المظهر')">
    <button
      v-for="[k, icon, label] in LOOKS"
      :key="k"
      type="button"
      role="radio"
      :aria-checked="themePref === k"
      :title="k === 'auto' ? $t('كما في إعدادات جهازك') : undefined"
      class="flex h-touch items-center gap-1.5 rounded-md px-3 text-sm font-bold"
      :class="themePref === k ? 'bg-gold text-on-gold' : 'text-text-soft'"
      @click="setThemePref(k)"
    >
      <span aria-hidden="true">{{ icon }}</span>{{ $t(label) }}
    </button>
  </div>
</template>
