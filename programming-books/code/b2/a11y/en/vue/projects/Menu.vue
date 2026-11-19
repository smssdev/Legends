<script setup lang="ts">
import MenuButton from "./MenuButton.vue";

const noop = () => {};
</script>

<template>
  <div class="card">
    <MenuButton
      label="Actions for order #1042"
      :items="[
        { label: 'Track', onSelect: noop },
        { label: 'Download invoice', onSelect: noop },
        { label: 'Return items', onSelect: noop },
        { label: 'Cancel order', danger: true, onSelect: noop },
      ]"
    />
  </div>
</template>
