<script setup lang="ts">
import { useLocalStorage } from "@vueuse/core";
import { watchEffect } from "vue";

// The same idea from VueUse: saved in localStorage, kept in step across tabs
const dark = useLocalStorage("dark", false);
watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
</script>

<template>
  <button type="button" :aria-pressed="dark" @click="dark = !dark">Dark theme</button>
</template>
