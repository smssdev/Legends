<script setup lang="ts">
import { ref, useId, useTemplateRef } from "vue";

const props = defineProps<{ labels: string[]; label: string }>();
const active = ref(0);
const id = useId();
const buttons = useTemplateRef<HTMLButtonElement[]>("tab");

function select(index: number) {
  const next = (index + props.labels.length) % props.labels.length;
  active.value = next;
  buttons.value?.[next]?.focus();
}

function onKeydown(event: KeyboardEvent) {
  const rtl = document.dir === "rtl";
  if (event.key === "ArrowRight") select(active.value + (rtl ? -1 : 1));
  if (event.key === "ArrowLeft") select(active.value + (rtl ? 1 : -1));
  if (event.key === "Home") select(0);
  if (event.key === "End") select(props.labels.length - 1);
}
</script>

<template>
  <div class="tabs">
    <div role="tablist" :aria-label="label" @keydown="onKeydown">
      <button
        v-for="(text, i) in labels"
        :id="`${id}-tab-${i}`"
        ref="tab"
        :key="text"
        type="button"
        role="tab"
        :aria-selected="i === active"
        :aria-controls="`${id}-panel-${i}`"
        :tabindex="i === active ? 0 : -1"
        @click="select(i)"
      >
        {{ text }}
      </button>
    </div>
    <div
      v-for="(text, i) in labels"
      :id="`${id}-panel-${i}`"
      :key="text"
      role="tabpanel"
      :aria-labelledby="`${id}-tab-${i}`"
      :hidden="i !== active"
    >
      <slot :name="`tab-${i}`" />
    </div>
  </div>
</template>
