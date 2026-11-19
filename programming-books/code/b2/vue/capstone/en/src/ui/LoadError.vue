<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const emit = defineEmits<{ retry: [] }>();
const { t } = storeToRefs(useSettings());
</script>

<template>
  <div role="alert" class="card">
    <p>{{ t("loadError") }}</p>
    <button type="button" @click="emit('retry')">{{ t("retry") }}</button>
  </div>
</template>
