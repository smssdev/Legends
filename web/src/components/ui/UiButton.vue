<script setup lang="ts">
// Buttons (design system: احفظ التشكيلة / تحسين تلقائي / إلغاء). At least 44px to touch.
withDefaults(defineProps<{ variant?: 'primary' | 'outline' | 'quiet' | 'danger'; type?: 'button' | 'submit'; block?: boolean; disabled?: boolean }>(), {
  variant: 'primary',
  type: 'button',
})
</script>

<template>
  <button
    :type="type"
    :disabled="disabled"
    class="inline-flex h-12 min-w-touch items-center justify-center gap-2 rounded-lg px-5 font-display text-base font-extrabold transition disabled:cursor-not-allowed disabled:opacity-50"
    :class="[
      block ? 'w-full' : '',
      {
        primary: 'bg-gold text-on-gold hover:bg-gold-light',
        outline: 'border border-gold/70 text-gold hover:bg-gold/10',
        quiet: 'bg-surface-raised text-text hover:bg-surface-raised/80',
        danger: 'bg-live text-white hover:bg-live/90',
      }[variant],
    ]"
  >
    <slot />
  </button>
</template>
