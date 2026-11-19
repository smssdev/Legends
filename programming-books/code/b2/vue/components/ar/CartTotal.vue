<script setup lang="ts">
import { computed } from "vue";
import { counts } from "./counts";

const props = defineProps<{ prices: number[] }>();

// تعمل من جديد في كل مرة يُرسم فيها القالب، ولكل مكان تُستخدم فيه
function totalMethod() {
  counts.method++;
  return props.prices.reduce((sum, p) => sum + p, 0);
}

// تعمل مرة واحدة، ثم فقط حين تتغير السلة
const total = computed(() => {
  counts.computed++;
  return props.prices.reduce((sum, p) => sum + p, 0);
});
</script>

<template>
  <p>{{ totalMethod() }} = {{ totalMethod() }} = {{ totalMethod() }}</p>
  <p>{{ total }} = {{ total }} = {{ total }}</p>
</template>
