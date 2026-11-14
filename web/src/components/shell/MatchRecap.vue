<script setup lang="ts">
import Icon from '../Icon.vue'
// [Sprint 24 B1, W1] The quick recap of a match the coach missed (the owner's request 2026-10-29): its big moments
// one after another, fast (the goals, the cards, the substitutions, the injuries), with the score as it moved, then
// the final score and the numbers (possession, shots, the best ratings). «تخطَّ إلى النتيجة» jumps to the end, and
// «التقرير الكامل» opens the report. The server picks the moments and counts the numbers; this only shows them.
// [X69] For any match of the league: a member who coaches neither side gets no result badge and no report, and
// «شاهد المحاكاة كاملة» plays the whole match again (watch: false where it already plays).
import { useEscape } from '../../lib/escape'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'

const props = withDefaults(defineProps<{ matchId: number; watch?: boolean }>(), { watch: true })
const emit = defineEmits<{ close: [] }>()
useEscape(() => emit('close'))
const router = useRouter()
type Recap = components['schemas']['MatchRecap']
const r = ref<Recap | null>(null)
const error = ref('')
const shown = ref(0)
const ended = ref(false)
const STEP_MS = 900
let timer: ReturnType<typeof setInterval> | undefined

onMounted(async () => {
  try {
    r.value = (await api.GET('/matches/{match}/recap', { params: { path: { match: props.matchId } } })).data ?? null
  } catch (e) {
    error.value = asApiError(e).message
    return
  }
  if (!r.value?.moments.length) return finish()
  timer = setInterval(() => {
    shown.value++
    if (shown.value >= r.value!.moments.length) setTimeout(finish, STEP_MS)
  }, STEP_MS)
})
onBeforeUnmount(() => clearInterval(timer))
function finish() {
  clearInterval(timer)
  if (r.value) shown.value = r.value.moments.length
  ended.value = true
}

const seen = computed(() => r.value?.moments.slice(0, shown.value) ?? [])
// The score on the board: the one after the last moment shown, the final one at the end.
const score = computed(() => (ended.value ? r.value?.score : seen.value[seen.value.length - 1]?.score) ?? { home: 0, away: 0 })
const progress = computed(() => (r.value?.moments.length ? Math.round((100 * shown.value) / r.value.moments.length) : 100))
const RESULT = {
  win: ['فوز', 'bg-success/20 text-success'],
  draw: ['تعادل', 'bg-surface-raised text-text'],
  loss: ['خسارة', 'bg-live/20 text-danger'],
} as const
const ICON = { goal: '⚽', card: '', sub: '🔁', injury: '✚', penalty: '◎' } as const
const STATS = [
  ['shots', 'التسديدات'],
  ['on_target', 'على المرمى'],
  ['big_chances', 'فرص محققة'],
  ['corners', 'الركنيات'],
  ['yellow', 'البطاقات الصفراء'],
  ['red', 'البطاقات الحمراء'],
] as const
const mine = (team: string | null) => team === r.value?.side
const rating = (n: number) => (n / 100).toFixed(1)
function go(to: string) {
  emit('close')
  router.push(to)
}
</script>

