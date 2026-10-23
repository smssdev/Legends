# دليل حمزة: الصوت والمجسمات

> **مرجعك.** فيه ما تعمله بالترتيب، وروابط كل أداة، والسكربتات الجاهزة وكيف تشغّلها، وكيف تسلّم. كله **مجاني، ولا دولار واحد**.
>
> **قرار صاحب المشروع (2026-10-23):** حمزة يراجع كل PR كما هو، **ومعه** يجهّز ما ينفعنا من الصوت والمجسمات بلا Unity، فيجده سليمان وClaude جاهزاً حين يصلون لسبرنته (`PLAN.md` القسم 9).

## لماذا هذا وليس الصور

الصور المسطحة لا تدخل محاكاة Unity: كل صورة لقطة من زاوية واحدة، وكاميرا Unity تتحرك. فلا صور جديدة. الذي يدخل Unity **مجسمات ثلاثية الأبعاد**، و**أصوات**. وهذا ما تجهّزه هنا.

## الأدوات (كلها مجانية)

| الأداة | الرابط | لماذا |
|---|---|---|
| **Blender** | https://www.blender.org/download/ | يشغّل سكربتاتنا، وتفتح فيه المجسمات وتعدّلها بيدك إن أردت |
| **MakeHuman** | http://www.makehumancommunity.org/ | برنامج الأجسام البشرية (رخصة CC0): تصمم فيه الوجوه والبنى وتختار الشعر |
| **MPFB2** (إضافة MakeHuman لـ Blender) | https://static.makehumancommunity.org/mpfb/index.html | نفس MakeHuman داخل Blender، وبه يصنع Claude اللاعبين النهائيين في Sprint 3 |
| **Freesound** | https://freesound.org | أصوات الملعب. **فلتر الرخصة: Creative Commons 0 فقط** |
| **Audacity** | https://www.audacityteam.org/download/ | قص الأصوات وتوحيد مستواها وصنع الحلقات |
| **Git** | https://git-scm.com/download/win | لرفع ما تصنعه |

**تجهيز جهازك مرة واحدة (ويندوز):**
1. ثبّت Blender وGit وAudacity من الروابط (أو `winget install --id BlenderFoundation.Blender -e` و`winget install --id Git.Git -e`).
2. `git clone https://github.com/smssdev/Legends.git C:\Legends-hamza`
3. **لسكربت الناس فقط:** ملفات MakeHuman الأصلية في `tools\unity\art\makehuman\`:
   - `base.obj` من https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/3dobjs/base.obj
   - و`makehuman\data\targets.npz` من حزمة MakeHuman على PyPI: https://pypi.org/project/makehuman/1.3.2/#files (نزّل الملف `.whl`، وغيّر امتداده إلى `.zip`، وانسخ منه المجلد `makehuman` كما هو).

**تشغيل أي سكربت** (من مجلد المستودع، في PowerShell):
```
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools\unity\art\<السكربت>.py
```
(غيّر رقم النسخة حسب ما ثبّت.) كل سكربت يكتب المجسم FBX في `unity\Assets\Legends\Art\` وصورة للحكم عليه في `unity\Reference\art\`. **افتح الصورة، وغيّر الأرقام أو الألوان في رأس السكربت، وشغّله مرة أخرى، حتى ترضى.**

---

## المهام بالترتيب

### 1. أصوات الملعب الـ44 (يحتاجها Sprint 7، ابدأ بها)

**المطلوب:** كل صوت في الجدول، **برخصة CC0 فقط** من Freesound (أو تسجيلك أنت، أو مولّد)، باسمه بالضبط في `audio\raw\sfx\`.

**القواعد:**
- **CC0 فقط.** في Freesound: ابحث، ثم من اليسار **License ← Creative Commons 0**. لا CC-BY ولا غيرها.
- **الصيغة:** OGG أو WAV، 44.1 كيلوهرتز. وطّد المستوى (Audacity ← Effect ← Normalize ← -1 dB).
- **الحلقات** (المكتوب عندها حلقة): 30 ثانية تقريباً، ولا يُسمع مكان التكرار (اقصص عند صوت متشابه، وCrossfade نصف ثانية).
- **لا موسيقى محمية، ولا معلق، ولا أسماء.**
- **سجّل مصدر كل ملف** في `audio\raw\sfx\sources.csv`: سطر لكل صوت بالشكل `الملف,الرابط,الرخصة` (مثلاً `crowd-oh.ogg,https://freesound.org/s/12345/,CC0`).

