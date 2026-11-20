<script setup lang="ts">
// defineModel: a prop and an event in one ref, for v-model
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
