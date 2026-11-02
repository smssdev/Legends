// The page's tags as the coach moves and switches the language [SEO] (src/content/seo.ts): the title, the description,
// the keywords and the links Google reads. The public pages are indexed; every other screen (a club, a league, a
// match) is noindex, since it is the coach's own.
import { watch } from 'vue'
import type { RouteLocationNormalized, Router } from 'vue-router'
import { BRAND, PAGES, keywordsOf, urlOf } from '../content/seo'
import { locale } from './i18n'

function meta(attr: 'name' | 'property', key: string, content: string) {
  let el = document.head.querySelector(`meta[${attr}="${key}"]`)
  if (!el) {
    el = document.head.appendChild(document.createElement('meta'))
    el.setAttribute(attr, key)
  }
  el.setAttribute('content', content)
}
function link(rel: string, href: string) {
  let el = document.head.querySelector(`link[rel="${rel}"]`)
  if (!el) {
    el = document.head.appendChild(document.createElement('link'))
    el.setAttribute('rel', rel)
  }
  el.setAttribute('href', href)
}

function apply(to: RouteLocationNormalized) {
  const l = locale.value
  const page = PAGES[String(to.name)]
  if (!page) {
    // A screen of the coach's own: the game's name for its tab, and out of Google.
    document.title = BRAND[l]
    meta('name', 'robots', 'noindex, nofollow')
    document.head.querySelector('link[rel="canonical"]')?.remove()
    return
  }
  document.title = page.title[l]
  meta('name', 'description', page.description[l])
  meta('name', 'keywords', keywordsOf(page, l))
  meta('name', 'robots', 'index, follow')
  meta('property', 'og:title', page.title[l])
  meta('property', 'og:description', page.description[l])
  meta('property', 'og:url', urlOf(page.path, l))
  meta('property', 'og:site_name', BRAND[l])
  meta('property', 'og:locale', l === 'ar' ? 'ar_AR' : 'en_GB')
  meta('name', 'twitter:title', page.title[l])
  meta('name', 'twitter:description', page.description[l])
  link('canonical', urlOf(page.path, l))
}

export function useSeo(router: Router) {
  router.afterEach((to) => apply(to))
  watch(locale, () => apply(router.currentRoute.value))
}
