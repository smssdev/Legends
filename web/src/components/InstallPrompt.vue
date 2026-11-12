<script setup lang="ts">
// [Sprint 30 G7] The game as an app on the phone's home screen (the service worker and the manifest are there since
// Sprint 9 and 36; the button was only in «حسابي»). Here once on the home screen: the browser's own install offer, or on
// an iPhone the two steps (Share, then «Add to Home Screen»). «لاحقاً» hides it on this device for two weeks; installed,
// it never shows.
import { computed, ref } from 'vue'
import { install, installable, isIos, standalone } from '../lib/pwa'
import UiButton from './ui/UiButton.vue'

const KEY = 'glm.install.later'
const later = ref((() => { try { return Date.now() - Number(localStorage.getItem(KEY) ?? 0) < 14 * 86400_000 } catch { return false } })())
const ios = isIos()
const show = computed(() => !later.value && !standalone() && (installable.value || ios))
function dismiss() {
  try { localStorage.setItem(KEY, String(Date.now())) } catch { /* private mode */ }
  later.value = true
}
</script>

<template>
  <section v-if="show" class="flex flex-wrap items-center gap-3 rounded-2xl border border-gold/30 bg-surface p-4" :aria-label="$t('ثبّت اللعبة')">
    <AppImage src="/icon-192.png" alt="" class="size-12 shrink-0 rounded-xl" :size="48" />
    <span class="min-w-0 flex-1">
      <b class="block">{{ $t('ثبّت اللعبة على جوالك') }}</b>
      <span class="text-sm text-text-muted">{{ ios ? $t('من زر المشاركة اختر «إضافة إلى الشاشة الرئيسية»، فتفتح كتطبيق وتصلك التذكيرات.') : $t('تفتح من الشاشة الرئيسية كتطبيق، أسرع وبلا شريط المتصفح.') }}</span>
    </span>
    <div class="flex gap-2">
      <UiButton v-if="installable" @click="install">{{ $t('ثبّت الآن') }}</UiButton>
      <UiButton variant="quiet" @click="dismiss">{{ $t('لاحقاً') }}</UiButton>
    </div>
  </section>
</template>
