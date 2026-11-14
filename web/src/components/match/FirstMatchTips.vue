<script setup lang="ts">
// [Sprint 30 G3] The coach's first live matches, taught as they happen by the Assistant Coach (his face, B3, and a
// bubble): at kick-off, at the first tactical window («بدّل الآن» opens the coach's panel), at half-time and at the
// first goal against. Each tip once on this device; three matches and they stop. The game's rules stay in his guide
// (Sprint 22): these are only «now is the moment» nudges.
import { storage } from '../../lib/storage'
import { computed, ref, watch } from 'vue'
import Character from '../characters/Character.vue'
import UiButton from '../ui/UiButton.vue'

const props = defineProps<{
  active: boolean
  started: boolean
  windowOn: boolean
  halftime: boolean
  conceded: number
  finished: boolean
}>()
const KEY = 'tutorial.match'
type Tip = 'kickoff' | 'window' | 'halftime' | 'conceded'
type Seen = { tips: Tip[]; matches: number }
function read(): Seen {
  try {
    return { tips: [], matches: 0, ...JSON.parse(storage.get(KEY) ?? '{}') }
  } catch {
    return { tips: [], matches: 0 }
  }
}
const seen = ref<Seen>(read())
const write = () => {
  try {
    storage.set(KEY, JSON.stringify(seen.value))
  } catch {
    /* private mode */
  }
}
const learning = computed(() => props.active && seen.value.matches < 3)
const current = ref<Tip | null>(null)
const TEXT: Record<Tip, { title: string; text: string; go?: string }> = {
  kickoff: {
    title: 'مباراتك المباشرة بدأت',
    text: 'تتابع كل دقيقة كما تحدث، وتغيّر التكتيك وتبدّل لاعبيك أثناء اللعب، وكل تغيير يُطبق في الدقيقة التالية.',
  },
  window: {
    title: 'النافذة التكتيكية مفتوحة',
    text: 'المباراة متوقفة لك ولخصمك: بدّل لاعباً متعباً أو غيّر الخطة الآن، ثم اضغط «أنا مستعد».',
    go: 'بدّل الآن',
  },
  halftime: { title: 'الاستراحة', text: 'راجع الزخم والإحصائيات، وعدّل التكتيك للشوط الثاني قبل أن يبدأ.', go: 'افتح لوحة المدرب' },
  conceded: {
    title: 'استقبلت هدفاً؟',
    text: 'جرّب رفع الضغط أو أسلوباً أكثر هجوماً من التكتيك، أو أدخل مهاجماً من الاحتياط.',
    go: 'غيّر التكتيك',
  },
}
function offer(tip: Tip) {
  if (!learning.value || seen.value.tips.includes(tip) || current.value) return
  current.value = tip
  seen.value.tips.push(tip)
  write()
}
watch(
  () => props.started,
  (on) => on && offer('kickoff'),
  { immediate: true },
)
watch(
  () => props.windowOn,
  (on) => on && offer('window'),
)
watch(
  () => props.halftime,
  (on) => on && offer('halftime'),
)
watch(
  () => props.conceded,
  (n, was) => n > (was ?? 0) && offer('conceded'),
)
// A match seen to its end counts; after three the tips stop (and those not seen yet are no longer needed).
watch(
  () => props.finished,
  (done) => {
    if (!done || !props.active) return
    seen.value.matches++
    write()
    current.value = null
  },
)
function go() {
  current.value = null
  document.getElementById('coach')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}
</script>

<template>
  <Transition name="tip">
    <aside
      v-if="current"
      class="fixed inset-x-3 bottom-[max(1rem,env(safe-area-inset-bottom))] z-50 mx-auto flex max-w-md items-start gap-3 rounded-2xl border border-gold/50 bg-panel p-3 shadow-2xl"
      role="status"
      aria-live="polite"
    >
      <Character model="B3" mood="joy" class="size-14 shrink-0" />
      <div class="flex min-w-0 flex-1 flex-col gap-2">
        <b class="font-display text-base text-gold">{{ $t(TEXT[current].title) }}</b>
        <p class="text-sm leading-relaxed">{{ $t(TEXT[current].text) }}</p>
        <div class="flex gap-2">
          <UiButton v-if="TEXT[current].go" @click="go">{{ $t(TEXT[current].go!) }}</UiButton>
          <UiButton variant="quiet" @click="current = null">{{ $t('حسناً') }}</UiButton>
        </div>
      </div>
    </aside>
  </Transition>
</template>

<style scoped>
.tip-enter-active,
.tip-leave-active {
  transition:
    opacity 0.25s ease,
    transform 0.25s ease;
}
.tip-enter-from,
.tip-leave-to {
  opacity: 0;
  transform: translateY(12px);
}
@media (prefers-reduced-motion: reduce) {
  .tip-enter-active,
  .tip-leave-active {
    transition: none;
  }
}
</style>
