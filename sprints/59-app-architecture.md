# Sprint 59: بنية التطبيق (عقد مولّد، وحالة مختبرة، وقواعد صارمة)

| | |
|---|---|
| **الحالة** | ✅ مبني (2026-11-12)، وينتظر مراجعة حمزة. F1 بنيته كاملة وأول شاشة عليه، ونقل باقي الشاشات ميزةً ميزة |
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
| F1 ✅ | **نماذج مولّدة من `openapi.yaml`:** `swagger_parser` (أو `openapi_generator`) يولّد النماذج و`fromJson` إلى `lib/api/gen/`. و`mobile.yml` يولّد ويفحص `git diff --exit-code` (كما `npm run api` في الويب). النماذج اليدوية تُستبدل ميزةً ميزة: السوق، ثم الفريق، ثم المباراة، ثم الباقي | `mobile/lib/api/gen/`، `mobile.yml`، كل `*_data.dart` |
| F2 ✅ | **قراءة متسامحة:** حقل جديد غير معروف لا يكسر، وحقل مطلوب ناقص يعطي خطأ واحداً واضحاً مسجّلاً (Sprint 66) لا شاشة حمراء | `lib/core/api/` |
| F3 ✅ | **قواعد التحليل:** `strict-casts`، و`strict-inference`، و`strict-raw-types`، و`unawaited_futures`، و`use_build_context_synchronously`، و`prefer_const_constructors`، و`avoid_dynamic_calls`، و`cancel_subscriptions`. و`formatter: page_width: 140` و`dart format --set-exit-if-changed` في CI. تُصلح على ثلاث دفعات | `analysis_options.yaml`، `mobile.yml` |
| F4 ✅ | **ملف لكل شاشة:** `social_screens.dart` (16 صنفاً) إلى `features/groups/`، و`features/coach/`، و`features/ideas/`، و`features/support/`. و`league_screen.dart` (19 صنفاً) إلى تبويباته. و`account_screens.dart`، و`tournament_screens.dart`، و`extras_screens.dart`، و`sim_screens.dart` كذلك. التسمية: `*_screen.dart`، و`*_repository.dart`، و`*_models.dart` | `lib/features/` |
| F5 ✅ | **`Notifier` للشاشات التي تعدّل:** التشكيلة، والتكتيك، والسوق، والمباراة الحية، والدردشة. الشاشة ترسم الحالة وترسل الأفعال فقط. اختبار وحدة لكل واحد (بمستودع وهمي) يغطي: الحفظ، والفشل، وإعادة المحاولة بالمفتاح نفسه | `lib/features/*/`، `test/` |
| F6 ✅ | **قاعدة الخانات من الخادم:** `GET …/team` يرسل لكل خانة `allowed` (خطوط اللاعبين المسموحة). `_keepersRight` يُحذف، والتطبيق والويب يطبّقان `allowed` | `TeamController.php`، `openapi.yaml`، `lineup_screen.dart`، `web/…/Lineup.vue` |
| F7 ✅ | **المؤقتات:** `motion.dart` بـ `Timer` يُلغى، وفحص: كل `Timer` و`StreamSubscription` و`AnimationController` له إلغاء في `dispose` (قاعدة `cancel_subscriptions` ومراجعة 9 المؤقتات) | `lib/ui/widgets/motion.dart`، متفرقة |
| F8 ✅ | **اختبارات اللقطات تعمل:** إصلاح الـ 11 الفاشلة (المؤقت، وصورة المتجر الوهمية، واختبار القائمة)، وحذف لقطات العمودي الثماني، وتشغيلها في CI (بلا مقارنة بكسل أولاً: يكفي أن تُرسم بلا خطأ) | `test/shots/`، `mobile.yml` |
| F9 ✅ | **الترجمة:** نصوص `api_error.dart`، واختصارات `league_screen.dart` إلى ملفي `arb`. وفحص في CI: لا حرف عربي في `lib/` خارج `l10n/` (قائمة استثناء: اسم اللعبة، و«العربية» في اختيار اللغة) | `lib/core/api/api_error.dart`، `lib/l10n/`، `mobile.yml` |
| F10 ✅ | **مفاتيح عدم التكرار المعلّقة** تُحفظ في `shared_preferences` حتى ينجح الطلب، وتُمسح بعد يوم | `lib/core/api/intents.dart` |
| F11 ✅ | **مسارات الإشعارات:** قائمة بيضاء من جدول المسارات نفسه قبل `push(route)` | `lib/app.dart`، `lib/router.dart` |
| F12 ✅ | **تنظيف:** `MaterialApp` واحد، و`pubspec.yaml` بلا تعليقات القالب وبلا `cupertino_icons`، و`mobile/README.md` من سطرين، وتحديث المكتبات المتأخرة (21) مع الاختبارات | متفرقة |

