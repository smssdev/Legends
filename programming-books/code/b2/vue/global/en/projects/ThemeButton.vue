<script setup lang="ts">
import { useTheme } from "./theme";

const { dark, toggle } = useTheme();
</script>

<template>
  <button type="button" :aria-pressed="dark" @click="toggle">Dark theme</button>
</template>
