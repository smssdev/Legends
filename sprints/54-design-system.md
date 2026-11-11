# Sprint 54: نظام التصميم الملزم (رموز ومكونات، للويب والتطبيق)

| | |
|---|---|
| **الحالة** | 🔄 مبني (2026-11-11)، وينتظر مراجعة حمزة واعتماد صاحب المشروع لصفحة المكونات (D3) |
| **المدة** | 7 أيام عمل |
| **المرحلة** | ب. الأساس |
| **المنصة** | ويب، تطبيق، `docs/design/` |
| **يعتمد على** | لا شيء (يسير مع Sprint 52) |

## الهدف

مصدر واحد لكل قرار بصري (لون، وخط، ومسافة، وظل، وحركة)، ومكوّن واحد لكل عنصر متكرر، وفحص آلي يمنع الخروج عنهما. بعده أي شاشة جديدة تخرج متسقة دون جهد.

## لماذا (رموز الملاحظات من [تقرير الويب](../audit-2026-11-10/01-web-audit.md) و[تقرير التطبيق](../audit-2026-11-10/02-mobile-audit.md))

W-D13، W-D14، W-D15، W-D16، W-D17، W-D18، W-D19، W-D11، W-D24، W-P12، W-F02، W-F03، M-D02، M-D03، M-F02.

## المهام

### التصميم

| الرمز | المهمة | الملفات |
|---|---|---|
| D1 ✅ | **`tokens.json` يكبر:** سلّم الخطوط (ستة أدوار: `caption` 12، `body` 14، `body-lg` 16، `title` 18، `headline` 22، `display` 32 و48)، والأوزان، وارتفاع السطر، وسلّم المسافات (4، 8، 12، 16، 24، 32)، والزوايا (بطاقة، وزر، وشارة)، والظلال (ثلاثة)، والمدد والمنحنيات (الموجودة في `style.css`)، وحد اللمس (44 ويب، 48 تطبيق) | `docs/design/tokens.json` |
| D2 ✅ | **رموز البث:** `broadcast.*` لألوان اللقطات والأستوديو (اليوم 134 لوناً يدوياً في `MatchFeed.vue` و56 في بث التطبيق) | `docs/design/tokens.json` |
| D3 ✅ | **صفحة المكونات مرجعاً:** `/dev/ui` (موجودة) تعرض كل مكوّن بكل حالاته (عادي، ومرور، وضغط، وتعطيل، وتحميل، وخطأ) بالليل والنهار وبالاتجاهين. ونظيرتها في التطبيق (شاشة تطوير). صاحب المشروع يعتمدها قبل الترحيل | `web/src/pages/UiLibrary.vue`، `mobile/lib/ui/` |

### الويب

| الرمز | المهمة | الملفات |
|---|---|---|
| W1 ✅ | **المولّد:** `scripts/tokens.mjs` يولّد السلّم الجديد إلى `@theme` (أحجام Tailwind تُستبدل بالأدوار الستة) | `web/scripts/tokens.mjs`، `style.css` |
| W2 ✅ | **الشكل داخل المكوّن:** قواعد `.rounded-xl.bg-surface` و`main h1.font-display` و`main table thead th` تنتقل من `style.css` إلى `UiCard` و`PageTitle` (جديد) و`UiTable`. ما يبقى في `style.css`: الأساس والخطوط فقط | `style.css`، `components/ui/` |
| W3 ✅ | **مكونات ناقصة:** `PageTitle`، و`AsyncState` (تحميل بهيكل، وخطأ بزر إعادة، وفراغ)، و`Skeleton` (بأشكال: سطر، وبطاقة، وصف جدول)، و`UiInput` (من `TextField`)، و`MoneyPill`، و`CountdownChip`، و`NavItem` | `components/ui/` |
| W4 ✅ | **مكتبة عناصر واحدة:** reka-ui لكل شيء. Headless UI يُستبدل في ملفاته التسعة (`Popover` في `AppShell`…) ويُحذف من `package.json` | `package.json`، 9 ملفات |
| W5 ✅ | **ترحيل الأساس:** `AppShell`، والرئيسية، ولوحة النادي إلى المكونات (الباقي يُرحَّل مع إعادة بنائه في Sprint 56) | `layouts/`، `pages/Home.vue`، `pages/team/ClubBoard.vue` |
| W7 ✅ | **`rem` بحجمه الصحيح (W-D24، وُجد في Sprint 51):** خط `html` 16px وخط `body` 14px، حتى لا يصغر كل مقاس بـ `rem` بـ 12.5%. ثم قياس أهداف اللمس على الشاشات المرحّلة | `style.css` |
| W6 ✅ | **الفحص:** قاعدة ESLint محلية ترفض في `pages/` و`components/` (عدا `ui/`): `bg-gold`/`bg-brand` على `<button>` أو `<a>` خام، و`rounded-(xl\|2xl) bg-surface`، و`text-[Npx]`، وألوان `#hex` خارج قائمة استثناء (الأعلام، والشعارات الاجتماعية) | `web/eslint.config.js` |

