# `art/raw/scenes/`: كل المطلوب في رسالة واحدة

> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).

**من:** سليمان · **الحالة:** ✅ 0 مكتملة · ⏳ 0 تنتظر المراجعة · 🔁 0 يجب إعادتها · ⬜ 8 لم يُعمل عليها.

## الخطوات

1. **محادثة جديدة** في Gemini.
2. **ارفق:** لا شيء (أول صورة في الرسالة هي المرجع).
3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.
4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `art/raw/scenes/`، ثم ارفعها وقل «راجع».

| الترتيب | الحالة | اللوحة | الملف | ملاحظة |
|---|---|---|---|---|
| IMAGE 1 | ⬜ | 16.1 | `aerial-night.jpg` |  |
| IMAGE 2 | ⬜ | 16.2 | `aerial-day.jpg` |  |
| IMAGE 3 | ⬜ | 16.3 | `tunnel.jpg` |  |
| IMAGE 4 | ⬜ | 16.4 | `dressing-room.jpg` |  |
| IMAGE 5 | ⬜ | 16.5 | `dressing-joy.jpg` |  |
| IMAGE 6 | ⬜ | 16.6 | `fans-arrive.jpg` |  |
| IMAGE 7 | ⬜ | 16.7 | `team-bus.jpg` |  |
| IMAGE 8 | ⬜ | 16.8 | `press-room.jpg` |  |

## الرسالة

```
I need 8 separate images for my 2D football game, made one after another in this order, each as its own image. When an image says "the attached" reference or previous image and that file is one of the earlier images of this list, use that earlier image you made in this chat.

RULES FOR EVERY IMAGE: A wide 16:9 landscape photograph. Photorealistic and cinematic, like a live TV broadcast. The image has no text, no numbers and no logos.

IMAGE 1 of 8 (aerial-night.jpg, board 16.1): Aerial drone view of a full football stadium at night, floodlights on, the lit pitch, city lights around.

IMAGE 2 of 8 (aerial-day.jpg, board 16.2): Use the attached image as the reference for the style, light and colours. Aerial drone view of a football stadium on a sunny day, crowds arriving.

IMAGE 3 of 8 (tunnel.jpg, board 16.3): Use the attached image as the reference for the style, light and colours. Inside the players tunnel looking out to the bright pitch and the crowd, no people.

IMAGE 4 of 8 (dressing-room.jpg, board 16.4): Use the attached image as the reference for the style, light and colours. A dressing room: benches, hanging plain white shirts without numbers, a blank tactics board, no people.

IMAGE 5 of 8 (dressing-joy.jpg, board 16.5): Use the attached image as the reference for the style, light and colours. A dressing room after a win: plain white shirts thrown around, confetti, an empty trophy plinth, no people.

IMAGE 6 of 8 (fans-arrive.jpg, board 16.6): Use the attached image as the reference for the style, light and colours. Crowds of fans with plain scarves walking towards a lit stadium at dusk, faces blurred.

IMAGE 7 of 8 (team-bus.jpg, board 16.7): Use the attached image as the reference for the style, light and colours. A plain white team coach bus arriving at a stadium entrance at night, fans behind barriers, faces blurred.

IMAGE 8 of 8 (press-room.jpg, board 16.8): Use the attached image as the reference for the style, light and colours. An empty post-match press conference room: a table with microphones, a plain backdrop, rows of empty chairs.

If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE 8.
```
