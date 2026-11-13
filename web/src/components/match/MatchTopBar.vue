<template>
  <!-- [Sprint 56 W7, Sprint 57 W2] The thin bar over the match: the way back, the live state (or the simulator's pace),
       and ⚙ (the view's settings). The score shows once, on the picture. -->
  <header class="match-top">
    <RouterLink :to="league ? '/match' : '/sim'" class="flex items-center gap-2">
      <BrandMark size="sm" />
    </RouterLink>
    <span v-if="!league" class="match-seed rounded-pill bg-gold/15 px-3 py-1 text-xs font-bold text-gold">{{ $t('المحاكي · بذرة') }} <span class="font-numbers">{{ seed }}</span></span>
    <span v-if="rerun" class="rounded-pill bg-gold/15 px-3 py-1 text-xs font-bold text-gold">{{ $t('إعادة المباراة كاملة') }}</span>
    <div class="flex-1" />
    <template v-if="isLive">
      <!-- [Sprint 53 W2] The dot says how the minutes arrive: pushed (it beats), or asked for while the channel comes back. -->
      <span class="flex h-touch items-center gap-2 rounded-md bg-live/15 px-3 text-sm font-bold text-danger"><span class="size-2 rounded-full" :class="league && !connected ? 'bg-warning' : 'bg-live'" :title="dotLabel" role="img" :aria-label="dotLabel" />{{ $t('مباشر · {v0}', { v0: mineName ? $t('تدير ') + mineName : $t('مشاهدة') }) }}</span>
      <button v-if="live.friendLink.value" type="button" class="h-touch rounded-md bg-surface px-3 text-sm" @click="live.share">{{ copied ? $t('نُسخ الرابط') : $t('رابط الصديق') }}</button>
    </template>
    <div v-else class="flex items-center gap-1 rounded-lg bg-surface p-1" role="group" :aria-label="$t('سرعة المحاكاة')">
      <button type="button" class="size-touch rounded-sm bg-surface-raised" :aria-label="playing ? $t('إيقاف مؤقت') : $t('تشغيل')" @click="player.togglePlay">
        <svg v-if="playing" viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><rect x="6" y="5" width="4" height="14" rx="1" /><rect x="14" y="5" width="4" height="14" rx="1" /></svg>
        <svg v-else viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><path d="M7 5l12 7-12 7z" /></svg>
      </button>
      <button v-for="s in [1, 2, 4]" :key="s" type="button" class="h-10 min-w-11 rounded-sm font-numbers text-lg" :class="speed === s ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="speed === s" dir="ltr" @click="speed = s">×{{ s }}</button>
      <button type="button" class="h-10 rounded-sm px-3 text-sm text-text-soft" :disabled="finished" @click="player.skipMoment">{{ $t('تخطَّ اللقطة') }}</button>
      <button type="button" class="h-10 rounded-sm px-3 text-sm text-text-soft" :disabled="skipping" @click="player.skip">{{ skipping ? '...' : $t('تخطٍّ للنهاية') }}</button>
    </div>
    <button type="button" class="match-btn" :aria-label="$t('إعدادات العرض')" :aria-expanded="settingsOpen" @click="emit('settings')"><Icon name="settings" :size="18" /></button>
  </header>
</template>

<script setup lang="ts">
import Icon from '../Icon.vue'
import { computed } from 'vue'
import { t } from '../../lib/i18n'
import type { MatchPlayer } from '../../match/useMatchPlayer'
import type { LiveMatch } from '../../match/useLiveMatch'

const props = defineProps<{ player: MatchPlayer; live: LiveMatch; league: boolean; seed?: number; mineName: string; settingsOpen: boolean }>()
const emit = defineEmits<{ settings: [] }>()
const { playing, speed, finished, skipping, rerun, live: isLive } = props.player
const { copied } = props.live
const connected = props.live.sync.connected
const dotLabel = computed(() => (props.league ? (connected.value ? t('متصل بالبث المباشر') : t('نعيد الاتصال بالبث... المباراة مستمرة')) : undefined))
</script>

<style scoped>
.match-top { position: relative; z-index: 45; display: flex; min-height: 2.75rem; align-items: center; gap: var(--space-sm); padding: 2px var(--space-sm); background: color-mix(in srgb, var(--color-broadcast-tv) 92%, transparent); }
.match-top :deep(.brand-words) { white-space: nowrap; }
@media (max-width: 900px) { .match-top :deep(.brand-words), .match-seed { display: none !important; } }
.match-top :deep(button) { white-space: nowrap; }
.match-btn { display: grid; width: var(--spacing-touch); height: var(--spacing-touch); place-items: center; border-radius: var(--radius-lg); font-size: var(--text-title); background: color-mix(in srgb, var(--color-text) 10%, transparent); }
</style>
