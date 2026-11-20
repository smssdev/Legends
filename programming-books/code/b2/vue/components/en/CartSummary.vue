<script setup lang="ts">
const props = defineProps<{ count: number; total: number }>();
const isEmpty = props.count === 0;
</script>

<template>
  <p class="summary" :class="{ empty: isEmpty }">
    {{ count }} items in your cart: {{ total.toFixed(2) }} EGP
  </p>
  <button type="button" :disabled="isEmpty" :style="{ fontWeight: 700 }">Add to cart</button>
</template>
