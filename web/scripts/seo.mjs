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
for (const page of Object.values(PAGES)) {
  const html = index
    .replace(/(<!-- seo:[^>]*-->)[\s\S]*?(<!-- \/seo -->)/, (_, open, close) => `${open}\n    ${seoHead(page)}\n    ${close}`)
    .replace('<div id="app"></div>', () => `<div id="app">${seoBody(page)}</div>`) // [X97] the page's words before the app
  const dir = new URL('.' + page.path + (page.path.endsWith('/') ? '' : '/'), dist)
  mkdirSync(dir, { recursive: true })
  writeFileSync(new URL('index.html', dir), html)
}
writeFileSync(new URL('sitemap.xml', dist), sitemapXml(new Date().toISOString().slice(0, 10)))
writeFileSync(new URL('robots.txt', dist), robotsTxt())
console.log(`seo: ${Object.keys(PAGES).length} pages, sitemap.xml, robots.txt`)
