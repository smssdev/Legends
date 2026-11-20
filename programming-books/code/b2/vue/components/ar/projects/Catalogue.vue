<script setup lang="ts">
import { computed, ref } from "vue";
import { products, type Product } from "../products";

type Filter = "all" | Product["category"];

const FILTERS: { value: Filter; label: string }[] = [
  { value: "all", label: "الكل" },
  { value: "books", label: "كتب" },
  { value: "gifts", label: "هدايا" },
];

const filter = ref<Filter>("all");
const visible = computed(() => (filter.value === "all" ? products : products.filter((p) => p.category === filter.value)));
</script>

<template>
  <section>
    <h2>الكتالوج</h2>
    <div class="filters" role="group" aria-label="الكتالوج">
      <button
        v-for="f in FILTERS"
        :key="f.value"
        type="button"
        :class="{ secondary: f.value !== filter }"
        :aria-pressed="f.value === filter"
        @click="filter = f.value"
      >
        {{ f.label }}
      </button>
    </div>
    <p class="count">يظهر {{ visible.length }} من {{ products.length }} منتجات</p>
    <div class="grid">
      <article v-for="product in visible" :key="product.id" class="card">
        <span v-if="product.isNew" class="badge">جديد</span>
        <h3>{{ product.name }}</h3>
        <p class="price">{{ product.price.toFixed(2) }} جنيهاً</p>
      </article>
    </div>
  </section>
</template>
