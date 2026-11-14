<script setup lang="ts">
// [Sprint 29] The chat groups (docs/design/legends-ui/Sprint29Drafts.html, 1): each with its last message and unread
// count, the leagues' and tournaments' own on their tab; "+" makes one with friends by their usernames.
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { intlLocale, t } from '../../lib/i18n'
import UiButton from '../../components/ui/UiButton.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import EmptyState from '../../components/ui/EmptyState.vue'
import { noteText } from './notes'

type Item = components['schemas']['ChatGroupItem']
const router = useRouter()
const groups = ref<Item[]>([])
const loaded = ref(false)
const error = ref('')
const tab = ref<'all' | 'leagues'>('all')
const creating = ref(false)
const name = ref('')
const names = ref('')
const busy = ref(false)
const formError = ref('')

async function load() {
  try {
    const { data } = await api.GET('/groups')
    groups.value = data!.groups
  } catch (e) {
    error.value = asApiError(e).message
  } finally {
    loaded.value = true
  }
}
onMounted(load)

const shown = computed(() => groups.value.filter((g) => (tab.value === 'leagues' ? g.league_id !== null : true)))
const initial = (s: string) => [...s.trim()][0] ?? '؟'
const preview = (g: Item) => {
  const m = g.last
  if (!m) return t('لا رسائل بعد')
  if (m.deleted) return t('هذه الرسالة حُذفت')
  if (m.kind === 'note') return noteText(m.body)
  if (m.kind === 'image') return `${m.user?.name ?? ''}: 📷 ${m.body || t('صورة')}`
  if (m.kind === 'audio') return `${m.user?.name ?? ''}: 🎤 ${t('رسالة صوتية')}`
  return `${m.user?.name ?? ''}: ${m.body}`
}
const time = (iso: string) => {
  const d = new Date(iso)
  const today = new Date().toDateString() === d.toDateString()
  return today
    ? d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
    : d.toLocaleDateString(intlLocale(), { day: 'numeric', month: 'short' })
}

async function create() {
  formError.value = ''
  busy.value = true
  try {
    await ensureCsrf()
    const usernames = names.value
      .split(/[\s,،]+/)
      .map((s) => s.trim())
      .filter(Boolean)
    const { data } = await api.POST('/groups', { body: { name: name.value, usernames } })
    creating.value = false
    await router.push({ name: 'group', params: { id: data!.group.id } })
  } catch (e) {
    formError.value = asApiError(e).message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="relative flex min-h-[70vh] flex-col gap-4 pb-24">
    <header class="flex items-center justify-between gap-3">
      <h1 class="font-display text-3xl font-extrabold">{{ $t('الجروبات') }}</h1>
      <div class="flex gap-2" role="tablist">
        <button
          type="button"
          v-for="k in ['all', 'leagues'] as const"
          :key="k"
          role="tab"
          :aria-selected="tab === k"
          class="min-h-touch rounded-full px-4 text-sm font-bold"
          :class="tab === k ? 'bg-brand text-text' : 'bg-surface-sunk text-text-muted'"
          @click="tab = k"
        >
          {{ k === 'all' ? $t('الكل') : $t('الدوريات والبطولات') }}
        </button>
      </div>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <!-- [Sprint 30 P10] The first group from the empty page itself, not only the round button. -->
    <EmptyState
      v-if="loaded && !shown.length"
      icon="chat"
      :title="$t('لا جروبات بعد')"
      :text="$t('أنشئ جروباً مع أصدقائك، أو افتح جروب دوريك من صفحته.')"
    >
      <UiButton class="mt-1" @click="creating = true">{{ $t('أنشئ جروباً') }}</UiButton>
    </EmptyState>
    <ul class="flex flex-col gap-2">
      <li v-for="g in shown" :key="g.id">
        <RouterLink
          :to="{ name: 'group', params: { id: g.id } }"
          class="flex min-h-[64px] items-center gap-3 rounded-2xl bg-surface p-3 hover:bg-surface-raised"
        >
          <span
            class="grid size-11 shrink-0 place-items-center rounded-full text-lg font-extrabold"
            :class="g.league_id ? 'bg-gold-dark text-text' : 'bg-brand text-text'"
            >{{ initial(g.name) }}</span
          >
          <span class="min-w-0 flex-1">
            <b class="block truncate">{{ g.name }}</b>
            <span class="block truncate text-sm text-text-muted">{{ preview(g) }}</span>
          </span>
          <span class="flex flex-col items-end gap-1">
            <span v-if="g.last" class="font-numbers text-xs text-text-muted" dir="ltr">{{ time(g.last.created_at) }}</span>
            <span v-if="g.unread" class="rounded-full bg-gold px-2 font-numbers text-xs font-extrabold text-on-gold">{{ g.unread }}</span>
          </span>
        </RouterLink>
      </li>
    </ul>

    <button
      type="button"
      class="fixed bottom-24 end-5 z-30 grid size-14 place-items-center rounded-full bg-gold text-3xl font-extrabold text-on-gold shadow-lg md:bottom-8"
      :aria-label="$t('جروب جديد')"
      @click="creating = true"
    >
      +
    </button>

    <UiDialog :open="creating" :title="$t('جروب جديد')" @close="creating = false">
      <form class="flex flex-col gap-3" @submit.prevent="create">
        <label class="flex flex-col gap-1"
          ><span class="font-bold">{{ $t('اسم الجروب') }}</span>
          <input v-model="name" required maxlength="60" class="h-touch rounded-lg bg-surface-sunk px-3"
        /></label>
        <label class="flex flex-col gap-1"
          ><span class="font-bold">{{ $t('أضف أعضاء بأسماء المستخدمين') }}</span>
          <input v-model="names" dir="ltr" placeholder="sara, omar" class="h-touch rounded-lg bg-surface-sunk px-3" />
          <span class="text-xs text-text-muted">{{
            $t('افصل بينها بمسافة أو فاصلة، ويمكنك الإضافة لاحقاً أو مشاركة رابط الجروب.')
          }}</span></label
        >
        <p v-if="formError" class="text-sm text-danger" role="alert">{{ $t(formError) }}</p>
        <UiButton type="submit" block :loading="busy">{{ $t('أنشئ الجروب') }}</UiButton>
      </form>
    </UiDialog>
  </div>
</template>
