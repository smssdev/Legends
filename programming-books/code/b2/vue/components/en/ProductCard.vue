<script setup lang="ts">
import type { Product } from "./products";

defineProps<{ product: Product }>();
const emit = defineEmits<{ add: [id: number] }>();
</script>

<template>
  <article class="card">
    <span v-if="product.isNew" class="badge">New</span>
    <h3>{{ product.name }}</h3>
    <p class="price">{{ product.price.toFixed(2) }} EGP</p>
    <button type="button" :disabled="!product.inStock" @click="emit('add', product.id)">
      {{ product.inStock ? "Add to cart" : "Sold out" }}
    </button>
  </article>
</template>
