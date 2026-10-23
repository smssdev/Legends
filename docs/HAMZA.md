# دليل حمزة: الصوت

> **مرجعك الوحيد.** منه تعرف ما المطلوب الآن، وكيف تسجله، وأين تضعه، وكم أنجز.
> يولده `python3 tools/team.py` بعد كل مراجعة، فلا يعدل يدويا.

**تقسيم العمل (قرار صاحب المشروع، 2026-10-23):** **الصوت كله عندك** (المعلق العربي وأصوات الملعب). والصور **ملغاة**، فلا لوحات ملاعب عليك: الملاعب والمباراة الواقعية تبنى في Unity بعد تطبيق Flutter، ومقاطعك تستخدم فيها كما هي. والتقرير الكامل لكل مقطع آخر هذا الملف.

## ⭐ الأولوية الآن: الدفعة 1 (المعلق العربي في المحاكي)

**المعلق العربي في المحاكي (السبرنت 7) يبنى بالدفعة 1.** فكل ما تحت يسبق أي مقطع من دفعة أخرى.

**الدفعة 1:** ✅ 94 مكتملة · 🔁 0 يجب إعادتها · 👂 4 تأكد بالسمع · ⬜ 0 لم تسجل. الباقي 4 مقطعا، أي يوم أو يومان بوتيرة 30 يوميا.

| | الحالة | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| 1 | 👂 تأكد بالسمع | `audio/raw/ar/story/miss-pre-1.wav` | هادئ | شوطة... | لم يتعرف عليها التحقق الآلي، وطولها ثانيتان لكلمة واحدة. اسمعها وتأكد أنها «تسديدة...» وحدها. |
| 2 | 👂 تأكد بالسمع | `audio/raw/ar/story/miss-post-2.wav` | هادئ | فرصة مبتتكررش كتير! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |
| 3 | 👂 تأكد بالسمع | `audio/raw/ar/story/blocked-key-2.wav` | متحمس | تدخل شجاع من المدافع! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |
| 4 | 👂 تأكد بالسمع | `audio/raw/ar/story/red-pre-1.wav` | هادئ | تدخل عنيف من ورا! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |

## المطلوب الآن، بالترتيب

1. **🔁 أعد المقاطع المرفوضة من الدفعة 1 (0)، و👂 تأكد بالسمع من (4):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، أول قسمين.
2. **ثم أصوات الملعب (44):** [`audio/todo/sfx.md`](audio/todo/sfx.md).

**الإيقاع:** حوالي 30 مقطعا معتمدا يوميا. وتواريخ كل دفعة في [`SCHEDULE.md`](SCHEDULE.md)، قسم «مسار الصوت».

## طريقة التسجيل

1. **باللهجة المصرية،** بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع (قرار 2026-10-20).
2. **النص مكتوب بالمصرية كما يقال، بلا تشكيل:** اقرأه كما هو.
3. **جملة واحدة لكل مقطع،** بلا جملة من مقطع آخر وبلا تكرار طويل. والمقطع الذي قبل اللحظة (pre) لا يكشف النتيجة.
4. **الحفظ:** باسم الملف وفي المجلد المكتوبين في قائمة الدفعة. والصيغة WAV أو MP3 أو M4A.
5. **أصوات الملعب:** بترخيص CC0 أو مولدة، والحلقات لا يسمع مكان تكرارها.

### بعد الرفع

- ارفع إلى `main` بالأسماء الصحيحة، وقل: «راجع الصوت».
- المعتمد يعلم ✅، والمرفوض يحذف من مجلده وينتقل لقائمة الإعادة بسببه.

## الحالة بالأرقام

| الدفعة | المجموع | ✅ | 🔁 | 👂 | ⬜ | القائمة |
|---|---|---|---|---|---|---|
| 1 | 98 | 94 | 0 | 4 | 0 | [`wave-01.md`](audio/todo/wave-01.md) |
| 2 | 111 | 111 | 0 | 0 | 0 | [`wave-02.md`](audio/todo/wave-02.md) |
| 3 | 98 | 98 | 0 | 0 | 0 | [`wave-03.md`](audio/todo/wave-03.md) |
| 4 | 56 | 56 | 0 | 0 | 0 | [`wave-04.md`](audio/todo/wave-04.md) |
| 5 | 31 | 31 | 0 | 0 | 0 | [`wave-05.md`](audio/todo/wave-05.md) |
| 6 | 15 | 15 | 0 | 0 | 0 | [`wave-06.md`](audio/todo/wave-06.md) |
| 7 | 5 | 5 | 0 | 0 | 0 | [`wave-07.md`](audio/todo/wave-07.md) |
| 8 | 3 | 3 | 0 | 0 | 0 | [`wave-08.md`](audio/todo/wave-08.md) |
| 9 | 3 | 3 | 0 | 0 | 0 | [`wave-09.md`](audio/todo/wave-09.md) |
| 10 | 3 | 3 | 0 | 0 | 0 | [`wave-10.md`](audio/todo/wave-10.md) |
| 11 | 3 | 3 | 0 | 0 | 0 | [`wave-11.md`](audio/todo/wave-11.md) |
| 12 | 2 | 2 | 0 | 0 | 0 | [`wave-12.md`](audio/todo/wave-12.md) |
| أصوات الملعب | 44 | 0 | 0 | 0 | 44 | [`sfx.md`](audio/todo/sfx.md) |
| **المعلق كله** | **428** | **424** | **0** | **4** | **0** | |

