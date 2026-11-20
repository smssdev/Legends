<script setup lang="ts">
import { ref } from "vue";
import ConfirmDialog from "./ConfirmDialog.vue";

const open = ref(false);
</script>

<template>
  <div class="card">
    <button type="button" class="danger" @click="open = true">احذف الحساب…</button>
    <ConfirmDialog v-model="open" title="أتحذف حسابك؟" confirm-label="احذف" cancel-label="ألغِ">
      ستُحذف كل طلباتك وقوائمك المحفوظة، ولا يمكن التراجع عن ذلك.
    </ConfirmDialog>
  </div>
</template>
