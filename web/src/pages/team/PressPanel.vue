<script setup lang="ts">
// [UP12] The press conference before my match (the owner's spec 6): the chances of each side, a reading of where each
// is strong and weak, and my one statement (it lifts my team's morale in this match). It opens half an hour before.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'

const props = defineProps<{ leagueId: number; fixtureId: number; home: string; away: string }>()
type Press = { open: boolean; opens_at: string; chances: { home: number; draw: number; away: number }; reading: { home: string; away: string };
  statements: { kind: string; text: string }[]; said: { home: string | null; away: string | null }; mine: 'home' | 'away' | null; morale: number }
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
async function say(kind: string) {
  error.value = ''
  try {
    await ensureCsrf()
    press.value = ((await api.POST('/leagues/{league}/press/{fixture}', { ...path(), body: { kind: kind as 'calm' } })).data as any).press
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const time = (iso: string) => new Date(iso).toLocaleTimeString('ar-EG', { hour: 'numeric', minute: '2-digit' })
onMounted(load)
</script>

<template>
  <section v-if="press && enabled" class="flex flex-col gap-3 rounded-xl border border-brand/40 bg-surface p-4" aria-labelledby="h-press">
    <h2 id="h-press" class="font-display text-xl font-extrabold">🎙️ المؤتمر الصحفي</h2>
    <div class="flex h-8 overflow-hidden rounded-lg text-xs font-bold" role="img" :aria-label="`ترجيح الفوز: ${home} ${press.chances.home}٪، التعادل ${press.chances.draw}٪، ${away} ${press.chances.away}٪`">
      <span class="flex items-center justify-center bg-brand text-white" :style="{ width: press.chances.home + '%' }">{{ press.chances.home }}%</span>
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
        <p class="text-sm font-bold">اختر تصريحك الرسمي قبل المباراة:</p>
        <button v-for="s in press.statements" :key="s.kind" type="button" class="min-h-touch rounded-lg bg-surface-sunk px-3 py-2 text-start text-sm hover:bg-surface-raised" @click="say(s.kind)">«{{ s.text }}»</button>
      </template>
      <p v-else class="text-sm text-text-muted">يُعقد المؤتمر الساعة {{ time(press.opens_at) }}، قبل المباراة بنصف ساعة: تصريحك يرفع معنويات لاعبيك.</p>
    </template>
    <p v-if="error" class="text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
  </section>
</template>
