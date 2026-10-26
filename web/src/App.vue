<template>
  <!-- A league match's viewer starts afresh when the coach switches to his other live match. The match page stays
       alive while the coach looks at another screen [X41]: its sound and commentary carry on, like the TV in the next
       room (stores/broadcast, the bar in AppShell). One match at a time: opening another closes the one before. -->
  <RouterView v-slot="{ Component, route }">
    <KeepAlive include="SimMatch" :max="1">
      <component :is="Component" :key="route.name === 'league-match' || route.name === 'sim-match' ? route.fullPath.split('?')[0] : undefined" />
    </KeepAlive>
  </RouterView>
</template>
