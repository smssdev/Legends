<script setup lang="ts">
import type { Orders } from "./orders";

defineProps<{ state: Orders }>();
</script>

<template>
  <p v-if="state.status === 'loading'" class="muted"><span class="spinner" />Loading your orders…</p>
  <p v-else-if="state.status === 'error'" class="error">
    Could not load your orders: {{ state.message }}
    <button type="button" class="secondary">Try again</button>
  </p>
  <p v-else-if="state.orders.length === 0" class="muted">You have no orders yet.</p>
  <ul v-else>
    <li v-for="order in state.orders" :key="order">{{ order }}</li>
  </ul>
</template>
