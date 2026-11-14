<script setup lang="ts">
// [Sprint 64 W1] The new coach's first match: the Assistant Coach (B3) speaks at the three moments the server chose,
// with the guide's words; a skip always in reach; and at the end, «take a club», with the starter gift given here.
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import type { IntroMoment } from '../../api/sim'
import { api, ensureCsrf } from '../../api/client'
import { useWallet } from '../../stores/wallet'
import Character from '../characters/Character.vue'
import UiButton from '../ui/UiButton.vue'

defineProps<{ current: IntroMoment | null; over: boolean }>()
const emit = defineEmits<{ answer: []; coach: []; skip: [] }>()
const router = useRouter()
const going = ref(false)

/** The gift for a first match (once; already taken or not offered, the way on is the same), then a club. */
async function takeClub() {
  going.value = true
  try {
    await ensureCsrf()
    await api.POST('/home/starter-gift')
    useWallet().load()
  } catch { /* the gift waits on the home screen */ }
  void router.replace('/leagues')
}
</script>

<template>
  <div class="intro-coach">
    <UiButton v-if="!over" class="intro-skip" size="sm" variant="quiet" @click="emit('skip')">{{ $t('تخطَّ المباراة التعريفية') }}</UiButton>
    <Transition name="tip">
      <aside v-if="current && !over" class="intro-bubble" role="status" aria-live="polite">
        <Character model="B3" mood="joy" class="intro-face" />
        <div class="intro-words">
          <b class="intro-title">{{ current.title }}</b>
          <p class="intro-text">{{ current.text }}</p>
          <div class="intro-actions">
            <UiButton v-if="current.kind !== 'effect'" size="sm" @click="emit('coach'); emit('answer')">{{ $t('افتح الأوامر') }}</UiButton>
            <UiButton size="sm" variant="quiet" @click="emit('answer')">{{ $t('حسناً') }}</UiButton>
          </div>
        </div>
      </aside>
      <aside v-else-if="over" class="intro-bubble" role="status">
        <Character model="B3" mood="cheer" class="intro-face" />
        <div class="intro-words">
          <b class="intro-title">{{ $t('أحسنت، هذه كانت مباراتك الأولى!') }}</b>
          <p class="intro-text">{{ $t('الآن خذ نادياً في دوري، ومعه هدية البداية.') }}</p>
          <div class="intro-actions"><UiButton :loading="going" @click="takeClub">{{ $t('خذ نادياً') }}</UiButton></div>
        </div>
      </aside>
    </Transition>
  </div>
</template>

<style scoped>
.intro-coach { position: absolute; inset: 0; z-index: 46; pointer-events: none; }
.intro-skip { position: absolute; inset-block-start: var(--space-sm); inset-inline-end: var(--space-sm); pointer-events: auto; }
.intro-bubble {
  position: absolute; inset-inline: var(--space-md); inset-block-end: var(--space-md); margin-inline: auto; max-inline-size: 28rem;
  display: flex; gap: var(--space-md); align-items: flex-start; padding: var(--space-md); pointer-events: auto;
  border: 1px solid color-mix(in srgb, var(--color-gold) 50%, transparent); border-radius: var(--radius-lg);
  background: var(--color-panel); box-shadow: var(--shadow-overlay);
}
.intro-face { inline-size: 56px; block-size: 56px; flex-shrink: 0; }
.intro-words { display: flex; min-inline-size: 0; flex: 1; flex-direction: column; gap: var(--space-sm); }
.intro-title { color: var(--color-gold); }
.intro-text { font-size: var(--text-body); line-height: 1.6; }
.intro-actions { display: flex; flex-wrap: wrap; gap: var(--space-sm); }
.tip-enter-active, .tip-leave-active { transition: opacity 0.2s, transform 0.2s; }
.tip-enter-from, .tip-leave-to { opacity: 0; transform: translateY(8px); }
</style>
