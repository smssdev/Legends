<script setup lang="ts">
import { ref } from "vue";
import Switch from "./Switch.vue";

const dark = ref(false);
</script>

<template>
  <div class="gallery" :data-theme="dark ? 'dark' : undefined">
    <Switch label="راسلني عن الكتب الجديدة" />
    <Switch label="الواي فاي" />
    <Switch v-model="dark" label="المظهر الداكن" />
  </div>
</template>
