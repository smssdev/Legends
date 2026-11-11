import { createRouter, createWebHistory } from 'vue-router'
import { SECTIONS } from './layouts/nav'
import { currentLeague } from './lib/currentLeague'
import { useAuth } from './stores/auth'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    // The game's screens, inside the navigation (Sprint 9 W1)
    {
      path: '/',
      component: () => import('./layouts/AppShell.vue'),
      children: [
        { path: '', name: 'home', component: () => import('./pages/Home.vue'), meta: { wide: true } },  // [Sprint 21 E3.4] wider on a computer
        ...SECTIONS.filter((s) => s.sprint).map((s) => ({ path: s.path.slice(1), name: s.name, component: () => import('./pages/ComingSoon.vue') })),
        { path: 'sim', name: 'sim-setup', component: () => import('./pages/SimSetup.vue') },
        { path: 'profile', name: 'profile', component: () => import('./pages/Profile.vue'), meta: { auth: true } },
        // Sprint 13: private leagues and the way in
        { path: 'leagues', name: 'leagues', component: () => import('./pages/leagues/MyLeagues.vue'), meta: { auth: true } },
        { path: 'leagues/new', name: 'create-league', component: () => import('./pages/leagues/CreateLeague.vue'), meta: { auth: true } },
        { path: 'leagues/:id(\\d+)', name: 'league-home', component: () => import('./pages/leagues/LeagueHome.vue'), props: true, meta: { auth: true } },
        // Sprint 37: the admin panel (the admin only, after the two-step code)
        { path: 'admin', name: 'admin', component: () => import('./pages/AdminPage.vue'), meta: { auth: true, admin: true } },
        // Sprint 34: the coins wallet and the shop
        { path: 'wallet', name: 'wallet', component: () => import('./pages/WalletPage.vue'), meta: { auth: true } },
        // [Sprint 43 W2] The store: packages and timed offers, ordered by WhatsApp.
        { path: 'store', name: 'store', component: () => import('./pages/StorePage.vue'), meta: { auth: true } },
        // Sprint 33: a coach's profile
        { path: 'coaches/:id(\\d+)', name: 'coach', component: () => import('./pages/leagues/CoachProfile.vue'), props: true, meta: { auth: true } },
        // [X27] The alliance tournament
        { path: 'leagues/:id(\\d+)/alliance', name: 'league-alliance', component: () => import('./pages/leagues/AlliancePage.vue'), props: true, meta: { auth: true } },
        // [X26] The live draw
        { path: 'leagues/:id(\\d+)/draw', name: 'league-draw', component: () => import('./pages/leagues/DrawPage.vue'), props: true, meta: { auth: true } },
        // [UP12] The league's media
        { path: 'leagues/:id(\\d+)/predictions', name: 'league-predictions', component: () => import('./pages/leagues/PredictionsPage.vue'), props: true, meta: { auth: true } },
        { path: 'leagues/:id(\\d+)/newspaper', name: 'league-newspaper', component: () => import('./pages/leagues/NewspaperPage.vue'), props: true, meta: { auth: true } },
        { path: 'leagues/:id(\\d+)/pick', name: 'pick-team', component: () => import('./pages/leagues/PickTeam.vue'), props: true, meta: { auth: true } },
        // Sprint 16: my club in the current league
        // [Sprint 20] The club board, the friendlies and the weekly quests.
        { path: 'club', name: 'club', component: () => import('./pages/team/ClubBoard.vue'), meta: { auth: true, fit: true } },
        { path: 'friendlies', name: 'friendlies', component: () => import('./pages/team/FriendliesPage.vue'), meta: { auth: true } },
        { path: 'quests', name: 'quests', component: () => import('./pages/team/QuestsPage.vue'), meta: { auth: true } },
        { path: 'team', name: 'team', component: () => import('./pages/team/Squad.vue'), meta: { auth: true } },
        // Sprint 17: tactics and the next match (the live match comes in Sprints 18 to 20)
        { path: 'tactics', name: 'tactics', component: () => import('./pages/team/TacticsPage.vue'), meta: { auth: true } },
        { path: 'match', name: 'match', component: () => import('./pages/team/NextMatch.vue'), meta: { auth: true } },
        { path: 'lineup', name: 'lineup', component: () => import('./pages/team/Lineup.vue'), meta: { auth: true } },
        // Sprint 26: the scout
        { path: 'scout', name: 'scout', component: () => import('./pages/team/ScoutPage.vue'), meta: { auth: true } },
        // Sprint 27: training
        { path: 'training', name: 'training', component: () => import('./pages/team/TrainingPage.vue'), meta: { auth: true } },
        // Sprint 31: the specialists
        { path: 'specialists', name: 'specialists', component: () => import('./pages/team/SpecialistsPage.vue'), meta: { auth: true } },
        // [Sprint 48 T4] The captain and the set-piece takers, a card each (were at the foot of the lineup).
        { path: 'takers', name: 'takers', component: () => import('./pages/team/TakersPage.vue'), meta: { auth: true } },
        // Sprint 29: the stadium
        { path: 'stadium', name: 'stadium', component: () => import('./pages/team/StadiumPage.vue'), meta: { auth: true } },
        // Sprint 24: the market
        { path: 'market', name: 'market', component: () => import('./pages/team/Market.vue'), meta: { auth: true } },
        // Sprint 23: the club's money
        { path: 'finance', name: 'finance', component: () => import('./pages/team/Finance.vue'), meta: { auth: true } },
        { path: 'stats', name: 'stats', component: () => import('./pages/team/StatsPage.vue'), meta: { auth: true } },
        // [Sprint 21 E4.3] The season's fixtures; and «الدوري والكأس» outside a club opens the leagues.
        // [Sprint 21 E7.7] The conversation with the developers.
        { path: 'support', name: 'support', component: () => import('./pages/SupportPage.vue'), meta: { auth: true } },
        // [Sprint 28] The development ideas: suggestions, polls and the honour roll.
        { path: 'ideas', name: 'ideas', component: () => import('./pages/IdeasPage.vue'), meta: { auth: true } },
        { path: 'fixtures', name: 'fixtures', component: () => import('./pages/leagues/FixturesPage.vue'), meta: { auth: true } },
        { path: 'league', name: 'league', redirect: '/leagues' },
        // Sprint 22: the inbox
        // [Sprint 29] The chat groups and the tournaments (the draw fills the screen, below).
        { path: 'groups', name: 'groups', component: () => import('./pages/groups/GroupsPage.vue'), meta: { auth: true } },
        { path: 'groups/join/:code', name: 'group-join', component: () => import('./pages/groups/JoinGroup.vue'), props: true, meta: { auth: true } },
        { path: 'groups/:id(\\d+)', name: 'group', component: () => import('./pages/groups/GroupChat.vue'), props: true, meta: { auth: true } },
        { path: 'tournaments', name: 'tournaments', component: () => import('./pages/tournaments/TournamentsPage.vue'), meta: { auth: true } },
        { path: 'tournaments/new', name: 'create-tournament', component: () => import('./pages/tournaments/CreateTournament.vue'), meta: { auth: true } },
        { path: 'tournaments/:id(\\d+)', name: 'tournament', component: () => import('./pages/tournaments/TournamentPage.vue'), props: true, meta: { auth: true } },
        { path: 'inbox', name: 'inbox', component: () => import('./pages/Inbox.vue'), meta: { auth: true } },
        // [X54] The developers' announcements as cards.
        { path: 'announcements', name: 'announcements', component: () => import('./pages/AnnouncementsPage.vue'), meta: { auth: true } },
        { path: 'join/:code?', name: 'join', component: () => import('./pages/leagues/JoinLeague.vue'), meta: { auth: true } },
        // Sprint 11: the component library on a real club. [Sprint 30 P4] The admins' only (or any one in development).
        { path: 'dev/ui', name: 'dev-ui', component: () => import('./pages/UiLibrary.vue'), meta: { auth: true, admin: true } },
        { path: 'dev/status', name: 'dev-status', component: () => import('./pages/DevStatus.vue'), meta: { auth: true, admin: true } },
        // [X61] The league's media without a league in the address (an old link): into my current league's, or the leagues.
        ...(['newspaper', 'predictions'] as const).map((page) => ({
          path: page,
          component: () => import('./pages/NotFound.vue'),
          meta: { auth: true },
          beforeEnter: async () => {
            const league = await currentLeague()
            return league ? `/leagues/${league}/${page}` : '/leagues'
          },
        })),
        // [X61] Any other address: «الصفحة غير موجودة» inside the shell, never a white screen.
        { path: ':pathMatch(.*)*', name: 'not-found', component: () => import('./pages/NotFound.vue') },
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
    // [X57] The privacy policy and the terms, open to everyone (Google AdSense and the stores ask for them)
    { path: '/privacy', name: 'privacy', component: () => import('./pages/LegalPage.vue'), props: { kind: 'privacy' } },
    { path: '/terms', name: 'terms', component: () => import('./pages/LegalPage.vue'), props: { kind: 'terms' } },
    // [Sprint 15 D1] The app to download (Android) or install (iPhone), open to everyone
    { path: '/download', name: 'download', component: () => import('./pages/DownloadPage.vue') },
    // [X59] The game's guide, open to everyone
    { path: '/guide', name: 'guide', component: () => import('./pages/GuidePage.vue') },
    // The match and its report fill the screen
    // A league match, live from the server (Sprint 18): the simulator's viewer on the league's match
    { path: '/tournaments/:id(\\d+)/draw', name: 'tournament-draw', component: () => import('./pages/tournaments/TournamentDraw.vue'), props: true, meta: { auth: true } },
    { path: '/live/:id(\\d+)', name: 'league-match', component: () => import('./pages/SimMatch.vue'), props: (r) => ({ id: String(r.params.id), league: true }), meta: { auth: true } },
    // Its report, "why you won or lost", for the coach (Sprint 20)
    { path: '/live/:id(\\d+)/report', name: 'league-report', component: () => import('./pages/SimReport.vue'), props: { league: true }, meta: { auth: true } },
    { path: '/sim/room', name: 'sim-room-new', component: () => import('./pages/SimRoom.vue') },
    { path: '/sim/room/:room', name: 'sim-room', component: () => import('./pages/SimRoom.vue'), props: true },
    { path: '/sim/:id', name: 'sim-match', component: () => import('./pages/SimMatch.vue'), props: true },
    { path: '/sim/:id/report', name: 'sim-report', component: () => import('./pages/SimReport.vue'), props: true },
  ],
})

// Screens for the signed-in only send guests to the login (and back after); the login and
// sign-up screens send the signed-in home.
router.beforeEach(async (to) => {
  // [Sprint 21 E2.3] An invite link's ?ref=12345 is kept for the sign-up, wherever the link lands.
  if (typeof to.query.ref === 'string' && /^\d{5}$/.test(to.query.ref)) {
    try {
      localStorage.setItem('glm.ref', to.query.ref)
    } catch {}
  }
  const auth = useAuth()
  await auth.ready()
  // [Sprint 51 W3] Unknown (the server did not answer) is not signed out: the page stays, App.vue offers to try again.
  if (auth.unreachable) return
  if (to.meta.auth && !auth.signedIn) return { name: 'login', query: { next: to.fullPath } }
  // [Sprint 30 P4] The developers' pages: «الصفحة غير موجودة» for anyone else on the server.
  if (to.meta.admin && !import.meta.env.DEV && auth.user?.role !== 'admin') {
    return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') }, replace: true }
  }
  if (to.meta.guest && !to.meta.any && auth.signedIn) return { name: 'home' }
})
