# `art/raw/linesman/move/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 4 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** `art/raw/linesman/ref.png`
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/linesman/move/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 246.1 | `side-run-01.png` |  |
| IMAGE 2 | ⬜ | 246.2 | `side-run-02.png` |  |
| IMAGE 3 | ⬜ | 246.3 | `flag-01.png` |  |
| IMAGE 4 | ⬜ | 246.4 | `flag-02.png` |  |

## الرسالة

```
I need 4 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: The character is a fictional assistant referee in an all-black kit holding a red and yellow flag, short grey hair. These are consecutive animation frames for a 2D game sprite sheet, evenly spaced in time: each frame moves on one clear step of the motion from the one before, like a real animation cycle, and no two frames are the same. Every frame shows the whole figure from head to feet at exactly the same scale, standing on the same invisible ground line (the ground line is at the same height in every frame), with clear space between frames and nothing cut off. There is no ball anywhere in the image, because the game draws the ball itself: where a pose mentions the ball, the body moves exactly as if the ball were there, but the ball is not drawn. Photorealistic 3D render in the style of a modern console football game, lit by night stadium floodlights from high above and slightly behind: cool bluish white light with a bright rim light on the head, shoulders and arms, and slightly darker lower legs. Correct, natural anatomy in every pose: knees and elbows bend the natural way, both legs and both arms complete, feet pointing where the body moves, five fingers on each hand. The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each figure is easy to cut out. The image has no text, no numbers and no logos.

IMAGE 1 of 4 (side-run-01.png, board 246.1): Use the attached reference card for this exact same person: the same face, hair, body and clothes, at the same scale. A wide 3:2 landscape image with 3 animation frames side by side in one row: frames 1 to 3 of a 6-frame side-running along the line sequence. The image shows exactly 3 figures of this same one person, one per frame, from left to right in frame order: no more, no fewer, and no other people. He is seen from the front, facing the camera, on the touchline; when he moves, he side-steps towards the right of the image without turning. Each frame is a clearly different pose from the others in this image; never repeat a pose. Left frame (frame 1): Side-stepping to the right, flag down in the right hand. Middle frame (frame 2): Feet wide apart, flag down. Right frame (frame 3): Feet together, flag down.

IMAGE 2 of 4 (side-run-02.png, board 246.2): Use the attached images: the reference card for this exact same person (same face, hair, body and clothes) and the previous frames, to continue the same motion at the same scale and on the same ground line. A wide 3:2 landscape image with 3 animation frames side by side in one row: frames 4 to 6 of a 6-frame side-running along the line sequence. The image shows exactly 3 figures of this same one person, one per frame, from left to right in frame order: no more, no fewer, and no other people. He is seen from the front, facing the camera, on the touchline; when he moves, he side-steps towards the right of the image without turning. Each frame is a clearly different pose from the others in this image; never repeat a pose. Do not copy any pose from the attached previous image: draw the next poses of the motion. Left frame (frame 4): Feet wide apart again, flag down. Middle frame (frame 5): Feet together again, flag down. Right frame (frame 6): Side-stepping on to the right, flag down.

IMAGE 3 of 4 (flag-01.png, board 246.3): Use the attached reference card for this exact same person: the same face, hair, body and clothes, at the same scale. A wide 3:2 landscape image with 3 animation frames side by side in one row: frames 1 to 3 of a 4-frame raising the flag sequence. The image shows exactly 3 figures of this same one person, one per frame, from left to right in frame order: no more, no fewer, and no other people. He is seen from the front, facing the camera, standing on the same spot in every frame. Each frame is a clearly different pose from the others in this image; never repeat a pose. Left frame (frame 1): Standing, flag down in the right hand. Middle frame (frame 2): Lifting the flag in the right hand. Right frame (frame 3): Flag held straight up above his head.

IMAGE 4 of 4 (flag-02.png, board 246.4): Use the attached images: the reference card for this exact same person (same face, hair, body and clothes) and the previous frames, to continue the same motion at the same scale and on the same ground line. A wide 3:2 landscape image with one single animation frame, centred: frame 4 of a 4-frame raising the flag sequence. The image shows exactly one figure, centred, and no other people. He is seen from the front, facing the camera, standing on the same spot in every frame. Do not copy any pose from the attached previous image: draw the next poses of the motion. Frame (frame 4): Flag held out straight forward at shoulder height: offside.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 4.
```
