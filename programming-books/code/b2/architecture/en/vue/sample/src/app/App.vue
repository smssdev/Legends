<script setup lang="ts">
import { CatalogPage } from "../features/catalog";
import { CartBadge } from "../features/cart";
import AppLayout from "../shared/ui/AppLayout.vue";
</script>

<template>
  <AppLayout>
    <template #header><CartBadge /></template>
    <CatalogPage />
  </AppLayout>
</template>
