// What Google reads on each page: the title, the description, the keywords and whether it is indexed. One table for
// the build (vite.config.ts writes sitemap.xml, robots.txt and a page per public route with its tags in its <head>)
// and for the browser (src/lib/seo.ts keeps the tags right as the coach moves and switches the language).
// [Sprint 39 B1] The game's official name is Game Legend Manager, in every language; in Arabic «المدرب الأسطورة» follows it.

/**
 * The site's address [X70, Sprint 39 B3]: one setting, PUBLIC_URL on the server, which the image's build passes here as
 * VITE_SITE_URL (Dockerfile, deploy/vps/compose.yml), so moving to gamelegendmanager.online is a server setting and a
 * deploy. The build (Vite, in the browser) and scripts/seo.mjs (Node, after it) read it each their own way.
 */
const env = (import.meta as { env?: Record<string, string | undefined> }).env?.VITE_SITE_URL
  ?? (globalThis as { process?: { env: Record<string, string | undefined> } }).process?.env.VITE_SITE_URL
export const SITE_URL = (env || 'https://gamelegendmanager.online').replace(/\/+$/, '')

export const BRAND = { ar: 'Game Legend Manager · المدرب الأسطورة', en: 'Game Legend Manager' } as const

export interface PageSeo {
  path: string
  title: { ar: string; en: string }
  description: { ar: string; en: string }
  keywords: { ar: string[]; en: string[] }
  /** The page's own heading in the HTML the crawlers read first [X97]; the title when absent. */
  heading?: { ar: string; en: string }
  /** Its place in sitemap.xml; a page without it is not indexed. */
  sitemap?: { priority: string; changefreq: 'daily' | 'weekly' | 'monthly' }
}

// The words players type, shared by every page.
// [Sprint 39 B2] The owner's words first (simple and compound searches), in both languages on every page: a search in
// either language finds the game.
const COMMON = {
  // [X97] The name as people type it: with and without the hamza, with ه for ة, and the short name GLM.
  ar: ['Game Legend Manager', 'المدرب الأسطورة', 'المدرب الاسطورة', 'المدرب الاسطوره', 'لعبة المدرب الأسطورة', 'لعبة المدرب الاسطوره', 'GLM', 'لعبة GLM', 'لعبة مدرب كرة قدم', 'المدرب الأفضل', 'لعبة كرة قدم تكتيكية', 'تدريب أندية أونلاين',
    'بيع وشراء لاعبين', 'لعبة إدارة كرة القدم', 'مدير كرة القدم', 'لعبة كرة قدم أونلاين', 'لعبة كورة اون لاين', 'لعبة كرة قدم عربية', 'لعبة مدرب كورة',
    'Football Manager Web', 'Soccer Simulation Game', 'Best Online Football Tactics'],
  en: ['Game Legend Manager', 'GLM', 'Football Manager Web', 'Soccer Simulation Game', 'Best Online Football Tactics', 'football manager game',
    'online football manager', 'soccer manager game', 'football coach game', 'football tactics game', 'buy and sell players', 'online club management',
    'Arabic football game', 'لعبة مدرب كرة قدم'],
}

