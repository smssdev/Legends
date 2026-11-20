<script setup lang="ts">
// Sets <html lang dir> and the title of every page, on the server and in the browser
useHead({
  htmlAttrs: { lang: "en", dir: "ltr" },
  titleTemplate: (title) => (title ? `${title} · Bit's shop` : "Bit's shop"),
});
</script>

<template>
  <NuxtLoadingIndicator />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
