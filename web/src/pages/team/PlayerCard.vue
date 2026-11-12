<script setup lang="ts">
// A player's card (Sprint 16 W1), after the draft MobilePlayer: rating and line, the attributes with bars,
// fitness, room to grow and value. [Sprint 20 W9] A sheet from the bottom on the phone, a panel from the side on the
// computer, so the list behind stays where it was; and its actions: train him, or sell him. [Sprint 39 S1] Selling is
// right here (the market's own panel, market/SellPanel.vue), without going to the market; buying stays in the market.
import UiButton from '../../components/ui/UiButton.vue'
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import SellPanel from './market/SellPanel.vue'
import { act, busy as isBusy } from '../../lib/action'
import { useToast } from '../../stores/toast'
import { t } from '../../lib/i18n'
import { nm } from '../../lib/names'
import Icon from '../../components/Icon.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import UiChip from '../../components/ui/UiChip.vue'
import { fitnessTone, money, type Line } from '../../lib/format'
import { ATTRIBUTES, barColor, type SquadPlayer } from './team'

const props = defineProps<{ player: SquadPlayer; sell?: boolean }>()
const emit = defineEmits<{ close: []; sold: [notice: string] }>()

// The sale's terms for this player (the market's `mine`), asked when the coach opens the panel.
const selling = ref<{ league: number; mine: components['schemas']['Market']['mine'][number] } | null>(null)
const sellError = ref('')
const loadingSale = ref(false)
async function openSale() {
  if (selling.value) return (selling.value = null)
  sellError.value = ''
  loadingSale.value = true
  try {
    const league = await currentLeague()
    // source=pool answers Market (source=list answers TransferList).
    const market = league ? ((await api.GET('/leagues/{league}/market', { params: { path: { league }, query: { source: 'pool', line: 'gk' } as any } })).data as components['schemas']['Market'] | undefined) : null
    const mine = market?.mine.find((m) => m.id === props.player.id)
    if (!league || !market) sellError.value = 'لا دوري لك الآن.'
    else if (market.closed) sellError.value = market.closed
    else if (!mine) sellError.value = 'لا يمكن بيع هذا اللاعب الآن.'
    else selling.value = { league, mine }
  } catch (e) {
    sellError.value = asApiError(e).message
  }
  loadingSale.value = false
}
// [X88] Training him from his card: the line's slot is his now; the one he replaced keeps his progress, and «تراجع»
// brings him back.
async function trainNow() {
  const league = await currentLeague()
  if (!league) return
  const view = (await api.GET('/leagues/{league}/training', { params: { path: { league } } }).catch(() => ({ data: undefined }))).data
  const before = view?.slots.find((s) => s.line === props.player.line)?.player?.id
  if (before === props.player.id) return useToast().show(t('{v0} يتدرب الآن.', { v0: nm(props.player.name) }))
  await act(`train-card:${props.player.id}`, () => api.POST('/leagues/{league}/training', { params: { path: { league } }, body: { player_id: props.player.id, replace: true } }), {
    success: t('بدأ {v0} التدريب في خانة خطه.', { v0: nm(props.player.name) }),
    undo: () => (before ? api.POST('/leagues/{league}/training', { params: { path: { league } }, body: { player_id: before, replace: true } })
      : api.DELETE('/leagues/{league}/training/{line}', { params: { path: { league, line: props.player.line as never } } })),
  })
}