## كل الملفات

| الملف | ما فيه |
|---|---|
| [`audio/todo/README.md`](audio/todo/README.md) | ملخص الصوت، ومنه قائمة كل دفعة |
| [`audio/ARABIC_VOICE.md`](audio/ARABIC_VOICE.md) | كتالوج المعلق كاملا والشرح |
| `audio/raw/<المجلد>/README.md` | أسماء ملفات كل مجلد |

## التقرير الكامل

### الصوت: كل مقطع بحالته

**الحالة:** ✅ مكتمل · 👂 مسجل ينتظر التأكد بالسمع · 🔁 يجب إعادته · ⬜ لم يتم العمل عليه. والصوت كله على حمزة.

| | المجموع | ✅ | 👂 | 🔁 | ⬜ |
|---|---|---|---|---|---|
| الدفعة 1 | 98 | 94 | 4 | 0 | 0 |
| الدفعة 2 | 111 | 111 | 0 | 0 | 0 |
| الدفعة 3 | 98 | 98 | 0 | 0 | 0 |
| الدفعة 4 | 56 | 56 | 0 | 0 | 0 |
| الدفعة 5 | 31 | 31 | 0 | 0 | 0 |
| الدفعة 6 | 15 | 15 | 0 | 0 | 0 |
| الدفعة 7 | 5 | 5 | 0 | 0 | 0 |
| الدفعة 8 | 3 | 3 | 0 | 0 | 0 |
| الدفعة 9 | 3 | 3 | 0 | 0 | 0 |
| الدفعة 10 | 3 | 3 | 0 | 0 | 0 |
| الدفعة 11 | 3 | 3 | 0 | 0 | 0 |
| الدفعة 12 | 2 | 2 | 0 | 0 | 0 |
| أصوات الملعب | 44 | 0 | 0 | 0 | 44 |
| **الكل** | **472** | **424** | **4** | **0** | **44** |

