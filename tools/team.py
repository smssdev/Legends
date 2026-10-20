"""The team's two daily references: python3 tools/team.py (after tools/plan/schedule.py)

Owner's decision (2026-10-20): Sliman makes the images beside the code sprints, Hamza records the voice.
- docs/SLIEMAN.md: Sliman's day (images, then the current sprint), what waits on his decisions, the next
  sprints with their dates, how to make and hand in an image, and the numbers.
- docs/HAMZA.md: the voice only, in order, with how to record it and the numbers.
Both come from what is in art/raw/ and audio/raw/, the image book (docs/art/images/), the image reviews
(tools/art-prompts/redo.py), the voice lists (tools/commentary/todo.py), docs/SPRINTS.md and docs/SCHEDULE.md.
Run it after every review and every merged sprint.
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path[:0] = [os.path.join(ROOT, 'tools', 'art-prompts'), os.path.join(ROOT, 'tools', 'commentary')]
import redo as art_redo   # noqa: E402
import todo as voice      # noqa: E402

IMG = os.path.join(ROOT, 'docs', 'art', 'images')
sys.path.insert(0, os.path.join(ROOT, 'tools', 'plan'))
import rates             # noqa: E402


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



# Redo boards Sliman chose to leave for later (2026-10-20): they go to the end of today's list.
LATER = {'45.13', '45.14', '45.15'}

# Things only Sliman can unblock: keep this list current (remove a line once it is done).
OPEN_DECISIONS = [
    ('D0 / D1', 'اعتماد نظام التصميم وشاشات السبرنتات 9 و10 و11 (المكونات، والحساب، والفريق)', 'الشاشات المكتوبة تنتظره، ولا تُكتب شاشة جديدة قبل تصميمها'),
    ('Google OAuth', 'معرّفات Google OAuth للويب وAndroid في `.env` (`GOOGLE_CLIENT_ID`...)', 'الدخول بجوجل يعمل في الاختبارات فقط حتى تُضاف'),
    ('PWA', 'تجربة تثبيت الموقع على جوال حقيقي', 'من تعريف انتهاء السبرنت 9'),
    ('ميزة الأرض', 'اعتماد +5% من القدرة و+4.5% من المبادرة بدل 2.5% (`docs/sprints/sprint-12.md`)', 'الرقم في `config/game.php` ويُغيَّر بسطر'),
]


def image_states():
    boards = boards_by_wave()
    redo = image_redo()
    ok = {'art/raw/' + p for p in art_redo.approved()}
    st = {}
    for wave, code, path, md, group in boards:
        if path in ok:
            st[path] = 'done'
        elif os.path.exists(os.path.join(ROOT, path)):
            st[path] = 'pending'      # uploaded, not reviewed yet (or made again after a redo)
        elif path in redo:
            st[path] = 'redo'
        else:
            st[path] = 'todo'
    return boards, redo, st


def voice_states():
    clips = voice.catalog()
    vst = {(c[1], c[2]): voice.status(c[1], c[2])[0] for c in clips}
    sfx = voice.sfx()
    sst = {(c[1], c[2]): voice.status(c[1], c[2])[0] for c in sfx}
    return clips, vst, sfx, sst


def left_by_wave():
    """Images and voice clips still to make, by wave (the plan uses them): ({wave: n}, {wave: n})."""
    boards, _, st = image_states()
    clips, vst, sfx, sst = voice_states()
    img = {}
    for b in boards:
        if st[b[2]] in ('redo', 'todo'):
            img[b[0]] = img.get(b[0], 0) + 1
    vo = {}
    for c in clips:
        if vst[(c[1], c[2])] != 'done':
            vo[c[0]] = vo.get(c[0], 0) + 1
    left_sfx = sum(1 for k in sst.values() if k != 'done')
    if left_sfx:
        vo['أصوات الملعب'] = left_sfx
    return img, vo


def sprint_block(n):
    """Title, task rows and definition of done of one sprint, from docs/SPRINTS.md."""
    text = open(os.path.join(ROOT, 'docs', 'SPRINTS.md'), encoding='utf-8').read()
    m = re.search(r'\n### Sprint ' + str(n) + r': ([^\n]*)\n(.*?)(?=\n### Sprint |\n## )', text, re.S)
    title, body = m.group(1).strip(), m.group(2)
    tasks = re.findall(r'^\| ([A-Z][A-Z0-9.]*(?: إلى [A-Z0-9]+)?) \| (.*?) \|\s*$', body, re.M)
    dod = re.findall(r'^- \[[ x]\] (.*)$', body, re.M)
    goal = re.search(r'\*\*الهدف:\*\* (.*?)(?: \*\*المراجع|$)', body, re.M)
    return title, tasks, dod, goal.group(1).strip() if goal else ''


def schedule_rows():
    """(sprint, phase, title, days, from, to) from docs/SCHEDULE.md, and the version dates."""
    text = open(os.path.join(ROOT, 'docs', 'SCHEDULE.md'), encoding='utf-8').read()
    part = text[text.index('## السبرنتات'):text.index('## كل يوم')]
    rows = [tuple(c.strip() for c in r.strip('|').split('|')) for r in part.split('\n') if re.match(r'\| \d+ \|', r)]
    vpart = text[text.index('## متى تخرج'):text.index('### كيف')]
    versions = [tuple(c.strip().strip('*') for c in r.strip('|').split('|')) for r in vpart.split('\n') if r.startswith('| **v')]
    return rows, versions


def link(path):
    return f'[`{os.path.basename(path)}`]({os.path.relpath(os.path.join(ROOT, path), os.path.join(ROOT, "docs"))})'


def write_slieman():
    boards, redo, st = image_states()
    waves = sorted({b[0] for b in boards})
    count = {w: {k: sum(1 for b in boards if b[0] == w and st[b[2]] == k) for k in ('done', 'pending', 'redo', 'todo')} for w in waves}
    rows, versions = schedule_rows()
    done_sprints = {int(r[0]) for r in rows if r[3] == '0'}
    upcoming = [r for r in rows if r[3] != '0']
    current = int(upcoming[0][0])
    title, tasks, dod, goal = sprint_block(current)
    clips, vst, sfx, sst = voice_states()

    o = []
    W = o.append
    W('# دليل سليمان: الصور والسبرنتات\n')
    W('> **مرجعك اليومي.** منه تعرف ماذا تعمل اليوم، وما ينتظر قرارك، وما القادم بتواريخه.')
    W('> يولّده `python3 tools/team.py` بعد كل مراجعة وكل دمج، فلا يُعدَّل يدوياً. والخطة كاملة في [`SCHEDULE.md`](SCHEDULE.md).\n')
    W(f'**تقسيم العمل (قرار 2026-10-20):** أنت تصنع الصور كلها بالتوازي مع السبرنتات، وحمزة على الصوت وحده ([`HAMZA.md`](HAMZA.md)). يومك {rates.DAY_HOURS} ساعات: **للصور {rates.IMG_HOURS} منها ({rates.IMG_PER_DAY} صورة معتمدة)، وللكود {rates.CODE_HOURS}** مع Claude. والأرقام في `tools/plan/rates.py`.\n')

    # ------------------------------------------------------------ today
    W('## يومك بالترتيب\n')
    W(f'### 1. الصور ({rates.IMG_HOURS} من {rates.DAY_HOURS} ساعات تقريباً)\n')
    W('**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تُبنى بها وحدها وتنتظرها. لا تبدأ الدفعة 2 قبل إكمالها.\n')
    p_all = [b for b in boards if st[b[2]] == 'pending']
    r1 = [b for b in boards if b[0] == 1 and st[b[2]] == 'redo']
    t1 = [b for b in boards if b[0] == 1 and st[b[2]] == 'todo']
    steps = []
    if p_all:
        steps.append(f"**⏳ {len(p_all)} صورة مرفوعة تنتظر المراجعة:** قل لـ Claude «راجع» أول الجلسة.")
    if r1:
        files = sorted({redo[b[2]][0] for b in r1})
        steps.append(f"**🔁 أعد {len(r1)} صورة من الدفعة 1** رفضتها المراجعة، بأمرها وسطر تصحيحها في: " + '، '.join(link(f) for f in files) + '.')
    if t1:
        steps.append(f"**⬜ ثم الجديدة بالترتيب ({len(t1)} باقية في الدفعة 1):** من [`sprint-02-days.md`](sprints/sprint-02-days.md). أول {rates.IMG_PER_DAY} في الجدول تحت.")
    for i, s in enumerate(steps, 1):
        W(f'{i}. {s}')
    W('')
    r1 = [b for b in r1 if b[1] not in LATER] + [b for b in r1 if b[1] in LATER]
    nxt = (r1 + t1)[:rates.IMG_PER_DAY]
    if nxt:
        W(f'**صور اليوم ({len(nxt)}):**\n')
        W('| | اللوحة | الملف | الأمر في |'); W('|---|---|---|---|')
        for wave, code, path, md, group in nxt:
            where = link(redo[path][0]) if path in redo else f'[`{md}`](art/images/{md})'
            W(f"| {'🔁' if path in redo else '⬜'} | {code} | `{path}` | {where} |")
        W('')

    W(f'### 2. الكود ({rates.CODE_HOURS} ساعات): Sprint {current}، {title}\n')
    if goal:
        W(f'**الهدف:** {goal}\n')
    W(f'ابدأ الجلسة بـ «نكمل سبرنت {current}»، وClaude يكمل من حالة [`sprint-{current:02d}.md`](sprints/sprint-{current:02d}.md) (يُنشأ أول السبرنت).\n')
    W('| الرمز | المهمة |'); W('|---|---|')
    for c, t in tasks:
        W(f'| {c} | {t} |')
    W('\n**تعريف الانتهاء:**\n')
    for d in dod:
        W(f'- [ ] {d}')
    W('')
    W('### 3. آخر الجلسة\n')
    W('- **الصور:** ارفعها إلى `art/raw/` بأسمائها، وشغّل `python3 tools/art/build.py` وشاهدها في `/dev/art`، ثم قل «راجع».')
    W('- **الكود:** Claude يفتح PR، وبعد نجاح CI يُدمج في `main`.')
    W('- **الخطة:** بعد كل مراجعة أو دمج تتحدث `SCHEDULE.md` وهذا الملف تلقائياً.\n')

    # ------------------------------------------------------------ decisions
    W('## ينتظر قرارك\n')
    W('| الموضوع | المطلوب | لماذا يهم |'); W('|---|---|---|')
    for a, b, c in OPEN_DECISIONS:
        W(f'| {a} | {b} | {c} |')
    W('')

    # ------------------------------------------------------------ plan
    W('## القادم بالتواريخ\n')
    W('| السبرنت | العنوان | الأيام | من | إلى |'); W('|---|---|---|---|---|')
    for r in upcoming[:10]:
        W(f'| {r[0]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |')
    W('\n**النسخ:** ' + '، '.join(f'{v[0]} في {v[3]}' for v in versions if v[0] in ('v0.1', 'v0.2', 'v1.0', 'v1.1', 'v1.8')) + '.\n')

    # ------------------------------------------------------------ how
    W('## طريقة صنع الصورة\n')
    W('1. **افتح أمر الصورة** في ملف الجزء المذكور (`docs/art/images/`)، وابحث برقم اللوحة مثل `### 49.1`. والمرفوضة من ملف الإعادة.')
    W('2. **محادثة جديدة لكل حركة** في Gemini، مع المرفقات المكتوبة تحت «ارفق» بالضبط. وفي ملف الإعادة قسم **«أمر واحد لكل حركة»**: تلصقه مرة فيرسم صور الحركة واحدة بعد الأخرى، وإن توقف بعد صورة فاكتب **next**.')
    W('3. **انسخ الأمر كاملاً.** وفي الإعادة: الأمر من ملف الإعادة، وفي آخره سطر التصحيح.')
    W('4. **الصورة المقبولة:**')
    W('   - صورة واحدة عريضة **3:2** (مثل 1264x848)، لا مربعة ولا لوحات ملصوقة. المربعة يرسم فيها Gemini الأشكال أصغر، فيصغر اللاعب في اللعبة، و`build.py` ينبّه لها.')
    W('   - خلفية خضراء سادة (#00FF00): بلا كشافات، ولا تدرج، ولا أرضية.')
    W('   - عدد الأشكال المطلوب، بالزاوية المطلوبة، وكل إطار وضعية مختلفة.')
    W('   - نفس الشخص من البطاقة المرجعية، بلا أطراف مكررة.')
    W('5. **احفظها PNG حقيقياً** (لا JPEG باسم png) باسمها في `README.md` المجلد. بلا `(2)` وبلا امتداد ثانٍ.')
    W('6. **لا ترفع فوق صورة معتمدة (✅)** إلا إذا طلبت المراجعة ذلك.\n')

    # ------------------------------------------------------------ numbers
    W('## الحالة بالأرقام\n')
    W('### الصور (أنت)\n')
    W('| الدفعة | المجموع | ✅ معتمد | ⏳ تنتظر المراجعة | 🔁 للإعادة | ⬜ لم تُصنع |'); W('|---|---|---|---|---|---|')
    for w in waves:
        c = count[w]
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['pending']} | {c['redo']} | {c['todo']} |")
    tot = {k: sum(count[w][k] for w in waves) for k in ('done', 'pending', 'redo', 'todo')}
    W(f"| **الكل** | **{sum(tot.values())}** | **{tot['done']}** | **{tot['pending']}** | **{tot['redo']}** | **{tot['todo']}** |\n")
    vdone = sum(1 for k in vst.values() if k == 'done')
    v1 = [c for c in clips if c[0] == 1]
    v1done = sum(1 for c in v1 if vst[(c[1], c[2])] == 'done')
    W(f'### الصوت (حمزة)\n')
    W(f'الدفعة 1: {v1done} من {len(v1)} معتمدة. والكل: {vdone} من {len(clips)} مقطعاً، وأصوات الملعب {sum(1 for k in sst.values() if k == "done")} من {len(sfx)}. التفاصيل في [`HAMZA.md`](HAMZA.md).\n')
    W(f"**السبرنتات المنجزة:** {'، '.join(str(n) for n in sorted(done_sprints))} (والسبرنت 1). السجل في [`SPRINTS.md`](SPRINTS.md).\n")

    # ------------------------------------------------------------ index
    W('## كل الملفات\n')
    W('| الملف | ما فيه |'); W('|---|---|')
    W('| [`SCHEDULE.md`](SCHEDULE.md) | الخطة يوماً يوماً: الكود والصور، وتاريخ كل نسخة |')
    W('| [`SPRINTS.md`](SPRINTS.md) | كل السبرنتات ومهامها، وسجل الإنجاز |')
    W('| [`sprints/sprint-02-days.md`](sprints/sprint-02-days.md) | صور الدفعة 1 بالترتيب: المنجز وما بقي |')
    for r in art_redo.REVIEWS:
        W(f"| {link(r['out'])} | إعادة: {r['title']} ({r['date']}) |")
    W('| [`art/images/00-waves.md`](art/images/00-waves.md) | كل الدفعات ومجموعاتها ومجلداتها |')
    W('| [`art/images/00-guide.md`](art/images/00-guide.md) | دليل كتاب الصور: الأسلوب وجمل التصحيح |')
    W('| [`HAMZA.md`](HAMZA.md) | مرجع حمزة للصوت |')
    open(os.path.join(ROOT, 'docs', 'SLIEMAN.md'), 'w', encoding='utf-8').write('\n'.join(o) + '\n')
    return current, {w: count[w] for w in waves[:2]}


def write_hamza():
    clips, vst, sfx, sst = voice_states()
    vwaves = sorted({c[0] for c in clips})
    vcount = {w: {k: sum(1 for c in clips if c[0] == w and vst[(c[1], c[2])] == k) for k in ('done', 'redo', 'check', 'missing')} for w in vwaves}
    scount = {k: sum(1 for v in sst.values() if v == k) for k in ('done', 'redo', 'check', 'missing')}
    o = []
    W = o.append
    W('# دليل حمزة: الصوت\n')
    W('> **مرجعك الوحيد.** منه تعرف ما المطلوب الآن، وكيف تسجله، وأين تضعه، وكم أُنجز.')
    W('> يولّده `python3 tools/team.py` بعد كل مراجعة، فلا يُعدَّل يدوياً.\n')
    W('**تقسيم العمل (قرار 2026-10-20):** أنت على الصوت وحده: المعلق العربي وأصوات الملعب. والصور يصنعها سليمان.\n')
    W('## المطلوب الآن، بالترتيب\n')
    W('**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تحتاج صوتها كاملاً مع صورها.\n')
    steps = []
    v1 = vcount[1]
    if v1['redo'] or v1['check']:
        steps.append(f"**🔁 أعد المقاطع المرفوضة من الدفعة 1 ({v1['redo']})، و👂 تأكد بالسمع من ({v1['check']}):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، أول قسمين.")
    if v1['missing']:
        steps.append(f"**⬜ سجّل باقي الدفعة 1 ({v1['missing']} مقطعاً):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، قسم «لم يُسجَّل بعد».")
    rest = [w for w in vwaves if w > 1 and vcount[w]['done'] < sum(vcount[w].values())]
    if rest:
        n = sum(sum(vcount[w].values()) - vcount[w]['done'] for w in rest)
        steps.append(f"**ثم الدفعات {rest[0]} إلى {rest[-1]} بالترتيب ({n} مقطعاً):** كل دفعة في قائمتها، أولها [`audio/todo/wave-{rest[0]:02d}.md`](audio/todo/wave-{rest[0]:02d}.md).")
    if scount['missing'] or scount['redo']:
        steps.append(f"**ثم أصوات الملعب ({scount['missing'] + scount['redo']}):** [`audio/todo/sfx.md`](audio/todo/sfx.md).")
    for i, s in enumerate(steps, 1):
        W(f'{i}. {s}')
    W(f'\n**الإيقاع:** حوالي {rates.VOICE_PER_DAY} مقطعاً معتمداً يومياً، وتواريخ كل دفعة في [`SCHEDULE.md`](SCHEDULE.md)، قسم «مسار الصوت».\n')
    W('## طريقة التسجيل\n')
    W('1. **باللهجة المصرية،** بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع (قرار 2026-10-20).')
    W('2. **النص المكتوب بالفصحى هو المعنى،** وتقوله بالمصرية بطريقتك.')
    W('3. **جملة واحدة لكل مقطع،** بلا جملة من مقطع آخر وبلا تكرار طويل. والمقطع الذي قبل اللحظة (pre) لا يكشف النتيجة.')
    W('4. **الحفظ:** باسم الملف وفي المجلد المكتوبين في قائمة الدفعة. والصيغة WAV أو MP3 أو M4A.')
    W('5. **أصوات الملعب:** بترخيص CC0 أو مولّدة، والحلقات لا يُسمع مكان تكرارها.\n')
    W('### بعد الرفع\n')
    W('- ارفع إلى `main` بالأسماء الصحيحة، وقل: «راجع الصوت».')
    W('- المعتمد يُعلَّم ✅، والمرفوض يُحذف من مجلده وينتقل لقائمة الإعادة بسببه.\n')
    W('## الحالة بالأرقام\n')
    W('| الدفعة | المجموع | ✅ | 🔁 | 👂 | ⬜ | القائمة |'); W('|---|---|---|---|---|---|---|')
    for w in vwaves:
        c = vcount[w]
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['redo']} | {c['check']} | {c['missing']} | [`wave-{w:02d}.md`](audio/todo/wave-{w:02d}.md) |")
    W(f"| أصوات الملعب | {len(sfx)} | {scount['done']} | {scount['redo']} | {scount['check']} | {scount['missing']} | [`sfx.md`](audio/todo/sfx.md) |")
    tot = {k: sum(vcount[w][k] for w in vwaves) for k in ('done', 'redo', 'check', 'missing')}
    W(f"| **المعلق كله** | **{sum(tot.values())}** | **{tot['done']}** | **{tot['redo']}** | **{tot['check']}** | **{tot['missing']}** | |\n")
    W('## كل الملفات\n')
    W('| الملف | ما فيه |'); W('|---|---|')
    W('| [`audio/todo/README.md`](audio/todo/README.md) | ملخص الصوت، ومنه قائمة كل دفعة |')
    W('| [`audio/ARABIC_VOICE.md`](audio/ARABIC_VOICE.md) | كتالوج المعلق كاملاً والشرح |')
    W('| `audio/raw/<المجلد>/README.md` | أسماء ملفات كل مجلد |')
    open(os.path.join(ROOT, 'docs', 'HAMZA.md'), 'w', encoding='utf-8').write('\n'.join(o) + '\n')
    return vcount[1]


if __name__ == '__main__':
    cur, img = write_slieman()
    v1 = write_hamza()
    print('docs/SLIEMAN.md: sprint', cur, img, '· docs/HAMZA.md voice wave 1:', v1)
