import { cn, ln, loadNames, nm, pn } from './lib/names'
import { i18nReady, t } from './lib/i18n'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import BrandMark from './components/BrandMark.vue'
import AppImage from './components/ui/AppImage.vue'
import { router } from './router'
import { useSeo } from './lib/seo'
import './lib/pwa' // the install offer comes early: keep it for our button [Sprint 36]
import './match/perf' // the smooth mode on weak phones, for the whole app [X30]
import './lib/theme' // the night or the day look [X56]
import { vueHandler, watchErrors } from './lib/errors'

// The names switch [X40]: $nm, $pn, $cn and $ln in every template, and the dictionary fetched once.
loadNames()
const app = createApp(App)
// [Sprint 66 W1] The errors on the players' devices, to our own server (nothing personal: lib/errors.ts).
app.config.errorHandler = vueHandler
watchErrors()
Object.assign(app.config.globalProperties, { $pn: pn, $cn: cn, $ln: ln, $nm: nm, $t: t })
app.component('BrandMark', BrandMark).component('AppImage', AppImage).use(createPinia()).use(router)
useSeo(router) // each page's title, description and keywords for Google [SEO]
// [X81] Google Analytics 4 and the Meta Pixel, with Google's Consent Mode; [Sprint 58 T1] loaded after the first paint.
void import('./lib/analytics').then((m) => m.useAnalytics(router))
// [E1.4] In English, once the dictionary is here (it loads on its own, only for English).
void i18nReady.then(() => app.mount('#app'))

// [X50] After a deploy, a page opened before it asks for the old build's files, which are gone: it loads the new
// build once instead of leaving the screen (the market, the club...) empty. Once a minute at most, never a loop.
function freshBuild(path?: string) {
  try {
    const last = Number(sessionStorage.getItem('glm.reloaded') || 0)
    if (Date.now() - last < 60_000) return false
    sessionStorage.setItem('glm.reloaded', String(Date.now()))
  } catch {}
  if (path) location.assign(path)
  else location.reload()
  return true
}
window.addEventListener('vite:preloadError', (e) => {
  if (freshBuild()) e.preventDefault()
})
router.onError((err, to) => {
  if (/dynamically imported module|Importing a module script failed|Failed to fetch/i.test(String(err?.message))) freshBuild(to.fullPath)
})

// Installable as an app (PWA). Only the built site: in development it would cache stale code.
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js'))
}