## تعريف الانتهاء

- [ ] `grep -c "\['" lib/features` قريب من الصفر: القراءة من النماذج المولّدة. **لم يتحقق بعد: 1086.** المولّد والقارئ المتسامح والفحص في CI جاهزة، وأول شاشة عليها (عرض الشراء). ونقل الباقي ميزةً ميزة كما تقول F1 (السوق، ثم الفريق، ثم المباراة)، وأغلبه يحتاج أن يكمل `openapi.yaml` وصف ما يرسله الخادم فعلاً (مثلاً `seller` و`fits` و`star` في قائمة السوق مذكورة في الوصف لا في المخطط).
- [x] تغيير اسم حقل في `openapi.yaml` يُفشل `flutter analyze` (التجربة في «ما أُنجز» أدناه).
- [x] `flutter analyze` نظيف بالقواعد الصارمة.
- [x] `flutter test` أخضر (89)، ومعه اللقطات: 51 من 51 بعد حذف العمودي الثماني (العدد في الخطة كان أقدم من لقطات Sprint 50).
- [x] لا ملف في `lib/features` فوق 500 سطر.
- [x] اختبار وحدة لكل `Notifier`: خمسة `Notifier` وسبعة اختبارات.
- [x] الشكل لم يتغير: اللقطات الـ 51 قبل التقسيم وبعده وبعد الـ `Notifier` **متطابقة بايتاً ببايت** (`cmp`).

## كيف يُختبر باليد

1. جولة كاملة في التطبيق: دخول، ودوري، وتشكيلة، وسوق، ومباراة، ودردشة. لا فرق عن قبل.
2. اشترِ لاعباً، واقطع الإنترنت قبل الرد، وأغلق التطبيق، وافتحه واضغط شراء: لا يُشترى مرتين.
3. بالإنجليزية واقطع الإنترنت: رسالة الخطأ بالإنجليزية.

## المخاطر

- **المولّد لا يفهم كل `openapi.yaml`:** يُجرَّب في أول يوم على السوق. البديل: نماذج `freezed` يدوية مع اختبار عقد يقرأ أمثلة `docs/api/samples`.
- **القواعد الصارمة تُظهر مئات الملاحظات:** على دفعات، وكل دفعة PR.

## ما أُنجز وكيف يُختبر

**ما بُني (2026-11-12):**

