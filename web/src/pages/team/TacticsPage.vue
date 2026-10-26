<script setup lang="ts">
// Tactics (Sprint 17 W1), after the draft MobileTactics: the plan, three sliders, tackling, the positions
// of each line, the trap and marking, with tips in our own words. Tips explain how the engine plays them;
// they change no number [PLAN 2.14]. Only tackling, marking, plan and trap are ever shown to the opponent.
import UiToggle from '../../components/ui/UiToggle.vue'
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import TacticIcon from '../../components/tactics/TacticIcon.vue'
import HelpTip from '../../components/ui/HelpTip.vue'
import UiButton from '../../components/ui/UiButton.vue'
import ScenariosPanel from './ScenariosPanel.vue'
import { currentLeague } from '../../lib/currentLeague'

type T = Required<components['schemas']['TacticsSet']>
const leagueId = ref<number | null>(null)
const t = ref<T | null>(null)
const saved = ref('')
const tips = ref<string[]>([])
// What each part does, behind its "?" [X5].
const help = ref<Record<string, string>>({})
const referee = ref<string | null>(null)
const message = ref('')
const loaded = ref(false)
// The pre-match scenarios [X23], saved on their own.
const scenarios = ref<components['schemas']['Scenario'][] | null>(null)
const kinds = ref<components['responses']['Tactics']['content']['application/json']['scenario_kinds']>([])

const PLANS = { counter: 'هجوم مرتد', shots: 'تسديد عن بعد', long: 'كرات طويلة', passing: 'تمريرات', wings: 'لعب على الأجنحة' } as const
const TACKLING = ['قانوني', 'عادي', 'حماس', 'خشونة']
const SLIDERS = [
  { key: 'pressing', label: 'الضغط على الخصم', low: 'منخفض', high: 'عالٍ' },
  { key: 'style', label: 'الأسلوب', low: 'دفاعي', high: 'هجومي' },
  { key: 'tempo', label: 'إيقاع اللعب', low: 'هادئ', high: 'سريع' },
] as const
const LINES = [
  { key: 'att', label: 'الهجوم', color: 'bg-[#F08A3C]', options: { back: 'ارتداد', support: 'مساندة الوسط', only: 'هجوم فقط' } },
  { key: 'mid', label: 'الوسط', color: 'bg-[#22A35A]', options: { def: 'مساندة الدفاع', stay: 'بقاء', push: 'اندفاع' } },
  { key: 'def', label: 'الدفاع', color: 'bg-[#3B82F6]', options: { stay: 'بقاء', fullbacks: 'هجوم الظهيرين', mid: 'مساندة الوسط' } },
] as const
const REFEREE: Record<string, string> = { lenient: 'متساهل', medium: 'متوسط', strict: 'صارم' }
// [UP16] The icons of each choice, and the quick presets of the spec (10): each sets the knobs the engine plays with.
const PLAN_ICON: Record<string, string> = { counter: 'counter', shots: 'shots', long: 'long_balls', passing: 'tiki_taka', wings: 'wings' }
const MENTALITY = [
  { id: 'all_out', label: 'الهجوم الكاسح', style: 95 }, { id: 'attacking', label: 'هجومي', style: 75 }, { id: 'balanced', label: 'متوازن', style: 50 },
  { id: 'defensive', label: 'دفاعي', style: 25 }, { id: 'park_bus', label: 'ركن الحافلة', style: 5 },
] as const
const PASSING = [
  { id: 'short', label: 'قصيرة وسريعة', plan: 'passing', tempo: 40 }, { id: 'through', label: 'بينية في المساحة', plan: 'counter', tempo: 70 },
  { id: 'long', label: 'طولية وعالية', plan: 'long', tempo: 55 }, { id: 'direct', label: 'مباشرة', plan: 'long', tempo: 85 },
] as const
const PRESSING = [{ id: 'press_low', label: 'منخفض', value: 20 }, { id: 'press_mid', label: 'متوسط', value: 50 }, { id: 'press_high', label: 'خنق الخصم', value: 85 }] as const
const near = (a: number, b: number) => Math.abs(a - b) <= 10
const mentality = computed(() => MENTALITY.reduce((best, m) => (Math.abs(m.style - (t.value?.style ?? 50)) < Math.abs(best.style - (t.value?.style ?? 50)) ? m : best)).id)
const dirty = computed(() => !!t.value && JSON.stringify(t.value) !== saved.value)