#### الدفعة 1

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-pre-1.wav` | هادئ | هجمة خطيرة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-pre-2.wav` | هادئ | انطلاقة سريعة على المرمى... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-pre-3.wav` | هادئ | الكورة بتقرب من منطقة الجزا... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-key-1.wav` | متحمس | جووول! جون جامد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-key-2.wav` | متحمس | جون! الكورة في الشبكة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-key-3.wav` | متحمس | يا سلام! جون خرافي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-post-1.wav` | هادئ | المدرجات ولعت فرحة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-post-2.wav` | هادئ | إيه الجون ده! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/goal-post-3.wav` | هادئ | جون يستاهل التسقيف! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-pre-1.wav` | هادئ | عرضية جوه المنطقة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-pre-2.wav` | هادئ | الكورة عالية جوه الصندوق... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-key-1.wav` | متحمس | جون! راسية قوية في الشبكة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-key-2.wav` | متحمس | جون براسية ولا أروع! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-post-1.wav` | هادئ | محدش يقدر يوقفه في الهوا! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/header-post-2.wav` | هادئ | طلعة حلوة أوي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-pre-1.wav` | هادئ | فاول على حدود المنطقة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-pre-2.wav` | هادئ | الحيطة اتعملت... والكل مستني. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-key-1.wav` | متحمس | فوق الحيطة وفي الزاوية! جون يجنن! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-key-2.wav` | متحمس | جون من فاول! لوحة فنية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-post-1.wav` | هادئ | الحارس متحركش! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_goal-post-2.wav` | هادئ | شوطة متتصدش! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_save-key-1.wav` | متحمس | فوق الحيطة... والحارس طار وبعدها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_save-key-2.wav` | متحمس | تصدي جامد للفاول! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_save-post-1.wav` | هادئ | كانت هتبقى جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_save-post-2.wav` | هادئ | قريبة أوي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_miss-key-1.wav` | متحمس | فوق العارضة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_miss-key-2.wav` | متحمس | جنب القائم! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/free_kick_miss-post-1.wav` | هادئ | فرصة ضاعت. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_goal-pre-1.wav` | هادئ | ضربة جزا! الحكم بيشاور على النقطة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_goal-pre-2.wav` | هادئ | الملعب كله حابس نفسه... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_goal-key-1.wav` | متحمس | جون! الحارس في حتة والكورة في حتة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_goal-key-2.wav` | متحمس | جون! شوطة واثقة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_goal-post-1.wav` | هادئ | أعصاب حديد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_save-key-1.wav` | متحمس | صدها! الحارس قراها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_save-key-2.wav` | متحمس | يا سلام! الحارس صد ضربة الجزا! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalty_save-post-1.wav` | هادئ | لحظة كبيرة في الماتش! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-pre-1.wav` | هادئ | انفراد بالمرمى! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-pre-2.wav` | هادئ | شوطة قوية... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-pre-3.wav` | هادئ | فرصة خطيرة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-key-1.wav` | متحمس | تصدي جامد من الحارس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-key-2.wav` | متحمس | الحارس طار وبعدها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-post-1.wav` | هادئ | حارس عالمي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/save-post-2.wav` | هادئ | إنقاذ بجون! |  |
| 👂 مسجل، ينتظر التأكد بالسمع | حمزة | `audio/raw/ar/story/miss-pre-1.wav` | هادئ | شوطة... | لم يتعرف عليها التحقق الآلي، وطولها ثانيتان لكلمة واحدة. اسمعها وتأكد أنها «تسديدة...» وحدها. |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/miss-pre-2.wav` | هادئ | محاولة على المرمى... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/miss-key-3.wav` | متحمس | كانت هتبقى جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/miss-post-1.wav` | هادئ | المدرب مش مصدق! |  |
| 👂 مسجل، ينتظر التأكد بالسمع | حمزة | `audio/raw/ar/story/miss-post-2.wav` | هادئ | فرصة مبتتكررش كتير! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/post-key-1.wav` | متحمس | القائم! القائم رجع الكورة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/post-post-1.wav` | هادئ | سنتيمترات حرمته من الجون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/blocked-pre-2.wav` | هادئ | محاولة قوية... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/blocked-key-1.wav` | متحمس | الدفاع صدها! |  |
| 👂 مسجل، ينتظر التأكد بالسمع | حمزة | `audio/raw/ar/story/blocked-key-2.wav` | متحمس | تدخل شجاع من المدافع! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/blocked-post-1.wav` | هادئ | دفاع جامد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/offside-pre-1.wav` | هادئ | كورة طويلة ورا الدفاع... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/offside-key-1.wav` | هادئ | الراية اترفعت. أوفسايد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/offside-key-2.wav` | هادئ | لأ! أوفسايد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/offside-post-1.wav` | هادئ | كان متقدم بخطوة قبل التمريرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_header-pre-1.wav` | هادئ | كورنر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_header-pre-2.wav` | هادئ | العرضية عالية... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_header-key-1.wav` | متحمس | راسية! فوق العارضة بشوية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_header-key-2.wav` | متحمس | راسية قريبة أوي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_header-post-1.wav` | هادئ | الكورنر كان هيجيب جون. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_claim-key-1.wav` | هادئ | الحارس ماسك الكورة كويس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/corner_claim-post-1.wav` | هادئ | الخطر راح. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/yellow-pre-1.wav` | هادئ | تدخل متأخر! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/yellow-pre-2.wav` | هادئ | تدخل جامد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/yellow-key-1.wav` | هادئ | كارت أصفر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/yellow-key-2.wav` | هادئ | الحكم طلع الكارت الأصفر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/yellow-post-1.wav` | هادئ | لازم ياخد باله من دلوقتي. |  |
| 👂 مسجل، ينتظر التأكد بالسمع | حمزة | `audio/raw/ar/story/red-pre-1.wav` | هادئ | تدخل عنيف من ورا! | سجل من جديد بعد المراجعة، وينتظر المراجعة. |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/red-pre-2.wav` | هادئ | تدخل خطير! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/red-key-1.wav` | متحمس | كارت أحمر! طرد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/red-key-2.wav` | متحمس | الحكم طرده على طول! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/red-post-1.wav` | هادئ | فريقه هيكمل بعشرة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/red-post-2.wav` | هادئ | خروج حزين على أوضة اللبس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/second_yellow-pre-1.wav` | هادئ | تدخل متأخر تاني... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/second_yellow-key-1.wav` | متحمس | الإنذار التاني! طرد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/second_yellow-post-1.wav` | هادئ | ميلومش غير نفسه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/sub-key-1.wav` | هادئ | تغيير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/sub-key-2.wav` | هادئ | تغيير في الفريق. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/sub-post-1.wav` | هادئ | دم جديد في الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/injury-key-1.wav` | هادئ | لاعب واقع على الأرض. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/injury-key-2.wav` | هادئ | إصابة... والجهاز الطبي داخل. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/injury-post-1.wav` | هادئ | نتمنى متكونش خطيرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/coach-key-1.wav` | هادئ | المدرب بيدي تعليمات جديدة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/coach-key-2.wav` | هادئ | تغيير تكتيكي من الدكة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/coach-post-1.wav` | هادئ | نشوف هيغير حاجة ولا لأ. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/kickoff-key-1.wav` | هادئ | الماتش بدأ! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/halftime-key-1.wav` | متحمس | نهاية الشوط الأول. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/fulltime-key-1.wav` | متحمس | صافرة النهاية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/extra_time-key-1.wav` | متحمس | على الوقت الإضافي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/penalties-key-1.wav` | متحمس | على ضربات الترجيح! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/stoppage-key-1.wav` | هادئ | وقت بدل ضايع. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/shootout-key-1.wav` | متحمس | ضربات الترجيح... أعصاب حديد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/attack-key-1.wav` | هادئ | هجمة منظمة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/attack-key-2.wav` | هادئ | ضغط مستمر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/story/attack-key-3.wav` | هادئ | بيحاولوا يبنوا الهجمة. |  |

