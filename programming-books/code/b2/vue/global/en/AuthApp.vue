<script setup lang="ts">
import { provideAuth } from "./auth";
import Profile from "./Profile.vue";
import UserMenu from "./UserMenu.vue";

provideAuth();
</script>

<template>
  <header>
    <span class="brand">Bit's shop</span>
    <UserMenu />
  </header>
  <main>
    <Profile />
  </main>
</template>
