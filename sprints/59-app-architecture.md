# Sprint 59: بنية التطبيق (عقد مولّد، وحالة مختبرة، وقواعد صارمة)

| | |
|---|---|
| **الحالة** | ✅ مبني كله (2026-11-13)، وينتظر مراجعة حمزة: كل رد من الخادم من نموذجه المولّد، وملف لكل شاشة في مجلد ميزتها، واللقطات تُقارن بالبكسل |
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

- [x] `grep -c "\['" lib/features` قريب من الصفر: القراءة من النماذج المولّدة. **كل رد من الخادم يُقرأ من نموذجه المولّد (2026-11-13):** من 404 إلى 92، ولا واحدة منها قراءة لرد: 29 قائمة ثابتة (`['home', 'away']`)، و8 أخطاء حقول النماذج (`_errors['email']`)، و11 قيم محرر التكتيك (خريطته هو)، و37 بيانات اللقطة التي يرسمها البث (`data` في `MomentStory`، حرة بتصميمها) ونصوص القصة (`StoryText` اتحاد: مفتاح أو `{p}` أو `{c}` أو `{t, v}` أو `{j, by}`)، والباقي قارئ ملف الإطارات الذهبية والأكواد.
- [x] تغيير اسم حقل في `openapi.yaml` يُفشل `flutter analyze` (التجربة في «ما أُنجز» أدناه).
- [x] `flutter analyze` نظيف بالقواعد الصارمة.
- [x] `flutter test` أخضر (98 في 2026-11-13)، ومعه اللقطات: 51 من 51 بعد حذف العمودي الثماني (العدد في الخطة كان أقدم من لقطات Sprint 50).
- [x] لا ملف في `lib/features` فوق 500 سطر.
- [x] اختبار وحدة لكل `Notifier`: خمسة `Notifier` وسبعة اختبارات.
- [x] الشكل لم يتغير: اللقطات الـ 51 قبل التقسيم وبعده وبعد الـ `Notifier` وبعد النقل إلى مجلدات الميزات **متطابقة بايتاً ببايت** (`cmp`)، وصارت تُقارن بمراجعها في كل تشغيل.

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
- **F8، اللقطات:** الـ 11 الفاشلة تعمل (مؤقت آخر طلب يُنهى قبل نهاية الاختبار، وصورة المتجر من الشبكة تبقى فارغة، ولقطة القائمة تضغط قسم «الفريق» في الرصيف بدل زر القائمة المحذوف)، وحُذفت لقطات العمودي الثماني، و`mobile.yml` يرسمها (`--update-goldens`، بلا مقارنة بعد). **وبعدها (2026-11-13): مقارنة بالبكسل.** المراجع الـ 51 في `test/shots/goldens/` في المستودع (13 ميجا، كما `web/e2e/visual.spec.ts-snapshots`)، و`test/shots/flutter_test_config.dart` يقارن بها بسماح 0.002% (نحو 26 بكسلاً من 1.3 مليون، لحواف قد يرسمها جهاز آخر بفرق طفيف)، و`mobile.yml` يقارن ولا يكتب، ويرفع صور الفرق (`failures/`) إن فشل. **جُرّب:** علامة تعجب في عنوان المحفظة (119 بكسلاً، 0.01%) أفشلت لقطتها وكتبت صورها الأربع، وبإرجاعها نجحت. **وأي تغيير مقصود في الشكل يُكتب بـ `--update-goldens` في نفس PR بعد النظر فيه.** ولأن CI معطّل لم يُجرَّب على جهاز CI بعد: أول تشغيل له يؤكد أن الرسم مطابق هناك (Linux وFlutter 3.47.9 كهنا).
- **F4، التقسيم:** الملفات الـ 17 الكبيرة صارت مكتبة وأجزاء (`part`) بحسب الشاشة، كل جزء باسم شاشته (`social_screens_chat_screen.dart` مثلاً)، وأوراق المباراة الحية ودردشتها في امتدادات. **اخترت الأجزاء لا النقل إلى مجلدات `features/groups/` وغيرها:** النقل يحتاج تحويل كل صنف خاص إلى عام، والأجزاء تُبقي الشكل مطابقاً بايتاً ببايت. ونقلها إلى مجلداتها يأتي مع F1 حين تُكتب نماذجها. و`tool/design.dart` يحسب الجزء مع مكتبته. **وبعدها (2026-11-13): ملف لكل شاشة في مجلد ميزتها،** كما طلب F4: الجروبات والدردشة (`features/groups/`)، والوديات (`friendlies/`)، والتوقعات (`predictions/`)، والجريدة (`newspaper/`)، وحسابي (`account/profile_screen.dart`)، وترتيب المدربين وملف المدرب (`coach/`)، والاقتراحات (`ideas/`)، والدعم والإعلانات (`support/`)، والدليل (`guide/`)، وأرقام الدوري (`stats/`)، ويوم المباراة وعقوده وتذاكره وما فاتني (`matchday/`)، والبطولات ست شاشات، والتدريب والمتخصصون والجاسوس والمهام والألقاب كل واحدة في ملفها، وتبويبات الدوري في `leagues/tabs/`، والمحاكي في أربعة ملفات. ومستودع كل ميزة وموفّراتها في `*_data.dart`. **وما كان مكرراً في كل مكتبة صار واحداً** في `leagues/page.dart`: `screenPage` (كان `_page` بأربع نسخ و`_scaffold`)، و`tryAction` (كان `_try` بأربع نسخ متطابقة و`_act`)، و`let`. والأجزاء الباقية قطع شاشة واحدة لا شاشات (عناصر الصفحة الرئيسية، وامتدادات المباراة الحية على حالتها الخاصة، ورسام اللقطات)، فبقيت أجزاءً. **نُقل بأداة لا باليد،** وقورنت التصريحات الـ 124 قبله وبعده: متطابقة إلا الأسماء التي صارت عامة لأنها تُستعمل من ملف آخر و`{super.key}` الذي يطلبه التحليل لها، و**اللقطات الـ 51 متطابقة بايتاً ببايت** قبل النقل وبعده (`cmp`).
- **F5، الـ `Notifier`:** `TacticsEditor` و`LineupEditor` و`BuyController` و`LiveOrders` و`ChatController`: الشاشة ترسم الحالة وترسل الأفعال. والشراء وأوامر المباراة يأخذان المفتاح في الـ `Notifier` (`Intents`)، والمستودع يستقبله. و`test/notifiers_test.dart` (7 اختبارات بمستودعات وهمية): الحفظ، والرفض، وإعادة المحاولة بالمفتاح نفسه.
- **F1 وF2، النماذج المولّدة:** `dart run tool/api.dart` يكتب `lib/api/gen/models.g.dart` (305 صنفاً) من `docs/api/openapi.yaml`، و`mobile.yml` يولّده ويفحص `git diff --exit-code`. **مولّدنا لا `swagger_parser`:** أصناف عادية بلا `build_runner` ولا `freezed`، وقراءتها كلها من `JsonReader` (`lib/api/read.dart`): حقل غير معروف لا يغيّر شيئاً، والاختياري الخاطئ يُقرأ null ويُسجَّل، وعنصر قائمة لا يُقرأ يُترك وحده، والمطلوب الناقص `ModelError` واحد باسم النموذج والحقل (`modelErrors` لـ Sprint 66). **أول شاشات عليه:** عرض الشراء (`BuyQuote` صار مكوّناً في `openapi.yaml`، والصنف اليدوي حُذف)، وقائمة الانتقالات (`TransferList` و`TransferListPlayer`: المخطط صار يصف ما يرسله الخادم فعلاً، و`GET …/market` يجيب `oneOf` حسب `source`، و`MarketPlayer.of()` يبني من النموذج المولّد، والرد المسجّل `test/fixtures/market.json` يُقرأ به فيفحص العقد، و`MarketTest` يفحص الحقول المطلوبة بـ `assertJsonStructure`)، ولاعبو الفريق (`Player.of(SquadPlayer)`، و`TeamSheetTest` يفحص حقوله). **والنموذج المولّد كشف خطأً:** القارئ اليدوي كان يضيف `training_bonus` إلى `overall` والخادم أضافه قبله (`Training::boosted`)، فاللاعب المتدرب ظهر في التطبيق أعلى من الموقع. صُحّح، واختبار في `test/models_test.dart`. والمولّد صار يفهم `type: [x, 'null']`. **وبعدها:** قائمة بيعي (`Selling` من `Market`)، والعروض بين المدربين (`Deals` من `Transfers`)، والمال والملعب (`ClubFinance` و`StadiumView`، من 55 قراءة يدوية إلى صفر)، والتدريب والمتخصصون والجاسوس والمهام والألقاب (`extras_data.dart`؛ **وفيه الخطأ نفسه:** تقييم المتدرب كان `overall + training_bonus` والخادم أضافه قبله في `TrainingController`)، ولوحة النادي (`ClubBoard`)، والصفحة الرئيسية (`HomeScreen`، ورد `/home` مسجّل من الخادم في `test/fixtures/home.json`، و`test/home_answer.dart` يضع قيم كل اختبار فوقه فتبقى اللقطات كما هي)، وبيانات الفريق والتكتيك والتشكيلات (`team_data.dart`)، وملف المدرب، والوديات وإعادتها السريعة والجروبات (**والنموذج كشف خطأً رابعاً:** سبب منع الودية كان يظهر كما أرسله الخادم `{reason: live}`، فصار جملة بالعربية والإنجليزية)، والمحفظة والمتجر (`WalletView.of` و`StoreItem.shown` من `StoreAnswer`) وصندوق الرسائل (`InboxMessage.of` من `Message`، والعدّاد من `MessagesUnreadAnswer`) وإعدادات الإشعارات (`NotificationSettings`)، بلا قراءة يدوية، والحساب (`Account.of` من `AccountAnswer` و`AccountTokenAnswer`)، والمدرب المساعد (`AssistantStart` و`AssistantAnswer`)، و`/health` وFirebase من `/app`، وتقرير الجاسوس كاملاً (`SpyViewReport`)، والكونسول (الشرط الجزائي وفتح الصندوق والوقت المستقطع والتفاعل)، والدردشة كلها (`ChatMessage` في المتحكم والشاشة)، و**`JsonReader` يقرأ `[]` خريطة فارغة** (PHP يكتب الخريطة الفارغة هكذا: رسالة بلا تفاعلات كانت ستُسجَّل خطأً)، و**المباراة الحية كلها:** `GET /matches/{match}/live` صار مكوّناً `MatchLive` (كان اسمه يتصادم مع `GET /matches/live` فلم يُولَّد)، والدقيقة `LiveMinute` بأحداثها `LiveEvent` ولقطتها `LiveMoment` وقصتها `MomentStory` وإطاراتها `Keyframe` وفريقيها `MatchViewTeam` (كانت كلها خرائط بلا أنواع في العقد)، والدقيقة المدفوعة على القناة والدردشة والتفاعلات الحية من النماذج نفسها، **وجُرّبت على مباراة كاملة من الخادم** (94 دقيقة بهدفيها وبطاقتيها وصافرتيها و15 مشهداً، بلا خطأ نموذج واحد)، ومنها ست دقائق في `test/fixtures/live_play.json`، و`MatchRunnerTest` يفحص حقول الدقيقة كلها؛ وتقرير المباراة (`timeline` من `LiveEvent`) والملخص (`MatchRecap`)، والتوقعات (`Predictions`، وكان مخططها بلا أنواع)، والمحاكي (`ClubSummary` ومعه `logo`)؛ **والنموذج كشف خطأً خامساً:** معرّف مباراة المحاكي ULID (نص) والتطبيق كان يقرؤه رقماً، فإنشاء مباراة في المحاكي من التطبيق كان يفشل دائماً. صار نصاً، واختبار في `test/sim_test.dart`، والبطولات كلها (القائمة والصفحة والقرعة والكتالوج والتحالف، بلا قراءة يدوية؛ و`TournamentTeam` و`AllianceClub` مكوّنان جديدان بدل خرائط بلا أنواع)، والسوق كله (عرض البيع ولاعبو نادٍ والإعارات والأكاديمية والكشاف، بلا قراءة يدوية؛ والمسار المنتهي بمعامل يُسمّى بـ `By<Param>` مثل `LeaguesClubsByClubAnswer`)، ومباراتي القادمة في يوم المباراة (`NextMatch` صار مكوّناً؛ **والنموذج كشف خطأً ثالثاً:** الخادم يرسل الحكم كلمة صرامته، والتطبيق كان ينتظر خريطة فيها `name`، فلم يظهر الحكم أبداً. صار يظهر بصرامته بالعربية والإنجليزية)، والمؤتمر الصحفي (`PressConference`، وكان مخططه بلا أنواع)، وما فاتني (`MissedMatch`) والعقود (`Contracts`) والنزاهة وتذاكر التشجيع (يوم المباراة كله بلا قراءة يدوية؛ والمولّد صار يولّد ردود `components/responses` أيضاً باسم `<Name>Answer`، 15 رداً، ورد كل GET المكتوب في مساره باسم مساره مثل `RankingsCoachesAnswer`: صار المولّد 500 نموذج)، والجريدة (`Newspaper` و`NewspaperEdition` و`NewspaperArticle`، وكان مخططها بلا أنواع)، وشاشات الحساب كلها (حسابي وأوسمتي وأرقام الدوري والدعم والإعلانات والدليل وترتيب المدربين والاقتراحات، بلا قراءة يدوية)، والكونسول (المهام اليومية والمزادات والتفاوض والصناديق، بردود مسجّلة من الخادم في `test/fixtures/`، و`bought` أُضيف إلى `Negotiation` في العقد)، وتقرير المباراة للمدرب (`MatchCoachReport` صار مكوّناً بأسبابه وتقييماته المكتوبة، و`readings` فيه اختياري: **التقارير تُحفظ عند نهاية المباراة، وتقارير السيرفر القديمة بلا `readings`**، فلو بقي مطلوباً لفشل التطبيق في فتحها)، و`JsonReader` صار يقرأ كائناً اختيارياً لا يُقرأ null بدل أن يُسقط الرد كله، والدوري كله (`League` ومدربوه في كل رد، وأنديته وجدوله وطلبات الانضمام وقوالبه، وتقويمه `Fixture`؛ و`allOf` بمرجع واحد صار ذلك المرجع في المولّد)، والمباراة (`MatchView` من `LeagueMatch` الجديد، وكان `GET /matches/{match}` بلا مخطط في العقد، ولاعبوها وأنديتها وفرقها)، وكل واحدة بفحص حقولها في اختبار الخادم (`MarketTest` و`TransfersTest` و`MatchRunnerTest` و`LeaguePresenceTest` و`SeasonScheduleTest` و`EconomyTest` و`TimedEventsTest` و`MoraleTest` و`IntegrityTest` و`WeeklyQuestsTest` و`SeasonEndTest` و`ClubBoardTest` و`MatchCommentaryTest` و`MarketDealsTest` و`DailyTasksTest` و`TournamentTest` و`MatchPrepTest` و`PressTest` و`MoraleTest` و`HomeDashboardTest` و`IdeasTest` و`ScoutTest` و`AcademyTest` و`AlliancePlannedTest` و`FriendliesTest` و`ChatGroupTest` و`WalletTest` و`StoreTest` و`MessagesTest` و`MatchOrdersTest` و`SpyTest` و`MarketDealsTest` و`MatchRunnerTest` و`ClubBoardTest` و`PressTest` و`SimulatorApiTest` و`AccountCodeTest` و`SeasonStatsTest` و`AdminToolsTest` و`PublicGuideTest`) وبقراءة ردها المسجّل في اختبارات التطبيق.

