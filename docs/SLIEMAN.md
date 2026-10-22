# دليل سليمان: الصور والسبرنتات

> **مرجعك اليومي.** منه تعرف ماذا تعمل اليوم، وما ينتظر قرارك، وما القادم بتواريخه.
> يولّده `python3 tools/team.py` بعد كل مراجعة وكل دمج، فلا يُعدَّل يدوياً. والخطة كاملة في [`SCHEDULE.md`](SCHEDULE.md).

**تقسيم العمل (قرار صاحب المشروع، 2026-10-22):** **الصوت كله عند حمزة.** والصور: **الكم الأكبر عندك** (كل الصور ما عدا الملاعب، 1776 صورة)، و**كل صورة تحتاج إعادة** من أي دفعة. و**جزء بسيط عند حمزة:** لوحات الملاعب (362 صورة) ([`HAMZA.md`](HAMZA.md)). يومك 5 ساعات: **للصور 2 منها (12 صورة معتمدة)، وللكود 3** مع Claude. والتقرير الكامل لكل صورة آخر هذا الملف.

## يومك بالترتيب

### 1. الصور (2 من 5 ساعات تقريباً)

**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تُبنى بها وحدها وتنتظرها. لا تبدأ الدفعة 2 قبل إكمالها.

1. **🔁 أعد 9 صورة من الدفعة 1** رفضتها المراجعة، بأمرها وسطر تصحيحها في: [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md)، [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md).
2. **⬜ ثم الجديدة بالترتيب (200 باقية في الدفعة 1):** من [`sprint-02-days.md`](sprints/sprint-02-days.md). أول 12 في الجدول تحت.

