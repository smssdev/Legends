<script setup lang="ts">
import Button from "./Button.vue";
</script>

<template>
  <div class="gallery">
    <div class="row">
      <Button>Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="danger">Danger</Button>
      <Button variant="ghost">Ghost</Button>
    </div>
    <div class="row">
      <Button size="sm">Small</Button>
      <Button size="lg">Large</Button>
      <Button loading>Saving…</Button>
      <Button disabled>Cancel</Button>
    </div>
  </div>
</template>
