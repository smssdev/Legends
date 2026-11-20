<script setup lang="ts">
import { nextTick, ref, useId, useTemplateRef, watch } from "vue";

type Item = { label: string; danger?: boolean; onSelect: () => void };
const props = defineProps<{ label: string; items: Item[] }>();

const open = ref(false);
const active = ref(0);
const id = useId();
const button = useTemplateRef<HTMLButtonElement>("button");
const itemEls = useTemplateRef<HTMLButtonElement[]>("item");

// Move the real focus to the active item whenever it changes
watch([open, active], async () => {
  await nextTick();
  if (open.value) itemEls.value?.[active.value]?.focus();
});

function openAt(index: number) {
  active.value = index;
  open.value = true;
}

function close() {
  open.value = false;
  button.value?.focus(); // focus goes back where it came from
}

function onMenuKey(event: KeyboardEvent) {
  const last = props.items.length - 1;
  if (event.key === "ArrowDown") active.value = active.value === last ? 0 : active.value + 1;
  else if (event.key === "ArrowUp") active.value = active.value === 0 ? last : active.value - 1;
  else if (event.key === "Home") active.value = 0;
  else if (event.key === "End") active.value = last;
  else if (event.key === "Escape" || event.key === "Tab") close();
  else return;
  event.preventDefault();
}
</script>

<template>
  <div class="menu-wrap">
    <button
      :id="`${id}-button`"
      ref="button"
      type="button"
      aria-haspopup="menu"
      :aria-expanded="open"
      :aria-controls="`${id}-menu`"
      @click="open ? close() : openAt(0)"
      @keydown.down.prevent="openAt(0)"
      @keydown.up.prevent="openAt(items.length - 1)"
    >
      {{ label }} ▾
    </button>
    <ul v-if="open" :id="`${id}-menu`" role="menu" :aria-labelledby="`${id}-button`" @keydown="onMenuKey">
      <li v-for="item in items" :key="item.label" role="none">
        <button
          ref="item"
          type="button"
          role="menuitem"
          tabindex="-1"
          :class="{ 'danger-text': item.danger }"
          @click="item.onSelect(), close()"
        >
          {{ item.label }}
        </button>
      </li>
    </ul>
  </div>
</template>
