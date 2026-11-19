<script setup lang="ts">
import { ref } from "vue";
import QuantityInput from "./QuantityInput.vue";

const mugs = ref(1);
</script>

<template>
  <p>Bit mug</p>
  <QuantityInput v-model="mugs" :max="5" label="Quantity" />
  <p>You ordered: {{ mugs }} · Total: {{ mugs * 8 }} EGP</p>
</template>
