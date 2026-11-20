<script setup lang="ts">
import type { NuxtError } from "#app";

defineProps<{ error: NuxtError }>();
</script>

<template>
  <NuxtLayout>
    <section class="card">
      <h1>{{ error.statusCode }}</h1>
      <p>{{ error.statusCode === 404 ? "لم نجد هذه الصفحة." : error.statusMessage }}</p>
      <button type="button" class="secondary" @click="clearError({ redirect: '/' })">الرئيسية</button>
    </section>
  </NuxtLayout>
</template>
