<script setup lang="ts">
import type { Orders } from "./orders";

defineProps<{ state: Orders }>();
</script>

<template>
  <p v-if="state.status === 'loading'" class="muted"><span class="spinner" />جارٍ تحميل طلباتك…</p>
  <p v-else-if="state.status === 'error'" class="error">
    تعذّر تحميل طلباتك: {{ state.message }}
    <button type="button" class="secondary">حاول مرة أخرى</button>
  </p>
  <p v-else-if="state.orders.length === 0" class="muted">ليست لديك طلبات بعد.</p>
  <ul v-else>
    <li v-for="order in state.orders" :key="order">{{ order }}</li>
  </ul>
</template>
