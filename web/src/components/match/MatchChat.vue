<template>
  <!-- [X24, Sprint 57 W2] Live: the two coaches cheer and tease each other; every screen sees it at once. In a league every
       member who watches may react, and cheer or boo one side once in half a minute; and the viewers' side chat. -->
  <section
    v-if="isLive && (mine || league) && !finished"
    class="flex flex-col gap-2 rounded-xl bg-surface p-2"
    :aria-label="$t('تفاعل مع المباراة')"
  >
    <div class="flex gap-1.5 overflow-x-auto">
      <button
        v-for="r in REACTIONS"
        :key="r.key"
        type="button"
        class="flex h-touch shrink-0 items-center gap-1 rounded-pill bg-surface-sunk px-3 text-sm font-bold hover:bg-surface-raised disabled:opacity-40"
        :disabled="reactWait"
        :aria-label="r.label"
        @click="social.react(r.key)"
      >
        <span class="text-lg" aria-hidden="true">{{ r.emoji }}</span><span v-if="r.text">{{ $t(r.text) }}</span>
      </button>
    </div>
    <div v-if="league" class="grid grid-cols-2 gap-1.5 sm:grid-cols-4">
      <template v-for="s in ['home', 'away'] as const" :key="s">
        <button
          type="button"
          class="flex h-touch items-center justify-center gap-1 truncate rounded-lg bg-success/15 px-2 text-sm font-bold text-success disabled:opacity-40"
          :disabled="cheerLeft > 0"
          @click="social.react('cheer', s)"
        >
          <Icon name="megaphone" :size="16" class="inline-block align-[-3px]" /><span class="truncate">{{ $nm(view.clubs[s].name) }}</span>
        </button>
        <button
          type="button"
          class="flex h-touch items-center justify-center gap-1 truncate rounded-lg bg-live/15 px-2 text-sm font-bold text-danger disabled:opacity-40"
          :disabled="cheerLeft > 0"
          @click="social.react('boo', s)"
        >
          <Icon name="thumbs_down" :size="16" class="inline-block align-[-3px]" /><span class="truncate">{{
            $nm(view.clubs[s].name)
          }}</span>
        </button>
      </template>
    </div>
    <p v-if="league && cheerLeft > 0" class="text-center text-xs text-text-muted">
      {{ $t('التشجيع والاستهجان بعد') }} <span class="font-numbers">{{ cheerLeft }}</span> {{ $t('ثانية') }}
    </p>
  </section>

  <section v-if="league && !rerun" class="flex flex-col gap-2 rounded-xl bg-surface p-3" :aria-label="$t('دردشة المشاهدين')">
    <h2 class="font-display text-base font-bold">{{ $t('دردشة المشاهدين') }}</h2>
    <div
      :ref="(el) => (chatBox = el as HTMLElement | null)"
      class="flex max-h-[240px] min-h-[64px] flex-col gap-1.5 overflow-y-auto"
      aria-live="polite"
    >
      <p v-if="!chat.length" class="text-sm text-text-muted">{{ $t('مدربو الدوري الذين يتابعون يتكلمون هنا.') }}</p>
      <p v-for="c in chat" :key="c.id" class="rounded-md bg-surface-sunk px-3 py-1.5 text-sm">
        <b :class="c.side ? 'text-gold' : 'text-text-soft'" dir="auto">{{ c.who }}</b><span class="text-text-muted">: </span
        ><span dir="auto">{{ c.body }}</span>
      </p>
    </div>
    <form v-if="isLive && !finished" class="flex gap-2" @submit.prevent="social.sendChat">
      <input
        v-model="chatText"
        type="text"
        maxlength="140"
        class="h-touch min-w-0 flex-1 rounded-lg bg-surface-sunk px-3"
        :placeholder="$t('اكتب رسالة…')"
        :aria-label="$t('رسالة')"
      />
      <button
        type="submit"
        class="h-touch rounded-lg bg-gold px-4 font-bold text-on-gold disabled:opacity-40"
        :disabled="!chatText.trim() || chatWait"
      >
        {{ $t('إرسال') }}
      </button>
    </form>
    <p v-if="chatError" class="text-xs text-danger" role="status">{{ $t(chatError) }}</p>
  </section>
</template>

<script setup lang="ts">
import Icon from '../Icon.vue'
import type { MatchView, Side } from '../../api/sim'
import type { MatchPlayer } from '../../match/useMatchPlayer'
import { REACTIONS, type MatchSocial } from '../../match/useMatchSocial'

const props = defineProps<{ social: MatchSocial; player: MatchPlayer; view: MatchView; mine: Side | null; league: boolean }>()
const { finished, rerun, live: isLive } = props.player
const { reactWait, cheerLeft, chat, chatText, chatWait, chatError, chatBox } = props.social
</script>