#### الدفعة 2

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-01.wav` | هادئ | مسا الخير وأهلا بيكم في ماتش منتظر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-02.wav` | هادئ | أهلا بيكم، المدرجات مليانة والجو تحفة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-03.wav` | هادئ | ماتش كبير مستنينا الليلة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-01.wav` | متحمس | الماتش بدأ! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-02.wav` | متحمس | صافرة البداية، وعلى بركة الله! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-03.wav` | هادئ | الكورة بتتحرك من نص الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-01.wav` | هادئ | تدوير للكورة في النص. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-02.wav` | هادئ | بنا هادي من ورا. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-03.wav` | هادئ | الفريق بيدور على ثغرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-01.wav` | هادئ | هجمة خطيرة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-02.wav` | هادئ | انطلاقة سريعة على المرمى... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-03.wav` | هادئ | الكورة بتقرب من منطقة الجزا... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-01.wav` | متحمس | هجمة مرتدة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-02.wav` | متحمس | مرتدة سريعة جدا! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-03.wav` | هادئ | قطع للكورة، والطريق مفتوح... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-01.wav` | متحمس | بيشوط! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-02.wav` | متحمس | شوطة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-03.wav` | متحمس | شاطها جامدة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-01.wav` | صاخب | جوووووول! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-02.wav` | صاخب | جون! جون! جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-03.wav` | صاخب | جووول! جون جامد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-01.wav` | متحمس | المدرجات ولعت فرحة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-02.wav` | هادئ | إيه الجون ده! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-03.wav` | هادئ | جون يستاهل التسقيف. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-01.wav` | متحمس | التعادل! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-02.wav` | متحمس | الفريق رجع للماتش! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-03.wav` | متحمس | تقدم مستحق! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-01.wav` | صاخب | في الوقت القاتل! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-02.wav` | صاخب | في آخر ثواني! جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-03.wav` | صاخب | جون قاتل! مش معقول! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-01.wav` | هادئ | عرضية جوه المنطقة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-02.wav` | هادئ | الكورة عالية جوه الصندوق... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-03.wav` | صاخب | جون! راسية قوية في الشبكة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-01.wav` | متحمس | جنب القائم! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-02.wav` | متحمس | فوق العارضة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-03.wav` | متحمس | آه! ضاعت! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/blocked/blocked-01.wav` | متحمس | المدافع صدها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/blocked/blocked-02.wav` | متحمس | جسم المدافع في الطريق! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/blocked/blocked-03.wav` | هادئ | تضحية دفاعية. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-01.wav` | متحمس | القائم! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-02.wav` | متحمس | العارضة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-03.wav` | متحمس | خبطت في القائم وطلعت! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-01.wav` | متحمس | تصدي جامد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-02.wav` | متحمس | الحارس طار وبعدها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-03.wav` | متحمس | إيه الحارس ده! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/line/line-01.wav` | متحمس | شالها من على الخط! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/line/line-02.wav` | متحمس | إنقاذ في آخر لحظة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/line/line-03.wav` | هادئ | كانت هتعدي الخط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/own/own-01.wav` | متحمس | جون في مرماه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/own/own-02.wav` | متحمس | جاب جون في نفسه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/own/own-03.wav` | هادئ | لحظة صعبة على المدافع. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-01.wav` | متحمس | الراية اترفعت! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-02.wav` | هادئ | أوفسايد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-03.wav` | هادئ | كان متقدم بخطوة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-01.wav` | متحمس | عرقلة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-02.wav` | هادئ | فاول واضح. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-03.wav` | هادئ | تدخل جامد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-01.wav` | متحمس | كارت أصفر! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-02.wav` | هادئ | إنذار. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-03.wav` | هادئ | الحكم طلع الكارت الأصفر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-01.wav` | صاخب | كارت أحمر! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-02.wav` | متحمس | طرد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-03.wav` | متحمس | الإنذار التاني... وطرد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-01.wav` | هادئ | فاول على حدود المنطقة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-02.wav` | هادئ | الحيطة اتعملت... والكل مستني. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-03.wav` | هادئ | مسافة مثالية للتسديد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-01.wav` | صاخب | ضربة جزا! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-02.wav` | متحمس | الحكم بيشاور على النقطة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-03.wav` | هادئ | الملعب كله حابس نفسه... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-01.wav` | هادئ | على ضربات الترجيح. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-02.wav` | هادئ | القرعة هتحدد مين يبدأ. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-03.wav` | هادئ | الضربة الأولى... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-01.wav` | هادئ | كورنر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-02.wav` | هادئ | الكل جوه المنطقة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-03.wav` | هادئ | الكورنر اتلعب عالي... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-01.wav` | هادئ | الحكم بيكلم حكام الفيديو. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-02.wav` | هادئ | لحظات... مراجعة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-03.wav` | هادئ | الحكم رايح للشاشة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-01.wav` | هادئ | لاعب واقع على الأرض. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-02.wav` | هادئ | الحكم وقف اللعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-03.wav` | هادئ | الجهاز الطبي داخل الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-01.wav` | هادئ | تغيير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-02.wav` | هادئ | المدرب بيعمل تغيير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-03.wav` | هادئ | دم جديد في الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-01.wav` | هادئ | المدرب بيغير الخطة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-02.wav` | هادئ | تعليمات جديدة من على الخط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-03.wav` | هادئ | الفريق طالع للهجوم. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/stoppage/stoppage-01.wav` | هادئ | الوقت بدل الضايع. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/stoppage/stoppage-02.wav` | هادئ | الحكم الرابع رافع اللوحة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/stoppage/stoppage-03.wav` | هادئ | فاضل دقايق قليلة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/half/half-01.wav` | هادئ | نهاية الشوط الأول. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/half/half-02.wav` | هادئ | الحكم صفر للاستراحة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/half/half-03.wav` | هادئ | شوط أول مثير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-01.wav` | متحمس | نهاية الماتش! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-02.wav` | متحمس | الحكم صفر صافرة النهاية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-03.wav` | متحمس | فوز غالي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/trophy/trophy-01.wav` | صاخب | الأبطال! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/trophy/trophy-02.wav` | صاخب | الكاس في الحضن! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/trophy/trophy-03.wav` | متحمس | الكابتن بيرفع الكاس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-01.wav` | هادئ | الجمهور مولع المدرجات. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-02.wav` | هادئ | الأغاني مش بتقف. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-03.wav` | هادئ | المدرجات بتترج. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-01.wav` | صاخب | مقصية! جون أسطوري! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-02.wav` | صاخب | بالكعب! إيه المهارة دي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-03.wav` | صاخب | صاروخ من بعيد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/scuffle/scuffle-01.wav` | متحمس | شد بين اللاعيبة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/scuffle/scuffle-02.wav` | هادئ | الحكم بيدخل يفضها. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/scuffle/scuffle-03.wav` | هادئ | الأعصاب مشدودة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-01.wav` | هادئ | تعالوا نحلل اللي حصل في الشوط الأول. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-02.wav` | هادئ | الأرقام بتقول كتير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-03.wav` | هادئ | الاستحواذ مش معناه الفوز. |  |

#### الدفعة 3

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-04.wav` | هادئ | الفريقين داخلين أرض الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-05.wav` | هادئ | كله جاهز لصافرة البداية. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-06.wav` | هادئ | ماتش مفيهوش قسمة على اتنين. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-04.wav` | هادئ | الشوط التاني بدأ. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-05.wav` | هادئ | الفريقين رجعوا من أوضة اللبس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-06.wav` | هادئ | شوط تاني جديد، وكل حاجة ممكنة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-04.wav` | هادئ | باصات قصيرة وصبر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-05.wav` | هادئ | الضغط عالي في نص الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-06.wav` | هادئ | الكورة راجعة للحارس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-04.wav` | هادئ | تمريرة بينية... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-05.wav` | هادئ | مراوغة على الخط... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-06.wav` | هادئ | عرضية على المنطقة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-04.wav` | متحمس | تلاتة ضد اتنين! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-05.wav` | هادئ | الضغط جاب كورة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-06.wav` | متحمس | الدفاع مكشوف! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-04.wav` | متحمس | من بعيد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-05.wav` | متحمس | بيجرب حظه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-06.wav` | متحمس | براسه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-04.wav` | صاخب | في الشبكة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-05.wav` | صاخب | يا سلام! جون خرافي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-06.wav` | صاخب | جون ولا أروع! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-04.wav` | هادئ | الجمهور مش هينساه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-05.wav` | هادئ | تعالوا نشوف الإعادة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-06.wav` | هادئ | بصوا اللمسة دي... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-04.wav` | متحمس | بيضاعف النتيجة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-05.wav` | متحمس | هاتريك! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-06.wav` | متحمس | رجوع تاريخي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-04.wav` | متحمس | دراما في آخر دقايق! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-05.wav` | متحمس | قلب النتيجة في الوقت بدل الضايع! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/late/late-06.wav` | هادئ | محدش يقوم من مكانه قبل الصافرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-04.wav` | صاخب | جون براسية ولا أروع! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-05.wav` | متحمس | راسية فوق العارضة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-06.wav` | متحمس | راسية في حضن الحارس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-04.wav` | متحمس | كانت جون أكيد! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-05.wav` | متحمس | سنتيمترات بس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-06.wav` | متحمس | مش معقول! ضاعت إزاي؟ |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/blocked/blocked-04.wav` | هادئ | الكورة رجعت كورنر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-04.wav` | متحمس | القائم أنقذ الحارس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-05.wav` | هادئ | الحظ واقف ضده. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/post/post-06.wav` | هادئ | القائم بيترج. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-04.wav` | متحمس | بأطراف صوابعه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-05.wav` | متحمس | فوق العارضة بلمسة سحرية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-06.wav` | متحمس | مسكها بثقة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/own/own-04.wav` | هادئ | كان بيحاول يشيلها. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-04.wav` | هادئ | مصيدة أوفسايد ناجحة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-05.wav` | هادئ | الحكم المساعد كان في مكانه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/offside/offside-06.wav` | هادئ | لولا الأوفسايد... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-04.wav` | هادئ | الحكم صفر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-05.wav` | هادئ | اللاعب وقع وبيتألم. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-06.wav` | هادئ | تدخل متأخر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-04.wav` | هادئ | إنذار مستحق. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-05.wav` | هادئ | لازم ياخد باله دلوقتي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-06.wav` | هادئ | بيعترض، بس القرار واضح. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-04.wav` | هادئ | الفريق هيكمل بعشرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-05.wav` | هادئ | قرار قاسي، بس صح. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-06.wav` | هادئ | خارج من الملعب وراسه في الأرض. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-04.wav` | صاخب | فوق الحيطة وفي الزاوية! جون يجنن! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-05.wav` | صاخب | جون من فاول! لوحة فنية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-06.wav` | متحمس | تصدي جامد للفاول! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-04.wav` | هادئ | اللي هيشوط بيحط الكورة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-05.wav` | هادئ | الحارس بيتحرك على خطه... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-06.wav` | هادئ | لحظة الحقيقة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-04.wav` | هادئ | كل ضربة كأنها نهائي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-05.wav` | متحمس | جابها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-06.wav` | متحمس | ضيعها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-04.wav` | هادئ | كورنر قصير. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-05.wav` | متحمس | الحارس طلع وبعدها بإيده! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/corner/corner-06.wav` | هادئ | الدفاع شالها. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-04.wav` | هادئ | الكل مستني القرار. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-05.wav` | متحمس | الجون اتلغى! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-06.wav` | متحمس | الجون صحيح! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-04.wav` | هادئ | نتمنى متكونش إصابة خطيرة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-05.wav` | هادئ | شكله مش هيكمل. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/injury/injury-06.wav` | هادئ | راجع للملعب، أخبار حلوة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-04.wav` | هادئ | تغيير هجومي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-05.wav` | هادئ | تغيير دفاعي عشان يحافظ على النتيجة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-06.wav` | هادئ | الجمهور بيسقف للي خارج. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-04.wav` | هادئ | تحفظ دفاعي دلوقتي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-05.wav` | هادئ | ضغط أعلى من دلوقتي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-06.wav` | هادئ | المدرب متعصب على الخط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/stoppage/stoppage-04.wav` | متحمس | آخر فرصة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/half/half-04.wav` | هادئ | شوط أول مقفول. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/half/half-05.wav` | هادئ | المدربين قدامهم حاجات كتير يراجعوها. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-04.wav` | هادئ | تعادل عادل. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-05.wav` | متحمس | مفاجأة الموسم! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-06.wav` | هادئ | الخسران قدم ماتش مشرف. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/trophy/trophy-04.wav` | هادئ | موسم تاريخي بيتختم باللقب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/trophy/trophy-05.wav` | هادئ | ليلة مش هتتنسي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-04.wav` | هادئ | سكوت رهيب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-05.wav` | هادئ | صفارات استهجان. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-06.wav` | هادئ | تسقيف جامد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-04.wav` | متحمس | مراوغة سحرية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-05.wav` | متحمس | لمسة بالكعب! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-06.wav` | متحمس | عداها من بين رجليه! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/scuffle/scuffle-04.wav` | هادئ | لازم الكل يهدى. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-04.wav` | هادئ | نجم الماتش من غير منافس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-05.wav` | هادئ | أداء جماعي ممتاز. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/studio/studio-06.wav` | هادئ | التغييرات هي اللي فرقت. |  |

#### الدفعة 4

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-07.wav` | هادئ | الجماهير بتهتف قبل ما الماتش يبدأ. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-08.wav` | هادئ | التشكيلتين على الشاشة، والمدربين جاهزين. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-09.wav` | هادئ | ليلة كورة بجد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/kickoff/kickoff-07.wav` | هادئ | يا ترى هنشوف تغيير في الشوط التاني؟ |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-07.wav` | هادئ | لعب على الأطراف. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-08.wav` | هادئ | نقل اللعب من ناحية للتانية. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-09.wav` | هادئ | الدفاع متماسك. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-07.wav` | متحمس | انفراد بالحارس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-08.wav` | متحمس | المساحة فاضية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-09.wav` | هادئ | لعب تنائي حلو... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/counter/counter-07.wav` | هادئ | تحول سريع من الدفاع للهجوم... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-07.wav` | متحمس | على الطاير! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shot/shot-08.wav` | متحمس | بالكعب! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-07.wav` | صاخب | الكورة في حضن الشبكة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-08.wav` | صاخب | جووول! الملعب ولع! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-09.wav` | صاخب | جون من عالم تاني! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-07.wav` | هادئ | الحارس ملوش أي فرصة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-08.wav` | هادئ | تمريرة الجون دي دهب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-09.wav` | متحمس | الاحتفال عند الراية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-07.wav` | متحمس | قلب الترابيزة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-08.wav` | هادئ | النتيجة لسه مفتوحة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-09.wav` | هادئ | جون واحد بس بين الفريقين. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-07.wav` | هادئ | محدش يقدر يوقفه في الهوا. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/header/header-08.wav` | هادئ | طلعة حلوة أوي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-07.wav` | هادئ | فرصة ضاعت. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-08.wav` | هادئ | مشاطهاش كويس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-09.wav` | هادئ | التركيز خانه في آخر لحظة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-07.wav` | متحمس | تصدي مزدوج! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-08.wav` | متحمس | حيطة في المرمى! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-09.wav` | هادئ | الحارس في يومه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-07.wav` | هادئ | كان ممكن يتجنبه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/foul/foul-08.wav` | هادئ | الحكم سايب اللعب يكمل... أفضلية. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/yellow/yellow-07.wav` | هادئ | كارت عشان يوقف الهجمة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/red/red-07.wav` | هادئ | ده بيغير شكل الماتش. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-07.wav` | متحمس | في الحيطة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-08.wav` | متحمس | فوق العارضة بشوية! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/freekick/freekick-09.wav` | هادئ | الحارس متحركش. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-07.wav` | صاخب | جون! الحارس في حتة والكورة في حتة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-08.wav` | صاخب | جون! شوطة واثقة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-09.wav` | صاخب | صدها! الحارس بطل! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-07.wav` | متحمس | الحارس صدها! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-08.wav` | صاخب | كسب بضربات الترجيح! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-09.wav` | هادئ | الضغط رهيب على اللي بيشوط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-07.wav` | متحمس | ضربة جزا بعد المراجعة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-08.wav` | متحمس | اتحولت لكارت أحمر! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-09.wav` | هادئ | مفيش حاجة بعد المراجعة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/sub/sub-07.wav` | هادئ | تغيير اضطراري. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/coach/coach-07.wav` | هادئ | المدرب بيسقف للاعيبته. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-07.wav` | هادئ | نقط مهمة في سباق الصدارة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-08.wav` | هادئ | شكرا إنكم كنتم معانا. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/full/full-09.wav` | هادئ | نتقابل في ماتش جاي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-07.wav` | هادئ | المطر مش موقف الحماس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-08.wav` | هادئ | التلج مغطي أطراف الملعب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/crowd/crowd-09.wav` | هادئ | الشبورة مخبية المدرجات البعيدة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-07.wav` | هادئ | مهارة عالية. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/skill/skill-08.wav` | هادئ | هي دي الكورة الحلوة. |  |

#### الدفعة 5

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-10.wav` | هادئ | نتمنالكم فرجة ممتعة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-11.wav` | هادئ | الملعب صعب على الضيوف، والجمهور مش بيهدى. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-12.wav` | هادئ | ماتش ممكن يغير شكل الترتيب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-10.wav` | هادئ | الإيقاع بطيء في الدقايق دي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-11.wav` | هادئ | الماتش محتاج شرارة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-12.wav` | هادئ | استحواذ على الكورة، بس من غير خطورة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-10.wav` | هادئ | اختراق من الشمال... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-11.wav` | هادئ | توغل من اليمين... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-12.wav` | متحمس | لوحده قدام المرمى! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-10.wav` | صاخب | مش معقول! جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-11.wav` | صاخب | جاب جون! جاب جون! جاب جون! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-12.wav` | صاخب | جون تاريخي! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-10.wav` | هادئ | زمايله بيحضنوه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-11.wav` | هادئ | المدرب بيحتفل على الخط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-12.wav` | هادئ | الجون ده بيغير كل حاجة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-10.wav` | هادئ | الفرق بيكبر. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-11.wav` | هادئ | يا ترى الخسران هيرجع للماتش؟ |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/score/score-12.wav` | هادئ | التعادل يرضي حد؟ |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-10.wav` | هادئ | هيندم على الفرصة دي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-11.wav` | هادئ | الجمهور حاطط إيده على راسه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/miss/miss-12.wav` | هادئ | المدرب مش مصدق اللي شايفه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-10.wav` | هادئ | رد فعل سريع. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-11.wav` | هادئ | كانت رايحة الشبكة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/save/save-12.wav` | هادئ | الحارس بيزعق في دفاعه. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-10.wav` | متحمس | ضيعها! فوق العارضة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-11.wav` | متحمس | في القائم! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-12.wav` | هادئ | أعصاب حديد. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/shootout/shootout-10.wav` | هادئ | ضربة حاسمة... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-10.wav` | هادئ | إيد واضحة في الإعادة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-11.wav` | هادئ | أوفسايد بفرق بسيط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/var/var-12.wav` | هادئ | التكنولوجيا حسمت الجدل. |  |

