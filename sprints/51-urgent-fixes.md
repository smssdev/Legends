# Sprint 51: الإسعاف (الأمان والأخطاء الظاهرة)

| | |
|---|---|
| **الحالة** | 🔄 مبني (2026-11-11)، وينتظر مراجعة حمزة، ونشره، وخطوتين على السيرفر وفي GitHub (تحت) |
| **من** | 2026-11-11 |
| **المدة** | 4 أيام عمل |
| **المرحلة** | أ. الإسعاف |
| **المنصة** | ويب، تطبيق، خادم |
| **يعتمد على** | لا شيء |

## الهدف

إغلاق كل ما يراه اللاعب خطأً اليوم، وكل ثغرة تُغلق في ساعات، بلا أي تغيير في شكل اللعبة أو قواعدها. PR واحد للسبرنت (الجلسة على فرع واحد)، وكل بند فيه منفصل في وصفه وفي «ما أُنجز» تحت.

## لماذا (رموز الملاحظات من [تقرير الويب](../audit-2026-11-10/01-web-audit.md) و[تقرير التطبيق](../audit-2026-11-10/02-mobile-audit.md))

W-S01، W-S02، W-S03، W-S04، W-S05، W-S09، W-B01، W-B02، W-B03، W-B04، W-B05، M-B02، M-B03.

## المهام

| الرمز | المهمة | النوع | الملفات |
|---|---|---|---|
| B1 | **ترويسات الأمان على صفحة اللعبة:** `send()` في `router.php` يضيف لكل رد HTML: `Strict-Transport-Security`، و`X-Content-Type-Options`، و`X-Frame-Options`، و`Referrer-Policy`، و`Permissions-Policy` (القيم نفسها في `SecurityHeaders.php`، من ثابت واحد يقرؤه الاثنان) | خادم | `deploy/docker/router.php`، `app/Http/Middleware/SecurityHeaders.php` |
| B2 | **CSP كاملة بوضع المراقبة أولاً:** `Content-Security-Policy-Report-Only` فيها `default-src 'self'`، و`script-src` لنا ولـ Google (AdSense، وGA، والدخول)، و`connect-src 'self' wss:` والتحليلات، و`img-src 'self' data: blob: https:`، و`style-src 'self' 'unsafe-inline'`، و`font-src 'self'`. ومسار `POST /api/v1/csp-report` (بحد محاولات) يسجّل المخالفات. بعد أسبوع بلا مخالفات تصير ملزِمة | خادم | نفسها، `routes/api.php` |
| B3 | **`composer update symfony/http-foundation`** وما يتبعه حتى يصير `composer audit` نظيفاً، ثم الاختبارات على SQLite وPostgreSQL | خادم | `backend/composer.lock` |
| B4 | **CORS:** `config/cors.php` يحصر `allowed_origins` في `APP_URL` (والتطبيق لا يحتاج CORS) | خادم | `backend/config/cors.php` |
| B5 | **إخفاء إصدار PHP:** `expose_php=Off` في `zz-legends-speed.ini`. وإعداد Nginx للموقع يُكتب في `deploy/vps/nginx-site.conf` (نسخة مما على السيرفر، بلا ترويسات مكررة) | خادم | `Dockerfile`، `deploy/vps/` |
| W1 | **التمرير الأفقي:** `overflow-x: clip` على جذر `AppShell`، وهامش يسع الشارة في الشريط. واختبار متصفح يفحص `scrollWidth <= clientWidth` على 20 شاشة النادي | ويب | `layouts/AppShell.vue`، `e2e/` |
| W2 | **إشعار يفتح شاشته دائماً:** `tab.navigate(link).catch(() => clients.openWindow(link))`، و`VERSION` يُرفع | ويب | `public/sw.js` |
| W3 | **تعثر `/auth/me` لا يُخرج المدرب:** 401 أو 204 = غير مسجّل. غير ذلك: محاولتان بفاصل ثانية، ثم شاشة «تعذر الاتصال» بزر إعادة، لا تحويل إلى الدخول | ويب | `stores/auth.ts`، `router.ts` |
| W4 | **الترجمة:** إزالة `$t` المكررة، و`t()` على «بدأت مباراتك الآن» و«تراجع» و«نهاية المباراة». و`scripts/i18n.mjs` يفحص النصوص العربية في ملفات `.ts` أيضاً (قائمة استثناء للمفاتيح نفسها) | ويب | `AppShell.vue`، `lib/action.ts`، `SimMatch.vue`، `scripts/i18n.mjs` |
| W5 | **محادثة المساعد تُمسح عند الخروج** من الحساب | ويب | `stores/bot.ts`، `stores/auth.ts` |
| F1 | **خط عنوان الشريط:** `fontFamily: GlmFonts.body` في `GameBar`، واختبار يتأكد أن عائلة خط العنوان Tajawal | تطبيق | `features/leagues/shell.dart` |
| F2 | **مؤقت الوقت المستقطع** يُحفظ في حقل ويُلغى في `dispose` | تطبيق | `features/match/live_screen.dart` |
| T1 | **مع هذا السبرنت من Sprint 66:** إعادة تشغيل CI (ينجح بعد B3)، وتشغيله على كل PR | جودة | `.github/workflows/ci.yml` |

