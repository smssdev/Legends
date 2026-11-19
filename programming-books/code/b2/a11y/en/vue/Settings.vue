<script setup lang="ts">
import { ref } from "vue";
import ConfirmDialog from "./ConfirmDialog.vue";

const open = ref(false);
</script>

<template>
  <div class="card">
    <button type="button" class="danger" @click="open = true">Delete account…</button>
    <ConfirmDialog v-model="open" title="Delete your account?" confirm-label="Delete" cancel-label="Cancel">
      All your orders and saved lists will be removed. This cannot be undone.
    </ConfirmDialog>
  </div>
</template>
