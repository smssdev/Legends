# دليل حمزة: أصوات الملعب والتعليق الحقيقي

لك مهمتان:
1. **أصوات الملعب الـ44** من موقع **Freesound** (الأقسام 1 إلى 5).
2. **التعليق الحقيقي** للمعلقين (القسم 6، قرار صاحب المشروع 2026-10-25): تنزّل التسجيلات وتصنّف مقاطعها، وClaude يقصها ويربطها بالمحاكي.

في أصوات الملعب مهمتك **فقط** أن تختار 44 صوتاً، وتقص الجزء المناسب من كل صوت، وتحفظه بالاسم المطلوب. وكل ما بعد ذلك يعمله Claude مع سليمان في Sprint 7 [PLAN 9]:

- مراجعة الرخص.
- توحيد مستوى الصوت.
- جعل الحلقات تتكرر بلا فاصل.
- إدخال الأصوات إلى Unity.

والمجسمات والملاعب والصور ليست من عملك.

## 1. التجهيز (مرة واحدة)

| ماذا | أين | ملاحظة |
|---|---|---|
| حساب في Freesound | https://freesound.org/home/register/ | مجاني، والتنزيل يحتاج تسجيل الدخول |
| برنامج Audacity | https://www.audacityteam.org/download/ | مجاني، للقص والحفظ |
| مجلد الحفظ | `audio/raw/sfx/` في المستودع | كل الأصوات الـ44 في هذا المجلد وحده، بلا مجلدات فرعية |

## 2. خطوات كل صوت

1. **ابحث:**
   - اضغط رابط «جملة البحث» في جدول الصوت (القسم 4).
   - الرابط يعرض أصواتاً برخصة **CC0** فقط، فلا تغيّر فلتر الرخصة.
   - لو لم يعجبك شيء فجرّب رابط «إن لم تجد».
2. **اسمع واختر:**
   - اسمع عدة نتائج، واختر الأقرب لوصف «ما نريده».
   - تأكد أن الرخصة تحت الصوت مكتوب فيها **Creative Commons 0**.
3. **نزّل:** زر **Download**.
4. **افتح في Audacity:** File ← Open.
5. **قص:**
   - حدد بالماوس أنظف جزء بالمدة المطلوبة في الجدول.
   - Edit ← Remove Special ← Trim Audio، فيبقى المحدد وحده.
6. **نظّف الأطراف:**
   - حدد أول جزء صغير من الصوت (عُشر ثانية تقريباً) ثم Effect ← Fade In.
   - وحدد آخر جزء صغير منه ثم Effect ← Fade Out.
   - هذا يمنع الطقة في أول الصوت وآخره.
7. **ارفع المستوى:**
   - حدد الكل (Ctrl+A).
   - Effect ← Volume and Compression ← Normalize على **-1 dB**.
8. **احفظ:**
   - File ← Export Audio.
   - النوع **Ogg Vorbis**، والجودة 6 (الافتراضي مناسب).
   - **الاسم بالضبط كما في عمود «اسم الملف»**: حروف إنجليزية صغيرة وشرطات، بلا مسافات ولا أرقام زائدة.
   - المكان: `audio/raw/sfx/`.
9. **سجّل المصدر:** أضف سطراً في الملف `audio/raw/sfx/sources.txt`:
   - اسم الملف.
   - ثم مسافة (Tab).
   - ثم رابط صفحة الصوت في Freesound.
   - مثال: `ball-shot.ogg	https://freesound.org/people/xxx/sounds/12345/`

### الحلقات (المكتوب عندها «حلقة»)

- هذه أصوات تتكرر طوال المباراة: الجمهور، والهتاف، والطبول، والمطر، والرياح، والخطوات، والنبض.
- اختر جزءاً **ثابت المستوى** بالمدة المطلوبة، بلا صيحة مفاجئة ولا صافرة ولا كلام.
- لا تحاول جعلها تتكرر بلا فاصل: هذا عمل Claude.

## 3. الممنوع

- **أي رخصة غير CC0**، حتى لو كان الصوت ممتازاً. فلا Attribution ولا Noncommercial.
- أي صوت مدفوع أو من موقع آخر.
- كلام مفهوم أو أسماء أندية أو لاعبين أو أغانٍ معروفة داخل الصوت.
- صوت معلق، أو مذيع، أو إعلان داخلي في الملعب.
- أصوات فيها ضجيج واضح: سيارات، ورياح على الميكروفون، وأشخاص قريبون جداً من الميكروفون.

