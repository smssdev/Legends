<script setup lang="ts">
import { storeToRefs } from "pinia";
import type { OrderStatus } from "../api/schemas";
import { useSettings } from "../settings";

defineProps<{ status: OrderStatus }>();
const { t } = storeToRefs(useSettings());
</script>

<template>
  <span :class="['badge', status]">{{ t(status) }}</span>
</template>
