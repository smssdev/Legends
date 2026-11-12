<template>
  <!-- [Sprint 57 W2] The coach's commands in a match: quick orders, substitutions, tactics and formation, the orders
       waiting for their minute and applied, and (league) the assistant's readings. -->
  <section id="coach" class="flex scroll-mt-3 flex-col gap-3 rounded-xl bg-surface p-3" :aria-label="$t('لوحة المدرب')">
    <div class="flex items-center gap-2">
      <h2 class="flex-1 font-display text-base font-bold">{{ $t('لوحة المدرب') }}<span v-if="mine"> · {{ $nm(view.clubs[mine].name) }}</span></h2>
      <span v-if="isLive && mine" class="rounded-pill bg-surface-sunk px-2 py-1 text-xs text-text-muted">{{ $t('تكتيك {v0} سري', { v0: $nm(view.clubs[mine === 'home' ? 'away' : 'home'].name) }) }}</span>
      <div v-if="!isLive && view.control.home === 'me' && view.control.away === 'me'" class="flex gap-1 rounded-md bg-surface-sunk p-1">
        <button v-for="s in (['home', 'away'] as const)" :key="s" type="button" class="h-9 rounded-sm px-2 text-xs font-bold" :class="mine === s ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="emit('choose', s)">{{ view.clubs[s].code }}</button>
      </div>
      <span v-if="mine" class="text-xs text-text-muted">{{ $t('التبديلات') }} <b class="font-numbers text-base text-text" dir="ltr">{{ teams[mine].subs_used }}/{{ teams[mine].subs_max }}</b></span>
    </div>

    <p v-if="!mine" class="text-sm text-text-muted">{{ isLive ? $t('أنت تشاهد فقط: كل مدرب يدير فريقه من جهازه.') : $t('الحاسوب يدير الفريقين. اختر "أنا" لأحدهما في شاشة الإعداد لتديره.') }}</p>

    <template v-else>
      <p v-if="!canChange && !finished" class="rounded-md bg-surface-sunk px-3 py-2 text-xs leading-5 text-text-muted" role="status">{{ $t('التغيير في فترات التوقف فقط: الدقائق 15 و30 و60 و75 والاستراحة.') }}<span v-if="nextWindow"> {{ $t('القادمة:') }} <b class="font-numbers text-text">{{ nextWindow }}</b>'</span></p>
      <div role="tablist" class="grid grid-cols-4 gap-1 rounded-md bg-surface-sunk p-1">
        <button v-for="t in TABS" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="h-10 rounded-sm text-sm font-bold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">{{ $t(t.label) }}</button>
      </div>

      <div v-if="tab === 'quick'" class="grid grid-cols-2 gap-2">
        <button v-for="q in quickOrders" :key="q.label" type="button" class="flex min-h-16 flex-col gap-0.5 rounded-md border border-text/10 bg-surface-sunk px-3 py-2 text-start hover:border-gold disabled:opacity-40 disabled:hover:border-text/10" :disabled="finished || !canChange" @click="orders.sendTactics(q.label, q.tactics)">
          <span class="font-display text-sm font-bold">{{ $t(q.label) }}</span>
          <span class="text-xs leading-5 text-text-muted">{{ $t(q.hint) }}</span>
        </button>
      </div>

      <div v-if="tab === 'subs'" class="flex flex-col gap-2">
        <span class="text-xs text-text-muted">{{ subOut ? $t('اختر البديل') : $t('اختر من يخرج (الأقل لياقة أولاً)') }}</span>
        <button v-for="p in subOut ? bench : onPitch" :key="p.id" type="button" :disabled="!canChange" class="flex min-h-11 items-center gap-2 rounded-md px-2 disabled:opacity-40" :class="subOut?.id === p.id ? 'bg-warning/15' : 'bg-surface-sunk hover:bg-surface-raised'" @click="subOut ? orders.sendSub(p) : (subOut = p)">
          <span class="w-8 rounded-sm px-1 text-center text-xs font-bold" :class="lineClass(p.line)">{{ p.pos }}</span>
          <span class="flex-1 truncate text-start text-sm">{{ $nm(p.name) }}</span>
          <span v-if="p.yc" class="h-3.5 w-2.5 rounded-[2px] bg-card-yellow" :aria-label="$t('بطاقة صفراء')" />
          <span class="w-12 text-start font-numbers" :class="fitClass(p.fit)">{{ subOut ? p.ovr : p.fit + '%' }}</span>
        </button>
        <button v-if="subOut" type="button" class="h-10 rounded-md bg-surface-raised text-sm" @click="subOut = null">{{ $t('رجوع') }}</button>
      </div>

      <div v-if="tab === 'tactics'" class="flex flex-col gap-3 text-sm">
        <label class="flex items-center justify-between gap-2">{{ $t('خطة اللعب') }}
          <select v-model="draft.plan" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="p in PLANS" :key="p.v" :value="p.v">{{ $t(p.label) }}</option></select>
        </label>
        <label class="flex items-center justify-between gap-2">{{ $t('قطع الكرة') }}
          <select v-model.number="draft.tackling" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="(t, i) in TACKLES" :key="t" :value="i">{{ t }}</option></select>
        </label>
        <label v-for="k in (['pressing', 'style', 'tempo'] as const)" :key="k" class="flex flex-col gap-1">
          <span class="flex justify-between"><span>{{ SLIDERS[k] }}</span><b class="font-numbers text-gold">{{ draft[k] }}</b></span>
          <UiSlider v-model="draft[k]" :label="SLIDERS[k]" />
        </label>
        <label v-for="l in (['att', 'mid', 'def'] as const)" :key="l" class="flex items-center justify-between gap-2">{{ LINE_NAMES[l] }}
          <select v-model="draft[l]" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="o in POSITIONING[l]" :key="o.v" :value="o.v">{{ $t(o.label) }}</option></select>
        </label>
        <div class="flex gap-2">
          <UiToggle v-model="draftTrap" class="flex-1" :label="$t('مصيدة التسلل')" />
          <UiToggle v-model="draftMan" class="flex-1" :label="$t('رقابة رجل لرجل')" />
        </div>
        <button type="button" class="h-11 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="finished || !canChange" @click="orders.applyDraft">{{ $t('طبّق في الدقيقة التالية') }}</button>
      </div>

      <div v-if="tab === 'shape'" class="flex flex-wrap gap-2">
        <button v-for="f in view.formations" :key="f" type="button" class="h-11 rounded-md border px-3 font-numbers text-lg disabled:opacity-40" :class="teams[mine].formation === f ? 'border-gold bg-gold/15 text-gold' : 'border-text/10 bg-surface-sunk'" dir="ltr" :disabled="finished || !canChange" @click="orders.sendFormation(f)">{{ formationLabel(f) }}</button>
      </div>

      <div v-for="o in pending" :key="o.key" class="flex items-center gap-3 rounded-lg border border-gold/45 bg-gold/10 px-3 py-2 text-sm">
        <span class="flex-1"><b>{{ $t(o.label) }}</b></span><span class="text-gold">{{ minute[0] === 0 ? $t('يُطبق مع صافرة البداية') : $t('يُطبق في الدقيقة القادمة') }}</span>
      </div>
      <div v-for="o in applied" :key="o.key" class="rounded-lg border border-success/50 bg-success/15 px-3 py-2 text-sm"><b>{{ $t(o.label) }}</b> {{ $t('طُبّق في الدقيقة {v0}', { v0: o.minute }) }}</div>
      <div v-for="r in rejected" :key="r" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger">{{ r }}</div>
    </template>
  </section>
  <section v-if="league && mine" class="flex max-h-[260px] flex-col gap-2 overflow-y-auto rounded-xl bg-surface p-3" :aria-label="$t('قراءة المساعد')" aria-live="polite">
    <h2 class="flex items-center gap-2 font-display text-base font-bold"><Character model="B2" :mood="moods[mine]" class="w-10" />{{ $t('قراءة المساعد') }}</h2>
    <p v-if="!readings.length" class="text-sm text-text-muted">{{ $t('يكتب لك المساعد ملاحظة كل ربع ساعة تقريباً، وبعد كل لحظة كبيرة.') }}</p>
    <div v-for="r in readings" :key="r.id" class="flex gap-3 rounded-md bg-surface-sunk px-3 py-2 text-sm" :class="r.kind.startsWith('goal') || r.kind.startsWith('red') ? 'border-s-2 border-gold' : ''">
      <span class="w-8 shrink-0 font-numbers text-base text-gold">{{ r.minute }}'</span>
      <span>{{ $t(r.text) }}</span>
    </div>
  </section>
