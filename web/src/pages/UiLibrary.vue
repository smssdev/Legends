<script setup lang="ts">
// Sprint 11: the component library on a real club. Choose a league and a club; its badge,
// squad with values and room to grow, and the league's clubs by strength, all from the API.
import { computed, onMounted, ref, watch } from 'vue'
import { api, asApiError } from '../api/client'
import type { components } from '../api/schema'
import ClubCrest from '../components/ui/ClubCrest.vue'
import Coins from '../components/ui/Coins.vue'
import LineBadge from '../components/ui/LineBadge.vue'
import PlayerRow from '../components/ui/PlayerRow.vue'
import UiButton from '../components/ui/UiButton.vue'
import UiCard from '../components/ui/UiCard.vue'
import UiChip from '../components/ui/UiChip.vue'
import UiTable from '../components/ui/UiTable.vue'
import UiSlider from '../components/ui/UiSlider.vue'
import UiTooltip from '../components/ui/UiTooltip.vue'
import UiSelect from '../components/ui/UiSelect.vue'
import ConfirmDangerDialog from '../components/patterns/ConfirmDangerDialog.vue'
import AsyncState from '../components/ui/AsyncState.vue'
import CountdownChip from '../components/ui/CountdownChip.vue'
import MoneyPill from '../components/ui/MoneyPill.vue'
import NavItem from '../components/ui/NavItem.vue'
import PageTitle from '../components/ui/PageTitle.vue'
import Skeleton from '../components/ui/Skeleton.vue'
import UiDialog from '../components/ui/UiDialog.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiTabs from '../components/ui/UiTabs.vue'
import UiToggle from '../components/ui/UiToggle.vue'
import { setThemePref, theme } from '../lib/theme'
import { useToast } from '../stores/toast'
import { LINES, money, strength, type Line } from '../lib/format'

type Club = components['schemas']['DataClub']
type Player = components['schemas']['DataPlayer']
type Template = { name: string; clubs: number; top_strength_cp: number }

// [Sprint 30 Q1] The design system's headless primitives, each shown here before any screen uses it.
const sliderValue = ref(3)
const pickedLeague = ref('')
const dangerOpen = ref(false)
const toast = useToast()
// [Sprint 54 D3] Every component in every state, by night and by day, in both directions: the owner signs this page
// off before the screens move to it (Sprint 56).
const ltr = ref(false)
const typed = ref('')
const on = ref(true)
const segment = ref<'a' | 'b' | 'c'>('a')
const shortPick = ref('')
const dialogOpen = ref(false)
const soon = new Date(Date.now() + 3 * 3600_000 + 125_000).toISOString()
const templates = ref<Template[]>([])
const league = ref('Premier League')
const clubs = ref<Club[]>([])
const clubId = ref<number | null>(null)
const club = ref<(Club & { squad_value: number; players: Player[] }) | null>(null)
const tab = ref<'all' | Line>('all')
const error = ref('')

onMounted(async () => {
  try {
    const { data } = await api.GET('/data/templates')
    templates.value = (data?.templates ?? []) as Template[]
    if (!templates.value.some((t) => t.name === league.value) && templates.value[0]) league.value = templates.value[0].name
    await loadClubs()
  } catch (e) {
    error.value = asApiError(e).message
  }
})
watch(league, loadClubs)
watch(clubId, loadClub)

async function loadClubs() {
  const { data } = await api.GET('/data/clubs', { params: { query: { league: league.value } } })
  clubs.value = data?.clubs ?? []
  clubId.value = clubs.value[0]?.id ?? null
}
async function loadClub() {
  if (!clubId.value) return
  const { data } = await api.GET('/data/clubs/{club}', { params: { path: { club: clubId.value } } })
  club.value = data as typeof club.value
  tab.value = 'all'
}

