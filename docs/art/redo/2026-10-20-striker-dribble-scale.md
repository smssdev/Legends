# إعادة صور المهاجم: الدريبل بالمقياس الصحيح (مراجعة 2026-10-20)

> - **السليمة** باقية في مجلدها، وهي ✅ في `docs/sprints/sprint-02-days.md`.
> - **التي تحتاج إعادة** حُذفت من المجلد حتى تُصنع من جديد، وتبقى نسختها في تاريخ git.
> - **لكل صورة هنا:** المشكلة، والمرفقات، والأمر كاملاً من الكتاب وفي آخره **سطر التصحيح**. انسخ الأمر كما هو في محادثة جديدة، وارفق الملفات المذكورة.

## ما حدث للملفات

- **الوضعيات صحيحة،** واعتُمدت أولاً. لكن اللوحتين مربعتان (1024x1024)، فرسم Gemini الأشكال أصغر: في اللعبة يصغر اللاعب حوالي 25% حين يبدأ الدريبل.
- **الإصلاح:** نفس الوضعيات في صورة عريضة 3:2 وبطول الجري. ارفق نسختك المربعة القديمة (عندك على جهازك، وفي تاريخ git) دليلاً للوضعيات، و`run-side-01.png` دليلاً للحجم.
- **أداة البناء** صارت تنبّه لأي لوحة ليست 3:2، وتوحّد دقة الصور (1024x687 و2528x1696 تُعامل مثل 1264x848).

## السليمة (0)

| اللوحة | الملف |
|---|---|

## تحتاج إعادة (1)

**أكثر مشكلة تكررت:** لوحة مربعة بدل 3:2، فالأشكال أصغر من باقي الحركات.

| اللوحة | الملف | المشكلة |
|---|---|---|
| 48.2 | `art/raw/striker/ball/dribble-02.png` | مربعة 1:1، فالأشكال أصغر 25% من الجري (الوضعيات صحيحة) |

### 48.2 `dribble-02.png`

**المشكلة:** مربعة 1:1، فالأشكال أصغر 25% من الجري (الوضعيات صحيحة)  
**المجلد:** `art/raw/striker/ball/`  
**ارفق:** `art/raw/striker/ref.png` و`art/raw/striker/ball/dribble-01.png`

```
Use the attached images: the reference card for this exact same person (same face, hair, body and clothes) and the previous frames, to continue the same motion at the same scale and on the same ground line. A wide 3:2 landscape image with 3 animation frames side by side in one row: frames 4 to 6 of an 8-frame dribbling sequence. The image shows exactly 3 figures of this same one person, one per frame, from left to right in frame order: no more, no fewer, and no other people. The character is a fictional male footballer in a plain pure white kit (white shirt, white shorts, white socks) and black boots, no logos or numbers (the game paints the team colours on the white), short dark brown hair, light olive skin, light stubble, athletic striker build. He is seen exactly from the side, his body and face turned to the right, so the camera sees his right side: his right leg and right arm are the near ones, closest to the camera, and his left leg and left arm are the far ones; whenever he moves, he moves to the right. These are consecutive animation frames for a 2D game sprite sheet, evenly spaced in time: each frame moves on one clear step of the motion from the one before, like a real animation cycle, and no two frames are the same. Every frame shows the whole figure from head to feet at exactly the same scale, standing on the same invisible ground line (the ground line is at the same height in every frame), with clear space between frames and nothing cut off. Each frame is a clearly different pose from the others in this image; never repeat a pose. Do not copy any pose from the attached previous image: draw the next poses of the motion. Left frame (frame 4): Dribbling at speed, looking down at a ball that is not shown: both feet off the ground, the far (left) knee driven forward, the near (right) leg extended behind. Middle frame (frame 5): Dribbling at speed, looking down at a ball that is not shown: the far (left) foot just touching the ball down in front of the body heel first, the near (right) leg stretched behind, the near (right) arm forward. Right frame (frame 6): Dribbling at speed, looking down at a ball that is not shown: the far (left) foot flat under the hips taking the weight, knee slightly bent, the near (right) leg swinging forward low. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn. Photorealistic 3D render in the style of a modern console football game, lit by night stadium floodlights from high above and slightly behind: cool bluish white light with a bright rim light on the head, shoulders and arms, and slightly darker lower legs. Correct, natural anatomy in every pose: knees and elbows bend the natural way, both legs and both arms complete, feet pointing where the body moves, five fingers on each hand. The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each figure is easy to cut out. The image has no text, no numbers and no logos. Make it a wide 3:2 landscape image (like 1264x848), never square. Draw every figure as tall as in the attached run-side-01.png: from the top of the head to the soles about four fifths of the image height. Keep exactly the poses of your earlier square version, attached as the pose guide. He looks down at the ball that is not drawn, his head tilted forward.
```

