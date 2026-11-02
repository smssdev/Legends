<script setup lang="ts">
// [X83] Choosing who trains in a line (the owner's request: picking was slow and rigid), opened from the slot itself.
// The line's players with a search, four orders (the quickest +1, the most room to grow, the youngest, the strongest)
// and a filter for the injured and those at 99; each with his age, rating, potential, the sessions a +1 takes and his
// progress. One tap trains him; when the slot is taken, one tap puts him in its place (the other keeps his progress).
// Every number comes from the server (GET /training); the order only sorts what it sent.
import { computed, ref } from 'vue'
import type { components } from '../../api/schema'
import UiDialog from '../../components/ui/UiDialog.vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import Icon from '../../components/Icon.vue'
import { nm } from '../../lib/names'
import type { Line } from '../../lib/format'

type View = components['schemas']['TrainingView']
type Player = components['schemas']['TrainingPlayer']
const props = defineProps<{ view: View; line: Line; busy: boolean; error?: string }>()
const emit = defineEmits<{ close: []; pick: [player: Player, replace: boolean]; line: [line: Line] }>()

const LINES: Line[] = ['gk', 'def', 'mid', 'att']
const LINE_NAMES: Record<Line, string> = { gk: 'حارس', def: 'دفاع', mid: 'وسط', att: 'هجوم' }
const SORTS = [
  { key: 'quick', label: 'الأسرع تطوراً' },
  { key: 'room', label: 'الأعلى إمكانية' },
  { key: 'young', label: 'الأصغر سناً' },
  { key: 'strong', label: 'الأقوى' },
] as const
type Sort = (typeof SORTS)[number]['key']
const sort = ref<Sort>('quick')
const query = ref('')
const all = ref(false)

const slot = computed(() => props.view.slots.find((s) => s.line === props.line))
const current = computed(() => slot.value?.player ?? null)
const recommended = computed(() => (props.view.recommended as Record<string, number | null> | undefined)?.[props.line] ?? null)
const ORDER: Record<Sort, (a: Player, b: Player) => number> = {
  quick: (a, b) => a.sessions - b.sessions || a.age - b.age,
  room: (a, b) => (b.potential - b.overall) - (a.potential - a.overall) || a.age - b.age,
  young: (a, b) => a.age - b.age || b.potential - a.potential,
  strong: (a, b) => b.overall - a.overall || a.age - b.age,
}
const inLine = computed(() => props.view.players.filter((p) => p.line === props.line && p.id !== current.value?.id))
const hidden = computed(() => inLine.value.filter((p) => p.maxed || p.injured).length)
const players = computed(() => {
  const q = query.value.trim().toLowerCase()
  return inLine.value
    .filter((p) => all.value || (!p.maxed && !p.injured))
    .filter((p) => !q || p.name.toLowerCase().includes(q) || nm(p.name).toLowerCase().includes(q) || p.position.toLowerCase().includes(q))
    // The maxed last whatever the order, the recommended first.
    .sort((a, b) => Number(a.maxed) - Number(b.maxed) || Number(b.id === recommended.value) - Number(a.id === recommended.value) || ORDER[sort.value](a, b))
})
const ageTone = (p: Player) => ((p.age_bp ?? 10000) > 10000 ? 'text-success' : (p.age_bp ?? 10000) < 10000 ? 'text-warning' : 'text-text-soft')
const growth = (p: Player) => Math.max(0, p.potential - p.overall)
</script>

