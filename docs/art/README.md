# صور اللقطات وأصواتها

- **كتاب الصور:** `images/00-guide.md` يشرح طريقة العمل، وكل جزء في ملف (`01-stadium.md` إلى `14-fx.md`): لكل لوحة اسمها ومجلدها وأمر Nano Banana الخاص بها. يولّده `python3 tools/art-prompts/book5.py`، فلا تعدّل الملفات يدوياً.
- **مجلدات الصور:** `art/raw/` فيها 323 مجلداً جاهزاً، وفي كل مجلد `README.md` بأسماء اللوحات التي تُحفظ فيه. الفهرس في `art/raw/README.md`.
- **الأصوات:** `docs/audio/ARABIC_VOICE.md` فيه كل مقاطع المعلق العربي وأصوات الملعب، ومجلداتها جاهزة في `audio/raw/` بنفس الطريقة. يولّده `python3 tools/commentary/ar_catalog.py`.
- **بعد الرفع:** `art/raw/` ← أداة الصور (`tools/art/`، المهمة W14) ← أطلس `webp` للكمبيوتر والجوال في `web/public/match-art/` ← محرك المشهد [MATCH_VIEW 4.7]. والأصوات ← `arabic_voice.py build` ← حزم الصوت في `web/public/commentary/`.
