<script setup lang="ts">
import { computed, ref } from "vue";

const step = ref(1);
const history = ref<number[]>([0]);
const value = computed(() => history.value.at(-1) ?? 0);

function change(by: number) {
  history.value.push(value.value + by);
}

function undo() {
  if (history.value.length > 1) history.value.pop();
}
</script>

<template>
  <p class="value" aria-live="polite">{{ value }}</p>
  <div class="row">
    <button type="button" class="secondary" @click="change(-step)">−{{ step }}</button>
    <button type="button" @click="change(step)">+{{ step }}</button>
    <button type="button" class="secondary" :disabled="history.length === 1" @click="undo">تراجع</button>
  </div>
  <label>الخطوة <input id="step" v-model.number="step" type="number" min="1" max="10" /></label>
  <p class="muted">السجل: {{ history.join(" → ") }}</p>
</template>
