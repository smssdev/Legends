<script setup lang="ts">
import Profile from "../Profile.vue";
import { provideAuth } from "../auth";
import ThemeButton from "./ThemeButton.vue";
import { provideTheme } from "./theme";

provideAuth();
provideTheme();
</script>

<template>
  <header>
    <span class="brand">Bit's shop</span>
    <ThemeButton />
  </header>
  <Profile />
</template>
