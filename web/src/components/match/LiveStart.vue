<template>
  <!-- [Sprint 57 W2] A live match with a friend before kick-off: the friend's link, and either coach starts it. -->
  <div class="absolute inset-0 z-40 grid place-items-center bg-bg-deep/80 p-4">
    <section
      :aria-label="$t('بدء المباراة المباشرة')"
      class="flex flex-col items-center gap-3 rounded-xl border border-gold/40 bg-surface p-4 text-center"
    >
      <span class="font-display text-2xl font-extrabold">{{ $t('مباراة مباشرة مع صديق') }}</span>
      <p class="max-w-md text-sm text-text-soft">
        {{ $t('أرسل الرابط لصديقك ليدير {v0} من جهازه، ثم ابدأ حين يكون جاهزاً.', { v0: $nm(otherName) }) }}
      </p>
      <div v-if="friendLink" class="flex w-full max-w-md gap-2">
        <input
          :value="friendLink"
          readonly
          dir="ltr"
          :aria-label="$t('رابط الصديق')"
          class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 text-xs"
          @focus="($event.target as HTMLInputElement).select()"
        />
        <button type="button" class="h-touch rounded-md bg-surface-raised px-4 text-sm" @click="live.share">
          {{ copied ? $t('نُسخ') : $t('نسخ') }}
        </button>
      </div>
      <button
        type="button"
        class="h-12 rounded-md bg-gold px-8 font-display font-bold text-on-gold disabled:opacity-50"
        :disabled="starting"
        @click="live.startLive"
      >
        {{ starting ? '...' : $t('ابدأ المباراة') }}
      </button>
      <span class="text-xs text-text-muted">{{ $t('أي من المدربين يستطيع البدء.') }}</span>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { LiveMatch } from '../../match/useLiveMatch'

const props = defineProps<{ live: LiveMatch; otherName: string }>()
const { friendLink, copied, starting } = props.live
</script>
