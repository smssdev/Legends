<script setup lang="ts">
// [Sprint 20 W3, W4] The top bar's two windows: the timers (everything on a clock, counting down live) or what waits
// for the coach (the most urgent first). [X61] Under the top bar on the phone too (it was a sheet from the bottom, under
// the bot and the bottom bar), and a panel under its icon on the computer.
// Each line opens its screen and closes the window.
import { useEscape } from '../../lib/escape'
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '../Icon.vue'
import { countdown, useNow } from '../../lib/clock'
import { useBoard } from '../../stores/board'
import { useInbox } from '../../stores/inbox'
import { useWallet } from '../../stores/wallet'
import { api } from '../../api/client'
import { act, busy } from '../../lib/action'
import { t } from '../../lib/i18n'
import { LINE_NAMES, PENDING, SECTION_NAMES, SEVERITY, TIMER } from './agenda'

// [Sprint 56 W1] `inline`: the same list inside the office's cards (Office.html), no window, no veil, no heading (the
// card has its own), scrolling inside its card.
const props = defineProps<{ kind: 'timers' | 'pending'; inline?: boolean }>()
const emit = defineEmits<{ close: [] }>()
if (!props.inline) useEscape(() => emit('close'))
const store = useBoard()
const inbox = useInbox()
const router = useRouter()
const now = useNow()
const b = computed(() => store.board)
const go = (to: string) => {
  emit('close')
  router.push(to)
}

// [X88] Done from here, without opening the screen: the daily reward taken, the empty training slots filled with
// their recommended players (the server's), each through lib/action (its button waits, the result in a toast).
const wallet = useWallet()
const claimDaily = () => act('daily', () => api.POST('/wallet/daily'), { success: t('استلمت مكافأة اليوم.') })
  .then((r) => { if (r) { wallet.load(); store.refresh() } })
const fillTraining = () => act('fill-training', async () => {
  const league = store.league!
  const view = (await api.GET('/leagues/{league}/training', { params: { path: { league } } })).data!
  const empty = new Set(view.slots.filter((s) => !s.player).map((s) => s.line))
  const ids = Object.entries((view.recommended ?? {}) as Record<string, number | null>).filter(([l, id]) => empty.has(l as never) && id).map(([, id]) => id!)
  for (const id of ids) await api.POST('/leagues/{league}/training', { params: { path: { league } }, body: { player_id: id } })
  return ids.length
}, { success: (n) => (n ? t('بدأ التدريب في {v0} خانات.', { v0: n }) : t('لا لاعب موصى به للخانات الفارغة الآن.')) }).then(() => store.refresh())
</script>

