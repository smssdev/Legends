# إعادة صور المهاجم: الجري ثلاثة أرباع من الخلف، ومن الأمام، ومن الخلف (الإعادة الأولى) (مراجعة 2026-10-20)

> - **السليمة** باقية في مجلدها، وهي ✅ في `docs/sprints/sprint-02-days.md`.
> - **التي تحتاج إعادة** حُذفت من المجلد حتى تُصنع من جديد، وتبقى نسختها في تاريخ git.
> - **لكل صورة هنا:** المشكلة، والمرفقات، والأمر كاملاً من الكتاب وفي آخره **سطر التصحيح**. انسخ الأمر كما هو في محادثة جديدة، وارفق الملفات المذكورة.

## ما حدث للملفات

- **تحسن واضح:** الزوايا كلها صحيحة الآن، والخلفية سادة، والأشباح اختفت. run-q-back-01 معتمدة.
- **المشكلة الجديدة في الأمام والخلف: الرجل الواقفة تتبدل كل إطار.** في الإطارات 1 و2 و3 يجب أن يقف على نفس الرجل (هبوط، ثم حمل، ثم دفع)، والإطار 4 والإطار 8 طيران. لو تبدلت كل إطار، يبدو في اللعبة كأنه يرتجف في مكانه. الأوامر الجديدة تحدد كل رجل بجهتها في الصورة، لأن Gemini يخلط اليمين واليسار من الخلف.
- **الأوامر مكتوبة من جديد** أقصر وأوضح: من هو، وشكل الصورة، ثم سطر لكل شكل.
- **الصيغة:** الصور كلها JPEG بدقة 1024x687. أداة البناء توحّد المقياس، لكن الأفضل تنزيل الصورة بحجمها الكامل وحفظها PNG.

## السليمة (1)

| اللوحة | الملف |
|---|---|
| 45.7 | ✅ `art/raw/striker/run/run-q-back-01.png` |

## أمر واحد لكل حركة (الأسهل)

> **محادثة جديدة لكل حركة.** ارفق الملفات، والصق الأمر. يرسم Gemini الصور واحدة بعد الأخرى بنفس الشخص والمقياس. وإن رسم صورة واحدة فقط وتوقف، اكتب **next** فيرسم التالية في نفس المحادثة. احفظ كل صورة باسمها المكتوب في الأمر (IMAGE 1 = الاسم الأول).

### الجري ثلاثة أرباع من الخلف: run-q-back-02 ثم run-q-back-03

**ارفق:** `art/raw/striker/ref.png` و`art/raw/striker/run/run-q-back-01.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. Make 2 separate images, one after another, in this order: each one continues the same run from the last pose of the one before, with the same man, the same camera, the same size and the same ground line. Every image: ONE wide 3:2 landscape image (not square, not separate panels) with exactly the given number of figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: three-quarter view from behind. We see his back and the back of his head, his face is hidden, and he runs away from the camera diagonally to the right, with the same camera angle as the attached run-q-back-01.png. That image shows the EARLIER frames 1 to 3, which are already made: use it only for the angle and the size, and never redraw its poses. Every figure here is a NEW pose that comes after them. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. IMAGE 1 of 2 (run-q-back-02, frames 4 to 6, exactly 3 figures): Figure 1: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; the left knee driven forward, the right leg stretched out behind. Figure 2: the left foot just landing on the ground in front of him, heel first; the right leg stretched behind; the right arm swinging forward. Figure 3: standing on the left foot, flat, right under his hips, knee slightly bent; the right foot off the ground, swinging forward low next to the left ankle. Figures 2 and 3 must look clearly different: in figure 2 the feet are far apart, in figure 3 they are close together. IMAGE 2 of 2 (run-q-back-03, frames 7 to 8, exactly 2 figures): Figure 1: pushing off: only the toes of the left foot still touch the ground far behind him, the left leg almost straight; the right knee lifted high in front at hip height, the right foot off the ground. Figure 2: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; the right knee driven forward, the left leg stretched out behind. The two figures must look clearly different: in the first one toe touches the ground, in the second nothing touches the ground. If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 2.
```

