# Sprint 59: بنية التطبيق (عقد مولّد، وحالة مختبرة، وقواعد صارمة)

| | |
|---|---|
| **الحالة** | ⏳ معتمد من صاحب المشروع (2026-11-11)، ولم يبدأ |
| **المدة** | 7 أيام عمل |
| **المرحلة** | ب. الأساس |
| **المنصة** | تطبيق (`mobile/`) |
| **يعتمد على** | لا شيء (يسير مع Sprint 55) |

## الهدف

أن يكسر تغيير الخادم **بناء** التطبيق لا التطبيق عند اللاعب، وأن يُختبر منطق كل شاشة بلا رسمها، وأن يرفض التحليل ما يمر اليوم. بلا تغيير في الشكل.

## لماذا (رموز الملاحظات من [تقرير الويب](../audit-2026-11-10/01-web-audit.md) و[تقرير التطبيق](../audit-2026-11-10/02-mobile-audit.md))

M-Sprint 51، M-Sprint 52، M-Sprint 53، M-Sprint 54، M-Sprint 55، M-Sprint 57، M-Sprint 58، M-B01، M-B04، M-B05، M-B07، M-B09، M-B10، M-B12، M-S05، M-F01، M-F03.

## المهام

| الرمز | المهمة | الملفات |
|---|---|---|
| F1 | **نماذج مولّدة من `openapi.yaml`:** `swagger_parser` (أو `openapi_generator`) يولّد النماذج و`fromJson` إلى `lib/api/gen/`. و`mobile.yml` يولّد ويفحص `git diff --exit-code` (كما `npm run api` في الويب). النماذج اليدوية تُستبدل ميزةً ميزة: السوق، ثم الفريق، ثم المباراة، ثم الباقي | `mobile/lib/api/gen/`، `mobile.yml`، كل `*_data.dart` |
| F2 | **قراءة متسامحة:** حقل جديد غير معروف لا يكسر، وحقل مطلوب ناقص يعطي خطأ واحداً واضحاً مسجّلاً (Sprint 66) لا شاشة حمراء | `lib/core/api/` |
| F3 | **قواعد التحليل:** `strict-casts`، و`strict-inference`، و`strict-raw-types`، و`unawaited_futures`، و`use_build_context_synchronously`، و`prefer_const_constructors`، و`avoid_dynamic_calls`، و`cancel_subscriptions`. و`formatter: page_width: 140` و`dart format --set-exit-if-changed` في CI. تُصلح على ثلاث دفعات | `analysis_options.yaml`، `mobile.yml` |
| F4 | **ملف لكل شاشة:** `social_screens.dart` (16 صنفاً) إلى `features/groups/`، و`features/coach/`، و`features/ideas/`، و`features/support/`. و`league_screen.dart` (19 صنفاً) إلى تبويباته. و`account_screens.dart`، و`tournament_screens.dart`، و`extras_screens.dart`، و`sim_screens.dart` كذلك. التسمية: `*_screen.dart`، و`*_repository.dart`، و`*_models.dart` | `lib/features/` |
| F5 | **`Notifier` للشاشات التي تعدّل:** التشكيلة، والتكتيك، والسوق، والمباراة الحية، والدردشة. الشاشة ترسم الحالة وترسل الأفعال فقط. اختبار وحدة لكل واحد (بمستودع وهمي) يغطي: الحفظ، والفشل، وإعادة المحاولة بالمفتاح نفسه | `lib/features/*/`، `test/` |
| F6 | **قاعدة الخانات من الخادم:** `GET …/team` يرسل لكل خانة `allowed` (خطوط اللاعبين المسموحة). `_keepersRight` يُحذف، والتطبيق والويب يطبّقان `allowed` | `TeamController.php`، `openapi.yaml`، `lineup_screen.dart`، `web/…/Lineup.vue` |
| F7 | **المؤقتات:** `motion.dart` بـ `Timer` يُلغى، وفحص: كل `Timer` و`StreamSubscription` و`AnimationController` له إلغاء في `dispose` (قاعدة `cancel_subscriptions` ومراجعة 9 المؤقتات) | `lib/ui/widgets/motion.dart`، متفرقة |
| F8 | **اختبارات اللقطات تعمل:** إصلاح الـ 11 الفاشلة (المؤقت، وصورة المتجر الوهمية، واختبار القائمة)، وحذف لقطات العمودي الثماني، وتشغيلها في CI (بلا مقارنة بكسل أولاً: يكفي أن تُرسم بلا خطأ) | `test/shots/`، `mobile.yml` |
| F9 | **الترجمة:** نصوص `api_error.dart`، واختصارات `league_screen.dart` إلى ملفي `arb`. وفحص في CI: لا حرف عربي في `lib/` خارج `l10n/` (قائمة استثناء: اسم اللعبة، و«العربية» في اختيار اللغة) | `lib/core/api/api_error.dart`، `lib/l10n/`، `mobile.yml` |
| F10 | **مفاتيح عدم التكرار المعلّقة** تُحفظ في `shared_preferences` حتى ينجح الطلب، وتُمسح بعد يوم | `lib/core/api/intents.dart` |
| F11 | **مسارات الإشعارات:** قائمة بيضاء من جدول المسارات نفسه قبل `push(route)` | `lib/app.dart`، `lib/router.dart` |
| F12 | **تنظيف:** `MaterialApp` واحد، و`pubspec.yaml` بلا تعليقات القالب وبلا `cupertino_icons`، و`mobile/README.md` من سطرين، وتحديث المكتبات المتأخرة (21) مع الاختبارات | متفرقة |

## تعريف الانتهاء

- [ ] `grep -c "\['" lib/features` قريب من الصفر: القراءة من النماذج المولّدة.
- [ ] تغيير اسم حقل في `openapi.yaml` يُفشل `flutter analyze` (تجربة مكتوبة في ملف السبرنت).
- [ ] `flutter analyze` نظيف بالقواعد الصارمة.
- [ ] `flutter test` أخضر، ومعه اللقطات (36 من 36، ثم 28 بعد حذف العمودي).
- [ ] لا ملف في `lib/features` فوق 500 سطر.
- [ ] اختبار وحدة لكل `Notifier` (خمسة على الأقل).
- [ ] الشكل لم يتغير: صور اللقطات قبل وبعد متطابقة بالعين.

## كيف يُختبر باليد

1. جولة كاملة في التطبيق: دخول، ودوري، وتشكيلة، وسوق، ومباراة، ودردشة. لا فرق عن قبل.
2. اشترِ لاعباً، واقطع الإنترنت قبل الرد، وأغلق التطبيق، وافتحه واضغط شراء: لا يُشترى مرتين.
3. بالإنجليزية واقطع الإنترنت: رسالة الخطأ بالإنجليزية.

## المخاطر

- **المولّد لا يفهم كل `openapi.yaml`:** يُجرَّب في أول يوم على السوق. البديل: نماذج `freezed` يدوية مع اختبار عقد يقرأ أمثلة `docs/api/samples`.
- **القواعد الصارمة تُظهر مئات الملاحظات:** على دفعات، وكل دفعة PR.

## ما أُنجز وكيف يُختبر

لم يبدأ. يُكتب هنا مع كل PR: ما بُني، وأين، وكيف يُجرَّب، والاختبارات، وما بقي.

## ملاحظات وتعديلات بالتوازي

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| | | | |
