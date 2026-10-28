// Legends service worker (Sprint 9): makes the site installable as an app (PWA) and opens it
// without a network. The API is never cached: game data always comes live from the server.
// Sprint 36: the game's notifications (Web Push), and a tap opens the screen they are about.
const VERSION = 'legends-v5'
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
  // [X51] The server's own pages (signing in with Google, its callback) go straight to the network: the worker must
  // not stand between the browser and Google's redirect.
  if (url.pathname.startsWith('/auth/')) return
  // Pages: the network first, the saved page when offline. [X50] Only a good page is saved, and the server's error
  // while it restarts for a deploy (502) shows the saved page instead.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then((r) => {
          // [X51] A redirect is the browser's to follow, never replaced by the saved page.
          if (r.type === 'opaqueredirect' || r.redirected) return r
          // [X51] The copy is taken now: the page reads the body as soon as the response is returned.
          if (r.ok) { const copy = r.clone(); caches.open(VERSION).then((c) => c.put('/', copy)); return r }
          return caches.match('/').then((hit) => hit ?? r)
        })
        .catch(() => caches.match('/')),
    )
    return
  }
  // Built files have their hash in the name, so a saved copy never goes stale.
  if (url.pathname.startsWith('/assets/')) {
    e.respondWith(
      caches.match(e.request).then((hit) => hit ?? fetch(e.request).then((r) => {
        if (r.ok) { const copy = r.clone(); caches.open(VERSION).then((c) => c.put(e.request, copy)) }
        return r
      })),
    )
  }
})

// A notification from the server: { title, body, link, tag } [Sprint 36].
self.addEventListener('push', (e) => {
  let n = {}
  try { n = e.data ? e.data.json() : {} } catch { n = { title: 'GLM', body: e.data?.text() ?? '' } }
  // [Sprint 21 E3.6] The game's own buzz on Android (a browser gives a push notification no sound of its own), and
  // the text's direction from its language: an English coach's notification reads left to right.
  const arabic = /[\u0600-\u06FF]/.test((n.title || '') + (n.body || ''))
  e.waitUntil(self.registration.showNotification(n.title || 'GLM', {
    body: n.body || '', tag: n.tag, icon: '/icon-192.png', badge: '/icon-192.png', dir: arabic ? 'rtl' : 'ltr', lang: arabic ? 'ar' : 'en',
    vibrate: [90, 50, 90, 50, 220], renotify: !!n.tag, data: { link: n.link || '/' },
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
