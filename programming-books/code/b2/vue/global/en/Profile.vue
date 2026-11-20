<script setup lang="ts">
import { useAuth } from "./auth";

const { user } = useAuth();
</script>

<template>
  <section class="card">
    <h2>Your profile</h2>
    <p class="muted">{{ user ? `${user.name} · Member since 2025` : "Guest" }}</p>
  </section>
</template>
