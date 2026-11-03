# Sprint 02: Unity: أول تشغيل والأساس والربط

| | |
|---|---|
| **الحالة** | ✅ منجز (2026-11-03)، ينتظر مراجعة حمزة |
| **المدة** | 5 أيام عمل |
| **من** | 2026-10-24 |

> **ملاحظة (2026-10-27):** حُذف التعليق العربي كله بعد هذا السبرنت (ملفاته وأدواته وكوده)، فما فيه هنا عن المعلقين العرب تاريخ فقط. والإنجليزي وحده يعمل.

## الهدف والمهام

**الهدف:** المباراة المسجلة (ليفربول ضد أرسنال) تتحرك في الأرينا داخل Unity على جهاز سليمان، ونسخة الويب منها تفتح في المتصفح، وClaude يرى المشهد بنفسه ويختبره آلياً.

**المدة:** 5 أيام (2026-10-24 إلى 2026-10-28). **أين:** جهاز سليمان.

**سليمان قبل البدء:** الخطوات أعلاه، ثم حساب Unity مجاني على unity.com.

| الرمز | المهمة | من | الملفات |
|---|---|---|---|
| U1 | **تثبيت Unity:** `unity\build.ps1 install` يثبت Unity Hub. ثم في Hub: الدخول، والرخصة Personal المجانية، و**Installs ← Install Editor ←** أحدث Unity 6 بعلامة LTS، **مع** WebGL Build Support وAndroid Build Support (ومعه OpenJDK وAndroid SDK & NDK) | سليمان بإرشاد Claude | |
| U2 | **أول فتح:** `build.ps1 setup` يصنع ملفات المشروع ويضيف الحزم (7.2). وClaude يقرأ `unity\Logs\setup.log` ويصلح كل خطأ ترجمة في الكود المكتوب سلفاً (7.13) حتى يصفو | Claude | `unity/Assets/Legends/**` |
| U3 | **أول مشهد:** `build.ps1 demo` يبني الأرينا ومشهد المباراة. سليمان يفتح `unity` في Unity Hub، ثم `Assets/Legends/Scenes/Match.unity`، ويضغط Play، ويقول ما يرى | Claude ثم سليمان | `Scenes/Match.unity` |
| U4 | **التحويل إلى URP:** أصل URP (`Assets/Legends/Quality/URP-High/Medium/Low`) مربوط بمستويات الجودة الثلاث (7.6)، وإعادة بناء المواد بـ `ArenaBuilder` فتأخذ ظلال URP وإضاءته | Claude | `Editor/Setup.cs`، `Quality/` |
| U5 | **عين Claude:** أمر `build.ps1 capture` يشغّل المشهد بلا واجهة ويلتقط صوراً في دقائق محددة (5، 20، 45، 70، 90) إلى `unity/Captures/`، فيفحصها Claude بنفسه ويرسلها لسليمان | Claude | `Editor/Capture.cs`، `build.ps1` |
| U6 | **ربط Claude بالمحرر المفتوح (اختياري):** تجربة أداة MCP مفتوحة المصدر لـ Unity. إن عملت يتحكم Claude بالمحرر مباشرة، وإلا يكمل بسطر الأوامر والصور | Claude | |
| U7 | **الاختبارات:** حزمة `Legends.Tests` (asmdef): EditMode لقارئ JSON (كل حقول الملحق أ)، والاستيفاء بين الإطارات، والانعكاس بين الشوطين، وتحويل الديسيمتر إلى متر. وPlayMode يشغّل التسجيل ويقارن موقع كل لاعب بإطاره في نفس اللحظة. و`build.ps1 test` | Claude | `Assets/Legends/Tests/` |
| U8 | **نسخة الويب:** `build.ps1 webgl` ثم تشغيلها من خادم محلي (`python -m http.server` داخل `unity\Builds\WebGL`) وفتحها في Chrome | Claude ثم سليمان | |
| B1 | **`GET /api/v1/matches/{id}/scene`** (7.7): الناديان (الاسم والرمز واللونان والنقش من `App\Data\Crest`)، واللاعبون (المعرّف والرقم والمركز والخط)، والملعب وساعة المباراة. في العقد `openapi.yaml`، واختبار Feature، واختبار أنه لا يحمل أي تكتيك مخفي | Claude | `backend/app/Http/Controllers/Api/`، `openapi.yaml` |
| X1 | رفع ملفات Unity الصحيحة إلى git: `ProjectSettings/` و`Packages/` وكل `.meta`، لا `Library/` | Claude | `unity/` |

