import { createRouter, createWebHistory } from 'vue-router'
import { SECTIONS } from './layouts/nav'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    // The game's screens, inside the navigation (Sprint 9 W1)
    {
      path: '/',
      component: () => import('./layouts/AppShell.vue'),
      children: [
        { path: '', name: 'home', component: () => import('./pages/Home.vue') },
        ...SECTIONS.filter((s) => s.sprint).map((s) => ({ path: s.path.slice(1), name: s.name, component: () => import('./pages/ComingSoon.vue') })),
        { path: 'sim', name: 'sim-setup', component: () => import('./pages/SimSetup.vue') },
      ],
    },
    // The match and its report fill the screen
    { path: '/sim/room', name: 'sim-room-new', component: () => import('./pages/SimRoom.vue') },
    { path: '/sim/room/:room', name: 'sim-room', component: () => import('./pages/SimRoom.vue'), props: true },
    { path: '/sim/:id', name: 'sim-match', component: () => import('./pages/SimMatch.vue'), props: true },
    { path: '/sim/:id/report', name: 'sim-report', component: () => import('./pages/SimReport.vue'), props: true },
    // W14b: developer preview of the match art, not in production builds
    ...(import.meta.env.DEV ? [{ path: '/dev/art', name: 'dev-art', component: () => import('./pages/ArtPreview.vue') }] : []),
  ],
})