<template>
  <div
    class="fixed inset-0 z-[60] grid place-items-center bg-bg-deep/90 p-4"
    role="dialog"
    aria-modal="true"
    :aria-label="$t('الملخص السريع')"
  >
    <div class="flex max-h-full w-full max-w-md flex-col gap-3 overflow-hidden rounded-2xl border border-gold/40 bg-surface p-4 shadow-2xl">
      <div class="flex items-center gap-2 text-xs text-text-muted">
        <span class="flex-1 font-bold text-gold">{{ $t('الملخص السريع') }}</span>
        <button type="button" class="grid size-11 place-items-center rounded-lg text-lg" :aria-label="$t('إغلاق')" @click="emit('close')">
          <Icon name="close" :size="18" />
        </button>
      </div>
      <p v-if="error" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger">{{ $t(error) }}</p>
      <div v-else-if="!r" class="h-40 animate-pulse rounded-xl bg-surface-sunk" aria-hidden="true" />

      <template v-if="r">
        <!-- The board: the crests and the score as it moved. -->
        <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 text-center">
          <span class="flex min-w-0 flex-col items-center gap-1"
            ><AppImage :src="r.home.crest_url" alt="" class="size-12" :size="48" crest /><b class="max-w-full truncate text-sm">{{
              $nm(r.home.name)
            }}</b></span
          >
          <span class="flex flex-col items-center gap-1">
            <!-- Each number beside its own crest, in the page's direction (home on the right in Arabic). -->
            <b class="flex gap-2 font-numbers text-5xl leading-none" aria-live="polite"
              ><span>{{ score.home }}</span
              ><span>-</span><span>{{ score.away }}</span></b
            >
            <span v-if="ended && r.shootout" class="text-xs text-text-soft"
              >{{ $t('ركلات الترجيح') }}
              <b class="inline-flex gap-1 font-numbers"
                ><span>{{ r.shootout.home }}</span
                ><span>-</span><span>{{ r.shootout.away }}</span></b
              ></span
            >
            <span v-if="ended && r.side" class="rounded-pill px-2 py-0.5 text-xs font-bold" :class="RESULT[r.result][1]">{{
              $t(RESULT[r.result][0])
            }}</span>
            <span v-else class="font-numbers text-xs text-text-muted" dir="ltr">{{
              seen.length ? seen[seen.length - 1].minute + "'" : "0'"
            }}</span>
          </span>
          <span class="flex min-w-0 flex-col items-center gap-1"
            ><AppImage :src="r.away.crest_url" alt="" class="size-12" :size="48" crest /><b class="max-w-full truncate text-sm">{{
              $nm(r.away.name)
            }}</b></span
          >
        </div>
        <div v-if="!ended" class="h-1 overflow-hidden rounded-pill bg-surface-sunk" aria-hidden="true">
          <span class="block h-full bg-gold transition-all" :style="{ width: progress + '%' }" />
        </div>

        <!-- The moments, the newest on top while it plays. -->
        <ol v-if="!ended" class="flex min-h-40 flex-col gap-1.5 overflow-y-auto">
          <li
            v-for="(m, i) in [...seen].reverse()"
            :key="seen.length - i"
            class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm"
            :class="[i === 0 ? 'bg-gold/15' : 'bg-surface-sunk', m.team === 'away' ? 'flex-row-reverse text-end' : '']"
          >
            <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ m.minute }}'</span>
            <span
              v-if="m.type === 'card'"
              class="inline-block h-4 w-3 rounded-sm"
              :class="m.color === 'red' ? 'bg-live' : 'bg-warning'"
              aria-hidden="true"
            />
            <span v-else aria-hidden="true">{{ ICON[m.type] }}</span>
            <span class="min-w-0 flex-1" :class="mine(m.team) ? 'font-bold' : 'text-text-soft'">
              <template v-if="m.type === 'goal'"
                >{{ $t('هدف') }}: <bdi>{{ $nm(m.player ?? '') }}</bdi><span v-if="m.other" class="text-xs text-text-muted">
                  · {{ $t('صناعة') }} <bdi>{{ $nm(m.other) }}</bdi></span
                ></template
              >
              <template v-else-if="m.type === 'card'"
                >{{ $t(m.color === 'red' ? 'طرد' : 'إنذار') }}: <bdi>{{ $nm(m.player ?? '') }}</bdi></template
              >
              <template v-else-if="m.type === 'sub'"
                >{{ $t('تبديل') }}: <bdi>{{ $nm(m.other ?? '') }}</bdi> ↔ <bdi>{{ $nm(m.player ?? '') }}</bdi></template
              >
              <template v-else-if="m.type === 'injury'"
                >{{ $t('إصابة') }}: <bdi>{{ $nm(m.player ?? '') }}</bdi></template
              >
              <template v-else
                >{{ $t('ركلة جزاء')
                }}<template v-if="m.player"
                  >: <bdi>{{ $nm(m.player) }}</bdi></template
                ></template
              >
            </span>
          </li>
          <li v-if="!seen.length" class="py-6 text-center text-sm text-text-muted">{{ $t('صافرة البداية…') }}</li>
        </ol>

        <!-- The end: the numbers and the best ratings. -->
        <template v-else>
          <div class="flex flex-col gap-1.5 rounded-lg bg-surface-sunk p-3 text-sm">
            <div class="flex items-center gap-2">
              <b class="w-10 font-numbers" dir="ltr">{{ r.stats.home.possession }}%</b>
              <span class="flex h-2 flex-1 overflow-hidden rounded-pill bg-surface-raised" :aria-label="$t('الاستحواذ %')"
                ><span class="bg-brand-light" :style="{ width: r.stats.home.possession + '%' }" /><span class="flex-1 bg-gold"
              /></span>
              <b class="w-10 text-end font-numbers" dir="ltr">{{ r.stats.away.possession }}%</b>
            </div>
            <p class="text-center text-xs text-text-muted">{{ $t('الاستحواذ %') }}</p>
            <div v-for="[k, label] in STATS" :key="k" class="grid grid-cols-[2.5rem_1fr_2.5rem] items-center text-center">
              <b class="font-numbers" dir="ltr">{{ r.stats.home[k] }}</b><span class="text-xs text-text-muted">{{ $t(label) }}</span
              ><b class="font-numbers" dir="ltr">{{ r.stats.away[k] }}</b>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-2 text-sm">
            <ul v-for="side in ['home', 'away'] as const" :key="side" class="flex flex-col gap-1 rounded-lg bg-surface-sunk p-2">
              <li v-for="p in r.best[side]" :key="p.id" class="flex items-center gap-1">
                <bdi class="min-w-0 flex-1 truncate">{{ $nm(p.name ?? '') }}</bdi><span class="font-numbers text-gold">{{
                  rating(p.rating)
                }}</span>
              </li>
            </ul>
          </div>
          <p v-if="r.man_of_the_match" class="text-center text-sm">
            <Icon name="star" :size="16" class="inline-block align-[-3px]" /> {{ $t('رجل المباراة') }}:
            <b
              ><bdi>{{ $nm(r.man_of_the_match.name ?? '') }}</bdi></b
            >
            <span class="font-numbers text-gold">{{ rating(r.man_of_the_match.rating ?? 0) }}</span>
          </p>
        </template>

        <div class="flex flex-wrap gap-2">
          <button v-if="!ended" type="button" class="h-touch flex-1 rounded-lg bg-surface-raised font-bold" @click="finish">
            {{ $t('تخطَّ إلى النتيجة') }}
          </button>
          <button
            v-if="props.watch"
            type="button"
            class="h-touch flex-1 rounded-lg font-bold"
            :class="ended ? 'bg-gold text-on-gold' : 'bg-surface-raised'"
            @click="go(`/live/${props.matchId}`)"
          >
            <Icon name="play" :size="16" class="inline-block align-[-3px]" /> {{ $t('شاهد المحاكاة كاملة') }}
          </button>
          <button
            v-if="r.side"
            type="button"
            class="h-touch flex-1 rounded-lg font-bold"
            :class="ended && !props.watch ? 'bg-gold text-on-gold' : 'text-text-muted'"
            @click="go(`/live/${props.matchId}/report`)"
          >
            {{ $t('التقرير الكامل') }}
          </button>
        </div>
      </template>
    </div>
  </div>
</template>
