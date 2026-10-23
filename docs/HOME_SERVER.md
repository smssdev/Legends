# السيرفر المنزلي

> قرار 2026-10-18 [PLAN 2.19]: اللعبة تعمل على جهاز في البيت يبقى شغالاً وقت المباريات، برابط عام مجاني ثابت من Tailscale Funnel. البيانات محفوظة على قرص الجهاز، مع نسخة احتياطية يومية.

## المتطلبات

- كمبيوتر بويندوز 10 أو 11 (أي جهاز، ولو قديم) متصل بالإنترنت.
- حساب GitHub (`smssdev`) للدخول على المستودع الخاص.
- حساب Tailscale مجاني (تسجيل بحساب جوجل أو GitHub أثناء التثبيت).

## التثبيت (مرة واحدة، حوالي 20 دقيقة)

1. نزّل الملف `deploy/windows/setup.ps1` على الجهاز (من GitHub: افتح الملف ← زر Download raw file).
2. افتح **PowerShell كمسؤول**: زر ابدأ ← اكتب PowerShell ← زر يمين ← **Run as administrator**.
3. اكتب (عدّل المسار لمكان الملف):
   ```
   powershell -ExecutionPolicy Bypass -File $HOME\Downloads\setup.ps1
   ```
4. أثناء التثبيت تظهر نافذتان للدخول:
   - **GitHub:** سجّل الدخول بحساب smssdev (لتنزيل المستودع الخاص).
   - **Tailscale:** سجّل الدخول، وأول مرة يطلب تفعيل **Funnel** و**HTTPS** من رابط يظهر في الشاشة: افتحه ووافق.
5. في النهاية يظهر رابطك: `https://اسم-الجهاز.اسم-الشبكة.ts.net`. أضف `/sim` والعب، وأرسله لحمزة.

## ماذا يحدث بعدها تلقائياً

