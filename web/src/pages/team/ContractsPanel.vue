<script setup lang="ts">
// [X61 E1] The squad's contracts this season: the wages a round against the cap, each player's wage, and ending a
// contract early for half the wages left (asked again in a window first).
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import UiButton from '../../components/ui/UiButton.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import { money } from '../../lib/format'
import { t } from '../../lib/i18n'
import { useToast } from '../../stores/toast'

type C = components['schemas']['Contracts']
const props = defineProps<{ leagueId: number }>()
const emit = defineEmits<{ changed: [] }>()
const c = ref<C | null>(null)
const ending = ref<C['players'][number] | null>(null)
const busy = ref(false)
const open = ref(false)
const toast = useToast()
const path = () => ({ params: { path: { league: props.leagueId } } })

async function load() {
  try { c.value = (await api.GET('/leagues/{league}/team/contracts', path())).data ?? null } catch (e) { toast.show(asApiError(e).message, 'error') }
}
async function end() {
  if (!ending.value) return
  busy.value = true
  try {
    await ensureCsrf()
    c.value = (await api.POST('/leagues/{league}/team/contracts/{player}/release', { params: { path: { league: props.leagueId, player: ending.value.id } } })).data ?? null
    toast.show(t('أنهيت عقد {v0}.', { v0: ending.value.name }))
    ending.value = null
    emit('changed')
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
  busy.value = false
}
onMounted(load)
</script>

<template>
  <section :aria-label="$t('العقود والرواتب')" class="flex flex-col gap-2 rounded-xl bg-surface p-4 text-sm">
    <h2 class="font-display text-lg font-bold">{{ $t('العقود والرواتب') }}</h2>
    <template v-if="c">
      <div class="flex justify-between"><span class="text-text-muted">{{ $t('الرواتب كل جولة') }}</span><b class="font-numbers" dir="ltr">{{ money(c.wages_per_round) }}</b></div>
      <div class="flex justify-between"><span class="text-text-muted">{{ $t('سقف الرواتب') }}</span><b class="font-numbers" dir="ltr">{{ money(c.cap_per_round) }}</b></div>
      <div class="h-2 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="Math.round((c.wages_per_round * 100) / Math.max(1, c.cap_per_round))" aria-valuemin="0" aria-valuemax="100">
        <div class="h-full rounded-full bg-gold transition-transform" :style="{ width: Math.min(100, (c.wages_per_round * 100) / Math.max(1, c.cap_per_round)) + '%' }" />
      </div>
      <p class="text-xs text-text-muted">{{ $t('تتسع لاعبين بقيمة {v0} قبل السقف، والعقود تنتهي بنهاية الموسم.', { v0: money(c.room) }) }}</p>
      <button type="button" class="min-h-touch rounded-lg bg-surface-sunk font-bold" :aria-expanded="open" @click="open = !open">{{ open ? $t('إخفاء العقود') : $t('عقود اللاعبين') }}</button>
      <ul v-if="open" class="flex flex-col">
        <li v-for="p in c.players" :key="p.id" class="flex min-h-touch items-center gap-2 border-t border-text/5 py-1">
          <span class="min-w-0 flex-1 truncate"><bdi>{{ $nm(p.name) }}</bdi> <span class="text-xs text-text-muted" dir="ltr">{{ p.position }}</span></span>
          <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.wage) }}</span>
          <button type="button" class="h-9 rounded-md px-2 text-xs font-bold text-danger hover:bg-live/10" @click="ending = p">{{ $t('إنهاء') }}</button>
        </li>
      </ul>
    </template>
    <UiDialog :open="!!ending" title="إنهاء عقد" @close="ending = null">
      <p v-if="ending" class="mb-3 text-sm">{{ $t('يغادر {v0} إلى السوق، وتدفع تعويضاً {v1} (نصف رواتبه الباقية هذا الموسم).', { v0: ending.name, v1: money(ending.release) }) }}</p>
      <div class="flex gap-2"><UiButton variant="danger" block :loading="busy" @click="end">{{ $t('أنهِ العقد') }}</UiButton><UiButton variant="quiet" @click="ending = null">{{ $t('إلغاء') }}</UiButton></div>
    </UiDialog>
  </section>
</template>
