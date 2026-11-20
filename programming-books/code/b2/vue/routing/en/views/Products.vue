<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@tanstack/vue-query";
import { getProducts } from "../api";
import Skeleton from "./Skeleton.vue";

const CATEGORIES = [
  { value: null, label: "All" },
  { value: "books", label: "Books" },
  { value: "gifts", label: "Gifts" },
];

const route = useRoute();
const category = computed(() => (typeof route.query.category === "string" ? route.query.category : null));

// The key names the data: a computed category in it refetches when the address changes
const query = useQuery({
  queryKey: ["products", category],
  queryFn: () => getProducts(category.value),
});
</script>

<template>
  <section class="card">
    <div class="filters">
      <RouterLink
        v-for="c in CATEGORIES"
        :key="c.label"
        :to="{ query: c.value ? { category: c.value } : {} }"
        :class="{ on: c.value === category }"
      >
        {{ c.label }}
      </RouterLink>
    </div>
    <Skeleton v-if="query.isPending.value" />
    <p v-else-if="query.isError.value" class="error">Something went wrong: {{ query.error.value?.message }}</p>
    <ul v-else class="list">
      <li v-for="p in query.data.value" :key="p.id">
        <RouterLink :to="`/products/${p.id}`">{{ p.name }}</RouterLink>
        <span class="price">{{ p.price }} EGP</span>
      </li>
    </ul>
  </section>
</template>
