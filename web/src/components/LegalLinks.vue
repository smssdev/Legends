<script setup lang="ts">
// [X57] The privacy policy and the terms, linked from every way in (and the account), as Google AdSense asks.
</script>

<template>
  <nav class="flex flex-wrap items-center justify-center gap-x-4 text-xs text-text-muted" :aria-label="$t('الشروط والخصوصية')">
    <RouterLink to="/privacy" class="flex min-h-touch items-center underline-offset-2 hover:underline">{{
      $t('سياسة الخصوصية')
    }}</RouterLink>
    <RouterLink to="/terms" class="flex min-h-touch items-center underline-offset-2 hover:underline">{{
      $t('الشروط والأحكام')
    }}</RouterLink>
  </nav>
</template>
