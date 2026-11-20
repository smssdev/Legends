<script setup lang="ts">
// يضبط <html lang dir> وعنوان كل صفحة، على الخادم وفي المتصفح
useHead({
  htmlAttrs: { lang: "ar", dir: "rtl" },
  titleTemplate: (title) => (title ? `${title} · متجر بِت` : "متجر بِت"),
});
</script>

<template>
  <NuxtLoadingIndicator />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
