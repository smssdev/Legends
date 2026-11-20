<script setup lang="ts">
import Button from "./Button.vue";
</script>

<template>
  <div class="gallery">
    <div class="row">
      <Button>أساسي</Button>
      <Button variant="secondary">ثانوي</Button>
      <Button variant="danger">خطر</Button>
      <Button variant="ghost">شفاف</Button>
    </div>
    <div class="row">
      <Button size="sm">صغير</Button>
      <Button size="lg">كبير</Button>
      <Button loading>جارٍ الحفظ…</Button>
      <Button disabled>ألغِ</Button>
    </div>
  </div>
</template>
