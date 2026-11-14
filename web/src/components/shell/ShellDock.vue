<script setup lang="ts">
// [Sprint 55 W1] The frame's dock (docs/design/legends-ui/landscape/LandscapeShell.html, approved 2026-11-11): 72px at
// the line's start on a phone held sideways, 200px with the names beside the icons on the computer (option A). At its
// head the club (a tap switches clubs) or the game's emblem outside a club; then the six sections by their one name
// (nav.ts DOCK), «المزيد», and the Assistant Coach at its foot (W2, no button floating over the page). A section with
// several pages opens their list beside the dock; the arrows walk it, Esc and a tap outside close it.
import { DropdownMenuContent, DropdownMenuItem, DropdownMenuPortal, DropdownMenuRoot, DropdownMenuTrigger } from 'reka-ui'
import Icon, { type PATHS } from '../Icon.vue'
import BrandMark from '../BrandMark.vue'
import ClubSwitcher from './ClubSwitcher.vue'
import ShellMore, { type MoreGroup } from './ShellMore.vue'
import { dockSide } from './dockSide'
import { DOCK } from '../../layouts/dock.g'

// [Sprint 63 G4] Each section's icon on its own coloured tile (docs/design/nav.json), as the app's dock draws it.
const tile = (key: string) => DOCK.find((d) => d.key === key)

export interface DockLink {
  to: string
  label: string
  icon: keyof typeof PATHS
  active: boolean
}
export interface DockEntry {
  key: string
  label: string
  icon: keyof typeof PATHS
  links: DockLink[]
  active: boolean
  badge?: string | number | null
}

defineProps<{ entries: DockEntry[]; more: MoreGroup[]; inSlot: boolean; botOpen: boolean; botDot: boolean }>()
const emit = defineEmits<{ bot: [] }>()
</script>

<template>
  <nav class="shell-dock" :aria-label="inSlot ? $t('أقسام النادي') : $t('أقسام اللعبة')">
    <ClubSwitcher v-if="inSlot" />
    <RouterLink v-else to="/" class="dock-crest" :aria-label="$t('الرئيسية')"><BrandMark size="sm" class="dock-brand" /></RouterLink>

    <template v-for="e in entries" :key="e.key">
      <RouterLink
        v-if="e.links.length === 1"
        :to="e.links[0].to"
        class="dock-item"
        :class="e.active ? 'is-active' : ''"
        :aria-current="e.active ? 'page' : undefined"
      >
        <span
          v-if="tile(e.key)"
          class="dock-tile"
          :class="tile(e.key)!.ink === 'dark' ? 'ink-dark' : 'ink-light'"
          :style="{ background: `var(--color-${tile(e.key)!.color})` }"
          ><Icon :name="e.icon" :size="18" /></span
        ><Icon v-else :name="e.icon" :size="22" /><span class="dock-label">{{ $t(e.label) }}</span>
        <span v-if="e.badge" class="dock-badge">{{ e.badge }}</span>
      </RouterLink>
      <DropdownMenuRoot v-else :modal="false">
        <DropdownMenuTrigger class="dock-item" :class="e.active ? 'is-active' : ''">
          <span
            v-if="tile(e.key)"
            class="dock-tile"
            :class="tile(e.key)!.ink === 'dark' ? 'ink-dark' : 'ink-light'"
            :style="{ background: `var(--color-${tile(e.key)!.color})` }"
            ><Icon :name="e.icon" :size="18" /></span
          ><Icon v-else :name="e.icon" :size="22" /><span class="dock-label">{{ $t(e.label) }}</span>
          <span v-if="e.badge" class="dock-badge">{{ e.badge }}</span>
        </DropdownMenuTrigger>
        <DropdownMenuPortal>
          <DropdownMenuContent :side="dockSide" align="start" :side-offset="6" class="nav-panel drop-panel">
            <DropdownMenuItem v-for="l in e.links" :key="l.to" as-child>
              <RouterLink :to="l.to" class="nav-link" :class="l.active ? 'is-active' : ''" :aria-current="l.active ? 'page' : undefined"
                ><Icon :name="l.icon" :size="18" />{{ $t(l.label) }}</RouterLink
              >
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenuPortal>
      </DropdownMenuRoot>
    </template>

    <ShellMore :groups="more" />
    <span class="flex-1" />
    <button type="button" class="dock-item dock-bot" :aria-expanded="botOpen" :aria-label="$t('المدرب المساعد')" @click="emit('bot')">
      <Icon name="bot" :size="22" /><span class="dock-label">{{ $t('المساعد') }}</span>
      <span v-if="botDot" class="dock-badge dock-dot" aria-hidden="true" />
    </button>
  </nav>
</template>
