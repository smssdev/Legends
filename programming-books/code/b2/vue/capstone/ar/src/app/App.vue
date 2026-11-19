<script setup lang="ts">
import { watchEffect } from "vue";
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const settings = useSettings();
const { t, lang, dark } = storeToRefs(settings);

watchEffect(() => {
  const html = document.documentElement;
  html.lang = lang.value;
  html.dir = lang.value === "ar" ? "rtl" : "ltr";
  html.classList.toggle("dark", dark.value);
});
</script>

<template>
  <div class="app">
    <a class="skip" href="#main">{{ t("skip") }}</a>
    <nav class="side" :aria-label="t('brand')">
      <span class="brand">{{ t("brand") }}</span>
      <RouterLink to="/" exact-active-class="active" active-class="">{{ t("overview") }}</RouterLink>
      <RouterLink to="/orders" active-class="active">{{ t("orders") }}</RouterLink>
      <RouterLink to="/products" active-class="active">{{ t("products") }}</RouterLink>
    </nav>
    <div>
      <header class="top">
        <button type="button" class="secondary" :lang="lang === 'en' ? 'ar' : 'en'" @click="settings.toggleLanguage()">
          {{ t("switchLanguage") }}
        </button>
        <button type="button" class="secondary" :aria-pressed="dark" @click="settings.toggleDark()">{{ t("dark") }}</button>
      </header>
      <main id="main"><RouterView /></main>
    </div>
  </div>
</template>
