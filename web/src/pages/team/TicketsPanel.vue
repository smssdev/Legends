<script setup lang="ts">
// Tickets [X25]: go to the other clubs' coming matches and cheer one side; each ticket lifts that side's morale
// for the match. One per match, club money, until the lock.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import { money } from '../../lib/format'

type Tickets = components['responses']['Tickets']['content']['application/json']
const props = defineProps<{ leagueId: number }>()
const data = ref<Tickets | null>(null)
const busy = ref<number | null>(null)
const message = ref('')

onMounted(async () => {
  try {
    data.value = (await api.GET('/leagues/{league}/tickets', { params: { path: { league: props.leagueId } } })).data!
  } catch (e) {
    message.value = asApiError(e).message
  }
})
async function buy(fixture: number, side: 'home' | 'away') {
  busy.value = fixture
  message.value = ''
  try {
    await ensureCsrf()
    data.value = (await api.POST('/leagues/{league}/tickets', { params: { path: { league: props.leagueId } }, body: { fixture_id: fixture, side } })).data!
    message.value = 'حجزت تذكرتك، وجمهورك يشجع.'
  } catch (e) {
    message.value = asApiError(e).message
  }
  busy.value = null
}
const when = (iso: string) => new Date(iso).toLocaleString('ar', { weekday: 'short', hour: 'numeric', minute: '2-digit' })
</script>

<template>
  <section v-if="data && data.fixtures.length" class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-tickets">
    <div>
      <h2 id="h-tickets" class="font-display text-xl font-extrabold">التذاكر</h2>
      <p class="text-sm text-text-muted">احضر مباريات منافسيك وشجّع أحد الفريقين: كل تذكرة ترفع معنوياته <b class="font-numbers text-gold">+{{ data.boost }}</b> في تلك المباراة. سعر التذكرة {{ money(data.price) }}.</p>
    </div>
    <p v-if="message" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm" role="status">{{ message }}</p>
    <ul class="flex flex-col gap-2">
      <li v-for="f in data.fixtures" :key="f.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <span class="text-xs text-text-muted">{{ f.competition === 'cup' ? 'الكأس' : f.competition === 'alliance' ? 'التحالفات' : `الجولة ${f.round}` }} · {{ when(f.scheduled_at) }}</span>
        <div class="grid grid-cols-2 gap-2">
          <button
            v-for="s in (['home', 'away'] as const)"
            :key="s"
            type="button"
            class="flex min-h-touch items-center gap-2 rounded-lg border px-2 py-1.5 text-start disabled:opacity-50"
            :class="f.mine === s ? 'border-gold bg-gold/15' : 'border-transparent bg-surface'"
            :disabled="!!f.mine || busy === f.id"
            :aria-pressed="f.mine === s"
            @click="buy(f.id, s)"
          >
            <ClubCrest :url="f[s].crest_url" :code="f[s].code" :size="28" />
            <span class="min-w-0 flex-1 truncate text-sm font-bold">{{ f[s].name }}</span>
            <span class="text-xs text-text-muted" :aria-label="`${f.cheering[s]} تذكرة`">📣 <span class="font-numbers">{{ f.cheering[s] }}</span></span>
          </button>
        </div>
      </li>
    </ul>
  </section>
</template>