### التطبيق

| الرمز | المهمة | الملفات |
|---|---|---|
| F1 ✅ | **المولّد:** `tool/tokens.dart` يولّد `GlmType` (الأدوار الستة)، و`GlmSpace`، و`GlmRadius`، و`GlmMotion` بجانب `GlmPalette` | `mobile/tool/tokens.dart`، `lib/ui/tokens.g.dart` |
| F2 ✅ | **`textTheme` من السلّم**، وامتداد `context.type.body` للوصول | `lib/ui/theme.dart` |
| F3 ✅ | **مكونات بأسماء الويب:** `GlmCard`، و`GlmButton` (خمسة أنواع الويب)، و`GlmAsync` (من `async_view.dart`)، و`GlmSkeleton`، و`GlmPageTitle`. كل مكوّن ويب له نظير بالاسم نفسه (جدول مطابقة في ملف السبرنت) | `lib/ui/widgets/` |
| F4 ✅ | **الفحص:** قاعدة تحليل مخصصة (`custom_lint`، مجانية) أو فحص نصي في CI يرفض `Color(0x` و`fontSize:` خارج `lib/ui/` | `mobile/analysis_options.yaml`، `mobile.yml` |

## تعريف الانتهاء

- [x] `tokens.json` فيه الخطوط والمسافات والظلال والحركة والبث، والمولّدان يعملان، وCI يفشل إن تأخر الملف المولّد (كما الألوان اليوم).
- [ ] صفحة المكونات في الويب والتطبيق معتمدة من صاحب المشروع. (الويب مبنية، `/dev/ui`، وتنتظر حكمه. ونظيرتها في التطبيق اختبار `design_system_test.dart` لا شاشة، وتُبنى شاشة مع Sprint 60.)
- [ ] `style.css` بلا قواعد تستهدف تركيبات أصناف. (جزئياً: المكونات صار لها أصنافها `.ui-card` و`.ui-page-title` و`.ui-table` و`.ui-nav-item`، والقواعد القديمة باقية للشاشات التي لم تُرحَّل، وتُحذف حين تفرغ قائمة `design-baseline.json` في Sprint 56.)
- [x] `@headlessui/vue` خارج `package.json`.
- [x] فحصا W6 وF4 يعملان في CI (بقائمة استثناء للملفات التي لم تُرحَّل، تتناقص حتى Sprint 56 وSprint 60).
- [x] الشاشات المرحّلة (الإطار، والرئيسية، ولوحة النادي) بلا نص أصغر من 12px ولا هدف لمس أصغر من 44px (قياس آلي).

## كيف يُختبر باليد

1. `/dev/ui`: كل مكوّن بالليل والنهار، وبالعربية والإنجليزية.
2. غيّر لون `gold` في `tokens.json` وابنِ: يتغير في الويب والتطبيق معاً.
3. اكتب بطاقة يدوية في صفحة: البناء يرفضها.

## المخاطر

- **تغيير أحجام الخط يغيّر كل الشاشات:** لذلك يُطبَّق على الشاشات المرحّلة أولاً، والباقي يأخذه مع Sprint 56.
- **استبدال Headless UI:** السلوك (Esc، والنقر خارجاً، والتركيز) يُختبر في المتصفح لكل قائمة.

## ما أُنجز وكيف يُختبر

**بُني كله في 2026-11-11** على فرع PR #783 (مع 52 و53)، إلا اعتماد صاحب المشروع لصفحة المكونات.