<template>
  <div class="contents">
  <div v-if="!inline" class="agenda-veil fixed inset-0 z-40 bg-black/55 md:bg-transparent" @click="emit('close')" />
  <section :class="inline ? 'agenda-inline' : 'agenda'" :aria-label="$t(kind === 'timers' ? 'المؤقتات' : 'ما ينتظرك')">
    <h2 v-if="!inline" class="mb-2 flex items-center gap-2 font-display text-base font-extrabold">
      <Icon :name="kind === 'timers' ? 'clock' : 'todo'" :size="18" />{{ $t(kind === 'timers' ? 'المؤقتات' : 'ما ينتظرك') }}
    </h2>
    <p v-if="!b" class="py-4 text-center text-sm text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
    <ul v-else-if="props.kind === 'timers'" class="flex flex-col gap-1.5">
      <li v-for="(t, i) in b.timers" :key="i" class="flex items-center gap-1.5">
        <!-- [X88] The daily reward, ready: taken here in one tap. -->
        <button v-if="t.kind === 'daily' && !(t.at && countdown(t.at, now))" type="button" class="agenda-row" :disabled="busy('daily')" @click="claimDaily">
          <Icon :name="TIMER[t.kind].icon as never" :size="18" class="shrink-0 text-text-muted" />
          <span class="min-w-0 flex-1 text-start"><b class="block truncate text-sm">{{ $t(TIMER[t.kind].label) }}</b><span class="block truncate text-xs text-text-muted">{{ $t('{v0} كوينز', { v0: t.amount }) }}</span></span>
          <span class="shrink-0 rounded-pill bg-gold px-3 py-1 text-xs font-bold text-on-gold">{{ busy('daily') ? '...' : $t('خذها') }}</span>
        </button>
        <button v-else type="button" class="agenda-row" @click="go(TIMER[t.kind].to)">
          <Icon :name="TIMER[t.kind].icon as never" :size="18" class="shrink-0 text-text-muted" />
          <span class="min-w-0 flex-1 text-start">
            <b class="block truncate text-sm">{{ $t(TIMER[t.kind].label) }}</b>
            <span class="block truncate text-xs text-text-muted">
              <template v-if="t.kind === 'match'">{{ t.live ? $t('مباشر الآن') : $t('ضد {v0}', { v0: $nm(t.opponent ?? '') }) }}</template>
              <template v-else-if="t.kind === 'training'"><bdi>{{ $nm(t.player ?? '') }}</bdi> · {{ $t(LINE_NAMES[t.line ?? ''] ?? '') }}</template>
              <template v-else-if="t.kind === 'stadium'">{{ $t(SECTION_NAMES[t.section ?? ''] ?? '') }} · {{ $t('الجزء {v0} من 5', { v0: t.part }) }}</template>
              <template v-else-if="t.kind === 'daily'">{{ $t('{v0} كوينز', { v0: t.amount }) }}</template>
            </span>
          </span>
          <span v-if="t.at && countdown(t.at, now)" class="shrink-0 font-numbers text-lg text-gold" dir="ltr">{{ countdown(t.at, now) }}</span>
          <span v-else class="shrink-0 rounded-pill bg-gold px-3 py-1 text-xs font-bold text-on-gold">{{ $t(t.kind === 'daily' ? 'خذها' : 'الآن') }}</span>
        </button>
      </li>
    </ul>
    <template v-else>
      <p v-if="!b.pending.length && !inbox.unread" class="py-4 text-center text-sm text-text-muted">{{ $t('لا شيء ينتظرك. أحسنت!') }}</p>
      <ul v-else class="flex flex-col gap-1.5">
        <!-- Unread messages wait too (and on a narrow phone this is their way in). -->
        <li v-if="inbox.unread">
          <button type="button" class="agenda-row" :style="{ boxShadow: `inset -3px 0 0 ${SEVERITY.mid}` }" @click="go('/inbox')">
            <span class="min-w-0 flex-1 text-start"><b class="block truncate text-sm">{{ $t('رسائل غير مقروءة') }} ({{ inbox.unread }})</b></span>
            <Icon name="more" :size="16" class="shrink-0 text-text-muted rtl:rotate-180" />
          </button>
        </li>
        <li v-for="(p, i) in b.pending" :key="i" class="flex gap-1.5" :class="inline ? 'flex-col items-stretch' : 'items-center'">
          <button type="button" class="agenda-row min-w-0 flex-1" :style="{ boxShadow: `inset -3px 0 0 ${SEVERITY[p.severity]}` }" @click="go(PENDING[p.kind].to(p, store.league))">
            <span class="min-w-0 flex-1 text-start">
              <b class="block truncate text-sm">{{ $t(PENDING[p.kind].label) }}<template v-if="p.count"> ({{ p.count }})</template></b>
              <span v-if="p.players?.length" class="block truncate text-xs text-text-muted">
                <template v-for="(pl, j) in p.players" :key="pl.id"><bdi>{{ $nm(pl.name) }}</bdi> {{ $t(pl.why === 'injured' ? '(مصاب)' : '(موقوف)') }}<template v-if="j < p.players.length - 1">، </template></template>
              </span>
              <span v-else-if="p.lines?.length" class="block truncate text-xs text-text-muted">{{ p.lines.map((l) => $t(LINE_NAMES[l] ?? l)).join('، ') }}</span>
            </span>
            <Icon name="more" :size="16" class="shrink-0 text-text-muted rtl:rotate-180" />
          </button>
          <!-- [X88] The empty training slots, filled here with their recommended players. -->
          <button v-if="p.kind === 'training_empty'" type="button" class="min-h-touch shrink-0 rounded-lg bg-gold px-3 text-xs font-bold text-on-gold disabled:opacity-40" :disabled="busy('fill-training')" @click="fillTraining">
            {{ busy('fill-training') ? '...' : $t('املأها بالموصى بهم') }}
          </button>
        </li>
      </ul>
    </template>
  </section>
  </div>
</template>

<style scoped>
.agenda {
  position: absolute;
  top: 100%;
  inset-inline: 0.5rem;
  z-index: 45;
  max-height: 70dvh;
  overflow-y: auto;
  overscroll-behavior: contain;
  margin-top: 0.4rem;
  padding: 0.75rem 0.85rem;
  border-radius: 1rem;
  background: var(--color-surface);
  border: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent);
  box-shadow: 0 16px 40px color-mix(in srgb, var(--color-shade) 60%, transparent);
  transform-origin: top;
}
@media (min-width: 768px) {
  .agenda { inset-inline-start: auto; inset-inline-end: 1rem; width: 24rem; }
}
.agenda-inline { min-height: 0; flex: 1; overflow-y: auto; overscroll-behavior: contain; }
.agenda-row {
  display: flex;
  width: 100%;
  min-height: 3rem;
  align-items: center;
  gap: 0.6rem;
  padding: 0.5rem 0.7rem;
  border-radius: 0.7rem;
  background: var(--color-surface-sunk);
}
.agenda-row:hover { background: var(--color-surface-raised); }
</style>