#### الدفعة 6

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-13.wav` | هادئ | المطر نازل، والنجيلة بتزحلق. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-14.wav` | هادئ | برد جامد الليلة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/intro/intro-15.wav` | هادئ | الحر شديد، واللياقة هتفرق. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-13.wav` | هادئ | صراع على الكورة في النص. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-14.wav` | هادئ | الكورة طلعت رمية تماس. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-15.wav` | هادئ | الحكم متابع من قريب. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-13.wav` | هادئ | بيراوغ الأول... والتاني... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-14.wav` | هادئ | الدفاع بيرجع لورا... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-15.wav` | متحمس | فرصة سانحة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-13.wav` | صاخب | في الزاوية العليا! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-14.wav` | صاخب | في الزاوية البعيدة! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-15.wav` | صاخب | من تحت الحارس! |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-13.wav` | هادئ | لازم رد فعل سريع دلوقتي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal-after/goal-after-14.wav` | هادئ | سكوت في مدرجات الضيوف. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/penalty/penalty-13.wav` | هادئ | الحكم بيقول تتعاد. |  |

#### الدفعة 7

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-16.wav` | هادئ | المدرب بيوجه لاعيبته من على الخط. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-17.wav` | هادئ | الجمهور عايز هجوم. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-18.wav` | هادئ | هدوء قبل العاصفة؟ |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/attack/attack-16.wav` | هادئ | رافع راسه وبيدور على زميل... |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/goal/goal-16.wav` | صاخب | صاروخ ميترجعش! |  |

