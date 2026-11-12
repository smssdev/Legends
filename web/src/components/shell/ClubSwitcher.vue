<script setup lang="ts">
// [Sprint 20 W2] The club on the top bar: a tap lists my teams (place, and what waits in each) to move between them in
// two taps from any screen, and «فرقي كلها» to the home screen.
// [X61] A menu: the keyboard, Esc and the tap outside are its own; the list drops from the top bar.
// [Sprint 54 W4] On reka-ui's DropdownMenu (Headless UI is gone).
// [Sprint 55 W1] It heads the dock now: the crest alone on the narrow dock, the name and the place beside it on the
// computer's wide one (.shell-dock-wide), and its list opens beside the dock.
import { DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuPortal, DropdownMenuRoot, DropdownMenuTrigger } from 'reka-ui'
import { computed } from 'vue'
import { dockSide } from './dockSide'
import { useRouter } from 'vue-router'
import Icon from '../Icon.vue'
import { rememberLeague } from '../../lib/currentLeague'
import { useSlot } from '../../stores/slot'

defineProps<{ inBar?: boolean }>()
const slot = useSlot()
const router = useRouter()
const clubs = computed(() => slot.slots.filter((s) => s.state === 'club'))
function pick(leagueId: number) {
  rememberLeague(leagueId)
  slot.pick()
  router.push('/club')
}
</script>

<template>
  <DropdownMenuRoot :modal="false">
    <DropdownMenuTrigger v-if="slot.current?.club" class="dock-crest" :aria-label="$t('بدّل النادي: {name}', { name: slot.current.club.name })">
      <AppImage :src="slot.current.club.crest_url" alt="" class="size-9 shrink-0 drop-shadow" :size="36" crest eager />
      <span class="dock-wide-only min-w-0 flex-1 text-start leading-tight">
        <b class="block truncate text-body">{{ $nm(slot.current.club.name) }}</b>
        <span v-if="slot.current.position" class="block truncate text-caption text-text-muted">{{ $t('المركز {v0} من {v1}', { v0: slot.current.position, v1: slot.current.teams }) }}</span>
      </span>
    </DropdownMenuTrigger>
    <span v-else class="dock-crest animate-pulse" aria-hidden="true"><span class="size-9 rounded-full bg-surface-raised" /></span>
    <DropdownMenuPortal>
      <DropdownMenuContent :side="inBar ? 'bottom' : dockSide" align="start" :side-offset="8" class="drop-panel z-50 flex max-h-[70vh] w-72 max-w-[calc(100vw-1.5rem)] flex-col gap-1.5 overflow-y-auto overscroll-contain rounded-xl border border-text/10 bg-surface p-2 shadow-overlay focus:outline-none">
        <DropdownMenuLabel class="px-2 text-xs text-text-muted">{{ $t('فرقي') }}</DropdownMenuLabel>
        <DropdownMenuItem v-for="s in clubs" :key="s.slot" class="flex min-h-touch cursor-pointer items-center gap-2 rounded-lg bg-surface-sunk px-2 py-1.5 text-start outline-none data-[highlighted]:bg-surface-raised" @select="pick(s.league!.id)">
          <AppImage :src="s.club!.crest_url" alt="" class="size-8 shrink-0" :size="32" crest eager />
          <span class="min-w-0 flex-1"><b class="block truncate text-sm">{{ $nm(s.club!.name) }}</b>
            <span class="block truncate text-xs text-text-muted">{{ $nm(s.league!.name) }}<template v-if="s.position"> · {{ $t('المركز {v0}', { v0: s.position }) }}</template></span></span>
          <span v-if="s.league!.id === slot.current?.league?.id" class="text-gold" aria-hidden="true">✓</span>
          <span v-else-if="s.pending" class="min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-xs text-white">{{ s.pending }}</span>
        </DropdownMenuItem>
        <DropdownMenuItem as-child>
          <RouterLink to="/" class="flex min-h-touch items-center gap-2 rounded-lg px-2 text-sm font-bold text-brand-light outline-none data-[highlighted]:bg-surface-raised"><Icon name="home" :size="18" />{{ $t('فرقي كلها') }}</RouterLink>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenuPortal>
  </DropdownMenuRoot>
</template>
