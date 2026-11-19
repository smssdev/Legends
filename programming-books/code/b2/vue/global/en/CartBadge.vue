<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

// storeToRefs keeps state and getters reactive after destructuring; actions are plain functions
const { count } = storeToRefs(useCart());
</script>

<template>
  <span class="row">Cart <span class="badge">{{ count }}</span></span>
</template>
