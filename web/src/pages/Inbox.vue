<script setup lang="ts">
// The inbox (Sprint 22 W1): the game's messages, newest first, the unread ones marked, each one leading to
// its screen. No draft of its own: the design system's cards and the "الرسائل" section of WebHome's side bar.
import OfficialBadge from '../components/OfficialBadge.vue'
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import UiButton from '../components/ui/UiButton.vue'
import { useInbox, type Message } from '../stores/inbox'

const inbox = useInbox()
const router = useRouter()
const ICON: Record<string, string> = {
  referee: '🟨', absence_warning: '⏰', left_absent: '🚪', kicked: '⛔', join_request: '✋', join_approved: '✅', join_rejected: '✖️', match_report: '📊',
}
const when = (iso: string) => new Intl.DateTimeFormat('ar-EG', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso))

function open(m: Message) {
  inbox.read(m)
  if (m.link) router.push(m.link)
}

onMounted(() => inbox.load())
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="font-display text-3xl font-extrabold">{{ $t('الرسائل') }}</h1>
        <p class="mt-1 text-text-muted">{{ inbox.unread ? $t('{v0} غير مقروءة', { v0: inbox.unread }) : $t('كلها مقروءة') }}</p>
      </div>
      <UiButton v-if="inbox.unread" variant="outline" @click="inbox.readAll()">{{ $t('اجعلها كلها مقروءة') }}</UiButton>
    </div>

    <p v-if="inbox.error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]">{{ inbox.error }}</p>
    <p v-else-if="!inbox.loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <section v-else-if="!inbox.messages.length" class="flex flex-col items-center gap-2 rounded-xl bg-surface p-8 text-center">
      <span class="text-4xl" aria-hidden="true">📭</span>
      <h2 class="font-display text-xl font-extrabold">{{ $t('لا رسائل بعد') }}</h2>
      <p class="text-sm text-text-muted">{{ $t('هنا يصلك حكم مباراتك، وتقاريرها، وطلبات الانضمام، وكل ما يخص دورياتك.') }}</p>
    </section>

    <ul v-else class="flex flex-col gap-2" :aria-label="$t('الرسائل')">
      <li v-for="m in inbox.messages" :key="m.id">
        <button
          type="button"
          class="flex w-full items-start gap-3 rounded-xl p-4 text-start transition hover:bg-surface-raised"
          :class="m.read ? 'bg-surface' : 'border-s-4 border-gold bg-surface-raised'"
          @click="open(m)"
        >
          <span class="flex size-11 shrink-0 items-center justify-center rounded-full bg-surface-sunk text-xl" aria-hidden="true">{{ ICON[m.type] ?? '✉️' }}</span>
          <span class="min-w-0 flex-1">
            <span class="flex flex-wrap items-baseline justify-between gap-x-3">
              <b class="font-display" :class="m.read ? 'font-bold text-text-soft' : 'font-extrabold'">{{ m.title }}</b>
              <span v-if="m.sender" class="text-xs text-text-muted">من {{ m.sender.name }} <span dir="ltr">@{{ m.sender.username }}</span> <OfficialBadge v-if="m.sender.official" /></span>
              <time class="text-xs text-text-muted" :datetime="m.created_at">{{ when(m.created_at) }}</time>
            </span>
            <span class="mt-1 block text-sm" :class="m.read ? 'text-text-muted' : 'text-text-soft'">{{ m.body }}</span>
          </span>
          <span v-if="!m.read" class="mt-2 size-2.5 shrink-0 rounded-full bg-gold" :aria-label="$t('غير مقروءة')" />
        </button>
      </li>
    </ul>
    <UiButton v-if="inbox.more" variant="quiet" @click="inbox.load(true)">{{ $t('رسائل أقدم') }}</UiButton>
  </div>
</template>