## تعريف الانتهاء

- [ ] `curl -I https://gamelegendmanager.online/` يُظهر HSTS و`Permissions-Policy` و`Content-Security-Policy-Report-Only`، وبلا `X-Powered-By`، وبلا ترويسة مكررة. **بعد النشر، ولصق `deploy/vps/nginx-site.conf` في CloudPanel (سليمان).**
- [x] الـ API لا يفتح لموقع آخر (`config/cors.php`، اختبار `test_the_api_is_not_open_to_other_sites`). ويُتحقق على الموقع بعد النشر بـ `curl -H "Origin: https://example.com" …/api/v1/health`.
- [x] `composer audit` بلا تنبيهات، و`php artisan test` أخضر على SQLite (573 ناجحاً). **PostgreSQL ينتظر CI.**
- [x] لا تمرير أفقي في 20 شاشة × 3 مقاسات (`e2e/layout.spec.ts`).
- [x] `SecurityHeadersTest` يشغّل `router.php` الحقيقي بخادم PHP ويفحص صفحة HTML وملفاً مبنياً.
- [ ] CI أخضر: **معطّل من إعدادات حساب GitHub لا من الكود** (تحت، T1). وحمزة راجع الـ PR.

## كيف يُختبر باليد

1. افتح أي شاشة في النادي على الجوال واسحب يميناً ويساراً: لا تتحرك الصفحة.
2. أوقف الخادم ثانيتين أثناء فتح اللعبة: تبقى مسجلاً، وتظهر «تعذر الاتصال».
3. أغلق كل تبويبات اللعبة، واستقبل إشعاراً وانقره: تفتح شاشته.
4. بدّل للإنجليزية: «Undo» في الإشعار بعد أي فعل يُتراجع عنه.
5. في التطبيق: عنوان الشريط العلوي بخط باقي الواجهة.

## المخاطر

- **CSP قد تكسر AdSense أو الدخول بجوجل:** لذلك تبدأ بوضع المراقبة، ولا تصير ملزِمة إلا بعد أسبوع من السجل النظيف.
- **تحديث Symfony:** نسخة فرعية، والاختبارات (570) تغطيه.

## ما أُنجز وكيف يُختبر

**B1 ترويسات الأمان على صفحة اللعبة.** `App\Http\Security\SecurityPolicy` (PHP بلا Laravel) مصدر واحد للترويسات: يستعمله `SecurityHeaders` لردود Laravel، ويقرؤه `deploy/docker/router.php` مباشرة (`require_once`) لكل ما يرسله قبل Laravel: صفحة اللعبة، والملفات المبنية، ورد `/app/`. وHSTS حين يأتي الطلب بـ HTTPS (`X-Forwarded-Proto` من Nginx). **الاختبار:** `test_the_router_serves_the_page_with_the_security_headers` يشغّل `router.php` بخادم PHP حقيقي على صفحة فيها سكربت داخلي وJSON-LD، ويفحص الترويسات على الصفحة وعلى ملف JS.

**B2 CSP كاملة بوضع المراقبة.** `Content-Security-Policy-Report-Only` على كل رد: `default-src 'self'`، والسكربتات لنا ولـ Google Analytics وAdSense وMeta Pixel، و`'wasm-unsafe-eval'` لـ Unity WebGL، و**سكربتات الصفحة الداخلية ببصمتها** (`sha256-…` يحسبها الراوتر من `index.html` نفسه، فلا `'unsafe-inline'` للسكربتات). والمخالفات إلى `POST /api/v1/csp-report` (`CspReportController`، 30 في الدقيقة، بلا XSRF) تُكتب في السجل سطراً قصيراً بلا روابط الاستعلام. السياسة الملزمة الحالية باقية كما هي. **التالي:** بعد أسبوع من النشر، اقرأ `docker logs legends-app-1 | grep csp` (أو `storage/logs/laravel.log`)، وحين يخلو من مخالفات حقيقية تُنقل `fullPolicy()` إلى `Content-Security-Policy` (سطر واحد في `SecurityPolicy::headers`). **الاختبار:** `test_the_browser_reports_a_csp_violation_without_a_session`، وفحص البصمة في اختبار الراوتر.

**B3 Symfony.** `composer update "symfony/*"` داخل 7.4 (16 حزمة، إصدارات تصحيحية): `composer audit` نظيف (كانت 3 تنبيهات في `http-foundation` ثم ظهرت 3 في `http-kernel` و`routing` و`yaml`). 573 اختباراً ناجحة.

**B4 CORS.** `backend/config/cors.php`: الأصل المسموح `APP_URL` (و`FRONTEND_URL`) وحده، بدل `*`. الويب من الدومين نفسه، والتطبيق وUnity بتوكن ليسا متصفحاً. **الاختبار:** `test_the_api_is_not_open_to_other_sites`.

