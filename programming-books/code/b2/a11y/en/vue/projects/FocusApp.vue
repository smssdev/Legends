<script setup lang="ts">
import { announcement } from "./routeFocus";
</script>

<template>
  <nav class="card" style="display: flex; gap: 12px">
    <RouterLink to="/">Home</RouterLink>
    <RouterLink to="/orders">Your orders</RouterLink>
  </nav>
  <main><RouterView /></main>
  <p role="status" class="sr-only">{{ announcement }}</p>
</template>
