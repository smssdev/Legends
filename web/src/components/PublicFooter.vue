<script setup lang="ts">
// [X59, X82] The foot of every page [X90: the game's frame, the sign-in screens, the guide and the legal pages]: the game and its
// mark, its quick links (the public pages that exist: router.ts), its social accounts and the support, then the
// copyright (this year, from the device) and the credit line [X98: «GLM Team» opens the team's site]. The accounts and the team come from content/site.ts:
// an account without its real address shows no button. Arabic first, right to left; one column on the phone.
import { computed } from 'vue'
import SupportLinks from './SupportLinks.vue'
import SocialIcon from './SocialIcon.vue'
import { EMAIL, SOCIALS, TEAM } from '../content/site'
import { useAuth } from '../stores/auth'

const year = new Date().getFullYear()
const socials = computed(() => SOCIALS.filter((s) => s.url))
const teamInside = TEAM.url.startsWith('/')
// [X90] A visitor's links (to sign up), or a signed-in coach's own (his teams, leagues, account and ideas).
const auth = useAuth()
const LINKS = computed(() => auth.user ? [
  { to: '/', label: 'فرقي' },
  { to: '/leagues', label: 'دورياتي' },
  { to: '/profile', label: 'حسابي' },
  { to: '/guide', label: 'طريقة اللعب' },
  { to: '/store', label: 'العروض' },
  { to: '/ideas', label: 'اقتراحات التطوير' },
] : [
  { to: '/', label: 'الرئيسية' },
  { to: '/guide', label: 'طريقة اللعب' },
  { to: '/register', label: 'إنشاء حساب مجاني' },
  { to: '/login', label: 'تسجيل الدخول' },
])
const LEGAL = [
  { to: '/privacy', label: 'سياسة الخصوصية' },
  { to: '/terms', label: 'الشروط والأحكام' },
]
</script>

<template>
  <footer class="site-foot relative mt-auto border-t border-gold/25 bg-surface-sunk/60" :aria-label="$t('تذييل الموقع')">
    <span class="foot-line" aria-hidden="true" />
    <div class="mx-auto grid max-w-5xl gap-10 px-4 pb-8 pt-12 md:grid-cols-[1.5fr_1fr_1fr] md:gap-8">
      <!-- The game and its mark. -->
      <section class="flex flex-col gap-4" :aria-label="$t('عن اللعبة')">
        <RouterLink to="/" class="w-fit rounded-md" :aria-label="$t('Game Legend Manager: الصفحة الرئيسية')"><BrandMark /></RouterLink>
        <p class="max-w-sm text-sm leading-7 text-text-soft">
          {{ $t('لعبة مدرب كرة قدم عربية مجانية أونلاين: اختر ناديك، وكوّن دورياً خاصاً مع أصحابك، وأدر كل مباراة حية بالتكتيك والتبديلات.') }}
        </p>
        <RouterLink v-if="!auth.user" to="/register" class="foot-cta flex h-touch w-fit items-center gap-2 rounded-lg bg-gold px-5 font-bold text-on-gold">{{ $t('ابدأ مجاناً') }}</RouterLink>
      </section>

      <!-- The quick links: the game's public pages. -->
      <nav class="flex flex-col gap-3" aria-labelledby="foot-links">
        <h2 id="foot-links" class="foot-head">{{ $t('روابط سريعة') }}</h2>
        <ul class="grid grid-cols-2 gap-x-4 md:flex md:flex-col">
          <li v-for="l in LINKS" :key="l.to">
            <RouterLink :to="l.to" class="foot-link">{{ $t(l.label) }}</RouterLink>
          </li>
        </ul>
      </nav>

      <!-- The game's accounts, and the support. -->
      <section class="flex flex-col gap-3" aria-labelledby="foot-follow">
        <h2 id="foot-follow" class="foot-head">{{ $t('تابعنا') }}</h2>
        <ul class="flex flex-wrap gap-2">
          <li v-for="s in socials" :key="s.key">
            <a :href="s.url!" target="_blank" rel="noopener noreferrer" class="social" :class="`social-${s.key}`" :aria-label="$t('{v0} (يفتح في تبويب جديد)', { v0: s.name })" :title="s.name">
              <SocialIcon :name="s.key" />
            </a>
          </li>
        </ul>
        <p class="pt-2 text-xs text-text-muted">{{ $t('مشكلة أو اقتراح؟ راسلنا:') }}</p>
        <a :href="`mailto:${EMAIL}`" class="foot-link w-fit gap-2 text-sm" dir="ltr">
          <svg viewBox="0 0 24 24" class="size-5 shrink-0" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M3 6h18v12H3zM3 7l9 6 9-6" /></svg>{{ EMAIL }}
        </a>
        <SupportLinks compact no-whatsapp />
      </section>
    </div>

    <!-- The copyright, the legal pages and the credit line. -->
    <div class="border-t border-text/10">
      <div class="mx-auto flex max-w-5xl flex-col gap-3 px-4 py-5 text-xs text-text-muted md:flex-row md:flex-wrap md:items-center md:justify-between">
        <p>
          <span class="copy" aria-hidden="true">©</span><span class="sr-only">{{ $t('حقوق النشر') }}</span> <span class="font-numbers" dir="ltr">{{ year }}</span> <span dir="ltr">Game Legend Manager</span>.
          {{ $t('جميع الحقوق محفوظة.') }}
          <span class="block pt-1 md:inline md:pt-0">{{ $t('لعبة مستقلة، غير تابعة لأي نادٍ أو دوري أو اتحاد كرة قدم.') }}</span>
        </p>
        <nav class="flex flex-wrap items-center gap-x-4" :aria-label="$t('الصفحات القانونية')">
          <RouterLink v-for="l in LEGAL" :key="l.to" :to="l.to" class="foot-link foot-link-sm">{{ $t(l.label) }}</RouterLink>
        </nav>
        <p class="flex items-center gap-1.5" dir="ltr">
          Made with <span class="heart" role="img" :aria-label="$t('حب')">♥</span> by
          <RouterLink v-if="teamInside" :to="TEAM.url" class="team">{{ TEAM.name }}</RouterLink>
          <a v-else :href="TEAM.url" target="_blank" rel="noopener noreferrer" class="team">{{ TEAM.name }}</a>
        </p>
      </div>
    </div>
  </footer>
