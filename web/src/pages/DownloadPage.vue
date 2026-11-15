<script setup lang="ts">
import Icon from '../components/Icon.vue'
// [Sprint 15 D1, the owner's request 2026-11-06] The app from the site itself: the Android app (the latest APK the
// admins uploaded, from our own server), and on the iPhone the game added to the home screen from Safari, where it
// opens as an app (README section 0: no App Store, 2026-11-14). The visitor's own phone comes first.
import { computed, onMounted, ref } from 'vue'
import { api } from '../api/client'
import PublicFooter from '../components/PublicFooter.vue'
import PublicHeader from '../components/PublicHeader.vue'
import UiButton from '../components/ui/UiButton.vue'
import { intlLocale } from '../lib/i18n'
import { install, installable, isIos, standalone } from '../lib/pwa'

type Release = {
  version: string
  bytes: number
  published_at: string | null
  url: string | null
  notes: string | null
  old_phones_url?: string | null
  build?: number | null
}
const android = ref<Release | null>(null)
const loaded = ref(false)
const ios = isIos()
const isAndroid = /android/i.test(typeof navigator !== 'undefined' ? navigator.userAgent : '')
const order = computed(() => (ios ? ['ios', 'android'] : ['android', 'ios']))
const mb = (b: number) => new Intl.NumberFormat(intlLocale(), { maximumFractionDigits: 1 }).format(b / 1048576)
const day = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(iso))

onMounted(async () => {
  try {
    android.value = ((await api.GET('/app')).data as any)?.android ?? null
  } catch {
    /* the page still shows the iPhone way */
  }
  loaded.value = true
})
</script>

