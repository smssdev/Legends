<script setup lang="ts">
// [Sprint 67] The game's bots and channels on Telegram and WhatsApp, a link each, wherever the site shows them (the
// public footer). Nothing shows for a bot or channel that is off on the server.
import { onMounted, ref } from 'vue'
import Icon from './Icon.vue'
import { siteConfig } from '../lib/session'
import { openBot, type BotPlatform } from '../lib/bots'
import { useAuth } from '../stores/auth'

const bots = ref<{
  telegram: string | null
  whatsapp: string | null
  telegram_channel: string | null
  whatsapp_channel: string | null
} | null>(null)
const auth = useAuth()
onMounted(async () => {
  try {
    bots.value = (await siteConfig())?.bots ?? null
  } catch {}
})
const BOTS: [BotPlatform, string][] = [
  ['telegram', 'بوت اللعبة على تيليجرام'],
  ['whatsapp', 'بوت اللعبة على واتساب'],
]
</script>

<template>
  <div v-if="bots && (bots.telegram || bots.whatsapp || bots.telegram_channel || bots.whatsapp_channel)" class="flex flex-col gap-1">
    <p class="text-xs text-text-muted">{{ $t('اسأل بوت اللعبة، وتابع قنواتنا:') }}</p>
    <template v-for="[p, label] in BOTS" :key="p">
      <a
        v-if="bots[p]"
        :href="bots[p]!"
        target="_blank"
        rel="noopener"
        class="foot-link w-fit gap-2 text-sm"
        @click.prevent="openBot(p, bots[p]!, auth.signedIn)"
      >
        <Icon name="bot" :size="18" />{{ $t(label) }}
      </a>
    </template>
    <a v-if="bots.telegram_channel" :href="bots.telegram_channel" target="_blank" rel="noopener" class="foot-link w-fit gap-2 text-sm">
      <Icon name="megaphone" :size="18" />{{ $t('قناة تيليجرام') }}
    </a>
    <a v-if="bots.whatsapp_channel" :href="bots.whatsapp_channel" target="_blank" rel="noopener" class="foot-link w-fit gap-2 text-sm">
      <Icon name="megaphone" :size="18" />{{ $t('قناة واتساب') }}
    </a>
  </div>
</template>
