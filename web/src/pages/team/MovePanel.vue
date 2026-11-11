<script setup lang="ts">
// [Sprint 27 B2, the owner's request 2026-10-30] Moving the next match on its own day: the hours the server allows now
// as chips (earlier or later), one tap to ask and one to confirm; the other coach sees the request here and accepts or
// declines it; whoever asked may take it back. Every rule is the server's (App\League\FixtureMoves).
import UiButton from '../../components/ui/UiButton.vue'
import { computed, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { intlLocale } from '../../lib/i18n'

const props = defineProps<{ leagueId: number; fixtureId: number; scheduledAt: string; move: components['schemas']['MatchMoveView'] }>()
const emit = defineEmits<{ changed: [] }>()
const chosen = ref<number | null>(null)
const busy = ref(false)
const message = ref('')
const open = ref(false)

const time = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
const at = (h: number) => new Date(Date.parse(props.scheduledAt) + h * 3600_000).toISOString()
const earlier = computed(() => props.move.hours.filter((h) => h < 0).reverse())
const later = computed(() => props.move.hours.filter((h) => h > 0))
const path = computed(() => ({ params: { path: { league: props.leagueId } } }))

async function run(work: () => Promise<unknown>, done: string) {
  busy.value = true
  message.value = ''
  try {
    await ensureCsrf()
    await work()
    message.value = done
    chosen.value = null
    emit('changed')
  } catch (e) {
    message.value = asApiError(e).message
  }
  busy.value = false
}
const ask = () => run(() => api.POST('/leagues/{league}/team/moves', { ...path.value, body: { fixture_id: props.fixtureId, hours: chosen.value! } }), 'أُرسل طلبك للمدرب الآخر.')
const answer = (accept: boolean) => run(() => api.POST(accept ? '/leagues/{league}/team/moves/{move}/accept' : '/leagues/{league}/team/moves/{move}/decline',
  { params: { path: { league: props.leagueId, move: props.move.pending!.id } } }), accept ? 'تغيّر موعد المباراة.' : 'بقيت المباراة في موعدها.')
const cancel = () => run(() => api.DELETE('/leagues/{league}/team/moves/{move}', { params: { path: { league: props.leagueId, move: props.move.pending!.id } } }), 'سحبت طلبك.')
</script>

<template>
  <section class="flex flex-col gap-3 rounded-xl ui-card p-4" :aria-label="$t('موعد المباراة')">
    <!-- The other coach asks me. -->
    <template v-if="move.pending && !move.pending.mine">
      <h2 class="font-display text-lg font-bold">{{ $t('طلب تغيير الموعد') }}</h2>
      <p class="text-sm">{{ $t('المدرب الآخر يطلب نقل المباراة إلى {v0} في اليوم نفسه.', { v0: time(move.pending.to_at) }) }}</p>
      <div class="grid grid-cols-2 gap-2">
        <button type="button" class="h-touch rounded-lg bg-success font-bold text-white disabled:opacity-40" :disabled="busy" @click="answer(true)">{{ $t('وافق') }}</button>
        <button type="button" class="h-touch rounded-lg bg-surface-raised font-bold disabled:opacity-40" :disabled="busy" @click="answer(false)">{{ $t('ارفض') }}</button>
      </div>
    </template>
    <!-- I asked: waiting. -->
    <template v-else-if="move.pending">
      <p class="text-sm">{{ $t('طلبت نقل المباراة إلى {v0}، وينتظر رد المدرب الآخر.', { v0: time(move.pending.to_at) }) }}</p>
      <button type="button" class="h-touch rounded-lg bg-surface-raised font-bold disabled:opacity-40" :disabled="busy" @click="cancel">{{ $t('اسحب الطلب') }}</button>
    </template>
    <template v-else-if="move.hours.length">
      <button type="button" class="flex h-touch items-center justify-between font-display text-lg font-bold" :aria-expanded="open" @click="open = !open">
        {{ $t('تقديم المباراة أو تأجيلها') }}<span aria-hidden="true">{{ open ? '−' : '+' }}</span>
      </button>
      <template v-if="open">
        <div v-for="[label, list] in ([['أبكر', earlier], ['أبعد', later]] as const)" :key="label" class="flex flex-col gap-1">
          <span v-if="list.length" class="text-xs text-text-muted">{{ $t(label) }}</span>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="h in list"
              :key="h"
              type="button"
              class="ui-choice min-w-20 px-3 font-numbers"
              :aria-pressed="chosen === h"
              @click="chosen = chosen === h ? null : h"
            >{{ time(at(h)) }}</button>
          </div>
        </div>
        <UiButton variant="brand" v-if="chosen !== null" :disabled="busy" @click="ask">
          {{ $t('اطلب النقل إلى {v0}', { v0: time(at(chosen)) }) }}
        </UiButton>
      </template>
    </template>
    <p v-if="message" class="text-sm text-text-soft" role="status">{{ $t(message) }}</p>
  </section>
</template>
