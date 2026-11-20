<script setup lang="ts">
import BaseButton from "../../shared/ui/BaseButton.vue";
import { formatMoney } from "../../shared/lib/money";
import { useCart } from "../cart";
import { useProducts } from "./useProducts";

const products = useProducts();
const cart = useCart();
</script>

<template>
  <ul>
    <li v-for="p in products" :key="p.id">
      {{ p.name }} {{ formatMoney(p.price) }} <BaseButton @click="cart.add(p)">+</BaseButton>
    </li>
  </ul>
</template>
