<script setup lang="ts">
import { useI18n } from "./i18n";

const LINES = [
  { name: "Code from Zero", price: 250 },
  { name: "Bit mug", price: 85 },
];
const { t, money, locale } = useI18n();
const total = LINES.reduce((sum, l) => sum + l.price, 0);
</script>

<template>
  <section class="card">
    <h2>
      {{ t("cart.title") }}
      <span class="badge">{{ t("cart.items", { count: LINES.length }) }}</span>
    </h2>
    <div v-for="l in LINES" :key="l.name" class="row">
      <bdi>{{ l.name }}</bdi>
      <span>{{ money(l.price) }}</span>
    </div>
    <p><b>{{ t("cart.total", { total: money(total) }) }}</b></p>
    <button type="button" class="next" @click="locale = locale === 'ar' ? 'en' : 'ar'">
      {{ locale === "ar" ? "English" : "العربية" }}
    </button>
  </section>
</template>
