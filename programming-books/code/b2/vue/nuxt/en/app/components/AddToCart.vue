<script setup lang="ts">
// Drawn on the server, then hydrated in the browser, where it reacts to clicks
defineProps<{ name: string }>();
const added = ref(false);
</script>

<template>
  <button type="button" :class="{ secondary: added }" :aria-pressed="added" :aria-label="`Add to cart: ${name}`" @click="added = !added">
    {{ added ? "✓ In your cart" : "Add to cart" }}
  </button>
</template>
