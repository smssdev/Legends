<script setup lang="ts">
import ProductCard from "./ProductCard.vue";
import ShopSection from "./ShopSection.vue";
import { products } from "./products";
</script>

<template>
  <ShopSection title="Bit's shop">
    <div class="grid">
      <ProductCard v-for="product in products" :key="product.id" :product="product" />
    </div>
  </ShopSection>
</template>
