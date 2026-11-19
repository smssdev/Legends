<script setup lang="ts">
import { computed } from "vue";
import { counts } from "./counts";

const props = defineProps<{ prices: number[] }>();

// Runs again every time the template is drawn, for every place it is used
function totalMethod() {
  counts.method++;
  return props.prices.reduce((sum, p) => sum + p, 0);
}

// Runs once, and again only when the cart changes
const total = computed(() => {
  counts.computed++;
  return props.prices.reduce((sum, p) => sum + p, 0);
});
</script>

<template>
  <p>{{ totalMethod() }} = {{ totalMethod() }} = {{ totalMethod() }}</p>
  <p>{{ total }} = {{ total }} = {{ total }}</p>
</template>
