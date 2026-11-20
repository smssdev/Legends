<script setup lang="ts">
import { useToasts } from "./toasts";

const store = useToasts();
</script>

<template>
  <Teleport to="body">
    <ul class="toasts" role="status" aria-live="polite" aria-label="Notifications">
      <li v-for="t in store.toasts" :key="t.id" class="toast">
        <span>{{ t.text }}</span>
        <button
          v-if="t.action"
          type="button"
          class="secondary"
          @click="t.action.run(), store.dismiss(t.id)"
        >
          {{ t.action.label }}
        </button>
        <button type="button" aria-label="Close" @click="store.dismiss(t.id)">×</button>
      </li>
    </ul>
  </Teleport>
</template>
