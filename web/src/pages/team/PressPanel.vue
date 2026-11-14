<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// [UP12] The press conference before my match (the owner's spec 6): the chances of each side, a reading of where each
// is strong and weak, and my one statement (it lifts my team's morale in this match). It opens half an hour before.
import { intlLocale, t } from '../../lib/i18n'
import { act, busy } from '../../lib/action'
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'

const props = defineProps<{ leagueId: number; fixtureId: number; home: string; away: string }>()
type Press = { open: boolean; opens_at: string; chances: { home: number; draw: number; away: number }; reading: { home: string; away: string };
  statements: { kind: string; text: string; stakes?: Record<'win' | 'draw' | 'loss', number> }[]; said: { home: string | null; away: string | null }; mine: 'home' | 'away' | null; morale: number }
const press = ref<Press | null>(null)
const enabled = ref(true)
const error = ref('')
const path = () => ({ params: { path: { league: props.leagueId, fixture: props.fixtureId } } })

async function load() {
  try {
    const data = (await api.GET('/leagues/{league}/press/{fixture}', path())).data as any
    press.value = data.press
    enabled.value = data.enabled
  } catch (e) {
    error.value = asApiError(e).message
  }
}
// [X92] Through lib/action: one statement a match and it stakes on the result, so it asks first.
async function say(st: Press['statements'][number]) {
  const r = await act('press', () => api.POST('/leagues/{league}/press/{fixture}', { ...path(), body: { kind: st.kind as 'calm' } }), {
    confirm: { title: t('تعتمد هذا التصريح؟'), text: `«${t(st.text)}» · ${t('تصريح واحد للمباراة، ولا يتغير بعده.')}`, action: t('اعتمده'), tone: 'gold' },
    success: t('سُجّل تصريحك، ومعنويات لاعبيك أعلى في هذه المباراة.'),
  })
  if (r?.data) press.value = (r.data as any).press
}
const time = (iso: string) => new Date(iso).toLocaleTimeString(intlLocale(), { hour: 'numeric', minute: '2-digit' })
onMounted(load)
</script>

<template>
  <section v-if="press && enabled" class="flex flex-col gap-3 rounded-xl border border-brand/40 ui-card p-4" aria-labelledby="h-press">
    <h2 id="h-press" class="font-display text-xl font-extrabold"><Icon name="mic" :size="16" class="inline-block align-[-3px]" /> {{ $t('المؤتمر الصحفي') }}</h2>
    <div class="flex h-8 overflow-hidden rounded-lg text-xs font-bold" role="img" :aria-label="$t('ترجيح الفوز: {v0} {v1}٪، التعادل {v2}٪، {v3} {v4}٪', { v0: home, v1: press.chances.home, v2: press.chances.draw, v3: away, v4: press.chances.away })">
      <span class="flex items-center justify-center bg-brand text-on-gold" :style="{ width: press.chances.home + '%' }">{{ press.chances.home }}%</span>
      <span class="flex items-center justify-center bg-surface-raised" :style="{ width: press.chances.draw + '%' }">{{ press.chances.draw }}%</span>
      <span class="flex items-center justify-center bg-gold text-on-gold" :style="{ width: press.chances.away + '%' }">{{ press.chances.away }}%</span>
    </div>
    <div class="grid gap-2 text-sm md:grid-cols-2">
      <p><b><bdi>{{ $nm(home) }}</bdi>:</b> {{ press.reading.home }}</p>
      <p><b><bdi>{{ $nm(away) }}</bdi>:</b> {{ press.reading.away }}</p>
    </div>
    <template v-if="press.mine">
      <p v-if="press.said[press.mine]" class="rounded-lg bg-success/15 px-3 py-2 text-sm text-success" role="status">
        تصريحك: «{{ press.statements.find((s) => s.kind === press!.said[press!.mine!])?.text }}» · +{{ press.morale }}% معنويات للاعبيك في هذه المباراة
      </p>
      <template v-else-if="press.open">
        <p class="text-sm font-bold">{{ $t('اختر تصريحك الرسمي قبل المباراة:') }}</p>
        <button v-for="s in press.statements" :key="s.kind" type="button" class="min-h-touch rounded-lg bg-surface-sunk px-3 py-2 text-start text-sm hover:bg-surface-raised disabled:opacity-40" :disabled="busy('press')" @click="say(s)">«{{ $t(s.text) }}»
          <!-- [X61 E9] What it stakes on the result. -->
          <span v-if="s.stakes" class="mt-1 flex flex-wrap gap-x-3 font-numbers text-xs" dir="ltr">
            <span v-for="(v, k) in { win: 'فوز', draw: 'تعادل', loss: 'خسارة' }" :key="k" :class="s.stakes[k] > 0 ? 'text-success' : s.stakes[k] < 0 ? 'text-danger' : 'text-text-muted'">{{ $t(v) }} {{ s.stakes[k] > 0 ? '+' : '' }}{{ s.stakes[k] }}</span>
          </span></button>
      </template>
      <p v-else class="text-sm text-text-muted">{{ $t('يُعقد المؤتمر الساعة {v0}', { v0: time(press.opens_at) }) }}</p>
    </template>
    <p v-if="error" class="text-sm text-danger" role="alert">{{ $t(error) }}</p>
  </section>
</template>
