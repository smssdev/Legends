# بيانات EA FC 26

مصدر الأمر `data:import` (Sprint 3). الملفان للقراءة فقط، ولا يُعدَّلان يدوياً. أي تنظيف يتم داخل أمر الاستيراد.

| الملف | السجلات | المحتوى |
|---|---|---|
| `ea_fc26_outfield.csv` | 14,412 | لاعبو الملعب: الخصائص الستة + 29 خاصية تفصيلية |
| `ea_fc26_goalkeepers.csv` | 1,816 | الحراس: `gkDiving`, `gkHandling`, `gkKicking`, `gkPositioning`, `gkReflexes` |

- المصدر: مجموعة بيانات EA FC 26 على Kaggle، ترخيص CC0. أسماء الأندية واللاعبين ملك أصحابها (انظر `docs/PLAN.md` 2.6 و2.18).
- الملف المدمج `ea_fc26_players.csv` غير مستخدم: نفس السجلات بتنسيق تاريخ مختلف.
- التاريخ في الملفين بصيغة `YYYY-MM-DD`، ولا يوجد أي حقل رقمي فارغ.

## الأعمدة

**مشتركة:** `id` (فريد عبر الملفين)، `rank`، `overallRating`، `firstName`، `lastName`، `commonName` (قد يكون فارغاً، ويُفضَّل للعرض إن وُجد)، `birthdate`، `height`، `weight`، `skillMoves`، `weakFootAbility`، `preferredFoot`، `position`، `positionType`، `alternatePositions` (مفصولة بفواصل)، `nationality`، `team`، `leagueName`، `playStyles`، `playStylesPlus`، `age`.

**لاعبو الملعب:** `pac` `sho` `pas` `dri` `def` `phy` + `acceleration` `sprintSpeed` `finishing` `shotPower` `longShots` `volleys` `penalties` `positioning` `shortPassing` `longPassing` `curve` `freeKickAccuracy` `crossing` `vision` `dribbling` `ballControl` `agility` `balance` `reactions` `composure` `interceptions` `defensiveAwareness` `standingTackle` `slidingTackle` `headingAccuracy` `aggression` `jumping` `stamina` `strength`.

**ربطها بالخطة:**

| في الخطة | العمود |
|---|---|
| منفذ الجزاء | `penalties` |
| منفذ الركلات الحرة | `freeKickAccuracy` |
| منفذ الركنيات | `crossing` |
| القائد | لا يوجد عمود قيادة: الأقدم والأقوى في التشكيلة |
| القيمة السوقية | غير موجودة: تُحسب بـ `PlayerValuation` |
| الإمكانية | غير موجودة: تُحسب من العمر والتقييم |

## ملاحظات من الفحص

- **644 نادياً**، منها **616** فيها 18 لاعباً على الأقل وحارس (الحد الأدنى للاستيراد). حجم التشكيلة: الأدنى 7، الوسيط 25، الأعلى 38.
- الدوريات الكبرى مكتملة: Premier League 20/20، LALIGA 20/20، Serie A 20/20، Bundesliga 18/18، Ligue 1 18/18، ROSHN Saudi League 16/18.
- `Libertadores` و`Sudamericana` ليستا دوريين: أندية أمريكا الجنوبية التي لا دوري لها في البيانات مسجلة تحت اسم البطولة. تُعامل كقوالب منفصلة أو تُستبعد (قرار في Sprint 3).
- لا يوجد الدوري المصري ولا دوريات عربية غير السعودي.
- أسماء الأندية مختصرة كما في اللعبة (`Spurs`, `Man Utd`, `Nott'm Forest`). يمكن إضافة اسم عربي للعرض لاحقاً.
- أقوى أندية Premier League بمتوسط أفضل 18: Liverpool 84.8، Arsenal 84.1، Manchester City 83.8، وأضعفها Burnley 75.2.