// [X84] Opened from the squad's «معروض للبيع» mark: straight to withdraw or keep.
onMounted(() => { if (props.sell) void openSale() })
const ROLE = { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' } as const
</script>

<template>
  <!-- [Sprint 56 W2] A side panel beside the squad's table (Squad.html), not a window over it. -->
  <UiDialog :open="true" side @close="$emit('close')">
    <section class="flex flex-col gap-4" :aria-label="player.name">
      <header class="flex items-center justify-between gap-3">
        <h2 class="font-display text-2xl font-extrabold">{{ $t('بطاقة اللاعب') }}</h2>
        <div class="flex items-center gap-2">
          <UiChip :tone="player.role === 'starter' ? 'win' : 'neutral'">{{ $t(ROLE[player.role]) }}</UiChip>
          <button type="button" class="flex size-touch items-center justify-center rounded-lg bg-surface" :aria-label="$t('إغلاق')" @click="$emit('close')"><Icon name="close" /></button>
        </div>
      </header>

      <div class="flex flex-col gap-4 rounded-xl border border-gold/30 ui-card p-4">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="font-display text-2xl font-extrabold">{{ $nm(player.name) }}</p>
            <p class="text-sm text-text-muted">
              {{ player.position }}<template v-if="player.alt_positions"> ({{ player.alt_positions }})</template><template v-if="player.nationality"> · {{ $nm(player.nationality) }}</template>
            </p>
            <p class="text-sm text-text-muted"><span class="font-numbers">{{ player.age }}</span> {{ $t('سنة') }}<template v-if="player.foot"> {{ $t('· القدم {v0}', { v0: player.foot === 'Left' ? $t('اليسرى') : $t('اليمنى') }) }}</template></p>
          </div>
          <div class="flex flex-col items-center gap-1">
            <span class="font-numbers text-5xl font-bold text-gold">{{ player.overall }}</span>
            <LineBadge :line="player.line as Line" />
          </div>
        </div>
        <dl class="grid grid-cols-2 gap-x-4 gap-y-3">
          <div v-for="(v, k) in player.attributes" :key="k">
            <dt class="flex justify-between text-sm"><span>{{ $t(ATTRIBUTES[k]) }}</span><span class="font-numbers text-base">{{ v ?? '—' }}</span></dt>
            <dd class="mt-1 h-1.5 rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="barColor(v ?? 0)" :style="{ width: `${v ?? 0}%` }" /></dd>
          </div>
        </dl>
      </div>

      <dl class="grid grid-cols-3 gap-2 text-center">
        <div class="rounded-xl ui-card p-3"><dt class="text-sm text-text-muted">{{ $t('اللياقة') }}</dt><dd class="font-numbers text-2xl" :class="fitnessTone(player.fitness, 'text')">{{ player.fitness }}%</dd></div>
        <div class="rounded-xl ui-card p-3"><dt class="text-sm text-text-muted">{{ $t('سقف التطور') }}</dt><dd class="font-numbers text-2xl">{{ player.potential }}</dd></div>
        <div class="rounded-xl ui-card p-3"><dt class="text-sm text-text-muted">{{ $t('القيمة') }}</dt><dd class="font-numbers text-2xl">{{ money(player.value) }}</dd></div>
      </dl>
      <p v-if="!player.available" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger">
        {{ player.injured_matches ? $t('مصاب: يغيب {v0} مباريات', { v0: player.injured_matches }) : $t('موقوف: {v0} مباريات', { v0: player.suspended_matches }) }}
      </p>
      <!-- Selling one's own players [X6]: at once, at his value, or at my price up to his cap, here on the card [Sprint 39 S1]. -->
      <div class="grid grid-cols-2 gap-2">
        <!-- [X88] Trained from here: in his line's slot at once (in place of whoever was there, «تراجع» puts him back). -->
        <UiButton :disabled="isBusy(`train-card:${player.id}`)" @click="trainNow">
          {{ isBusy(`train-card:${player.id}`) ? '...' : $t('درّبه الآن') }}</UiButton>
        <button type="button" class="flex h-12 items-center justify-center rounded-lg font-bold disabled:opacity-40" :class="player.listed ? 'bg-gold/15 text-gold' : 'border border-warning/60 text-warning'" :aria-expanded="!!selling" :disabled="loadingSale" @click="openSale">{{ loadingSale ? '...' : player.listed ? $t('معروض للبيع ✓') : $t('بيع اللاعب') }}</button>
      </div>
      <p v-if="sellError" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger" role="alert">{{ $t(sellError) }}</p>
      <SellPanel v-if="selling" :league-id="selling.league" :player="selling.mine" @done="(n: string) => emit('sold', n)" @error="(e: string) => (sellError = e)" @keep="selling = null" />
    </section>
  </UiDialog>
</template>
