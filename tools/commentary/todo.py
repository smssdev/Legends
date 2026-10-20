"""Hamza's audio work lists: python3 tools/commentary/todo.py

Reads every clip the game needs (audio/raw/ar/catalog.tsv for the Arabic voice, the stadium
sounds from audio/raw/sfx/README.md), looks at what is already in audio/raw/, and writes
docs/audio/todo/: one file per wave with each clip's folder, file name, tone and text, marked
done, to redo (with why) or missing. Rejected clips are taken out of audio/raw/ so the build
keeps the old voice for them until they are recorded again.
Edit REVIEW after each review of the recordings, then run this again.
"""
import os as _os, sys as _sys
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from ar_egyptian import plain  # noqa: E402  the voice lists carry no diacritics (owner's decision, 2026-10-20)
import os, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
RAW = os.path.join(ROOT, 'audio', 'raw')
OUT = os.path.join(ROOT, 'docs', 'audio', 'todo')
EXT = ('.wav', '.mp3', '.m4a', '.ogg', '.flac', '.aac')

# Reviews of what was uploaded: file -> why it must be recorded again. Checked by ear and by
# speech recognition against the line it should say.
REVIEW = {
    'date': '2026-10-20',
    'redo': {
        'story/blocked-key-2.wav': 'نسخة مطابقة تماماً لـ blocked-key-1 (نفس الملف). سجّل جملتها هي.',
        'story/miss-post-2.wav': 'فيها جملتان: جملة miss-post-1 أولاً ثم جملتها. سجّل جملتها وحدها.',
        'story/red-pre-1.wav': 'تقول «كرت أحمر» قبل أن يرفعه الحكم، فتكشف النتيجة. المطلوب وصف التدخل فقط.',
    },
    'check': {
        'story/miss-pre-1.wav': 'لم يتعرف عليها التحقق الآلي، وطولها ثانيتان لكلمة واحدة. اسمعها وتأكد أنها «تسديدة...» وحدها.',
    },
}

import datetime as _dt
REVIEW_TIME = _dt.datetime.fromisoformat(REVIEW['date'] + 'T23:59:59').timestamp()

TONES = {'هادئ': 'هادئ', 'متحمس': 'متحمس', 'صاخب': 'صاخب'}


def present(folder):
    d = os.path.join(RAW, folder)
    if not os.path.isdir(d):
        return set()
    return {os.path.splitext(f)[0] for f in os.listdir(d) if f.lower().endswith(EXT)}


def catalog():
    rows = []
    for line in open(os.path.join(RAW, 'ar', 'catalog.tsv'), encoding='utf-8'):
        if line.strip() and not line.startswith('#'):
            wave, folder, name, tone, text = line.rstrip('\n').split('\t')
            rows.append((int(wave), 'ar/' + folder, name, tone, text))
    return rows


def sfx():
    rows = []
    for line in open(os.path.join(RAW, 'sfx', 'README.md'), encoding='utf-8'):
        m = re.match(r'\| `([^`]+)` \| (.*?) \|', line)
        if m:
            rows.append((0, 'sfx', m.group(1), '', m.group(2)))
    return rows


def status(folder, name):
    key = folder.split('/', 1)[-1] + '/' + name if folder.startswith('ar/') else 'sfx/' + name
    here = os.path.splitext(name)[0] in present(folder)
    if key in REVIEW['redo']:
        # recorded again after the review: waiting to be heard
        return ('check', 'سُجّل من جديد بعد المراجعة، وينتظر المراجعة.') if here else ('redo', REVIEW['redo'][key])
    if here:
        return ('check', REVIEW['check'][key]) if key in REVIEW['check'] else ('done', '')
    return 'missing', ''


MARK = {'done': '✅', 'redo': '🔁', 'check': '👂', 'missing': '⬜'}


