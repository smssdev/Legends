<script setup lang="ts">
// With v-model the parent owns the value; without it, defineModel keeps a local one
const on = defineModel<boolean>({ default: false });
defineProps<{ label: string }>();
</script>

<template>
  <button type="button" role="switch" :aria-checked="on" class="switch" @click="on = !on">
    <span class="track" aria-hidden="true"><span class="thumb" /></span>
    {{ label }}
  </button>
</template>
