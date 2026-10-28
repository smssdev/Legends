<script setup lang="ts">
// [Sprint 21 E2.5] A verified coach's account: lighter than the developers' official badge, a check beside the name.
</script>

<template>
  <span class="inline-flex size-4 items-center justify-center rounded-full bg-success/20 align-middle text-success" :title="$t('حساب موثّق')" role="img" :aria-label="$t('حساب موثّق')">
    <svg viewBox="0 0 24 24" class="size-3" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
  </span>
</template>