| # | الملف | الصوت |
|---|---|---|
| 1 | `crowd-bed-calm.ogg` | خلفية الجمهور الهادئة (حلقة 30 ثانية) |
| 2 | `crowd-bed-tense.ogg` | خلفية متوترة ترتفع مع الهجمة (حلقة) |
| 3 | `crowd-bed-loud.ogg` | خلفية صاخبة بعد الهدف (حلقة) |
| 4 | `crowd-oh.ogg` | آه جماعية بعد فرصة ضائعة |
| 5 | `crowd-goal.ogg` | انفجار الهدف |
| 6 | `crowd-goal-away.ogg` | هدف الضيف: صيحة صغيرة وصمت |
| 7 | `crowd-boo.ogg` | استهجان |
| 8 | `crowd-whistle.ogg` | صفير الجمهور |
| 9 | `crowd-applause.ogg` | تصفيق |
| 10 | `crowd-chant-1.ogg` | أهزوجة عامة 1 (حلقة) |
| 11 | `crowd-chant-2.ogg` | أهزوجة عامة 2 (حلقة) |
| 12 | `crowd-drums.ogg` | طبول الألتراس (حلقة) |
| 13 | `crowd-count.ogg` | العد التنازلي قبل ركلة الجزاء: صمت ثم همهمة |
| 14 | `crowd-heartbeat.ogg` | نبض قلب قبل الجزاء والضربة الحرة |
| 15 | `whistle-short.ogg` | صافرة قصيرة (خطأ) |
| 16 | `whistle-long.ogg` | صافرة طويلة (ركلة جزاء) |
| 17 | `whistle-half.ogg` | صافرتان (الاستراحة) |
| 18 | `whistle-end.ogg` | ثلاث صافرات (النهاية) |
| 19 | `ball-pass.ogg` | لمسة تمرير |
| 20 | `ball-shot.ogg` | ضربة قوية |
| 21 | `ball-header.ogg` | رأسية |
| 22 | `ball-net.ogg` | الكرة في الشباك |
| 23 | `ball-post.ogg` | القائم: رنين معدني |
| 24 | `ball-bar.ogg` | العارضة |
| 25 | `ball-catch.ogg` | الحارس يمسك الكرة |
| 26 | `ball-punch.ogg` | لكمة الحارس |
| 27 | `ball-bounce.ogg` | ارتداد على العشب |
| 28 | `slide.ogg` | تزحلق على العشب |
| 29 | `slide-wet.ogg` | تزحلق على عشب مبتل |
| 30 | `fall.ogg` | سقوط لاعب |
| 31 | `step-run.ogg` | خطوات الجري (حلقة) |
| 32 | `rain.ogg` | مطر (حلقة) |
| 33 | `wind.ogg` | رياح (حلقة) |
| 34 | `thunder.ogg` | رعد بعيد |
| 35 | `pyro.ogg` | اشتعال شمروخ |
| 36 | `fireworks.ogg` | ألعاب نارية |
| 37 | `var-beep.ogg` | نغمة الفار |
| 38 | `board-beep.ogg` | نغمة لوحة التبديل |
| 39 | `ui-confirm.ogg` | تأكيد أمر المدرب |
| 40 | `ui-applied.ogg` | نغمة تطبيق الأمر في الدقيقة |
| 41 | `sting-goal.ogg` | نغمة البث للهدف |
| 42 | `sting-card.ogg` | نغمة البطاقة |
| 43 | `sting-half.ogg` | نغمة الاستراحة |
| 44 | `sting-intro.ogg` | موسيقى بداية البث (8 ثوانٍ) |

**نصيحة بحث في Freesound:** «stadium crowd»، «football crowd cheer»، «crowd groan»، «referee whistle»، «ball kick»، «goal net»، «metal post hit»، «rain loop»، «flare ignite»، «drums ultras».

### 2. الكرة

**السكربت:** `tools\unity\art\ball.py`. كرة Legends بـ32 قطعة وبمقاس 22 سم حقيقي، بألوان الهوية.

**جرّب:**
- `... -P tools\unity\art\ball.py -- --panels ivory --patches navy` (الحالي)
- `... -- --panels navy --patches gold`
- `... -- --panels ivory --patches gold`

**المطلوب:** اختر الأجمل وأرسل الصورة لسليمان ليعتمدها. والصورة الحالية في `unity\Reference\art\ball.png`.

### 3. ملحقات الملعب