#### الدفعة 8

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-19.wav` | هادئ | كل فريق عامل حساب التاني. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-20.wav` | هادئ | الاستحواذ لصاحب الأرض. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-21.wav` | هادئ | الضيوف مستنيين المرتدة. |  |

#### الدفعة 9

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-22.wav` | هادئ | كورة طويلة لقدام. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-23.wav` | هادئ | قطع حلو في النص. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-24.wav` | هادئ | غلطة بسيطة في التمريرة. |  |

#### الدفعة 10

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-25.wav` | هادئ | اللياقة بدأت تبان. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-26.wav` | هادئ | المساحات بتضيق. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-27.wav` | هادئ | الفريق بيطلع لقدام. |  |

#### الدفعة 11

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-28.wav` | هادئ | رجوع للدفاع بسرعة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-29.wav` | هادئ | مفيش حاجة تذكر لحد دلوقتي. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-30.wav` | هادئ | الماتش متكافئ. |  |

#### الدفعة 12

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-31.wav` | هادئ | الأعصاب مشدودة. |  |
| ✅ مكتمل | حمزة | `audio/raw/ar/calm/calm-32.wav` | هادئ | كل دقيقة الضغط بيزيد. |  |

#### أصوات الملعب

| الحالة | من | الملف | النبرة | النص | ملاحظة |
|---|---|---|---|---|---|
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-bed-calm.ogg` |  | خلفية الجمهور الهادئة (حلقة 30 ثانية) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-bed-tense.ogg` |  | خلفية متوترة ترتفع مع الهجمة (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-bed-loud.ogg` |  | خلفية صاخبة بعد الهدف (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-oh.ogg` |  | آه جماعية بعد فرصة ضائعة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-goal.ogg` |  | انفجار الهدف |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-goal-away.ogg` |  | هدف الضيف: صيحة صغيرة وصمت |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-boo.ogg` |  | استهجان |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-whistle.ogg` |  | صفير الجمهور |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-applause.ogg` |  | تصفيق |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-chant-1.ogg` |  | أهزوجة عامة 1 (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-chant-2.ogg` |  | أهزوجة عامة 2 (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-drums.ogg` |  | طبول الألتراس (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-count.ogg` |  | العد التنازلي قبل ركلة الجزاء: صمت ثم همهمة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/crowd-heartbeat.ogg` |  | نبض قلب قبل الجزاء والضربة الحرة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/whistle-short.ogg` |  | صافرة قصيرة (خطأ) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/whistle-long.ogg` |  | صافرة طويلة (ركلة جزاء) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/whistle-half.ogg` |  | صافرتان (الاستراحة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/whistle-end.ogg` |  | ثلاث صافرات (النهاية) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-pass.ogg` |  | لمسة تمرير |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-shot.ogg` |  | ضربة قوية |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-header.ogg` |  | رأسية |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-net.ogg` |  | الكرة في الشباك |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-post.ogg` |  | القائم: رنين معدني |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-bar.ogg` |  | العارضة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-catch.ogg` |  | الحارس يمسك الكرة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-punch.ogg` |  | لكمة الحارس |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ball-bounce.ogg` |  | ارتداد على العشب |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/slide.ogg` |  | تزحلق على العشب |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/slide-wet.ogg` |  | تزحلق على عشب مبتل |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/fall.ogg` |  | سقوط لاعب |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/step-run.ogg` |  | خطوات الجري (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/rain.ogg` |  | مطر (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/wind.ogg` |  | رياح (حلقة) |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/thunder.ogg` |  | رعد بعيد |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/pyro.ogg` |  | اشتعال شمروخ |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/fireworks.ogg` |  | ألعاب نارية |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/var-beep.ogg` |  | نغمة الفار |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/board-beep.ogg` |  | نغمة لوحة التبديل |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ui-confirm.ogg` |  | تأكيد أمر المدرب |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/ui-applied.ogg` |  | نغمة تطبيق الأمر في الدقيقة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/sting-goal.ogg` |  | نغمة البث للهدف |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/sting-card.ogg` |  | نغمة البطاقة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/sting-half.ogg` |  | نغمة الاستراحة |  |
| ⬜ لم يتم العمل عليه | حمزة | `audio/raw/sfx/sting-intro.ogg` |  | موسيقى بداية البث (8 ثوان) |  |