- **F3، التحليل الصارم:** `mobile/analysis_options.yaml` بـ `strict-casts` و`strict-inference` و`strict-raw-types` والقواعد الخمس، و`page_width: 140`. أُصلحت 110 ملاحظات (أنواع صريحة، و`unawaited`، وقراءة JSON بأنواعها في `tool/tokens.dart`). و`mobile.yml` يشغّل `dart format --set-exit-if-changed`.
- **F7، المؤقتات:** تأخير `FadeSlideIn` صار `Timer` يُلغى، ومستمع المذكرة الصوتية ومستمعو Firebase (`PushService.dispose` مع الـ provider) يُلغون. وراجعت كل `Timer` و`AnimationController` في `lib/`: كلها تُلغى.
- **F12، التنظيف:** `MaterialApp.router` واحد (التحديث الإجباري يحل محل الشاشات في `builder`)، و`pubspec.yaml` بلا تعليقات القالب وبلا `cupertino_icons`، و`mobile/README.md` سطران، والمكتبات محدّثة (`flutter pub outdated`: لا شيء مباشر متأخر).
- **F6، قاعدة الخانات:** `TeamSheet::allowed()` هي القاعدة الوحيدة: يطبّقها الحفظ، وترسلها كل خانة في `GET …/team` و`/data/formations` (`allowed`). والويب (`Lineup.vue`، `takes()`) والتطبيق (`Slot.takes`) يقرآنها، و`_keepersRight` حُذف. واختبار `test_each_slot_says_which_lines_it_takes` و`test/slot_rule_test.dart`.
- **F9، الترجمة:** رسائل الشبكة (`ApiError.locale` من إعداد اللغة) والعد التنازلي وحروف النتائج والمقدمة و«هدف!» في ملفي `arb`. و`tool/arabic.dart` (في `mobile.yml`) يرفض حرفاً عربياً في نص داخل `lib/` خارج `l10n/`، والاستثناءات: اسم اللعبة، و«العربية»، وكلمات الرواية المولّدة، وسطر يقول لماذا بـ `l10n-ok`.
- **F10، المفاتيح المعلّقة:** `Intents` يحفظ مفتاح كل فعل في `glm.intents` حتى ينجح، ويقرؤه `main()` عند الفتح، وينساه بعد يوم (`test/intents_test.dart`).
- **F11، مسارات الإشعارات:** `knownRoute()` في `router.dart`: مسار من التطبيق نفسه (لا مخطط ولا مضيف) يطابقه جدول المسارات، وإلا لا يُفتح. للإشعار ولرسالة الصندوق (`test/push_routes_test.dart`).
- **F8، اللقطات:** الـ 11 الفاشلة تعمل (مؤقت آخر طلب يُنهى قبل نهاية الاختبار، وصورة المتجر من الشبكة تبقى فارغة، ولقطة القائمة تضغط قسم «الفريق» في الرصيف بدل زر القائمة المحذوف)، وحُذفت لقطات العمودي الثماني، و`mobile.yml` يرسمها (`--update-goldens`، بلا مقارنة بعد).
- **F4، التقسيم:** الملفات الـ 17 الكبيرة صارت مكتبة وأجزاء (`part`) بحسب الشاشة، كل جزء باسم شاشته (`social_screens_chat_screen.dart` مثلاً)، وأوراق المباراة الحية ودردشتها في امتدادات. **اخترت الأجزاء لا النقل إلى مجلدات `features/groups/` وغيرها:** النقل يحتاج تحويل كل صنف خاص إلى عام، والأجزاء تُبقي الشكل مطابقاً بايتاً ببايت. ونقلها إلى مجلداتها يأتي مع F1 حين تُكتب نماذجها. و`tool/design.dart` يحسب الجزء مع مكتبته.
- **F5، الـ `Notifier`:** `TacticsEditor` و`LineupEditor` و`BuyController` و`LiveOrders` و`ChatController`: الشاشة ترسم الحالة وترسل الأفعال. والشراء وأوامر المباراة يأخذان المفتاح في الـ `Notifier` (`Intents`)، والمستودع يستقبله. و`test/notifiers_test.dart` (7 اختبارات بمستودعات وهمية): الحفظ، والرفض، وإعادة المحاولة بالمفتاح نفسه.
- **F1 وF2، النماذج المولّدة:** `dart run tool/api.dart` يكتب `lib/api/gen/models.g.dart` (305 صنفاً) من `docs/api/openapi.yaml`، و`mobile.yml` يولّده ويفحص `git diff --exit-code`. **مولّدنا لا `swagger_parser`:** أصناف عادية بلا `build_runner` ولا `freezed`، وقراءتها كلها من `JsonReader` (`lib/api/read.dart`): حقل غير معروف لا يغيّر شيئاً، والاختياري الخاطئ يُقرأ null ويُسجَّل، وعنصر قائمة لا يُقرأ يُترك وحده، والمطلوب الناقص `ModelError` واحد باسم النموذج والحقل (`modelErrors` لـ Sprint 66). **أول شاشات عليه:** عرض الشراء (`BuyQuote` صار مكوّناً في `openapi.yaml`، والصنف اليدوي حُذف)، وقائمة الانتقالات (`TransferList` و`TransferListPlayer`: المخطط صار يصف ما يرسله الخادم فعلاً، و`GET …/market` يجيب `oneOf` حسب `source`، و`MarketPlayer.of()` يبني من النموذج المولّد، والرد المسجّل `test/fixtures/market.json` يُقرأ به فيفحص العقد، و`MarketTest` يفحص الحقول المطلوبة بـ `assertJsonStructure`)، ولاعبو الفريق (`Player.of(SquadPlayer)`، و`TeamSheetTest` يفحص حقوله). **والنموذج المولّد كشف خطأً:** القارئ اليدوي كان يضيف `training_bonus` إلى `overall` والخادم أضافه قبله (`Training::boosted`)، فاللاعب المتدرب ظهر في التطبيق أعلى من الموقع. صُحّح، واختبار في `test/models_test.dart`. والمولّد صار يفهم `type: [x, 'null']`. **وبعدها:** قائمة بيعي (`Selling` من `Market`)، والعروض بين المدربين (`Deals` من `Transfers`)، والمباراة (`MatchView` من `LeagueMatch` الجديد، وكان `GET /matches/{match}` بلا مخطط في العقد، ولاعبوها وأنديتها وفرقها)، وكل واحدة بفحص حقولها في اختبار الخادم (`MarketTest` و`TransfersTest` و`MatchRunnerTest`) وبقراءة ردها المسجّل في اختبارات التطبيق.