### الجري من الأمام: run-front-01 وحدها

**ارفق:** `art/raw/striker/ref.png` و`art/raw/striker/run/run-front-02.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. ONE wide 3:2 landscape image (not square, not separate panels) with exactly 3 figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: straight from the front. He faces the camera and runs straight towards it. Because he faces us, his RIGHT leg is on the LEFT side of the image and his LEFT leg is on the RIGHT side. Match the size and style of the attached run-front-02.png. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. Figure 1: his right foot (on the LEFT side of the image) landing on the ground in front of him; his left foot (on the RIGHT side of the image) lifted off the ground behind him; his left arm forward. Figure 2: his weight on his right foot (LEFT side of the image), flat under his body, knee slightly bent; his left foot (RIGHT side) off the ground, passing forward low next to the standing ankle. Figure 3: his right foot (LEFT side) pushing off on its toes; his left knee (RIGHT side) lifted high in front at hip height. In all three figures he stands on the leg on the LEFT side of the image, and the foot on the RIGHT side of the image is off the ground.
```

### الجري من الخلف: run-back-01 ثم run-back-02 ثم run-back-03

**ارفق:** `art/raw/striker/ref.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. Make 3 separate images, one after another, in this order: each one continues the same run from the last pose of the one before, with the same man, the same camera, the same size and the same ground line. Every image: ONE wide 3:2 landscape image (not square, not separate panels) with exactly the given number of figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: straight from behind. We see only his back and the back of his head, and he runs straight away from the camera. Because we see his back, his RIGHT leg is on the RIGHT side of the image and his LEFT leg is on the LEFT side. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. IMAGE 1 of 3 (run-back-01, frames 1 to 3, exactly 3 figures): Figure 1: his right foot (RIGHT side of the image) landing on the ground; his left foot (LEFT side) kicked up behind him, the sole of the boot visible. Figure 2: his weight on his right foot (RIGHT side), flat under his body, knee slightly bent; his left foot (LEFT side) off the ground, swinging forward low. Figure 3: his right foot (RIGHT side) pushing off on its toes; his left knee (LEFT side) lifted high in front of him, so his left lower leg is partly hidden by his body. In all three figures he stands on the leg on the RIGHT side of the image, and the foot on the LEFT side of the image is off the ground. IMAGE 2 of 3 (run-back-02, frames 4 to 6, exactly 3 figures): Figure 1: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; his left knee forward, his right foot (RIGHT side of the image) kicked up behind him, the sole of the boot visible. Figure 2: his left foot (LEFT side of the image) landing on the ground; his right foot (RIGHT side) kicked up behind him, the sole visible. Figure 3: his weight on his left foot (LEFT side), flat under his body, knee slightly bent; his right foot (RIGHT side) off the ground, swinging forward low. In figures 2 and 3 he stands on the leg on the LEFT side of the image, and the foot on the RIGHT side is off the ground. IMAGE 3 of 3 (run-back-03, frames 7 to 8, exactly 2 figures): Figure 1: his left foot (LEFT side of the image) pushing off on its toes behind him; his right knee (RIGHT side) lifted high in front, so his right lower leg is partly hidden by his body. Figure 2: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; his right knee forward, his left foot (LEFT side) kicked up behind him, the sole of the boot visible. The two figures must look clearly different: in the first one toe touches the ground, in the second nothing touches the ground. If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 3.
```

## أو صورة صورة

إن لم ينجح الأمر الواحد، كل صورة بأمرها تحت.

## تحتاج إعادة (3)

**أكثر مشكلة تكررت:** الرجل الواقفة تتبدل كل إطار بدل أن تبقى نفسها في الإطارات 1 إلى 3 و5 إلى 7، وإطارات الطيران على الأرض.

