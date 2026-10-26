<script setup lang="ts">
// [UP12] The league's newspaper (the owner's spec 6): the round's own report (written on the server from the round:
// the results, its stories and the team of the week), and the coaches' articles, which the owner publishes.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'

const props = defineProps<{ id: string }>()
type Article = { id: number; title: string; body: string; status: string; author: { id: number; name: string }; at: string }
type Paper = {
  edition: null | { round: number; rounds: number[]; results: { home: string; away: string; home_goals: number; away_goals: number }[]; stories: { kind: string; title: string; text: string }[]; team: { id: number; name: string; line: string; position: string; club: string; rating: number }[] }
  articles: Article[]; pending: Article[]; is_owner: boolean; max: number
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
      <RouterLink :to="{ name: 'league-home', params: { id } }" class="text-sm text-text-muted">› الدوري</RouterLink>
      <h1 class="font-display text-3xl font-extrabold">جريدة الدوري</h1>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>

    <section v-if="p?.edition" class="flex flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4" aria-labelledby="h-edition">
      <div class="flex flex-wrap items-center gap-2">
        <h2 id="h-edition" class="font-display text-2xl font-extrabold">عدد الجولة {{ p.edition.round }}</h2>
        <select v-if="p.edition.rounds.length > 1" class="ms-auto h-touch rounded-md bg-surface-sunk px-2" :value="p.edition.round" aria-label="جولة أخرى" @change="load(Number(($event.target as HTMLSelectElement).value))">
          <option v-for="n in [...p.edition.rounds].reverse()" :key="n" :value="n">الجولة {{ n }}</option>
        </select>
      </div>
      <article v-for="(s, i) in p.edition.stories" :key="i" class="rounded-lg bg-surface-sunk p-3" :class="i === 0 ? 'border-s-4 border-gold' : ''">
        <h3 class="font-display font-extrabold" :class="i === 0 ? 'text-xl' : 'text-base'">{{ s.title }}</h3>
        <p class="text-sm text-text-soft">{{ s.text }}</p>
      </article>
      <div class="grid gap-3 md:grid-cols-2">
        <div>
          <h3 class="mb-1 font-bold">النتائج</h3>
          <ul class="flex flex-col text-sm">
            <li v-for="(m, i) in p.edition.results" :key="i" class="flex items-center justify-between gap-2 border-t border-text/5 py-1.5 first:border-0">
              <bdi class="flex-1 truncate">{{ $nm(m.home) }}</bdi><b class="font-numbers" dir="ltr">{{ m.home_goals }} - {{ m.away_goals }}</b><bdi class="flex-1 truncate text-end">{{ $nm(m.away) }}</bdi>
            </li>
          </ul>
        </div>
        <div v-if="p.edition.team.length">
          <h3 class="mb-1 font-bold">تشكيلة الجولة المثالية</h3>
          <ul class="flex flex-col text-sm">
            <li v-for="t in p.edition.team" :key="t.id" class="flex items-center gap-2 border-t border-text/5 py-1.5 first:border-0">
              <span class="w-10 text-xs text-text-muted">{{ LINE[t.line] }}</span><bdi class="flex-1 truncate font-bold">{{ $nm(t.name) }}</bdi>
              <span class="truncate text-xs text-text-muted">{{ $nm(t.club) }}</span><b class="font-numbers text-gold">{{ (t.rating / 10).toFixed(1) }}</b>
            </li>
          </ul>
        </div>
      </div>
    </section>
    <p v-else-if="p" class="rounded-xl bg-surface p-6 text-text-muted">يصدر أول عدد بعد أول جولة.</p>

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-articles">
      <h2 id="h-articles" class="font-display text-xl font-extrabold">مقالات المدربين</h2>
      <article v-for="a in p?.articles ?? []" :key="a.id" class="rounded-lg bg-surface-sunk p-3">
        <h3 class="font-bold">{{ a.title }}</h3>
        <p class="whitespace-pre-line text-sm text-text-soft">{{ a.body }}</p>
        <p class="mt-1 text-xs text-text-muted">{{ a.author.name }} · {{ day(a.at) }}</p>
      </article>
      <p v-if="p && !p.articles.length" class="text-sm text-text-muted">لا مقالات منشورة بعد.</p>
    </section>

    <section v-if="p?.pending.length" class="flex flex-col gap-2 rounded-xl border border-warning/40 bg-surface p-4" aria-labelledby="h-pending">
      <h2 id="h-pending" class="font-display text-lg font-extrabold">{{ p.is_owner ? 'مقالات تنتظر موافقتك' : 'مقالاتك عند المشرف' }}</h2>
      <article v-for="a in p.pending" :key="a.id" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <h3 class="font-bold">{{ a.title }} <span class="text-xs font-normal text-text-muted">· {{ a.author.name }}</span></h3>
        <p class="whitespace-pre-line text-sm text-text-soft">{{ a.body }}</p>
        <div v-if="p.is_owner" class="flex gap-2">
          <button type="button" class="h-touch rounded-md bg-success/20 px-4 font-bold text-success" @click="decide(a.id, true)">انشره</button>
          <button type="button" class="h-touch rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="decide(a.id, false)">ارفضه</button>
        </div>
      </article>
    </section>

    <form class="flex flex-col gap-2 rounded-xl bg-surface p-4" @submit.prevent="write">
      <h2 class="font-display text-lg font-extrabold">اكتب للجريدة</h2>
      <p class="text-sm text-text-muted">خبر، أو بيان، أو صفقة، أو رسالة لمنافسيك. يُنشر بعد موافقة مشرف الدوري.</p>
      <input v-model="title" maxlength="120" placeholder="العنوان" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3" aria-label="العنوان" />
      <textarea v-model="body" :maxlength="p?.max ?? 2000" rows="5" placeholder="نص المقال" class="rounded-lg border border-text/10 bg-surface-sunk p-3" aria-label="نص المقال" />
      <button type="submit" class="h-12 self-start rounded-lg bg-gold px-5 font-bold text-on-gold disabled:opacity-50" :disabled="title.trim().length < 3 || body.trim().length < 10">أرسل للمشرف</button>
      <p v-if="sent" class="text-sm text-success" role="status">{{ sent }}</p>
    </form>
  </div>
</template>