**كيف يُختبر:**

- من `mobile/`: `flutter analyze` (نظيف)، و`flutter test` (89)، و`flutter test test/shots --tags shots --run-skipped --update-goldens` (51)، و`dart run tool/design.dart`، و`dart run tool/arabic.dart`، و`dart run tool/api.dart && git diff --exit-code lib/api/gen/`، و`dart format --set-exit-if-changed lib test tool`.
- **تجربة العقد:** غيّرت `doc_coins` إلى `register_coins` في `BuyQuote` بـ `openapi.yaml` وولّدت: `flutter analyze` فشل في `market_screen_buy_sheet.dart:94` (`The getter 'docCoins' isn't defined for the type 'BuyQuote'`). ثم أرجعته.
- من `backend/`: `php artisan test tests/Feature/TeamSheetTest.php`. ومن `web/`: `npx vue-tsc` و`npx vitest run`.
- باليد كما في القسم السابق، وزد: في التشكيلة ضع حارساً في خانة لاعب: يُرفض برسالة، كما على الموقع.

**ما بقي:**

- **F1 لباقي الشاشات:** 1086 قراءة `['` في `lib/features` (أكثرها في الدوري `leagues/models.dart`، والإضافات `extras_data.dart`، ويوم المباراة، والمال، وأحداث المباراة الحية وتقريرها)، وكل واحدة تحتاج أن يصف `openapi.yaml` ما يرسله الخادم بالضبط (القائمة مثلاً بـ `seller` و`fits` و`star` في الوصف لا في المخطط). ومعها نقل الأجزاء إلى مجلدات ميزاتها.
- مقارنة اللقطات بالبكسل في CI (F8 قال: لاحقاً).

## ملاحظات وتعديلات بالتوازي

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| | | | |