**التصميم (D1، D2، D3):**
- `docs/design/tokens.json` فيه الآن `type` (الأدوار: `caption` 12، و`body` 14، و`bodyLg` 16، و`title` 18، و`headline` 22، و`display` 32، و`displayLg` 48، بارتفاع السطر والوزن)، و`spacing` (4 إلى 32)، و`touch` (44 ويب، 48 تطبيق)، و`shadow` (card وraised وoverlay)، و`motion` (منحنيان وثلاث مدد، كانت في `style.css`)، و`broadcast` (17 لوناً للبث والأستوديو).
- `/dev/ui`: قسم جديد بكل مكوّن في كل حالاته: الأزرار الخمسة، والتعطيل، والتحميل، والنجاح، والحجم الصغير، والرابط، والحقل بتلميح وبخطأ، والاختيار، والمفتاح، والتبويبات بلونيها، والنافذة، والانتظار والفراغ والخطأ، والهياكل، والعملتان، والعداد، وبند القائمة. وفيه مفتاحا النهار والاتجاه من اليسار.

**الويب (W1 إلى W7):**
- **W1:** `scripts/tokens.mjs` يولّد `--text-caption` إلى `--text-display-lg` بارتفاعها ووزنها، و`--space-*`، و`--spacing-touch`، و`--shadow-*`، و`--ease-*`، و`--duration-*`، و`--color-broadcast-*`. والمسافات باسم `--space-*` لا `--spacing-*`: الاسم الثاني كان يكسر `max-w-md` في Tailwind v4 (ضاقت لوحة الدخول إلى 58px في التجربة الأولى).
- **W7 (W-D24):** `html` بخط 16px و`body` بـ `--text-body` (14px)، فصار كل `rem` بحجمه. و`text-xs` صار 12px، أصغر نص مسموح.
- **W2 وW3:** `UiCard` و`UiTable` بأصنافهما (`.ui-card`، `.ui-table`)، ومكونات جديدة في `components/ui/`: `PageTitle`، و`AsyncState`، و`Skeleton` (سطر، وبطاقة، وصف، وبطل)، و`MoneyPill`، و`CountdownChip`، و`NavItem`. و`TextField` صار `ui/UiInput`. و`UiButton` يأخذ `to` (رابط بشكل الزر) و`size: 'sm'` (44px)، و`UiDialog` يأخذ `closable`.
- **W4:** reka-ui وحده. انتقلت إليه الملفات التسعة (`UiToggle` وSwitch، و`UiTabs` وTabs، و`UiSelect` وSelect وCombobox، و`UiDialog` و`BotClosing` وDialog، و`TicketPrices` وRadioGroup، و`ClubSwitcher` وقوائم الشريط وDropdownMenu، و`OnboardingChecklist` وCollapsible). ونافذتا «المؤقتات» و«ما ينتظرك» بحالتهما في `AppShell` (Esc والستار يغلقان، والتركيز يدخل ويعود). وحُذف `@headlessui/vue`. والحركة من حالة reka (`data-state`) في `style.css`، فالقائمة تختفي بنعومة أيضاً.
- **W5:** `AppShell` بـ `MoneyPill` و`NavItem` و`UiButton`، والرئيسية بنوافذ `UiDialog` (الترتيب بتبويبات `UiTabs`، والدرجة، والفتح الفوري) وأزرار `UiButton`، ولوحة النادي بـ `Skeleton`. **والقياس الآلي** (915×412 و1440×900): لا نص أصغر من 12px، ولا هدف لمس أصغر من 44px في الإطار والرئيسية ولوحة النادي (كان 36 و45 هدفاً قبله). و✕ تحية المدرب المساعد صغيرة الشكل وهدفها 44px بطبقة حولها.
- **W6:** `scripts/design.mjs` (`npm run design`، قبل كل بناء مع i18n). **ليس ESLint:** المشروع بلا linter، وأربعة أنماط على القوالب لا تحتاج إليه. يرفض في `pages/` و`layouts/` و`components/` (عدا `ui/`): زر أو رابط خام ذهبي أو زمردي، و`rounded-xl/2xl` مع `bg-surface`، و`text-[Npx]` و`text-[Nrem]`، و`#hex`. والملفات التي لم تُرحَّل في `scripts/design-baseline.json` (104 ملفات: 141 زراً و279 بطاقة و24 مقاساً و205 ألوان)، والملف ينقص ولا يزيد، و`npm run design -- --write` بعد كل ترحيل. والاستثناء الدائم `PublicFooter.vue` (ألوان الشبكات الاجتماعية).

