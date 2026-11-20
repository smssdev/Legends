<script setup lang="ts">
import LikeButton from "./LikeButton.vue";
</script>

<template>
  <p style="display: flex; gap: 8px">
    <LikeButton :initial="41" />
    <LikeButton :initial="7" />
  </p>
</template>
