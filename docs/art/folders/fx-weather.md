# `art/raw/fx/weather/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 6 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** لا شيء (أول صورة في الرسالة هي المرجع).
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/fx/weather/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 324.1 | `rain-01.png` |  |
| IMAGE 2 | ⬜ | 324.2 | `rain-02.png` |  |
| IMAGE 3 | ⬜ | 324.3 | `snow-01.png` |  |
| IMAGE 4 | ⬜ | 324.4 | `snow-02.png` |  |
| IMAGE 5 | ⬜ | 324.5 | `fog-01.png` |  |
| IMAGE 6 | ⬜ | 324.6 | `fog-02.png` |  |

## الرسالة

```
I need 6 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: It is a seamless loop: the last frame leads smoothly back into the first. Visual effects for a football game. Only the effect itself is drawn: no people, no feet, no ball, no grass field and no ground, unless a frame names fans. Photorealistic render lit by cool night stadium floodlights from above. The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each frame is easy to cut out. The image has no text, no numbers and no logos.

IMAGE 1 of 6 (rain-01.png, board 324.1): A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame rain loop for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): Rain streaks across the whole frame, phase 1 of a seamless loop. Middle frame (frame 2): Rain streaks across the whole frame, phase 2 of a seamless loop. Right frame (frame 3): Rain streaks across the whole frame, phase 3 of a seamless loop.

IMAGE 2 of 6 (rain-02.png, board 324.2): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame rain loop for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): Rain streaks across the whole frame, phase 4 of a seamless loop.

IMAGE 3 of 6 (snow-01.png, board 324.3): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame snowfall loop for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): Snowflakes across the whole frame, phase 1 of a seamless loop. Middle frame (frame 2): Snowflakes across the whole frame, phase 2 of a seamless loop. Right frame (frame 3): Snowflakes across the whole frame, phase 3 of a seamless loop.

IMAGE 4 of 6 (snow-02.png, board 324.4): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame snowfall loop for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): Snowflakes across the whole frame, phase 4 of a seamless loop.

IMAGE 5 of 6 (fog-01.png, board 324.5): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame drifting fog loop for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): A soft layer of white fog drifting, phase 1 of a seamless loop. Middle frame (frame 2): A soft layer of white fog drifting, phase 2 of a seamless loop. Right frame (frame 3): A soft layer of white fog drifting, phase 3 of a seamless loop.

IMAGE 6 of 6 (fog-02.png, board 324.6): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame drifting fog loop for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): A soft layer of white fog drifting, phase 4 of a seamless loop.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 6.
```
