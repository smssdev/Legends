<script setup lang="ts">
// [UP12] The league's newspaper (the owner's spec 6): the round's own report (written on the server from the round:
// the results, its stories and the team of the week), and the coaches' articles, which the owner publishes.
// [Sprint 21 E4.5, E4.6] «أخبار الدوري»: the round's best matches, its player and its coach, the bribes an opponent
// exposed, and one article a round for each coach.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'

const props = defineProps<{ id: string }>()
type Article = { id: number; title: string; body: string; status: string; author: { id: number; name: string }; at: string }
type Best = { score: number; home: string; away: string; home_goals: number; away_goals: number; upset: boolean; match_id: number | null }
type Scandal = { club: string; coach: string | null; accuser: string; points: number; fine: number; at: string }
type Paper = {
  edition: null | { round: number; rounds: number[]; results: { home: string; away: string; home_goals: number; away_goals: number }[]; stories: { kind: string; title: string; text: string }[]; team: { id: number; name: string; line: string; position: string; club: string; rating: number }[]
    best_matches: Best[]; player: { name: string; club: string; position: string; rating: number; goals?: number; assists?: number } | null
    coach: { coach: { id: number; name: string }; club: string; opponent: string; goals: [number, number]; away: boolean } | null; scandals: Scandal[] }
  articles: Article[]; pending: Article[]; is_owner: boolean; max: number; wrote_this_round: boolean; round: number
}
const p = ref<Paper | null>(null)
const error = ref('')
const title = ref('')
const body = ref('')
const sent = ref('')
const league = () => ({ params: { path: { league: Number(props.id) } } })

