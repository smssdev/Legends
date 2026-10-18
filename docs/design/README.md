# تصاميم Legends

معاينة كل الشاشات كما تظهر في لوحة التصميم. **الحالة: مسودات للمراجعة قبل الاعتماد.**

| المجلد | المحتوى |
|---|---|
| `screens/png/` | صور الشاشات (هي المعروضة هنا) |
| `screens/*.html` | نفس الشاشات كصفحات ثابتة، تُفتح في المتصفح بعد استنساخ المستودع (`screens/index.html`) |
| `legends-ui/` | مصادر لوحة التصميم (`*.dc.html` و`canvas.json`) |
| `reference/` | لقطات OSM المرجعية (اختيارية) |

**إعادة التصدير بعد أي تعديل:**

```bash
node tools/design-export/render.mjs docs/design/legends-ui docs/design/screens
python3 tools/design-export/shoot.py docs/design/legends-ui/canvas.json docs/design/screens docs/design/screens/png
```

## نظام التصميم

### نظام التصميم

![نظام التصميم](screens/png/Main.png)

## الشاشات الأساسية · الويب

### الويب: الرئيسية

![الويب: الرئيسية](screens/png/WebHome.png)

### الويب: التشكيلة

![الويب: التشكيلة](screens/png/WebLineup.png)

### الويب: المباراة الحية

![الويب: المباراة الحية](screens/png/WebMatch.png)

## الشاشات الأساسية · الموبايل

| الرئيسية | التشكيلة | المباراة الحية |
|---|---|---|
| <img src="screens/png/MobileHome.png" width="220" alt="MobileHome"> | <img src="screens/png/MobileLineup.png" width="220" alt="MobileLineup"> | <img src="screens/png/MobileMatch.png" width="220" alt="MobileMatch"> |

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
| <img src="screens/png/MobileLogin.png" width="220" alt="MobileLogin"> | <img src="screens/png/MobileRegister.png" width="220" alt="MobileRegister"> | <img src="screens/png/MobileJoin.png" width="220" alt="MobileJoin"> | <img src="screens/png/MobilePickTeam.png" width="220" alt="MobilePickTeam"> | <img src="screens/png/MobileCreateLeague.png" width="220" alt="MobileCreateLeague"> |

## ملاحظات

- الألوان والخطوط هنا هي المرجع لـ Tailwind في `web/` (السبرنت 1 للمحاكي، وكاملة في السبرنت 2).
- البيانات حقيقية من `data/ea-fc26/` (ليفربول وآرسنال)، والأسماء معروضة بالعربية.
- الويب: شريط جانبي. الموبايل: شريط سفلي بخمسة أقسام (الرئيسية، الفريق، المباراة، السوق، المزيد).
- شارات الأندية مولّدة من ألوان النادي وحروفه، بدل الشعارات الحقيقية.
