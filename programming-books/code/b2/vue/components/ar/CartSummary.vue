<script setup lang="ts">
const props = defineProps<{ count: number; total: number }>();
const isEmpty = props.count === 0;
</script>

<template>
  <p class="summary" :class="{ empty: isEmpty }">
    {{ count }} عناصر في سلتك: {{ total.toFixed(2) }} جنيهاً
  </p>
  <button type="button" :disabled="isEmpty" :style="{ fontWeight: 700 }">أضف إلى السلة</button>
</template>
