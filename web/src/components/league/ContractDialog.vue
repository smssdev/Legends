<script setup lang="ts">
import Icon from '../Icon.vue'
// [Sprint 43 W1] The contract the coach signs when he takes his club, once a season (Sprint43Drafts.html): paper with
// the club's seal, the board's objective and the money for transfers, and the coach's signature drawn with his finger.
// The drawing stays on this screen: only «signed» goes to the server. What it is: the guide («contract»).
import { computed, nextTick, onBeforeUnmount, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { cupGoal, leagueGoal } from '../../api/leagues'
import { money } from '../../lib/format'
import { useAuth } from '../../stores/auth'
import { useToast } from '../../stores/toast'
import ClubCrest from '../ui/ClubCrest.vue'
import UiButton from '../ui/UiButton.vue'

type Contract = { club: { id: number; name: string; code: string; colors: string[]; crest_url: string }; league: string; season: number;
  objective: { kind: string; target: number } | null; cup: string | null; budget: number }
const props = defineProps<{ leagueId: number; contract: Contract }>()
const emit = defineEmits<{ signed: [] }>()
const auth = useAuth()
const pad = ref<HTMLCanvasElement | null>(null)
const strokes = ref(0)
const busy = ref(false)
const done = ref(false)
let drawing = false
let last: [number, number] | null = null
const goal = computed(() => (props.contract.objective ? leagueGoal(props.contract.objective) : null))

function point(e: PointerEvent): [number, number] {
  const r = pad.value!.getBoundingClientRect()
  return [(e.clientX - r.left) * (pad.value!.width / r.width), (e.clientY - r.top) * (pad.value!.height / r.height)]
}
function down(e: PointerEvent) {
  drawing = true
  last = point(e)
  pad.value?.setPointerCapture(e.pointerId)
}
function move(e: PointerEvent) {
  if (!drawing || !pad.value || !last) return
  const ctx = pad.value.getContext('2d')!
  const p = point(e)
  ctx.strokeStyle = '#1B3A8A'
  ctx.lineWidth = 4
  ctx.lineCap = 'round'
  ctx.beginPath()
  ctx.moveTo(...last)
  ctx.lineTo(...p)
  ctx.stroke()
  last = p
  strokes.value++
}
function up() { drawing = false; last = null }
function clear() {
  pad.value?.getContext('2d')?.clearRect(0, 0, pad.value.width, pad.value.height)
  strokes.value = 0
}

async function sign() {
  busy.value = true
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/contract', { params: { path: { league: props.leagueId } } })
    done.value = true
    await nextTick()
  } catch (e) { useToast().show(asApiError(e).message, 'error') }
  busy.value = false
}
onBeforeUnmount(() => { drawing = false })
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-shade/70 p-4 backdrop-blur-sm" role="dialog" aria-modal="true" :aria-label="$t('عقد تولي القيادة الفنية')">
    <div class="theme-night w-full max-w-md py-4">
      <article class="contract relative rounded-2xl p-5 text-on-chrome shadow-2xl">
        <div class="mx-auto mb-2 grid size-20 place-items-center rounded-full bg-surface-sunk ring-4 ring-gold-light">
          <ClubCrest :url="contract.club.crest_url" :code="contract.club.code" :name="contract.club.name" :size="60" />
        </div>
        <p class="text-center text-xs font-bold tracking-widest text-gold-dark">{{ $t('عقد تولي القيادة الفنية') }}</p>
        <h2 class="text-center font-display text-2xl font-extrabold">{{ $nm(contract.club.name) }}</h2>
        <p class="mt-2 text-sm leading-relaxed">
          {{ $t('تعلن إدارة {c} تعيين المدرب {u} مديراً فنياً للفريق الأول في {l}، الموسم {s}.', { c: $nm(contract.club.name), u: auth.user?.name ?? '', l: contract.league, s: contract.season }) }}
        </p>
        <div class="mt-3 grid grid-cols-2 gap-2 text-xs">
          <div v-if="goal" class="col-span-2 rounded-xl bg-on-chrome p-2.5 text-gold-light">{{ $t('هدف الإدارة هذا الموسم') }}<b class="block text-base text-chrome"><Icon name="trophy" :size="16" class="inline-block align-[-3px]" /> {{ goal }}</b></div>
          <div class="rounded-xl border border-chrome-dark bg-white/60 p-2.5">{{ $t('ميزانية الانتقالات') }}<b class="block font-numbers text-base" dir="ltr">{{ money(contract.budget) }}</b></div>
          <div class="rounded-xl border border-chrome-dark bg-white/60 p-2.5">{{ contract.cup ? $t('هدف الكأس') : $t('مدة العقد') }}<b class="block text-base">{{ contract.cup ? cupGoal(contract.cup) : $t('موسم واحد') }}</b></div>
        </div>
        <div class="mt-4 grid grid-cols-2 gap-3 text-center text-xs">
          <div><div class="flex h-12 items-end justify-center border-b-2 border-on-chrome pb-1 font-bold italic">{{ $t('إدارة {c}', { c: $nm(contract.club.name) }) }}</div>{{ $t('رئيس النادي') }}</div>
          <div><div class="flex h-12 items-end justify-center border-b-2 border-on-chrome pb-1 font-bold italic">{{ done ? auth.user?.name : '' }}</div>{{ $t('المدير الفني') }}</div>
        </div>
      </article>

      <template v-if="!done">
        <div class="mt-3 rounded-2xl border-2 border-dashed border-gold bg-panel">
          <canvas ref="pad" width="600" height="180" class="block h-28 w-full touch-none rounded-2xl" :aria-label="$t('وقّع بإصبعك هنا')"
            @pointerdown="down" @pointermove="move" @pointerup="up" @pointercancel="up" @pointerleave="up" />
          <p v-if="!strokes" class="pointer-events-none -mt-16 mb-10 text-center text-sm text-text-muted"><Icon name="idea" :size="16" class="inline-block align-[-3px]" /> {{ $t('وقّع بإصبعك هنا') }}</p>
        </div>
        <div class="mt-3 flex gap-2">
          <UiButton class="flex-1" :disabled="strokes < 8" :loading="busy" @click="sign">{{ $t('وقّع وتولَّ القيادة') }}</UiButton>
          <UiButton variant="quiet" :disabled="!strokes" @click="clear">{{ $t('امسح') }}</UiButton>
        </div>
      </template>
      <div v-else class="mt-4 flex flex-col gap-3 text-center">
        <b class="text-lg text-gold-light"><Icon name="star" :size="16" class="inline-block align-[-3px]" /> {{ $t('مرحباً بك مدرباً لـ{c}', { c: $nm(contract.club.name) }) }}</b>
        <UiButton @click="emit('signed')">{{ $t('إلى غرفة الملابس') }}</UiButton>
      </div>
    </div>
  </div>
</template>

<style scoped>
.contract { background: linear-gradient(180deg, var(--color-chrome), var(--color-chrome-dark) 260%); box-shadow: inset 0 0 0 2px var(--color-chrome-dark), 0 18px 40px -10px var(--color-shade) }
.contract::before { content: ''; position: absolute; inset: 7px; border: 1px solid var(--color-gold-dark); border-radius: 13px; pointer-events: none }
</style>
