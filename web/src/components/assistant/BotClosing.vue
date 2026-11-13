<script setup lang="ts">
import Icon from '../Icon.vue'
// [X61] The Assistant Coach's end: a card over the conversation, dropping from the top (reka-ui's Dialog, Sprint 54 W4, keeps
// the focus inside and closes on Esc). What was done, what is next (the most urgent thing waiting, from the club
// board), the coins and the club's money; the next step, the lineup, or keep it for later; and 👍/👎 with a note.
import { DialogContent, DialogOverlay, DialogPortal, DialogRoot, DialogTitle } from 'reka-ui'
import { computed, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { money } from '../../lib/format'
import { t } from '../../lib/i18n'
import { useBoard } from '../../stores/board'
import { useBot } from '../../stores/bot'
import { useSlot } from '../../stores/slot'
import { useWallet } from '../../stores/wallet'
import { PENDING } from '../shell/agenda'

const props = defineProps<{ page: string; leagueId: number | null; labelOf: (go: string) => string; pathFor: (go: string) => string }>()
const emit = defineEmits<{ go: [path: string] }>()
const bot = useBot()
const board = useBoard()
const slot = useSlot()
const wallet = useWallet()

const asked = computed(() => bot.messages.filter((m) => m.from === 'me'))
const lastAsked = computed(() => asked.value[asked.value.length - 1]?.text ?? '')
const next = computed(() => {
  const p = board.board?.pending[0]
  return p ? { label: t(PENDING[p.kind].label), to: PENDING[p.kind].to(p, props.leagueId) } : null
})
const savedNow = ref(false)
const vote = ref<null | boolean>(null)
const note = ref('')
const thanks = ref('')
const error = ref('')

function close() {
  bot.closing = null
  bot.followed = null
}
function go(path: string) {
  close()
  emit('go', path)
}
function keep() {
  bot.save()
  savedNow.value = true
}
async function rate(helpful: boolean, withNote = false) {
  vote.value = helpful
  if (!helpful && !withNote) return   // a 👎 asks for a word first
  error.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/assistant/feedback', { body: { helpful, page: props.page, note: note.value.trim() || null } })
    thanks.value = data!.message
  } catch (e) {
    error.value = asApiError(e).message
  }
}
</script>

