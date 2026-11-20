<script setup lang="ts">
import { useTemplateRef, watchEffect } from "vue";

const open = defineModel<boolean>({ required: true });
defineProps<{ title: string; confirmLabel: string; cancelLabel: string }>();
const emit = defineEmits<{ confirm: [] }>();
const dialog = useTemplateRef<HTMLDialogElement>("dialog");

watchEffect(() => {
  const el = dialog.value;
  if (!el) return;
  if (open.value && !el.open) el.showModal(); // modal: traps focus, Esc closes, the page behind is inert
  if (!open.value && el.open) el.close(); // the browser returns the focus to the button that opened it
});
</script>

<template>
  <dialog ref="dialog" aria-labelledby="dlg-title" aria-describedby="dlg-text" @close="open = false">
    <h2 id="dlg-title">{{ title }}</h2>
    <p id="dlg-text"><slot /></p>
    <div class="row">
      <button type="button" class="secondary" autofocus @click="open = false">{{ cancelLabel }}</button>
      <button type="button" class="danger" @click="emit('confirm'), (open = false)">{{ confirmLabel }}</button>
    </div>
  </dialog>
</template>
