<script setup lang="ts">
// Support by WhatsApp and Telegram [X13]: account and sign-up problems, and ideas. The links come from the server
// (/health), and a channel without a number or username has no button.
import { onMounted, ref } from 'vue'
import { api } from '../api/client'

defineProps<{ compact?: boolean }>()
const links = ref<{ whatsapp: string | null; telegram: string | null } | null>(null)
onMounted(async () => {
  try {
    links.value = (await api.GET('/health')).data?.support ?? null
  } catch {}
})
</script>

<template>
  <div v-if="links && (links.whatsapp || links.telegram)" class="flex flex-col gap-2">
    <p v-if="!compact" class="text-sm text-text-muted">مشكلة في حسابك أو التسجيل، أو عندك اقتراح؟ راسلنا مباشرة:</p>
    <div class="flex flex-wrap gap-2">
      <a v-if="links.whatsapp" :href="links.whatsapp" target="_blank" rel="noopener" class="flex h-touch items-center gap-2 rounded-md bg-[#25D366] px-4 font-bold text-[#0B2E13]">
        <svg viewBox="0 0 24 24" class="size-5" fill="currentColor" aria-hidden="true"><path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2a8.2 8.2 0 0 1-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8s-.4-.1-.6.1-.6.8-.8 1-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.8-1.4a.5.5 0 0 0 0-.5l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.3.8 3.2.6a2.7 2.7 0 0 0 1.8-1.3 2.2 2.2 0 0 0 .2-1.3c-.1-.1-.3-.2-.5-.3Z" /></svg>
        واتساب
      </a>
      <a v-if="links.telegram" :href="links.telegram" target="_blank" rel="noopener" class="flex h-touch items-center gap-2 rounded-md bg-[#229ED9] px-4 font-bold text-white">
        <svg viewBox="0 0 24 24" class="size-5" fill="currentColor" aria-hidden="true"><path d="M21.9 4.3 18.7 19.4c-.2 1-.9 1.3-1.7.8l-4.8-3.5-2.3 2.2c-.3.3-.5.5-1 .5l.3-4.9 8.9-8c.4-.3-.1-.5-.6-.2L6.5 13.2 1.8 11.7c-1-.3-1-1 .2-1.5L20.5 3c.9-.3 1.6.2 1.4 1.3Z" /></svg>
        تيليجرام
      </a>
    </div>
  </div>
</template>