def write(path, title, intro, rows):
    o = [f'# {title}\n', intro, '']
    counts = {k: 0 for k in MARK}
    table = []
    for wave, folder, name, tone, text in rows:
        st, why = status(folder, name)
        counts[st] += 1
        table.append((st, folder, name, tone, text, why))
    o.append(f"**المجموع:** {len(rows)}. ✅ معتمد {counts['done']} · 🔁 للإعادة {counts['redo']} · 👂 للتأكد بالسمع {counts['check']} · ⬜ لم يُسجَّل {counts['missing']}\n")
    for st, head in (('redo', 'للإعادة'), ('check', 'للتأكد بالسمع'), ('missing', 'لم يُسجَّل بعد'), ('done', 'معتمد')):
        part = [t for t in table if t[0] == st]
        if not part:
            continue
        o.append(f'## {MARK[st]} {head} ({len(part)})\n')
        if st in ('redo', 'check'):
            o.append('| الملف | المكان | النبرة | النص | لماذا |')
            o.append('|---|---|---|---|---|')
            for _, folder, name, tone, text, why in part:
                o.append(f'| `{name}` | `audio/raw/{folder}/` | {tone} | {text} | {why} |')
        else:
            o.append('| الملف | المكان | النبرة | النص |' if tone or st else '')
            o.append('|---|---|---|---|')
            for _, folder, name, tone, text, why in part:
                o.append(f'| `{name}` | `audio/raw/{folder}/` | {tone} | {text} |')
        o.append('')
    open(path, 'w', encoding='utf-8').write(plain('\n'.join(o)) + '\n')
    return counts


def main():
    os.makedirs(OUT, exist_ok=True)
    # rejected clips leave audio/raw/ (they stay in git history)
    for key in REVIEW['redo']:
        folder, name = key.split('/', 1)
        base = os.path.join(RAW, 'ar' if folder != 'sfx' else '', folder, os.path.splitext(name)[0])
        for ext in EXT:
            # only the rejected recording: a new one, added after the review, stays
            if os.path.exists(base + ext) and os.path.getmtime(base + ext) < REVIEW_TIME:
                os.remove(base + ext)
    rows = catalog()
    rule = ('**طريقة التسجيل (قرار صاحب المشروع، 2026-10-20):**\n'
            '- **اللهجة:** باللهجة المصرية، بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع، مثل مقاطع الدفعة الأولى المعتمدة. النص مكتوب بالمصرية كما يُقال، بلا تشكيل، فاقرأه كما هو.\n'
            '- **الطول:** جملة واحدة، بلا جمل إضافية من مقطع آخر، وبلا تكرار طويل. والمقطع الذي قبل اللحظة (pre) لا يكشف النتيجة.\n'
            '- **الحفظ:** في المجلد المكتوب باسم الملف بالضبط. والصيغة WAV أو MP3 أو M4A.\n'
            '- **بعد الرفع:** Claude يراجع، ثم `python3 tools/commentary/todo.py` يحدّث هذه القوائم.')
    summary = []
    for wave in sorted({r[0] for r in rows}):
        part = [r for r in rows if r[0] == wave]
        where = 'كلها في `audio/raw/ar/story/`: ما يقوله المحاكي الآن.' if wave == 1 else f'المقاطع من كل فئة في مجلدها تحت `audio/raw/ar/`.'
        c = write(os.path.join(OUT, f'wave-{wave:02d}.md'), f'الصوت العربي: الدفعة {wave}', f'> {where}\n\n{rule}', part)
        summary.append((f'الدفعة {wave}', f'wave-{wave:02d}.md', len(part), c))
    c = write(os.path.join(OUT, 'sfx.md'), 'أصوات الملعب والمباراة', '> في `audio/raw/sfx/`. ليست صوت المعلق: بترخيص CC0 أو مولّدة، والحلقات لا يُسمع مكان تكرارها.', sfx())
    summary.append(('أصوات الملعب', 'sfx.md', sum(c.values()), c))
    o = ['# قوائم عمل الصوت (حمزة)\n',
         f"> يولّدها `tools/commentary/todo.py` من `audio/raw/ar/catalog.tsv` وما في `audio/raw/`. آخر مراجعة: {REVIEW['date']}.",
         '> ابدأ بالدفعة 1: 🔁 ثم 👂 ثم ⬜. كل ملف فيه اسم المقطع ومكانه ونبرته ونصه.\n',
         '| القائمة | الملف | المجموع | ✅ | 🔁 | 👂 | ⬜ |', '|---|---|---|---|---|---|---|']
    for name, f, n, c in summary:
        o.append(f"| {name} | [`{f}`]({f}) | {n} | {c['done']} | {c['redo']} | {c['check']} | {c['missing']} |")
    open(os.path.join(OUT, 'README.md'), 'w', encoding='utf-8').write(plain('\n'.join(o)) + '\n')
    for name, f, n, c in summary[:1] + summary[-1:]:
        print(name, c)


if __name__ == '__main__':
    main()
