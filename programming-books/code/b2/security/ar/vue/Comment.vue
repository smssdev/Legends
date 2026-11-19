<script setup lang="ts">
const comment = `<img src="x" onerror="alert('hacked')">`;

// URLs from users can run code too: Vue does not block them, so checking the scheme is your job
const link = "javascript:alert('hacked')";
const safe = /^https?:\/\//.test(link) ? link : "#";
</script>

<template>
  <!-- Text in double braces is escaped: it is shown, never run -->
  <p>{{ comment }}</p>
  <!-- v-html puts raw HTML into the page -->
  <p v-html="comment" />
  <a :href="safe">الملف الشخصي</a>
</template>