## 4. الأصوات الـ44

- كلها تُحفظ في `audio/raw/sfx/`.
- اضغط جملة البحث لتفتح نتائج CC0 مباشرة.
- المدة هي طول الجزء الذي تقصه.

### أ. الجمهور (14 صوتاً)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 1 | `crowd-bed-calm.ogg` | جمهور ملعب كبير في لحظة عادية: همهمة مستمرة، بلا هتاف عالٍ ولا صافرة ولا صوت معلق | [`stadium crowd ambience`](https://freesound.org/search/?q=stadium+crowd+ambience&f=license%3A%22Creative+Commons+0%22) | [`football crowd background`](https://freesound.org/search/?q=football+crowd+background&f=license%3A%22Creative+Commons+0%22) | 40 ث (حلقة) |
| 2 | `crowd-bed-tense.ogg` | جمهور يترقب هجمة: الصوت يعلو تدريجياً ويشتد | [`crowd anticipation stadium`](https://freesound.org/search/?q=crowd+anticipation+stadium&f=license%3A%22Creative+Commons+0%22) | [`crowd rising tension`](https://freesound.org/search/?q=crowd+rising+tension&f=license%3A%22Creative+Commons+0%22) | 40 ث (حلقة) |
| 3 | `crowd-bed-loud.ogg` | جمهور متحمس بعد هدف: صخب وهتاف مستمر بلا توقف | [`stadium crowd cheering loop`](https://freesound.org/search/?q=stadium+crowd+cheering+loop&f=license%3A%22Creative+Commons+0%22) | [`football crowd loud`](https://freesound.org/search/?q=football+crowd+loud&f=license%3A%22Creative+Commons+0%22) | 40 ث (حلقة) |
| 4 | `crowd-oh.ogg` | آآه جماعية بعد فرصة ضائعة: تعلو ثم تهبط | [`crowd ooh disappointed`](https://freesound.org/search/?q=crowd+ooh+disappointed&f=license%3A%22Creative+Commons+0%22) | [`crowd groan`](https://freesound.org/search/?q=crowd+groan&f=license%3A%22Creative+Commons+0%22) | 2 إلى 3 ث |
| 5 | `crowd-goal.ogg` | انفجار الجمهور لحظة الهدف: صرخة كبيرة ثم هتاف | [`stadium crowd goal cheer`](https://freesound.org/search/?q=stadium+crowd+goal+cheer&f=license%3A%22Creative+Commons+0%22) | [`football goal celebration crowd`](https://freesound.org/search/?q=football+goal+celebration+crowd&f=license%3A%22Creative+Commons+0%22) | 8 إلى 10 ث |
| 6 | `crowd-goal-away.ogg` | هدف للضيف: صيحة صغيرة من بعيد (جمهور قليل) ثم يهدأ | [`small crowd cheer distant`](https://freesound.org/search/?q=small+crowd+cheer+distant&f=license%3A%22Creative+Commons+0%22) | [`distant cheer short`](https://freesound.org/search/?q=distant+cheer+short&f=license%3A%22Creative+Commons+0%22) | 4 ث |
| 7 | `crowd-boo.ogg` | الجمهور يستهجن: صيحات «بووو» | [`crowd booing`](https://freesound.org/search/?q=crowd+booing&f=license%3A%22Creative+Commons+0%22) | [`stadium boo`](https://freesound.org/search/?q=stadium+boo&f=license%3A%22Creative+Commons+0%22) | 5 ث |
| 8 | `crowd-whistle.ogg` | الجمهور يصفّر احتجاجاً بأفواههم (ليست صافرة حكم) | [`crowd whistling stadium`](https://freesound.org/search/?q=crowd+whistling+stadium&f=license%3A%22Creative+Commons+0%22) | [`crowd whistle protest`](https://freesound.org/search/?q=crowd+whistle+protest&f=license%3A%22Creative+Commons+0%22) | 5 ث |
| 9 | `crowd-applause.ogg` | تصفيق جمهور كبير بالأيدي | [`stadium applause`](https://freesound.org/search/?q=stadium+applause&f=license%3A%22Creative+Commons+0%22) | [`large crowd applause`](https://freesound.org/search/?q=large+crowd+applause&f=license%3A%22Creative+Commons+0%22) | 5 إلى 6 ث |
| 10 | `crowd-chant-1.ogg` | هتاف جماعي بإيقاع: تصفيق منتظم وأصوات بلا كلمات مفهومة | [`crowd chant clapping rhythm`](https://freesound.org/search/?q=crowd+chant+clapping+rhythm&f=license%3A%22Creative+Commons+0%22) | [`football chant crowd`](https://freesound.org/search/?q=football+chant+crowd&f=license%3A%22Creative+Commons+0%22) | 30 ث (حلقة) |
| 11 | `crowd-chant-2.ogg` | هتاف جماعي ثانٍ مختلف عن الأول | [`football fans chanting`](https://freesound.org/search/?q=football+fans+chanting&f=license%3A%22Creative+Commons+0%22) | [`crowd chanting stadium`](https://freesound.org/search/?q=crowd+chanting+stadium&f=license%3A%22Creative+Commons+0%22) | 30 ث (حلقة) |
| 12 | `crowd-drums.ogg` | طبول الألتراس في المدرج بإيقاع ثابت | [`stadium drums`](https://freesound.org/search/?q=stadium+drums&f=license%3A%22Creative+Commons+0%22) | [`ultras drum crowd`](https://freesound.org/search/?q=ultras+drum+crowd&f=license%3A%22Creative+Commons+0%22) | 30 ث (حلقة) |
| 13 | `crowd-count.ogg` | الجمهور يصمت قبل ركلة الجزاء: هدوء ثم همهمة خفيفة | [`crowd hush`](https://freesound.org/search/?q=crowd+hush&f=license%3A%22Creative+Commons+0%22) | [`crowd quiet murmur`](https://freesound.org/search/?q=crowd+quiet+murmur&f=license%3A%22Creative+Commons+0%22) | 6 ث |
| 14 | `crowd-heartbeat.ogg` | نبض قلب واضح وبطيء (يُسمع قبل الجزاء) | [`heartbeat`](https://freesound.org/search/?q=heartbeat&f=license%3A%22Creative+Commons+0%22) | [`heart beat slow`](https://freesound.org/search/?q=heart+beat+slow&f=license%3A%22Creative+Commons+0%22) | 8 ث (حلقة) |

### ب. صافرة الحكم (4 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 15 | `whistle-short.ogg` | صافرة حكم واحدة قصيرة (خطأ) | [`referee whistle short`](https://freesound.org/search/?q=referee+whistle+short&f=license%3A%22Creative+Commons+0%22) | [`whistle blow single`](https://freesound.org/search/?q=whistle+blow+single&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |
| 16 | `whistle-long.ogg` | صافرة حكم واحدة طويلة (ركلة جزاء) | [`referee whistle long`](https://freesound.org/search/?q=referee+whistle+long&f=license%3A%22Creative+Commons+0%22) | [`whistle long blow`](https://freesound.org/search/?q=whistle+long+blow&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 17 | `whistle-half.ogg` | صافرتان متتاليتان (نهاية الشوط الأول) | [`referee whistle double`](https://freesound.org/search/?q=referee+whistle+double&f=license%3A%22Creative+Commons+0%22) | [`referee whistle two`](https://freesound.org/search/?q=referee+whistle+two&f=license%3A%22Creative+Commons+0%22) | 2 ث |
| 18 | `whistle-end.ogg` | ثلاث صافرات، الأخيرة أطول (نهاية المباراة) | [`final whistle`](https://freesound.org/search/?q=final+whistle&f=license%3A%22Creative+Commons+0%22) | [`referee whistle three times`](https://freesound.org/search/?q=referee+whistle+three+times&f=license%3A%22Creative+Commons+0%22) | 3 ث |

### ج. الكرة (9 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 19 | `ball-pass.ogg` | ركلة خفيفة لكرة قدم (تمريرة) | [`soccer ball pass kick soft`](https://freesound.org/search/?q=soccer+ball+pass+kick+soft&f=license%3A%22Creative+Commons+0%22) | [`football kick light`](https://freesound.org/search/?q=football+kick+light&f=license%3A%22Creative+Commons+0%22) | ثلث ثانية |
| 20 | `ball-shot.ogg` | ركلة قوية لكرة قدم (تسديدة) | [`soccer ball kick hard`](https://freesound.org/search/?q=soccer+ball+kick+hard&f=license%3A%22Creative+Commons+0%22) | [`football shot kick`](https://freesound.org/search/?q=football+shot+kick&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |
| 21 | `ball-header.ogg` | ضربة الكرة بالرأس: صوت مكتوم | [`soccer ball header`](https://freesound.org/search/?q=soccer+ball+header&f=license%3A%22Creative+Commons+0%22) | [`ball hit head`](https://freesound.org/search/?q=ball+hit+head&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |
| 22 | `ball-net.ogg` | الكرة تدخل الشباك وتهزها | [`goal net ball`](https://freesound.org/search/?q=goal+net+ball&f=license%3A%22Creative+Commons+0%22) | [`ball hitting net`](https://freesound.org/search/?q=ball+hitting+net&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 23 | `ball-post.ogg` | الكرة تضرب القائم: رنين معدني | [`goal post hit metal`](https://freesound.org/search/?q=goal+post+hit+metal&f=license%3A%22Creative+Commons+0%22) | [`ball hit metal pole`](https://freesound.org/search/?q=ball+hit+metal+pole&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 24 | `ball-bar.ogg` | الكرة تضرب العارضة: رنين أخف من القائم | [`crossbar hit`](https://freesound.org/search/?q=crossbar+hit&f=license%3A%22Creative+Commons+0%22) | [`ball hits metal bar`](https://freesound.org/search/?q=ball+hits+metal+bar&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 25 | `ball-catch.ogg` | الحارس يمسك الكرة بيديه (بالقفازات) | [`goalkeeper catch ball`](https://freesound.org/search/?q=goalkeeper+catch+ball&f=license%3A%22Creative+Commons+0%22) | [`catch ball hands`](https://freesound.org/search/?q=catch+ball+hands&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |
| 26 | `ball-punch.ogg` | الحارس يبعد الكرة بقبضته | [`punch ball`](https://freesound.org/search/?q=punch+ball&f=license%3A%22Creative+Commons+0%22) | [`fist hit ball`](https://freesound.org/search/?q=fist+hit+ball&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |
| 27 | `ball-bounce.ogg` | الكرة ترتد على العشب | [`ball bounce grass`](https://freesound.org/search/?q=ball+bounce+grass&f=license%3A%22Creative+Commons+0%22) | [`soccer ball bounce`](https://freesound.org/search/?q=soccer+ball+bounce&f=license%3A%22Creative+Commons+0%22) | نصف ثانية |

### د. اللاعبون (4 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 28 | `slide.ogg` | لاعب يتزحلق على العشب (تدخل) | [`slide tackle grass`](https://freesound.org/search/?q=slide+tackle+grass&f=license%3A%22Creative+Commons+0%22) | [`sliding on grass`](https://freesound.org/search/?q=sliding+on+grass&f=license%3A%22Creative+Commons+0%22) | 1.2 ث |
| 29 | `slide-wet.ogg` | تزحلق على عشب مبتل: فيه رذاذ ماء | [`wet grass slide`](https://freesound.org/search/?q=wet+grass+slide&f=license%3A%22Creative+Commons+0%22) | [`slide wet ground`](https://freesound.org/search/?q=slide+wet+ground&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 30 | `fall.ogg` | لاعب يسقط على العشب | [`body fall grass`](https://freesound.org/search/?q=body+fall+grass&f=license%3A%22Creative+Commons+0%22) | [`body fall ground`](https://freesound.org/search/?q=body+fall+ground&f=license%3A%22Creative+Commons+0%22) | 1 ث |
| 31 | `step-run.ogg` | خطوات جري على العشب | [`running footsteps grass`](https://freesound.org/search/?q=running+footsteps+grass&f=license%3A%22Creative+Commons+0%22) | [`footsteps running grass`](https://freesound.org/search/?q=footsteps+running+grass&f=license%3A%22Creative+Commons+0%22) | 10 ث (حلقة) |

### هـ. الطقس والمؤثرات (5 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 32 | `rain.ogg` | مطر متوسط مستمر، بلا رعد | [`rain loop`](https://freesound.org/search/?q=rain+loop&f=license%3A%22Creative+Commons+0%22) | [`steady rain`](https://freesound.org/search/?q=steady+rain&f=license%3A%22Creative+Commons+0%22) | 40 ث (حلقة) |
| 33 | `wind.ogg` | رياح مستمرة في مكان مفتوح | [`wind loop`](https://freesound.org/search/?q=wind+loop&f=license%3A%22Creative+Commons+0%22) | [`wind open field`](https://freesound.org/search/?q=wind+open+field&f=license%3A%22Creative+Commons+0%22) | 40 ث (حلقة) |
| 34 | `thunder.ogg` | رعد من بعيد | [`distant thunder`](https://freesound.org/search/?q=distant+thunder&f=license%3A%22Creative+Commons+0%22) | [`thunder rumble`](https://freesound.org/search/?q=thunder+rumble&f=license%3A%22Creative+Commons+0%22) | 5 ث |
| 35 | `pyro.ogg` | اشتعال شعلة (شمروخ): فحيح نار | [`flare ignite`](https://freesound.org/search/?q=flare+ignite&f=license%3A%22Creative+Commons+0%22) | [`flare burning`](https://freesound.org/search/?q=flare+burning&f=license%3A%22Creative+Commons+0%22) | 3 ث |
| 36 | `fireworks.ogg` | ألعاب نارية من بعيد | [`fireworks distant`](https://freesound.org/search/?q=fireworks+distant&f=license%3A%22Creative+Commons+0%22) | [`fireworks`](https://freesound.org/search/?q=fireworks&f=license%3A%22Creative+Commons+0%22) | 6 ث |

### و. النغمات (4 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 37 | `var-beep.ogg` | نغمة إلكترونية قصيرة (مراجعة الفار) | [`electronic beep short`](https://freesound.org/search/?q=electronic+beep+short&f=license%3A%22Creative+Commons+0%22) | [`alert beep`](https://freesound.org/search/?q=alert+beep&f=license%3A%22Creative+Commons+0%22) | 1 ث |
| 38 | `board-beep.ogg` | نغمتان صاعدتان (لوحة التبديل) | [`two tone beep`](https://freesound.org/search/?q=two+tone+beep&f=license%3A%22Creative+Commons+0%22) | [`double beep`](https://freesound.org/search/?q=double+beep&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 39 | `ui-confirm.ogg` | نقرة تأكيد ناعمة (المدرب أرسل أمراً) | [`ui click confirm`](https://freesound.org/search/?q=ui+click+confirm&f=license%3A%22Creative+Commons+0%22) | [`soft click`](https://freesound.org/search/?q=soft+click&f=license%3A%22Creative+Commons+0%22) | ثلث ثانية |
| 40 | `ui-applied.ogg` | رنة إشعار ناعمة (الأمر طُبّق في الملعب) | [`soft notification chime`](https://freesound.org/search/?q=soft+notification+chime&f=license%3A%22Creative+Commons+0%22) | [`notification chime`](https://freesound.org/search/?q=notification+chime&f=license%3A%22Creative+Commons+0%22) | أقل من ثانية |

### ز. نغمات البث (4 أصوات)

| # | اسم الملف | ما نريده | جملة البحث | إن لم تجد | المدة |
|---|---|---|---|---|---|
| 41 | `sting-goal.ogg` | نغمة قصيرة حماسية للهدف كالقنوات الرياضية | [`sports broadcast sting`](https://freesound.org/search/?q=sports+broadcast+sting&f=license%3A%22Creative+Commons+0%22) | [`sport stinger`](https://freesound.org/search/?q=sport+stinger&f=license%3A%22Creative+Commons+0%22) | 3 ث |
| 42 | `sting-card.ogg` | نغمة «ووش» قصيرة للبطاقة | [`short whoosh sting`](https://freesound.org/search/?q=short+whoosh+sting&f=license%3A%22Creative+Commons+0%22) | [`whoosh`](https://freesound.org/search/?q=whoosh&f=license%3A%22Creative+Commons+0%22) | 1.5 ث |
| 43 | `sting-half.ogg` | نغمة انتقال للاستراحة | [`transition sting`](https://freesound.org/search/?q=transition+sting&f=license%3A%22Creative+Commons+0%22) | [`transition swoosh`](https://freesound.org/search/?q=transition+swoosh&f=license%3A%22Creative+Commons+0%22) | 3 ث |
| 44 | `sting-intro.ogg` | موسيقى بداية البث: حماسية بلا كلمات ولا لحن معروف | [`sports intro music`](https://freesound.org/search/?q=sports+intro+music&f=license%3A%22Creative+Commons+0%22) | [`epic sport intro`](https://freesound.org/search/?q=epic+sport+intro&f=license%3A%22Creative+Commons+0%22) | 8 ث |

## 5. التسليم

1. تأكد أن في `audio/raw/sfx/`:
   - 44 ملف `.ogg` بالأسماء أعلاه بالضبط.
   - و`sources.txt` فيه 44 سطراً.
2. ارفعها كما رفعت مقاطع المعلق.
3. أخبر سليمان: **«راجع أصوات الملعب»**.
4. لو بقي صوت لم تجد له شيئاً مناسباً، فاكتب اسمه في آخر `sources.txt` بكلمة `ناقص`، وClaude يبحث له.

ويمكنك تسليمها على دفعات: الجمهور والصافرة أولاً، فهما الأهم.

## 6. التعليق الحقيقي للمعلقين (X37)

**القرار:** صاحب المشروع يريد معلقاً بتعليق حقيقي (عصام الشوالي أولاً). وهو يتحمل مسؤولية مصدر التسجيلات.
- **مهمتك:** تنزيل التسجيلات ووضعها في المستودع، ثم مراجعة تصنيف المقاطع.
- **ومهمة Claude:** كل العمل التقني، أي القص والتنظيف والربط بالمحاكي والاختبار.
- **وClaude لا ينزّل التسجيلات بنفسه.**

### أ. ما تنزّله
التعليق الكامل لمباراة من نفس المعلق أفضل من المقاطع القصيرة، لأنه أغنى بالعبارات. والمطلوب كحد أدنى:

| اللحظة | ما تبحث عنه | الحد الأدنى |
|---|---|---|
| الهدف | الصرخة و«جووول»، والكلام بعد الهدف | 15 |
| الهدف المتأخر أو الحاسم | لحظاته الكبرى، أهداف الدقيقة 90 | 5 |
| الفرصة والهجمة | «انطلاقة... تسديدة...» قبل التسديد | 15 |
| التصدي | مدح الحارس | 10 |
| الضياع والقائم | «يا خسارة... القائم!» | 10 |
| ركلة الجزاء | قبلها، وهدفها، وتصديها | 8 |
| الركلة الحرة | قبلها وبعدها | 6 |
| البطاقات | الصفراء والحمراء | 8 |
| التسلل والخطأ والفار | ردوده عليها | 10 |
| البداية والاستراحة والنهاية | افتتاح المباراة وختامها | 10 |
| اللعب الهادئ | كلام عادي بين اللقطات | 20 |
| الجمهور والأجواء | كلامه عن الجماهير والملعب | 6 |

**تجنّب:**
- **الأسماء والتفاصيل الخاصة بمباراة بعينها** («ميسي»، «الريال»). اللعبة تضع أسماء لاعبيها هي، فالعبارة التي تذكر اسماً حقيقياً ستبدو خاطئة. والأفضل العبارات العامة: «يا سلام! هدف ولا أروع!».
- **الموسيقى أو الضجيج** الأعلى من صوته.

### ب. الصيغة والمكان
- **الصيغة:** أي صيغة من mp3 أو wav أو m4a أو ogg، والطويلة مقبولة لأن Claude يقصها.
- **المجلد:** `audio/raw/patches/chawali/`. ولكل معلق آخر مجلد باسمه (`medhat`، `hafid`...).
- **أسماء الملفات:** أي اسم، والأفضل تلميح مثل `goals-1.mp3` أو `full-match-final.mp3`.

### ج. التسليم
- **حتى 100 ميجا:** ترفعها من صفحة GitHub (Add file ← Upload files) إلى المجلد على فرع `main`.
- **أكبر:** مجلد Google Drive مشارك «لأي شخص لديه الرابط»، وتُرسل رابطه لـ Claude.
- **ثم:** أخبر سليمان: **«التعليق الحقيقي جاهز»**.

### د. ما يحدث بعدها (Claude)
1. **القص:** يقص التسجيلات عند وقفات المعلق، فكل عبارة ملف وحدها، وينظف الصمت والضجيج.
2. **جدول المراجعة لك:** فيه كل عبارة مع رابطها وطولها واقتراحه للحظتها.
   - تؤكد اللحظة أو تغيّرها، في 10 ثوانٍ لكل عبارة.
   - وتعلّم ما فيه اسم حقيقي بـ «حذف».
3. **حزمة الصوت:** يبنيها من الجدول، فيتكلم المعلق في المباراة في لحظته الصحيحة.
   - لا يقول عبارة قبل أن تصل الكرة، فالنتيجة لا تُكشف قبل التسديد.
   - وفي كل لحظة يختار عشوائياً من عباراتها فلا تتكرر.
4. **في قائمة المعلقين:** خيار جديد «عصام الشوالي (أصلي)» بجانب الأصوات الحالية.
5. **الاختبار:** في مباراة كاملة، وفيديو لك ولسليمان قبل الدمج.