</template>

<style scoped>
/* [X82] A gold line across the top, brightest in the middle, as on the game's logo. */
.foot-line { position: absolute; inset-inline: 0; top: -1px; height: 2px; background: linear-gradient(90deg, transparent, var(--color-gold), transparent); opacity: 0.7; }
.foot-head { font-family: var(--font-display, inherit); font-size: 0.95rem; font-weight: 800; color: var(--color-text); position: relative; padding-bottom: 0.5rem; }
.foot-head::after { content: ''; position: absolute; inset-inline-start: 0; bottom: 0; width: 2rem; height: 2px; border-radius: 2px; background: var(--color-gold); }
.foot-link { display: inline-flex; min-height: 2.75rem; align-items: center; font-size: 0.9rem; color: var(--color-text-soft); transition: color 0.15s, transform 0.15s; border-radius: 0.375rem; }
.foot-link-sm { min-height: 2.75rem; font-size: 0.8rem; }
.foot-link:hover { color: var(--color-gold); transform: translateX(-3px); }
:dir(ltr) .foot-link:hover { transform: translateX(3px); }
.foot-link.router-link-exact-active { color: var(--color-gold); font-weight: 700; }
/* [X98] Each account its own coloured tile (SocialIcon.vue), lifted a little under the finger or the mouse. */
.social { display: grid; place-items: center; width: 2.75rem; height: 2.75rem; border-radius: 0.75rem; transition: transform 0.15s, filter 0.15s; }
.social:hover { transform: translateY(-2px); filter: brightness(1.08) drop-shadow(0 4px 8px rgb(0 0 0 / 0.3)); }
.team { font-weight: 800; background: linear-gradient(90deg, var(--color-gold), var(--color-brand-light, var(--color-gold))); -webkit-background-clip: text; background-clip: text; color: transparent;
  border-radius: 0.25rem; text-decoration: underline; text-decoration-color: color-mix(in srgb, var(--color-gold) 40%, transparent); text-underline-offset: 3px; }
.team:hover { text-decoration-color: var(--color-gold); }
.copy { font-family: Arial, Helvetica, sans-serif; }
.heart { color: var(--color-live); display: inline-block; animation: beat 1.6s ease-in-out infinite; }
@keyframes beat { 0%, 100% { transform: scale(1) } 15% { transform: scale(1.2) } 30% { transform: scale(1) } }
.foot-cta { transition: filter 0.15s; }
.foot-cta:hover { filter: brightness(1.08); }
/* The keyboard's focus, clear on every link and button of the footer. */
.site-foot :is(a, button):focus-visible { outline: 2px solid var(--color-gold); outline-offset: 3px; }
@media (prefers-reduced-motion: reduce) { .heart { animation: none } .foot-link:hover, .social:hover { transform: none } }
</style>