const lines: Line[] = ['gk', 'def', 'mid', 'att']
const counts = computed(() => Object.fromEntries(lines.map((l) => [l, club.value?.players.filter((p) => p.line === l).length ?? 0])))
const shown = computed(() => (club.value?.players ?? []).filter((p) => tab.value === 'all' || p.line === tab.value))
const table = computed(() => clubs.value.map((c, i) => ({ rank: i + 1, ...c })))
</script>

<template>
  <div class="flex flex-col gap-5">
    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('مكتبة المكونات') }}</h1>
      <p class="mt-1 text-text-muted">{{ $t('مكونات نظام التصميم على نادٍ حقيقي من البيانات.') }}</p>
    </div>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <!-- [Sprint 54 D3] The binding design system, each component in each of its states. -->
    <div class="flex flex-wrap gap-2">
      <UiToggle :model-value="theme === 'light'" label="النهار" @update:model-value="(v: boolean) => setThemePref(v ? 'light' : 'dark')" />
      <UiToggle v-model="ltr" label="من اليسار إلى اليمين" />
    </div>
    <div class="flex flex-col gap-5" :dir="ltr ? 'ltr' : undefined">
      <PageTitle title="عنوان الصفحة" subtitle="سطر تحته يشرح ما فيها">
        <UiButton size="sm" variant="outline">{{ $t('إجراء') }}</UiButton>
      </PageTitle>
      <UiCard title="الأزرار بكل حالاتها">
        <div class="flex flex-wrap gap-2">
          <UiButton>primary</UiButton><UiButton variant="brand">brand</UiButton><UiButton variant="outline">outline</UiButton>
          <UiButton variant="quiet">quiet</UiButton><UiButton variant="danger">danger</UiButton>
        </div>
        <div class="flex flex-wrap gap-2">
          <UiButton disabled>{{ $t('معطّل') }}</UiButton><UiButton loading>{{ $t('جارٍ التحميل') }}</UiButton>
          <UiButton success>{{ $t('حُفظ.') }}</UiButton><UiButton size="sm">sm</UiButton><UiButton to="/dev/ui" variant="brand" size="sm">{{ $t('رابط') }}</UiButton>
        </div>
      </UiCard>
      <UiCard title="الحقول والاختيار">
        <div class="grid gap-4 md:grid-cols-2">
          <UiInput v-model="typed" label="الاسم" placeholder="اكتب هنا" hint="سطر مساعد تحت الحقل" />
          <UiInput model-value="x" label="البريد" type="email" error="البريد غير صالح" />
          <UiSelect v-model="shortPick" label="الخط" none="أي خط" :options="lines.map((l) => ({ value: l, label: $t(LINES[l].name) }))" />
          <UiToggle v-model="on" label="الإشعارات" hint="تصلك قبل المباراة بساعة" tone="success" />
        </div>
        <UiTabs v-model="segment" :items="[{ key: 'a', label: 'الأول', n: 3 }, { key: 'b', label: 'الثاني' }, { key: 'c', label: 'الثالث' }]" label="تبويبات" />
        <UiTabs v-model="segment" :items="[{ key: 'a', label: 'الأول' }, { key: 'b', label: 'الثاني' }, { key: 'c', label: 'الثالث' }]" label="تبويبات" tone="brand" fill size="sm" />
        <div><UiButton variant="outline" @click="dialogOpen = true">UiDialog</UiButton></div>
        <UiDialog :open="dialogOpen" title="نافذة" closable @close="dialogOpen = false">
          <p class="text-body">{{ $t('مكونات نظام التصميم على نادٍ حقيقي من البيانات.') }}</p>
          <div class="mt-4 flex gap-2"><UiButton class="flex-1" @click="dialogOpen = false">{{ $t('حُفظ.') }}</UiButton><UiButton class="flex-1" variant="quiet" @click="dialogOpen = false">{{ $t('إلغاء') }}</UiButton></div>
        </UiDialog>
      </UiCard>
      <UiCard title="الانتظار والفراغ والخطأ">
        <div class="grid gap-4 md:grid-cols-3">
          <AsyncState loading skeleton="row" :rows="3" />
          <AsyncState empty empty-title="لا شيء هنا بعد" empty-text="سطر يشرح ما سيأتي" />
          <AsyncState error="تعذّر الاتصال بالخادم." />
        </div>
        <div class="grid gap-4 md:grid-cols-3"><Skeleton /><Skeleton kind="card" :count="1" /><Skeleton kind="hero" :count="1" /></div>
      </UiCard>
      <UiCard title="الشريط العلوي">
        <div class="flex flex-wrap items-center gap-3">
          <MoneyPill kind="coins" to="/wallet" :value="1250" label="المحفظة" />
          <MoneyPill kind="cash" to="/finance" :value="3_400_000" caption="أموال النادي" label="أموال النادي" />
          <CountdownChip :to="soon" /><CountdownChip :to="soon" size="lg" /><CountdownChip :to="null" />
        </div>
        <nav class="flex flex-wrap" :aria-label="$t('أقسام')"><NavItem to="/dev/ui" icon="home" label="الرئيسية" active /><NavItem to="/club" icon="team" label="الفريق" /></nav>
      </UiCard>
    </div>

    <UiCard :title="$t('الأزرار والشارات')">
      <div class="flex flex-wrap gap-2">
        <UiButton>{{ $t('احفظ التشكيلة') }}</UiButton>
        <UiButton variant="outline">{{ $t('تحسين تلقائي') }}</UiButton>
        <UiButton variant="quiet">{{ $t('إلغاء') }}</UiButton>
        <UiButton variant="danger">{{ $t('حذف') }}</UiButton>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <UiChip tone="live">{{ $t('مباشر') }} <span class="font-numbers" dir="ltr">67'</span></UiChip>
        <UiChip><Coins :amount="1250" /></UiChip>
        <UiChip tone="win">{{ $t('فوز') }}</UiChip>
        <UiChip tone="draw">{{ $t('تعادل') }}</UiChip>
        <UiChip tone="loss">{{ $t('خسارة') }}</UiChip>
        <UiChip tone="gold">{{ $t('الحكم: صارم') }}</UiChip>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <LineBadge v-for="l in lines" :key="l" :line="l" full />
        <span class="text-sm text-text-muted">{{ $t('ألوان الخطوط تفرّق الخط فقط') }}</span>
      </div>
    </UiCard>

    <!-- [Sprint 30 Q1] The headless primitives, all on reka-ui since Sprint 54 W4. -->
    <UiCard :title="$t('المكونات الموحّدة')">
      <div class="grid gap-4 md:grid-cols-2">
        <div class="flex flex-col gap-1"><span class="text-sm font-bold">UiSlider</span>
          <UiSlider v-model="sliderValue" :min="1" :max="5" label="الضغط" :marks="['منخفض', 'متوسط', 'عالٍ']" /></div>
        <div class="flex flex-col gap-1"><span class="text-sm font-bold">UiSelect (Combobox)</span>
          <UiSelect v-model="pickedLeague" :options="templates.map((t) => ({ value: t.name, label: t.name }))" label="الدوري" searchable /></div>
        <div class="flex flex-wrap items-center gap-2"><span class="text-sm font-bold">UiTooltip</span>
          <UiTooltip text="القوة: متوسط أفضل 11 لاعباً"><button type="button" class="h-touch rounded-md bg-surface-raised px-3 font-numbers">85</button></UiTooltip></div>
        <div class="flex flex-wrap items-center gap-2">
          <UiButton variant="danger" @click="dangerOpen = true">ConfirmDangerDialog</UiButton>
          <UiButton variant="outline" @click="toast.show($t('حُفظ.'))">Toast</UiButton>
        </div>
      </div>
      <ConfirmDangerDialog :open="dangerOpen" title="حذف" expected="Liverpool" action="احذف" @close="dangerOpen = false" @confirm="dangerOpen = false" />
    </UiCard>

    <UiCard :title="$t('النادي')">
      <template #action>
        <div class="flex flex-wrap gap-2">
          <label class="sr-only" for="ui-league">{{ $t('الدوري') }}</label>
          <select id="ui-league" v-model="league" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
            <option v-for="t in templates" :key="t.name" :value="t.name">{{ t.name }} ({{ t.clubs }})</option>
          </select>
          <label class="sr-only" for="ui-club">{{ $t('النادي') }}</label>
          <select id="ui-club" v-model="clubId" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
            <option v-for="c in clubs" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </div>
      </template>
      <div class="flex gap-3 overflow-x-auto pb-1">
        <button v-for="c in clubs.slice(0, 10)" :key="c.id" type="button" class="shrink-0 rounded-xl p-2" :class="c.id === clubId ? 'bg-surface-raised ring-1 ring-gold/60' : ''" @click="clubId = c.id">
          <ClubCrest :url="c.crest_url" :code="c.code" :name="c.name" :size="52" />
        </button>
      </div>
    </UiCard>

    <section v-if="club" class="flex flex-col gap-3" aria-labelledby="h-squad">
      <div class="flex flex-wrap items-center gap-4">
        <ClubCrest :url="club.crest_url" :code="club.code" :size="64" />
        <div class="min-w-0 flex-1">
          <h2 id="h-squad" class="font-display text-2xl font-extrabold">{{ club.name }}</h2>
          <p class="text-text-muted">
            <span class="font-numbers text-base text-text">{{ club.players.length }}</span> {{ $t('لاعباً · القوة') }}
            <span class="font-numbers text-base text-gold">{{ strength(club.strength_cp) }}</span> {{ $t('· القيمة') }}
            <span class="font-numbers text-base text-text">{{ money(club.squad_value) }}</span>
          </p>
        </div>
      </div>
      <div role="tablist" :aria-label="$t('الخطوط')" class="flex gap-2 overflow-x-auto pb-1">
        <button type="button" role="tab" :aria-selected="tab === 'all'" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === 'all' ? 'bg-gold text-on-gold' : 'bg-surface'" @click="tab = 'all'">
          {{ $t('الكل') }} <span class="font-numbers">{{ club.players.length }}</span>
        </button>
        <button v-for="l in lines" :key="l" type="button" role="tab" :aria-selected="tab === l" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === l ? 'bg-gold text-on-gold' : 'bg-surface'" @click="tab = l">
          {{ $t(LINES[l].plural) }} <span class="font-numbers">{{ counts[l] }}</span>
        </button>
      </div>
      <div class="grid gap-2 lg:grid-cols-2">
        <PlayerRow v-for="p in shown" :key="p.id" :name="p.name" :line="p.line" :position="p.position" :age="p.age" :overall="p.overall" :potential="p.potential" :value="p.value" />
      </div>
    </section>

    <UiCard v-if="table.length" :title="$t('أندية {v0}', { v0: league })">
      <UiTable
        :rows="table"
        :caption="$t('أندية {v0} حسب القوة', { v0: league })"
        :columns="[{ key: 'rank', label: '#', numeric: true }, { key: 'name', label: $t('النادي') }, { key: 'code', label: $t('الرمز'), hideSm: true }, { key: 'strength_cp', label: $t('القوة'), numeric: true }]"
        :highlight="(r) => r.id === clubId"
      >
        <template #name="{ row }">
          <span class="flex items-center gap-2"><AppImage :src="row.crest_url" alt="" :width="24" :height="27" crest />{{ row.name }}</span>
        </template>
        <template #strength_cp="{ row }"><span class="text-gold">{{ strength(row.strength_cp) }}</span></template>
      </UiTable>
    </UiCard>
  </div>
</template>
