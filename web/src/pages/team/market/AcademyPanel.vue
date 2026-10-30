<script setup lang="ts">
// [X61 E3] The youth academy: this period's prospects with their potential as a range (the true one after signing),
// their price, and the season's signings out of the limit.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../../api/client'
import type { components } from '../../../api/schema'
import EmptyState from '../../../components/ui/EmptyState.vue'
import LineBadge from '../../../components/ui/LineBadge.vue'
import UiButton from '../../../components/ui/UiButton.vue'
import { countdown, useNow } from '../../../lib/clock'
import { money, type Line } from '../../../lib/format'
import { t } from '../../../lib/i18n'
import { useToast } from '../../../stores/toast'

const props = defineProps<{ leagueId: number }>()
const emit = defineEmits<{ changed: [] }>()
const a = ref<components['schemas']['Academy'] | null>(null)
const busy = ref<number | null>(null)
const now = useNow()
const toast = useToast()
const path = () => ({ params: { path: { league: props.leagueId } } })

async function load() {
  try { a.value = (await api.GET('/leagues/{league}/market/academy', path())).data ?? null } catch (e) { toast.show(asApiError(e).message, 'error') }
}
async function sign(id: number, name: string) {
  busy.value = id
  try {
    await ensureCsrf()
    a.value = (await api.POST('/leagues/{league}/market/academy', { ...path(), body: { master_player_id: id } })).data ?? null
    toast.show(t('انضم {v0} إلى فريقك من الأكاديمية.', { v0: name }))
    emit('changed')
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
  busy.value = null
}
onMounted(load)
</script>

<template>
  <section class="flex flex-col gap-3" :aria-label="$t('أكاديمية الشباب')">
    <p v-if="!a" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <template v-else>
      <div class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-3 text-sm">
        <span class="flex-1">{{ $t('مواهب لا تتجاوز 19 عاماً، إمكانيتها الحقيقية تظهر بعد التوقيع.') }}</span>
        <span class="font-numbers text-text-muted">{{ $t('وقّعت {v0} من {v1} هذا الموسم', { v0: a.signed, v1: a.per_season }) }}</span>
        <span class="rounded-pill border border-gold/40 px-3 py-1">{{ $t('مواهب جديدة بعد') }} <b class="font-numbers text-gold" dir="ltr">{{ countdown(a.renews_at, now) }}</b></span>
      </div>
      <EmptyState v-if="!a.prospects.length" icon="training" title="لا مواهب الآن" text="تصل مواهب جديدة في الموعد أعلاه." />
      <ul v-else class="stagger grid gap-2 sm:grid-cols-3">
        <li v-for="p in a.prospects" :key="p.id" class="flex flex-col gap-2 rounded-xl border border-text/10 bg-surface p-3">
          <div class="flex items-center gap-2"><LineBadge :line="p.line as Line" /><b class="min-w-0 flex-1 truncate"><bdi>{{ $nm(p.name) }}</bdi></b></div>
          <span class="text-xs text-text-muted">{{ $t('{v0} · {v1} سنة', { v0: p.position, v1: p.age }) }}<template v-if="p.nationality"> · {{ p.nationality }}</template></span>
          <div class="flex items-end justify-between">
            <span><span class="block text-xs text-text-muted">{{ $t('القوة') }}</span><b class="font-numbers text-2xl">{{ p.overall }}</b></span>
            <span class="text-end"><span class="block text-xs text-text-muted">{{ $t('الإمكانية') }}</span><b class="font-numbers text-lg text-success" dir="ltr">{{ p.potential_from }}–{{ p.potential_to }}</b></span>
          </div>
          <UiButton block :loading="busy === p.id" :disabled="a.signed >= a.per_season || a.balance < p.price" @click="sign(p.id, p.name)">{{ $t('وقّع') }} · <span class="font-numbers" dir="ltr">{{ money(p.price) }}</span></UiButton>
        </li>
      </ul>
    </template>
  </section>
</template>
