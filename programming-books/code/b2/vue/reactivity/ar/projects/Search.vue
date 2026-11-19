<script setup lang="ts">
import { onWatcherCleanup, ref, watch } from "vue";
import { searchProducts } from "../fake-api";
import type { Product } from "../cart-model";

const query = ref("");
const results = ref<Product[]>([]);
const loading = ref(false);

watch(query, async (q) => {
  if (!q.trim()) {
    results.value = [];
    return;
  }
  // إن كتب المستخدم من جديد، فألغِ الطلب القديم
  const controller = new AbortController();
  onWatcherCleanup(() => controller.abort());
  loading.value = true;
  try {
    results.value = await searchProducts(q, controller.signal);
    loading.value = false;
  } catch {
    // aborted: a newer search is already running
  }
});
</script>

<template>
  <label for="q">ابحث في المنتجات</label>
  <input id="q" v-model="query" type="search" autocomplete="off" />
  <p v-if="loading" class="muted" role="status">جارٍ البحث عن “{{ query }}”…</p>
  <template v-else-if="query">
    <p role="status">{{ results.length }} نتائج</p>
    <ul>
      <li v-for="p in results" :key="p.id">{{ p.name }}</li>
    </ul>
  </template>
</template>
