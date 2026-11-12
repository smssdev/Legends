<script setup lang="ts">
// [X61] The first steps of a new coach, on the home screen: seven steps, each a button to the right screen. [X75] A step
// is done only when the server says it is done in the game (home.onboarding), never by tapping it. Folds away (reka-ui's Collapsible, Sprint 54 W4), and goes once every step is done. [Sprint 26 W4] The falcon (A1)
// cheers each step.
import { storage } from '../lib/storage'
import { CollapsibleContent, CollapsibleRoot, CollapsibleTrigger } from 'reka-ui'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../stores/auth'
import Character from './characters/Character.vue'

const props = defineProps<{ hasClub: boolean; steps: Record<string, boolean> }>()
const auth = useAuth()
const router = useRouter()
const KEY = computed(() => `onboarding.${auth.user?.id ?? 0}`)

type Step = { key: string; label: string; to: string; club?: boolean }
const STEPS: Step[] = [
  { key: 'account', label: 'وثّق حسابك أو اربطه بجوجل', to: '/profile' },
  { key: 'invite', label: 'ادعُ صديقاً إلى دوريك', to: '/profile' },
  { key: 'coach', label: 'تعاقد مع مدرب خط', to: '/specialists', club: true },
  { key: 'lineup', label: 'اضبط التشكيلة', to: '/lineup', club: true },
  { key: 'tactics', label: 'اختر التكتيك', to: '/tactics', club: true },
  { key: 'name', label: 'اختر اسمك وصورتك في اللعبة', to: '/profile' },
  { key: 'friendly', label: 'العب أول ودية', to: '/friendlies', club: true },
]

const done = (s: Step) => !!props.steps[s.key]
const count = computed(() => STEPS.filter(done).length)
// [X86] Closed by default: the next step under its title, the seven when opened.
const next = computed(() => STEPS.find((s) => !done(s)) ?? null)
const hidden = ref((() => { try { return storage.get(`${KEY.value}.hidden`) === '1' } catch { return false } })())

function go(s: Step) {
  void router.push(s.club && !props.hasClub ? '/leagues' : s.to)
}
function hide() {
  hidden.value = true
  try { storage.set(`${KEY.value}.hidden`, '1') } catch {}
}
</script>

<template>
  <CollapsibleRoot v-if="!hidden && count < STEPS.length" v-slot="{ open }" as="section" class="animate-fade-up rounded-xl border border-gold/30 bg-surface p-3" :aria-label="$t('خطواتك الأولى')">
    <div class="flex items-center gap-2">
      <Character model="A1" :mood="count ? 'cheer' : 'joy'" class="w-12 shrink-0" />
      <CollapsibleTrigger class="flex min-h-touch flex-1 items-center gap-3 text-start">
        <span class="relative grid size-11 shrink-0 place-items-center">
          <svg viewBox="0 0 36 36" class="absolute inset-0 -rotate-90" aria-hidden="true">
            <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" class="text-surface-sunk" />
            <circle cx="18" cy="18" r="15" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" class="text-gold transition-[stroke-dashoffset] duration-700 ease-soft"
              :stroke-dasharray="94.25" :stroke-dashoffset="94.25 * (1 - count / STEPS.length)" />
          </svg>
          <b class="font-numbers text-sm" dir="ltr">{{ count }}/{{ STEPS.length }}</b>
        </span>
        <span class="min-w-0 flex-1"><b class="block font-display text-base">{{ $t('خطواتك الأولى') }}</b>
          <span class="text-xs text-text-muted">{{ open || !next ? $t('سبع خطوات تجهّز ناديك لأول مباراة') : $t('التالية: {v0}', { v0: $t(next.label) }) }}</span></span>
        <span class="text-gold transition-transform duration-200" :class="open ? 'rotate-180' : ''" aria-hidden="true">▾</span>
      </CollapsibleTrigger>
      <button type="button" class="grid size-11 place-items-center rounded-lg text-text-muted hover:bg-surface-raised" :aria-label="$t('إخفاء')" @click="hide">✕</button>
    </div>
    <CollapsibleContent as="ol" class="drop-panel mt-2 flex flex-col gap-1.5">
        <li v-for="(s, i) in STEPS" :key="s.key">
          <button type="button" class="flex min-h-touch w-full items-center gap-3 rounded-lg px-3 py-2 text-start transition-colors" :class="done(s) ? 'bg-success/10' : 'bg-surface-sunk hover:bg-surface-raised'" @click="go(s)">
            <span class="grid size-7 shrink-0 place-items-center rounded-full font-numbers text-sm font-bold" :class="done(s) ? 'bg-success text-white' : 'bg-gold/15 text-gold'">
              <svg v-if="done(s)" viewBox="0 0 24 24" class="size-4" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
              <template v-else>{{ i + 1 }}</template>
            </span>
            <span class="min-w-0 flex-1 text-sm" :class="done(s) ? 'text-text-muted line-through' : 'font-bold'">{{ $t(s.label) }}</span>
            <span v-if="!done(s)" aria-hidden="true" class="text-gold rtl:rotate-180">→</span>
          </button>
        </li>
    </CollapsibleContent>
  </CollapsibleRoot>
</template>