</template>

<script setup lang="ts">
import UiSlider from '../ui/UiSlider.vue'
import UiToggle from '../ui/UiToggle.vue'
import Character from '../characters/Character.vue'
import type { MatchView, Reading, Side } from '../../api/sim'
import type { MatchPlayer } from '../../match/useMatchPlayer'
import { LINE_NAMES, PLANS, POSITIONING, SLIDERS, TABS, TACKLES, formationLabel, type CoachOrders } from '../../match/useCoachOrders'

const props = defineProps<{ player: MatchPlayer; orders: CoachOrders; view: MatchView; mine: Side | null; league: boolean; canChange: boolean; nextWindow: number | null; readings: Reading[] }>()
const emit = defineEmits<{ choose: [side: Side] }>()
const { teams, finished, minute, moods, live: isLive } = props.player
const { tab, quickOrders, draft, draftTrap, draftMan, onPitch, bench, subOut, pending, applied, rejected } = props.orders
const lineClass = (l: string) => ({ gk: 'bg-line-gk text-line-gk-fg', def: 'bg-line-def text-line-def-fg', mid: 'bg-line-mid text-line-mid-fg', att: 'bg-line-att text-line-att-fg' })[l] ?? ''
const fitClass = (f: number) => (f >= 75 ? 'text-success' : f >= 60 ? 'text-gold' : 'text-warning')
</script>