**كيف يُختبر:**

- من `mobile/`: `flutter analyze` (نظيف)، و`flutter test` (98)، و`flutter test test/shots --tags shots --run-skipped` (51، تقارن بـ `test/shots/goldens/`)، و`dart run tool/design.dart`، و`dart run tool/arabic.dart`، و`dart run tool/api.dart && git diff --exit-code lib/api/gen/`، و`dart format --set-exit-if-changed lib test tool`.
- **تجربة العقد:** غيّرت `doc_coins` إلى `register_coins` في `BuyQuote` بـ `openapi.yaml` وولّدت: `flutter analyze` فشل في `market_screen_buy_sheet.dart:94` (`The getter 'docCoins' isn't defined for the type 'BuyQuote'`). ثم أرجعته.
- من `backend/`: `php artisan test tests/Feature/TeamSheetTest.php`. ومن `web/`: `npx vue-tsc` و`npx vitest run`.
- باليد كما في القسم السابق، وزد: في التشكيلة ضع حارساً في خانة لاعب: يُرفض برسالة، كما على الموقع.

**ما بقي:**

- لا شيء من مهام السبرنت. ومقارنة اللقطات على جهاز CI تنتظر إعادة تشغيله (القسم 11 من `README.md`).

## ملاحظات وتعديلات بالتوازي

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| | | | |
