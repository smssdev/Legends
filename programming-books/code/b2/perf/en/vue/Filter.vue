<script setup lang="ts">
import { computed, ref, shallowRef } from "vue";
import { refDebounced } from "@vueuse/core";
import SlowList from "./SlowList.vue";

// shallowRef: Vue does not need to watch inside 5,000 strings that never change
const ALL = shallowRef(Array.from({ length: 5000 }, (_, i) => `Bit item ${i + 1}`));

const text = ref("");
// Keep the typing urgent; the big list update can wait
const deferred = refDebounced(text, 250);
const items = computed(() => ALL.value.filter((name) => name.includes(deferred.value)));
const stale = computed(() => text.value !== deferred.value);
</script>

<template>
  <div class="card">
    <label for="q">Filter products</label>
    <input id="q" v-model="text" />
    <p class="muted" aria-live="polite">{{ stale ? "Updating…" : `Showing ${items.length} of ${ALL.length}` }}</p>
    <div :class="{ stale }">
      <SlowList :items="items" />
    </div>
  </div>
</template>
