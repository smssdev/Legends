"""Hamza's one reference for images and voice: python3 tools/hamza.py

Writes docs/HAMZA.md from what is in art/raw/ and audio/raw/, the image book
(docs/art/images/00-waves.md), the image reviews (tools/art-prompts/redo.py) and the voice
lists (tools/commentary/todo.py): what to do now in order, how to make each thing, where to
put it, and how much of every wave is done. Run it after every review (or let the reviews do it).
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path[:0] = [os.path.join(ROOT, 'tools', 'art-prompts'), os.path.join(ROOT, 'tools', 'commentary')]
import redo as art_redo   # noqa: E402
import todo as voice      # noqa: E402

IMG = os.path.join(ROOT, 'docs', 'art', 'images')
OUT = os.path.join(ROOT, 'docs', 'HAMZA.md')


def boards_by_wave():
    """Every board of every wave: (wave, code, path, book file, group)."""
    text = open(os.path.join(IMG, '00-waves.md'), encoding='utf-8').read()
    parts = re.split(r'\n## الدفعة (\d+) ', text)
    out = []
    for i in range(1, len(parts), 2):
        wave, body = int(parts[i]), parts[i + 1]
        for r in body.split('\n'):
            if not r.startswith('| ') or 'القسم' in r or r.startswith('|---'):
                continue
            c = [x.strip() for x in r.strip('|').split('|')]
            if len(c) < 5 or not re.match(r'\d+\.', c[1]):
                continue
            num = int(c[1].split('.')[0])
            md = re.search(r'\((.*?)\)', c[3]).group(1)
            folder = c[4].strip('`')
            t = open(os.path.join(IMG, md), encoding='utf-8').read()
            a = t.index(f'## المجموعة {num}:')
            b = t.find('\n## ', a + 5)
            g = t[a:b if b > 0 else None]
            out += [(wave, k, folder + f, md, c[1]) for k, f in re.findall(r'### (\d+\.\d+) `([^`]+)`', g)]
    return out


def image_redo():
    """path -> (review file, why) for every rejected board."""
    out = {}
    for r in art_redo.REVIEWS:
        for code, folder, why, _ in r['redo']:
            book = open(os.path.join(ROOT, r['book']), encoding='utf-8').read()
            name = re.search(r'### ' + re.escape(code) + r' `([^`]+)`', book).group(1)
            out[f'art/raw/{folder}/{name}'] = (r['out'], why)
    return out


def main():
    boards = boards_by_wave()
    redo = image_redo()
    ok = {'art/raw/' + p for p in art_redo.approved()}
    st = {}
    for wave, code, path, md, group in boards:
        here = os.path.exists(os.path.join(ROOT, path))
        if path in ok:
            st[path] = 'done'
        elif here:
            st[path] = 'pending'      # uploaded, not reviewed yet (or uploaded again after a redo)
        elif path in redo:
            st[path] = 'redo'
        else:
            st[path] = 'todo'
    waves = sorted({b[0] for b in boards})
    count = {w: {k: sum(1 for b in boards if b[0] == w and st[b[2]] == k) for k in ('done', 'pending', 'redo', 'todo')} for w in waves}

    clips = voice.catalog()
    vst = {}
    for wave, folder, name, tone, text in clips:
        vst[(folder, name)] = voice.status(folder, name)[0]
    vwaves = sorted({c[0] for c in clips})
    vcount = {w: {k: sum(1 for c in clips if c[0] == w and vst[(c[1], c[2])] == k) for k in ('done', 'redo', 'check', 'missing')} for w in vwaves}

    o = []
    W = o.append
    W('# دليل حمزة: الصور والصوت\n')
    W('> **الملف المرجع الوحيد.** منه تعرف ما المطلوب الآن، وكيف تصنعه، وأين تضعه، وكم أُنجز.')
    W('> يولّده `python3 tools/hamza.py` بعد كل مراجعة، فلا يُعدَّل يدوياً.\n')

    # ------------------------------------------------------------ now
    W('## المطلوب الآن، بالترتيب\n')
    W('**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تُبنى بها وحدها، وتنتظرها. أي عمل في الدفعة 2 قبل إكمالها يؤخر المحاكاة.\n')
    r1 = [b for b in boards if b[0] == 1 and st[b[2]] == 'redo']
    t1 = [b for b in boards if b[0] == 1 and st[b[2]] == 'todo']
    v1 = vcount[1]
    steps = []
    p1 = [b for b in boards if st[b[2]] == 'pending']
    if p1:
        steps.append(f"**⏳ {len(p1)} صورة مرفوعة تنتظر مراجعة Claude.** لا تعيدها حتى تُراجع.")
    if r1:
        files = sorted({redo[b[2]][0] for b in r1})
        steps.append(f"**🔁 أعد {len(r1)} صورة من الدفعة 1** رفضتها المراجعة. لكل صورة أمرها كاملاً وسطر التصحيح في: " + '، '.join(f'[`{os.path.basename(f)}`]({os.path.relpath(f, "docs")})' for f in files) + '.')
    if v1['redo'] or v1['check']:
        steps.append(f"**🔁 أعد مقاطع الصوت المرفوضة من الدفعة 1 ({v1['redo']})، و👂 تأكد بالسمع من ({v1['check']}):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، أول قسمين.")
    if t1:
        steps.append(f"**⬜ اصنع باقي صور الدفعة 1 ({len(t1)} صورة)** بالترتيب، 25 كل يوم: [`sprints/sprint-02-days.md`](sprints/sprint-02-days.md). أول 10 في الجدول تحت.")
    if v1['missing']:
        steps.append(f"**⬜ سجّل باقي صوت الدفعة 1 ({v1['missing']} مقطعاً):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، قسم «لم يُسجَّل بعد».")
    r2 = [b for b in boards if b[0] == 2 and st[b[2]] == 'redo']
    steps.append(f"**بعد إكمال الدفعة 1 فقط:** الدفعة 2. فيها {len(r2)} صورة رُفعت مبكراً ورُفضت، وأوامرها في ملفات الإعادة نفسها. ثم صوت الدفعة 2: [`audio/todo/wave-02.md`](audio/todo/wave-02.md).")
    for i, s in enumerate(steps, 1):
        W(f'{i}. {s}')
    W('')
    if t1:
        W('### أول 10 صور تالية في الدفعة 1\n')
        W('| اللوحة | الملف | المجموعة | الأمر في |')
        W('|---|---|---|---|')
        for wave, code, path, md, group in t1[:10]:
            W(f'| {code} | `{path}` | {group} | [`{md}`](art/images/{md}) |')
        W('')

    # ------------------------------------------------------------ how
    W('## طريقة العمل\n')
    W('### الصور\n')
    W('1. **افتح أمر الصورة** في ملف الجزء المذكور (`docs/art/images/`). ابحث برقم اللوحة، مثل `### 45.5`.')
    W('2. **محادثة جديدة لكل مجموعة** في Gemini، مع المرفقات المكتوبة تحت «ارفق» بالضبط.')
    W('3. **انسخ الأمر كما هو كاملاً.** وفي الإعادة: الأمر من ملف الإعادة، وفي آخره سطر التصحيح.')
    W('4. **الصورة يجب أن تكون:**')
    W('   - صورة واحدة عريضة، لا لوحات ملصوقة.')
    W('   - بخلفية خضراء واحدة سادة (#00FF00): بلا كشافات، ولا تدرج، ولا أرضية.')
    W('   - بعدد الأشكال المطلوب، وبالزاوية المطلوبة.')
    W('   - بلا أطراف شفافة مكررة.')
    W('5. **احفظها PNG باسمها في `README.md` المجلد بالضبط.** لا تضف `(2)`، ولا تضف امتداداً ثانياً.')
    W('6. **لا ترفع صورة فوق صورة معتمدة (✅).** والمعتمد لا يُعاد إلا إذا طلبت المراجعة ذلك.\n')
    W('### الصوت\n')
    W('1. **باللهجة المصرية،** بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع (قرار 2026-10-20).')
    W('2. **النص المكتوب بالفصحى هو المعنى،** وتقوله بالمصرية بطريقتك.')
    W('3. **جملة واحدة لكل مقطع،** بلا جملة من مقطع آخر وبلا تكرار طويل. والمقطع الذي قبل اللحظة (pre) لا يكشف النتيجة.')
    W('4. **الحفظ:** باسم الملف وفي المجلد المكتوبين في قائمة الدفعة. والصيغة WAV أو MP3 أو M4A.\n')
    W('### بعد الرفع\n')
    W('- ارفع إلى `main` بالأسماء الصحيحة، وقل لـ Claude: «راجع».')
    W('- Claude يراجع، ويحدّث هذا الملف وملفات الإعادة وقوائم الصوت.')
    W('- المعتمد يُعلَّم ✅، والمرفوض يُحذف من مجلده وينتقل لقائمة الإعادة بسببه وتصحيحه.')
    W('- تقدر تشاهد صورك تتحرك بألوان أي نادٍ في `/dev/art` بعد `python3 tools/art/build.py`.\n')

    # ------------------------------------------------------------ numbers
    W('## الحالة بالأرقام\n')
    W('### الصور\n')
    W('| الدفعة | المجموع | ✅ معتمد | ⏳ تنتظر المراجعة | 🔁 للإعادة | ⬜ لم تُصنع |')
    W('|---|---|---|---|---|---|')
    for w in waves:
        c = count[w]
        n = sum(c.values())
        W(f"| {w} | {n} | {c['done']} | {c['pending']} | {c['redo']} | {c['todo']} |")
    tot = {k: sum(count[w][k] for w in waves) for k in ('done', 'pending', 'redo', 'todo')}
    W(f"| **الكل** | **{sum(tot.values())}** | **{tot['done']}** | **{tot['pending']}** | **{tot['redo']}** | **{tot['todo']}** |\n")
    W('### الصوت\n')
    W('| الدفعة | المجموع | ✅ | 🔁 | 👂 | ⬜ | القائمة |')
    W('|---|---|---|---|---|---|---|')
    for w in vwaves:
        c = vcount[w]
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['redo']} | {c['check']} | {c['missing']} | [`wave-{w:02d}.md`](audio/todo/wave-{w:02d}.md) |")
    W('| أصوات الملعب | 44 | | | | | [`sfx.md`](audio/todo/sfx.md) |\n')

    # ------------------------------------------------------------ index
    W('## كل الملفات\n')
    W('| الملف | ما فيه |')
    W('|---|---|')
    W('| [`sprints/sprint-02-days.md`](sprints/sprint-02-days.md) | صور الدفعة 1 يوماً يوماً: المنجز، وما بقي بالترتيب |')
    for r in art_redo.REVIEWS:
        W(f"| [`{os.path.relpath(r['out'], 'docs')}`]({os.path.relpath(r['out'], 'docs')}) | إعادة: {r['title']} ({r['date']})، كل صورة بأمرها وسطر التصحيح |")
    W('| [`art/images/00-waves.md`](art/images/00-waves.md) | كل الدفعات ومجموعاتها ومجلداتها |')
    W('| [`art/images/00-guide.md`](art/images/00-guide.md) | دليل الكتاب: الأسلوب وجمل التصحيح العامة |')
    W('| [`audio/todo/README.md`](audio/todo/README.md) | ملخص الصوت، ومنه قائمة كل دفعة |')
    W('| [`audio/ARABIC_VOICE.md`](audio/ARABIC_VOICE.md) | كتالوج المعلق كاملاً والشرح |')
    W('| `art/raw/<المجلد>/README.md` و`audio/raw/<المجلد>/README.md` | أسماء ملفات كل مجلد |')
    open(OUT, 'w', encoding='utf-8').write('\n'.join(o) + '\n')
    print('docs/HAMZA.md:', {w: count[w] for w in waves[:2]}, 'voice wave 1:', vcount[1])


if __name__ == '__main__':
    main()
