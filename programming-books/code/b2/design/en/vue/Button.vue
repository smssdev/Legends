<script setup lang="ts">
type Variant = "primary" | "secondary" | "danger" | "ghost";
type Size = "sm" | "md" | "lg";

const { variant = "primary", size = "md", loading = false, type = "button" } = defineProps<{
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  disabled?: boolean;
  type?: "button" | "submit" | "reset";
}>();
</script>

<!-- Every native button prop (type, disabled, onClick, aria-…) still works -->
<template>
  <button :type="type" :class="['btn', `btn-${variant}`, `btn-${size}`]" :disabled="disabled || loading" :aria-busy="loading || undefined">
    <span v-if="loading" class="spinner" aria-hidden="true" />
    <slot />
  </button>
</template>
