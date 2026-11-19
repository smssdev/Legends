<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

const cart = useCart();
const { lines, total } = storeToRefs(cart);
</script>

<template>
  <p v-if="Object.keys(lines).length === 0" class="card muted">The cart is empty.</p>
  <section v-else class="card">
    <ul>
      <li v-for="l in lines" :key="l.product.id">
        <span>{{ l.quantity }} × {{ l.product.name }}</span>
        <span>{{ l.quantity * l.product.price }} EGP</span>
      </li>
    </ul>
    <p><b>Total: {{ total }} EGP</b></p>
    <button type="button" class="secondary" @click="cart.clear()">Empty the cart</button>
  </section>
</template>
