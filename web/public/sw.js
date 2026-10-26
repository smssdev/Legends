// Legends service worker (Sprint 9): makes the site installable as an app (PWA) and opens it
// without a network. The API is never cached: game data always comes live from the server.
// Sprint 36: the game's notifications (Web Push), and a tap opens the screen they are about.
const VERSION = 'legends-v2'
const SHELL = ['/', '/manifest.webmanifest', '/icon-192.png', '/icon-512.png']

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k)))).then(() => self.clients.claim()),
  )
})

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url)
  if (e.request.method !== 'GET' || url.origin !== location.origin) return
  if (url.pathname.startsWith('/api/')) return
  // Pages: the network first, the saved page when offline.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then((r) => (caches.open(VERSION).then((c) => c.put('/', r.clone())), r))
        .catch(() => caches.match('/')),
    )
    return
  }
  // Built files have their hash in the name, so a saved copy never goes stale.
  if (url.pathname.startsWith('/assets/')) {
    e.respondWith(
      caches.match(e.request).then((hit) => hit ?? fetch(e.request).then((r) => (r.ok && caches.open(VERSION).then((c) => c.put(e.request, r.clone())), r))),
    )
  }
})

// A notification from the server: { title, body, link, tag } [Sprint 36].
self.addEventListener('push', (e) => {
  let n = {}
  try { n = e.data ? e.data.json() : {} } catch { n = { title: 'GLM', body: e.data?.text() ?? '' } }
  e.waitUntil(self.registration.showNotification(n.title || 'GLM', {
    body: n.body || '', tag: n.tag, icon: '/icon-192.png', badge: '/icon-192.png', dir: 'rtl', lang: 'ar', data: { link: n.link || '/' },
  }))
})

// The tap: the open tab goes to the screen, or a new one opens on it.
self.addEventListener('notificationclick', (e) => {
  e.notification.close()
  const link = new URL(e.notification.data?.link || '/', location.origin).href
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((tabs) => {
    const tab = tabs.find((t) => t.url.startsWith(location.origin))
    return tab ? tab.navigate(link).then((t) => t?.focus()) : self.clients.openWindow(link)
  }))
})
