<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const { t } = storeToRefs(useSettings());
</script>

<template>
  <div aria-busy="true" :aria-label="t('loading')">
    <div class="skeleton" />
    <div class="skeleton" />
    <div class="skeleton" />
  </div>
</template>
