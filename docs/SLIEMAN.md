# دليل سليمان: الصور والسبرنتات

> **مرجعك اليومي.** منه تعرف ماذا تعمل اليوم، وما ينتظر قرارك، وما القادم بتواريخه.
> يولّده `python3 tools/team.py` بعد كل مراجعة وكل دمج، فلا يُعدَّل يدوياً. والخطة كاملة في [`SCHEDULE.md`](SCHEDULE.md).

**تقسيم العمل (قرار 2026-10-22):** أنت تصنع صور الدفعات 1 إلى 4 (التي تحتاجها اللعبة أولاً) **ما عدا الملاعب**، بالتوازي مع السبرنتات، و**كل صورة تحتاج إعادة** من أي دفعة. وحمزة على الصوت، ثم **الملاعب كلها** من أي دفعة، وصور الدفعات 5 إلى 16 التي تُبنى آخر الخطة ([`HAMZA.md`](HAMZA.md)). وصور اللحظات والمدربين تصنعها يدوياً بجانبها (قسمها تحت). يومك 5 ساعات: **للصور 2 منها (12 صورة معتمدة)، وللكود 3** مع Claude. والأرقام في `tools/plan/rates.py`.

## يومك بالترتيب

### 1. الصور (2 من 5 ساعات تقريباً)

**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تُبنى بها وحدها وتنتظرها. لا تبدأ الدفعة 2 قبل إكمالها.

1. **🔁 أعد 9 صورة من الدفعة 1** رفضتها المراجعة، بأمرها وسطر تصحيحها في: [`2026-10-20-striker-ball.md`](art/redo/2026-10-20-striker-ball.md)، [`2026-10-20-striker-run-back.md`](art/redo/2026-10-20-striker-run-back.md).
2. **⬜ ثم الجديدة بالترتيب (196 باقية في الدفعة 1):** من [`sprint-02-days.md`](sprints/sprint-02-days.md). أول 12 في الجدول تحت.

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

## صور اللحظات والمدربين (يدوياً، خارج صور اليوم)

**قرار صاحب المشروع (2026-10-22):** صور [`08-moments.md`](art/images/08-moments.md) و[`09-coaches.md`](art/images/09-coaches.md) تصنعها يدوياً بجانب صور اليوم، وترفعها بنفسك متى جهزت، ثم قل «راجع اللحظات والمدربين». وليست عند حمزة.

**148 صورة:** ✅ 28 معتمدة · ⏳ 0 تنتظر المراجعة · 🔁 3 للإعادة · ⬜ 117 لم تُصنع.

1. **الأمر** في ملف الجزء، ابحث برقم اللوحة مثل `### 256.1`، ومعه المرفقات المكتوبة تحت «ارفق». والإعادة من ملف الإعادة بسطر تصحيحها.
2. **احفظ كل صورة PNG حقيقياً، عريضة 3:2،** باسمها في المسار المكتوب تحت، وارفعها إلى `art/raw/`.

| الجزء | الدفعة | المجموع | ✅ | ⏳ | 🔁 | ⬜ |
|---|---|---|---|---|---|---|
| `08-moments.md` | 1 | 4 | 0 | 0 | 0 | 4 |
| `08-moments.md` | 2 | 20 | 16 | 0 | 0 | 4 |
| `08-moments.md` | 4 | 4 | 0 | 0 | 0 | 4 |
| `09-coaches.md` | 1 | 12 | 12 | 0 | 0 | 0 |
| `09-coaches.md` | 2 | 12 | 0 | 0 | 3 | 9 |
| `09-coaches.md` | 3 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 4 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 5 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 6 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 7 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 8 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 9 | 12 | 0 | 0 | 0 | 12 |
| `09-coaches.md` | 10 | 12 | 0 | 0 | 0 | 12 |

### ما بقي منها (120)، بالترتيب

🔁 = إعادة (بأمرها في ملف الإعادة)، ⏳ = مرفوعة تنتظر المراجعة، ⬜ = لم تُصنع (بأمرها في الكتاب). والمعتمد لا يظهر هنا.

#### 256. احتفالات الهدف (وضعيات ثابتة) (الدفعة 1، [`08-moments.md`](art/images/08-moments.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 256.1 | `art/raw/celebrations/solo-1.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 256.2 | `art/raw/celebrations/solo-2.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 256.3 | `art/raw/celebrations/solo-3.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 256.4 | `art/raw/celebrations/solo-4.png` | [`08-moments.md`](art/images/08-moments.md) |

#### 257. احتفالات جماعية (وضعيات ثابتة) (الدفعة 2، [`08-moments.md`](art/images/08-moments.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 257.1 | `art/raw/team-celebrations/team-1.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 257.2 | `art/raw/team-celebrations/team-2.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 257.3 | `art/raw/team-celebrations/team-3.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 257.4 | `art/raw/team-celebrations/final-whistle.png` | [`08-moments.md`](art/images/08-moments.md) |