**صور اليوم (12):**

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| 🔁 | 48.13 | `art/raw/striker/ball/volley-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 48.14 | `art/raw/striker/ball/chip-01.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 48.15 | `art/raw/striker/ball/chip-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 48.17 | `art/raw/striker/ball/cross-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 48.18 | `art/raw/striker/ball/control-01.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 48.19 | `art/raw/striker/ball/control-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) |
| 🔁 | 45.13 | `art/raw/striker/run/run-back-01.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md) |
| 🔁 | 45.14 | `art/raw/striker/run/run-back-02.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md) |
| 🔁 | 45.15 | `art/raw/striker/run/run-back-03.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md) |
| ⬜ | 49.1 | `art/raw/striker/ground/tackle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ | 49.2 | `art/raw/striker/ground/tackle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ | 49.3 | `art/raw/striker/ground/tackle-03.png` | [`03-players.md`](art/images/03-players.md) |

**إعادة من الدفعات اللاحقة (26):** بعد صور الدفعة 1، أو حين تصل دفعتها. لكل صورة أمرها وسطر تصحيحها في ملف الإعادة.

| الدفعة | اللوحة | الملف | المشكلة | الأمر في |
|---|---|---|---|---|
| 2 | 2.3 | `art/raw/stadiums/classic/day/wing.jpg` | لا يظهر أي مرمى. المطلوب مرمى واحد صغير على الحافة اليمنى (عرضيات الجناح تتجه إليه) | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md) |
| 2 | 46.1 | `art/raw/striker/walk/jog-01.png` | ثلاث لوحات ملصوقة بخطوط فاصلة، والخلفية فيها كشافات وتدرج، والإطار الثالث ركبة عالية لا هرولة | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.2 | `art/raw/striker/walk/jog-02.png` | نفس مشكلة الخلفية واللوحات، وتكاد تطابق jog-03 | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.3 | `art/raw/striker/walk/jog-03.png` | نفس مشكلة الخلفية واللوحات، وشبه مطابقة لـ jog-02 وwalk-03، وفيها 3 أشكال والمطلوب 2 | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.4 | `art/raw/striker/walk/walk-01.png` | ثلاث لوحات ملصوقة، والخلفية فيها كشافات، والإطار الثالث ركبة عالية لا مشي | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.5 | `art/raw/striker/walk/walk-02.png` | نفس المشكلة، والإطار الأول ركبة عالية | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.6 | `art/raw/striker/walk/walk-03.png` | نفس المشكلة، وفيها 3 أشكال والمطلوب 2، وفيها ركبتان عاليتان | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.7 | `art/raw/striker/walk/walk-front-01.png` | الزاوية صحيحة (من الأمام)، لكن الخلفية فيها كشافات وتدرج واللوحات ملصوقة | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.8 | `art/raw/striker/walk/walk-front-02.png` | الزاوية خطأ (جانبية والمطلوب من الأمام)، والخلفية فيها كشافات | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.9 | `art/raw/striker/walk/walk-front-03.png` | الزاوية خطأ (جانبية)، وتكاد تطابق walk-front-02، وفيها 3 أشكال والمطلوب 2 | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.10 | `art/raw/striker/walk/walk-back-01.png` | الزاوية صحيحة (من الخلف)، لكن الخلفية فيها كشافات واللوحات ملصوقة | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.11 | `art/raw/striker/walk/walk-back-02.png` | الزاوية خطأ (جانبية والوجه ظاهر)، وفيها ركبة عالية | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.12 | `art/raw/striker/walk/walk-back-03.png` | الزاوية خطأ (جانبية)، وفيها 3 أشكال والمطلوب 2 | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.13 | `art/raw/striker/walk/backpedal-01.png` | يمشي للأمام لا للخلف، والخلفية فيها كشافات | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 46.14 | `art/raw/striker/walk/backpedal-02.png` | نفس المشكلة: مشي للأمام، والخلفية فيها كشافات | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) |
| 2 | 47.2 | `art/raw/striker/start/start-02.png` | الإطار 4 وقوف (يكرر الإطار 1 من start-01)، والمطلوب الخطوة الثانية فالثالثة فالجري الكامل | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 47.3 | `art/raw/striker/start/stop-01.png` | الإطاران 1 و2 شبه متطابقين، والإطار 1 ليس جرياً بأقصى سرعة، والإطار 3 وقوف | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 47.4 | `art/raw/striker/start/stop-02.png` | الإطار 4 خطوة جري (رجوع للخلف في الحركة)، والمطلوب: شبه متوقف بركبتين منثنيتين، ثم يستعيد توازنه، ثم يقف | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 47.5 | `art/raw/striker/start/turn-01.png` | الترتيب معكوس: يبدأ من الأمام وينتهي جانبياً، والمطلوب العكس (جانبي، ثم ثلاثة أرباع، ثم من الأمام). واسم الملف خطأ | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 47.6 | `art/raw/striker/start/turn-02.png` | الزوايا خطأ: من الخلف وجانبي لليمين، والمطلوب: ثلاثة أرباع لليسار، ثم جانبي لليسار، ثم واقف لليسار | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 47.7 | `art/raw/striker/start/idle-01.png` | الخلفية فيها كشافات وتدرج أخضر فلا تُقص | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) |
| 2 | 264.1 | `art/raw/coach-2/ref.png` | الوجه شبيه جداً بمدرب حقيقي مشهور، والمطلوب شخص مخترع | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md) |
| 2 | 264.2 | `art/raw/coach-2/faces.png` | تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md) |
| 2 | 265.1 | `art/raw/coach-2/start/idle-01.png` | تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md) |
| 4 | 4.5 | `art/raw/stadiums/maghreb/night/goal-front.jpg` | لوحات الإعلانات خلف المرمى فيها كتابة وشعارات، والمطلوب بلا أي نص | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md) |
| 5 | 5.3 | `art/raw/stadiums/coast/dusk/wing.jpg` | نسخة من لوحة التسديدة (المرمى كبير في الوسط)، والمطلوب منظر خط التماس والمرمى صغير بعيد | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md) |

### 2. الكود (3 ساعات): Sprint 13، الدوريات والانضمام

ابدأ الجلسة بـ «نكمل سبرنت 13»، وClaude يكمل من حالة [`sprint-13.md`](sprints/sprint-13.md) (يُنشأ أول السبرنت).

| الرمز | المهمة |
|---|---|
| D0 | تصميم شاشات هذا السبرنت للويب والموبايل حسب نظام التصميم، وموافقة صاحب المشروع قبل W |
| B1 | جداول `leagues`، `seasons`، `league_join_requests`، `league_memberships`، `clubs`، `players` كما في [4] |
| B2 | إنشاء دوري بكل الإعدادات (4 إلى 20 فريقاً، موعد البدء، "دوري نزيه")، وكود من 8 أحرف، و`LeagueFactory` ينسخ أقوى N نادٍ. المنشئ يختار فريقاً. زر "ابدأ الآن" ودوري تطوير |
| B3 | الانضمام بالكود (بحد معدل) ← طلب ← موافقة المنشئ ← استلام الفريق بتحديث شرطي واحد |
| B4 | سجل أموال النادي الأساسي (`club_transactions` بمفتاح idempotency وتحديث شرطي)، لأن الاستلام يحتاجه. والقواعد: فريق واحد في الدوري، 4 فرق نشطة، منع الانضمام في آخر 25%، ميزانية البداية بين 1 و10 ملايين، حصر الميزانية عند الاستلام بين 500 ألف وميزانية البداية، قفل الإعدادات عند البدء |
| W1 | شاشات: دورياتي، إنشاء دوري، الانضمام بالكود، طلبات الانضمام، اختيار الفريق |

**تعريف الانتهاء:**

- [ ] 20 طلباً متزامناً على نفس الفريق: واحد فقط ينجح، على SQLite الحقيقية لا في الذاكرة (اختبار)
- [ ] كل قاعدة في B4 مُختبرة

### 3. آخر الجلسة

- **الصور:** ارفعها إلى `art/raw/` بأسمائها، وشغّل `python3 tools/art/build.py` وشاهدها في `/dev/art`، ثم قل «راجع».
- **الكود:** Claude يفتح PR، وبعد نجاح CI يُدمج في `main`.
- **الخطة:** بعد كل مراجعة أو دمج تتحدث `SCHEDULE.md` وهذا الملف تلقائياً.

## ينتظر قرارك

| الموضوع | المطلوب | لماذا يهم |
|---|---|---|
| D0 / D1 | اعتماد نظام التصميم وشاشات السبرنتات 9 و10 و11 (المكونات، والحساب، والفريق) | الشاشات المكتوبة تنتظره، ولا تُكتب شاشة جديدة قبل تصميمها |
| Google OAuth | معرّفات Google OAuth للويب وAndroid في `.env` (`GOOGLE_CLIENT_ID`...) | الدخول بجوجل يعمل في الاختبارات فقط حتى تُضاف |
| PWA | تجربة تثبيت الموقع على جوال حقيقي | من تعريف انتهاء السبرنت 9 |
| ميزة الأرض | اعتماد +5% من القدرة و+4.5% من المبادرة بدل 2.5% (`docs/sprints/sprint-12.md`) | الرقم في `config/game.php` ويُغيَّر بسطر |

## القادم بالتواريخ

| السبرنت | العنوان | الأيام | من | إلى |
|---|---|---|---|---|
| 13 | الدوريات والانضمام | 12 | 2026-10-21 | 2026-11-01 |
| 14 | الدعوة والغياب والإشراف | 7 | 2026-11-02 | 2026-11-08 |
| 3 | محرك المشهد المصور، الدفعة 1 في المحاكاة | 9 | 2026-11-09 | 2026-11-17 |
| 4 | محاكاة الويب | 7 | 2026-11-18 | 2026-11-24 |
| 5 | محاكاة الموبايل | 7 | 2026-11-25 | 2026-12-01 |
| 6 | المعلق الإنجليزي الافتراضي | 7 | 2026-12-02 | 2026-12-08 |
| 7 | المعلق العربي وأصوات الملعب | 7 | 2026-12-09 | 2026-12-15 |
| 8 | السلاسة والاعتماد | 9 | 2026-12-16 | 2026-12-24 |
| 15 | الجدول والكأس | 9 | 2026-12-25 | 2027-01-02 |
| 16 | التشكيلة ومنفذو الكرات الثابتة | 7 | 2027-01-03 | 2027-01-09 |

**النسخ:** v0.1 في 24 ديسمبر 2026، v0.2 في 18 فبراير 2027، v1.0 في 31 مايو 2027، v1.1 في 1 يوليو 2027، v1.8 في 30 يوليو 2027.

## طريقة صنع الصورة

1. **افتح أمر الصورة** في ملف الجزء المذكور (`docs/art/images/`)، وابحث برقم اللوحة مثل `### 49.1`. والمرفوضة من ملف الإعادة.
2. **محادثة جديدة لكل حركة** في Gemini، مع المرفقات المكتوبة تحت «ارفق» بالضبط. وفي ملف الإعادة قسم **«أمر واحد لكل حركة»**: تلصقه مرة فيرسم صور الحركة واحدة بعد الأخرى، وإن توقف بعد صورة فاكتب **next**.
3. **انسخ الأمر كاملاً.** وفي الإعادة: الأمر من ملف الإعادة، وفي آخره سطر التصحيح.
4. **الصورة المقبولة:**
   - صورة واحدة عريضة **3:2** (مثل 1264x848)، لا مربعة ولا لوحات ملصوقة. المربعة يرسم فيها Gemini الأشكال أصغر، فيصغر اللاعب في اللعبة، و`build.py` ينبّه لها.
   - خلفية خضراء سادة (#00FF00): بلا كشافات، ولا تدرج، ولا أرضية.
   - عدد الأشكال المطلوب، بالزاوية المطلوبة، وكل إطار وضعية مختلفة.
   - نفس الشخص من البطاقة المرجعية، بلا أطراف مكررة.
5. **احفظها PNG حقيقياً** (لا JPEG باسم png) باسمها في `README.md` المجلد. بلا `(2)` وبلا امتداد ثانٍ.
6. **لا ترفع فوق صورة معتمدة (✅)** إلا إذا طلبت المراجعة ذلك.
7. **بعد الرفع:** إلى `art/raw/` بأسمائها، وشغّل `python3 tools/art/build.py` وشاهدها في `/dev/art`، ثم قل «راجع».

## الحالة بالأرقام

### الصور (أنت)

| الدفعة | المجموع | ✅ معتمد | ⏳ تنتظر المراجعة | 🔁 للإعادة | ⬜ لم تُصنع |
|---|---|---|---|---|---|
| 1 | 252 | 43 | 0 | 9 | 200 |
| 2 | 254 | 18 | 0 | 24 | 212 |
| 3 | 338 | 0 | 0 | 0 | 338 |
| 4 | 323 | 0 | 0 | 1 | 322 |
| 5 | 225 | 0 | 0 | 1 | 224 |
| 6 | 141 | 0 | 0 | 0 | 141 |
| 7 | 129 | 0 | 0 | 0 | 129 |
| 8 | 90 | 0 | 0 | 0 | 90 |
| 9 | 12 | 0 | 0 | 0 | 12 |
| 10 | 12 | 0 | 0 | 0 | 12 |
| **الكل** | **1776** | **61** | **0** | **35** | **1680** |

**صور حمزة (لوحات الملاعب):** 61 من 362 معتمدة. التفاصيل في [`HAMZA.md`](HAMZA.md).

### الصوت (حمزة)

الدفعة 1: 65 من 98 معتمدة. والكل: 65 من 428 مقطعاً، وأصوات الملعب 0 من 44. التفاصيل في [`HAMZA.md`](HAMZA.md).

**السبرنتات المنجزة:** 2، 9، 10، 11، 12 (والسبرنت 1). السجل في [`SPRINTS.md`](SPRINTS.md).

## كل الملفات

| الملف | ما فيه |
|---|---|
| [`SCHEDULE.md`](SCHEDULE.md) | الخطة يوماً يوماً: الكود والصور، وتاريخ كل نسخة |
| [`SPRINTS.md`](SPRINTS.md) | كل السبرنتات ومهامها، وسجل الإنجاز |
| [`sprints/sprint-02-days.md`](sprints/sprint-02-days.md) | صور الدفعة 1 بالترتيب: المنجز وما بقي |
| [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md) | إعادة: المهاجم: الجري والمشي (2026-10-20) |
| [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md) | إعادة: المهاجم: البداية والتوقف والدوران والوقوف (الدفعة 2) (2026-10-20) |
| [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md) | إعادة: المهاجم: الكرة (2026-10-20) |
| [`2026-10-20-striker-dribble-scale.md`](art/redo/2026-10-20-striker-dribble-scale.md) | إعادة: المهاجم: الدريبل بالمقياس الصحيح (2026-10-20) |
| [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md) | إعادة: المهاجم: الجري ثلاثة أرباع من الخلف، ومن الأمام، ومن الخلف (الإعادة الأولى) (2026-10-20) |
| [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md) | إعادة: الملاعب: الكلاسيكي نهاراً، والمغاربي ليلاً، والساحلي عند الغروب (حمزة) (2026-10-22) |
| [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md) | إعادة: المدربان 1 و2 (يدوياً) (2026-10-22) |
| [`2026-10-22-moments.md`](art/redo/2026-10-22-moments.md) | إعادة: لحظات جماعية متحركة (يدوياً) (2026-10-22) |
| [`art/images/00-waves.md`](art/images/00-waves.md) | كل الدفعات ومجموعاتها ومجلداتها |
| [`art/images/00-guide.md`](art/images/00-guide.md) | دليل كتاب الصور: الأسلوب وجمل التصحيح |
| [`HAMZA.md`](HAMZA.md) | مرجع حمزة: الصوت كله، ولوحات الملاعب |

## التقرير الكامل

### الصور: كل صورة بحالتها

**الحالة:** ✅ مكتمل (معتمد في المراجعة) · ⏳ مرفوع ينتظر المراجعة · 🔁 يجب إعادته · ⬜ لم يتم العمل عليه. **من:** للمكتمل والمرفوع من رفعه فعلاً (تاريخ git)، ولغيره من عليه أن يعمله.

| الدفعة | المجموع | ✅ | ⏳ | 🔁 | ⬜ |
|---|---|---|---|---|---|
| 1 | 252 | 43 | 0 | 9 | 200 |
| 2 | 254 | 18 | 0 | 24 | 212 |
| 3 | 338 | 0 | 0 | 0 | 338 |
| 4 | 323 | 0 | 0 | 1 | 322 |
| 5 | 225 | 0 | 0 | 1 | 224 |
| 6 | 141 | 0 | 0 | 0 | 141 |
| 7 | 129 | 0 | 0 | 0 | 129 |
| 8 | 90 | 0 | 0 | 0 | 90 |
| 9 | 12 | 0 | 0 | 0 | 12 |
| 10 | 12 | 0 | 0 | 0 | 12 |
| **الكل** | **1776** | **61** | **0** | **35** | **1680** |

#### الدفعة 1

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ✅ مكتمل | سليمان | 44.1 | `art/raw/striker/ref.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 44.2 | `art/raw/striker/faces.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.1 | `art/raw/striker/run/run-side-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.2 | `art/raw/striker/run/run-side-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.3 | `art/raw/striker/run/run-side-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.4 | `art/raw/striker/run/run-q-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.5 | `art/raw/striker/run/run-q-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.6 | `art/raw/striker/run/run-q-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.7 | `art/raw/striker/run/run-q-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.8 | `art/raw/striker/run/run-q-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.9 | `art/raw/striker/run/run-q-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.10 | `art/raw/striker/run/run-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | حمزة | 45.11 | `art/raw/striker/run/run-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | حمزة | 45.12 | `art/raw/striker/run/run-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| 🔁 يجب إعادته | سليمان | 45.13 | `art/raw/striker/run/run-back-01.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md): الرجل الواقفة تتبدل كل إطار (يسرى، يمنى، يسرى)، والمطلوب اليمنى في الثلاثة |
| 🔁 يجب إعادته | سليمان | 45.14 | `art/raw/striker/run/run-back-02.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md): الإطار 4 بقدمين على الأرض والمطلوب طيران، والإطاران 5 و6 على رجلين مختلفتين |
| 🔁 يجب إعادته | سليمان | 45.15 | `art/raw/striker/run/run-back-03.png` | [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md): الإطاران 7 و8 متطابقان تقريباً، والإطار 8 ليس طيراناً |
| ✅ مكتمل | سليمان | 45.16 | `art/raw/striker/run/sprint-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.17 | `art/raw/striker/run/sprint-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.18 | `art/raw/striker/run/sprint-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 45.19 | `art/raw/striker/run/sprint-04.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.1 | `art/raw/striker/ball/dribble-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.2 | `art/raw/striker/ball/dribble-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.3 | `art/raw/striker/ball/dribble-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.4 | `art/raw/striker/ball/shoot-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.5 | `art/raw/striker/ball/shoot-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | حمزة | 48.6 | `art/raw/striker/ball/shoot-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.7 | `art/raw/striker/ball/pass-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.8 | `art/raw/striker/ball/pass-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.9 | `art/raw/striker/ball/header-01.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.10 | `art/raw/striker/ball/header-02.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.11 | `art/raw/striker/ball/header-03.png` | [`03-players.md`](art/images/03-players.md) |
| ✅ مكتمل | سليمان | 48.12 | `art/raw/striker/ball/volley-01.png` | [`03-players.md`](art/images/03-players.md) |
| 🔁 يجب إعادته | سليمان | 48.13 | `art/raw/striker/ball/volley-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): الإطارات تكرر بداية الضربة، والمطلوب: متابعة الرجل عبر الجسم، ثم الهبوط على القدم اليمنى، ثم الوقوف |
| 🔁 يجب إعادته | سليمان | 48.14 | `art/raw/striker/ball/chip-01.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): الخلفية فيها كشافات |
| 🔁 يجب إعادته | سليمان | 48.15 | `art/raw/striker/ball/chip-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): الخلفية فيها كشافات |
| ✅ مكتمل | حمزة | 48.16 | `art/raw/striker/ball/cross-01.png` | [`03-players.md`](art/images/03-players.md) |
| 🔁 يجب إعادته | سليمان | 48.17 | `art/raw/striker/ball/cross-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): الإطاران 4 و5 جري مكرر، والمطلوب: لحظة لمس الكرة من تحتها، ثم المتابعة بذراعين مفتوحتين، ثم مراقبة العرضية |
| 🔁 يجب إعادته | سليمان | 48.18 | `art/raw/striker/ball/control-01.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): لوحات ملصوقة، والخلفية فيها كشافات |
| 🔁 يجب إعادته | سليمان | 48.19 | `art/raw/striker/ball/control-02.png` | [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md): ثلاث خطوات جري، والمطلوب: الكرة تموت عند قدمه (وقوف)، ثم يدفعها، ثم يبدأ الجري |
| ⬜ لم يتم العمل عليه | سليمان | 49.1 | `art/raw/striker/ground/tackle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.2 | `art/raw/striker/ground/tackle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.3 | `art/raw/striker/ground/tackle-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.4 | `art/raw/striker/ground/tackle-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.5 | `art/raw/striker/ground/fall-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.6 | `art/raw/striker/ground/fall-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.7 | `art/raw/striker/ground/fall-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.8 | `art/raw/striker/ground/fall-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.9 | `art/raw/striker/ground/block-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.10 | `art/raw/striker/ground/block-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.11 | `art/raw/striker/ground/block-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.12 | `art/raw/striker/ground/getup-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.13 | `art/raw/striker/ground/getup-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.14 | `art/raw/striker/ground/hurt-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 49.15 | `art/raw/striker/ground/hurt-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.1 | `art/raw/striker/emotion/celebrate-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.2 | `art/raw/striker/emotion/celebrate-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.3 | `art/raw/striker/emotion/celebrate-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.4 | `art/raw/striker/emotion/sad-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.5 | `art/raw/striker/emotion/sad-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.6 | `art/raw/striker/emotion/knee-slide-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.7 | `art/raw/striker/emotion/knee-slide-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.8 | `art/raw/striker/emotion/knee-slide-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.9 | `art/raw/striker/emotion/jump-cel-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.10 | `art/raw/striker/emotion/jump-cel-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.11 | `art/raw/striker/emotion/argue-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 50.12 | `art/raw/striker/emotion/argue-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 78.1 | `art/raw/players/look-1/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 78.2 | `art/raw/players/look-1/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.1 | `art/raw/players/look-1/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.2 | `art/raw/players/look-1/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.3 | `art/raw/players/look-1/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.4 | `art/raw/players/look-1/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.5 | `art/raw/players/look-1/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.6 | `art/raw/players/look-1/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 79.7 | `art/raw/players/look-1/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.1 | `art/raw/players/look-1/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.2 | `art/raw/players/look-1/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.3 | `art/raw/players/look-1/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.4 | `art/raw/players/look-1/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.5 | `art/raw/players/look-1/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.6 | `art/raw/players/look-1/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.7 | `art/raw/players/look-1/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.8 | `art/raw/players/look-1/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.9 | `art/raw/players/look-1/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.10 | `art/raw/players/look-1/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 81.11 | `art/raw/players/look-1/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.1 | `art/raw/players/look-1/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.2 | `art/raw/players/look-1/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.3 | `art/raw/players/look-1/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.4 | `art/raw/players/look-1/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.5 | `art/raw/players/look-1/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.6 | `art/raw/players/look-1/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.7 | `art/raw/players/look-1/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 82.8 | `art/raw/players/look-1/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 83.1 | `art/raw/players/look-1/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 83.2 | `art/raw/players/look-1/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 83.3 | `art/raw/players/look-1/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 83.4 | `art/raw/players/look-1/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 83.5 | `art/raw/players/look-1/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 84.1 | `art/raw/players/look-2/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 84.2 | `art/raw/players/look-2/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.1 | `art/raw/players/look-2/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.2 | `art/raw/players/look-2/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.3 | `art/raw/players/look-2/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.4 | `art/raw/players/look-2/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.5 | `art/raw/players/look-2/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.6 | `art/raw/players/look-2/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 85.7 | `art/raw/players/look-2/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.1 | `art/raw/players/look-2/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.2 | `art/raw/players/look-2/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.3 | `art/raw/players/look-2/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.4 | `art/raw/players/look-2/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.5 | `art/raw/players/look-2/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.6 | `art/raw/players/look-2/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.7 | `art/raw/players/look-2/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.8 | `art/raw/players/look-2/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.9 | `art/raw/players/look-2/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.10 | `art/raw/players/look-2/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 87.11 | `art/raw/players/look-2/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.1 | `art/raw/players/look-2/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.2 | `art/raw/players/look-2/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.3 | `art/raw/players/look-2/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.4 | `art/raw/players/look-2/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.5 | `art/raw/players/look-2/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.6 | `art/raw/players/look-2/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.7 | `art/raw/players/look-2/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 88.8 | `art/raw/players/look-2/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 89.1 | `art/raw/players/look-2/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 89.2 | `art/raw/players/look-2/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 89.3 | `art/raw/players/look-2/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 89.4 | `art/raw/players/look-2/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 89.5 | `art/raw/players/look-2/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 198.1 | `art/raw/keeper/ref.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 198.2 | `art/raw/keeper/faces.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 199.1 | `art/raw/keeper/ready/ready-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 199.2 | `art/raw/keeper/ready/ready-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 199.3 | `art/raw/keeper/ready/shuffle-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 199.4 | `art/raw/keeper/ready/shuffle-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.1 | `art/raw/keeper/dive/dive-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.2 | `art/raw/keeper/dive/dive-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.3 | `art/raw/keeper/dive/dive-high-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.4 | `art/raw/keeper/dive/dive-high-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.5 | `art/raw/keeper/dive/dive-high-05.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.6 | `art/raw/keeper/dive/dive-low-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.7 | `art/raw/keeper/dive/dive-low-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.8 | `art/raw/keeper/dive/dive-low-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.9 | `art/raw/keeper/dive/beaten-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 200.10 | `art/raw/keeper/dive/beaten-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.1 | `art/raw/keeper/hands/catch-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.2 | `art/raw/keeper/hands/catch-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.3 | `art/raw/keeper/hands/catch-chest-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.4 | `art/raw/keeper/hands/catch-chest-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.5 | `art/raw/keeper/hands/punch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.6 | `art/raw/keeper/hands/punch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.7 | `art/raw/keeper/hands/tip-over-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.8 | `art/raw/keeper/hands/tip-over-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.9 | `art/raw/keeper/hands/tip-over-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.10 | `art/raw/keeper/hands/save-land-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 201.11 | `art/raw/keeper/hands/save-land-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 202.1 | `art/raw/keeper/ground/getup-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 202.2 | `art/raw/keeper/ground/getup-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 204.1 | `art/raw/keeper/emotion/celebrate-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 204.2 | `art/raw/keeper/emotion/celebrate-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 230.1 | `art/raw/referee-1/ref.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 230.2 | `art/raw/referee-1/faces.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.1 | `art/raw/referee-1/run/run-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.2 | `art/raw/referee-1/run/run-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.3 | `art/raw/referee-1/run/run-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.4 | `art/raw/referee-1/run/run-back-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.5 | `art/raw/referee-1/run/run-back-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 231.6 | `art/raw/referee-1/run/run-back-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.1 | `art/raw/referee-1/signals/whistle-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.2 | `art/raw/referee-1/signals/whistle-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.3 | `art/raw/referee-1/signals/card-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.4 | `art/raw/referee-1/signals/card-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.5 | `art/raw/referee-1/signals/point-spot-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.6 | `art/raw/referee-1/signals/point-spot-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.7 | `art/raw/referee-1/signals/advantage-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 233.8 | `art/raw/referee-1/signals/advantage-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 234.1 | `art/raw/referee-1/var/var-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 234.2 | `art/raw/referee-1/var/var-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 234.3 | `art/raw/referee-1/var/monitor-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 234.4 | `art/raw/referee-1/var/monitor-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 245.1 | `art/raw/linesman/ref.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 246.1 | `art/raw/linesman/move/side-run-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 246.2 | `art/raw/linesman/move/side-run-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 246.3 | `art/raw/linesman/move/flag-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 246.4 | `art/raw/linesman/move/flag-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 247.1 | `art/raw/fourth/ref.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 248.1 | `art/raw/fourth/move/board-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 248.2 | `art/raw/fourth/move/board-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 250.1 | `art/raw/cards/yellow/ref-angles.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 250.2 | `art/raw/cards/yellow/ref-pocket.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 250.3 | `art/raw/cards/yellow/close.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 250.4 | `art/raw/cards/yellow/reactions-a.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 250.5 | `art/raw/cards/yellow/reactions-b.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 251.1 | `art/raw/cards/red/ref-angles.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 251.2 | `art/raw/cards/red/close.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 251.3 | `art/raw/cards/red/sent-off.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 251.4 | `art/raw/cards/red/protest-a.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 251.5 | `art/raw/cards/red/protest-b.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 256.1 | `art/raw/celebrations/solo-1.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 256.2 | `art/raw/celebrations/solo-2.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 256.3 | `art/raw/celebrations/solo-3.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 256.4 | `art/raw/celebrations/solo-4.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 260.1 | `art/raw/coach-1/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 260.2 | `art/raw/coach-1/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 261.1 | `art/raw/coach-1/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 261.2 | `art/raw/coach-1/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 262.1 | `art/raw/coach-1/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 262.2 | `art/raw/coach-1/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.1 | `art/raw/coach-1/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.2 | `art/raw/coach-1/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.3 | `art/raw/coach-1/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.4 | `art/raw/coach-1/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.5 | `art/raw/coach-1/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ✅ مكتمل | سليمان | 263.6 | `art/raw/coach-1/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 300.1 | `art/raw/medics/sheet-1-a.png` | [`10-bench.md`](art/images/10-bench.md) |
| ⬜ لم يتم العمل عليه | سليمان | 300.2 | `art/raw/medics/sheet-1-b.png` | [`10-bench.md`](art/images/10-bench.md) |
| ⬜ لم يتم العمل عليه | سليمان | 301.1 | `art/raw/bench/sheet-1-a.png` | [`10-bench.md`](art/images/10-bench.md) |
| ⬜ لم يتم العمل عليه | سليمان | 301.2 | `art/raw/bench/sheet-1-b.png` | [`10-bench.md`](art/images/10-bench.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.1 | `art/raw/crowd/ultras.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.2 | `art/raw/crowd/tifo.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.3 | `art/raw/crowd/phones.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.4 | `art/raw/crowd/family.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.5 | `art/raw/crowd/anguish.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.6 | `art/raw/crowd/pray.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.7 | `art/raw/crowd/away-end.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.8 | `art/raw/crowd/rain-fans.jpg` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 302.9 | `art/raw/crowd/foreground.png` | [`11-crowd.md`](art/images/11-crowd.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.1 | `art/raw/balls/classic/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.2 | `art/raw/balls/classic/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.3 | `art/raw/balls/classic/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.4 | `art/raw/balls/classic/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.5 | `art/raw/balls/classic/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 304.6 | `art/raw/balls/classic/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 310.1 | `art/raw/goals/standard/bulge-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 310.2 | `art/raw/goals/standard/bulge-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 310.3 | `art/raw/goals/standard/bulge-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 310.4 | `art/raw/goals/standard/shake-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 310.5 | `art/raw/goals/standard/shake-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 317.1 | `art/raw/goals/standard/views.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 317.2 | `art/raw/goals/standard/hits.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.1 | `art/raw/fx/ground/grass-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.2 | `art/raw/fx/ground/grass-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.3 | `art/raw/fx/ground/water-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.4 | `art/raw/fx/ground/water-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.5 | `art/raw/fx/ground/snow-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.6 | `art/raw/fx/ground/snow-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.7 | `art/raw/fx/ground/dust-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 323.8 | `art/raw/fx/ground/dust-02.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 2

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| 🔁 يجب إعادته | سليمان | 2.3 | `art/raw/stadiums/classic/day/wing.jpg` | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md): لا يظهر أي مرمى. المطلوب مرمى واحد صغير على الحافة اليمنى (عرضيات الجناح تتجه إليه) |
| ⬜ لم يتم العمل عليه | سليمان | 16.1 | `art/raw/scenes/aerial-night.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.2 | `art/raw/scenes/aerial-day.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.3 | `art/raw/scenes/tunnel.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.4 | `art/raw/scenes/dressing-room.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.5 | `art/raw/scenes/dressing-joy.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.6 | `art/raw/scenes/fans-arrive.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.7 | `art/raw/scenes/team-bus.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| ⬜ لم يتم العمل عليه | سليمان | 16.8 | `art/raw/scenes/press-room.jpg` | [`01-stadium.md`](art/images/01-stadium.md) |
| 🔁 يجب إعادته | سليمان | 46.1 | `art/raw/striker/walk/jog-01.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): ثلاث لوحات ملصوقة بخطوط فاصلة، والخلفية فيها كشافات وتدرج، والإطار الثالث ركبة عالية لا هرولة |
| 🔁 يجب إعادته | سليمان | 46.2 | `art/raw/striker/walk/jog-02.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): نفس مشكلة الخلفية واللوحات، وتكاد تطابق jog-03 |
| 🔁 يجب إعادته | سليمان | 46.3 | `art/raw/striker/walk/jog-03.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): نفس مشكلة الخلفية واللوحات، وشبه مطابقة لـ jog-02 وwalk-03، وفيها 3 أشكال والمطلوب 2 |
| 🔁 يجب إعادته | سليمان | 46.4 | `art/raw/striker/walk/walk-01.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): ثلاث لوحات ملصوقة، والخلفية فيها كشافات، والإطار الثالث ركبة عالية لا مشي |
| 🔁 يجب إعادته | سليمان | 46.5 | `art/raw/striker/walk/walk-02.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): نفس المشكلة، والإطار الأول ركبة عالية |
| 🔁 يجب إعادته | سليمان | 46.6 | `art/raw/striker/walk/walk-03.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): نفس المشكلة، وفيها 3 أشكال والمطلوب 2، وفيها ركبتان عاليتان |
| 🔁 يجب إعادته | سليمان | 46.7 | `art/raw/striker/walk/walk-front-01.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية صحيحة (من الأمام)، لكن الخلفية فيها كشافات وتدرج واللوحات ملصوقة |
| 🔁 يجب إعادته | سليمان | 46.8 | `art/raw/striker/walk/walk-front-02.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية خطأ (جانبية والمطلوب من الأمام)، والخلفية فيها كشافات |
| 🔁 يجب إعادته | سليمان | 46.9 | `art/raw/striker/walk/walk-front-03.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية خطأ (جانبية)، وتكاد تطابق walk-front-02، وفيها 3 أشكال والمطلوب 2 |
| 🔁 يجب إعادته | سليمان | 46.10 | `art/raw/striker/walk/walk-back-01.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية صحيحة (من الخلف)، لكن الخلفية فيها كشافات واللوحات ملصوقة |
| 🔁 يجب إعادته | سليمان | 46.11 | `art/raw/striker/walk/walk-back-02.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية خطأ (جانبية والوجه ظاهر)، وفيها ركبة عالية |
| 🔁 يجب إعادته | سليمان | 46.12 | `art/raw/striker/walk/walk-back-03.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): الزاوية خطأ (جانبية)، وفيها 3 أشكال والمطلوب 2 |
| 🔁 يجب إعادته | سليمان | 46.13 | `art/raw/striker/walk/backpedal-01.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): يمشي للأمام لا للخلف، والخلفية فيها كشافات |
| 🔁 يجب إعادته | سليمان | 46.14 | `art/raw/striker/walk/backpedal-02.png` | [`2026-10-20-striker-run-walk.md`](art/redo/2026-10-20-striker-run-walk.md): نفس المشكلة: مشي للأمام، والخلفية فيها كشافات |
| ✅ مكتمل | حمزة | 47.1 | `art/raw/striker/start/start-01.png` | [`03-players.md`](art/images/03-players.md) |
| 🔁 يجب إعادته | سليمان | 47.2 | `art/raw/striker/start/start-02.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الإطار 4 وقوف (يكرر الإطار 1 من start-01)، والمطلوب الخطوة الثانية فالثالثة فالجري الكامل |
| 🔁 يجب إعادته | سليمان | 47.3 | `art/raw/striker/start/stop-01.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الإطاران 1 و2 شبه متطابقين، والإطار 1 ليس جرياً بأقصى سرعة، والإطار 3 وقوف |
| 🔁 يجب إعادته | سليمان | 47.4 | `art/raw/striker/start/stop-02.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الإطار 4 خطوة جري (رجوع للخلف في الحركة)، والمطلوب: شبه متوقف بركبتين منثنيتين، ثم يستعيد توازنه، ثم يقف |
| 🔁 يجب إعادته | سليمان | 47.5 | `art/raw/striker/start/turn-01.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الترتيب معكوس: يبدأ من الأمام وينتهي جانبياً، والمطلوب العكس (جانبي، ثم ثلاثة أرباع، ثم من الأمام). واسم الملف خطأ |
| 🔁 يجب إعادته | سليمان | 47.6 | `art/raw/striker/start/turn-02.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الزوايا خطأ: من الخلف وجانبي لليمين، والمطلوب: ثلاثة أرباع لليسار، ثم جانبي لليسار، ثم واقف لليسار |
| 🔁 يجب إعادته | سليمان | 47.7 | `art/raw/striker/start/idle-01.png` | [`2026-10-20-striker-start.md`](art/redo/2026-10-20-striker-start.md): الخلفية فيها كشافات وتدرج أخضر فلا تُقص |
| ✅ مكتمل | حمزة | 47.8 | `art/raw/striker/start/idle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.1 | `art/raw/striker/setpiece/pk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.2 | `art/raw/striker/setpiece/pk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.3 | `art/raw/striker/setpiece/pk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.4 | `art/raw/striker/setpiece/pk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.5 | `art/raw/striker/setpiece/pk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.6 | `art/raw/striker/setpiece/freekick-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.7 | `art/raw/striker/setpiece/freekick-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.8 | `art/raw/striker/setpiece/throwin-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.9 | `art/raw/striker/setpiece/throwin-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.10 | `art/raw/striker/setpiece/corner-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 51.11 | `art/raw/striker/setpiece/corner-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 68.1 | `art/raw/defender/ref.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 68.2 | `art/raw/defender/faces.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.1 | `art/raw/defender/run/run-side-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.2 | `art/raw/defender/run/run-side-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.3 | `art/raw/defender/run/run-side-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.4 | `art/raw/defender/run/run-q-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.5 | `art/raw/defender/run/run-q-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.6 | `art/raw/defender/run/run-q-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.7 | `art/raw/defender/run/run-q-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.8 | `art/raw/defender/run/run-q-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.9 | `art/raw/defender/run/run-q-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.10 | `art/raw/defender/run/run-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.11 | `art/raw/defender/run/run-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.12 | `art/raw/defender/run/run-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.13 | `art/raw/defender/run/run-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.14 | `art/raw/defender/run/run-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.15 | `art/raw/defender/run/run-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.16 | `art/raw/defender/run/sprint-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.17 | `art/raw/defender/run/sprint-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.18 | `art/raw/defender/run/sprint-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 69.19 | `art/raw/defender/run/sprint-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.1 | `art/raw/defender/ball/dribble-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.2 | `art/raw/defender/ball/dribble-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.3 | `art/raw/defender/ball/dribble-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.4 | `art/raw/defender/ball/shoot-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.5 | `art/raw/defender/ball/shoot-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.6 | `art/raw/defender/ball/shoot-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.7 | `art/raw/defender/ball/pass-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.8 | `art/raw/defender/ball/pass-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.9 | `art/raw/defender/ball/header-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.10 | `art/raw/defender/ball/header-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.11 | `art/raw/defender/ball/header-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.12 | `art/raw/defender/ball/volley-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.13 | `art/raw/defender/ball/volley-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.14 | `art/raw/defender/ball/chip-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.15 | `art/raw/defender/ball/chip-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.16 | `art/raw/defender/ball/cross-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.17 | `art/raw/defender/ball/cross-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.18 | `art/raw/defender/ball/control-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 72.19 | `art/raw/defender/ball/control-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.1 | `art/raw/defender/ground/tackle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.2 | `art/raw/defender/ground/tackle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.3 | `art/raw/defender/ground/tackle-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.4 | `art/raw/defender/ground/tackle-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.5 | `art/raw/defender/ground/fall-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.6 | `art/raw/defender/ground/fall-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.7 | `art/raw/defender/ground/fall-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.8 | `art/raw/defender/ground/fall-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.9 | `art/raw/defender/ground/block-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.10 | `art/raw/defender/ground/block-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.11 | `art/raw/defender/ground/block-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.12 | `art/raw/defender/ground/getup-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.13 | `art/raw/defender/ground/getup-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.14 | `art/raw/defender/ground/hurt-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 73.15 | `art/raw/defender/ground/hurt-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.1 | `art/raw/defender/emotion/celebrate-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.2 | `art/raw/defender/emotion/celebrate-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.3 | `art/raw/defender/emotion/celebrate-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.4 | `art/raw/defender/emotion/sad-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.5 | `art/raw/defender/emotion/sad-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.6 | `art/raw/defender/emotion/knee-slide-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.7 | `art/raw/defender/emotion/knee-slide-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.8 | `art/raw/defender/emotion/knee-slide-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.9 | `art/raw/defender/emotion/jump-cel-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.10 | `art/raw/defender/emotion/jump-cel-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.11 | `art/raw/defender/emotion/argue-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 74.12 | `art/raw/defender/emotion/argue-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 76.1 | `art/raw/striker-states/sheet-rain-a.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 76.2 | `art/raw/striker-states/sheet-rain-b.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 76.3 | `art/raw/striker-states/sheet-tired-a.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 76.4 | `art/raw/striker-states/sheet-tired-b.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 77.1 | `art/raw/striker-skills/sheet-bicycle.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 77.2 | `art/raw/striker-skills/sheet-skill-a.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 77.3 | `art/raw/striker-skills/sheet-skill-b.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.1 | `art/raw/players/look-1/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.2 | `art/raw/players/look-1/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.3 | `art/raw/players/look-1/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.4 | `art/raw/players/look-1/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.5 | `art/raw/players/look-1/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 80.6 | `art/raw/players/look-1/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.1 | `art/raw/players/look-2/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.2 | `art/raw/players/look-2/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.3 | `art/raw/players/look-2/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.4 | `art/raw/players/look-2/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.5 | `art/raw/players/look-2/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 86.6 | `art/raw/players/look-2/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 90.1 | `art/raw/players/look-3/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 90.2 | `art/raw/players/look-3/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.1 | `art/raw/players/look-3/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.2 | `art/raw/players/look-3/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.3 | `art/raw/players/look-3/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.4 | `art/raw/players/look-3/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.5 | `art/raw/players/look-3/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.6 | `art/raw/players/look-3/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 91.7 | `art/raw/players/look-3/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.1 | `art/raw/players/look-3/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.2 | `art/raw/players/look-3/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.3 | `art/raw/players/look-3/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.4 | `art/raw/players/look-3/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.5 | `art/raw/players/look-3/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 92.6 | `art/raw/players/look-3/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.1 | `art/raw/players/look-3/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.2 | `art/raw/players/look-3/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.3 | `art/raw/players/look-3/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.4 | `art/raw/players/look-3/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.5 | `art/raw/players/look-3/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.6 | `art/raw/players/look-3/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.7 | `art/raw/players/look-3/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.8 | `art/raw/players/look-3/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.9 | `art/raw/players/look-3/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.10 | `art/raw/players/look-3/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 93.11 | `art/raw/players/look-3/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.1 | `art/raw/players/look-3/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.2 | `art/raw/players/look-3/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.3 | `art/raw/players/look-3/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.4 | `art/raw/players/look-3/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.5 | `art/raw/players/look-3/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.6 | `art/raw/players/look-3/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.7 | `art/raw/players/look-3/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 94.8 | `art/raw/players/look-3/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 95.1 | `art/raw/players/look-3/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 95.2 | `art/raw/players/look-3/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 95.3 | `art/raw/players/look-3/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 95.4 | `art/raw/players/look-3/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 95.5 | `art/raw/players/look-3/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 203.1 | `art/raw/keeper/distribute/kick-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 203.2 | `art/raw/keeper/distribute/kick-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 203.3 | `art/raw/keeper/distribute/kick-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 203.4 | `art/raw/keeper/distribute/throw-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 203.5 | `art/raw/keeper/distribute/throw-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.1 | `art/raw/keeper/penalty/front-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.2 | `art/raw/keeper/penalty/front-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.3 | `art/raw/keeper/penalty/front-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.4 | `art/raw/keeper/penalty/front-dive-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.5 | `art/raw/keeper/penalty/front-catch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.6 | `art/raw/keeper/penalty/front-catch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.7 | `art/raw/keeper/penalty/back-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.8 | `art/raw/keeper/penalty/back-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 205.9 | `art/raw/keeper/penalty/back-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 232.1 | `art/raw/referee-1/walk/walk-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 232.2 | `art/raw/referee-1/walk/walk-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 232.3 | `art/raw/referee-1/walk/walk-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 252.1 | `art/raw/referee-calls/calls-1.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 252.2 | `art/raw/referee-calls/calls-2.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 252.3 | `art/raw/referee-calls/calls-3.png` | [`07-situations.md`](art/images/07-situations.md) |
| ✅ مكتمل | سليمان | 255.1 | `art/raw/team/hug-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.2 | `art/raw/team/hug-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.3 | `art/raw/team/high-five-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.4 | `art/raw/team/high-five-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.5 | `art/raw/team/header-duel-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.6 | `art/raw/team/header-duel-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.7 | `art/raw/team/header-duel-03.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.8 | `art/raw/team/tackle-duel-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.9 | `art/raw/team/tackle-duel-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.10 | `art/raw/team/tackle-duel-03.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.11 | `art/raw/team/pile-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.12 | `art/raw/team/pile-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.13 | `art/raw/team/shake-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.14 | `art/raw/team/shake-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.15 | `art/raw/team/push-01.png` | [`08-moments.md`](art/images/08-moments.md) |
| ✅ مكتمل | سليمان | 255.16 | `art/raw/team/push-02.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 257.1 | `art/raw/team-celebrations/team-1.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 257.2 | `art/raw/team-celebrations/team-2.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 257.3 | `art/raw/team-celebrations/team-3.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 257.4 | `art/raw/team-celebrations/final-whistle.png` | [`08-moments.md`](art/images/08-moments.md) |
| 🔁 يجب إعادته | سليمان | 264.1 | `art/raw/coach-2/ref.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): الوجه شبيه جداً بمدرب حقيقي مشهور، والمطلوب شخص مخترع |
| 🔁 يجب إعادته | سليمان | 264.2 | `art/raw/coach-2/faces.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة |
| 🔁 يجب إعادته | سليمان | 265.1 | `art/raw/coach-2/start/idle-01.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة |
| ⬜ لم يتم العمل عليه | سليمان | 265.2 | `art/raw/coach-2/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 266.1 | `art/raw/coach-2/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 266.2 | `art/raw/coach-2/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.1 | `art/raw/coach-2/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.2 | `art/raw/coach-2/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.3 | `art/raw/coach-2/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.4 | `art/raw/coach-2/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.5 | `art/raw/coach-2/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 267.6 | `art/raw/coach-2/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.1 | `art/raw/balls/league/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.2 | `art/raw/balls/league/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.3 | `art/raw/balls/league/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.4 | `art/raw/balls/league/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.5 | `art/raw/balls/league/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 305.6 | `art/raw/balls/league/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 311.1 | `art/raw/goals/deep/bulge-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 311.2 | `art/raw/goals/deep/bulge-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 311.3 | `art/raw/goals/deep/bulge-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 311.4 | `art/raw/goals/deep/shake-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 311.5 | `art/raw/goals/deep/shake-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.1 | `art/raw/flags/corner-flag-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.2 | `art/raw/flags/corner-flag-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.3 | `art/raw/flags/fan-flag-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.4 | `art/raw/flags/fan-flag-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.5 | `art/raw/flags/linesman-flag-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 315.6 | `art/raw/flags/linesman-flag-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.1 | `art/raw/props/sheet-1-a.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.2 | `art/raw/props/sheet-1-b.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.3 | `art/raw/props/sheet-2-a.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.4 | `art/raw/props/sheet-2-b.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.5 | `art/raw/props/sheet-3-a.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 316.6 | `art/raw/props/sheet-3-b.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 318.1 | `art/raw/goals/deep/views.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 318.2 | `art/raw/goals/deep/hits.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 322.1 | `art/raw/net/net-inside.jpg` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 322.2 | `art/raw/net/net-top.jpg` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 322.3 | `art/raw/net/post-close.jpg` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 322.4 | `art/raw/net/line-close.jpg` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.1 | `art/raw/fx/weather/rain-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.2 | `art/raw/fx/weather/rain-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.3 | `art/raw/fx/weather/snow-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.4 | `art/raw/fx/weather/snow-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.5 | `art/raw/fx/weather/fog-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 324.6 | `art/raw/fx/weather/fog-02.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 3

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 52.1 | `art/raw/winger/ref.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 52.2 | `art/raw/winger/faces.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.1 | `art/raw/winger/run/run-side-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.2 | `art/raw/winger/run/run-side-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.3 | `art/raw/winger/run/run-side-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.4 | `art/raw/winger/run/run-q-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.5 | `art/raw/winger/run/run-q-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.6 | `art/raw/winger/run/run-q-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.7 | `art/raw/winger/run/run-q-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.8 | `art/raw/winger/run/run-q-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.9 | `art/raw/winger/run/run-q-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.10 | `art/raw/winger/run/run-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.11 | `art/raw/winger/run/run-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.12 | `art/raw/winger/run/run-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.13 | `art/raw/winger/run/run-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.14 | `art/raw/winger/run/run-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.15 | `art/raw/winger/run/run-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.16 | `art/raw/winger/run/sprint-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.17 | `art/raw/winger/run/sprint-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.18 | `art/raw/winger/run/sprint-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 53.19 | `art/raw/winger/run/sprint-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.1 | `art/raw/winger/ball/dribble-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.2 | `art/raw/winger/ball/dribble-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.3 | `art/raw/winger/ball/dribble-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.4 | `art/raw/winger/ball/shoot-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.5 | `art/raw/winger/ball/shoot-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.6 | `art/raw/winger/ball/shoot-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.7 | `art/raw/winger/ball/pass-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.8 | `art/raw/winger/ball/pass-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.9 | `art/raw/winger/ball/header-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.10 | `art/raw/winger/ball/header-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.11 | `art/raw/winger/ball/header-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.12 | `art/raw/winger/ball/volley-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.13 | `art/raw/winger/ball/volley-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.14 | `art/raw/winger/ball/chip-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.15 | `art/raw/winger/ball/chip-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.16 | `art/raw/winger/ball/cross-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.17 | `art/raw/winger/ball/cross-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.18 | `art/raw/winger/ball/control-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 56.19 | `art/raw/winger/ball/control-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.1 | `art/raw/winger/ground/tackle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.2 | `art/raw/winger/ground/tackle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.3 | `art/raw/winger/ground/tackle-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.4 | `art/raw/winger/ground/tackle-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.5 | `art/raw/winger/ground/fall-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.6 | `art/raw/winger/ground/fall-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.7 | `art/raw/winger/ground/fall-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.8 | `art/raw/winger/ground/fall-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.9 | `art/raw/winger/ground/block-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.10 | `art/raw/winger/ground/block-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.11 | `art/raw/winger/ground/block-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.12 | `art/raw/winger/ground/getup-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.13 | `art/raw/winger/ground/getup-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.14 | `art/raw/winger/ground/hurt-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 57.15 | `art/raw/winger/ground/hurt-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.1 | `art/raw/winger/emotion/celebrate-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.2 | `art/raw/winger/emotion/celebrate-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.3 | `art/raw/winger/emotion/celebrate-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.4 | `art/raw/winger/emotion/sad-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.5 | `art/raw/winger/emotion/sad-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.6 | `art/raw/winger/emotion/knee-slide-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.7 | `art/raw/winger/emotion/knee-slide-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.8 | `art/raw/winger/emotion/knee-slide-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.9 | `art/raw/winger/emotion/jump-cel-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.10 | `art/raw/winger/emotion/jump-cel-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.11 | `art/raw/winger/emotion/argue-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 58.12 | `art/raw/winger/emotion/argue-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.1 | `art/raw/defender/walk/jog-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.2 | `art/raw/defender/walk/jog-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.3 | `art/raw/defender/walk/jog-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.4 | `art/raw/defender/walk/walk-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.5 | `art/raw/defender/walk/walk-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.6 | `art/raw/defender/walk/walk-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.7 | `art/raw/defender/walk/walk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.8 | `art/raw/defender/walk/walk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.9 | `art/raw/defender/walk/walk-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.10 | `art/raw/defender/walk/walk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.11 | `art/raw/defender/walk/walk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.12 | `art/raw/defender/walk/walk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.13 | `art/raw/defender/walk/backpedal-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 70.14 | `art/raw/defender/walk/backpedal-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.1 | `art/raw/defender/start/start-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.2 | `art/raw/defender/start/start-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.3 | `art/raw/defender/start/stop-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.4 | `art/raw/defender/start/stop-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.5 | `art/raw/defender/start/turn-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.6 | `art/raw/defender/start/turn-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.7 | `art/raw/defender/start/idle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 71.8 | `art/raw/defender/start/idle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.1 | `art/raw/defender/setpiece/pk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.2 | `art/raw/defender/setpiece/pk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.3 | `art/raw/defender/setpiece/pk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.4 | `art/raw/defender/setpiece/pk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.5 | `art/raw/defender/setpiece/pk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.6 | `art/raw/defender/setpiece/freekick-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.7 | `art/raw/defender/setpiece/freekick-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.8 | `art/raw/defender/setpiece/throwin-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.9 | `art/raw/defender/setpiece/throwin-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.10 | `art/raw/defender/setpiece/corner-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 75.11 | `art/raw/defender/setpiece/corner-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 96.1 | `art/raw/players/look-4/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 96.2 | `art/raw/players/look-4/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.1 | `art/raw/players/look-4/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.2 | `art/raw/players/look-4/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.3 | `art/raw/players/look-4/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.4 | `art/raw/players/look-4/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.5 | `art/raw/players/look-4/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.6 | `art/raw/players/look-4/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 97.7 | `art/raw/players/look-4/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.1 | `art/raw/players/look-4/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.2 | `art/raw/players/look-4/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.3 | `art/raw/players/look-4/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.4 | `art/raw/players/look-4/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.5 | `art/raw/players/look-4/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 98.6 | `art/raw/players/look-4/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.1 | `art/raw/players/look-4/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.2 | `art/raw/players/look-4/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.3 | `art/raw/players/look-4/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.4 | `art/raw/players/look-4/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.5 | `art/raw/players/look-4/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.6 | `art/raw/players/look-4/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.7 | `art/raw/players/look-4/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.8 | `art/raw/players/look-4/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.9 | `art/raw/players/look-4/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.10 | `art/raw/players/look-4/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 99.11 | `art/raw/players/look-4/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.1 | `art/raw/players/look-4/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.2 | `art/raw/players/look-4/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.3 | `art/raw/players/look-4/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.4 | `art/raw/players/look-4/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.5 | `art/raw/players/look-4/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.6 | `art/raw/players/look-4/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.7 | `art/raw/players/look-4/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 100.8 | `art/raw/players/look-4/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 101.1 | `art/raw/players/look-4/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 101.2 | `art/raw/players/look-4/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 101.3 | `art/raw/players/look-4/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 101.4 | `art/raw/players/look-4/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 101.5 | `art/raw/players/look-4/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 102.1 | `art/raw/players/look-5/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 102.2 | `art/raw/players/look-5/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.1 | `art/raw/players/look-5/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.2 | `art/raw/players/look-5/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.3 | `art/raw/players/look-5/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.4 | `art/raw/players/look-5/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.5 | `art/raw/players/look-5/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.6 | `art/raw/players/look-5/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 103.7 | `art/raw/players/look-5/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.1 | `art/raw/players/look-5/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.2 | `art/raw/players/look-5/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.3 | `art/raw/players/look-5/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.4 | `art/raw/players/look-5/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.5 | `art/raw/players/look-5/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 104.6 | `art/raw/players/look-5/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.1 | `art/raw/players/look-5/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.2 | `art/raw/players/look-5/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.3 | `art/raw/players/look-5/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.4 | `art/raw/players/look-5/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.5 | `art/raw/players/look-5/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.6 | `art/raw/players/look-5/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.7 | `art/raw/players/look-5/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.8 | `art/raw/players/look-5/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.9 | `art/raw/players/look-5/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.10 | `art/raw/players/look-5/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 105.11 | `art/raw/players/look-5/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.1 | `art/raw/players/look-5/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.2 | `art/raw/players/look-5/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.3 | `art/raw/players/look-5/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.4 | `art/raw/players/look-5/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.5 | `art/raw/players/look-5/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.6 | `art/raw/players/look-5/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.7 | `art/raw/players/look-5/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 106.8 | `art/raw/players/look-5/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 107.1 | `art/raw/players/look-5/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 107.2 | `art/raw/players/look-5/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 107.3 | `art/raw/players/look-5/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 107.4 | `art/raw/players/look-5/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 107.5 | `art/raw/players/look-5/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 108.1 | `art/raw/players/look-6/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 108.2 | `art/raw/players/look-6/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.1 | `art/raw/players/look-6/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.2 | `art/raw/players/look-6/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.3 | `art/raw/players/look-6/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.4 | `art/raw/players/look-6/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.5 | `art/raw/players/look-6/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.6 | `art/raw/players/look-6/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 109.7 | `art/raw/players/look-6/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.1 | `art/raw/players/look-6/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.2 | `art/raw/players/look-6/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.3 | `art/raw/players/look-6/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.4 | `art/raw/players/look-6/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.5 | `art/raw/players/look-6/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 110.6 | `art/raw/players/look-6/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.1 | `art/raw/players/look-6/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.2 | `art/raw/players/look-6/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.3 | `art/raw/players/look-6/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.4 | `art/raw/players/look-6/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.5 | `art/raw/players/look-6/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.6 | `art/raw/players/look-6/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.7 | `art/raw/players/look-6/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.8 | `art/raw/players/look-6/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.9 | `art/raw/players/look-6/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.10 | `art/raw/players/look-6/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 111.11 | `art/raw/players/look-6/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.1 | `art/raw/players/look-6/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.2 | `art/raw/players/look-6/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.3 | `art/raw/players/look-6/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.4 | `art/raw/players/look-6/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.5 | `art/raw/players/look-6/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.6 | `art/raw/players/look-6/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.7 | `art/raw/players/look-6/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 112.8 | `art/raw/players/look-6/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 113.1 | `art/raw/players/look-6/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 113.2 | `art/raw/players/look-6/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 113.3 | `art/raw/players/look-6/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 113.4 | `art/raw/players/look-6/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 113.5 | `art/raw/players/look-6/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 206.1 | `art/raw/keeper-2/ref.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 206.2 | `art/raw/keeper-2/faces.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 207.1 | `art/raw/keeper-2/ready/ready-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 207.2 | `art/raw/keeper-2/ready/ready-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 207.3 | `art/raw/keeper-2/ready/shuffle-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 207.4 | `art/raw/keeper-2/ready/shuffle-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.1 | `art/raw/keeper-2/dive/dive-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.2 | `art/raw/keeper-2/dive/dive-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.3 | `art/raw/keeper-2/dive/dive-high-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.4 | `art/raw/keeper-2/dive/dive-high-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.5 | `art/raw/keeper-2/dive/dive-high-05.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.6 | `art/raw/keeper-2/dive/dive-low-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.7 | `art/raw/keeper-2/dive/dive-low-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.8 | `art/raw/keeper-2/dive/dive-low-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.9 | `art/raw/keeper-2/dive/beaten-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 208.10 | `art/raw/keeper-2/dive/beaten-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.1 | `art/raw/keeper-2/hands/catch-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.2 | `art/raw/keeper-2/hands/catch-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.3 | `art/raw/keeper-2/hands/catch-chest-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.4 | `art/raw/keeper-2/hands/catch-chest-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.5 | `art/raw/keeper-2/hands/punch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.6 | `art/raw/keeper-2/hands/punch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.7 | `art/raw/keeper-2/hands/tip-over-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.8 | `art/raw/keeper-2/hands/tip-over-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.9 | `art/raw/keeper-2/hands/tip-over-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.10 | `art/raw/keeper-2/hands/save-land-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 209.11 | `art/raw/keeper-2/hands/save-land-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 210.1 | `art/raw/keeper-2/ground/getup-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 210.2 | `art/raw/keeper-2/ground/getup-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 211.1 | `art/raw/keeper-2/distribute/kick-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 211.2 | `art/raw/keeper-2/distribute/kick-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 211.3 | `art/raw/keeper-2/distribute/kick-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 211.4 | `art/raw/keeper-2/distribute/throw-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 211.5 | `art/raw/keeper-2/distribute/throw-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 212.1 | `art/raw/keeper-2/emotion/celebrate-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 212.2 | `art/raw/keeper-2/emotion/celebrate-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.1 | `art/raw/keeper-2/penalty/front-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.2 | `art/raw/keeper-2/penalty/front-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.3 | `art/raw/keeper-2/penalty/front-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.4 | `art/raw/keeper-2/penalty/front-dive-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.5 | `art/raw/keeper-2/penalty/front-catch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.6 | `art/raw/keeper-2/penalty/front-catch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.7 | `art/raw/keeper-2/penalty/back-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.8 | `art/raw/keeper-2/penalty/back-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 213.9 | `art/raw/keeper-2/penalty/back-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 235.1 | `art/raw/referee-2/ref.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 235.2 | `art/raw/referee-2/faces.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.1 | `art/raw/referee-2/run/run-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.2 | `art/raw/referee-2/run/run-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.3 | `art/raw/referee-2/run/run-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.4 | `art/raw/referee-2/run/run-back-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.5 | `art/raw/referee-2/run/run-back-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 236.6 | `art/raw/referee-2/run/run-back-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 237.1 | `art/raw/referee-2/walk/walk-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 237.2 | `art/raw/referee-2/walk/walk-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 237.3 | `art/raw/referee-2/walk/walk-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.1 | `art/raw/referee-2/signals/whistle-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.2 | `art/raw/referee-2/signals/whistle-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.3 | `art/raw/referee-2/signals/card-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.4 | `art/raw/referee-2/signals/card-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.5 | `art/raw/referee-2/signals/point-spot-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.6 | `art/raw/referee-2/signals/point-spot-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.7 | `art/raw/referee-2/signals/advantage-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 238.8 | `art/raw/referee-2/signals/advantage-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 239.1 | `art/raw/referee-2/var/var-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 239.2 | `art/raw/referee-2/var/var-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 239.3 | `art/raw/referee-2/var/monitor-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 239.4 | `art/raw/referee-2/var/monitor-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 249.1 | `art/raw/var-room/room.jpg` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 249.2 | `art/raw/var-room/room-close.jpg` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 249.3 | `art/raw/var-room/monitor-pitch.jpg` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 249.4 | `art/raw/var-room/monitor-close.jpg` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 253.1 | `art/raw/var/steps-1.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 253.2 | `art/raw/var/steps-2.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 253.3 | `art/raw/var/steps-3.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 253.4 | `art/raw/var/close.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 268.1 | `art/raw/coach-3/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 268.2 | `art/raw/coach-3/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 269.1 | `art/raw/coach-3/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 269.2 | `art/raw/coach-3/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 270.1 | `art/raw/coach-3/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 270.2 | `art/raw/coach-3/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.1 | `art/raw/coach-3/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.2 | `art/raw/coach-3/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.3 | `art/raw/coach-3/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.4 | `art/raw/coach-3/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.5 | `art/raw/coach-3/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 271.6 | `art/raw/coach-3/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.1 | `art/raw/broadcast/big-screen.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.2 | `art/raw/broadcast/scoreboard.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.3 | `art/raw/broadcast/studio.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.4 | `art/raw/broadcast/studio-hosts.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.5 | `art/raw/broadcast/booth.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.6 | `art/raw/broadcast/camera-op.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.7 | `art/raw/broadcast/spider-cam.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.8 | `art/raw/broadcast/control-room.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.9 | `art/raw/broadcast/pitchside-led.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.10 | `art/raw/broadcast/flash-interview.jpg` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 303.11 | `art/raw/broadcast/gear.png` | [`12-broadcast.md`](art/images/12-broadcast.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.1 | `art/raw/balls/winter/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.2 | `art/raw/balls/winter/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.3 | `art/raw/balls/winter/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.4 | `art/raw/balls/winter/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.5 | `art/raw/balls/winter/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 306.6 | `art/raw/balls/winter/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 312.1 | `art/raw/goals/hex/bulge-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 312.2 | `art/raw/goals/hex/bulge-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 312.3 | `art/raw/goals/hex/bulge-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 312.4 | `art/raw/goals/hex/shake-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 312.5 | `art/raw/goals/hex/shake-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 319.1 | `art/raw/goals/hex/views.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 319.2 | `art/raw/goals/hex/hits.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.1 | `art/raw/fx/fire/flare-red-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.2 | `art/raw/fx/fire/flare-red-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.3 | `art/raw/fx/fire/flare-green-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.4 | `art/raw/fx/fire/flare-green-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.5 | `art/raw/fx/fire/smoke-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.6 | `art/raw/fx/fire/smoke-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.7 | `art/raw/fx/fire/firework-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.8 | `art/raw/fx/fire/firework-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 325.9 | `art/raw/fx/fire/firework-03.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 4

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| 🔁 يجب إعادته | سليمان | 4.5 | `art/raw/stadiums/maghreb/night/goal-front.jpg` | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md): لوحات الإعلانات خلف المرمى فيها كتابة وشعارات، والمطلوب بلا أي نص |
| ⬜ لم يتم العمل عليه | سليمان | 54.1 | `art/raw/winger/walk/jog-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.2 | `art/raw/winger/walk/jog-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.3 | `art/raw/winger/walk/jog-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.4 | `art/raw/winger/walk/walk-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.5 | `art/raw/winger/walk/walk-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.6 | `art/raw/winger/walk/walk-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.7 | `art/raw/winger/walk/walk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.8 | `art/raw/winger/walk/walk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.9 | `art/raw/winger/walk/walk-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.10 | `art/raw/winger/walk/walk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.11 | `art/raw/winger/walk/walk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.12 | `art/raw/winger/walk/walk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.13 | `art/raw/winger/walk/backpedal-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 54.14 | `art/raw/winger/walk/backpedal-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.1 | `art/raw/winger/start/start-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.2 | `art/raw/winger/start/start-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.3 | `art/raw/winger/start/stop-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.4 | `art/raw/winger/start/stop-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.5 | `art/raw/winger/start/turn-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.6 | `art/raw/winger/start/turn-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.7 | `art/raw/winger/start/idle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 55.8 | `art/raw/winger/start/idle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.1 | `art/raw/winger/setpiece/pk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.2 | `art/raw/winger/setpiece/pk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.3 | `art/raw/winger/setpiece/pk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.4 | `art/raw/winger/setpiece/pk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.5 | `art/raw/winger/setpiece/pk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.6 | `art/raw/winger/setpiece/freekick-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.7 | `art/raw/winger/setpiece/freekick-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.8 | `art/raw/winger/setpiece/throwin-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.9 | `art/raw/winger/setpiece/throwin-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.10 | `art/raw/winger/setpiece/corner-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 59.11 | `art/raw/winger/setpiece/corner-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 60.1 | `art/raw/midfielder/ref.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 60.2 | `art/raw/midfielder/faces.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.1 | `art/raw/midfielder/run/run-side-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.2 | `art/raw/midfielder/run/run-side-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.3 | `art/raw/midfielder/run/run-side-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.4 | `art/raw/midfielder/run/run-q-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.5 | `art/raw/midfielder/run/run-q-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.6 | `art/raw/midfielder/run/run-q-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.7 | `art/raw/midfielder/run/run-q-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.8 | `art/raw/midfielder/run/run-q-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.9 | `art/raw/midfielder/run/run-q-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.10 | `art/raw/midfielder/run/run-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.11 | `art/raw/midfielder/run/run-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.12 | `art/raw/midfielder/run/run-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.13 | `art/raw/midfielder/run/run-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.14 | `art/raw/midfielder/run/run-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.15 | `art/raw/midfielder/run/run-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.16 | `art/raw/midfielder/run/sprint-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.17 | `art/raw/midfielder/run/sprint-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.18 | `art/raw/midfielder/run/sprint-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 61.19 | `art/raw/midfielder/run/sprint-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.1 | `art/raw/midfielder/ball/dribble-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.2 | `art/raw/midfielder/ball/dribble-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.3 | `art/raw/midfielder/ball/dribble-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.4 | `art/raw/midfielder/ball/shoot-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.5 | `art/raw/midfielder/ball/shoot-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.6 | `art/raw/midfielder/ball/shoot-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.7 | `art/raw/midfielder/ball/pass-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.8 | `art/raw/midfielder/ball/pass-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.9 | `art/raw/midfielder/ball/header-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.10 | `art/raw/midfielder/ball/header-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.11 | `art/raw/midfielder/ball/header-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.12 | `art/raw/midfielder/ball/volley-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.13 | `art/raw/midfielder/ball/volley-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.14 | `art/raw/midfielder/ball/chip-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.15 | `art/raw/midfielder/ball/chip-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.16 | `art/raw/midfielder/ball/cross-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.17 | `art/raw/midfielder/ball/cross-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.18 | `art/raw/midfielder/ball/control-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 64.19 | `art/raw/midfielder/ball/control-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.1 | `art/raw/midfielder/ground/tackle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.2 | `art/raw/midfielder/ground/tackle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.3 | `art/raw/midfielder/ground/tackle-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.4 | `art/raw/midfielder/ground/tackle-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.5 | `art/raw/midfielder/ground/fall-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.6 | `art/raw/midfielder/ground/fall-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.7 | `art/raw/midfielder/ground/fall-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.8 | `art/raw/midfielder/ground/fall-04.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.9 | `art/raw/midfielder/ground/block-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.10 | `art/raw/midfielder/ground/block-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.11 | `art/raw/midfielder/ground/block-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.12 | `art/raw/midfielder/ground/getup-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.13 | `art/raw/midfielder/ground/getup-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.14 | `art/raw/midfielder/ground/hurt-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 65.15 | `art/raw/midfielder/ground/hurt-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.1 | `art/raw/midfielder/emotion/celebrate-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.2 | `art/raw/midfielder/emotion/celebrate-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.3 | `art/raw/midfielder/emotion/celebrate-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.4 | `art/raw/midfielder/emotion/sad-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.5 | `art/raw/midfielder/emotion/sad-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.6 | `art/raw/midfielder/emotion/knee-slide-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.7 | `art/raw/midfielder/emotion/knee-slide-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.8 | `art/raw/midfielder/emotion/knee-slide-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.9 | `art/raw/midfielder/emotion/jump-cel-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.10 | `art/raw/midfielder/emotion/jump-cel-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.11 | `art/raw/midfielder/emotion/argue-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 66.12 | `art/raw/midfielder/emotion/argue-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 114.1 | `art/raw/players/look-7/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 114.2 | `art/raw/players/look-7/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.1 | `art/raw/players/look-7/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.2 | `art/raw/players/look-7/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.3 | `art/raw/players/look-7/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.4 | `art/raw/players/look-7/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.5 | `art/raw/players/look-7/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.6 | `art/raw/players/look-7/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 115.7 | `art/raw/players/look-7/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.1 | `art/raw/players/look-7/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.2 | `art/raw/players/look-7/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.3 | `art/raw/players/look-7/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.4 | `art/raw/players/look-7/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.5 | `art/raw/players/look-7/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 116.6 | `art/raw/players/look-7/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.1 | `art/raw/players/look-7/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.2 | `art/raw/players/look-7/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.3 | `art/raw/players/look-7/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.4 | `art/raw/players/look-7/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.5 | `art/raw/players/look-7/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.6 | `art/raw/players/look-7/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.7 | `art/raw/players/look-7/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.8 | `art/raw/players/look-7/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.9 | `art/raw/players/look-7/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.10 | `art/raw/players/look-7/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 117.11 | `art/raw/players/look-7/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.1 | `art/raw/players/look-7/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.2 | `art/raw/players/look-7/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.3 | `art/raw/players/look-7/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.4 | `art/raw/players/look-7/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.5 | `art/raw/players/look-7/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.6 | `art/raw/players/look-7/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.7 | `art/raw/players/look-7/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 118.8 | `art/raw/players/look-7/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 119.1 | `art/raw/players/look-7/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 119.2 | `art/raw/players/look-7/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 119.3 | `art/raw/players/look-7/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 119.4 | `art/raw/players/look-7/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 119.5 | `art/raw/players/look-7/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 120.1 | `art/raw/players/look-8/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 120.2 | `art/raw/players/look-8/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.1 | `art/raw/players/look-8/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.2 | `art/raw/players/look-8/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.3 | `art/raw/players/look-8/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.4 | `art/raw/players/look-8/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.5 | `art/raw/players/look-8/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.6 | `art/raw/players/look-8/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 121.7 | `art/raw/players/look-8/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.1 | `art/raw/players/look-8/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.2 | `art/raw/players/look-8/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.3 | `art/raw/players/look-8/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.4 | `art/raw/players/look-8/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.5 | `art/raw/players/look-8/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 122.6 | `art/raw/players/look-8/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.1 | `art/raw/players/look-8/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.2 | `art/raw/players/look-8/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.3 | `art/raw/players/look-8/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.4 | `art/raw/players/look-8/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.5 | `art/raw/players/look-8/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.6 | `art/raw/players/look-8/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.7 | `art/raw/players/look-8/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.8 | `art/raw/players/look-8/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.9 | `art/raw/players/look-8/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.10 | `art/raw/players/look-8/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 123.11 | `art/raw/players/look-8/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.1 | `art/raw/players/look-8/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.2 | `art/raw/players/look-8/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.3 | `art/raw/players/look-8/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.4 | `art/raw/players/look-8/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.5 | `art/raw/players/look-8/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.6 | `art/raw/players/look-8/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.7 | `art/raw/players/look-8/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 124.8 | `art/raw/players/look-8/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 125.1 | `art/raw/players/look-8/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 125.2 | `art/raw/players/look-8/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 125.3 | `art/raw/players/look-8/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 125.4 | `art/raw/players/look-8/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 125.5 | `art/raw/players/look-8/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 126.1 | `art/raw/players/look-9/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 126.2 | `art/raw/players/look-9/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.1 | `art/raw/players/look-9/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.2 | `art/raw/players/look-9/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.3 | `art/raw/players/look-9/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.4 | `art/raw/players/look-9/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.5 | `art/raw/players/look-9/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.6 | `art/raw/players/look-9/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 127.7 | `art/raw/players/look-9/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.1 | `art/raw/players/look-9/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.2 | `art/raw/players/look-9/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.3 | `art/raw/players/look-9/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.4 | `art/raw/players/look-9/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.5 | `art/raw/players/look-9/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 128.6 | `art/raw/players/look-9/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.1 | `art/raw/players/look-9/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.2 | `art/raw/players/look-9/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.3 | `art/raw/players/look-9/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.4 | `art/raw/players/look-9/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.5 | `art/raw/players/look-9/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.6 | `art/raw/players/look-9/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.7 | `art/raw/players/look-9/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.8 | `art/raw/players/look-9/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.9 | `art/raw/players/look-9/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.10 | `art/raw/players/look-9/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 129.11 | `art/raw/players/look-9/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.1 | `art/raw/players/look-9/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.2 | `art/raw/players/look-9/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.3 | `art/raw/players/look-9/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.4 | `art/raw/players/look-9/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.5 | `art/raw/players/look-9/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.6 | `art/raw/players/look-9/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.7 | `art/raw/players/look-9/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 130.8 | `art/raw/players/look-9/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 131.1 | `art/raw/players/look-9/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 131.2 | `art/raw/players/look-9/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 131.3 | `art/raw/players/look-9/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 131.4 | `art/raw/players/look-9/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 131.5 | `art/raw/players/look-9/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 214.1 | `art/raw/keeper-3/ref.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 214.2 | `art/raw/keeper-3/faces.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 215.1 | `art/raw/keeper-3/ready/ready-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 215.2 | `art/raw/keeper-3/ready/ready-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 215.3 | `art/raw/keeper-3/ready/shuffle-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 215.4 | `art/raw/keeper-3/ready/shuffle-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.1 | `art/raw/keeper-3/dive/dive-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.2 | `art/raw/keeper-3/dive/dive-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.3 | `art/raw/keeper-3/dive/dive-high-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.4 | `art/raw/keeper-3/dive/dive-high-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.5 | `art/raw/keeper-3/dive/dive-high-05.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.6 | `art/raw/keeper-3/dive/dive-low-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.7 | `art/raw/keeper-3/dive/dive-low-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.8 | `art/raw/keeper-3/dive/dive-low-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.9 | `art/raw/keeper-3/dive/beaten-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 216.10 | `art/raw/keeper-3/dive/beaten-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.1 | `art/raw/keeper-3/hands/catch-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.2 | `art/raw/keeper-3/hands/catch-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.3 | `art/raw/keeper-3/hands/catch-chest-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.4 | `art/raw/keeper-3/hands/catch-chest-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.5 | `art/raw/keeper-3/hands/punch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.6 | `art/raw/keeper-3/hands/punch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.7 | `art/raw/keeper-3/hands/tip-over-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.8 | `art/raw/keeper-3/hands/tip-over-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.9 | `art/raw/keeper-3/hands/tip-over-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.10 | `art/raw/keeper-3/hands/save-land-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 217.11 | `art/raw/keeper-3/hands/save-land-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 218.1 | `art/raw/keeper-3/ground/getup-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 218.2 | `art/raw/keeper-3/ground/getup-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 219.1 | `art/raw/keeper-3/distribute/kick-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 219.2 | `art/raw/keeper-3/distribute/kick-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 219.3 | `art/raw/keeper-3/distribute/kick-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 219.4 | `art/raw/keeper-3/distribute/throw-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 219.5 | `art/raw/keeper-3/distribute/throw-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 220.1 | `art/raw/keeper-3/emotion/celebrate-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 220.2 | `art/raw/keeper-3/emotion/celebrate-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.1 | `art/raw/keeper-3/penalty/front-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.2 | `art/raw/keeper-3/penalty/front-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.3 | `art/raw/keeper-3/penalty/front-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.4 | `art/raw/keeper-3/penalty/front-dive-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.5 | `art/raw/keeper-3/penalty/front-catch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.6 | `art/raw/keeper-3/penalty/front-catch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.7 | `art/raw/keeper-3/penalty/back-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.8 | `art/raw/keeper-3/penalty/back-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 221.9 | `art/raw/keeper-3/penalty/back-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 240.1 | `art/raw/referee-3/ref.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 240.2 | `art/raw/referee-3/faces.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.1 | `art/raw/referee-3/run/run-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.2 | `art/raw/referee-3/run/run-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.3 | `art/raw/referee-3/run/run-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.4 | `art/raw/referee-3/run/run-back-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.5 | `art/raw/referee-3/run/run-back-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 241.6 | `art/raw/referee-3/run/run-back-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 242.1 | `art/raw/referee-3/walk/walk-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 242.2 | `art/raw/referee-3/walk/walk-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 242.3 | `art/raw/referee-3/walk/walk-03.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.1 | `art/raw/referee-3/signals/whistle-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.2 | `art/raw/referee-3/signals/whistle-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.3 | `art/raw/referee-3/signals/card-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.4 | `art/raw/referee-3/signals/card-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.5 | `art/raw/referee-3/signals/point-spot-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.6 | `art/raw/referee-3/signals/point-spot-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.7 | `art/raw/referee-3/signals/advantage-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 243.8 | `art/raw/referee-3/signals/advantage-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 244.1 | `art/raw/referee-3/var/var-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 244.2 | `art/raw/referee-3/var/var-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 244.3 | `art/raw/referee-3/var/monitor-01.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 244.4 | `art/raw/referee-3/var/monitor-02.png` | [`06-officials.md`](art/images/06-officials.md) |
| ⬜ لم يتم العمل عليه | سليمان | 254.1 | `art/raw/scuffle/scuffle-a.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 254.2 | `art/raw/scuffle/scuffle-b.png` | [`07-situations.md`](art/images/07-situations.md) |
| ⬜ لم يتم العمل عليه | سليمان | 258.1 | `art/raw/trophy/lift.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 258.2 | `art/raw/trophy/moments.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 259.1 | `art/raw/shootout/line.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 259.2 | `art/raw/shootout/walk.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ لم يتم العمل عليه | سليمان | 272.1 | `art/raw/coach-4/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 272.2 | `art/raw/coach-4/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 273.1 | `art/raw/coach-4/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 273.2 | `art/raw/coach-4/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 274.1 | `art/raw/coach-4/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 274.2 | `art/raw/coach-4/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.1 | `art/raw/coach-4/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.2 | `art/raw/coach-4/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.3 | `art/raw/coach-4/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.4 | `art/raw/coach-4/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.5 | `art/raw/coach-4/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 275.6 | `art/raw/coach-4/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.1 | `art/raw/balls/final/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.2 | `art/raw/balls/final/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.3 | `art/raw/balls/final/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.4 | `art/raw/balls/final/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.5 | `art/raw/balls/final/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 307.6 | `art/raw/balls/final/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 313.1 | `art/raw/goals/black-net/bulge-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 313.2 | `art/raw/goals/black-net/bulge-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 313.3 | `art/raw/goals/black-net/bulge-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 313.4 | `art/raw/goals/black-net/shake-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 313.5 | `art/raw/goals/black-net/shake-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 320.1 | `art/raw/goals/black-net/views.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 320.2 | `art/raw/goals/black-net/hits.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.1 | `art/raw/fx/light/flashes-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.2 | `art/raw/fx/light/flashes-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.3 | `art/raw/fx/light/flare-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.4 | `art/raw/fx/light/flare-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.5 | `art/raw/fx/light/spark-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 326.6 | `art/raw/fx/light/spark-02.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 5

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| 🔁 يجب إعادته | سليمان | 5.3 | `art/raw/stadiums/coast/dusk/wing.jpg` | [`2026-10-22-stadiums.md`](art/redo/2026-10-22-stadiums.md): نسخة من لوحة التسديدة (المرمى كبير في الوسط)، والمطلوب منظر خط التماس والمرمى صغير بعيد |
| ⬜ لم يتم العمل عليه | سليمان | 62.1 | `art/raw/midfielder/walk/jog-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.2 | `art/raw/midfielder/walk/jog-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.3 | `art/raw/midfielder/walk/jog-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.4 | `art/raw/midfielder/walk/walk-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.5 | `art/raw/midfielder/walk/walk-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.6 | `art/raw/midfielder/walk/walk-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.7 | `art/raw/midfielder/walk/walk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.8 | `art/raw/midfielder/walk/walk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.9 | `art/raw/midfielder/walk/walk-front-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.10 | `art/raw/midfielder/walk/walk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.11 | `art/raw/midfielder/walk/walk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.12 | `art/raw/midfielder/walk/walk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.13 | `art/raw/midfielder/walk/backpedal-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 62.14 | `art/raw/midfielder/walk/backpedal-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.1 | `art/raw/midfielder/start/start-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.2 | `art/raw/midfielder/start/start-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.3 | `art/raw/midfielder/start/stop-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.4 | `art/raw/midfielder/start/stop-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.5 | `art/raw/midfielder/start/turn-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.6 | `art/raw/midfielder/start/turn-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.7 | `art/raw/midfielder/start/idle-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 63.8 | `art/raw/midfielder/start/idle-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.1 | `art/raw/midfielder/setpiece/pk-back-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.2 | `art/raw/midfielder/setpiece/pk-back-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.3 | `art/raw/midfielder/setpiece/pk-back-03.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.4 | `art/raw/midfielder/setpiece/pk-front-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.5 | `art/raw/midfielder/setpiece/pk-front-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.6 | `art/raw/midfielder/setpiece/freekick-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.7 | `art/raw/midfielder/setpiece/freekick-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.8 | `art/raw/midfielder/setpiece/throwin-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.9 | `art/raw/midfielder/setpiece/throwin-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.10 | `art/raw/midfielder/setpiece/corner-01.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 67.11 | `art/raw/midfielder/setpiece/corner-02.png` | [`03-players.md`](art/images/03-players.md) |
| ⬜ لم يتم العمل عليه | سليمان | 132.1 | `art/raw/players/look-10/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 132.2 | `art/raw/players/look-10/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.1 | `art/raw/players/look-10/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.2 | `art/raw/players/look-10/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.3 | `art/raw/players/look-10/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.4 | `art/raw/players/look-10/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.5 | `art/raw/players/look-10/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.6 | `art/raw/players/look-10/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 133.7 | `art/raw/players/look-10/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.1 | `art/raw/players/look-10/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.2 | `art/raw/players/look-10/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.3 | `art/raw/players/look-10/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.4 | `art/raw/players/look-10/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.5 | `art/raw/players/look-10/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 134.6 | `art/raw/players/look-10/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.1 | `art/raw/players/look-10/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.2 | `art/raw/players/look-10/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.3 | `art/raw/players/look-10/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.4 | `art/raw/players/look-10/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.5 | `art/raw/players/look-10/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.6 | `art/raw/players/look-10/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.7 | `art/raw/players/look-10/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.8 | `art/raw/players/look-10/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.9 | `art/raw/players/look-10/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.10 | `art/raw/players/look-10/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 135.11 | `art/raw/players/look-10/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.1 | `art/raw/players/look-10/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.2 | `art/raw/players/look-10/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.3 | `art/raw/players/look-10/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.4 | `art/raw/players/look-10/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.5 | `art/raw/players/look-10/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.6 | `art/raw/players/look-10/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.7 | `art/raw/players/look-10/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 136.8 | `art/raw/players/look-10/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 137.1 | `art/raw/players/look-10/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 137.2 | `art/raw/players/look-10/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 137.3 | `art/raw/players/look-10/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 137.4 | `art/raw/players/look-10/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 137.5 | `art/raw/players/look-10/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 138.1 | `art/raw/players/look-11/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 138.2 | `art/raw/players/look-11/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.1 | `art/raw/players/look-11/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.2 | `art/raw/players/look-11/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.3 | `art/raw/players/look-11/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.4 | `art/raw/players/look-11/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.5 | `art/raw/players/look-11/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.6 | `art/raw/players/look-11/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 139.7 | `art/raw/players/look-11/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.1 | `art/raw/players/look-11/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.2 | `art/raw/players/look-11/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.3 | `art/raw/players/look-11/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.4 | `art/raw/players/look-11/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.5 | `art/raw/players/look-11/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 140.6 | `art/raw/players/look-11/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.1 | `art/raw/players/look-11/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.2 | `art/raw/players/look-11/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.3 | `art/raw/players/look-11/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.4 | `art/raw/players/look-11/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.5 | `art/raw/players/look-11/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.6 | `art/raw/players/look-11/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.7 | `art/raw/players/look-11/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.8 | `art/raw/players/look-11/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.9 | `art/raw/players/look-11/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.10 | `art/raw/players/look-11/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 141.11 | `art/raw/players/look-11/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.1 | `art/raw/players/look-11/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.2 | `art/raw/players/look-11/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.3 | `art/raw/players/look-11/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.4 | `art/raw/players/look-11/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.5 | `art/raw/players/look-11/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.6 | `art/raw/players/look-11/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.7 | `art/raw/players/look-11/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 142.8 | `art/raw/players/look-11/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 143.1 | `art/raw/players/look-11/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 143.2 | `art/raw/players/look-11/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 143.3 | `art/raw/players/look-11/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 143.4 | `art/raw/players/look-11/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 143.5 | `art/raw/players/look-11/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 144.1 | `art/raw/players/look-12/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 144.2 | `art/raw/players/look-12/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.1 | `art/raw/players/look-12/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.2 | `art/raw/players/look-12/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.3 | `art/raw/players/look-12/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.4 | `art/raw/players/look-12/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.5 | `art/raw/players/look-12/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.6 | `art/raw/players/look-12/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 145.7 | `art/raw/players/look-12/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.1 | `art/raw/players/look-12/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.2 | `art/raw/players/look-12/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.3 | `art/raw/players/look-12/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.4 | `art/raw/players/look-12/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.5 | `art/raw/players/look-12/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 146.6 | `art/raw/players/look-12/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.1 | `art/raw/players/look-12/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.2 | `art/raw/players/look-12/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.3 | `art/raw/players/look-12/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.4 | `art/raw/players/look-12/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.5 | `art/raw/players/look-12/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.6 | `art/raw/players/look-12/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.7 | `art/raw/players/look-12/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.8 | `art/raw/players/look-12/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.9 | `art/raw/players/look-12/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.10 | `art/raw/players/look-12/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 147.11 | `art/raw/players/look-12/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.1 | `art/raw/players/look-12/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.2 | `art/raw/players/look-12/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.3 | `art/raw/players/look-12/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.4 | `art/raw/players/look-12/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.5 | `art/raw/players/look-12/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.6 | `art/raw/players/look-12/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.7 | `art/raw/players/look-12/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 148.8 | `art/raw/players/look-12/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 149.1 | `art/raw/players/look-12/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 149.2 | `art/raw/players/look-12/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 149.3 | `art/raw/players/look-12/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 149.4 | `art/raw/players/look-12/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 149.5 | `art/raw/players/look-12/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 222.1 | `art/raw/keeper-4/ref.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 222.2 | `art/raw/keeper-4/faces.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 223.1 | `art/raw/keeper-4/ready/ready-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 223.2 | `art/raw/keeper-4/ready/ready-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 223.3 | `art/raw/keeper-4/ready/shuffle-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 223.4 | `art/raw/keeper-4/ready/shuffle-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.1 | `art/raw/keeper-4/dive/dive-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.2 | `art/raw/keeper-4/dive/dive-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.3 | `art/raw/keeper-4/dive/dive-high-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.4 | `art/raw/keeper-4/dive/dive-high-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.5 | `art/raw/keeper-4/dive/dive-high-05.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.6 | `art/raw/keeper-4/dive/dive-low-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.7 | `art/raw/keeper-4/dive/dive-low-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.8 | `art/raw/keeper-4/dive/dive-low-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.9 | `art/raw/keeper-4/dive/beaten-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 224.10 | `art/raw/keeper-4/dive/beaten-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.1 | `art/raw/keeper-4/hands/catch-high-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.2 | `art/raw/keeper-4/hands/catch-high-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.3 | `art/raw/keeper-4/hands/catch-chest-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.4 | `art/raw/keeper-4/hands/catch-chest-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.5 | `art/raw/keeper-4/hands/punch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.6 | `art/raw/keeper-4/hands/punch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.7 | `art/raw/keeper-4/hands/tip-over-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.8 | `art/raw/keeper-4/hands/tip-over-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.9 | `art/raw/keeper-4/hands/tip-over-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.10 | `art/raw/keeper-4/hands/save-land-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 225.11 | `art/raw/keeper-4/hands/save-land-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 226.1 | `art/raw/keeper-4/ground/getup-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 226.2 | `art/raw/keeper-4/ground/getup-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 227.1 | `art/raw/keeper-4/distribute/kick-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 227.2 | `art/raw/keeper-4/distribute/kick-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 227.3 | `art/raw/keeper-4/distribute/kick-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 227.4 | `art/raw/keeper-4/distribute/throw-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 227.5 | `art/raw/keeper-4/distribute/throw-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 228.1 | `art/raw/keeper-4/emotion/celebrate-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 228.2 | `art/raw/keeper-4/emotion/celebrate-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.1 | `art/raw/keeper-4/penalty/front-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.2 | `art/raw/keeper-4/penalty/front-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.3 | `art/raw/keeper-4/penalty/front-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.4 | `art/raw/keeper-4/penalty/front-dive-04.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.5 | `art/raw/keeper-4/penalty/front-catch-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.6 | `art/raw/keeper-4/penalty/front-catch-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.7 | `art/raw/keeper-4/penalty/back-dive-01.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.8 | `art/raw/keeper-4/penalty/back-dive-02.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 229.9 | `art/raw/keeper-4/penalty/back-dive-03.png` | [`05-keepers.md`](art/images/05-keepers.md) |
| ⬜ لم يتم العمل عليه | سليمان | 276.1 | `art/raw/coach-5/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 276.2 | `art/raw/coach-5/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 277.1 | `art/raw/coach-5/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 277.2 | `art/raw/coach-5/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 278.1 | `art/raw/coach-5/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 278.2 | `art/raw/coach-5/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.1 | `art/raw/coach-5/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.2 | `art/raw/coach-5/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.3 | `art/raw/coach-5/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.4 | `art/raw/coach-5/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.5 | `art/raw/coach-5/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 279.6 | `art/raw/coach-5/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.1 | `art/raw/balls/retro/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.2 | `art/raw/balls/retro/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.3 | `art/raw/balls/retro/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.4 | `art/raw/balls/retro/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.5 | `art/raw/balls/retro/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 308.6 | `art/raw/balls/retro/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 314.1 | `art/raw/goals/training/bulge-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 314.2 | `art/raw/goals/training/bulge-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 314.3 | `art/raw/goals/training/bulge-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 314.4 | `art/raw/goals/training/shake-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 314.5 | `art/raw/goals/training/shake-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 321.1 | `art/raw/goals/training/views.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 321.2 | `art/raw/goals/training/hits.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 327.1 | `art/raw/fx/party/confetti-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 327.2 | `art/raw/fx/party/confetti-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 327.3 | `art/raw/fx/party/streamers-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 327.4 | `art/raw/fx/party/streamers-02.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 6

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 150.1 | `art/raw/players/look-13/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 150.2 | `art/raw/players/look-13/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.1 | `art/raw/players/look-13/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.2 | `art/raw/players/look-13/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.3 | `art/raw/players/look-13/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.4 | `art/raw/players/look-13/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.5 | `art/raw/players/look-13/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.6 | `art/raw/players/look-13/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 151.7 | `art/raw/players/look-13/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.1 | `art/raw/players/look-13/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.2 | `art/raw/players/look-13/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.3 | `art/raw/players/look-13/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.4 | `art/raw/players/look-13/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.5 | `art/raw/players/look-13/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 152.6 | `art/raw/players/look-13/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.1 | `art/raw/players/look-13/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.2 | `art/raw/players/look-13/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.3 | `art/raw/players/look-13/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.4 | `art/raw/players/look-13/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.5 | `art/raw/players/look-13/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.6 | `art/raw/players/look-13/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.7 | `art/raw/players/look-13/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.8 | `art/raw/players/look-13/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.9 | `art/raw/players/look-13/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.10 | `art/raw/players/look-13/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 153.11 | `art/raw/players/look-13/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.1 | `art/raw/players/look-13/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.2 | `art/raw/players/look-13/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.3 | `art/raw/players/look-13/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.4 | `art/raw/players/look-13/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.5 | `art/raw/players/look-13/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.6 | `art/raw/players/look-13/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.7 | `art/raw/players/look-13/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 154.8 | `art/raw/players/look-13/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 155.1 | `art/raw/players/look-13/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 155.2 | `art/raw/players/look-13/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 155.3 | `art/raw/players/look-13/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 155.4 | `art/raw/players/look-13/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 155.5 | `art/raw/players/look-13/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 156.1 | `art/raw/players/look-14/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 156.2 | `art/raw/players/look-14/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.1 | `art/raw/players/look-14/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.2 | `art/raw/players/look-14/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.3 | `art/raw/players/look-14/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.4 | `art/raw/players/look-14/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.5 | `art/raw/players/look-14/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.6 | `art/raw/players/look-14/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 157.7 | `art/raw/players/look-14/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.1 | `art/raw/players/look-14/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.2 | `art/raw/players/look-14/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.3 | `art/raw/players/look-14/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.4 | `art/raw/players/look-14/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.5 | `art/raw/players/look-14/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 158.6 | `art/raw/players/look-14/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.1 | `art/raw/players/look-14/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.2 | `art/raw/players/look-14/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.3 | `art/raw/players/look-14/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.4 | `art/raw/players/look-14/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.5 | `art/raw/players/look-14/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.6 | `art/raw/players/look-14/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.7 | `art/raw/players/look-14/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.8 | `art/raw/players/look-14/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.9 | `art/raw/players/look-14/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.10 | `art/raw/players/look-14/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 159.11 | `art/raw/players/look-14/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.1 | `art/raw/players/look-14/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.2 | `art/raw/players/look-14/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.3 | `art/raw/players/look-14/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.4 | `art/raw/players/look-14/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.5 | `art/raw/players/look-14/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.6 | `art/raw/players/look-14/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.7 | `art/raw/players/look-14/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 160.8 | `art/raw/players/look-14/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 161.1 | `art/raw/players/look-14/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 161.2 | `art/raw/players/look-14/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 161.3 | `art/raw/players/look-14/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 161.4 | `art/raw/players/look-14/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 161.5 | `art/raw/players/look-14/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 162.1 | `art/raw/players/look-15/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 162.2 | `art/raw/players/look-15/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.1 | `art/raw/players/look-15/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.2 | `art/raw/players/look-15/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.3 | `art/raw/players/look-15/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.4 | `art/raw/players/look-15/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.5 | `art/raw/players/look-15/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.6 | `art/raw/players/look-15/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 163.7 | `art/raw/players/look-15/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.1 | `art/raw/players/look-15/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.2 | `art/raw/players/look-15/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.3 | `art/raw/players/look-15/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.4 | `art/raw/players/look-15/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.5 | `art/raw/players/look-15/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 164.6 | `art/raw/players/look-15/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.1 | `art/raw/players/look-15/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.2 | `art/raw/players/look-15/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.3 | `art/raw/players/look-15/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.4 | `art/raw/players/look-15/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.5 | `art/raw/players/look-15/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.6 | `art/raw/players/look-15/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.7 | `art/raw/players/look-15/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.8 | `art/raw/players/look-15/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.9 | `art/raw/players/look-15/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.10 | `art/raw/players/look-15/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 165.11 | `art/raw/players/look-15/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.1 | `art/raw/players/look-15/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.2 | `art/raw/players/look-15/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.3 | `art/raw/players/look-15/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.4 | `art/raw/players/look-15/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.5 | `art/raw/players/look-15/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.6 | `art/raw/players/look-15/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.7 | `art/raw/players/look-15/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 166.8 | `art/raw/players/look-15/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 167.1 | `art/raw/players/look-15/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 167.2 | `art/raw/players/look-15/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 167.3 | `art/raw/players/look-15/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 167.4 | `art/raw/players/look-15/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 167.5 | `art/raw/players/look-15/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 280.1 | `art/raw/coach-6/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 280.2 | `art/raw/coach-6/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 281.1 | `art/raw/coach-6/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 281.2 | `art/raw/coach-6/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 282.1 | `art/raw/coach-6/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 282.2 | `art/raw/coach-6/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.1 | `art/raw/coach-6/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.2 | `art/raw/coach-6/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.3 | `art/raw/coach-6/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.4 | `art/raw/coach-6/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.5 | `art/raw/coach-6/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 283.6 | `art/raw/coach-6/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.1 | `art/raw/balls/futsal/spin-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.2 | `art/raw/balls/futsal/spin-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.3 | `art/raw/balls/futsal/spin-03.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.4 | `art/raw/balls/futsal/spin-04.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.5 | `art/raw/balls/futsal/kick-01.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 309.6 | `art/raw/balls/futsal/kick-02.png` | [`13-kit.md`](art/images/13-kit.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.1 | `art/raw/fx/crowd/jump-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.2 | `art/raw/fx/crowd/jump-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.3 | `art/raw/fx/crowd/scarves-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.4 | `art/raw/fx/crowd/scarves-02.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.5 | `art/raw/fx/crowd/clap-01.png` | [`14-fx.md`](art/images/14-fx.md) |
| ⬜ لم يتم العمل عليه | سليمان | 328.6 | `art/raw/fx/crowd/clap-02.png` | [`14-fx.md`](art/images/14-fx.md) |

#### الدفعة 7

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 168.1 | `art/raw/players/look-16/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 168.2 | `art/raw/players/look-16/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.1 | `art/raw/players/look-16/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.2 | `art/raw/players/look-16/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.3 | `art/raw/players/look-16/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.4 | `art/raw/players/look-16/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.5 | `art/raw/players/look-16/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.6 | `art/raw/players/look-16/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 169.7 | `art/raw/players/look-16/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.1 | `art/raw/players/look-16/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.2 | `art/raw/players/look-16/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.3 | `art/raw/players/look-16/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.4 | `art/raw/players/look-16/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.5 | `art/raw/players/look-16/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 170.6 | `art/raw/players/look-16/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.1 | `art/raw/players/look-16/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.2 | `art/raw/players/look-16/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.3 | `art/raw/players/look-16/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.4 | `art/raw/players/look-16/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.5 | `art/raw/players/look-16/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.6 | `art/raw/players/look-16/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.7 | `art/raw/players/look-16/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.8 | `art/raw/players/look-16/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.9 | `art/raw/players/look-16/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.10 | `art/raw/players/look-16/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 171.11 | `art/raw/players/look-16/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.1 | `art/raw/players/look-16/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.2 | `art/raw/players/look-16/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.3 | `art/raw/players/look-16/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.4 | `art/raw/players/look-16/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.5 | `art/raw/players/look-16/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.6 | `art/raw/players/look-16/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.7 | `art/raw/players/look-16/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 172.8 | `art/raw/players/look-16/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 173.1 | `art/raw/players/look-16/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 173.2 | `art/raw/players/look-16/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 173.3 | `art/raw/players/look-16/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 173.4 | `art/raw/players/look-16/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 173.5 | `art/raw/players/look-16/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 174.1 | `art/raw/players/look-17/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 174.2 | `art/raw/players/look-17/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.1 | `art/raw/players/look-17/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.2 | `art/raw/players/look-17/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.3 | `art/raw/players/look-17/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.4 | `art/raw/players/look-17/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.5 | `art/raw/players/look-17/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.6 | `art/raw/players/look-17/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 175.7 | `art/raw/players/look-17/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.1 | `art/raw/players/look-17/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.2 | `art/raw/players/look-17/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.3 | `art/raw/players/look-17/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.4 | `art/raw/players/look-17/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.5 | `art/raw/players/look-17/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 176.6 | `art/raw/players/look-17/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.1 | `art/raw/players/look-17/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.2 | `art/raw/players/look-17/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.3 | `art/raw/players/look-17/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.4 | `art/raw/players/look-17/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.5 | `art/raw/players/look-17/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.6 | `art/raw/players/look-17/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.7 | `art/raw/players/look-17/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.8 | `art/raw/players/look-17/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.9 | `art/raw/players/look-17/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.10 | `art/raw/players/look-17/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 177.11 | `art/raw/players/look-17/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.1 | `art/raw/players/look-17/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.2 | `art/raw/players/look-17/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.3 | `art/raw/players/look-17/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.4 | `art/raw/players/look-17/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.5 | `art/raw/players/look-17/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.6 | `art/raw/players/look-17/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.7 | `art/raw/players/look-17/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 178.8 | `art/raw/players/look-17/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 179.1 | `art/raw/players/look-17/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 179.2 | `art/raw/players/look-17/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 179.3 | `art/raw/players/look-17/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 179.4 | `art/raw/players/look-17/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 179.5 | `art/raw/players/look-17/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 180.1 | `art/raw/players/look-18/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 180.2 | `art/raw/players/look-18/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.1 | `art/raw/players/look-18/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.2 | `art/raw/players/look-18/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.3 | `art/raw/players/look-18/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.4 | `art/raw/players/look-18/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.5 | `art/raw/players/look-18/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.6 | `art/raw/players/look-18/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 181.7 | `art/raw/players/look-18/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.1 | `art/raw/players/look-18/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.2 | `art/raw/players/look-18/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.3 | `art/raw/players/look-18/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.4 | `art/raw/players/look-18/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.5 | `art/raw/players/look-18/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 182.6 | `art/raw/players/look-18/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.1 | `art/raw/players/look-18/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.2 | `art/raw/players/look-18/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.3 | `art/raw/players/look-18/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.4 | `art/raw/players/look-18/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.5 | `art/raw/players/look-18/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.6 | `art/raw/players/look-18/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.7 | `art/raw/players/look-18/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.8 | `art/raw/players/look-18/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.9 | `art/raw/players/look-18/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.10 | `art/raw/players/look-18/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 183.11 | `art/raw/players/look-18/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.1 | `art/raw/players/look-18/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.2 | `art/raw/players/look-18/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.3 | `art/raw/players/look-18/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.4 | `art/raw/players/look-18/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.5 | `art/raw/players/look-18/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.6 | `art/raw/players/look-18/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.7 | `art/raw/players/look-18/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 184.8 | `art/raw/players/look-18/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 185.1 | `art/raw/players/look-18/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 185.2 | `art/raw/players/look-18/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 185.3 | `art/raw/players/look-18/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 185.4 | `art/raw/players/look-18/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 185.5 | `art/raw/players/look-18/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 284.1 | `art/raw/coach-7/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 284.2 | `art/raw/coach-7/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 285.1 | `art/raw/coach-7/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 285.2 | `art/raw/coach-7/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 286.1 | `art/raw/coach-7/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 286.2 | `art/raw/coach-7/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.1 | `art/raw/coach-7/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.2 | `art/raw/coach-7/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.3 | `art/raw/coach-7/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.4 | `art/raw/coach-7/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.5 | `art/raw/coach-7/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 287.6 | `art/raw/coach-7/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### الدفعة 8

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 186.1 | `art/raw/players/look-19/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 186.2 | `art/raw/players/look-19/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.1 | `art/raw/players/look-19/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.2 | `art/raw/players/look-19/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.3 | `art/raw/players/look-19/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.4 | `art/raw/players/look-19/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.5 | `art/raw/players/look-19/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.6 | `art/raw/players/look-19/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 187.7 | `art/raw/players/look-19/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.1 | `art/raw/players/look-19/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.2 | `art/raw/players/look-19/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.3 | `art/raw/players/look-19/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.4 | `art/raw/players/look-19/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.5 | `art/raw/players/look-19/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 188.6 | `art/raw/players/look-19/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.1 | `art/raw/players/look-19/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.2 | `art/raw/players/look-19/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.3 | `art/raw/players/look-19/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.4 | `art/raw/players/look-19/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.5 | `art/raw/players/look-19/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.6 | `art/raw/players/look-19/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.7 | `art/raw/players/look-19/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.8 | `art/raw/players/look-19/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.9 | `art/raw/players/look-19/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.10 | `art/raw/players/look-19/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 189.11 | `art/raw/players/look-19/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.1 | `art/raw/players/look-19/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.2 | `art/raw/players/look-19/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.3 | `art/raw/players/look-19/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.4 | `art/raw/players/look-19/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.5 | `art/raw/players/look-19/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.6 | `art/raw/players/look-19/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.7 | `art/raw/players/look-19/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 190.8 | `art/raw/players/look-19/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 191.1 | `art/raw/players/look-19/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 191.2 | `art/raw/players/look-19/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 191.3 | `art/raw/players/look-19/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 191.4 | `art/raw/players/look-19/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 191.5 | `art/raw/players/look-19/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 192.1 | `art/raw/players/look-20/ref.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 192.2 | `art/raw/players/look-20/faces.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.1 | `art/raw/players/look-20/run/run-side-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.2 | `art/raw/players/look-20/run/run-side-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.3 | `art/raw/players/look-20/run/run-side-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.4 | `art/raw/players/look-20/run/sprint-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.5 | `art/raw/players/look-20/run/sprint-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.6 | `art/raw/players/look-20/run/sprint-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 193.7 | `art/raw/players/look-20/run/sprint-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.1 | `art/raw/players/look-20/walk/jog-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.2 | `art/raw/players/look-20/walk/jog-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.3 | `art/raw/players/look-20/walk/jog-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.4 | `art/raw/players/look-20/walk/walk-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.5 | `art/raw/players/look-20/walk/walk-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 194.6 | `art/raw/players/look-20/walk/walk-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.1 | `art/raw/players/look-20/ball/dribble-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.2 | `art/raw/players/look-20/ball/dribble-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.3 | `art/raw/players/look-20/ball/dribble-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.4 | `art/raw/players/look-20/ball/shoot-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.5 | `art/raw/players/look-20/ball/shoot-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.6 | `art/raw/players/look-20/ball/shoot-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.7 | `art/raw/players/look-20/ball/pass-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.8 | `art/raw/players/look-20/ball/pass-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.9 | `art/raw/players/look-20/ball/header-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.10 | `art/raw/players/look-20/ball/header-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 195.11 | `art/raw/players/look-20/ball/header-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.1 | `art/raw/players/look-20/ground/tackle-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.2 | `art/raw/players/look-20/ground/tackle-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.3 | `art/raw/players/look-20/ground/tackle-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.4 | `art/raw/players/look-20/ground/tackle-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.5 | `art/raw/players/look-20/ground/fall-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.6 | `art/raw/players/look-20/ground/fall-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.7 | `art/raw/players/look-20/ground/fall-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 196.8 | `art/raw/players/look-20/ground/fall-04.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 197.1 | `art/raw/players/look-20/emotion/celebrate-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 197.2 | `art/raw/players/look-20/emotion/celebrate-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 197.3 | `art/raw/players/look-20/emotion/celebrate-03.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 197.4 | `art/raw/players/look-20/emotion/sad-01.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 197.5 | `art/raw/players/look-20/emotion/sad-02.png` | [`04-looks.md`](art/images/04-looks.md) |
| ⬜ لم يتم العمل عليه | سليمان | 288.1 | `art/raw/coach-8/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 288.2 | `art/raw/coach-8/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 289.1 | `art/raw/coach-8/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 289.2 | `art/raw/coach-8/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 290.1 | `art/raw/coach-8/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 290.2 | `art/raw/coach-8/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.1 | `art/raw/coach-8/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.2 | `art/raw/coach-8/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.3 | `art/raw/coach-8/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.4 | `art/raw/coach-8/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.5 | `art/raw/coach-8/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 291.6 | `art/raw/coach-8/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### الدفعة 9

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 292.1 | `art/raw/coach-9/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 292.2 | `art/raw/coach-9/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 293.1 | `art/raw/coach-9/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 293.2 | `art/raw/coach-9/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 294.1 | `art/raw/coach-9/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 294.2 | `art/raw/coach-9/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.1 | `art/raw/coach-9/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.2 | `art/raw/coach-9/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.3 | `art/raw/coach-9/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.4 | `art/raw/coach-9/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.5 | `art/raw/coach-9/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 295.6 | `art/raw/coach-9/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### الدفعة 10

| الحالة | من | اللوحة | الملف | الأمر في |
|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | سليمان | 296.1 | `art/raw/coach-10/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 296.2 | `art/raw/coach-10/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 297.1 | `art/raw/coach-10/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 297.2 | `art/raw/coach-10/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 298.1 | `art/raw/coach-10/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 298.2 | `art/raw/coach-10/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.1 | `art/raw/coach-10/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.2 | `art/raw/coach-10/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.3 | `art/raw/coach-10/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.4 | `art/raw/coach-10/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.5 | `art/raw/coach-10/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ لم يتم العمل عليه | سليمان | 299.6 | `art/raw/coach-10/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

