<script setup lang="ts">
// [Sprint 64 W1] After the sign-up: «play your first match» before anything else. The server makes it (two clubs of
// about the same strength, its three moments), the moments are kept for the match's page, and the page plays it. On
// any failure, or a skip, the way on is the one it replaces (the welcome on the profile).
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ensureCsrf } from '../api/client'
import { sim } from '../api/sim'
import AsyncState from '../components/ui/AsyncState.vue'
import UiButton from '../components/ui/UiButton.vue'
import { keepIntroMoments } from '../match/useIntroMatch'

const router = useRouter()
const failed = ref(false)

onMounted(async () => {
  try {
    await ensureCsrf()
    const m = await sim.intro()
    keepIntroMoments(String(m.id), m.intro.moments)
    void router.replace({ name: 'sim-match', params: { id: String(m.id) } })
  } catch {
    failed.value = true
  }
})
</script>

<template>
  <main class="intro-start">
    <template v-if="!failed">
      <AsyncState loading skeleton="hero" />
      <p>{{ $t('نجهّز مباراتك الأولى...') }}</p>
    </template>
    <template v-else>
      <p>{{ $t('تعذّر تجهيز المباراة التعريفية الآن.') }}</p>
      <UiButton to="/profile?welcome=1">{{ $t('تابع') }}</UiButton>
    </template>
  </main>
</template>

<style scoped>
.intro-start { display: grid; min-block-size: 100dvh; place-content: center; gap: var(--space-md); padding: var(--space-lg); text-align: center; }
</style>
