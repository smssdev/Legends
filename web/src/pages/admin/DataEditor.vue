<script setup lang="ts">
// [X62 E8] The game's data editor (the owner's decision 2026-10-30): search players or clubs of the latest data,
// correct a field, add a player or a club, remove a player no league took; the data's leagues with those under six
// clubs flagged. Every change is logged on the server (data_edits).
import { onMounted, reactive, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiButton from '../../components/ui/UiButton.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import UiTabs from '../../components/ui/UiTabs.vue'
import ConfirmDangerDialog from '../../components/patterns/ConfirmDangerDialog.vue'
import { money } from '../../lib/format'
import { t } from '../../lib/i18n'
import { useToast } from '../../stores/toast'

type Row = Record<string, any>
const kind = ref<'players' | 'clubs'>('players')
const q = ref('')
const rows = ref<Row[]>([])
const leagues = ref<{ name: string; clubs: number; too_small: boolean }[]>([])
const editing = ref<Row | null>(null)
const creating = ref(false)
const form = reactive<Row>({})
const busy = ref(false)
const toast = useToast()
const PLAYER = ['name', 'position', 'line', 'age', 'nationality', 'overall', 'potential', 'value', 'master_club_id'] as const
const CLUB = ['name', 'code', 'league_name', 'color_primary', 'color_secondary', 'kit_pattern'] as const
// [X76] The kit's pattern, in the club's two colours (none set is plain).
const PATTERNS = [['plain', 'سادة'], ['stripes', 'خطوط طولية'], ['hoops', 'خطوط عرضية'], ['halves', 'نصفان'], ['sash', 'حزام مائل']]
const NUM = ['age', 'overall', 'potential', 'value', 'master_club_id']
const LABEL: Record<string, string> = { name: 'الاسم', position: 'المركز', line: 'الخط', age: 'العمر', nationality: 'الجنسية', overall: 'القوة', potential: 'الإمكانية',
  value: 'القيمة', master_club_id: 'رقم النادي', code: 'الرمز', league_name: 'الدوري', color_primary: 'اللون الأول', color_secondary: 'اللون الثاني', kit_pattern: 'نقش القميص' }
const fields = () => (kind.value === 'players' ? PLAYER : CLUB)

async function search() {
  try { rows.value = (await api.GET('/admin/data', { params: { query: { kind: kind.value, q: q.value || undefined } } })).data!.rows } catch (e) { toast.show(asApiError(e).message, 'error') }
}
function open(row: Row | null) {
  for (const k of Object.keys(form)) delete form[k]
  for (const f of fields()) form[f] = row ? row[f] ?? (f === 'kit_pattern' ? 'plain' : '') : f === 'line' ? 'mid' : f === 'kit_pattern' ? 'plain' : ''
  editing.value = row
  creating.value = !row
}
async function save() {
  busy.value = true
  const body: Row = {}
  for (const f of fields()) {
    if (form[f] === '' || form[f] === null) continue
    if (editing.value && String(editing.value[f] ?? (f === 'kit_pattern' ? 'plain' : '')) === String(form[f])) continue
    body[f] = NUM.includes(f) ? Number(form[f]) : form[f]
  }
  try {
    await ensureCsrf()
    const one = kind.value === 'players' ? 'players' : 'clubs'
    if (editing.value) await api.PATCH(`/admin/data/${one}/{id}` as '/admin/data/players/{id}', { params: { path: { id: editing.value.id } }, body: body as never })
    else await api.POST(`/admin/data/${one}` as '/admin/data/players', { body: body as never })
    toast.show(t('حُفظ التعديل وسُجّل.'))
    editing.value = null
    creating.value = false
    await Promise.all([search(), loadLeagues()])
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
  busy.value = false
}
// [Sprint 30 P2] Never at one tap: the player's name is typed first, here and on the server.
const removing = ref<Row | null>(null)
async function remove() {
  const row = removing.value
  if (!row) return
  busy.value = true
  try {
    await ensureCsrf()
    await api.DELETE('/admin/data/players/{id}', { params: { path: { id: row.id }, query: { confirm: row.name } } })
    toast.show(t('حُذف اللاعب.'))
    removing.value = null
    await search()
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
  busy.value = false
}
async function loadLeagues() {
  try { leagues.value = (await api.GET('/admin/data/leagues')).data!.leagues } catch {}
}
onMounted(() => Promise.all([search(), loadLeagues()]))
</script>

<template>
  <section class="flex flex-col gap-3" :aria-label="$t('محرر البيانات')">
    <div class="flex flex-wrap items-center gap-2">
      <UiTabs :model-value="kind" :items="[{ key: 'players', label: 'اللاعبون' }, { key: 'clubs', label: 'الأندية' }]" label="محرر البيانات" size="sm" @update:model-value="(v) => { kind = v as 'players' | 'clubs'; search() }" />
      <form class="flex min-w-0 flex-1 gap-2" @submit.prevent="search">
        <input v-model="q" dir="auto" class="h-11 min-w-0 flex-1 rounded-lg bg-surface-sunk px-3" :placeholder="$t('ابحث بالاسم')" :aria-label="$t('ابحث بالاسم')" />
        <button type="submit" class="h-11 rounded-lg bg-surface-raised px-4 font-bold">{{ $t('ابحث') }}</button>
      </form>
      <UiButton variant="outline" @click="open(null)">{{ kind === 'players' ? $t('لاعب جديد') : $t('نادٍ جديد') }}</UiButton>
    </div>
    <ul class="flex flex-col rounded-xl bg-surface p-2">
      <li v-for="r in rows" :key="r.id" class="flex min-h-touch items-center gap-2 border-t border-text/5 px-2 text-sm first:border-0">
        <span class="w-12 font-numbers text-xs text-text-muted" dir="ltr">#{{ r.id }}</span>
        <span class="min-w-0 flex-1 truncate"><b><bdi>{{ r.name }}</bdi></b> <span class="text-xs text-text-muted">{{ kind === 'players' ? `${r.position} · ${r.age} · ${r.club}` : r.league_name }}</span></span>
        <span v-if="kind === 'players'" class="font-numbers" dir="ltr">{{ r.overall }}/{{ r.potential }} · {{ money(r.value) }}</span>
        <button type="button" class="h-9 rounded-md px-2 text-xs font-bold text-gold hover:bg-gold/10" @click="open(r)">{{ $t('تعديل') }}</button>
        <button v-if="kind === 'players'" type="button" class="h-9 rounded-md px-2 text-xs font-bold text-danger hover:bg-live/10" @click="removing = r">{{ $t('حذف') }}</button>
      </li>
      <li v-if="!rows.length" class="p-3 text-sm text-text-muted">{{ $t('لا نتائج') }}</li>
    </ul>
    <section class="rounded-xl bg-surface p-3" :aria-label="$t('دوريات البيانات')">
      <h3 class="mb-2 font-bold">{{ $t('دوريات البيانات') }}</h3>
      <div class="flex flex-wrap gap-1.5">
        <span v-for="l in leagues" :key="l.name" class="rounded-pill px-2.5 py-1 text-xs" :class="l.too_small ? 'bg-live/15 text-danger' : 'bg-surface-sunk'">{{ l.name }} · <b class="font-numbers">{{ l.clubs }}</b></span>
      </div>
      <p class="mt-2 text-xs text-text-muted">{{ $t('الأحمر أقل من 6 أندية: لا يظهر في «أنشئ دورياً» حتى يكتمل.') }}</p>
    </section>
    <UiDialog :open="!!editing || creating" :title="editing ? 'تعديل' : kind === 'players' ? 'لاعب جديد' : 'نادٍ جديد'" @close="editing = null; creating = false">
      <form class="grid grid-cols-2 gap-2" @submit.prevent="save">
        <label v-for="f in fields()" :key="f" class="flex flex-col gap-1 text-xs text-text-muted" :class="f === 'name' ? 'col-span-2' : ''">{{ $t(LABEL[f]) }}
          <select v-if="f === 'line'" v-model="form[f]" class="h-11 rounded-md bg-surface-sunk px-2 text-text"><option v-for="l in ['gk', 'def', 'mid', 'att']" :key="l" :value="l">{{ l }}</option></select>
          <select v-else-if="f === 'kit_pattern'" v-model="form[f]" class="h-11 rounded-md bg-surface-sunk px-2 text-text"><option v-for="[v, l] in PATTERNS" :key="v" :value="v">{{ $t(l) }}</option></select>
          <input v-else v-model="form[f]" :type="NUM.includes(f) ? 'number' : 'text'" class="h-11 rounded-md bg-surface-sunk px-2 text-sm text-text" :dir="f === 'name' ? 'auto' : 'ltr'" />
        </label>
        <div class="col-span-2 mt-2 flex gap-2"><UiButton type="submit" block :loading="busy">{{ $t('احفظ') }}</UiButton><UiButton variant="quiet" @click="editing = null; creating = false">{{ $t('إلغاء') }}</UiButton></div>
      </form>
    </UiDialog>
    <ConfirmDangerDialog :open="!!removing" title="حذف لاعب" :expected="removing?.name ?? ''" action="احذف اللاعب نهائياً" :busy="busy"
      text="يُحذف من بيانات اللعبة ولا يعود، ويُسجّل الحذف. ولا يُحذف لاعب أخذه دوري قائم." @close="removing = null" @confirm="remove" />
  </section>
</template>