<template>
  <DialogRoot :open="!!bot.closing" @update:open="(o: boolean) => { if (!o) close() }">
    <DialogPortal>
    <DialogOverlay class="ui-veil fixed inset-0 z-[70] bg-black/55" />
    <div class="pointer-events-none fixed inset-x-0 top-0 z-[70] flex justify-center p-3 pt-[max(0.75rem,env(safe-area-inset-top))] md:inset-x-auto md:end-0 md:w-[23rem]">
      <DialogContent class="closing pointer-events-auto relative w-full max-w-md overflow-hidden rounded-2xl p-[1.5px] shadow-overlay" :aria-describedby="undefined">
        <div class="relative flex max-h-[85dvh] flex-col gap-3 overflow-y-auto overscroll-contain rounded-2xl bg-surface p-4">
          <button type="button" class="absolute end-2 top-2 grid size-11 place-items-center rounded-lg text-text-muted hover:bg-surface-raised" :aria-label="$t('إغلاق')" @click="close"><Icon name="close" :size="18" /></button>
          <header class="flex items-center gap-3 pe-10">
            <span class="relative grid size-14 shrink-0 pulse-ring place-items-center rounded-full bg-gold/15">
              <AppImage :src="slot.current?.club?.crest_url ?? '/brand/emblem-loader.svg'" alt="" class="size-11 animate-pop-in drop-shadow-[0_0_10px_var(--color-gold)]" :size="44" crest />
            </span>
            <span class="min-w-0">
              <DialogTitle class="flex items-center gap-1.5 font-display text-lg font-extrabold text-gold">
                {{ bot.closing === 'done' ? $t('تمّت المهمة') : $t('انتهت المحادثة') }}
                <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M5 12.5l4.5 4.5L19 7.5" class="animate-draw" style="stroke-dasharray: 24; stroke-dashoffset: 24" />
                </svg>
              </DialogTitle>
              <p class="text-sm text-text-soft">{{ bot.followed ? $t('فتحت لك {v0} كما اقترحت.', { v0: $t(labelOf(bot.followed)) }) : $t('سعدت بمساعدتك يا كوتش، وأنا هنا متى احتجتني.') }}</p>
            </span>
          </header>

          <dl class="flex flex-col gap-1.5 rounded-xl bg-surface-sunk p-3 text-sm">
            <div class="flex gap-2"><dt class="w-20 shrink-0 text-text-muted">{{ $t('ما تم') }}</dt>
              <dd class="min-w-0 flex-1">{{ asked.length === 1 ? $t('سؤال واحد: «{v0}»', { v0: lastAsked.slice(0, 60) }) : asked.length ? $t('{v0} أسئلة، آخرها: «{v1}»', { v0: asked.length, v1: lastAsked.slice(0, 60) }) : $t('لا أسئلة بعد') }}</dd></div>
            <div class="flex gap-2"><dt class="w-20 shrink-0 text-text-muted">{{ $t('ما التالي') }}</dt>
              <dd class="min-w-0 flex-1">{{ next ? next.label : $t('لا شيء ينتظرك. أحسنت!') }}</dd></div>
            <div class="flex gap-2"><dt class="w-20 shrink-0 text-text-muted">{{ $t('رصيدك') }}</dt>
              <dd class="flex min-w-0 flex-1 flex-wrap items-center gap-x-3 font-numbers" dir="ltr">
                <span class="flex items-center gap-1"><AppImage src="/brand/coin.svg" alt="" class="size-4" :size="16" />{{ wallet.view?.balance ?? 0 }}</span>
                <span v-if="board.board" class="text-success"><Icon name="finance" :size="16" class="inline-block align-[-3px]" /> {{ money(board.board.money.cash) }}</span>
              </dd></div>
          </dl>

          <div class="flex flex-col gap-2">
            <button v-if="next || bot.followed" type="button" class="btn-closing bg-gold text-on-gold" @click="go(next ? next.to : pathFor(bot.followed!))">{{ next ? next.label : $t('افتح {v0}', { v0: $t(labelOf(bot.followed!)) }) }}</button>
            <div class="grid grid-cols-2 gap-2">
              <button type="button" class="btn-closing bg-surface-raised" @click="go('/lineup')">{{ $t('شوف التشكيلة') }}</button>
              <button type="button" class="btn-closing bg-surface-raised" :disabled="savedNow" @click="keep">{{ savedNow ? $t('حُفظت') : $t('احفظ وتابع لاحقاً') }}</button>
            </div>
          </div>

          <section class="flex flex-col gap-2 border-t border-text/10 pt-3" :aria-label="$t('هل أفادك الرد؟')">
            <p v-if="thanks" class="animate-pop-in text-center text-sm font-bold text-success" role="status">{{ thanks }}</p>
            <template v-else>
              <div class="flex items-center gap-2">
                <span class="flex-1 text-sm">{{ $t('هل أفادك الرد؟') }}</span>
                <button type="button" class="grid size-11 place-items-center rounded-full text-xl transition active:scale-90" :class="vote === true ? 'bg-success/25' : 'bg-surface-raised'" :aria-label="$t('أفادني')" :aria-pressed="vote === true" @click="rate(true)"><Icon name="thumbs_up" :size="18" class="inline-block align-[-3px]" /></button>
                <button type="button" class="grid size-11 place-items-center rounded-full text-xl transition active:scale-90" :class="vote === false ? 'bg-live/25' : 'bg-surface-raised'" :aria-label="$t('لم يفدني')" :aria-pressed="vote === false" @click="rate(false)"><Icon name="thumbs_down" :size="18" class="inline-block align-[-3px]" /></button>
              </div>
              <form v-if="vote === false" class="flex gap-2" @submit.prevent="rate(false, true)">
                <input v-model="note" maxlength="300" dir="auto" class="h-11 min-w-0 flex-1 rounded-lg bg-surface-sunk px-3 text-sm" :placeholder="$t('ما الذي كان ينقص؟ (اختياري)')" :aria-label="$t('ما الذي كان ينقص؟ (اختياري)')" />
                <button type="submit" class="h-11 rounded-lg bg-brand px-4 text-sm font-bold text-white">{{ $t('أرسل') }}</button>
              </form>
              <p v-if="error" class="text-xs text-danger" role="alert">{{ error }}</p>
            </template>
          </section>

          <button type="button" class="min-h-touch text-sm font-bold text-brand-light" @click="close">{{ $t('العودة للمحادثة') }}</button>
        </div>
      </DialogContent>
    </div>
    </DialogPortal>
  </DialogRoot>
</template>

<style scoped>
/* A gold edge that fades to the night, and the card drops in from the top. */
.closing {
  background: linear-gradient(135deg, var(--color-gold), color-mix(in srgb, var(--color-gold) 25%, transparent) 45%, transparent 70%);
  transform-origin: top;
  animation: closing-in var(--duration-slow) var(--ease-spring);
}
@keyframes closing-in { from { opacity: 0; transform: translateY(-1.5rem) scale(0.97); } to { opacity: 1; transform: none; } }
.btn-closing { display: flex; min-height: 2.75rem; align-items: center; justify-content: center; border-radius: 0.75rem; padding: 0 0.75rem; font-weight: 800; font-size: 0.875rem; transition: transform var(--duration-fast) var(--ease-soft); }
.btn-closing:active { transform: scale(0.97); }
.btn-closing:disabled { opacity: 0.6; }
</style>
