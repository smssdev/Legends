// After the build [SEO]: sitemap.xml and robots.txt, and each public page as its own HTML (dist/register/index.html...)
// with its title, description and keywords already in its <head> (src/content/seo.ts), for the crawlers that do not
// run the app. The server sends a page's own HTML when there is one (deploy/docker/router.php), else index.html.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { PAGES, robotsTxt, seoBody, seoHead, sitemapXml } from '../src/content/seo.ts'

const dist = new URL('../dist/', import.meta.url)
const index = readFileSync(new URL('index.html', dist), 'utf8')
if (!/<!-- seo:[^>]*-->[\s\S]*?<!-- \/seo -->/.test(index) || !index.includes('<div id="app"></div>')) {
  console.error('index.html: the <!-- seo --> block or the empty <div id="app"></div> is missing')
  process.exit(1)
}
// [Sprint 75 W9, WEB-09] Each page in English too (index.en.html beside it, sent for ?lang=en by router.php): its <html>
// in English left to right, its tags and words in English, and the English emblem on the splash.
const lang = (html, l) =>
  l === 'ar'
    ? html
    : html
        .replace('<html lang="ar" dir="rtl">', '<html lang="en" dir="ltr">')
        .replaceAll('/brand/emblem-loader-ar.svg', '/brand/emblem-loader.svg')
if (!index.includes('<html lang="ar" dir="rtl">')) {
  console.error('index.html: <html lang="ar" dir="rtl"> is missing (the English pages replace it)')
  process.exit(1)
}
for (const page of Object.values(PAGES)) {
  const dir = new URL('.' + page.path + (page.path.endsWith('/') ? '' : '/'), dist)
  mkdirSync(dir, { recursive: true })
  for (const l of ['ar', 'en']) {
    const html = lang(index, l)
      .replace(/(<!-- seo:[^>]*-->)[\s\S]*?(<!-- \/seo -->)/, (_, open, close) => `${open}\n    ${seoHead(page, l)}\n    ${close}`)
      .replace('<div id="app"></div>', () => `<div id="app">${seoBody(page, l)}</div>`) // [X97] the page's words before the app
    writeFileSync(new URL(l === 'ar' ? 'index.html' : 'index.en.html', dir), html)
  }
}
writeFileSync(new URL('sitemap.xml', dist), sitemapXml(new Date().toISOString().slice(0, 10)))
writeFileSync(new URL('robots.txt', dist), robotsTxt())
console.log(`seo: ${Object.keys(PAGES).length} pages in Arabic and English, sitemap.xml, robots.txt`)
