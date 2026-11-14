<script setup lang="ts">
// Google on the web goes through the server (Socialite): a full page visit, not a request.
defineProps<{ label: string }>()
</script>

<template>
  <a href="/auth/google/redirect" class="flex h-12 items-center justify-center gap-3 rounded-lg bg-white font-bold text-[#1f2937]">
    <svg width="20" height="20" viewBox="0 0 48 48" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M44.5 20H24v8.5h11.8C34.7 33.9 30.1 37 24 37c-7.2 0-13-5.8-13-13s5.8-13 13-13c3.1 0 5.9 1.1 8.1 2.9l6.4-6.4C34.6 4.1 29.6 2 24 2 11.8 2 2 11.8 2 24s9.8 22 22 22c11 0 21-8 21-22 0-1.3-.2-2.7-.5-4z"
      />
    </svg>
    {{ $t(label) }}
  </a>
</template>
