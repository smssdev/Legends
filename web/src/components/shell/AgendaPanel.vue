<script setup lang="ts">
// [Sprint 20 W3, W4] The top bar's two windows: the timers (everything on a clock, counting down live) or what waits
// for the coach (the most urgent first). A sheet from the bottom on the phone, a panel under its icon on the computer.
// Each line opens its screen and closes the window.
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '../Icon.vue'
import { countdown, useNow } from '../../lib/clock'
import { useBoard } from '../../stores/board'
import { useInbox } from '../../stores/inbox'
import { LINE_NAMES, PENDING, SECTION_NAMES, SEVERITY, TIMER } from './agenda'

const props = defineProps<{ kind: 'timers' | 'pending' }>()
const emit = defineEmits<{ close: [] }>()
const store = useBoard()
const inbox = useInbox()
const router = useRouter()
const now = useNow()
const b = computed(() => store.board)
const go = (to: string) => {
  emit('close')
  router.push(to)
}
</script>

<template>
  <div class="fixed inset-0 z-40 bg-black/55 md:bg-transparent" @click="emit('close')" />
  <section class="agenda" role="dialog" :aria-label="$t(kind === 'timers' ? 'المؤقتات' : 'ما ينتظرك')" @keydown.esc="emit('close')">
    <span class="mx-auto mb-2 block h-1 w-10 rounded-full bg-surface-raised md:hidden" aria-hidden="true" />
    <h2 class="mb-2 flex items-center gap-2 font-display text-base font-extrabold">
      <Icon :name="kind === 'timers' ? 'clock' : 'todo'" :size="18" />{{ $t(kind === 'timers' ? 'المؤقتات' : 'ما ينتظرك') }}
    </h2>
    <p v-if="!b" class="py-4 text-center text-sm text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
    <ul v-else-if="props.kind === 'timers'" class="flex flex-col gap-1.5">
      <li v-for="(t, i) in b.timers" :key="i">
        <button type="button" class="agenda-row" @click="go(TIMER[t.kind].to)">
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
        <li v-for="(p, i) in b.pending" :key="i">
          <button type="button" class="agenda-row" :style="{ boxShadow: `inset -3px 0 0 ${SEVERITY[p.severity]}` }" @click="go(PENDING[p.kind].to(p, store.league))">
            <span class="min-w-0 flex-1 text-start">
              <b class="block truncate text-sm">{{ $t(PENDING[p.kind].label) }}<template v-if="p.count"> ({{ p.count }})</template></b>
              <span v-if="p.players?.length" class="block truncate text-xs text-text-muted">
                <template v-for="(pl, j) in p.players" :key="pl.id"><bdi>{{ $nm(pl.name) }}</bdi> {{ $t(pl.why === 'injured' ? '(مصاب)' : '(موقوف)') }}<template v-if="j < p.players.length - 1">، </template></template>
              </span>
              <span v-else-if="p.lines?.length" class="block truncate text-xs text-text-muted">{{ p.lines.map((l) => $t(LINE_NAMES[l] ?? l)).join('، ') }}</span>
            </span>
            <Icon name="more" :size="16" class="shrink-0 text-text-muted rtl:rotate-180" />
          </button>
        </li>
      </ul>
    </template>
  </section>
</template>

<style scoped>
.agenda {
  position: fixed;
  inset-inline: 0;
  bottom: 0;
  z-index: 45;
  max-height: 80dvh;
  overflow-y: auto;
  padding: 0.6rem 0.85rem calc(1rem + env(safe-area-inset-bottom, 0px));
  border-radius: 1.25rem 1.25rem 0 0;
  background: var(--color-surface);
  border-top: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent);
  box-shadow: 0 -12px 40px color-mix(in srgb, var(--color-shade) 60%, transparent);
}
@media (min-width: 768px) {
  .agenda { position: absolute; top: 100%; bottom: auto; inset-inline-start: auto; inset-inline-end: 1rem; width: 24rem; margin-top: 0.4rem; border-radius: 1rem; border: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent); }
}
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