**التطبيق (F1 إلى F4):**
- **F1:** `tool/tokens.dart` يولّد `GlmType` و`GlmSpace` و`GlmTouch` و`GlmRadius` و`GlmShadow` و`GlmMotion` و`GlmBroadcast` إلى `lib/ui/tokens.g.dart` (وCI يفحص أنه محدّث كما كان).
- **F2:** `textTheme` كله من الأدوار (`bodyMedium` = `body`، و`titleLarge` = `title`، و`bodySmall` = `caption`…)، و`context.type.body` وأخواتها (`GlmTypeStyles`).
- **F3:** `GlmAsync` (كان `AsyncView` في `async_view.dart`، والاسم القديم باقٍ اسماً ثانياً) بهيكل وفراغ، و`GlmSkeleton`، و`GlmPageTitle`. و`GlmCard` و`GlmButton` (الأنواع الخمسة) موجودان.
- **F4:** `tool/design.dart` في `mobile.yml` يرفض `Color(0x` و`fontSize:` خارج `lib/ui/` (35 ملفاً في `tool/design-baseline.json`: 147 لوناً و280 مقاساً، تنقص حتى Sprint 60). فحص نصي لا `custom_lint`: أخف وبلا اعتماد جديد.

**المطابقة بين الويب والتطبيق:**

| الويب (`components/ui/`) | التطبيق (`lib/ui/`) |
|---|---|
| `UiButton` (primary، brand، outline، quiet، danger) | `GlmButton` (`GlmButtonVariant` بالأسماء نفسها) |
| `UiCard` | `GlmCard` |
| `AsyncState` | `GlmAsync` (و`AsyncView`) |
| `Skeleton` (line، card، row، hero) | `GlmSkeleton` (`GlmSkeletonKind` بالأسماء نفسها) |
| `PageTitle` | `GlmPageTitle` |
| `text-caption` … `text-display-lg` | `context.type.caption` … `context.type.displayLg` |
| `--space-xs` … `--space-xxl` | `GlmSpace.xs` … `GlmSpace.xxl` |
| `--shadow-card` وأخواها | `GlmShadow.card` وأخواها |
| `--ease-soft`، `--duration-base` | `GlmMotion.easeSoft`، `GlmMotion.base` |
| `--color-broadcast-*` | `GlmBroadcast.*` |

**كيف يُجرَّب:**
1. `/dev/ui`: كل مكوّن، ثم مفتاح النهار، ثم مفتاح الاتجاه من اليسار.
2. القوائم بلوحة المفاتيح: النادي في الشريط، وأقسام الكمبيوتر (الأسهم وEnter)، والمؤقتات (Esc)، وأي اختيار في الكشاف (`/scout`)، والنافذة: كلها تفتح وتغلق بالنقر خارجها وبـ Esc.
3. اكتب في أي صفحة `class="rounded-xl bg-surface"` ثم `npm run build`: يرفض ويسمّي الملف. ونفسه في التطبيق بـ `Color(0xFF000000)` ثم `dart run tool/design.dart`.

**الاختبارات:** `npm run build` (بفحوصه: tokens وi18n وdesign وframes وfeed)، و`vue-tsc`، و`npm run e2e` (4 من 4، ومنها منع التمرير الأفقي)، و`flutter analyze` بلا ملاحظات، و`flutter test` (73، منها 3 جديدة في `test/design_system_test.dart`).

**ما بقي:**
- اعتماد صاحب المشروع لـ `/dev/ui`.
- شاشة المكونات في التطبيق (مع Sprint 60).
- ترحيل الشاشات الباقية (Sprint 56 للويب و60 للتطبيق)، ومعها تُحذف قواعد التركيبات القديمة من `style.css`.
- ألوان `MatchFeed.vue` إلى `--color-broadcast-*` (مع تفكيك المباراة في Sprint 57).
- الصفحات أطول بنحو 14% لأن الخط صار بحجمه: Sprint 55 (تصميم العرض) و56 يعيدان التخطيط.

## ملاحظات وتعديلات بالتوازي

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| | | | |
