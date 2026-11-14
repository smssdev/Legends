<script setup lang="ts">
// [Sprint 55 W1] «المزيد» in the dock: what is not one of the six sections (the league's news, predictions and table
// inside a club; the community, the shop and the account for everyone; the admin's panel), in groups, beside the dock.
// The notification sound's switch lives here now (it was an icon on the top bar).
import {
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuPortal,
  DropdownMenuRoot,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from 'reka-ui'
import Icon, { type PATHS } from '../Icon.vue'
import { setTone, toneOn } from '../../lib/tone'
import { dockSide } from './dockSide'
import { onMounted, ref } from 'vue'
import { siteConfig } from '../../lib/session'
import { openBot, type BotPlatform } from '../../lib/bots'

// [Sprint 67] The game's bots, opened from here: the chat comes with the link code when the account is not linked yet.
const bots = ref<{ telegram: string | null; whatsapp: string | null } | null>(null)
onMounted(async () => {
  try {
    bots.value = (await siteConfig())?.bots ?? null
  } catch {}
})
const BOTS: [BotPlatform, string][] = [
  ['telegram', 'بوت اللعبة على تيليجرام'],
  ['whatsapp', 'بوت اللعبة على واتساب'],
]

export interface MoreGroup {
  label: string
  links: { to: string; label: string; icon: keyof typeof PATHS; active?: boolean }[]
}
defineProps<{ groups: MoreGroup[] }>()
</script>

<template>
  <DropdownMenuRoot :modal="false">
    <DropdownMenuTrigger class="dock-item" :aria-label="$t('المزيد')">
      <Icon name="more" :size="22" /><span class="dock-label">{{ $t('المزيد') }}</span>
    </DropdownMenuTrigger>
    <DropdownMenuPortal>
      <DropdownMenuContent
        :side="dockSide"
        align="end"
        :side-offset="6"
        :collision-padding="8"
        class="nav-panel drop-panel max-h-[calc(100dvh-1rem)] overflow-y-auto"
      >
        <template v-for="(g, i) in groups" :key="g.label">
          <DropdownMenuSeparator v-if="i" class="my-1 h-px bg-text/10" />
          <DropdownMenuLabel class="px-3 pt-1 text-caption text-text-muted">{{ $t(g.label) }}</DropdownMenuLabel>
          <DropdownMenuItem v-for="l in g.links" :key="l.to + l.label" as-child>
            <RouterLink :to="l.to" class="nav-link" :class="l.active ? 'is-active' : ''"
              ><Icon :name="l.icon" :size="18" />{{ $t(l.label) }}</RouterLink
            >
          </DropdownMenuItem>
        </template>
        <template v-if="bots && (bots.telegram || bots.whatsapp)">
          <DropdownMenuSeparator class="my-1 h-px bg-text/10" />
          <template v-for="[p, label] in BOTS" :key="p">
            <DropdownMenuItem v-if="bots[p]" class="nav-link cursor-pointer" @select="openBot(p, bots[p]!, true)">
              <Icon name="bot" :size="18" />{{ $t(label) }}
            </DropdownMenuItem>
          </template>
        </template>
        <DropdownMenuSeparator class="my-1 h-px bg-text/10" />
        <DropdownMenuItem class="nav-link cursor-pointer" @select.prevent="setTone(!toneOn)">
          <Icon :name="toneOn ? 'sound' : 'muted'" :size="18" />{{ toneOn ? $t('كتم صوت الإشعارات') : $t('تشغيل صوت الإشعارات') }}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenuPortal>
  </DropdownMenuRoot>
</template>
