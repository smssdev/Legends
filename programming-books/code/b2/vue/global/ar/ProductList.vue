<script setup lang="ts">
import { useCart, type Product } from "./stores/cart";

const products: Product[] = [
  { id: 1, name: "البرمجة من الصفر", price: 25 },
  { id: 2, name: "كوب بِت", price: 8 },
  { id: 3, name: "قبعة بِت", price: 12 },
];
const { add } = useCart();
</script>

<template>
  <section class="card">
    <div v-for="p in products" :key="p.id" class="row spread">
      <span>{{ p.name }}</span>
      <button type="button" @click="add(p)">أضف</button>
    </div>
  </section>
</template>