**تعديلات بالتوازي** (على ما أُنجز، خارج مشهد Unity):

| الرمز | التعديل | من | الحالة |
|---|---|---|---|
| X2 | **حفظ بيانات Render** (8.1): Litestream إلى Backblaze B2، و`APP_KEY_SEED` ثابت، وcron-job.org لمنع النوم | Claude (الكود، PR #540 و#541 ✅) ثم سليمان (الإعداد) | الكود مدموج. والإعداد: ✅ الحساب والـ Bucket والمفتاح ومتغيرات Render وcron-job.org (2026-10-25)، ويبقى التحقق في الجدول تحته |
| X3 | **تنظيف المستودع:** التنزيل 189 ميجا بدل 422 (حُذفت من السجل صور `art/raw` القديمة، وملفات zip الأربعة المكررة من `audio/raw`، ولقطات `docs/reference/osm`)، و`unity/.gitignore` | Claude | ✅ (2026-10-24) |

**المطلوب من سليمان في X2** (التفصيل في 8.1):

| # | الخطوة | الحالة |
|---|---|---|
| 1 | حساب Backblaze | ✅ |
| 2 | الـ Bucket، والـ Endpoint `s3.eu-central-003.backblazeb2.com` | ✅ |
| 3 | مفتاح `legends-render` لهذا الـ Bucket فقط، **Read and Write**. ونسخ keyID وapplicationKey فوراً، **ولا يُرسلان في أي محادثة** | ✅ |
| 4 | **Caps & Alerts:** كل الأسقف على $0 | |
| 5 | Render ← **Environment**: `B2_BUCKET`، و`B2_ENDPOINT` (`s3.eu-central-003.backblazeb2.com`)، و`B2_KEY_ID`، و`B2_APPLICATION_KEY`، و`APP_KEY_SEED` (نص عشوائي من 40 حرفاً فأكثر، يُحفظ عند سليمان) ← **Save** | ✅ |
| 6 | **Manual Deploy**، وإرسال سطر `Saved game` من **Logs** لـ Claude | |
| 7 | تجربة: حساب جديد ← **Restart service** ← الحساب باقٍ، وفي Logs: `brought back from B2` | |
| 8 | cron-job.org: زيارة `https://<الخدمة>.onrender.com/up` كل 5 دقائق | ✅ |

**الأيام:**

| اليوم | العمل |
|---|---|
| 1 | U1 تثبيت Unity، وU2 أول فتح وإصلاح الأخطاء |
| 2 | U3 أول مشهد ورأي سليمان، وU5 التقاط الصور |
| 3 | U4 التحويل إلى URP، وU6 تجربة MCP |
| 4 | U7 الاختبارات، وB1 مسار المشهد |
| 5 | U8 نسخة الويب، وX1، وتعريف الانتهاء والـ PR |

**تعريف الانتهاء:**
- [x] المباراة المسجلة تُعرض في الأرينا من أولها لآخرها: كل لاعب والكرة في مكانهما من الإطارات (اختبار PlayMode)، والنتيجة والدقيقة صحيحتان، والملعب ينعكس في الشوط الثاني
- [x] `build.ps1 test` كله أخضر (EditMode 12، وPlayMode 3)، و`build.ps1 capture` يُخرج الصور الخمس
- [x] نسخة الويب تفتح في المتصفح وتلعب المباراة (`build.ps1 webgl` ثم `build.ps1 serve`)
- [x] `/matches/{id}/scene` مُختبر، ولا يحمل تكتيكاً مخفياً
- [ ] (بالتوازي) X2: بيانات Render تبقى بعد إعادة التشغيل (الخطوة 7 أعلاه)

**الحالة (2026-10-24، نهاية اليوم الأول):**
- **تم:** U1 وU2 وU3 وU4 وU5 وU7 وU8، والتفصيل في ملف السبرنت (Sprint 2). وX1 بـ `unity/.gitignore` الموجود (يُرفع `Assets` و`Packages` و`ProjectSettings` وكل `.meta`، لا `Library` ولا `Builds` ولا `Logs`).
- **مؤجل:** U6 (MCP للمحرر): سطر الأوامر والصور الملتقطة كفيا، يُجرَّب إن احتجناه.
- **اختلافات عن الخطة:** المستودع على جهاز سليمان في `D:\Legends` (لا `C:\Legends-dev`)، وUnity 6.3 LTS (6000.3.27f1) في `D:\unity` (قرص C ممتلئ)، وBlender 5.2 في `D:\Blender Foundation`. و`build.ps1` يجد المحرر أينما ثبّته Unity Hub. والعمل اليوم من جلسة Cowork: Claude يكتب الملفات في المشروع، وسليمان يشغّل أوامر `build.ps1` وgit.
- **من أين نكمل (اليوم الثاني):**
  1. **B1:** `GET /api/v1/matches/{id}/scene` في `MatchController` (نفس `load()`: لأعضاء الدوري فقط): الناديان (المعرّف والاسم والرمز واللونان والنقش من `App\Data\Crest`، ويُستخرج النقش منه في دالة عامة)، واللاعبون (المعرّف والرقم والمركز والخط ومن بدأ) من `matches.state`، والملعب (الأرينا أو الكلاسيكي) وساعة المباراة المحلية ليلاً أو نهاراً (`scheduled_at` بتوقيت `Africa/Cairo`، والحدود في `config/game.php`)، و`tick_ms`. ثم اختبار Feature (`tests/Feature/MatchSceneTest.php` بـ `MakesLeagues`) واختبار أنه لا يحمل أي مفتاح من `MatchSetup::DEFAULT_TACTICS`، وتحديث `docs/api/openapi.yaml` و`npm run api` في `web/`.
  2. صور الالتقاط بعد آخر تعديل (`build.ps1 demo` ثم `capture`) للـ PR.
  3. إغلاق السبرنت: علامة B1 هنا، وPR يراجعه حمزة.
  4. **بالتوازي:** سليمان يكمل X2 من الخطوة 3، ويرسل سطر `Saved game` من Logs.
- **ملاحظات من الصور لسبرنتات قادمة:** الجمهور ممطوط وضبابي (Sprint 5)، واللاعبون كبسولات (Sprint 3).

**يراجعه حمزة:** يفتح الصور الملتقطة في الـ PR، ويشغّل نسخة الويب من الرابط المرفق، ويتأكد أن المباراة تتحرك.

## ما كان جاهزاً في `unity/` قبل البدء

كُتب في الحاوية السحابية بلا Unity، فأول مهمة هنا تشغيله على جهاز سليمان وإصلاح ما يظهر:

| الملف | ما يفعله |
|---|---|
| `build.ps1` | `install` (Unity Hub بـ winget، ثم المحرر من Hub بخطوات مكتوبة)، `setup` (يفتح المشروع أول مرة ويضيف الحزم)، `demo` (يبني الأرينا ومشهد المباراة)، `webgl` و`android` (البناءان) |
| `Assets/Legends/Scripts/MiniJson.cs` | قارئ JSON صغير، فلا حاجة لحزمة لقراءة رسائل الخادم |
| `Assets/Legends/Scripts/MatchFeed.cs` | رسائل الخادم في أصناف: الإعداد (الناديان وألوانهما واللاعبون) والدقيقة (الإطارات واللقطة ومدتها والنتيجة) |
| `Assets/Legends/Scripts/MatchScene.cs` | يحرك اللاعبين (أشكال بسيطة بألوان أطقمهم الآن) والكرة بين إطارات الخادم الستة، ويعكس الملعب بين الشوطين، ويغيّر طقم الضيف عند تشابه اللونين |
| `Assets/Legends/Scripts/Bridge.cs` | الجسر: `OnSetup` و`OnMinute` و`OnQuality` و`OnPause`، يناديه الويب والتطبيق باسم الكائن `Bridge` |
| `Assets/Legends/Scripts/SamplePlayback.cs` | يشغّل مباراة ليفربول وأرسنال المسجلة عبر الجسر نفسه، للتجربة بلا خادم |
| `Assets/Legends/Scripts/BroadcastCamera.cs` و`Scoreboard.cs` | كاميرا بث تتبع الكرة، والنتيجة والدقيقة |
| `Assets/Legends/Editor/Setup.cs` | يضيف الحزم: URP، وCinemachine، وTimeline، وAnimation Rigging، وAddressables، وProBuilder، وTest Framework |
| `Assets/Legends/Editor/ArenaBuilder.cs` | يبني الأرينا ليلاً بمقاسات حقيقية: الملعب بخطوطه وأشرطة العشب، والمرميان، ولوحات LED، وأربع مدرجات بطابقين من خامات جمهورنا، وشريط الإضاءة، والسقف، والكشافات |
| `Assets/Legends/Editor/DemoScene.cs` | يصنع `Scenes/Match.unity`: الأرينا والمباراة المسجلة والكاميرا والنتيجة. اضغط Play فتتحرك المباراة |
| `Assets/Legends/Editor/Builds.cs` | بناء WebGL (gzip مع Decompression Fallback) وAPK للتجربة |
| `Reference/stadiums/` | صور ملاعبنا الـ92 مرجعاً |

**أول تجربة على جهاز سليمان (اليوم الأول):** `build.ps1 install` ← المحرر من Unity Hub ← `build.ps1 setup` ← `build.ps1 demo` ← افتح `unity/` في Unity Hub واضغط Play.

## ما أُنجز وكيف يُختبر

**ما بُني (كله في `unity/`):**
- **`build.ps1`:** يجد Unity أينما ثبّته Unity Hub (C أو «Installs location» مثل `D:\unity`)، وخطوات جديدة: `where` (أي Unity.exe)، و`capture`، و`test`، و`serve`، و`open`.
- **`Editor/Setup.cs`:** يضيف الحزم السبع ويخرج بـ 0 حتى بعد إعادة الترجمة التي يسببها إضافتها (الحالة في `SessionState`).
- **`Editor/QualityLevels.cs` (U4):** URP بثلاثة مستويات (Low وMedium وHigh) في `Assets/Legends/Quality/`، والكمبيوتر والويب على High وAndroid على Medium. و`demo` يضبطها قبل بناء الأرينا فتُبنى المواد بـ shaders الـ URP، وشدة الكشافات لـ URP في `ArenaBuilder`.
- **الكاميرا والكرة:** كاميرا البث أعلى وأبعد (`BroadcastCamera`)، والكرة 32 سم بتوهج خفيف (`MatchScene`).
- **`Editor/Capture.cs` (U5):** يشغّل المباراة المسجلة بسرعة 8 ويلتقط كاميرا البث 1600×900 عند 5 و20 و45 و70 و90 إلى `unity/Captures/`.
- **`Editor/OpenMatch.cs`:** يفتح المحرر على `Scenes/Match.unity` (`build.ps1 open`، والقائمة Legends).
- **الوحدات (asmdef):** `Legends` (Scripts)، و`Legends.Editor`، و`Legends.Tests.EditMode`، و`Legends.Tests.PlayMode`.
- **الاختبارات (U7):** `Tests/EditMode/FeedTests.cs` (12): قارئ JSON والعربية، والإعداد والدقيقة بحقول الملحق أ، والديسيمتر إلى متر، والانعكاس، والاستيفاء، والمباراة المسجلة كاملة (93 دقيقة بستة إطارات، 1-1). و`Tests/PlayMode/PlaybackTests.cs` (3): كل لاعب والكرة في مكانهما من الإطارات في كل إطار رسم (بفارق أقل من 5 سم)، في الشوط الأول والثاني المعكوس، والدقائق بالترتيب.
- **نسخة الويب (U8):** `build.ps1 webgl` ثم `build.ps1 serve` (خادم Python على `http://localhost:8090`).

**كيف تجربه (على جهاز فيه Unity 6.3 LTS):**
1. `powershell -ExecutionPolicy Bypass -File unity\build.ps1 setup` ثم `demo`.
2. `build.ps1 test`: المتوقع `12 passed` و`3 passed` و`All tests green.`
3. `build.ps1 capture`: خمس صور في `unity\Captures\`، وفي السجل النتيجة واللحظة عند كل صورة.
4. `build.ps1 open` ثم Play: المباراة تتحرك، والنتيجة والدقيقة في الزاوية.
5. `build.ps1 webgl` (أول مرة 15 إلى 40 دقيقة) ثم `build.ps1 serve`: نفس المباراة في المتصفح.

**يراجعه حمزة:** يفتح الصور في `unity/Captures/`، ويقارنها بحركة اللاعبين في `open`، ويشغّل نسخة الويب.

**إصلاحات معه في نفس اليوم:**
- **Codespaces:** الدخول والجلسة على العنوان العام، والبريد عبر Gmail وجوجل من أسرار Codespaces، والطابور والمجدول و`matches:run` (`.devcontainer/env.sh` و`start.sh`، والقسم «الحسابات في Codespaces» أعلاه).
- **Render:** نفس الإصلاح وقت التشغيل (`deploy/render/start.sh`)، والإعدادات تُحفظ بعد معرفة العنوان لا وقت البناء (`Dockerfile`).

**تعديلات بالتوازي:**
- **X2 حفظ بيانات Render** (PR #540 و#541، الخطة 8.1):
  - **ما بُني:**
    - `deploy/render/litestream.yml` ينسخ `legends.sqlite` و`queue.sqlite` إلى Backblaze B2.
    - و`start.sh` يسترجعهما قبل الترحيلات، ثم يشغّل الموقع تحت `litestream replicate -exec`.
    - ولو تعذرت قراءة B2 يتوقف التشغيل.
    - و`APP_KEY_SEED` يثبّت مفتاح التطبيق.
    - و`Dockerfile` يثبت Litestream 0.3.13.
  - **اختُبر بخادم S3 محلي:** النسخ ثم الاسترجاع يعيدان صفاً كُتب قبل الإيقاف مباشرة، والمكان الفارغ يبدأ نظيفاً. لم يُبنَ الـ Docker في الجلسة.
  - **كيف يُختبر:** الخطوتان 6 و7 في 8.1 بعد إعداد سليمان. **الحالة:** الحساب والـ Bucket جاهزان.
- **X3 تنظيف المستودع:**
  - **ما حُذف من السجل:** صور `art/raw` القديمة، وملفات zip الأربعة المكررة من `audio/raw` (تأكدنا أن محتواها مطابق للملفات الموجودة حرفاً بحرف)، و`docs/reference/osm` (قرار سليمان).
  - **الحجم:** التنزيل 189 ميجا بدل 422. وأُضيف `Build/` وملفات المحررات إلى `unity/.gitignore`.
  - **كيف يُختبر:** `git clone` جديد، ثم `git count-objects -vH`.

**B1 مسار المشهد (2026-11-03):**
- **ما بُني:** `GET /api/v1/matches/{id}/scene` (`MatchController::scene`): الناديان (المعرّف والاسم والرمز واللونان والنقش والطقم الاحتياطي من `App\Data\KitPattern`)، ولاعبو الفريقين (المعرّف والاسم والرقم والمركز والخط ومن بدأ)، والقائدان، وشكل كل مدرب، والملعب وإضاءته من ساعة البداية في القاهرة (`game.scene`: الأرينا ليلاً وعند الغروب، والكلاسيكي نهاراً، بنفس حدود اللقطات الكرتونية)، و`tick_ms`. لأعضاء الدوري فقط، ولا يحمل تكتيك أي فريق، فهو واحد لكل الأعضاء. وشكله هو ما يقرؤه `MatchSetup.From` في Unity.
- **الاختبارات:** `tests/Feature/MatchSceneTest.php` (4): الشكل كاملاً و11 أساسياً بحارس لكل فريق، ولا مفتاح من `MatchSetup::DEFAULT_TACTICS`، و404 لغير الأعضاء، والإضاءة بالساعة.
- **العقد:** `docs/api/openapi.yaml` (`SceneClub` و`ScenePlayer`)، و`npm run api`.
- **كيف يُختبر:** في مباراة دوري حية أو منتهية، افتح `/api/v1/matches/{id}/scene` وأنت عضو في الدوري.

**بقي:** تجربة U6 إن احتجناها. وربط الويب بالمسار (Vue يمرره إلى `OnSetup`) في Sprint 11.

## ملاحظات وتعديلات بالتوازي

- ما يُطلب أثناء السبرنت يُكتب هنا برمز X، في PR صغير مستقل.