**B5 إصدار PHP وإعداد Nginx.** `expose_php=Off` في الصورة (`Dockerfile`)، و`header_remove('X-Powered-By')` في الراوتر. و`deploy/vps/nginx-site.conf` نسخة من موقع CloudPanel بلا ترويسات الأمان المكررة (اللعبة ترسلها الآن) و`server_tokens off`. **على سليمان:** يلصق الكتلتين في CloudPanel ← Sites ← gamelegendmanager.online ← Vhost (مع سطري الشهادة كما هما)، ثم `curl -sI https://gamelegendmanager.online/ | sort` فلا تظهر ترويسة مرتين.

**W1 التمرير الأفقي.** السبب أعمق مما في التقرير: زرّا «المؤقتات» و«ما ينتظرك» من `PopoverButton` في Headless UI، والنمط المحصور (`scoped`) لم يصل إليهما، فكانا يُرسمان 22px بلا دائرة، وشارتهما معلّقة على حافة الشاشة. صار نمطاهما عامين (`:global(.bar-icon)`)، فعادا دائرتين بشارتهما، وجذر الإطار `overflow-x: clip`. **الاختبار:** `web/e2e/layout.spec.ts` يمر على 20 شاشة × 3 مقاسات (915×412، 667×375، 1440×900) ويفشل على أي تمرير أفقي. جُرّب على الإطار القديم: فشل بـ «917 > 915» في كل شاشة نادٍ.

**W2 الإشعار.** في `sw.js` إن رفض التبويب التنقل (لا يتحكم به العامل) أو لم يرجع نافذة، تُفتح نافذة جديدة. `VERSION` صار `legends-v8`.

**W3 تعثر `/auth/me`.** `stores/auth.ts`: 401 و419 = غير مسجّل. أي خطأ آخر (انقطاع، 5xx، نشر) يُعاد مرتين بفاصل ثانية، ثم `unreachable`: الموجّه لا يحوّل إلى الدخول، و`App.vue` يعرض شريط «تعذر الاتصال بالخادم» بزر «حاول مجدداً» يعيد السؤال ثم يعيد فتح الصفحة. **جُرّب في المتصفح:** حجب `/auth/me` ثم فتح `/club`: بقي على `/club` بالشريط، وبعد رفع الحجب والضغط اختفى الشريط.

**W4 الترجمة.** `$t` المكررة في شريط البث، و`t()` على «بدأت مباراتك الآن» و«تراجع» و«نهاية المباراة». و`scripts/i18n.mjs` صار يفحص كل جملة عربية في ملفات `.ts` أيضاً (لا داخل `t()` فقط)، بقائمة ملفات مستثناة لكل واحد سببه: المحتوى ثنائي اللغة في ملفه (`legal.ts`، `seo.ts`)، وكلمات الجمع العربية المستعملة بالعربية فقط (`format.ts`، `clock.ts`، `dates.ts`)، وجدول التعليق العربي (`commentary.ts`). وأربعة ملفات ثغرات معروفة، كل واحد باسم السبرنت الذي يغلقه (56، 57، 63). **جُرّب:** ملف جديد فيه جملة عربية بلا ترجمة يوقف البناء ويسمّيها.

**W5 محادثة المساعد.** الخروج من الحساب يمسح المحادثة المحفوظة والمعروضة (`useBot().forget(true)`).

**F1 خط عنوان الشريط في التطبيق.** `GameBar` بـ `fontFamily: GlmFonts.body`. **الاختبار:** `mobile/test/game_bar_test.dart` (فشل بلا الإصلاح: `Expected: 'Tajawal' Actual: <null>`).

**F2 مؤقت الوقت المستقطع** في `live_screen.dart` محفوظ في `_timeoutEnd`، ويُلغى قبل أي مؤقت جديد وفي `dispose`.

**T1 CI: لم يكتمل، والسبب خارج الكود.** كل وظائف CI وPackage تفشل خلال ثانيتين قبل أي خطوة، على كل دفع منذ مدة، حتى على PR وثائق فقط (#781). هذا رفض من GitHub لتشغيل الوظائف (غالباً حد الإنفاق أو الدفع في إعدادات الحساب)، لا خطأ في `ci.yml`. **على سليمان:** github.com ← Settings ← Billing and plans ← Actions، ثم Re-run لآخر تشغيل. وحتى يعود، الفحوص محلية كما ينص `CLAUDE.md`.

**ووُجد أثناء القياس (W-D24، مضاف إلى Sprint 54):** خط `html` 14px، فكل مقاس بـ `rem` أصغر بـ 12.5%: أزرار الشريط 39px لا 44، و`UiButton` 42px لا 48.

**الفحوص المحلية:** `php artisan test` (573 ناجحاً، 1 متخطى)، و`vendor/bin/pint --test`، و`composer audit`، و`npm run build` (الأنواع وi18n وframes وfeed)، و`npm run api` (`schema.d.ts` محدّث)، و`npx playwright test e2e/layout.spec.ts`، و`flutter analyze` و`flutter test` (68 ناجحاً).

**ما بقي:** النشر بموافقة صاحب المشروع حين «آمن للنشر»، ولصق إعداد Nginx، وإصلاح إعداد Actions، وبعد أسبوع جعل CSP ملزمة.

## ملاحظات وتعديلات بالتوازي

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| | | | |
