// Legends service worker (Sprint 9): makes the site installable as an app (PWA) and opens it
// without a network. The API is never cached: game data always comes live from the server.
const VERSION = 'legends-v1'
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
  if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/match-art/')) return
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