<template>
  <div class="min-h-dvh bg-bg">
    <PublicHeader />
    <main class="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
      <header class="flex flex-col items-center gap-3 text-center">
        <AppImage src="/icon-192.png" alt="" class="size-24 rounded-3xl shadow-lg" :size="96" />
        <h1 class="font-display text-3xl font-extrabold md:text-4xl">{{ $t('حمّل اللعبة على جوالك') }}</h1>
        <p class="max-w-xl leading-relaxed text-text-soft">
          {{ $t('نفس حسابك ونفس دورياتك في الموقع والتطبيق: ادخل بحسابك وتكمل من حيث توقفت.') }}
        </p>
      </header>

      <div class="grid gap-4 md:grid-cols-2">
        <template v-for="k in order" :key="k">
          <!-- Android: the APK from our own server. -->
          <section
            v-if="k === 'android'"
            class="flex flex-col gap-4 rounded-2xl border bg-surface p-5"
            :class="isAndroid ? 'border-gold/60' : 'border-surface-raised'"
            :aria-label="$t('أندرويد')"
          >
            <div class="flex items-center gap-3">
              <svg viewBox="0 0 24 24" class="size-10 fill-success" aria-hidden="true">
                <path
                  d="M17.6 9.5 19.4 6.4a.4.4 0 0 0-.7-.4l-1.8 3.1A11 11 0 0 0 12 8a11 11 0 0 0-4.9 1.1L5.3 6a.4.4 0 0 0-.7.4l1.8 3.1A10.3 10.3 0 0 0 1 18h22a10.3 10.3 0 0 0-5.4-8.5ZM7 15.3a1 1 0 1 1 1-1 1 1 0 0 1-1 1Zm10 0a1 1 0 1 1 1-1 1 1 0 0 1-1 1Z"
                />
              </svg>
              <div>
                <h2 class="font-display text-2xl font-bold">{{ $t('أندرويد') }}</h2>
                <p v-if="android" class="text-sm text-text-muted">
                  <span dir="ltr"
                    >{{ android.version }}<template v-if="android.build">+{{ android.build }}</template></span
                  >
                  · {{ $t('{n} ميجا', { n: mb(android.bytes) })
                  }}<template v-if="android.published_at"> · {{ day(android.published_at) }}</template>
                </p>
              </div>
            </div>
            <template v-if="android?.url">
              <a
                :href="android.url"
                download
                class="flex min-h-touch items-center justify-center gap-2 rounded-xl bg-gold px-5 py-3 font-display text-lg font-extrabold text-on-gold"
                ><Icon name="download" :size="16" class="inline-block align-[-3px]" /> {{ $t('نزّل التطبيق') }}</a
              >
              <ol class="flex list-decimal flex-col gap-1.5 ps-5 text-sm leading-relaxed text-text-soft">
                <li>{{ $t('اضغط «نزّل التطبيق» وانتظر حتى يكتمل التنزيل.') }}</li>
                <li>{{ $t('افتح الملف من الإشعارات أو «التنزيلات»، وإن سألك الجوال فاسمح بالتثبيت من هذا المصدر.') }}</li>
                <li>{{ $t('افتح «المدرب الأسطورة» وادخل بحسابك.') }}</li>
              </ol>
              <p v-if="android.notes" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm text-text-muted">{{ android.notes }}</p>
              <!-- [Sprint 62 F2] The move to the game's fixed key: the signed version does not install over the earlier one. -->
              <p class="rounded-lg border border-gold/40 bg-gold/10 px-3 py-2 text-sm text-text-soft">
                {{
                  $t(
                    'ثبّتّ التطبيق من قبل ورفض الجوال التحديث؟ احذف النسخة القديمة مرة واحدة ثم ثبّت هذه: حسابك ودورياتك على الخادم فلا يضيع شيء، وكل نسخة بعدها تُثبَّت فوق التي قبلها.',
                  )
                }}
              </p>
              <a v-if="android.old_phones_url" :href="android.old_phones_url" download class="text-sm text-text-muted underline">{{
                $t('جوال قديم لا يقبل التثبيت؟ نزّل نسخة الجوالات القديمة')
              }}</a>
            </template>
            <template v-else-if="loaded">
              <p class="text-text-soft">{{ $t('تطبيق أندرويد قريباً هنا. والآن ثبّت الموقع على جوالك فيفتح كتطبيق.') }}</p>
              <UiButton v-if="installable" @click="install">{{ $t('ثبّت الآن') }}</UiButton>
            </template>
          </section>

          <!-- iPhone: the site on the home screen from Safari, the game's way on the iPhone (the owner, 2026-11-14: no paid Apple account, no App Store). -->
          <section
            v-else
            class="flex flex-col gap-4 rounded-2xl border bg-surface p-5"
            :class="ios ? 'border-gold/60' : 'border-surface-raised'"
            :aria-label="$t('آيفون')"
          >
            <div class="flex items-center gap-3">
              <svg viewBox="0 0 24 24" class="size-10 fill-text" aria-hidden="true">
                <path
                  d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9a4.8 4.8 0 0 0-3.8-2c-1.6-.2-3.1.9-3.9.9s-2-.9-3.4-.9a5 5 0 0 0-4.2 2.6c-1.8 3.1-.5 7.7 1.3 10.2.8 1.2 1.8 2.6 3.1 2.5s1.7-.8 3.2-.8 1.9.8 3.2.8 2.2-1.2 3-2.5a10.6 10.6 0 0 0 1.4-2.8 4.3 4.3 0 0 1-2.1-4.1ZM14 5.1a4.4 4.4 0 0 0 1-3.1 4.4 4.4 0 0 0-2.9 1.5 4.1 4.1 0 0 0-1 3 3.6 3.6 0 0 0 2.9-1.4Z"
                />
              </svg>
              <div>
                <h2 class="font-display text-2xl font-bold">{{ $t('آيفون') }}</h2>
                <p class="text-sm text-text-muted">{{ $t('من Safari، بلا متجر') }}</p>
              </div>
            </div>
            <p class="text-text-soft">{{ $t('ثبّت اللعبة من Safari على شاشتك الرئيسية، فتفتح كتطبيق بأيقونتها وتصلك التذكيرات:') }}</p>
            <ol class="flex list-decimal flex-col gap-1.5 ps-5 text-sm leading-relaxed text-text-soft">
              <li>{{ $t('افتح gamelegendmanager.online في Safari.') }}</li>
              <li>{{ $t('اضغط زر المشاركة (المربع والسهم للأعلى).') }}</li>
              <li>{{ $t('اختر «إضافة إلى الشاشة الرئيسية» ثم «إضافة».') }}</li>
            </ol>
            <p v-if="ios && standalone()" class="rounded-lg bg-success/15 px-3 py-2 text-sm">{{ $t('اللعبة مثبتة على جوالك.') }}</p>
          </section>
        </template>
      </div>
    </main>
    <PublicFooter />
  </div>
</template>
