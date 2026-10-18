# تصاميم Legends

معاينة كل الشاشات كما تظهر في لوحة التصميم. **الحالة: مسودات للمراجعة قبل الاعتماد.** لوحة التصميم الحية: https://claude.ai/artifact/VYxhBkJadep3NdbxgTk9nd

| المجلد | المحتوى |
|---|---|
| `screens/png/` | صور الشاشات (هي المعروضة هنا) |
| `screens/*.html` | نفس الشاشات كصفحات ثابتة، تُفتح في المتصفح بعد استنساخ المستودع (`screens/index.html`) |
| `legends-ui/` | مصادر لوحة التصميم (`*.dc.html` و`canvas.json`) |
| `../reference/osm/` | لقطات OSM المرجعية (95 موبايل و74 ويب) |

**إعادة التصدير بعد أي تعديل:**

```bash
node tools/design-export/render.mjs docs/design/legends-ui docs/design/screens
python3 tools/design-export/shoot.py docs/design/legends-ui/canvas.json docs/design/screens docs/design/screens/png
```
> **المباراة والمحاكي** (Sprint 1) لوحات متحركة وتفاعلية على لوحة التصميم: الملعب 2.5D والكرة تتحرك، وأزرار السرعة والأوامر السريعة والتبويبات تعمل. الصور هنا لقطة من أول إطار. المواصفة في `docs/MATCH_VIEW.md`.

## نظام التصميم

### نظام التصميم

![نظام التصميم](screens/png/Main.png)

## الويب

### الويب: الرئيسية

![الويب: الرئيسية](screens/png/WebHome.png)

### الويب: التشكيلة

![الويب: التشكيلة](screens/png/WebLineup.png)

## الموبايل

| الرئيسية | التشكيلة |
|---|---|
| <img src="screens/png/MobileHome.png" width="200" alt="MobileHome"> | <img src="screens/png/MobileLineup.png" width="200" alt="MobileLineup"> |

## الدخول والانضمام · الويب

### الويب: تسجيل الدخول

![الويب: تسجيل الدخول](screens/png/WebLogin.png)

### الويب: إنشاء حساب

![الويب: إنشاء حساب](screens/png/WebRegister.png)

### الويب: الانضمام لدوري

![الويب: الانضمام لدوري](screens/png/WebJoin.png)

### الويب: اختيار الفريق

![الويب: اختيار الفريق](screens/png/WebPickTeam.png)

### الويب: إنشاء دوري

![الويب: إنشاء دوري](screens/png/WebCreateLeague.png)

## الدخول والانضمام · الموبايل

| تسجيل الدخول | إنشاء حساب | الانضمام لدوري | اختيار الفريق | إنشاء دوري |
|---|---|---|---|---|
| <img src="screens/png/MobileLogin.png" width="200" alt="MobileLogin"> | <img src="screens/png/MobileRegister.png" width="200" alt="MobileRegister"> | <img src="screens/png/MobileJoin.png" width="200" alt="MobileJoin"> | <img src="screens/png/MobilePickTeam.png" width="200" alt="MobilePickTeam"> | <img src="screens/png/MobileCreateLeague.png" width="200" alt="MobileCreateLeague"> |

## الفريق والإدارة · الويب

### الويب: الفريق وبطاقة اللاعب

![الويب: الفريق وبطاقة اللاعب](screens/png/WebSquad.png)

### الويب: التكتيك

![الويب: التكتيك](screens/png/WebTactics.png)

### الويب: الدوري والكأس

![الويب: الدوري والكأس](screens/png/WebLeague.png)

### الويب: التدريب

![الويب: التدريب](screens/png/WebTraining.png)

### الويب: السوق

![الويب: السوق](screens/png/WebMarket.png)

### الويب: المالية والرعاة

![الويب: المالية والرعاة](screens/png/WebFinance.png)

### الويب: الملعب

![الويب: الملعب](screens/png/WebStadium.png)

## الفريق والإدارة · الموبايل

| الفريق | بطاقة اللاعب | التكتيك | الدوري والكأس | التدريب | السوق | المالية | الملعب |
|---|---|---|---|---|---|---|---|
| <img src="screens/png/MobileSquad.png" width="200" alt="MobileSquad"> | <img src="screens/png/MobilePlayer.png" width="200" alt="MobilePlayer"> | <img src="screens/png/MobileTactics.png" width="200" alt="MobileTactics"> | <img src="screens/png/MobileLeague.png" width="200" alt="MobileLeague"> | <img src="screens/png/MobileTraining.png" width="200" alt="MobileTraining"> | <img src="screens/png/MobileMarket.png" width="200" alt="MobileMarket"> | <img src="screens/png/MobileFinance.png" width="200" alt="MobileFinance"> | <img src="screens/png/MobileStadium.png" width="200" alt="MobileStadium"> |

## المباراة والمحاكي · الويب

### الويب: إعداد المحاكي

![الويب: إعداد المحاكي](screens/png/WebSimSetup.png)

### الويب: المباراة الحية (متحركة)

![الويب: المباراة الحية (متحركة)](screens/png/WebMatch.png)

### الويب: لحظة الهدف

![الويب: لحظة الهدف](screens/png/WebMatchGoal.png)

### الويب: التكتيك أثناء المباراة

![الويب: التكتيك أثناء المباراة](screens/png/WebMatchTactics.png)

### الويب: التبديل

![الويب: التبديل](screens/png/WebMatchSubs.png)

### الويب: الاستراحة

![الويب: الاستراحة](screens/png/WebHalftime.png)

### الويب: تقرير المباراة

![الويب: تقرير المباراة](screens/png/WebMatchReport.png)

## المباراة والمحاكي · الموبايل

| إعداد المحاكي | المباراة الحية (متحركة) | لحظة الهدف | التكتيك أثناء المباراة | التبديل | ملء الشاشة أفقياً | تقرير المباراة |
|---|---|---|---|---|---|---|
| <img src="screens/png/MobileSimSetup.png" width="200" alt="MobileSimSetup"> | <img src="screens/png/MobileMatch.png" width="200" alt="MobileMatch"> | <img src="screens/png/MobileMatchGoal.png" width="200" alt="MobileMatchGoal"> | <img src="screens/png/MobileMatchTactics.png" width="200" alt="MobileMatchTactics"> | <img src="screens/png/MobileMatchSubs.png" width="200" alt="MobileMatchSubs"> | <img src="screens/png/MobileMatchLandscape.png" width="360" alt="MobileMatchLandscape"> | <img src="screens/png/MobileMatchReport.png" width="200" alt="MobileMatchReport"> |

## ملاحظات

- الألوان والخطوط هنا هي المرجع لـ Tailwind في `web/` (السبرنت 1 للمحاكي، وكاملة في السبرنت 2).
- لوحات المباراة تستخدم ناديين حقيقيين بتشكيلتيهما من `data/ea-fc26/` (ليفربول 4-2-3-1 ضد آرسنال 4-3-3، والقوة متوسط أفضل 18).
- لوحات التكتيك والتبديل ولحظة الهدف تستورد لوحة المباراة الحية (`<dc-import>`)، والتصدير يدعم ذلك.
- البيانات حقيقية من `data/ea-fc26/` (ليفربول وآرسنال)، والأسماء معروضة بالعربية.
- الويب: شريط جانبي. الموبايل: شريط سفلي بخمسة أقسام (الرئيسية، الفريق، المباراة، السوق، المزيد).
- شارات الأندية مولّدة من ألوان النادي وحروفه، بدل الشعارات الحقيقية.
