# 04. نموذج البيانات والـ API

## 1. قاعدتان

- **قاعدة القرآن** (للقراءة فقط، نفسها على الخادم وداخل التطبيق): النص، والصفحات، والتلاوات، والتفاسير. تُبنى بسكربتات `data/` وتُفحص ببصمة.
- **قاعدة المستخدمين:** كل ما يخص المستخدم وحفظه.

## 2. قاعدة القرآن

```mermaid
erDiagram
    SURAHS ||--o{ AYAHS : "تحوي"
    AYAHS ||--o{ WORDS : "تحوي"
    PAGES ||--o{ PAGE_LINES : "تحوي"
    PAGE_LINES ||--o{ WORDS : "ترسم"
    AYAHS ||--o{ AYAH_SEGMENTS : "تُقسم"
    RECITERS ||--o{ RECITATION_TIMINGS : "له"
    AYAHS ||--o{ RECITATION_TIMINGS : "توقيت"
    AYAHS ||--o{ TAFSIR_ENTRIES : "تفسير"
    TAFSIR_BOOKS ||--o{ TAFSIR_ENTRIES : "من"
    WORDS ||--o{ WORD_MEANINGS : "معنى"
    AYAHS ||--o{ SIMILARITY_EDGES : "تشابه"
    SURAHS ||--o{ SURAH_CARDS : "بطاقة"

    SURAHS { int id PK "1..114" string name_ar int ayah_count string revelation "مكية/مدنية" }
    AYAHS { int id PK int surah_id FK int number int juz int hizb int rub int page string text_uthmani string text_imlaei string text_plain "بلا تشكيل" }
    WORDS { int id PK int ayah_id FK int position string text_uthmani string text_plain string phonemes int line_id FK }
    PAGES { int number PK "1..604" string riwaya }
    PAGE_LINES { int id PK int page FK int line_no string type "آية/اسم سورة/بسملة" }
    AYAH_SEGMENTS { int id PK int ayah_id FK int from_word int to_word "تقسيم الطويلة على الوقف" }
    RECITERS { int id PK string name string style "مرتل/معلم/مجود" }
    RECITATION_TIMINGS { int reciter_id FK int ayah_id FK string audio_url json word_timings }
    TAFSIR_BOOKS { int id PK string name string author string license }
    TAFSIR_ENTRIES { int book_id FK int ayah_id FK text body }
    WORD_MEANINGS { int word_id FK string lang string meaning string root }
    SIMILARITY_EDGES { int ayah_a FK int ayah_b FK int score json diff "مواضع الفرق" bool reviewed }
    SURAH_CARDS { int surah_id FK text purpose json themes "المحاور ونطاق آياتها" string source }
```

## 3. قاعدة المستخدمين

```mermaid
erDiagram
    USERS ||--o{ PLANS : "له"
    USERS ||--o{ AYAH_MEMORY : "حفظه"
    USERS ||--o{ JUNCTION_MEMORY : "مفاصله"
    PLANS ||--o{ DAILY_WIRDS : "تولّد"
    DAILY_WIRDS ||--o{ WIRD_ITEMS : "بنود"
    USERS ||--o{ SESSIONS : "جلساته"
    WIRD_ITEMS ||--o| SESSIONS : "تُنجز بـ"
    SESSIONS ||--o{ RECITATION_ERRORS : "أخطاؤها"
    SESSIONS ||--o{ REVIEW_EVENTS : "أحداثها"
    USERS ||--o{ ITQAN_RECORDS : "إتقانه"
    USERS ||--o{ EXAMS : "اختباراته"
    USERS ||--o{ TADABBUR_NOTES : "تدبره"
    USERS ||--o{ MY_MUTASHABIHAT : "متشابهاته"
    HALAQAS ||--o{ HALAQA_MEMBERS : "أعضاء"
    USERS ||--o{ HALAQA_MEMBERS : "ينتسب"
    SESSIONS ||--o{ TEACHER_REVIEWS : "تصحيح"
    FAMILIES ||--o{ USERS : "أفراد"

    USERS { uuid id PK string name string email string gender date birth_date string timezone int day_start_hour string locale uuid family_id FK }
    PLANS { uuid id PK uuid user_id FK string template "متوازن/حصون/..." string direction date target_date int daily_minutes json settings string status string life_mode "عادي/سفر/رمضان" }
    DAILY_WIRDS { uuid id PK uuid plan_id FK date day int est_minutes string status }
    WIRD_ITEMS { uuid id PK uuid wird_id FK string kind "جديد/قريب/بعيد/ترميم/تحضير/اختبار" int from_ayah int to_ayah int est_minutes string status }
    SESSIONS { uuid id PK uuid user_id FK string kind string mode "صوتي/كتابي/ذاتي" int from_ayah int to_ayah timestamp started_at int duration_s string audio_key string source "خادم/جهاز" string idempotency_key }
    RECITATION_ERRORS { uuid id PK uuid session_id FK int word_id string code "OMIT/SUB/..." string heard int at_ms bool disputed string verdict "آلي/معلم/ملغى" }
    REVIEW_EVENTS { uuid id PK uuid session_id FK int ayah_id int rating "1..4" int errors int stalls int prompts timestamp at }
    AYAH_MEMORY { uuid user_id FK int ayah_id int stability_x100 int difficulty_x100 timestamp last_review timestamp due_at int lapses string stage "جديد/قريب/بعيد/تعاهد" json weak_words }
    JUNCTION_MEMORY { uuid user_id FK int from_ayah int to_ayah int stability_x100 timestamp due_at }
    ITQAN_RECORDS { uuid user_id FK int page int clean_days bool random_passed bool teacher_ok timestamp mastered_at }
    EXAMS { uuid id PK uuid user_id FK string type json scope json questions int score json deductions }
    TADABBUR_NOTES { uuid id PK uuid user_id FK int ayah_id text body bool private }
    MY_MUTASHABIHAT { uuid user_id FK int ayah_a int ayah_b int hits text my_rule }
    HALAQAS { uuid id PK string name uuid teacher_id FK string gender_policy json itqan_rules }
    HALAQA_MEMBERS { uuid halaqa_id FK uuid user_id FK string role }
    TEACHER_REVIEWS { uuid id PK uuid session_id FK uuid teacher_id FK json word_marks string voice_note_key text note string grade }
    FAMILIES { uuid id PK uuid guardian_id FK }
```

