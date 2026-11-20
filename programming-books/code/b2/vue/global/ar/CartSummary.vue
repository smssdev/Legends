<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

const cart = useCart();
const { lines, total } = storeToRefs(cart);
</script>

<template>
  <p v-if="Object.keys(lines).length === 0" class="card muted">السلة فارغة.</p>
  <section v-else class="card">
    <ul>
      <li v-for="l in lines" :key="l.product.id">
        <span>{{ l.quantity }} × {{ l.product.name }}</span>
        <span>{{ l.quantity * l.product.price }} جنيهاً</span>
      </li>
    </ul>
    <p><b>المجموع: {{ total }} جنيهاً</b></p>
    <button type="button" class="secondary" @click="cart.clear()">أفرغ السلة</button>
  </section>
</template>
