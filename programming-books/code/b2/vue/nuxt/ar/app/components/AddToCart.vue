<script setup lang="ts">
// يُرسم على الخادم، ثم يُحيا في المتصفح حيث يتفاعل مع الضغطات
defineProps<{ name: string }>();
const added = ref(false);
</script>

<template>
  <button type="button" :class="{ secondary: added }" :aria-pressed="added" :aria-label="`أضف إلى السلة: ${name}`" @click="added = !added">
    {{ added ? "✓ في سلتك" : "أضف إلى السلة" }}
  </button>
</template>
