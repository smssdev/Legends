# `art/raw/fx/light/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 6 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** لا شيء (أول صورة في الرسالة هي المرجع).
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/fx/light/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 326.1 | `flashes-01.png` |  |
| IMAGE 2 | ⬜ | 326.2 | `flashes-02.png` |  |
| IMAGE 3 | ⬜ | 326.3 | `flare-01.png` |  |
| IMAGE 4 | ⬜ | 326.4 | `flare-02.png` |  |
| IMAGE 5 | ⬜ | 326.5 | `spark-01.png` |  |
| IMAGE 6 | ⬜ | 326.6 | `spark-02.png` |  |

## الرسالة

```
I need 6 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: Visual effects for a football game. Only the effect itself is drawn: no people, no feet, no ball, no grass field and no ground, unless a frame names fans. Photorealistic render lit by cool night stadium floodlights from above. The background is pure black, because these are light effects. The image has no text, no numbers and no logos.

IMAGE 1 of 6 (flashes-01.png, board 326.1): A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame camera flashes loop for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. It is a seamless loop: the last frame leads smoothly back into the first. Left frame (frame 1): Scattered camera flashes in the dark, phase 1. Middle frame (frame 2): Scattered camera flashes in the dark, phase 2. Right frame (frame 3): Scattered camera flashes in the dark, phase 3.

IMAGE 2 of 6 (flashes-02.png, board 326.2): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame camera flashes loop for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. It is a seamless loop: the last frame leads smoothly back into the first. Left frame (frame 4): Scattered camera flashes in the dark, phase 4.

IMAGE 3 of 6 (flare-01.png, board 326.3): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame lens flare pulse for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): A floodlight lens flare, small. Middle frame (frame 2): The flare growing. Right frame (frame 3): The flare at its brightest.

IMAGE 4 of 6 (flare-02.png, board 326.4): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame lens flare pulse for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): The flare shrinking.

IMAGE 5 of 6 (spark-01.png, board 326.5): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame impact spark for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): A tiny white flash. Middle frame (frame 2): A bright star-shaped spark. Right frame (frame 3): The spark spreading.

IMAGE 6 of 6 (spark-02.png, board 326.6): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame impact spark for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): Fading.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 6.
```