| اللوحة | الملف | المشكلة |
|---|---|---|
| 45.13 | `art/raw/striker/run/run-back-01.png` | الرجل الواقفة تتبدل كل إطار (يسرى، يمنى، يسرى)، والمطلوب اليمنى في الثلاثة |
| 45.14 | `art/raw/striker/run/run-back-02.png` | الإطار 4 بقدمين على الأرض والمطلوب طيران، والإطاران 5 و6 على رجلين مختلفتين |
| 45.15 | `art/raw/striker/run/run-back-03.png` | الإطاران 7 و8 متطابقان تقريباً، والإطار 8 ليس طيراناً |

### 45.13 `run-back-01.png`

**المشكلة:** الرجل الواقفة تتبدل كل إطار (يسرى، يمنى، يسرى)، والمطلوب اليمنى في الثلاثة  
**المجلد:** `art/raw/striker/run/`  
**ارفق:** `art/raw/striker/ref.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. ONE wide 3:2 landscape image (not square, not separate panels) with exactly 3 figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: straight from behind. We see only his back and the back of his head, and he runs straight away from the camera. Because we see his back, his RIGHT leg is on the RIGHT side of the image and his LEFT leg is on the LEFT side. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. Figure 1: his right foot (RIGHT side of the image) landing on the ground; his left foot (LEFT side) kicked up behind him, the sole of the boot visible. Figure 2: his weight on his right foot (RIGHT side), flat under his body, knee slightly bent; his left foot (LEFT side) off the ground, swinging forward low. Figure 3: his right foot (RIGHT side) pushing off on its toes; his left knee (LEFT side) lifted high in front of him, so his left lower leg is partly hidden by his body. In all three figures he stands on the leg on the RIGHT side of the image, and the foot on the LEFT side of the image is off the ground.
```

### 45.14 `run-back-02.png`

**المشكلة:** الإطار 4 بقدمين على الأرض والمطلوب طيران، والإطاران 5 و6 على رجلين مختلفتين  
**المجلد:** `art/raw/striker/run/`  
**ارفق:** `art/raw/striker/ref.png` و`art/raw/striker/run/run-back-01.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. ONE wide 3:2 landscape image (not square, not separate panels) with exactly 3 figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: straight from behind. We see only his back and the back of his head, and he runs straight away from the camera. Because we see his back, his RIGHT leg is on the RIGHT side of the image and his LEFT leg is on the LEFT side. Continue the attached run-back-01.png at the same size. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. Figure 1: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; his left knee forward, his right foot (RIGHT side of the image) kicked up behind him, the sole of the boot visible. Figure 2: his left foot (LEFT side of the image) landing on the ground; his right foot (RIGHT side) kicked up behind him, the sole visible. Figure 3: his weight on his left foot (LEFT side), flat under his body, knee slightly bent; his right foot (RIGHT side) off the ground, swinging forward low. In figures 2 and 3 he stands on the leg on the LEFT side of the image, and the foot on the RIGHT side is off the ground.
```

### 45.15 `run-back-03.png`

**المشكلة:** الإطاران 7 و8 متطابقان تقريباً، والإطار 8 ليس طيراناً  
**المجلد:** `art/raw/striker/run/`  
**ارفق:** `art/raw/striker/ref.png` و`art/raw/striker/run/run-back-02.png`

```
Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit (shirt, shorts, socks) and black boots, no logos or numbers. ONE wide 3:2 landscape image (not square, not separate panels) with exactly 2 figures of him in one row, left to right, all the same size, feet on the same ground line, each figure about four fifths of the image height, clear space between them, nothing cut off. Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. Photorealistic 3D render like a modern console football game. No ball. Camera: straight from behind. We see only his back and the back of his head, and he runs straight away from the camera. Because we see his back, his RIGHT leg is on the RIGHT side of the image and his LEFT leg is on the LEFT side. Continue the attached run-back-02.png at the same size. He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, never arms hanging down, never walking. Every figure is a different pose. Figure 1: his left foot (LEFT side of the image) pushing off on its toes behind him; his right knee (RIGHT side) lifted high in front, so his right lower leg is partly hidden by his body. Figure 2: in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot; his right knee forward, his left foot (LEFT side) kicked up behind him, the sole of the boot visible. The two figures must look clearly different: in the first one toe touches the ground, in the second nothing touches the ground.
```