**ملاحظات:**

- `REVIEW_EVENTS` **سجل لا يُعدَّل**، و`AYAH_MEMORY` تُشتق منه ويمكن إعادة بنائها كاملة (وهذا ما يجعل المزامنة آمنة، وتغيير الخوارزمية لاحقاً ممكناً).
- الأرقام العشرية تُخزن أعداداً صحيحة (`_x100`) حتى يتطابق حساب PHP وDart.
- `idempotency_key` على كل جلسة حتى لا تتكرر عند إعادة الإرسال.
- اعتراض المستخدم (`disputed`) لا يحذف الخطأ بل يعلّمه، ويحسمه المعلم أو إعادة التسميع.

## 4. الـ API (المسارات الرئيسية)

الأساس `/api/v1`، والعقد الكامل `docs/api/openapi.yaml` (يُكتب في M01 ويُحدَّث مع كل مسار).

| المجموعة | المسارات |
|---|---|
| القرآن | `GET /quran/pages/{n}` · `GET /quran/surahs` · `GET /quran/ayahs/{id}` · `GET /quran/search` · `GET /quran/reciters` |
| الحساب | `POST /auth/register` · `POST /auth/login` · `GET /me` · `PATCH /me` · `POST /me/export` · `DELETE /me` |
| التهيئة | `POST /onboarding/known` (ما أحفظه) · `POST /onboarding/placement` (اختبار تحديد المستوى) |
| الخطة | `POST /plans` · `GET /plans/current` · `PATCH /plans/current` · `POST /plans/current/life-mode` · `POST /plans/preview` |
| الورد | `GET /wird/today` · `GET /wird/{date}` · `POST /wird/items/{id}/skip` |
| الجلسات | `POST /sessions` · `POST /sessions/{id}/audio` · `POST /sessions/{id}/finish` · `GET /sessions/{id}` · `POST /sessions/sync` (دفعة من الجوال) |
| التسميع | `POST /recitation/token` (توكن البث) · `POST /recitation/errors/{id}/dispute` |
| الذاكرة | `GET /memory/map` (خريطة الإتقان) · `GET /memory/weak` · `GET /memory/forecast` |
| الكتابة | `POST /writing/check` · `GET /writing/exercise` |
| المتشابهات | `GET /mutashabihat/{ayah}` · `GET /mutashabihat/mine` · `GET /mutashabihat/drill` |
| الاختبارات | `POST /exams` · `POST /exams/{id}/answers` · `GET /exams/{id}` |
| الفهم | `GET /understanding/words/{id}` · `GET /understanding/tafsir/{ayah}` · `GET /understanding/surahs/{id}/card` |
| التدبر | `GET/POST /tadabbur` |
| الرفيق | `GET /companion/today` · `POST /companion/chat` · `GET /reports/weekly` |
| الحلقات | `POST /halaqas` · `POST /halaqas/{id}/join` · `GET /halaqas/{id}/board` · `POST /sessions/{id}/submit` · `POST /reviews` |
| المباشر | `POST /live/rooms` · `POST /live/rooms/{id}/token` |
| الوسائط | `POST /videos` · `GET /videos/{id}` |
| Unity | `GET /journey/state` |

**شكل الخطأ:** `{message, code, errors?}` برسالة بلغة المستخدم.

## 5. الأحداث الحية

| القناة | الحدث | من يسمع |
|---|---|---|
| `user.{id}` | `wird.updated` · `session.analyzed` · `video.ready` · `review.received` | صاحب الحساب |
| `halaqa.{id}` | `member.submitted` · `exam.assigned` | أعضاء الحلقة |
| WebSocket التسميع | `word.ok` · `word.error` · `position` · `stall` | جلسة التسميع نفسها |
