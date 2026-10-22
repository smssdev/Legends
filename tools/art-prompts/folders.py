"""One message per image folder: python3 tools/art-prompts/folders.py (tools/team.py runs it too)

docs/art/FOLDERS.md lists every folder under art/raw/ with who makes it and how far it is. For every folder
with images still to make, docs/art/folders/<folder>.md holds ONE message to paste into a new Gemini chat:
the rules every image of the folder shares, written once, then each image (redo first, with its correction
line) by its file name. Gemini makes them one after another, and "next" asks for the following one.
"""
import os, re, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path[:0] = [os.path.join(ROOT, 'tools'), os.path.dirname(os.path.abspath(__file__))]
import team            # noqa: E402
import redo as R       # noqa: E402

DOCS = os.path.join(ROOT, 'docs', 'art')
OUT = os.path.join(DOCS, 'folders')
WORD = {'done': '✅', 'pending': '⏳', 'redo': '🔁', 'todo': '⬜'}


def sentences(p):
    return [s.strip() for s in re.split(r'(?<=[.:])\s+(?=[A-Z])', p) if s.strip()]


def slug(folder):
    return folder.removeprefix('art/raw/').strip('/').replace('/', '-')


def prompt_of(b, books, redo):
    """(attachments, prompt) of one board: the book's, or the redo file's with its correction line."""
    wave, code, path, md, g = b
    books.setdefault(md, open(os.path.join(ROOT, 'docs', 'art', 'images', md), encoding='utf-8').read())
    name, att, prompt = R.entry(books[md], code)
    if path in redo:
        fix = next(f for rv in R.REVIEWS for k, folder, why, f in rv['redo'] if k == code)
        if isinstance(fix, dict):
            return fix['attach'], fix['prompt']
        prompt = prompt + ' ' + fix
    return re.findall(r'`([^`]+)`', att), prompt


def message(rows):
    """One message for a folder: shared rules once, then image by image."""
    sents = [sentences(p) for *_, p in rows]
    common = [s for s in sents[0] if all(s in x for x in sents[1:])] if len(rows) > 1 else []
    n = len(rows)
    out = [f'I need {n} separate images for my 2D football game, made one after another in this order, each as its own image. '
           'When an image says "the attached" reference or previous image and that file is one of the earlier images of this '
           'list, use that earlier image you made in this chat.']
    if common:
        out.append('RULES FOR EVERY IMAGE: ' + ' '.join(common))
    for i, (b, att, p) in enumerate(rows, 1):
        own = ' '.join(s for s in sentences(p) if s not in common)
        out.append(f'IMAGE {i} of {n} ({os.path.basename(b[2])}, board {b[1]}): {own}')
    out.append(f'If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE {n}.')
    return '\n\n'.join(out)


def main():
    boards, redo, st = team.image_states()
    by = team.made_by()
    folders = {}
    for b in boards:
        folders.setdefault(os.path.dirname(b[2]), []).append(b)
    books = {}
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith('.md'):
            os.remove(os.path.join(OUT, f))
    index = []
    for folder, bs in folders.items():
        left = [b for b in bs if st[b[2]] in ('redo', 'todo')]
        left = [b for b in left if st[b[2]] == 'redo'] + [b for b in left if st[b[2]] == 'todo']
        count = {k: sum(1 for b in bs if st[b[2]] == k) for k in WORD}
        owners = sorted({team.NAME[team.who_makes(b, st)] for b in (left or bs)})
        index.append((min(b[0] for b in bs), folder, owners, count, len(bs), bool(left)))
        if not left:
            continue
        rows = [(b, *prompt_of(b, books, redo)) for b in left]
        made = {b[2] for b in left}
        attach = []
        for b, att, p in rows:
            for a in att:
                if a not in attach and a not in made:
                    attach.append(a)
        o = []
        W = o.append
        W(f'# `{folder}/`: كل المطلوب في رسالة واحدة\n')
        W('> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`)، فلا يُعدَّل يدوياً. والفهرس في [`FOLDERS.md`](../FOLDERS.md).\n')
        W(f"**من:** {' و'.join(owners)} · **الحالة:** ✅ {count['done']} مكتملة · ⏳ {count['pending']} تنتظر المراجعة · 🔁 {count['redo']} يجب إعادتها · ⬜ {count['todo']} لم يُعمل عليها.\n")
        W('## الخطوات\n')
        W('1. **محادثة جديدة** في Gemini.')
        W('2. **ارفق:** ' + ('، '.join(f'`{a}`' for a in attach) if attach else 'لا شيء (أول صورة في الرسالة هي المرجع).'))
        W('3. **الصق الرسالة كلها** من الصندوق تحت. وإن رسم صورة واحدة وتوقف، اكتب **next**.')
        W('4. **احفظ كل صورة PNG حقيقياً** باسمها في الجدول، في `' + folder + '/`، ثم ارفعها وقل «راجع».\n')
        W('| الترتيب | الحالة | اللوحة | الملف | ملاحظة |'); W('|---|---|---|---|---|')
        for i, (b, att, p) in enumerate(rows, 1):
            note = redo[b[2]][1] if st[b[2]] == 'redo' else ''
            W(f'| IMAGE {i} | {WORD[st[b[2]]]} | {b[1]} | `{os.path.basename(b[2])}` | {note} |')
        W('\n## الرسالة\n')
        W('```')
        W(message(rows))
        W('```')
        open(os.path.join(OUT, slug(folder) + '.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')

    o = []
    W = o.append
    W('# المجلدات: كل مجلد صور برسالة واحدة\n')
    W('> يولّده `python3 tools/art-prompts/folders.py` (ويشغّله `tools/team.py`) بعد كل رفع أو مراجعة، فلا يُعدَّل يدوياً.')
    W('> لكل مجلد فيه عمل: ملف برسالة واحدة تنسخها كاملة في محادثة Gemini جديدة، فيها قواعده المشتركة مرة واحدة، ثم كل صورة باسمها (الإعادة أولاً بسطر تصحيحها).\n')
    W('**الحالة:** ✅ مكتملة · ⏳ تنتظر المراجعة · 🔁 يجب إعادتها · ⬜ لم يُعمل عليها.\n')
    for nm in ('سليمان', 'حمزة'):
        mine = [x for x in index if nm in x[2]]
        W(f'## {nm}\n')
        W('| الدفعة | المجلد | من | ✅ | ⏳ | 🔁 | ⬜ | الرسالة |'); W('|---|---|---|---|---|---|---|---|')
        for wave, folder, owners, c, total, left in sorted(mine):
            ln = f'[`{slug(folder)}.md`](folders/{slug(folder)}.md)' if left else 'مكتمل'
            W(f"| {wave} | `{folder.removeprefix('art/raw/')}/` | {' و'.join(owners)} | {c['done']} | {c['pending']} | {c['redo']} | {c['todo']} | {ln} |")
        W('')
    open(os.path.join(DOCS, 'FOLDERS.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
    return len(index), sum(1 for x in index if x[5])


if __name__ == '__main__':
    print('folders, with work left:', main())