<template>
  <UiDialog :open="true" bare @close="emit('close')">
    <section class="flex max-h-[88dvh] w-full max-w-xl flex-col overflow-hidden rounded-2xl border border-text/10 bg-bg shadow-2xl" :aria-label="$t('اختر من يتدرب')">
      <!-- The line, the slot's player now, and the way to another line. -->
      <header class="flex flex-col gap-3 border-b border-text/10 p-4">
        <div class="flex items-center gap-2">
          <LineBadge :line="line" />
          <h2 class="flex-1 font-display text-xl font-extrabold">{{ $t('من يتدرب في خانة {v0}؟', { v0: $t(LINE_NAMES[line]) }) }}</h2>
          <button type="button" class="grid size-touch place-items-center rounded-lg bg-surface" :aria-label="$t('إغلاق')" @click="emit('close')"><Icon name="close" /></button>
        </div>
        <div class="flex gap-1 rounded-xl bg-surface p-1" role="tablist" :aria-label="$t('الخط')">
          <button v-for="l in LINES" :key="l" type="button" role="tab" :aria-selected="l === line" class="h-10 flex-1 rounded-lg text-sm font-bold"
            :class="l === line ? 'bg-gold text-on-gold' : 'text-text-soft hover:bg-surface-raised'" @click="emit('line', l)">{{ $t(LINE_NAMES[l]) }}</button>
        </div>
        <p v-if="current" class="flex flex-wrap items-center gap-x-2 rounded-lg bg-surface px-3 py-2 text-sm">
          <span class="text-text-muted">{{ $t('يتدرب الآن:') }}</span>
          <b><bdi>{{ $nm(current.name) }}</bdi></b>
          <span class="font-numbers text-text-muted"><bdi dir="ltr">{{ current.overall }}</bdi> · <bdi dir="ltr">{{ current.progress }}%</bdi></span>
          <span class="text-xs text-text-muted">{{ $t('اختر غيره ليأخذ مكانه، ويحتفظ هو بتقدمه.') }}</span>
        </p>
        <!-- The search and the orders. -->
        <input v-model="query" type="search" class="h-touch rounded-lg bg-surface-sunk px-3 text-sm" :placeholder="$t('ابحث بالاسم أو المركز')" :aria-label="$t('ابحث بالاسم أو المركز')" />
        <div class="flex flex-wrap items-center gap-2" role="radiogroup" :aria-label="$t('الترتيب')">
          <button v-for="s in SORTS" :key="s.key" type="button" role="radio" :aria-checked="sort === s.key" class="h-9 rounded-pill px-3 text-xs font-bold"
            :class="sort === s.key ? 'bg-brand text-white' : 'bg-surface text-text-soft hover:bg-surface-raised'" @click="sort = s.key">{{ $t(s.label) }}</button>
          <label v-if="hidden" class="ms-auto flex min-h-touch items-center gap-2 text-xs text-text-muted">
            <input v-model="all" type="checkbox" class="size-4 accent-[var(--color-gold)]" />{{ $t('أظهر المصابين ومن بلغ 99 ({v0})', { v0: hidden }) }}
          </label>
        </div>
      </header>

      <p v-if="error" class="mx-3 mt-3 rounded-lg bg-live/15 px-3 py-2 text-sm text-danger" role="alert">{{ $t(error) }}</p>
      <!-- The line's players. -->
      <ul class="flex flex-col gap-2 overflow-y-auto p-3">
        <li v-for="p in players" :key="p.id" class="flex items-center gap-3 rounded-xl border bg-surface px-3 py-2.5"
          :class="p.id === recommended ? 'border-gold/50' : 'border-transparent'">
          <span class="grid size-12 shrink-0 place-items-center rounded-lg bg-surface-sunk font-numbers text-xl font-bold" :class="p.overall >= 85 ? 'text-gold' : ''">{{ p.overall }}</span>
          <span class="min-w-0 flex-1">
            <span class="flex items-center gap-1.5">
              <b class="truncate"><bdi>{{ $nm(p.name) }}</bdi></b>
              <span v-if="p.id === recommended" class="shrink-0 rounded-pill bg-gold px-1.5 text-[11px] font-bold text-on-gold">{{ $t('الموصى به') }}</span>
            </span>
            <span class="flex flex-wrap gap-x-2 text-xs text-text-muted">
              <span dir="ltr">{{ p.position }}</span>
              <span :class="ageTone(p)" :title="$t('سرعة التدريب في عمره {v0}%', { v0: Math.round((p.age_bp ?? 10000) / 100) })">{{ $t('{v0} سنة', { v0: p.age }) }}</span>
              <span :class="p.over_potential ? 'text-warning' : 'text-success'">{{ $t('الإمكانية {v0}', { v0: p.potential }) }}<bdi v-if="growth(p)" dir="ltr"> (+{{ growth(p) }})</bdi></span>
              <span>{{ $t('الدرجة التالية بعد نحو {v0} جلسة', { v0: p.sessions }) }}</span>
              <span v-if="p.injured" class="text-danger">{{ $t('مصاب') }}</span>
            </span>
            <span v-if="p.progress" class="mt-1 block h-1.5 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="p.progress" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('التقدم')">
              <span class="block h-full rounded-full bg-gold" :style="{ width: p.progress + '%' }" />
            </span>
          </span>
          <span v-if="p.maxed" class="shrink-0 text-xs text-text-muted">{{ $t('بلغ 99') }}</span>
          <button v-else type="button" class="h-touch shrink-0 rounded-md px-4 text-sm font-bold disabled:opacity-40"
            :class="current ? 'bg-gold text-on-gold' : 'bg-brand text-white'" :disabled="busy" @click="emit('pick', p, !!current)">
            {{ current ? $t('استبدل به') : $t('درّب') }}
          </button>
        </li>
        <li v-if="!players.length" class="rounded-xl bg-surface p-4 text-center text-sm text-text-muted">
          {{ query ? $t('لا لاعب بهذا الاسم في هذا الخط.') : $t('لا لاعبين آخرين في هذا الخط يمكن تدريبهم الآن.') }}
        </li>
      </ul>
    </section>
  </UiDialog>
</template>
