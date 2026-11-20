<script setup lang="ts">
import MenuButton from "./MenuButton.vue";

const noop = () => {};
</script>

<template>
  <div class="card">
    <MenuButton
      label="إجراءات الطلب #1042"
      :items="[
        { label: 'تتبّع', onSelect: noop },
        { label: 'نزّل الفاتورة', onSelect: noop },
        { label: 'أرجع منتجات', onSelect: noop },
        { label: 'ألغِ الطلب', danger: true, onSelect: noop },
      ]"
    />
  </div>
</template>
