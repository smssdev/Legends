<template>
  <!-- [Sprint 30 Q1] reka-ui's primitives (Slider, Tooltip…) take the direction from here: right to left in Arabic. -->
  <ConfigProvider :dir="locale === 'ar' ? 'rtl' : 'ltr'">
  <TooltipProvider :delay-duration="250">
  <!-- A league match's viewer starts afresh when the coach switches to his other live match. The match page stays
       alive while the coach looks at another screen [X41]: its sound and commentary carry on, like the TV in the next
       room (stores/broadcast, the bar in AppShell). One match at a time: opening another closes the one before. -->
  <RouterView v-slot="{ Component, route }">
    <!-- [X74] Only a live match stays behind the other screens; a recorded one, or one closed from the bar, goes. -->
    <KeepAlive :include="broadcast.keep ? 'SimMatch' : []" :max="1">
      <component :is="Component" :key="route.name === 'league-match' || route.name === 'sim-match' ? route.path : undefined" />
    </KeepAlive>
  </RouterView>
  <!-- [UP4] The splash, once per visit, over the game until the server answers. -->
  <SplashScreen v-if="splash" @done="splash = false" />
  <!-- [Sprint 30 Q2] The one «are you sure» window (stores/confirm). -->
  <ConfirmHost />
  </TooltipProvider>
  </ConfigProvider>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ConfigProvider, TooltipProvider } from 'reka-ui'
import { locale } from './lib/i18n'
import SplashScreen from './components/SplashScreen.vue'
import ConfirmHost from './components/shell/ConfirmHost.vue'
import { useBroadcast } from './stores/broadcast'

const splash = ref(true)
const broadcast = useBroadcast()
</script>
