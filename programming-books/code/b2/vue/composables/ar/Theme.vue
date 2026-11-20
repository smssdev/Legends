<script setup lang="ts">
import { useLocalStorage } from "@vueuse/core";
import { watchEffect } from "vue";

// الفكرة نفسها من VueUse: محفوظ في localStorage ومتوافق بين الألسنة
const dark = useLocalStorage("dark", false);
watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
</script>

<template>
  <button type="button" :aria-pressed="dark" @click="dark = !dark">المظهر الداكن</button>
</template>
