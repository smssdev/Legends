# `art/raw/fx/ground/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 8 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** لا شيء (أول صورة في الرسالة هي المرجع).
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/fx/ground/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 323.1 | `grass-01.png` |  |
| IMAGE 2 | ⬜ | 323.2 | `grass-02.png` |  |
| IMAGE 3 | ⬜ | 323.3 | `water-01.png` |  |
| IMAGE 4 | ⬜ | 323.4 | `water-02.png` |  |
| IMAGE 5 | ⬜ | 323.5 | `snow-01.png` |  |
| IMAGE 6 | ⬜ | 323.6 | `snow-02.png` |  |
| IMAGE 7 | ⬜ | 323.7 | `dust-01.png` |  |
| IMAGE 8 | ⬜ | 323.8 | `dust-02.png` |  |

## الرسالة

```
I need 8 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: Visual effects for a football game. Only the effect itself is drawn: no people, no feet, no ball, no grass field and no ground, unless a frame names fans. Photorealistic render lit by cool night stadium floodlights from above. The background is one flat, solid magenta (#FF00FF) with nothing else on it, so each item is easy to cut out. The image has no text, no numbers and no logos.

IMAGE 1 of 8 (grass-01.png, board 323.1): A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 6-frame grass spray for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): A small burst at the point where a kick hits the turf, only the first specks of grass. Middle frame (frame 2): Grass and soil starting to fly up. Right frame (frame 3): A spray of grass and soil in the air.

IMAGE 2 of 8 (grass-02.png, board 323.2): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 4 to 6 of a 6-frame grass spray for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 4): The spray spreading and rising. Middle frame (frame 5): Clumps falling back. Right frame (frame 6): Last bits settling.

IMAGE 3 of 8 (water-01.png, board 323.3): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 6-frame water splash for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): The first small splash where a foot hits wet grass. Middle frame (frame 2): Water starting to splash. Right frame (frame 3): A wide splash of water.

IMAGE 4 of 8 (water-02.png, board 323.4): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 4 to 6 of a 6-frame water splash for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 4): Drops flying outward. Middle frame (frame 5): Drops falling. Right frame (frame 6): Last drops.

IMAGE 5 of 8 (snow-01.png, board 323.5): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 6-frame snow burst for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): The first small puff where a kick hits snow. Middle frame (frame 2): Snow bursting up. Right frame (frame 3): A cloud of snow.

IMAGE 6 of 8 (snow-02.png, board 323.6): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 4 to 6 of a 6-frame snow burst for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 4): The cloud spreading. Middle frame (frame 5): Snow falling back. Right frame (frame 6): Last flakes.

IMAGE 7 of 8 (dust-01.png, board 323.7): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with exactly 3 consecutive animation frames side by side in one row, no more and no fewer: frames 1 to 3 of a 4-frame landing dust for a 2D game, evenly spaced in time, each frame the same size and centred in its third of the image, each moving on only slightly from the one before. Left frame (frame 1): The first small puff where a body hits the ground. Middle frame (frame 2): A puff of dust and grass rising. Right frame (frame 3): The puff spreading.

IMAGE 8 of 8 (dust-02.png, board 323.8): Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame landing dust for a 2D game, evenly spaced in time, each frame the same size and centred in the image, each moving on only slightly from the one before. Left frame (frame 4): Fading.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 8.
```
