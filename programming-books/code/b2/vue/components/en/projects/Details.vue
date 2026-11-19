<script setup lang="ts">
import TabList from "./TabList.vue";
</script>

<template>
  <TabList label="Product details" :labels="['Description', 'Reviews', 'Shipping']">
    <template #tab-0><p>A friendly guide that takes you from your first line of code to your first app.</p></template>
    <template #tab-1><p>“Clear, kind and practical. My son finished it in a month.” ★★★★★</p></template>
    <template #tab-2><p>Free delivery in Egypt for orders over 50 EGP. Arrives in 2–4 days.</p></template>
  </TabList>
</template>
