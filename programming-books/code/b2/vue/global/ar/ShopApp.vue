<script setup lang="ts">
import CartBadge from "./CartBadge.vue";
import CartSummary from "./CartSummary.vue";
import ProductList from "./ProductList.vue";
</script>

<template>
  <header>
    <span class="brand">متجر بِت</span>
    <CartBadge />
  </header>
  <ProductList />
  <CartSummary />
</template>
