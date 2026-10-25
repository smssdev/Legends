import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import BrandMark from './components/BrandMark.vue'
import { router } from './router'
import './lib/pwa'   // the install offer comes early: keep it for our button [Sprint 36]
import './match/perf'   // the smooth mode on weak phones, for the whole app [X30]

createApp(App).component('BrandMark', BrandMark).use(createPinia()).use(router).mount('#app')

// Installable as an app (PWA). Only the built site: in development it would cache stale code.
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js'))
}
