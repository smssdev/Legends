# `art/raw/bench/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 2 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** لا شيء (أول صورة في الرسالة هي المرجع).
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/bench/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 301.1 | `sheet-1-a.png` |  |
| IMAGE 2 | ⬜ | 301.2 | `sheet-1-b.png` |  |

## الرسالة

```
I need 2 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: A wide 3:2 landscape image showing 3 different fictional footballers, each with a different look side by side in one row, every figure full body from head to boots, all at the same size and scale, with clear space between them and nothing cut off. There are exactly 3 figures, no more and no fewer, and no other people. Unless a pose says otherwise he is seen from the side, facing right. They wear plain pure white training tops and shorts with plain white bibs, white socks and black boots. The kit must be pure white, because the game paints the team colours on it. Different fictional people in each cell, varied looks. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn. Photorealistic 3D render in the style of a modern console football game, lit by night stadium floodlights from high above and slightly behind: cool bluish white light with a bright rim light on the head, shoulders and arms, and slightly darker lower legs. Correct, natural anatomy in every pose: knees and elbows bend the natural way, both legs and both arms complete, feet pointing where the body moves, five fingers on each hand. The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each figure is easy to cut out. The image has no text, no numbers and no logos.

IMAGE 1 of 2 (sheet-1-a.png, board 301.1): On the left: sitting on a bench seat, leaning forward, watching. In the middle: standing, cheering with both arms up. On the right: jumping with joy, fists up.

IMAGE 2 of 2 (sheet-1-b.png, board 301.2): Use the attached image as the reference for the style, light and kit. On the left: jogging and warming up, knees high. In the middle: standing, both hands on his head. On the right: standing and applauding.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 2.
```
