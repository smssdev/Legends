<script setup lang="ts">
// Join a league by its code (Sprint 13 W1), after the drafts WebJoin and MobileJoin: three steps
// (the code, the owner's approval, choosing a club), the league's card, and the request's state.
// ?code= fills the code (the invite link, Sprint 14); ?league= shows a request already sent.
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import { budget, END_MODES, when, type League } from '../../api/leagues'
import Icon from '../../components/Icon.vue'
import UiButton from '../../components/ui/UiButton.vue'
import UiChip from '../../components/ui/UiChip.vue'

const route = useRoute()
const router = useRouter()
// The invite link /join/CODE (Sprint 14) or ?code=.
const code = ref(String(route.params.code || route.query.code || '').toUpperCase())
const league = ref<League | null>(null)
const status = ref<'pending' | 'approved' | 'rejected' | null>(null)
const error = ref('')
const sending = ref(false)

const clean = computed(() => code.value.replace(/[\s#-]+/g, '').toUpperCase().slice(0, 8))
const boxes = computed(() => Array.from({ length: 8 }, (_, i) => clean.value[i] ?? ''))
const step = computed(() => (status.value === 'approved' ? 3 : status.value ? 2 : 1))
const owner = computed(() => league.value?.owner?.name ?? 'منشئ الدوري')

async function send() {
  error.value = ''
  if (clean.value.length !== 8) {
    error.value = 'الكود 8 أحرف.'
    return
  }
  sending.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues/join', { body: { code: clean.value } })
    league.value = data!.league ?? null
    status.value = data!.request.status
    router.replace({ query: { league: league.value?.id } })
  } catch (e) {
    error.value = asApiError(e).message
  }
  sending.value = false
}

/** A request already sent: read its state again (the owner may have answered meanwhile). */
async function refresh() {
  const id = Number(route.query.league)
  if (!id) return
  try {
    const { data } = await api.GET('/leagues/{league}', { params: { path: { league: id } } })
    league.value = data!.league
    status.value = data!.league.my_request ?? null
    if (data!.league.my_club_id) router.replace({ name: 'league-home', params: { id } })
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function cancel() {
  if (!league.value) return
  try {
    await ensureCsrf()
    await api.DELETE('/leagues/{league}/request', { params: { path: { league: league.value.id } } })
    router.push({ name: 'leagues' })
  } catch (e) {
    error.value = asApiError(e).message
  }
}

let timer = 0
onMounted(() => {
  refresh()
  // Until notifications come (Sprint 36), the screen asks every half minute while it waits.
  timer = window.setInterval(() => status.value === 'pending' && refresh(), 30000)
})
onBeforeUnmount(() => window.clearInterval(timer))
</script>

<template>
  <div class="flex flex-col gap-5">
    <ol class="grid grid-cols-3 gap-2" :aria-label="$t('الخطوات')">
      <li
        v-for="(s, i) in [
          { title: 'الكود', note: clean || '8 أحرف' },
          { title: 'موافقة المنشئ', note: status === 'pending' ? `بانتظار ${owner}` : status === 'approved' ? 'وافق' : status === 'rejected' ? 'رُفض' : 'بعد الكود' },
          { title: 'اختيار الفريق', note: 'بعد الموافقة' },
        ]"
        :key="s.title"
        class="flex items-center gap-3 rounded-xl p-3"
        :class="i + 1 === step ? 'border border-gold/60 bg-surface-raised' : 'bg-surface'"
        :aria-current="i + 1 === step ? 'step' : undefined"
      >
        <span
          class="flex size-8 shrink-0 items-center justify-center rounded-full font-numbers text-base font-bold"
          :class="i + 1 < step ? 'bg-success text-on-gold' : i + 1 === step ? 'bg-gold text-on-gold' : 'bg-surface-raised text-text-soft'"
        >{{ i + 1 < step ? '✓' : i + 1 }}</span>
        <span class="hidden min-w-0 sm:block">
          <span class="block font-bold">{{ $t(s.title) }}</span>
          <span class="block truncate text-xs text-text-muted" :dir="i === 0 && clean ? 'ltr' : undefined">{{ s.note }}</span>
        </span>
        <span class="text-sm font-bold sm:hidden">{{ $t(s.title) }}</span>
      </li>
    </ol>

    <div class="grid gap-4 md:grid-cols-2">
      <section class="flex flex-col gap-4 rounded-xl bg-surface p-4 md:p-6" aria-labelledby="h-code">
        <div>
          <h1 id="h-code" class="font-display text-3xl font-extrabold">{{ $t('انضم بكود الدوري') }}</h1>
          <p class="mt-1 text-sm text-text-muted">{{ $t('الكود من 8 أحرف، تجده عند صاحبك أو في رابط الدعوة.') }}</p>
        </div>

        <form v-if="!status" class="flex flex-col gap-4" @submit.prevent="send">
          <label class="relative block">
            <span class="sr-only">{{ $t('كود الدوري') }}</span>
            <!-- One real input (paste and the keyboard work as usual) under the eight boxes of the design. -->
            <input
              v-model="code"
              dir="ltr"
              autocomplete="off"
              autocapitalize="characters"
              spellcheck="false"
              maxlength="12"
              class="absolute inset-0 z-10 w-full cursor-text opacity-0"
              aria-describedby="code-err"
            />
            <span class="grid grid-cols-8 gap-1.5" dir="ltr" aria-hidden="true">
              <span
                v-for="(c, i) in boxes"
                :key="i"
                class="flex aspect-[4/5] items-center justify-center rounded-lg border bg-surface-sunk font-numbers text-2xl font-bold text-gold md:text-3xl"
                :class="i === clean.length ? 'border-gold' : 'border-gold/40'"
              >{{ c }}</span>
            </span>
          </label>
          <p v-if="error" id="code-err" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
          <UiButton type="submit" block :disabled="sending || clean.length !== 8">{{ sending ? $t('يرسل…') : $t('أرسل طلب الانضمام') }}</UiButton>
        </form>

        <article v-if="league" class="flex flex-col gap-3 rounded-xl bg-surface-sunk p-4">
          <header class="flex items-start gap-3">
            <span class="flex size-12 shrink-0 items-center justify-center rounded-lg bg-surface-raised text-gold"><Icon name="league" /></span>
            <div class="min-w-0 flex-1">
              <h2 class="truncate font-display text-xl font-extrabold">{{ $nm(league.name) }}</h2>
              <p class="text-sm text-text-muted">{{ $t('أنشأه {v0}', { v0: owner }) }}</p>
            </div>
            <UiChip v-if="league.fair_league" tone="win">{{ $t('دوري نزيه') }}</UiChip>
          </header>
          <dl class="grid grid-cols-2 gap-2 text-sm">
            <div class="rounded-lg bg-surface p-3"><dt class="text-text-muted">{{ $t('القالب') }}</dt><dd class="font-bold">{{ $ln(league.template) }}</dd></div>
            <div class="rounded-lg bg-surface p-3">
              <dt class="text-text-muted">{{ $t('الفرق') }}</dt>
              <dd class="font-bold"><span class="font-numbers">{{ league.team_count }}</span> {{ $t('· منها') }} <span class="font-numbers">{{ league.coaches }}</span> {{ $t('مدربين') }}</dd>
            </div>
            <div class="rounded-lg bg-surface p-3"><dt class="text-text-muted">{{ $t('البداية') }}</dt><dd class="font-bold">{{ $t('{v0} بتوقيتك', { v0: when(league.starts_at) }) }}</dd></div>
            <div class="rounded-lg bg-surface p-3">
              <dt class="text-text-muted">{{ $t('الجولات') }}</dt>
              <dd class="font-bold">{{ league.rounds_per_day === 1 ? $t('جولة يومياً') : $t('جولتان يومياً') }}</dd>
            </div>
            <div class="rounded-lg bg-surface p-3"><dt class="text-text-muted">{{ $t('الميزانية') }}</dt><dd class="font-bold">{{ budget(league.starting_budget) }}</dd></div>
            <div class="rounded-lg bg-surface p-3"><dt class="text-text-muted">{{ $t('نهاية الموسم') }}</dt><dd class="font-bold">{{ END_MODES[league.season_end_mode] }}</dd></div>
          </dl>
        </article>
      </section>

      <section v-if="status" class="flex flex-col items-center gap-4 rounded-xl border border-gold/30 bg-surface p-6 text-center" role="status">
        <span class="flex size-20 items-center justify-center rounded-full bg-surface-raised text-gold">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" />
          </svg>
        </span>
        <template v-if="status === 'pending'">
          <h2 class="font-display text-2xl font-extrabold">{{ $t('طلبك وصل لـ{v0}', { v0: owner }) }}</h2>
          <p class="text-text-muted">{{ $t('بانتظار موافقته، وبعدها تختار فريقك. هذه الصفحة تتحدث وحدها.') }}</p>
          <p v-if="league" class="text-sm text-text-muted">
            {{ $t('الأندية المتاحة الآن:') }} <span class="font-numbers font-bold text-text">{{ league.free_clubs }}</span>
          </p>
          <UiButton variant="quiet" block @click="cancel">{{ $t('إلغاء الطلب') }}</UiButton>
        </template>
        <template v-else-if="status === 'approved'">
          <h2 class="font-display text-2xl font-extrabold">{{ $t('وافق {v0} على طلبك', { v0: owner }) }}</h2>
          <p class="text-text-muted">{{ $t('اختر فريقاً بلا مدرب، قبل أن يسبقك أحد.') }}</p>
          <RouterLink
            v-if="league"
            :to="{ name: 'pick-team', params: { id: league.id } }"
            class="flex h-12 w-full items-center justify-center rounded-lg bg-gold font-display font-extrabold text-on-gold hover:bg-gold-light"
          >
            {{ $t('اختر فريقك') }}
          </RouterLink>
        </template>
        <template v-else>
          <h2 class="font-display text-2xl font-extrabold">{{ $t('رفض {v0} طلبك', { v0: owner }) }}</h2>
          <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('عودة لدورياتي') }}</RouterLink>
        </template>
        <p v-if="error" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
      </section>
    </div>
  </div>
</template>
