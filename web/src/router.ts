import { createRouter, createWebHistory } from 'vue-router'
import { SECTIONS } from './layouts/nav'
import { useAuth } from './stores/auth'

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
        { path: 'profile', name: 'profile', component: () => import('./pages/Profile.vue'), meta: { auth: true } },
        // Sprint 13: private leagues and the way in
        { path: 'leagues', name: 'leagues', component: () => import('./pages/leagues/MyLeagues.vue'), meta: { auth: true } },
        { path: 'leagues/new', name: 'create-league', component: () => import('./pages/leagues/CreateLeague.vue'), meta: { auth: true } },
        { path: 'leagues/:id(\\d+)', name: 'league-home', component: () => import('./pages/leagues/LeagueHome.vue'), props: true, meta: { auth: true } },
        { path: 'leagues/:id(\\d+)/pick', name: 'pick-team', component: () => import('./pages/leagues/PickTeam.vue'), props: true, meta: { auth: true } },
        // Sprint 16: my club in the current league
        { path: 'team', name: 'team', component: () => import('./pages/team/Squad.vue'), meta: { auth: true } },
        // Sprint 17: tactics and the next match (the live match comes in Sprints 18 to 20)
        { path: 'tactics', name: 'tactics', component: () => import('./pages/team/TacticsPage.vue'), meta: { auth: true } },
        { path: 'match', name: 'match', component: () => import('./pages/team/NextMatch.vue'), meta: { auth: true } },
        { path: 'lineup', name: 'lineup', component: () => import('./pages/team/Lineup.vue'), meta: { auth: true } },
        // Sprint 26: the scout
        { path: 'scout', name: 'scout', component: () => import('./pages/team/ScoutPage.vue'), meta: { auth: true } },
        // Sprint 27: training
        { path: 'training', name: 'training', component: () => import('./pages/team/TrainingPage.vue'), meta: { auth: true } },
        // Sprint 29: the stadium
        { path: 'stadium', name: 'stadium', component: () => import('./pages/team/StadiumPage.vue'), meta: { auth: true } },
        // Sprint 24: the market
        { path: 'market', name: 'market', component: () => import('./pages/team/Market.vue'), meta: { auth: true } },
        // Sprint 23: the club's money
        { path: 'finance', name: 'finance', component: () => import('./pages/team/Finance.vue'), meta: { auth: true } },
        // Sprint 22: the inbox
        { path: 'inbox', name: 'inbox', component: () => import('./pages/Inbox.vue'), meta: { auth: true } },
        { path: 'join/:code?', name: 'join', component: () => import('./pages/leagues/JoinLeague.vue'), meta: { auth: true } },
        // Sprint 11: the component library on a real club
        { path: 'dev/ui', name: 'dev-ui', component: () => import('./pages/UiLibrary.vue') },
      ],
    },
    // Signing in (Sprint 10), outside the navigation
    {
      path: '/',
      component: () => import('./layouts/AuthLayout.vue'),
      meta: { guest: true },
      children: [
        { path: 'login', name: 'login', component: () => import('./pages/auth/Login.vue') },
        { path: 'register', name: 'register', component: () => import('./pages/auth/Register.vue') },
        { path: 'forgot-password', name: 'forgot-password', component: () => import('./pages/auth/ForgotPassword.vue') },
        { path: 'reset-password', name: 'reset-password', component: () => import('./pages/auth/ResetPassword.vue'), meta: { any: true } },
      ],
    },
    // The match and its report fill the screen
    // A league match, live from the server (Sprint 18): the simulator's viewer on the league's match
    { path: '/live/:id(\\d+)', name: 'league-match', component: () => import('./pages/SimMatch.vue'), props: (r) => ({ id: String(r.params.id), league: true }), meta: { auth: true } },
    // Its report, "why you won or lost", for the coach (Sprint 20)
    { path: '/live/:id(\\d+)/report', name: 'league-report', component: () => import('./pages/SimReport.vue'), props: { league: true }, meta: { auth: true } },
    { path: '/sim/room', name: 'sim-room-new', component: () => import('./pages/SimRoom.vue') },
    { path: '/sim/room/:room', name: 'sim-room', component: () => import('./pages/SimRoom.vue'), props: true },
    { path: '/sim/:id', name: 'sim-match', component: () => import('./pages/SimMatch.vue'), props: true },
    { path: '/sim/:id/report', name: 'sim-report', component: () => import('./pages/SimReport.vue'), props: true },
    // W14b: developer preview of the match art, not in production builds
    ...(import.meta.env.DEV ? [{ path: '/dev/art', name: 'dev-art', component: () => import('./pages/ArtPreview.vue') }] : []),
  ],
})

// Screens for the signed-in only send guests to the login (and back after); the login and
// sign-up screens send the signed-in home.
router.beforeEach(async (to) => {
  const auth = useAuth()
  await auth.ready()
  if (to.meta.auth && !auth.signedIn) return { name: 'login', query: { next: to.fullPath } }
  if (to.meta.guest && !to.meta.any && auth.signedIn) return { name: 'home' }
})
