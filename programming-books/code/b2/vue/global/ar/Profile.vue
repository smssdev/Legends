<script setup lang="ts">
import { useAuth } from "./auth";

const { user } = useAuth();
</script>

<template>
  <section class="card">
    <h2>ملفك الشخصي</h2>
    <p class="muted">{{ user ? `${user.name} · عضو منذ 2025` : "زائر" }}</p>
  </section>
</template>
