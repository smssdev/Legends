<script setup lang="ts">
import OrderList from "./OrderList.vue";
import type { Orders } from "./orders";

const examples: Orders[] = [
  { status: "loading" },
  { status: "error", message: "you are offline" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · Code from Zero", "#1043 · Bit mug"] },
];
</script>

<template>
  <div v-for="(state, i) in examples" :key="i" class="panel">
    <OrderList :state="state" />
  </div>
</template>