/** The public pages, by route name. Any other route (a club, a league, the admin) is noindex. */
export const PAGES: Record<string, PageSeo> = {
  home: {
    path: '/',
    title: {
      ar: 'Game Legend Manager (GLM) · المدرب الأسطورة: لعبة مدرب كرة قدم أونلاين مع أصحابك',
      en: 'Game Legend Manager (GLM): the online football manager and soccer simulation game',
    },
    heading: { ar: 'المدرب الأسطورة · Game Legend Manager (GLM)', en: 'Game Legend Manager (GLM) · المدرب الأسطورة' },
    description: {
      ar: 'المدرب الأسطورة (Game Legend Manager، واختصاره GLM) لعبة مدرب كرة قدم تكتيكية مجانية أونلاين: اختر ناديك الحقيقي، وكوّن دورياً خاصاً مع أصحابك، وأدر المباراة حية بالتكتيك والتبديلات، مع بيع وشراء اللاعبين والتدريب والملعب.',
      en: 'Game Legend Manager (GLM, المدرب الأسطورة) is a free online football manager: pick a real club, start a private league with your friends, and run every match live with tactics and substitutions, plus the market, training and the stadium.',
    },
    keywords: {
      ar: ['دوري خاص مع الأصدقاء', 'مباراة مباشرة', 'تكتيك كرة القدم', 'سوق الانتقالات', 'أندية حقيقية', 'لعبة مجانية', 'محاكاة مباريات كرة القدم'],
      en: ['private league with friends', 'live match', 'football tactics', 'transfer market', 'real clubs', 'free game', 'football match simulator'],
    },
    sitemap: { priority: '1.0', changefreq: 'weekly' },
  },
  register: {
    path: '/register',
    title: { ar: 'إنشاء حساب مجاني | Game Legend Manager', en: 'Create a free account | Game Legend Manager' },
    description: {
      ar: 'سجّل مجاناً في المدرب الأسطورة وابدأ مسيرتك مدرباً: اختر ناديك، وادعُ أصحابك إلى دوري خاص بكود، ونافس على الدوري والكأس كل موسم.',
      en: 'Sign up free to Game Legend Manager and start your coaching career: pick your club, invite your friends to a private league with a code, and fight for the league and the cup every season.',
    },
    keywords: {
      ar: ['تسجيل لعبة كرة قدم', 'حساب مجاني', 'ابدأ مدرباً', 'دوري بكود'],
      en: ['sign up football game', 'free account', 'start as a coach', 'league code'],
    },
    sitemap: { priority: '0.9', changefreq: 'monthly' },
  },
  login: {
    path: '/login',
    title: { ar: 'تسجيل الدخول | Game Legend Manager', en: 'Sign in | Game Legend Manager' },
    description: {
      ar: 'ادخل إلى حسابك في المدرب الأسطورة وتابع ناديك ودورياتك ومبارياتك الحية.',
      en: 'Sign in to Game Legend Manager and get back to your club, your leagues and your live matches.',
    },
    keywords: { ar: ['تسجيل الدخول', 'دخول اللعبة'], en: ['sign in', 'log in'] },
    sitemap: { priority: '0.6', changefreq: 'monthly' },
  },
  developers: {
    path: '/developers',
    title: { ar: 'فريق التطوير | Game Legend Manager', en: 'The developers | Game Legend Manager' },
    description: {
      ar: 'تعرّف على فريق تطوير المدرب الأسطورة، لعبة إدارة كرة القدم العربية، وقصة بنائها.',
      en: 'Meet the team behind Game Legend Manager, the Arabic football manager game, and the story of how it was built.',
    },
    keywords: { ar: ['مطورو اللعبة', 'فريق المدرب الأسطورة'], en: ['game developers', 'GLM team'] },
    sitemap: { priority: '0.4', changefreq: 'monthly' },
  },
  // [X59] The game's guide, open to everyone: the Assistant Coach's explanations, the site's richest page.
  guide: {
    path: '/guide',
    title: { ar: 'طريقة اللعب: دليل Game Legend Manager الكامل', en: 'How to play: the complete Game Legend Manager guide' },
    description: {
      ar: 'دليل المدرب الأسطورة كاملاً: كيف تبني ناديك، وتختار تكتيكك، وتدرّب لاعبيك، وتدير السوق والملعب والمالية، وتعيش المباراة مباشرة.',
      en: 'The complete Game Legend Manager guide: how to build your club, choose your tactics, train your players, run the market, stadium and money, and live every match.',
    },
    keywords: {
      ar: ['طريقة اللعب', 'دليل اللعبة', 'شرح التكتيك', 'التدريب', 'سوق الانتقالات', 'الكأس'],
      en: ['how to play', 'game guide', 'tactics explained', 'training', 'transfer market', 'cup'],
    },
    sitemap: { priority: '0.8', changefreq: 'weekly' },
  },
  // [X57] The privacy policy and the terms, open to everyone.
  privacy: {
    path: '/privacy',
    title: { ar: 'سياسة الخصوصية | Game Legend Manager', en: 'Privacy policy | Game Legend Manager' },
    description: {
      ar: 'سياسة الخصوصية في المدرب الأسطورة: ما نجمعه من بيانات ولماذا، والإعلانات والكوكيز، وحقك في حذف حسابك.',
      en: 'Game Legend Manager\'s privacy policy: what we collect and why, the ads and cookies, and your right to delete your account.',
    },
    keywords: { ar: ['سياسة الخصوصية', 'حذف الحساب'], en: ['privacy policy', 'delete account'] },
    sitemap: { priority: '0.3', changefreq: 'monthly' },
  },
  terms: {
    path: '/terms',
    title: { ar: 'الشروط والأحكام | Game Legend Manager', en: 'Terms and conditions | Game Legend Manager' },
    description: {
      ar: 'شروط استخدام المدرب الأسطورة: اللعب النظيف، والكوينز، والحسابات، وحقوق المدربين.',
      en: 'Game Legend Manager\'s terms of use: fair play, the coins, the accounts and the coaches\' rights.',
    },
    keywords: { ar: ['شروط الاستخدام', 'اللعب النظيف'], en: ['terms of use', 'fair play'] },
    sitemap: { priority: '0.3', changefreq: 'monthly' },
  },
}

/** A page's keywords with the shared ones, as one meta content. */
export function keywordsOf(page: PageSeo, l: 'ar' | 'en'): string {
  return [...page.keywords[l], ...COMMON[l]].join(l === 'ar' ? '، ' : ', ')
}

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

