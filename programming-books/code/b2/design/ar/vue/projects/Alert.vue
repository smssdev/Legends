<script setup lang="ts">
type Tone = "info" | "success" | "warning" | "danger";
const ICONS: Record<Tone, string> = { info: "ℹ", success: "✓", warning: "!", danger: "✕" };

const { tone = "info" } = defineProps<{ tone?: Tone }>();
</script>

<template>
  <!-- Errors interrupt (alert); everything else waits for a pause (status) -->
  <div :class="['alert', `alert-${tone}`]" :role="tone === 'danger' ? 'alert' : 'status'">
    <span aria-hidden="true">{{ ICONS[tone] }}</span>
    <span><slot /></span>
  </div>
</template>
