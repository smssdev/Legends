// What Google reads on each page: the title, the description, the keywords and whether it is indexed. One table for
// the build (vite.config.ts writes sitemap.xml, robots.txt and a page per public route with its tags in its <head>)
// and for the browser (src/lib/seo.ts keeps the tags right as the coach moves and switches the language).
// In Arabic the game is «المدرب الأسطورة»; GLM stays the English short name.

export const SITE_URL = 'https://srv2100776.hstgr.cloud'

export const BRAND = { ar: 'المدرب الأسطورة', en: 'GLM · Game Legend Manager' } as const

export interface PageSeo {
  path: string
  title: { ar: string; en: string }
  description: { ar: string; en: string }
  keywords: { ar: string[]; en: string[] }
  /** Its place in sitemap.xml; a page without it is not indexed. */
  sitemap?: { priority: string; changefreq: 'daily' | 'weekly' | 'monthly' }
}

// The words players type, shared by every page.
const COMMON = {
  ar: ['المدرب الأسطورة', 'لعبة المدرب الأسطورة', 'لعبة إدارة كرة القدم', 'لعبة مدرب كرة قدم', 'مدير كرة القدم', 'لعبة كرة قدم أونلاين', 'لعبة كورة اون لاين', 'لعبة كرة قدم عربية'],
  en: ['Game Legend Manager', 'GLM', 'football manager game', 'online football manager', 'soccer manager game', 'Arabic football game'],
}

/** The public pages, by route name. Any other route (a club, a league, the admin) is noindex. */
export const PAGES: Record<string, PageSeo> = {
  home: {
    path: '/',
    title: {
      ar: 'المدرب الأسطورة · لعبة إدارة كرة القدم أونلاين مع أصحابك',
      en: 'GLM · Game Legend Manager, the online football manager with your friends',
    },
    description: {
      ar: 'المدرب الأسطورة لعبة عربية مجانية لإدارة كرة القدم أونلاين: اختر ناديك الحقيقي، وكوّن دورياً خاصاً مع أصحابك، وأدر المباراة حية بالتكتيك والتبديلات، مع السوق والتدريب والملعب والمعلق.',
      en: 'Game Legend Manager is a free online football manager: pick a real club, start a private league with your friends, and run every match live with tactics and substitutions, plus the market, training and the stadium.',
    },
    keywords: {
      ar: ['دوري خاص مع الأصدقاء', 'مباراة مباشرة', 'تكتيك كرة القدم', 'سوق الانتقالات', 'أندية حقيقية', 'لعبة مجانية'],
      en: ['private league with friends', 'live match', 'football tactics', 'transfer market', 'real clubs', 'free game'],
    },
    sitemap: { priority: '1.0', changefreq: 'weekly' },
  },
  register: {
    path: '/register',
    title: { ar: 'إنشاء حساب مجاني | المدرب الأسطورة', en: 'Create a free account | GLM' },
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
    title: { ar: 'تسجيل الدخول | المدرب الأسطورة', en: 'Sign in | GLM' },
    description: {
      ar: 'ادخل إلى حسابك في المدرب الأسطورة وتابع ناديك ودورياتك ومبارياتك الحية.',
      en: 'Sign in to Game Legend Manager and get back to your club, your leagues and your live matches.',
    },
    keywords: { ar: ['تسجيل الدخول', 'دخول اللعبة'], en: ['sign in', 'log in'] },
    sitemap: { priority: '0.6', changefreq: 'monthly' },
  },
  developers: {
    path: '/developers',
    title: { ar: 'فريق التطوير | المدرب الأسطورة', en: 'The developers | GLM' },
    description: {
      ar: 'تعرّف على فريق تطوير المدرب الأسطورة، لعبة إدارة كرة القدم العربية، وقصة بنائها.',
      en: 'Meet the team behind Game Legend Manager, the Arabic football manager game, and the story of how it was built.',
    },
    keywords: { ar: ['مطورو اللعبة', 'فريق المدرب الأسطورة'], en: ['game developers', 'GLM team'] },
    sitemap: { priority: '0.4', changefreq: 'monthly' },
  },
  // [X57] The privacy policy and the terms, open to everyone.
  privacy: {
    path: '/privacy',
    title: { ar: 'سياسة الخصوصية | المدرب الأسطورة', en: 'Privacy policy | GLM' },
    description: {
      ar: 'سياسة الخصوصية في المدرب الأسطورة: ما نجمعه من بيانات ولماذا، والإعلانات والكوكيز، وحقك في حذف حسابك.',
      en: 'Game Legend Manager\'s privacy policy: what we collect and why, the ads and cookies, and your right to delete your account.',
    },
    keywords: { ar: ['سياسة الخصوصية', 'حذف الحساب'], en: ['privacy policy', 'delete account'] },
    sitemap: { priority: '0.3', changefreq: 'monthly' },
  },
  terms: {
    path: '/terms',
    title: { ar: 'الشروط والأحكام | المدرب الأسطورة', en: 'Terms and conditions | GLM' },
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
    `<meta property="og:site_name" content="${BRAND.ar}" />`,
    `<meta property="og:title" content="${esc(title)}" />`,
    `<meta property="og:description" content="${esc(description)}" />`,
    `<meta property="og:url" content="${urlOf(page.path, 'ar')}" />`,
    `<meta property="og:image" content="${SITE_URL}/brand/og-invite.png" />`,
    `<meta property="og:locale" content="ar_AR" />`,
    `<meta property="og:locale:alternate" content="en_GB" />`,
    `<meta name="twitter:card" content="summary_large_image" />`,
  ].join('\n    ')
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
  return `User-agent: *\nAllow: /\n${closed.map((p) => `Disallow: ${p}`).join('\n')}\n\nUser-agent: Mediapartners-Google\nAllow: /\nDisallow: /api/\n\nSitemap: ${SITE_URL}/sitemap.xml\n`
}
