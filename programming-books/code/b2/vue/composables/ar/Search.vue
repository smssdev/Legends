<script setup lang="ts">
import { ref } from "vue";
import { useDebounced } from "./composables/useDebounced";
import { useSearch } from "./composables/useSearch";

const query = ref("");
const { results, loading, error } = useSearch(useDebounced(query, 250));
</script>

<template>
  <label for="q">ابحث في المنتجات</label>
  <input id="q" v-model="query" type="search" autocomplete="off" />
  <p v-if="loading" role="status" class="muted">جارٍ البحث…</p>
  <p v-else-if="error" role="alert">تعذّر البحث: {{ error }}</p>
  <template v-else-if="query">
    <p role="status">{{ results.length }} نتائج</p>
    <ul>
      <li v-for="p in results" :key="p.id">{{ p.name }}</li>
    </ul>
  </template>
</template>