async function load(round?: number) {
  try {
    p.value = (await api.GET('/leagues/{league}/newspaper', { params: { path: { league: Number(props.id) }, query: round ? { round } : {} } })).data as Paper
  } catch (e) {
    error.value = asApiError(e).message
  }
}
async function write() {
  error.value = sent.value = ''
  try {
    await ensureCsrf()
    p.value = (await api.POST('/leagues/{league}/newspaper/articles', { ...league(), body: { title: title.value.trim(), body: body.value.trim() } })).data as Paper
    title.value = body.value = ''
    sent.value = 'أُرسل مقالك إلى مشرف الدوري، ويُنشر حين يوافق.'
  } catch (e) {
    error.value = asApiError(e).message
  }
}
async function decide(id: number, publish: boolean) {
  try {
    await ensureCsrf()
    p.value = (await api.POST('/leagues/{league}/newspaper/articles/{article}/decide', { params: { path: { league: Number(props.id), article: id } }, body: { publish } })).data as Paper
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const LINE = { gk: 'حارس', def: 'دفاع', mid: 'وسط', att: 'هجوم' } as Record<string, string>
const day = (iso: string) => new Date(iso).toLocaleDateString('ar-EG', { day: 'numeric', month: 'long' })
onMounted(() => load())
</script>

<template>
  <div class="flex flex-col gap-4">
    <header>
      <RouterLink :to="{ name: 'league-home', params: { id } }" class="text-sm text-text-muted">{{ $t('› الدوري') }}</RouterLink>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('أخبار الدوري') }}</h1>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <section v-if="p?.edition" class="flex flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4" aria-labelledby="h-edition">
      <div class="flex flex-wrap items-center gap-2">
        <h2 id="h-edition" class="font-display text-2xl font-extrabold">{{ $t('عدد الجولة {v0}', { v0: p.edition.round }) }}</h2>
        <select v-if="p.edition.rounds.length > 1" class="ms-auto h-touch rounded-md bg-surface-sunk px-2" :value="p.edition.round" :aria-label="$t('جولة أخرى')" @change="load(Number(($event.target as HTMLSelectElement).value))">
          <option v-for="n in [...p.edition.rounds].reverse()" :key="n" :value="n">{{ $t('الجولة {v0}', { v0: n }) }}</option>
        </select>
      </div>
      <article v-for="(s, i) in p.edition.stories" :key="i" class="rounded-lg bg-surface-sunk p-3" :class="i === 0 ? 'border-s-4 border-gold' : ''">
        <h3 class="font-display font-extrabold" :class="i === 0 ? 'text-xl' : 'text-base'">{{ $t(s.title) }}</h3>
        <p class="text-sm text-text-soft">{{ $t(s.text) }}</p>
      </article>
      <!-- [Sprint 21 E4.6] The round's player and coach. -->
      <div v-if="p.edition.player || p.edition.coach" class="grid gap-3 sm:grid-cols-2">
        <div v-if="p.edition.player" class="flex items-center gap-3 rounded-lg bg-gold/10 p-3">
          <span class="grid size-12 shrink-0 place-items-center rounded-full bg-gold text-2xl" aria-hidden="true">⭐</span>
          <span class="min-w-0"><span class="block text-xs font-bold text-gold">{{ $t('رجل الجولة') }}</span><b class="block truncate font-display text-lg"><bdi>{{ $nm(p.edition.player.name) }}</bdi></b>
            <span class="text-xs text-text-muted">{{ $nm(p.edition.player.club) }} · <span class="font-numbers text-gold">{{ (p.edition.player.rating / 100).toFixed(1) }}</span><template v-if="p.edition.player.goals || p.edition.player.assists"> · {{ $t('{v0} هدف · {v1} صناعة', { v0: p.edition.player.goals ?? 0, v1: p.edition.player.assists ?? 0 }) }}</template></span></span>
        </div>
        <div v-if="p.edition.coach" class="flex items-center gap-3 rounded-lg bg-brand/15 p-3">
          <span class="grid size-12 shrink-0 place-items-center rounded-full bg-brand text-2xl" aria-hidden="true">🧠</span>
          <span class="min-w-0"><span class="block text-xs font-bold text-brand-light">{{ $t('أفضل مدرب في الجولة') }}</span><b class="block truncate font-display text-lg">{{ p.edition.coach.coach.name }}</b>
            <span class="text-xs text-text-muted">{{ $t('{v0} فاز على {v1}', { v0: $nm(p.edition.coach.club), v1: $nm(p.edition.coach.opponent) }) }} <b class="font-numbers" dir="ltr">{{ p.edition.coach.goals[0] }}-{{ p.edition.coach.goals[1] }}</b><template v-if="p.edition.coach.away"> {{ $t('خارج أرضه') }}</template></span></span>
        </div>
      </div>
      <div v-if="p.edition.best_matches?.length">
        <h3 class="mb-1 font-bold">{{ $t('أفضل مباريات الجولة') }}</h3>
        <ol class="flex flex-col gap-1.5">
          <li v-for="(m, i) in p.edition.best_matches" :key="i">
            <component :is="m.match_id ? 'RouterLink' : 'div'" :to="m.match_id ? { name: 'league-report', params: { id: m.match_id } } : undefined" class="flex items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm">
              <span class="font-numbers text-text-muted">{{ i + 1 }}</span>
              <bdi class="flex-1 truncate">{{ $nm(m.home) }}</bdi><b class="font-numbers" dir="ltr">{{ m.home_goals }} - {{ m.away_goals }}</b><bdi class="flex-1 truncate text-end">{{ $nm(m.away) }}</bdi>
              <span v-if="m.upset" class="rounded-pill bg-warning/20 px-2 text-xs text-warning">{{ $t('مفاجأة') }}</span>
            </component>
          </li>
        </ol>
      </div>
      <!-- [Sprint 21 E4.6] Exposed: the bribes an opponent caught, as the FA ruled them. -->
      <div v-if="p.edition.scandals?.length" class="flex flex-col gap-1.5 rounded-lg border border-live/40 bg-live/10 p-3">
        <h3 class="font-bold text-danger">{{ $t('فضائح الرشوة') }}</h3>
        <p v-for="(c, i) in p.edition.scandals" :key="i" class="text-sm">
          {{ $t('كشف {v0} رشوة الحكم من {v1}{v2}: خصم {v3} نقاط وغرامة.', { v0: $nm(c.accuser), v1: $nm(c.club), v2: c.coach ? ' (' + c.coach + ')' : '', v3: c.points }) }}
        </p>
      </div>
      <div class="grid gap-3 md:grid-cols-2">
        <div>
          <h3 class="mb-1 font-bold">{{ $t('النتائج') }}</h3>
          <ul class="flex flex-col text-sm">
            <li v-for="(m, i) in p.edition.results" :key="i" class="flex items-center justify-between gap-2 border-t border-text/5 py-1.5 first:border-0">
              <bdi class="flex-1 truncate">{{ $nm(m.home) }}</bdi><b class="font-numbers" dir="ltr">{{ m.home_goals }} - {{ m.away_goals }}</b><bdi class="flex-1 truncate text-end">{{ $nm(m.away) }}</bdi>
            </li>
          </ul>
        </div>
        <div v-if="p.edition.team.length">
          <h3 class="mb-1 font-bold">{{ $t('تشكيلة الجولة المثالية') }}</h3>
          <ul class="flex flex-col text-sm">
            <li v-for="t in p.edition.team" :key="t.id" class="flex items-center gap-2 border-t border-text/5 py-1.5 first:border-0">
              <span class="w-10 text-xs text-text-muted">{{ $t(LINE[t.line] ?? '') }}</span><bdi class="flex-1 truncate font-bold">{{ $nm(t.name) }}</bdi>
              <span class="truncate text-xs text-text-muted">{{ $nm(t.club) }}</span><b class="font-numbers text-gold">{{ (t.rating / 100).toFixed(1) }}</b>
            </li>
          </ul>
        </div>
      </div>
    </section>
    <p v-else-if="p" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('يصدر أول عدد بعد أول جولة.') }}</p>

    <!-- [Sprint 21 E3.3] The articles and the form come with the paper, not before it: nothing jumps down. -->
    <template v-if="p">
    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-articles">
      <h2 id="h-articles" class="font-display text-xl font-extrabold">{{ $t('مقالات المدربين') }}</h2>
      <article v-for="a in p?.articles ?? []" :key="a.id" class="rounded-lg bg-surface-sunk p-3">
        <h3 class="font-bold">{{ $t(a.title) }}</h3>
        <p class="whitespace-pre-line text-sm text-text-soft">{{ a.body }}</p>
        <p class="mt-1 text-xs text-text-muted">{{ a.author.name }} · {{ day(a.at) }}</p>
      </article>
      <p v-if="p && !p.articles.length" class="text-sm text-text-muted">{{ $t('لا مقالات منشورة بعد.') }}</p>
    </section>

    <section v-if="p?.pending.length" class="flex flex-col gap-2 rounded-xl border border-warning/40 bg-surface p-4" aria-labelledby="h-pending">
      <h2 id="h-pending" class="font-display text-lg font-extrabold">{{ p.is_owner ? $t('مقالات تنتظر موافقتك') : $t('مقالاتك عند المشرف') }}</h2>
      <article v-for="a in p.pending" :key="a.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <h3 class="font-bold">{{ $t(a.title) }} <span class="text-xs font-normal text-text-muted">· {{ a.author.name }}</span></h3>
        <p class="whitespace-pre-line text-sm text-text-soft">{{ a.body }}</p>
        <div v-if="p.is_owner" class="flex gap-2">
          <button type="button" class="h-touch rounded-md bg-success/20 px-4 font-bold text-success" @click="decide(a.id, true)">{{ $t('انشره') }}</button>
          <button type="button" class="h-touch rounded-md bg-live/15 px-4 font-bold text-danger" @click="decide(a.id, false)">{{ $t('ارفضه') }}</button>
        </div>
      </article>
    </section>

    <form class="flex flex-col gap-2 rounded-xl bg-surface p-4" @submit.prevent="write">
      <h2 class="font-display text-lg font-extrabold">{{ $t('اكتب للجريدة') }}</h2>
      <p v-if="p.wrote_this_round" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm text-text-soft" role="status">{{ $t('كتبت مقال الجولة {v0}. تكتب التالي في الجولة القادمة.', { v0: p.round }) }}</p>
      <input v-model="title" maxlength="120" :placeholder="$t('العنوان')" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3" :aria-label="$t('العنوان')" />
      <textarea v-model="body" :maxlength="p?.max ?? 2000" rows="5" :placeholder="$t('نص المقال')" class="rounded-lg border border-text/10 bg-surface-sunk p-3" :aria-label="$t('نص المقال')" />
      <button type="submit" class="h-12 self-start rounded-lg bg-gold px-5 font-bold text-on-gold disabled:opacity-50" :disabled="p.wrote_this_round || title.trim().length < 3 || body.trim().length < 10">{{ $t('أرسل للمشرف') }}</button>
      <p v-if="sent" class="text-sm text-success" role="status">{{ sent }}</p>
    </form>
    </template>
  </div>
</template>
