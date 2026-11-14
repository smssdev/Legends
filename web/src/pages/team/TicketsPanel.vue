<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// Tickets [X25]: go to the other clubs' coming matches and cheer one side; each ticket lifts that side's morale
// for the match. One per match, club money, until the lock.
import { intlLocale, t } from '../../lib/i18n'
import { act, busy } from '../../lib/action'
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import { money } from '../../lib/format'

type Tickets = components['responses']['Tickets']['content']['application/json']
const props = defineProps<{ leagueId: number }>()
const data = ref<Tickets | null>(null)
const message = ref('')

onMounted(async () => {
  try {
    data.value = (await api.GET('/leagues/{league}/tickets', { params: { path: { league: props.leagueId } } })).data!
  } catch (e) {
    message.value = asApiError(e).message
  }
})
// [X92] Through lib/action: the side tapped waits, the result in a toast.
async function buy(fixture: number, side: 'home' | 'away') {
  const r = await act(
    `ticket:${fixture}`,
    () => api.POST('/leagues/{league}/tickets', { params: { path: { league: props.leagueId } }, body: { fixture_id: fixture, side } }),
    {
      success: t('حجزت تذكرتك، وجمهورك يشجع.'),
    },
  )
  if (r?.data) data.value = r.data
}
const when = (iso: string) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'short', hour: 'numeric', minute: '2-digit' })
</script>

<template>
  <section v-if="data && data.fixtures.length" class="flex flex-col gap-3 rounded-xl ui-card p-4" aria-labelledby="h-tickets">
    <div>
      <h2 id="h-tickets" class="font-display text-xl font-extrabold">{{ $t('التذاكر') }}</h2>
      <p class="text-sm text-text-muted">
        {{ $t('المعنويات') }} <b class="font-numbers text-gold">+{{ data.boost }}</b> · <span dir="ltr">{{ money(data.price) }}</span>
      </p>
    </div>
    <p v-if="message" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>
    <ul class="flex flex-col gap-2">
      <li v-for="f in data.fixtures" :key="f.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <span class="text-xs text-text-muted"
          >{{
            f.competition === 'cup' ? $t('الكأس') : f.competition === 'alliance' ? $t('التحالفات') : $t('الجولة {v0}', { v0: f.round })
          }}
          · {{ when(f.scheduled_at) }}</span
        >
        <div class="grid grid-cols-2 gap-2">
          <button
            v-for="s in ['home', 'away'] as const"
            :key="s"
            type="button"
            class="flex min-h-touch items-center gap-2 rounded-lg border px-2 py-1.5 text-start disabled:opacity-50"
            :class="f.mine === s ? 'border-gold bg-gold/15' : 'border-transparent bg-surface'"
            :disabled="!!f.mine || busy(`ticket:${f.id}`)"
            :aria-pressed="f.mine === s"
            @click="buy(f.id, s)"
          >
            <ClubCrest :url="f[s].crest_url" :code="f[s].code" :size="28" />
            <span class="min-w-0 flex-1 truncate text-sm font-bold">{{ $nm(f[s].name) }}</span>
            <span class="text-xs text-text-muted" :aria-label="$t('{v0} تذكرة', { v0: f.cheering[s] })"
              ><Icon name="megaphone" :size="16" class="inline-block align-[-3px]" /><span class="font-numbers">{{
                f.cheering[s]
              }}</span></span
            >
          </button>
        </div>
      </li>
    </ul>
  </section>
</template>