/** A page's address in a language: Arabic is the page itself, English adds ?lang=en (src/lib/i18n.ts reads it). */
export const urlOf = (path: string, l: 'ar' | 'en') => SITE_URL + path + (l === 'en' ? '?lang=en' : '')

/** The tags of a page's <head> in Arabic, written into its HTML by the build (between <!-- seo --> and <!-- /seo -->). */
export function seoHead(page: PageSeo): string {
  const l = 'ar'
  const title = page.title[l]
  const description = page.description[l]
  return [
    `<title>${esc(title)}</title>`,
    `<meta name="description" content="${esc(description)}" />`,
    `<meta name="keywords" content="${esc(keywordsOf(page, l))}" />`,
    `<meta name="robots" content="index, follow" />`,
    `<link rel="canonical" href="${urlOf(page.path, 'ar')}" />`,
    `<link rel="alternate" hreflang="ar" href="${urlOf(page.path, 'ar')}" />`,
    `<link rel="alternate" hreflang="en" href="${urlOf(page.path, 'en')}" />`,
    `<link rel="alternate" hreflang="x-default" href="${urlOf(page.path, 'ar')}" />`,
    `<meta property="og:type" content="website" />`,
    `<meta property="og:site_name" content="${esc(BRAND.ar)}" />`,
    `<meta property="og:title" content="${esc(title)}" />`,
    `<meta property="og:description" content="${esc(description)}" />`,
    `<meta property="og:url" content="${urlOf(page.path, 'ar')}" />`,
    `<meta property="og:image" content="${SITE_URL}/brand/og-invite.png" />`,
    `<meta property="og:image:width" content="1200" />`,
    `<meta property="og:image:height" content="630" />`,
    `<meta property="og:image:alt" content="Game Legend Manager" />`,
    `<meta property="og:locale" content="ar_AR" />`,
    `<meta property="og:locale:alternate" content="en_GB" />`,
    `<meta name="twitter:card" content="summary_large_image" />`,
    `<meta name="twitter:title" content="${esc(title)}" />`,
    `<meta name="twitter:description" content="${esc(description)}" />`,
    `<meta name="twitter:image" content="${SITE_URL}/brand/og-invite.png" />`,
  ].join('\n    ')
}

/**
 * [X97] What a crawler reads in a page's HTML before the app starts: its heading, its description, and links to the
 * other public pages (written into <div id="app"> by the build; the app replaces it when it mounts, so a visitor sees
 * it only for the instant the game loads). The same words as the page itself, nothing hidden.
 */
export function seoBody(page: PageSeo): string {
  const l = 'ar'
  const links = Object.values(PAGES).filter((p) => p.sitemap && p.path !== page.path)
    .map((p) => `<a href="${p.path}">${esc(p.title[l].split(/ \| |: /)[0])}</a>`).join(' · ')
  return [
    `<main class="seo-static">`,
    `<img src="/icon-192.png" alt="المدرب الأسطورة · Game Legend Manager" width="96" height="96" />`,
    `<h1>${esc((page.heading ?? page.title)[l])}</h1>`,
    `<p>${esc(page.description[l])}</p>`,
    `<nav>${links}</nav>`,
    `</main>`,
  ].join('')
}

/** sitemap.xml: the public pages, each with its English twin. */
export function sitemapXml(lastmod: string): string {
  const urls = Object.values(PAGES).filter((p) => p.sitemap).map((p) => {
    const alt = (['ar', 'en'] as const).map((l) => `    <xhtml:link rel="alternate" hreflang="${l}" href="${esc(urlOf(p.path, l))}" />`).join('\n')
    return `  <url>\n    <loc>${urlOf(p.path, 'ar')}</loc>\n${alt}\n    <lastmod>${lastmod}</lastmod>\n    <changefreq>${p.sitemap!.changefreq}</changefreq>\n    <priority>${p.sitemap!.priority}</priority>\n  </url>`
  })
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${urls.join('\n')}\n</urlset>\n`
}

/** robots.txt: the public pages open, the API and the private screens closed, and where the sitemap is. Google's
 * ads crawler (AdSense, X57) reads every page but the API, so the ads match the screens they show on. */
export function robotsTxt(): string {
  const closed = ['/api/', '/admin', '/sanctum/', '/broadcasting/', '/auth/google/', '/email/verify/', '/live/', '/sim/', '/dev/', '/reset-password', '/forgot-password']
  return `User-agent: *\nAllow: /\n${closed.map((p) => `Disallow: ${p}`).join('\n')}\n\nUser-agent: Mediapartners-Google\nAllow: /\nDisallow: /api/\nDisallow: /admin\n\nSitemap: ${SITE_URL}/sitemap.xml\n`
}
