<script setup lang="ts">
export type Tone = "neutral" | "success" | "warning" | "danger";
const { tone = "neutral" } = defineProps<{ tone?: Tone }>();
</script>

<template>
  <span :class="['badge', `badge-${tone}`]"><slot /></span>
</template>