- **اللعبة تبدأ مع تشغيل ويندوز**، وتُعاد وحدها لو توقفت (مهمة مجدولة اسمها `Legends Web`).
- **البث المباشر** (`Legends Live`، خادم Reverb) و**الطابور** (`Legends Queue`، رسائل البريد) يبدآن معها. والبث يعمل على نفس الرابط: `wss://اسم-الجهاز...ts.net/app/...`، وReverb نفسه لا يُفتح إلا على الجهاز.
- **مشغّل المباريات** (`Legends Matches`، `php artisan matches:run`) يلعب المباريات الحية دقيقة بدقيقة، ولو توقف يكمل من آخر حالة محفوظة بنفس النتيجة. و`update.ps1` ينتظر انتهاء المباريات الحية (`php artisan matches:live` = 0) قبل أن يحدّث. ولقياس قدرة الجهاز: أوقف مهمة `Legends Matches`، ثم `php artisan matches:load-test` (50 مباراة حية في حوالي 6 دقائق، ويحذف ما صنعه بعدها)، ثم شغّلها من جديد.
- **رابط الدعوة** `https://اسم-الجهاز...ts.net/join/الكود` يظهر في واتساب ببطاقة الدوري (السبرنت 14).
- **المجدول كل دقيقة** (`Legends Scheduler`)، ومنه **نسخة احتياطية يومية الساعة 4 فجراً بتوقيت القاهرة** في `C:\Legends\backend\database\backups\` (يحتفظ بآخر 14 نسخة).
- **معايرة المحرك كل ليلة** (`GAME_NIGHTLY_BALANCE=true` في `.env`): الساعة 3 فجراً `sim:balance` بـ 5000 مباراة، ثم `sim:knobs` و`sim:matrix` كاملة. النتيجة في `backend/storage/app/balance/latest.json` والسجل في `backend/storage/logs/balance.log`. وتأخذ قرابة 20 دقيقة من المعالج.
- **الحارس** (`Legends Watchdog`، كل دقيقة، `deploy/windows/watchdog.ps1`): يشغّل أي مهمة متوقفة من المهام الأربع (الموقع، والبث، والطابور، والمباريات)، سواء وقعت أو خرجت خروجاً عادياً (ويندوز لا يعيد المهمة وحده إلا بعد خطأ، والطابور يخرج كل ساعة ليتجدد). ثم يشغّل `php artisan server:health --notify`، وسجله في `backend\storage\logs\watchdog.log`. و`update.ps1` يوقفه أثناء التحديث.
- **التنبيه على الجوال (ntfy، مجاني):** `setup.ps1` يصنع موضوعاً سرياً (`NTFY_TOPIC` في `.env`) ويطبعه في النهاية. ثبّت تطبيق **ntfy** على جوالك وجوال حمزة، واضغط + واكتب اسم الموضوع. فيصلك تنبيه عاجل خلال دقيقة إذا توقفت أي خدمة (ويتكرر كل نصف ساعة ما دامت متوقفة)، وتنبيه عادي حين ترجع. والفحص يشمل: الموقع، والبث، ومشغّل المباريات، والطابور، والمجدول، وقاعدة البيانات، ومساحة القرص (أقل من 1 جيجا).
- **الجهاز لا ينام** وهو موصول بالكهرباء.
- **الرابط ثابت** ولا يتغير مع إعادة التشغيل.

## التحديث (حين أدمج تعديلاً جديداً)

في PowerShell كمسؤول، والأفضل في وقت لا توجد فيه مباراة:
```
powershell -ExecutionPolicy Bypass -File C:\Legends\deploy\windows\update.ps1
```
يأخذ نسخة احتياطية أولاً، ثم ينزّل التحديث ويبنيه ويعيد التشغيل. **لا يمسح أي بيانات.**

## حماية البيانات

- لا تشغّل `composer fresh` ولا `migrate:fresh` على هذا الجهاز: هذان للتطوير فقط ويمسحان قاعدة البيانات.
- **نسخة متواصلة على القرص الثاني (Litestream):** اكتب في `backend\.env` السطر `LITESTREAM_REPLICA_DIR=D:\LegendsReplica` (مجلد على القرص الثاني)، ثم شغّل `setup.ps1` مرة. تعمل مهمة `Legends Replica` دائماً وتحفظ آخر 72 ساعة.
- **النسخة اليومية على Google Drive (rclone، مجاني):** ثبّت rclone، ثم `rclone config` مرة (remote باسم `gdrive` من نوع Google Drive)، واكتب `BACKUP_RCLONE_REMOTE=gdrive:LegendsBackups` في `backend\.env`. كل نسخة يومية تُرفع، ويُحذف هناك ما فوق 30 يوماً.
- **الاسترجاع:** أوقف المهام (أو شغّل من داخل `update.ps1`)، ثم من `backend`:
  - من نسخة على الجهاز: `php artisan db:restore <التاريخ>` (اسم المجلد في `database\backups\`، وتراه أيضاً في لوحة الإدارة).
  - من Google Drive: `rclone copy gdrive:LegendsBackups\<التاريخ> restore\` ثم `php artisan db:restore restore`.
  - من Litestream: `tools\litestream\litestream.exe restore -o legends-restored.sqlite D:\LegendsReplica\legends` ثم `php artisan db:restore legends-restored.sqlite`.
  - يفحص الملف قبل أي تغيير، ويحفظ الحالي بجانبه باسم `.before-restore`. ثم شغّل المهام.

## لو لم يعمل شيء

- افتح `http://127.0.0.1:8000/sim` على نفس الجهاز: لو فتح، فالمشكلة في Tailscale (`tailscale funnel status`، ويجب أن يظهر فيه `/` على المنفذ 8000 و`/app` على 8080).
- **البث لا يصل** (زر «جرّب البث» في الرئيسية): تأكد أن المهمة `Legends Live` تعمل. والتثبيت القديم (قبل السبرنت 14) يحتاج تشغيل `setup.ps1` مرة أخرى ليضيفها، وهو آمن ولا يمسح شيئاً.
- **حالة كل خدمة الآن:** `php artisan server:health` من `C:\Legends\backend` (جدول بالعربية، والرمز 1 لو توقفت خدمة).
- **لا يصل تنبيه:** تأكد من `NTFY_TOPIC` في `.env` ومن الاشتراك في نفس الاسم في تطبيق ntfy، وأن المهمة `Legends Watchdog` موجودة (التثبيت قبل السبرنت 21 يحتاج تشغيل `setup.ps1` مرة أخرى).
- سجل الأخطاء: `C:\Legends\backend\storage\logs\laravel.log`.
