<script setup lang="ts">
import { useCart } from "./store";

const cart = useCart();
</script>

<template>
  <span>{{ cart.count }}</span>
</template>
