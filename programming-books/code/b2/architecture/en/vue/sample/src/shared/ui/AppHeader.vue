<script setup lang="ts">
import { useCart } from "../../features/cart/store";

const cart = useCart();
</script>

<template>
  <p>{{ cart.count }}</p>
</template>
