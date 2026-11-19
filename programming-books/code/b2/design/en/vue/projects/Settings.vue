<script setup lang="ts">
import { ref } from "vue";
import Switch from "./Switch.vue";

const dark = ref(false);
</script>

<template>
  <div class="gallery" :data-theme="dark ? 'dark' : undefined">
    <Switch label="Email me about new books" />
    <Switch label="Wi-Fi" />
    <Switch v-model="dark" label="Dark theme" />
  </div>
</template>
