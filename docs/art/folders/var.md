# `art/raw/var/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 4 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** `art/raw/referee-1/ref.png`
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/var/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 253.1 | `steps-1.png` |  |
| IMAGE 2 | ⬜ | 253.2 | `steps-2.png` |  |
| IMAGE 3 | ⬜ | 253.3 | `steps-3.png` |  |
| IMAGE 4 | ⬜ | 253.4 | `close.png` |  |

## الرسالة

```
I need 4 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: Use the attached image as the reference for this exact same person: the same face, hair, body and clothes. He wears an all-black referee kit (black shirt, shorts and socks, black boots) with a whistle on a cord around his neck. Bald head, short dark beard, fit build. Photorealistic 3D render in the style of a modern console football game, lit by night stadium floodlights from high above and slightly behind: cool bluish white light with a bright rim light on the head, shoulders and arms, and slightly darker lower legs. Correct, natural anatomy in every pose: knees and elbows bend the natural way, both legs and both arms complete, feet pointing where the body moves, five fingers on each hand. The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each figure is easy to cut out. The image has no text, no numbers and no logos.

IMAGE 1 of 4 (steps-1.png, board 253.1): A wide 3:2 landscape image showing the same fictional man exactly three times, side by side in one row, every figure full body from head to boots, all at the same size and scale, with clear space between them and nothing cut off. There are exactly 3 figures, no more and no fewer, and no other people. Unless a pose says otherwise he is seen from the side, facing right. On the left: hand on his earpiece, listening, the other arm raised to stop play. In the middle: standing still, hand on his earpiece, alone, no other people. On the right: drawing a rectangle in the air with both index fingers, the video review sign. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn.

IMAGE 2 of 4 (steps-2.png, board 253.2): A wide 3:2 landscape image showing the same fictional man exactly three times, side by side in one row, every figure full body from head to boots, all at the same size and scale, with clear space between them and nothing cut off. There are exactly 3 figures, no more and no fewer, and no other people. Unless a pose says otherwise he is seen from the side, facing right. On the left: walking quickly towards the touchline. In the middle: bending forward, watching a screen in front of him, hands on hips, side view. On the right: watching a screen, seen from behind over his shoulder. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn.

IMAGE 3 of 4 (steps-3.png, board 253.3): A wide 3:2 landscape image showing the same fictional man exactly three times, side by side in one row, every figure full body from head to boots, all at the same size and scale, with clear space between them and nothing cut off. There are exactly 3 figures, no more and no fewer, and no other people. Unless a pose says otherwise he is seen from the side, facing right. On the left: waving both arms crossed low in front of him: no goal. In the middle: pointing firmly to the penalty spot after the review. On the right: running back onto the pitch, reaching for his pocket. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn.

IMAGE 4 of 4 (close.png, board 253.4): A wide 3:2 landscape image with 4 close-ups in a 2 by 2 grid, from the waist up, seen from the front facing the camera, all the same size with clear space between them. Top left: close-up from the waist up: hand on his earpiece, eyes closed, concentrating. Top right: close-up from the waist up: watching a screen, the screen glow lighting his face. Bottom left: close-up from the waist up: drawing the review rectangle in the air. Bottom right: close-up from the waist up: pointing firmly, decision made.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 4.
```
