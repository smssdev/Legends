<script setup lang="ts">
import { ref } from "vue";
import QuantityInput from "./QuantityInput.vue";

const mugs = ref(1);
</script>

<template>
  <p>كوب بِت</p>
  <QuantityInput v-model="mugs" :max="5" label="الكمية" />
  <p>طلبت: {{ mugs }} · المجموع: {{ mugs * 8 }} جنيهاً</p>
</template>
