<script setup lang="ts">
// [Sprint 55 W1] The frame's bar, 42px (LandscapeShell.html): the screen's name, the countdown to the club's next match
// (a tap opens it), the coins and, on the screens where it is spent or earned, the club's money (X85), the messages,
// and the coach's account. [W3] The verification is a dot on the account (and a card on the home screen), not a strip
// across every screen. [Sprint 56 W1] The timers and what waits left the bar for the office (Office.html); the dock's
// «المكتب» carries their count.
import Icon from '../Icon.vue'
import ClubSwitcher from './ClubSwitcher.vue'
import CountdownChip from '../ui/CountdownChip.vue'
import MoneyPill from '../ui/MoneyPill.vue'

defineProps<{
  title: string
  next?: { at: string | null; live: boolean; opponent: string } | null
  coins: number
  cash?: { value: number; label: string; title: string } | null
  unread: string
  avatar?: string | null
  initial: string
  unverified: boolean
  inSlot?: boolean
}>()
</script>

<template>
  <header class="shell-bar">
    <!-- On a short phone the club leaves the dock for here (AppShell's .bar-club). -->
    <div v-if="inSlot" class="bar-club"><ClubSwitcher in-bar /></div>
    <p class="shell-title">{{ title ? $t(title) : '' }}</p>
    <span class="flex-1" />
    <RouterLink v-if="next" to="/match" class="bar-next" :aria-label="next.live ? $t('مباراتك مباشرة الآن') : $t('المباراة القادمة ضد {o}', { o: next.opponent })">
      <span v-if="next.live" class="bar-live">{{ $t('مباشر') }}</span>
      <template v-else><span class="bar-wide truncate">{{ $t('ضد {o}', { o: next.opponent }) }}</span><CountdownChip :to="next.at" /></template>
    </RouterLink>
    <MoneyPill kind="coins" to="/wallet" :value="coins" :label="$t('المحفظة')" />
    <MoneyPill v-if="cash" kind="cash" to="/finance" :value="cash.value" caption="أموال النادي" :title="cash.title" :label="cash.label" />
    <RouterLink to="/inbox" class="bar-icon" :aria-label="unread ? $t('الرسائل: {n} غير مقروءة', { n: unread }) : $t('الرسائل')">
      <Icon name="inbox" /><span v-if="unread" class="bar-badge bg-live text-white">{{ unread }}</span>
    </RouterLink>
    <RouterLink to="/profile" class="bar-avatar" :aria-label="unverified ? $t('حسابي: وثّق حسابك') : $t('حسابي')">
      <img v-if="avatar" :src="avatar" alt="" class="size-full rounded-full object-cover" decoding="async" /><template v-else>{{ initial }}</template>
      <span v-if="unverified" class="bar-avatar-dot" aria-hidden="true" />
    </RouterLink>
  </header>
</template>
