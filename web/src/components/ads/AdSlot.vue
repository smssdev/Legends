<script setup lang="ts">
// [X57] One Google AdSense display unit, in a calm place of a screen (never in a match, nor beside its buttons, as
// Google's policy asks): nothing at all until the owner's account and unit are set on the server.
import { nextTick, onMounted, ref } from 'vue'
import { adsense, fill, type AdSenseConfig } from '../../lib/adsense'

const cfg = ref<AdSenseConfig | null>(null)
onMounted(async () => {
  const c = await adsense()
  if (!c?.slot) return
  cfg.value = c
  await nextTick()
  fill()
})
</script>

<template>
  <aside v-if="cfg?.slot" class="ad-slot flex flex-col gap-1" :aria-label="$t('إعلان')">
    <span class="text-[10px] uppercase tracking-wide text-text-muted">{{ $t('إعلان') }}</span>
    <ins
      class="adsbygoogle block min-h-[90px] w-full"
      :data-ad-client="cfg.client"
      :data-ad-slot="cfg.slot"
      data-ad-format="auto"
      data-full-width-responsive="true"
      :data-adtest="cfg.test ? 'on' : undefined"
    />
  </aside>
</template>
