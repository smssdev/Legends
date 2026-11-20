<script setup lang="ts">
import OrderList from "./OrderList.vue";
import type { Orders } from "./orders";

const examples: Orders[] = [
  { status: "loading" },
  { status: "error", message: "أنت غير متصل" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · البرمجة من الصفر", "#1043 · كوب بِت"] },
];
</script>

<template>
  <div v-for="(state, i) in examples" :key="i" class="panel">
    <OrderList :state="state" />
  </div>
</template>
