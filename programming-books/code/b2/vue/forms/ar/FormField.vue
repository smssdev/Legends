<script setup lang="ts">
defineProps<{ id: string; label: string; error?: string | undefined }>();
</script>

<template>
  <div class="field">
    <label :for="id">{{ label }}</label>
    <!-- تستلم الفتحة السمات التي تربط الحقل بعنوانه وخطئه -->
    <slot :id="id" :aria-invalid="!!error" :aria-describedby="error ? `${id}-error` : undefined" />
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>
