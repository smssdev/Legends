// Legends service worker (Sprint 9): makes the site installable as an app (PWA) and opens it
// without a network. The API is never cached: game data always comes live from the server.
// Sprint 36: the game's notifications (Web Push), and a tap opens the screen they are about.
// [Sprint 58 W5] Generated at the build (scripts/sw.mjs): the build's own version, and what it saves first (the app's
// shell, its built files, the fonts and the icons). Each build is a new cache, and activating it deletes the older
// ones (W-B08: they grew with every deploy). Pages: one app shell, never one page under another's address (W-B09).
const VERSION = 'glm-__BUILD__'
const PRECACHE = [/*__PRECACHE__*/]
// The commentary's audio and the crests: kept after their first use (they rarely change), at most MEDIA_MAX of them.
const MEDIA = 'glm-media'
const MEDIA_MAX = 300
const SHELL = '/shell.html'

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(PRECACHE)).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== VERSION && k !== MEDIA).map((k) => caches.delete(k)))).then(() => self.clients.claim()),
  )
})

async function keepMedia(req, res) {
  const c = await caches.open(MEDIA)
  await c.put(req, res)
  const keys = await c.keys()
  // The oldest leave first.
  for (const k of keys.slice(0, Math.max(0, keys.length - MEDIA_MAX))) await c.delete(k)
}

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url)
  if (e.request.method !== 'GET' || url.origin !== location.origin) return
  if (url.pathname.startsWith('/api/')) return
  // [X51] The server's own pages (signing in with Google, its callback) go straight to the network: the worker must
  // not stand between the browser and Google's redirect.
  if (url.pathname.startsWith('/auth/')) return
  // [Sprint 15 D1] The app's file downloads as itself, never through the worker (nor saved as a page).
  if (url.pathname.startsWith('/downloads/')) return
  // Pages: the network first; offline, or the server's error while it restarts for a deploy (502) [X50], the app's
  // shell, which opens the address asked for and says it has no connection.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then((r) => {
          // [X51] A redirect is the browser's to follow, never replaced by the shell.
          if (r.type === 'opaqueredirect' || r.redirected || r.ok) return r
          return caches.match(SHELL).then((hit) => hit ?? r)
        })
        .catch(() => caches.match(SHELL).then((hit) => hit ?? Response.error())),
    )
    return
  }
  // Built files and the fonts: their names change with their content, so a saved copy never goes stale.
  if (url.pathname.startsWith('/assets/') || url.pathname.startsWith('/fonts/')) {
    e.respondWith(
      caches.match(e.request).then((hit) => hit ?? fetch(e.request).then((r) => {
        if (r.ok) { const copy = r.clone(); caches.open(VERSION).then((c) => c.put(e.request, copy)) }
        return r
      })),
    )
    return
  }
  // The commentary's audio and the crests: the saved copy first, at most MEDIA_MAX of them.
  if (url.pathname.startsWith('/commentary/') || url.pathname.startsWith('/crests/')) {
    e.respondWith(
      caches.match(e.request).then((hit) => hit ?? fetch(e.request).then((r) => {
        if (r.ok && r.status === 200) { const copy = r.clone(); keepMedia(e.request, copy) }
        return r
      })),
    )
    return
  }
  // Anything else (the emblems, the icons): the network first, the saved copy when offline.
  e.respondWith(fetch(e.request).catch(() => caches.match(e.request).then((hit) => hit ?? Response.error())))
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
    // [Sprint 51 W2] A tab the worker does not control refuses navigate(): a new window then, never a dead tap.
    if (!tab) return self.clients.openWindow(link)
    return tab.navigate(link).then((t) => (t ? t.focus() : self.clients.openWindow(link))).catch(() => self.clients.openWindow(link))
  }))
})
