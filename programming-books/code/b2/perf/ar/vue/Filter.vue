<script setup lang="ts">
import { computed, ref, shallowRef } from "vue";
import { refDebounced } from "@vueuse/core";
import SlowList from "./SlowList.vue";

// shallowRef: Vue does not need to watch inside 5,000 strings that never change
const ALL = shallowRef(Array.from({ length: 5000 }, (_, i) => `منتج بِت ${i + 1}`));

const text = ref("");
// أبقِ الكتابة عاجلة، وتحديث القائمة الكبيرة يستطيع الانتظار
const deferred = refDebounced(text, 250);
const items = computed(() => ALL.value.filter((name) => name.includes(deferred.value)));
const stale = computed(() => text.value !== deferred.value);
</script>

<template>
  <div class="card">
    <label for="q">صفِّ المنتجات</label>
    <input id="q" v-model="text" />
    <p class="muted" aria-live="polite">{{ stale ? "جارٍ التحديث…" : `يظهر ${items.length} من ${ALL.length}` }}</p>
    <div :class="{ stale }">
      <SlowList :items="items" />
    </div>
  </div>
</template>
