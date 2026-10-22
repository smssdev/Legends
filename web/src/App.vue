<template>
  <!-- A league match's viewer starts afresh when the coach switches to his other live match. -->
  <RouterView v-slot="{ Component, route }">
    <component :is="Component" :key="route.name === 'league-match' ? route.fullPath : undefined" />
  </RouterView>
</template>