#### 264. المدرب 2: البطاقة المرجعية (الدفعة 2، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| 🔁 | 264.1 | `art/raw/coach-2/ref.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): الوجه شبيه جداً بمدرب حقيقي مشهور، والمطلوب شخص مخترع |
| 🔁 | 264.2 | `art/raw/coach-2/faces.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة |

#### 265. المدرب 2: الانطلاق والتوقف والدوران (الدفعة 2، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| 🔁 | 265.1 | `art/raw/coach-2/start/idle-01.png` | [`2026-10-22-coaches.md`](art/redo/2026-10-22-coaches.md): تتبع البطاقة المرفوضة: تُعاد بإرفاق البطاقة الجديدة |
| ⬜ | 265.2 | `art/raw/coach-2/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 266. المدرب 2: الحركة (الدفعة 2، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 266.1 | `art/raw/coach-2/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 266.2 | `art/raw/coach-2/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 267. المدرب 2: المشاعر (الدفعة 2، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 267.1 | `art/raw/coach-2/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 267.2 | `art/raw/coach-2/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 267.3 | `art/raw/coach-2/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 267.4 | `art/raw/coach-2/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 267.5 | `art/raw/coach-2/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 267.6 | `art/raw/coach-2/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 268. المدرب 3: البطاقة المرجعية (الدفعة 3، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 268.1 | `art/raw/coach-3/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 268.2 | `art/raw/coach-3/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 269. المدرب 3: الانطلاق والتوقف والدوران (الدفعة 3، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 269.1 | `art/raw/coach-3/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 269.2 | `art/raw/coach-3/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 270. المدرب 3: الحركة (الدفعة 3، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 270.1 | `art/raw/coach-3/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 270.2 | `art/raw/coach-3/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 271. المدرب 3: المشاعر (الدفعة 3، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 271.1 | `art/raw/coach-3/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 271.2 | `art/raw/coach-3/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 271.3 | `art/raw/coach-3/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 271.4 | `art/raw/coach-3/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 271.5 | `art/raw/coach-3/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 271.6 | `art/raw/coach-3/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 258. الكأس والتتويج (وضعيات ثابتة) (الدفعة 4، [`08-moments.md`](art/images/08-moments.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 258.1 | `art/raw/trophy/lift.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 258.2 | `art/raw/trophy/moments.png` | [`08-moments.md`](art/images/08-moments.md) |

#### 259. ركلات الترجيح (وضعيات ثابتة) (الدفعة 4، [`08-moments.md`](art/images/08-moments.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 259.1 | `art/raw/shootout/line.png` | [`08-moments.md`](art/images/08-moments.md) |
| ⬜ | 259.2 | `art/raw/shootout/walk.png` | [`08-moments.md`](art/images/08-moments.md) |

#### 272. المدرب 4: البطاقة المرجعية (الدفعة 4، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 272.1 | `art/raw/coach-4/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 272.2 | `art/raw/coach-4/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 273. المدرب 4: الانطلاق والتوقف والدوران (الدفعة 4، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 273.1 | `art/raw/coach-4/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 273.2 | `art/raw/coach-4/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 274. المدرب 4: الحركة (الدفعة 4، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 274.1 | `art/raw/coach-4/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 274.2 | `art/raw/coach-4/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 275. المدرب 4: المشاعر (الدفعة 4، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 275.1 | `art/raw/coach-4/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 275.2 | `art/raw/coach-4/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 275.3 | `art/raw/coach-4/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 275.4 | `art/raw/coach-4/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 275.5 | `art/raw/coach-4/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 275.6 | `art/raw/coach-4/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 276. المدرب 5: البطاقة المرجعية (الدفعة 5، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 276.1 | `art/raw/coach-5/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 276.2 | `art/raw/coach-5/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 277. المدرب 5: الانطلاق والتوقف والدوران (الدفعة 5، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 277.1 | `art/raw/coach-5/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 277.2 | `art/raw/coach-5/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 278. المدرب 5: الحركة (الدفعة 5، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 278.1 | `art/raw/coach-5/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 278.2 | `art/raw/coach-5/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 279. المدرب 5: المشاعر (الدفعة 5، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 279.1 | `art/raw/coach-5/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 279.2 | `art/raw/coach-5/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 279.3 | `art/raw/coach-5/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 279.4 | `art/raw/coach-5/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 279.5 | `art/raw/coach-5/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 279.6 | `art/raw/coach-5/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 280. المدرب 6: البطاقة المرجعية (الدفعة 6، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 280.1 | `art/raw/coach-6/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 280.2 | `art/raw/coach-6/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 281. المدرب 6: الانطلاق والتوقف والدوران (الدفعة 6، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 281.1 | `art/raw/coach-6/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 281.2 | `art/raw/coach-6/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 282. المدرب 6: الحركة (الدفعة 6، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 282.1 | `art/raw/coach-6/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 282.2 | `art/raw/coach-6/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 283. المدرب 6: المشاعر (الدفعة 6، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 283.1 | `art/raw/coach-6/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 283.2 | `art/raw/coach-6/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 283.3 | `art/raw/coach-6/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 283.4 | `art/raw/coach-6/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 283.5 | `art/raw/coach-6/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 283.6 | `art/raw/coach-6/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 284. المدرب 7: البطاقة المرجعية (الدفعة 7، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 284.1 | `art/raw/coach-7/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 284.2 | `art/raw/coach-7/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 285. المدرب 7: الانطلاق والتوقف والدوران (الدفعة 7، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 285.1 | `art/raw/coach-7/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 285.2 | `art/raw/coach-7/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 286. المدرب 7: الحركة (الدفعة 7، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 286.1 | `art/raw/coach-7/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 286.2 | `art/raw/coach-7/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 287. المدرب 7: المشاعر (الدفعة 7، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 287.1 | `art/raw/coach-7/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 287.2 | `art/raw/coach-7/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 287.3 | `art/raw/coach-7/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 287.4 | `art/raw/coach-7/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 287.5 | `art/raw/coach-7/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 287.6 | `art/raw/coach-7/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 288. المدرب 8: البطاقة المرجعية (الدفعة 8، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 288.1 | `art/raw/coach-8/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 288.2 | `art/raw/coach-8/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 289. المدرب 8: الانطلاق والتوقف والدوران (الدفعة 8، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 289.1 | `art/raw/coach-8/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 289.2 | `art/raw/coach-8/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 290. المدرب 8: الحركة (الدفعة 8، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 290.1 | `art/raw/coach-8/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 290.2 | `art/raw/coach-8/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 291. المدرب 8: المشاعر (الدفعة 8، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 291.1 | `art/raw/coach-8/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 291.2 | `art/raw/coach-8/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 291.3 | `art/raw/coach-8/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 291.4 | `art/raw/coach-8/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 291.5 | `art/raw/coach-8/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 291.6 | `art/raw/coach-8/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 292. المدرب 9: البطاقة المرجعية (الدفعة 9، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 292.1 | `art/raw/coach-9/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 292.2 | `art/raw/coach-9/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 293. المدرب 9: الانطلاق والتوقف والدوران (الدفعة 9، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 293.1 | `art/raw/coach-9/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 293.2 | `art/raw/coach-9/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 294. المدرب 9: الحركة (الدفعة 9، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 294.1 | `art/raw/coach-9/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 294.2 | `art/raw/coach-9/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 295. المدرب 9: المشاعر (الدفعة 9، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 295.1 | `art/raw/coach-9/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 295.2 | `art/raw/coach-9/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 295.3 | `art/raw/coach-9/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 295.4 | `art/raw/coach-9/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 295.5 | `art/raw/coach-9/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 295.6 | `art/raw/coach-9/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 296. المدرب 10: البطاقة المرجعية (الدفعة 10، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 296.1 | `art/raw/coach-10/ref.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 296.2 | `art/raw/coach-10/faces.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 297. المدرب 10: الانطلاق والتوقف والدوران (الدفعة 10، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 297.1 | `art/raw/coach-10/start/idle-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 297.2 | `art/raw/coach-10/start/idle-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 298. المدرب 10: الحركة (الدفعة 10، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 298.1 | `art/raw/coach-10/move/instruct-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 298.2 | `art/raw/coach-10/move/instruct-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

#### 299. المدرب 10: المشاعر (الدفعة 10، [`09-coaches.md`](art/images/09-coaches.md))

| | اللوحة | الملف | الأمر في |
|---|---|---|---|
| ⬜ | 299.1 | `art/raw/coach-10/emotion/celebrate-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 299.2 | `art/raw/coach-10/emotion/celebrate-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 299.3 | `art/raw/coach-10/emotion/despair-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 299.4 | `art/raw/coach-10/emotion/despair-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 299.5 | `art/raw/coach-10/emotion/argue-01.png` | [`09-coaches.md`](art/images/09-coaches.md) |
| ⬜ | 299.6 | `art/raw/coach-10/emotion/argue-02.png` | [`09-coaches.md`](art/images/09-coaches.md) |

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

**النسخ:** v0.1 في 24 ديسمبر 2026، v0.2 في 6 فبراير 2027، v1.0 في 8 مايو 2027، v1.1 في 8 يونيو 2027، v1.8 في 7 يوليو 2027.

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
| 1 | 236 | 31 | 0 | 9 | 196 |
| 2 | 225 | 2 | 0 | 24 | 199 |
| 3 | 326 | 0 | 0 | 0 | 326 |
| 4 | 307 | 0 | 0 | 1 | 306 |
| 5 | 1 | 0 | 0 | 1 | 0 |
| **الكل** | **1095** | **33** | **0** | **35** | **1027** |

**صور حمزة (الملاعب كلها، والدفعات 5 إلى 16):** 61 من 898 معتمدة. التفاصيل في [`HAMZA.md`](HAMZA.md).

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
| [`HAMZA.md`](HAMZA.md) | مرجع حمزة: الصوت، وصور الدفعات الأخيرة |
