import { createRouter, createWebHistory } from 'vue-router'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/sim' },
    { path: '/sim', name: 'sim-setup', component: () => import('./pages/SimSetup.vue') },
    { path: '/sim/:id', name: 'sim-match', component: () => import('./pages/SimMatch.vue'), props: true },
    { path: '/sim/:id/report', name: 'sim-report', component: () => import('./pages/SimReport.vue'), props: true },
  ],
})