async function load() {
  leagueId.value = await currentLeague()
  if (!leagueId.value) {
    loaded.value = true
    return
  }
  const { data } = await api.GET('/leagues/{league}/team/tactics', { params: { path: { league: leagueId.value } } })
  apply(data!)
  scenarios.value = data!.scenarios
  kinds.value = data!.scenario_kinds
  loaded.value = true
}
function apply(d: { tactics: components['schemas']['TacticsSet']; tips: string[]; referee?: string | null; help?: Record<string, string> }) {
  help.value = d.help ?? help.value
  t.value = { ...(d.tactics as T) }
  saved.value = JSON.stringify(t.value)
  tips.value = d.tips
  referee.value = d.referee ?? null
}
async function save() {
  if (!leagueId.value || !t.value) return
  message.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/tactics', { params: { path: { league: leagueId.value } }, body: t.value })
    apply(data!)
    message.value = 'حُفظ التكتيك.'
  } catch (e) {
    message.value = asApiError(e).message
  }
}
onMounted(() => load().catch((e) => ((message.value = asApiError(e).message), (loaded.value = true))))
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <div v-if="loaded && !leagueId" class="rounded-xl bg-surface p-8 text-center">
      <p class="mb-3 text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
      <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink>
    </div>
    <template v-else-if="t">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">{{ $t('التكتيك') }}</h1>
          <p class="text-sm text-text-muted">{{ $t('الحكم: {v0} · الضغط والأسلوب والإيقاع والتمركز لا يراها الخصم', { v0: referee ? REFEREE[referee] : $t('يُعيَّن قبل المباراة بنصف ساعة') }) }}</p>
        </div>
        <UiButton :disabled="!dirty" @click="save">{{ $t('حفظ') }}</UiButton>
      </header>
      <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>

      <section class="flex flex-col gap-2 rounded-xl border border-gold/30 bg-surface p-4" aria-labelledby="h-tips">
        <div class="flex flex-wrap items-center justify-between gap-x-2">
          <h2 id="h-tips" class="text-sm text-text-muted">{{ $t('الأثر المتوقع في المباراة{v0}', { v0: dirty ? $t(' (يتحدث بعد الحفظ)') : '' }) }}</h2>
          <HelpTip :text="help.tips" :label="$t('الأثر المتوقع')" />
        </div>
        <ul class="flex flex-col gap-1.5 text-sm">
          <li v-for="(tip, i) in tips" :key="i" class="rounded-lg bg-surface-sunk px-3 py-2">{{ tip }}</li>
        </ul>
      </section>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('العقلية') }}</legend>
        <div class="grid grid-cols-5 gap-1">
          <button v-for="m in MENTALITY" :key="m.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="mentality === m.id ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="mentality === m.id" @click="t.style = m.style">
            <TacticIcon :name="m.id" :active="mentality === m.id" />{{ $t(m.label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('أسلوب التمرير') }}</legend>
        <div class="grid grid-cols-4 gap-1">
          <button v-for="ps in PASSING" :key="ps.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="t.plan === ps.plan && near(t.tempo, ps.tempo) ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="t.plan === ps.plan && near(t.tempo, ps.tempo)"
            @click="t.plan = ps.plan; t.tempo = ps.tempo"><TacticIcon :name="ps.id" :active="t.plan === ps.plan && near(t.tempo, ps.tempo)" />{{ $t(ps.label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 font-bold">{{ $t('درجة الضغط') }}</legend>
        <div class="grid grid-cols-3 gap-1">
          <button v-for="pr in PRESSING" :key="pr.id" type="button" class="flex min-h-touch flex-col items-center gap-1 rounded-xl border px-1 py-2 text-xs font-bold"
            :class="near(t.pressing, pr.value) ? 'border-gold bg-surface-raised' : 'border-transparent bg-surface'" :aria-pressed="near(t.pressing, pr.value)" @click="t.pressing = pr.value">
            <TacticIcon :name="pr.id" :active="near(t.pressing, pr.value)" />{{ $t(pr.label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 flex w-full flex-wrap items-center gap-x-1 font-bold">{{ $t('خطة اللعب') }} <span class="text-xs font-normal text-text-muted">{{ $t('(يراها الخصم بعد القفل)') }}</span><HelpTip :text="help.plan" :label="$t('خطة اللعب')" /></legend>
        <div class="flex flex-wrap gap-2">
          <button v-for="(label, k) in PLANS" :key="k" type="button" class="flex h-12 items-center gap-2 rounded-xl border px-3 font-bold" :class="t.plan === k ? 'border-gold bg-surface-raised text-gold' : 'border-transparent bg-surface'" :aria-pressed="t.plan === k" @click="t.plan = k"><TacticIcon :name="PLAN_ICON[k]" :active="t.plan === k" />{{ $t(label) }}</button>
        </div>
      </fieldset>

      <section class="flex flex-col gap-4 rounded-xl bg-surface p-4">
        <div v-for="s in SLIDERS" :key="s.key" class="flex flex-col gap-1">
          <span class="flex flex-wrap items-center justify-between font-bold"><span class="flex items-center gap-1"><label :for="`t-${s.key}`">{{ $t(s.label) }}</label><HelpTip :text="help[s.key]" :label="s.label" /></span><span class="font-numbers text-2xl text-gold">{{ t[s.key] }}</span></span>
          <input :id="`t-${s.key}`" v-model.number="t[s.key]" type="range" min="0" max="100" step="5" class="accent-gold" />
          <span class="flex justify-between text-xs text-text-muted"><span>{{ s.low }}</span><span>{{ s.high }}</span></span>
        </div>
      </section>

      <fieldset>
        <legend class="mb-2 flex w-full flex-wrap items-center gap-x-1 font-bold">{{ $t('قطع الكرة') }} <span class="text-xs font-normal text-text-muted">{{ $t('(يراه الخصم بعد القفل)') }}</span><HelpTip :text="help.tackling" :label="$t('قطع الكرة')" /></legend>
        <div class="grid grid-cols-4 gap-1 rounded-xl bg-surface p-1">
          <button v-for="(label, i) in TACKLING" :key="i" type="button" class="flex min-h-14 flex-col items-center justify-center gap-0.5 rounded-lg text-xs font-bold" :class="t.tackling === i ? 'bg-surface-raised text-text' : 'text-text-soft'" :aria-pressed="t.tackling === i" @click="t.tackling = i"><TacticIcon :name="`tackle_${i}`" :active="t.tackling === i" />{{ $t(label) }}</button>
        </div>
      </fieldset>

      <fieldset class="flex flex-col gap-2">
        <legend class="mb-2 flex w-full flex-wrap items-center gap-x-1 font-bold">{{ $t('التمركز') }}<HelpTip :text="help.lines" :label="$t('التمركز')" /></legend>
        <div v-for="l in LINES" :key="l.key" class="flex items-center gap-2">
          <span class="flex w-20 shrink-0 items-center gap-1.5 text-sm"><span class="size-2.5 rounded-full" :class="l.color" />{{ $t(l.label) }}</span>
          <div class="grid flex-1 grid-cols-3 gap-1 rounded-xl bg-surface p-1">
            <button v-for="(label, k) in l.options" :key="k" type="button" class="flex min-h-14 flex-col items-center justify-center gap-0.5 rounded-lg px-1 text-xs font-bold" :class="t[l.key] === k ? 'bg-surface-raised text-text' : 'text-text-soft'" :aria-pressed="t[l.key] === k" @click="(t as Record<string, unknown>)[l.key] = k"><TacticIcon :name="`${l.key}_${k}`" :active="t[l.key] === k" />{{ $t(label) }}</button>
          </div>
        </div>
      </fieldset>

      <div class="grid gap-2 md:grid-cols-2">
        <div class="flex min-h-touch flex-wrap items-center justify-between gap-3 rounded-xl bg-surface p-3">
          <span class="flex items-center gap-1"><label for="t-trap"><span class="block font-bold">{{ $t('مصيدة التسلل') }}</span><span class="text-xs text-text-muted">{{ $t('يراها الخصم بعد القفل') }}</span></label><HelpTip :text="help.trap" :label="$t('مصيدة التسلل')" /></span>
          <span class="flex items-center gap-2"><TacticIcon :name="t.trap === 1 ? 'trap_on' : 'trap_off'" :active="true" />
          <UiToggle id="t-trap" tone="success" :label="$t('مصيدة التسلل')" class="[&_label]:sr-only" :model-value="t.trap === 1" @update:model-value="(on: boolean) => (t!.trap = on ? 1 : 0)" /></span>
        </div>
        <div class="flex flex-wrap items-center justify-between gap-3 rounded-xl bg-surface p-3">
          <span class="flex items-center gap-1"><span><span class="block font-bold">{{ $t('الرقابة') }}</span><span class="text-xs text-text-muted">{{ $t('يراها الخصم بعد القفل') }}</span></span><HelpTip :text="help.marking" :label="$t('الرقابة')" /></span>
          <div class="grid grid-cols-2 gap-1 rounded-lg bg-surface-sunk p-1">
            <button v-for="(label, k) in { zone: 'منطقة', man: 'رجل لرجل' }" :key="k" type="button" class="flex min-h-12 items-center gap-1 rounded-md px-2 text-sm font-bold" :class="t.marking === k ? 'bg-surface-raised text-text' : 'text-text-soft'" :aria-pressed="t.marking === k" @click="t.marking = k"><TacticIcon :name="k" :active="t.marking === k" />{{ $t(label) }}</button>
          </div>
        </div>
      </div>

      <ScenariosPanel v-if="leagueId && scenarios" :league-id="leagueId" :scenarios="scenarios" :kinds="kinds" />
    </template>
    <p v-else class="text-text-muted">{{ message || $t('جارٍ التحميل…') }}</p>
  </div>
</template>