**السكربت:** `tools\unity\art\props.py`، بمقاسات قانون اللعبة:
- **المرمى** 7.32 × 2.44 م بشبكة حقيقية (خانات 12 سم).
- **راية الركنية** 1.5 م.
- **لوحة LED** باسم LEGENDS.
- **دكة البدلاء** بسقف شفاف ومقاعد.
- **صارية الكشافات** 40 م.

**جرّب:** قطعة واحدة: `... -- --only goal` (أو `flag`، `boards`، `dugout`، `mast`).

**المطلوب:** راجع كل قطعة في `unity\Reference\art\props.png`، وعدّل ما لا يعجبك (الألوان والمقاسات في رأس السكربت)، وإن أردت حسّنها بيدك في Blender (افتح FBX من `unity\Assets\Legends\Art\Props\`) واحفظها FBX بنفس الاسم.

### 4. ملعب الأرينا ثلاثي الأبعاد

**السكربت:** `tools\unity\art\stadium.py`. الأرينا كاملة على شكل صورنا (`unity\Reference\stadiums\arena\`):
- وعاء مغلق، وطابقان بجمهورنا الحقيقي من صورنا.
- شريط LED بين الطابقين.
- سقف على جمالونات حديد، وكشافات تحت حافته، ونفق اللاعبين.

**جرّب:** `... -- --seats-lower 26 --seats-upper 24` (صفوف أكثر = ملعب أكبر)، أو غيّر الأرقام في رأس السكربت (`CORNER` استدارة الزوايا، و`RISE_UPPER` ميل الطابق العلوي...).

**المطلوب:**
1. قارن الصورتين `stadium-arena.png` (من الجو) و`stadium-arena-pitch.png` (من خط التماس) بصور الأرينا الأصلية، واضبط الأرقام حتى يقترب الشكل.
2. **إن عندك وقت ومهارة:** افتح `Arena.fbx` في Blender وأضف التفاصيل بيدك: درج الممرات بين المدرجات، والبوابات، وغرفة الإعلام، والشاشة الكبيرة. واحفظه `unity\Assets\Legends\Art\Stadium\Arena.fbx`.
3. **بعدها الكلاسيكي** (نهاراً، مدرجات مفتوحة، سقف جزئي): `... -- --name Classic`، وعدّل ليقترب من `unity\Reference\stadiums\classic\`.

### 5. شكل الناس (قبل Sprint 3)

**السكربت:** `tools\unity\art\people.py`. يصنع من MakeHuman الأصلي:
- ثلاثة لاعبين، والحارس بقفازيه، والحكم، والمساعد برايته، والمدرب.
- الصورة الحالية `unity\Reference\art\people.png`، والقريبة بـ `-- --close`.

**جرّب:** غيّر قائمة `PEOPLE` في رأس السكربت: لون البشرة، و`muscle` و`weight` (من 0 إلى 1)، وألوان الطقم. ثم شغّل وقارن.

**المطلوب في برنامج MakeHuman** (هذا عمل فني يفيدنا كثيراً):
1. **4 وجوه** مختلفة لرجال بين 20 و35 سنة، لا تشبه أي لاعب حقيقي (Modelling ← Face).
2. **3 بنى:** نحيف سريع، ومتوسط، وقوي (Modelling ← Main: Muscle وWeight وHeight).
3. **الشعر القصير:** من الشعر المرفق مع MakeHuman برخصة CC0 فقط (Geometries ← Hair)، اختر أفضل 4 قصات قصيرة لرياضيين.
4. **احفظ كل شخصية** (Files ← Save) بملف `.mhm` في `unity\Reference\players\mhm\`، باسم واضح مثل `face-1-slim.mhm`. هذه الملفات يقرأها Claude في Sprint 3 فيصنع منها لاعبي Legends.

---

## كيف تسلّم

1. اعمل فرعاً باسمك: `git checkout -b hamza/art`
2. أضف ما صنعته: `git add audio/raw/sfx unity/Assets/Legends/Art unity/Reference` ثم `git commit -m "أصوات الملعب والمجسمات"` ثم `git push -u origin hamza/art`
3. افتح PR على GitHub، وسليمان يقول لـ Claude: «راجع PR حمزة». Claude يفحص الرخص والأسماء والمقاسات ويعطيك ملاحظاته.

## ممنوع

- **أي شيء مدفوع**، ولو دولار واحد.
- **رخصة غير CC0** في الأصوات والأصول الجاهزة (إلا ما تصنعه بنفسك).
- **شعارات أو أسماء أندية أو وجوه أشخاص حقيقيين** في أي مجسم.
- **التعديل على كود اللعبة:** ملفاتك هي الأصوات والمجسمات والصور المرجعية فقط.
