<script setup lang="ts">
// [Sprint 20 W2] The club on the top bar: a tap lists my teams (place, and what waits in each) to move between them in
// two taps from any screen, and «فرقي كلها» to the home screen.
// [X61] Headless UI's Menu: the keyboard, Esc and the tap outside are its own; the list drops from the top bar.
import { Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '../Icon.vue'
import { rememberLeague } from '../../lib/currentLeague'
import { useSlot } from '../../stores/slot'

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
  <Menu as="div" class="relative min-w-[7rem] flex-1 md:w-80 md:flex-none">
    <MenuButton v-if="slot.current?.club" class="chrome-tab chrome-start w-full" :aria-label="$t('بدّل النادي: {name}', { name: slot.current.club.name })">
      <img :src="slot.current.club.crest_url" alt="" class="size-9 shrink-0 drop-shadow md:size-11" />
      <span class="min-w-0 flex-1 text-start leading-tight">
        <b class="block truncate font-display text-base md:text-lg">{{ $nm(slot.current.club.name) }}</b>
        <span class="flex items-center gap-1.5 truncate text-xs font-semibold opacity-75">
          <span class="truncate">{{ $nm(slot.current.league?.name) }}</span>
          <span v-if="slot.current.position" class="shrink-0 rounded bg-brand px-1.5 font-numbers text-white" dir="ltr">{{ slot.current.position }}/{{ slot.current.teams }}</span>
        </span>
      </span>
      <span class="shrink-0 text-gold" aria-hidden="true">▾</span>
    </MenuButton>
    <span v-else class="chrome-tab chrome-start block w-full animate-pulse" aria-hidden="true" />
    <Transition name="drop">
      <MenuItems class="drop-panel absolute start-0 top-full z-50 mt-2 flex max-h-[70vh] w-72 max-w-[calc(100vw-1.5rem)] flex-col gap-1.5 overflow-y-auto overscroll-contain rounded-xl border border-text/10 bg-surface p-2 shadow-2xl focus:outline-none">
        <span class="px-2 text-xs text-text-muted">{{ $t('فرقي') }}</span>
        <MenuItem v-for="s in clubs" :key="s.slot" v-slot="{ active }">
          <button type="button" class="flex min-h-touch items-center gap-2 rounded-lg px-2 py-1.5 text-start" :class="active ? 'bg-surface-raised' : 'bg-surface-sunk'" @click="pick(s.league!.id)">
            <img :src="s.club!.crest_url" alt="" class="size-8 shrink-0" />
            <span class="min-w-0 flex-1"><b class="block truncate text-sm">{{ $nm(s.club!.name) }}</b>
              <span class="block truncate text-xs text-text-muted">{{ $nm(s.league!.name) }}<template v-if="s.position"> · {{ $t('المركز {v0}', { v0: s.position }) }}</template></span></span>
            <span v-if="s.league!.id === slot.current?.league?.id" class="text-gold" aria-hidden="true">✓</span>
            <span v-else-if="s.pending" class="min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-xs text-white">{{ s.pending }}</span>
          </button>
        </MenuItem>
        <MenuItem v-slot="{ active, close }">
          <RouterLink to="/" class="flex min-h-touch items-center gap-2 rounded-lg px-2 text-sm font-bold text-brand-light" :class="active ? 'bg-surface-raised' : ''" @click="close"><Icon name="home" :size="18" />{{ $t('فرقي كلها') }}</RouterLink>
        </MenuItem>
      </MenuItems>
    </Transition>
  </Menu>
</template>
