<script setup lang="ts">
// The pre-match scenarios [X23]: up to three plans the server carries out at their moment, even when the
// coach is away: trailing from a minute, a red card against us, holding a lead from a minute. Each changes
// the pressing, the tempo or the style and may make one substitution. The rival never sees them.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import UiButton from '../../components/ui/UiButton.vue'
import UiToggle from '../../components/ui/UiToggle.vue'
import type { Team } from './team'

type Scenario = components['schemas']['Scenario']
type Kind = { kind: 'trailing' | 'red_card' | 'leading'; minute: { default: number; min: number; max: number } | null }
const props = defineProps<{ leagueId: number; scenarios: Scenario[]; kinds: Kind[] }>()

const KIND = {
  trailing: { title: 'إن تأخرنا', hint: 'من الدقيقة', icon: '⬇' },
  red_card: { title: 'إن طُرد لاعب منا', hint: 'فوراً', icon: '🟥' },
  leading: { title: 'إن تقدمنا', hint: 'لتأمين النتيجة من الدقيقة', icon: '⬆' },
} as const
const SLIDERS = [
  { key: 'pressing', label: 'الضغط' },
  { key: 'tempo', label: 'الإيقاع' },
  { key: 'style', label: 'الأسلوب' },
] as const
type Key = (typeof SLIDERS)[number]['key']

type Row = { on: boolean; minute: number; tactics: Partial<Record<Key, number>>; out: number | null; in: number | null }
const rows = ref<Record<string, Row>>({})
const saved = ref('')
const message = ref('')
const team = ref<Team | null>(null)

function apply(list: Scenario[]) {
  rows.value = Object.fromEntries(
    props.kinds.map((k) => {
      const s = list.find((x) => x.kind === k.kind)
      return [k.kind, { on: !!s, minute: s?.minute ?? k.minute?.default ?? 0, tactics: { ...(s?.tactics ?? {}) }, out: s?.sub?.out ?? null, in: s?.sub?.in ?? null }]
    }),
  )
  saved.value = JSON.stringify(rows.value)
}
apply(props.scenarios)
const dirty = computed(() => JSON.stringify(rows.value) !== saved.value)

onMounted(async () => {
  const { data } = await api.GET('/leagues/{league}/team', { params: { path: { league: props.leagueId } } })
  team.value = data as Team
})
const players = computed(() => new Map((team.value?.players ?? []).map((p) => [p.id, p])))
const starters = computed(() => (team.value?.lineup.starters ?? []).filter((id): id is number => !!id))
const bench = computed(() => team.value?.lineup.bench ?? [])

function toggleSlider(r: Row, key: Key, on: boolean) {
  if (on) r.tactics[key] = 50
  else delete r.tactics[key]
}

async function save() {
  message.value = ''
  const body = props.kinds.flatMap((k) => {
    const r = rows.value[k.kind]
    if (!r.on) return []
    return [{ kind: k.kind, minute: k.minute ? r.minute : null, tactics: r.tactics, sub: r.out && r.in ? { out: r.out, in: r.in } : null }]
  })
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/scenarios', { params: { path: { league: props.leagueId } }, body: { scenarios: body } })
    apply(data!.scenarios)
    message.value = 'حُفظت السيناريوهات.'
  } catch (e) {
    message.value = asApiError(e).message
  }
}
</script>

<template>
  <section class="flex flex-col gap-3" aria-labelledby="h-scenarios">
    <div class="flex items-start justify-between gap-3">
      <div>
        <h2 id="h-scenarios" class="font-display text-2xl font-extrabold">السيناريوهات</h2>
        <p class="text-sm text-text-muted">خطط تُنفَّذ وحدها في لحظتها، حتى لو لم تكن تتابع المباراة. لا يراها الخصم.</p>
      </div>
      <UiButton :disabled="!dirty" @click="save">حفظ</UiButton>
    </div>
    <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ message }}</p>

    <article v-for="k in kinds" :key="k.kind" class="flex flex-col gap-3 rounded-xl bg-surface p-4" :class="rows[k.kind].on ? 'ring-1 ring-gold/40' : ''">
      <div class="flex items-center justify-between gap-3">
        <span class="flex items-center gap-2 font-bold"><span aria-hidden="true">{{ KIND[k.kind].icon }}</span>{{ KIND[k.kind].title }}</span>
        <UiToggle :id="`sc-${k.kind}`" tone="success" :label="KIND[k.kind].title" class="[&_label]:sr-only" :model-value="rows[k.kind].on" @update:model-value="(on: boolean) => (rows[k.kind].on = on)" />
      </div>
      <template v-if="rows[k.kind].on">
        <label v-if="k.minute" class="flex flex-col gap-1">
          <span class="flex justify-between text-sm"><span>{{ KIND[k.kind].hint }}</span><span class="font-numbers text-xl font-bold text-gold" dir="ltr">{{ rows[k.kind].minute }}'</span></span>
          <input v-model.number="rows[k.kind].minute" type="range" :min="k.minute.min" :max="k.minute.max" step="1" class="accent-gold" />
        </label>
        <p v-else class="text-sm text-text-muted">{{ KIND[k.kind].hint }}</p>

        <div v-for="s in SLIDERS" :key="s.key" class="flex flex-col gap-1">
          <span class="flex min-h-touch items-center justify-between gap-2">
            <UiToggle :id="`sc-${k.kind}-${s.key}`" :label="s.label" :model-value="rows[k.kind].tactics[s.key] !== undefined" @update:model-value="(on: boolean) => toggleSlider(rows[k.kind], s.key, on)" />
            <span v-if="rows[k.kind].tactics[s.key] !== undefined" class="font-numbers text-xl font-bold text-gold">{{ rows[k.kind].tactics[s.key] }}</span>
            <span v-else class="text-sm text-text-muted">بلا تغيير</span>
          </span>
          <input v-if="rows[k.kind].tactics[s.key] !== undefined" v-model.number="rows[k.kind].tactics[s.key]" type="range" min="0" max="100" step="5" class="accent-gold" :aria-label="s.label" />
        </div>

        <div class="grid grid-cols-2 gap-2">
          <label class="flex flex-col gap-1 text-sm">يخرج
            <select v-model="rows[k.kind].out" class="h-12 rounded-lg bg-surface-sunk px-2">
              <option :value="null">بلا تبديل</option>
              <option v-for="id in starters" :key="id" :value="id">{{ $nm(players.get(id)?.name) }}</option>
            </select>
          </label>
          <label class="flex flex-col gap-1 text-sm">يدخل
            <select v-model="rows[k.kind].in" class="h-12 rounded-lg bg-surface-sunk px-2" :disabled="!rows[k.kind].out">
              <option :value="null">—</option>
              <option v-for="id in bench" :key="id" :value="id">{{ $nm(players.get(id)?.name) }}</option>
            </select>
          </label>
        </div>
      </template>
    </article>
  </section>
</template>
