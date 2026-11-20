<script setup lang="ts">
import { announcement } from "./routeFocus";
</script>

<template>
  <nav class="card" style="display: flex; gap: 12px">
    <RouterLink to="/">الرئيسية</RouterLink>
    <RouterLink to="/orders">طلباتك</RouterLink>
  </nav>
  <main><RouterView /></main>
  <p role="status" class="sr-only">{{ announcement }}</p>
</template>
