<script setup lang="ts">
// defineModel: خاصية وحدث في مرجع واحد، من أجل v-model
const quantity = defineModel<number>({ required: true });
const props = defineProps<{ max: number; label: string }>();
</script>

<template>
  <div class="quantity" role="group" :aria-label="label">
    <button type="button" class="secondary" :disabled="quantity <= 1" aria-label="−1" @click="quantity--">−</button>
    <output>{{ quantity }}</output>
    <button type="button" class="secondary" :disabled="quantity >= props.max" aria-label="+1" @click="quantity++">+</button>
  </div>
</template>
