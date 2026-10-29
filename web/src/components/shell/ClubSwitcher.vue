<script setup lang="ts">
// [Sprint 20 W2] The club on the top bar: a tap lists my teams (place, and what waits in each) to move between them in
// two taps from any screen, and «فرقي كلها» to the home screen.
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '../Icon.vue'
import { rememberLeague } from '../../lib/currentLeague'
import { useSlot } from '../../stores/slot'

const slot = useSlot()
const router = useRouter()
const open = ref(false)
const clubs = computed(() => slot.slots.filter((s) => s.state === 'club'))
function pick(leagueId: number) {
  open.value = false
  rememberLeague(leagueId)
  slot.pick()
  router.push('/club')
}
</script>

<template>
  <div class="relative min-w-[7rem] flex-1 md:w-80 md:flex-none">
    <button v-if="slot.current?.club" type="button" class="chrome-tab chrome-start w-full" :aria-expanded="open" aria-controls="club-switcher" :aria-label="$t('بدّل النادي: {name}', { name: slot.current.club.name })" @click="open = !open">
      <img :src="slot.current.club.crest_url" alt="" class="size-9 shrink-0 drop-shadow md:size-11" />
      <span class="min-w-0 flex-1 text-start leading-tight">
        <b class="block truncate font-display text-base md:text-lg">{{ $nm(slot.current.club.name) }}</b>
        <span class="flex items-center gap-1.5 truncate text-xs font-semibold opacity-75">
          <span class="truncate">{{ $nm(slot.current.league?.name) }}</span>
          <span v-if="slot.current.position" class="shrink-0 rounded bg-brand px-1.5 font-numbers text-white" dir="ltr">{{ slot.current.position }}/{{ slot.current.teams }}</span>
        </span>
      </span>
      <span class="shrink-0 text-gold" aria-hidden="true">▾</span>
    </button>
    <span v-else class="chrome-tab chrome-start block w-full animate-pulse" aria-hidden="true" />
    <template v-if="open">
      <div class="fixed inset-0 z-40" @click="open = false" />
      <div id="club-switcher" class="absolute start-0 top-full z-50 mt-2 flex w-72 max-w-[85vw] flex-col gap-1.5 rounded-xl border border-text/10 bg-surface p-2 shadow-2xl" role="menu" @keydown.esc="open = false">
        <span class="px-2 text-xs text-text-muted">{{ $t('فرقي') }}</span>
        <button v-for="s in clubs" :key="s.slot" type="button" role="menuitem" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-2 py-1.5 text-start hover:bg-surface-raised" @click="pick(s.league!.id)">
          <img :src="s.club!.crest_url" alt="" class="size-8 shrink-0" />
          <span class="min-w-0 flex-1"><b class="block truncate text-sm">{{ $nm(s.club!.name) }}</b>
            <span class="block truncate text-xs text-text-muted">{{ $nm(s.league!.name) }}<template v-if="s.position"> · {{ $t('المركز {v0}', { v0: s.position }) }}</template></span></span>
          <span v-if="s.league!.id === slot.current?.league?.id" class="text-gold" aria-hidden="true">✓</span>
          <span v-else-if="s.pending" class="min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-xs text-white">{{ s.pending }}</span>
        </button>
        <RouterLink to="/" class="flex min-h-touch items-center gap-2 rounded-lg px-2 text-sm font-bold text-brand-light hover:bg-surface-raised" @click="open = false"><Icon name="home" :size="18" />{{ $t('فرقي كلها') }}</RouterLink>
      </div>
    </template>
  </div>
</template>
