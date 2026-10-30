<script setup lang="ts">
// [Sprint 20 B5] The weekly quests (the owner's approved draft): five, renewed every Monday in Cairo, each with its
// bar and reward; a finished one is claimed once. The big one pays the club's money.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import Icon from '../../components/Icon.vue'
import { currentLeague } from '../../lib/currentLeague'
import { countdown, useNow } from '../../lib/clock'
import { money } from '../../lib/format'
import { useWallet } from '../../stores/wallet'

type View = components['schemas']['Quests']
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const message = ref('')
const busy = ref(false)
const loaded = ref(false)
const now = useNow()
const wallet = useWallet()
const path = computed(() => ({ params: { path: { league: leagueId.value! } } }))
const QUEST: Record<string, { title: string; icon: string }> = {
  friendly: { title: 'العب ودية', icon: 'friendly' },
  wins: { title: 'فز بمباراتين في الدوري', icon: 'match' },
  stadium: { title: 'أكمل جزءاً من الملعب', icon: 'stadium' },
  training: { title: 'أوصل لاعباً إلى +1 بالتدريب', icon: 'training' },
  unbeaten: { title: 'مهمة الأسبوع الكبرى: مباراتان على الأقل بلا خسارة', icon: 'quest' },
}
const coins = computed(() => (v.value?.quests ?? []).reduce((n, q) => n + (q.reward.coins ?? 0), 0))

onMounted(async () => {
  leagueId.value = await currentLeague()
  if (leagueId.value) v.value = (await api.GET('/leagues/{league}/quests', path.value)).data ?? null
  loaded.value = true
})
async function claim(quest: View['quests'][number]['quest']) {
  message.value = ''
  busy.value = true
  try {
    await ensureCsrf()
    v.value = (await api.POST('/leagues/{league}/quests/claim', { ...path.value, body: { quest } })).data ?? v.value
    wallet.load()
  } catch (e) {
    message.value = asApiError(e).message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-start gap-3">
      <div class="min-w-0 flex-1">
        <h1 class="font-display text-3xl font-extrabold">{{ $t('المهام الأسبوعية') }}</h1>
        <p v-if="v" class="text-sm text-text-muted">{{ $t('تتجدد بعد') }} <span class="font-numbers text-text-soft" dir="ltr">{{ countdown(v.renews_at, now) }}</span></p>
      </div>
      <span v-if="v" class="flex items-center gap-1 rounded-pill bg-gold px-3 py-1 text-sm font-bold text-on-gold"><img src="/brand/coin.svg" alt="" class="size-4" /><span class="font-numbers" dir="ltr">+{{ coins }}</span> {{ $t('كوينز') }}</span>
    </header>
    <p v-if="loaded && !leagueId" class="rounded-xl bg-surface p-6 text-center text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
    <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm text-warning" role="status">{{ $t(message) }}</p>
    <div v-if="!v && leagueId" class="flex flex-col gap-2" aria-hidden="true"><div v-for="n in 5" :key="n" class="h-20 animate-pulse rounded-xl bg-surface" /></div>
    <ul v-else-if="v" class="flex flex-col gap-2">
      <li v-for="q in v.quests" :key="q.quest" class="grid grid-cols-[2.5rem_minmax(0,1fr)_auto] items-center gap-3 rounded-xl bg-surface p-3" :class="q.quest === 'unbeaten' ? 'border border-gold/45' : ''">
        <span class="grid size-10 place-items-center rounded-lg bg-surface-raised" :class="q.claimed ? 'text-success' : q.quest === 'unbeaten' ? 'text-gold' : ''"><Icon :name="(q.claimed ? 'todo' : QUEST[q.quest].icon) as never" :size="20" /></span>
        <span class="min-w-0">
          <b class="block text-sm">{{ $t(QUEST[q.quest].title) }}</b>
          <span class="mt-1 block h-1.5 overflow-hidden rounded-full bg-surface-sunk"><span class="block h-full rounded-full" :class="q.complete ? 'bg-success' : 'bg-gold'" :style="{ width: `${(q.progress / q.target) * 100}%` }" /></span>
          <span class="text-xs text-text-muted" dir="ltr">{{ q.progress }} / {{ q.target }}</span>
        </span>
        <span class="flex flex-col items-end gap-1">
          <!-- [X61] Each reward says its currency: coins (the wallet) or the club's money. -->
          <span v-if="q.reward.coins" class="flex items-center gap-1 rounded-pill bg-gold px-2 text-xs font-bold text-on-gold"><img src="/brand/coin.svg" alt="" class="size-3.5" /><span class="font-numbers" dir="ltr">{{ q.reward.coins }}</span> {{ $t('كوينز') }}</span>
          <span v-else class="flex items-center gap-1 rounded-pill bg-success/20 px-2 text-xs font-bold text-success"><span aria-hidden="true">💵</span><span class="font-numbers" dir="ltr">{{ money(q.reward.money ?? 0) }}</span> {{ $t('أموال النادي') }}</span>
          <button v-if="q.complete && !q.claimed" type="button" class="h-10 rounded-lg bg-gold px-3 text-sm font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="claim(q.quest)">{{ $t('خذها') }}</button>
          <span v-else-if="q.claimed" class="text-xs text-success">{{ $t('أُخذت') }}</span>
        </span>
      </li>
    </ul>
  </div>
</template>
