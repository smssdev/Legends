<template>
  <!-- [Sprint 57 W2] The break over the picture: half-time, a coach's window [X42] or the final whistle, with the score,
       the countdown, the ready button [UP17], and what comes next. -->
  <div v-if="(halftime || finished || windowOn) && !highlighting" dir="rtl" class="absolute inset-0 z-20 flex flex-col items-center justify-center gap-4 bg-bg-deep/85 p-4 text-center">
    <span class="text-sm font-bold text-gold">{{ finished ? $t('نهاية المباراة') : windowOn ? $t('فترة توقف · الدقيقة {v0}', { v0: minute[0] }) : $t('الاستراحة') }}</span>
    <span class="font-numbers text-6xl" dir="ltr">{{ scoreText(score.home, score.away) }}</span>
    <span v-if="shootout" class="text-sm text-text-soft">{{ $t('ركلات الترجيح: {v0} - {v1}', { v0: shootout.home, v1: shootout.away }) }}</span>
    <div class="flex flex-wrap justify-center gap-2">
      <span v-if="halftime && isLive" class="text-sm text-text-soft">{{ $t('الشوط الثاني بعد') }} <b class="font-numbers text-lg text-gold">{{ halftimeLeft }}</b> {{ $t('ثانية · غيّر خطتك الآن') }}</span>
      <span v-if="windowOn && !finished" class="text-sm text-text-soft">{{ $t('تُستأنف المباراة بعد') }} <b class="font-numbers text-lg text-gold">{{ halftimeLeft }}</b> {{ $t('ثانية · غيّر خطتك أو أجرِ تبديلاتك الآن') }}</span>
      <button v-if="(halftime || windowOn) && isLive && league && mine" type="button" class="h-12 rounded-md px-6 font-display font-bold disabled:opacity-60"
        :class="iAmReady ? 'bg-success/20 text-success' : 'bg-brand text-white'" :disabled="iAmReady || readyBusy" @click="live.sayReady">
        {{ iAmReady ? $t('مستعد ✓ بانتظار الخصم') : $t('أنا مستعد') }}</button>
      <a v-if="(halftime || windowOn) && isLive && mine" href="#coach" class="flex h-12 items-center rounded-md bg-gold px-5 font-display font-bold text-on-gold" @click.prevent="emit('coach')">{{ $t('لوحة المدرب') }}</a>
      <button v-if="halftime && !isLive" type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold" @click="player.endHalftime">{{ $t('ابدأ الشوط الثاني') }} <span class="font-numbers">({{ halftimeLeft }})</span></button>
      <button v-if="finished && keyCount" type="button" class="h-12 rounded-md bg-surface-raised px-5 font-display font-bold" @click="player.highlights">{{ $t('ملخص المباراة · {v0} لقطة', { v0: keyCount }) }}</button>
      <RouterLink v-if="finished && !league" :to="{ name: 'sim-report', params: { id }, query: mine ? { side: mine } : {} }" class="flex h-12 items-center rounded-md bg-gold px-6 font-display font-bold text-on-gold">{{ $t('تقرير المباراة') }}</RouterLink>
      <button v-if="finished && league" type="button" class="h-12 rounded-md bg-surface-raised px-5 font-display font-bold" @click="emit('recap')">⚡ {{ $t('الملخص السريع') }}</button>
      <button v-if="finished && rerun" type="button" class="h-12 rounded-md bg-surface-raised px-5 font-display font-bold" @click="player.watchAgain">{{ $t('شاهدها من جديد') }}</button>
      <RouterLink v-if="finished && league && mine" :to="{ name: 'league-report', params: { id } }" class="flex h-12 items-center rounded-md bg-gold px-6 font-display font-bold text-on-gold">{{ $t('تقرير المباراة') }}</RouterLink>
      <RouterLink v-if="finished && league" to="/fixtures" class="flex h-12 items-center rounded-md bg-surface-raised px-5">{{ $t('مباريات الدوري') }}</RouterLink>
      <RouterLink v-if="finished && league" to="/match" class="flex h-12 items-center rounded-md bg-surface-raised px-5">{{ $t('المباراة القادمة') }}</RouterLink>
      <RouterLink v-if="finished && !league" to="/sim" class="flex h-12 items-center rounded-md bg-surface-raised px-5">{{ $t('مباراة جديدة') }}</RouterLink>
    </div>
    <!-- The league's half-time: room kept for an advert (none in v1). -->
    <div v-if="halftime && league" class="flex h-24 w-full max-w-md items-center justify-center rounded-lg border border-dashed border-text/20 text-xs text-text-muted" aria-hidden="true">{{ $t('مساحة إعلانية') }}</div>
  </div>
</template>

<script setup lang="ts">
import { scoreText } from '../../lib/format'
import type { Side } from '../../api/sim'
import type { MatchPlayer } from '../../match/useMatchPlayer'
import type { LiveMatch } from '../../match/useLiveMatch'

const props = defineProps<{ player: MatchPlayer; live: LiveMatch; league: boolean; id: string; mine: Side | null; keyCount: number }>()
const emit = defineEmits<{ coach: []; recap: [] }>()
const { halftime, finished, windowOn, highlighting, minute, score, shootout, halftimeLeft, rerun, live: isLive } = props.player
const { iAmReady, readyBusy } = props.live
</script>
