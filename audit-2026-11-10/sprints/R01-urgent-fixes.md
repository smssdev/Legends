# R01: الإسعاف (الأمان والأخطاء الظاهرة)

| | |
|---|---|
| **الحالة** | 📝 مقترح، ينتظر قرار صاحب المشروع |
| **المدة** | 4 أيام عمل |
| **المرحلة** | أ. الإسعاف |
| **المنصة** | ويب، تطبيق، خادم |
| **يعتمد على** | لا شيء |

## الهدف

إغلاق كل ما يراه اللاعب خطأً اليوم، وكل ثغرة تُغلق في ساعات، بلا أي تغيير في شكل اللعبة أو قواعدها. كل بند PR صغير مستقل (كما في Sprint 30).

## لماذا (من التقريرين)

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
| T1 | **مع هذا السبرنت من R16:** إعادة تشغيل CI (ينجح بعد B3)، وتشغيله على كل PR | جودة | `.github/workflows/ci.yml` |

## تعريف الانتهاء

- [ ] `curl -I https://gamelegendmanager.online/` يُظهر HSTS و`Permissions-Policy` و`Content-Security-Policy-Report-Only`، وبلا `X-Powered-By`، وبلا ترويسة مكررة.
- [ ] `curl -H "Origin: https://example.com" …/api/v1/health` بلا `Access-Control-Allow-Origin: *`.
- [ ] `composer audit` بلا تنبيهات، و`php artisan test` أخضر على القاعدتين.
- [ ] لا تمرير أفقي في أي شاشة من 36 (اختبار W1).
- [ ] `SecurityHeadersTest` يفحص رد صفحة HTML لا رد الـ API وحده.
- [ ] CI أخضر، وحمزة راجع كل PR.

## كيف يُختبر باليد

1. افتح أي شاشة في النادي على الجوال واسحب يميناً ويساراً: لا تتحرك الصفحة.
2. أوقف الخادم ثانيتين أثناء فتح اللعبة: تبقى مسجلاً، وتظهر «تعذر الاتصال».
3. أغلق كل تبويبات اللعبة، واستقبل إشعاراً وانقره: تفتح شاشته.
4. بدّل للإنجليزية: «Undo» في الإشعار بعد أي فعل يُتراجع عنه.
5. في التطبيق: عنوان الشريط العلوي بخط باقي الواجهة.

## المخاطر

- **CSP قد تكسر AdSense أو الدخول بجوجل:** لذلك تبدأ بوضع المراقبة، ولا تصير ملزِمة إلا بعد أسبوع من السجل النظيف.
- **تحديث Symfony:** نسخة فرعية، والاختبارات (570) تغطيه.
