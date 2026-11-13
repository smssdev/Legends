<script setup lang="ts">
import Icon, { type PATHS } from '../components/Icon.vue'
// The inbox (Sprint 22 W1): the game's messages, newest first, the unread ones marked, each one leading to
// its screen. No draft of its own: the design system's cards and the "الرسائل" section of WebHome's side bar.
import EmptyState from '../components/ui/EmptyState.vue'
import { stamp } from '../lib/dates'
import OfficialBadge from '../components/OfficialBadge.vue'
import { computed, onMounted, ref } from 'vue'
import UiTabs from '../components/ui/UiTabs.vue'
import { useRouter } from 'vue-router'
import UiButton from '../components/ui/UiButton.vue'
import { useInbox, type Message } from '../stores/inbox'

const inbox = useInbox()
const router = useRouter()
// [Sprint 63 G5] Each kind's mark from the icon set (they were emoji).
const ICON: Record<string, keyof typeof PATHS> = {
  referee: 'card', absence_warning: 'clock', left_absent: 'exit', kicked: 'ban', join_request: 'key', join_approved: 'check', join_rejected: 'close', match_report: 'chart',
}
const when = stamp   // [X61] the same on every list

// [X61 E7] The inbox as a notification centre: its kinds in five groups, each a tab with its unread count.
type Group = 'all' | 'league' | 'market' | 'team' | 'alerts'
const GROUPS: Record<Exclude<Group, 'all'>, string[]> = {
  league: ['match_report', 'match_of_day', 'season_end', 'join_request', 'join_approved', 'join_rejected', 'article_pending', 'referee', 'vacation_request', 'vacation_approved', 'vacation_rejected'],
  market: ['offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'offer_cancelled', 'offer_expired', 'listing_sold', 'scout_report', 'forced_sale'],
  team: ['training_done', 'camp_back', 'stadium_part', 'staff_left', 'assistant_led'],
  alerts: ['absence_warning', 'left_absent', 'kicked', 'in_debt', 'inactive_warning', 'account_vacation', 'account_vacation_request', 'announcement', 'official_message', 'coins_gift', 'suggestion_answer', 'referral_reward', 'slot_opened'],
}
const group = ref<Group>('all')
const groupOf = (type: string): Group => (Object.keys(GROUPS) as Exclude<Group, 'all'>[]).find((g) => GROUPS[g].includes(type)) ?? 'alerts'
const shown = computed(() => (group.value === 'all' ? inbox.messages : inbox.messages.filter((m) => groupOf(m.type) === group.value)))
const unreadIn = (g: Group) => inbox.messages.filter((m) => !m.read && (g === 'all' || groupOf(m.type) === g)).length || null
const tabs = computed(() => ([['all', 'الكل'], ['league', 'الدوري'], ['market', 'العروض والسوق'], ['team', 'الفريق'], ['alerts', 'التنبيهات']] as const)
  .map(([key, label]) => ({ key, label, n: unreadIn(key) })))

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

    <p v-if="inbox.error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger">{{ $t(inbox.error) }}</p>
    <p v-else-if="!inbox.loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <EmptyState v-else-if="!inbox.messages.length" icon="inbox" title="لا رسائل بعد" text="تصلك هنا نتائج مبارياتك وعروض السوق وأخبار دورياتك." :cta="{ label: 'إلى ناديك', to: '/club' }" />

    <UiTabs v-if="inbox.loaded && inbox.messages.length" v-model="group" :items="tabs" label="أنواع الرسائل" size="sm" />
    <p v-if="inbox.loaded && inbox.messages.length && !shown.length" class="rounded-xl bg-surface p-4 text-sm text-text-muted">{{ $t('لا رسائل من هذا النوع.') }}</p>
    <ul v-else-if="inbox.messages.length" class="flex flex-col gap-2" :aria-label="$t('الرسائل')">
      <li v-for="m in shown" :key="m.id">
        <button
          type="button"
          class="flex w-full items-start gap-3 rounded-xl p-4 text-start transition hover:bg-surface-raised"
          :class="m.read ? 'bg-surface' : 'border-s-4 border-gold bg-surface-raised'"
          @click="open(m)"
        >
          <span class="flex size-11 shrink-0 items-center justify-center rounded-full bg-surface-sunk text-xl" aria-hidden="true"><Icon :name="ICON[m.type] ?? 'mail'" :size="22" /></span>
          <span class="min-w-0 flex-1">
            <span class="flex flex-wrap items-baseline justify-between gap-x-3">
              <b class="font-display" :class="m.read ? 'font-bold text-text-soft' : 'font-extrabold'">{{ $t(m.title) }}</b>
              <span v-if="m.sender" class="text-xs text-text-muted">{{ $t('من {v0}', { v0: m.sender.name }) }} <span dir="ltr">@{{ m.sender.username }}</span> <OfficialBadge v-if="m.sender.official" /></span>
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
