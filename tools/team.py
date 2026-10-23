"""The team's two daily references: python3 tools/team.py (after tools/plan/schedule.py)

Owner's decision (2026-10-22, final): the voice is all Hamza's; of the images Sliman makes the large part
(everything but the stadiums) beside the code sprints and every redo, and Hamza the stadium plates
(tools/plan/rates.py). Each file ends with a full report: every item, its state and who makes it.
- docs/SLIEMAN.md: Sliman's day (his images, then the current sprint), what waits on his decisions, the next
  sprints with their dates, how to make and hand in an image, and the numbers.
- docs/HAMZA.md: the voice, then his images, in order, with how to record and draw them and the numbers.
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
    ('D0 / D1', 'اعتماد نظام التصميم وشاشات السبرنتات 9 و10 و11 و13 إلى 17 و20 و22 إلى 34 (المكونات، والحساب، والفريق، والدوريات والانضمام، والدعوة والإجازة والطرد، والترتيب والمباريات والكأس، والتشكيلة، والتكتيك والمباراة القادمة، وشاشة المباراة وتقريرها، وصندوق الرسائل، والمالية، والسوق والعروض، والكشاف، والتدريب والمعسكر والتدريب السري، والملعب، والتجسس، والأخصائيون، وزر الاستقالة، وقاعة الشرف وملف المدرب، والمحفظة والمتجر)', 'الشاشات المكتوبة تنتظره، ولا تُكتب شاشة جديدة قبل تصميمها'),
    ('التجارب المؤجلة', 'تجارب الجهاز المنزلي والجوال والأصدقاء T1 إلى T8 (PWA، وجوجل، والرابط العام، والمشغّل، والحمل، وأول تجربة مع الأصدقاء، والحارس وتنبيه ntfy)', 'مؤجلة بقرارك (2026-10-22) ومسجلة في «التجارب المؤجلة» بـ `docs/SPRINTS.md`، ولا توقف السبرنتات'),
    ('مواصفات مزايا OSM', 'موافقة المواصفات المكتوبة على آلية OSM بأرقام مبدئية: الكشاف (`docs/features/scout.md`)، والمعسكر (`camp.md`)، والتدريب السري (`secret-training.md`)، والتجسس (`spy.md`)، والأخصائيون (`specialists.md`)، وأسعار الكوينز ومكافآتها (`premium.md`)', 'الكود مبني عليها وكل رقم في `config/game.php`'),
    ('سقف المال بين ناديين', 'طُبق على ما يُدفع فوق القيمة (لا على كل المال) حتى لا تُمنع الصفقات العادلة (`docs/sprints/sprint-25.md`)', 'يُغيَّر بسطر في `App\\Market\\Transfers` لو أردت غيره'),
    ('الدوري النزيه', 'الكوينز مقفلة فيه، فالتجسس والتدريب السري والأخصائيون تُدفع فيه بأموال النادي، والإنهاء الفوري غير متاح (`docs/features/premium.md`)', 'أو تُقفل هذه المزايا فيه كلياً لو أردت'),
    ('استقالة المنشئ', 'منشئ الدوري لا يستقيل منه لأنه يديره (الخطة لا تقول)', 'يُسمح له بسطر في `Leaving::resign` لو أردت، ويبقى منشئاً بلا فريق'),
    ('معادلة هدف النادي', 'الأقوى: اللقب. ربع القمة: ترتيبه + 1. الباقي: + 2. ولا أحد أقل من الخروج من آخر الخُمس. والكأس بربع الترتيب (`docs/sprints/sprint-33.md`)', 'الأرقام في `config(\'game.objectives\')`'),
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


def images_left():
    """Images still to make, by wave and by who makes them: {(wave, 'slieman' | 'hamza'): n}."""
    boards, _, st = image_states()
    out = {}
    for b in boards:
        if st[b[2]] in ('redo', 'todo'):
            k = (b[0], who_makes(b, st))
            out[k] = out.get(k, 0) + 1
    return out


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
    rel = os.path.relpath(os.path.join(ROOT, path), os.path.join(ROOT, 'docs')).replace(os.sep, '/')
    return f'[`{os.path.basename(path)}`]({rel})'


def who_makes(b, st):
    """Who makes a board: its owner (tools/plan/rates.py), but every redo is Sliman's (owner, 2026-10-22):
    Hamza never draws an image twice, he only makes new ones."""
    return 'slieman' if st[b[2]] == 'redo' else rates.image_owner(b[0], b[2], b[3])


def owned(boards, st, who):
    """The boards one person makes."""
    return [b for b in boards if who_makes(b, st) == who]


def next_images(boards, redo, st, n):
    """The next n boards to make, in order: the first wave with work left, its redo boards first."""
    left = [b for b in boards if st[b[2]] in ('redo', 'todo')]
    if not left:
        return [], None
    w = min(b[0] for b in left)
    r = [b for b in left if b[0] == w and st[b[2]] == 'redo']
    r = [b for b in r if b[1] not in LATER] + [b for b in r if b[1] in LATER]
    t = [b for b in left if b[0] == w and st[b[2]] == 'todo']
    return (r + t)[:n], w


def image_table(W, title, nxt, redo):
    if not nxt:
        return
    W(f'**{title} ({len(nxt)}):**\n')
    W('| | اللوحة | الملف | الأمر في |'); W('|---|---|---|---|')
    for wave, code, path, md, group in nxt:
        where = link(redo[path][0]) if path in redo else f'[`{md}`](art/images/{md})'
        W(f"| {'🔁' if path in redo else '⬜'} | {code} | `{path}` | {where} |")
    W('')


def image_howto(W):
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
    W('6. **لا ترفع فوق صورة معتمدة (✅)** إلا إذا طلبت المراجعة ذلك.')
    W('7. **بعد الرفع:** إلى `art/raw/` بأسمائها، وشغّل `python3 tools/art/build.py` وشاهدها في `/dev/art`، ثم قل «راجع».\n')


def image_counts(W, boards, st, waves):
    W('| الدفعة | المجموع | ✅ معتمد | ⏳ تنتظر المراجعة | 🔁 للإعادة | ⬜ لم تُصنع |'); W('|---|---|---|---|---|---|')
    count = {w: {k: sum(1 for b in boards if b[0] == w and st[b[2]] == k) for k in ('done', 'pending', 'redo', 'todo')} for w in waves}
    for w in waves:
        c = count[w]
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['pending']} | {c['redo']} | {c['todo']} |")
    tot = {k: sum(count[w][k] for w in waves) for k in ('done', 'pending', 'redo', 'todo')}
    W(f"| **الكل** | **{sum(tot.values())}** | **{tot['done']}** | **{tot['pending']}** | **{tot['redo']}** | **{tot['todo']}** |\n")
    return count


def wave1_images(W, boards, redo, st, who):
    """The first priority: every wave 1 image one person still has to make, folder by folder, each with
    its one-message file (docs/art/folders/), in the order of the plan."""
    import folders
    left = [b for b in boards if b[0] == 1 and st[b[2]] != 'done' and who_makes(b, st) == who]
    done = sum(1 for b in boards if b[0] == 1 and st[b[2]] == 'done' and who_makes(b, st) == who)
    W('## ⭐ الأولوية الآن: الدفعة 1 (المحاكي المصور)\n')
    W('**المحاكي المصور (السبرنتات 3 إلى 8) يُبنى بالدفعة 1 وحدها ولا يبدأ قبل اكتمال صورها وصوتها.** فكل ما تحت يسبق أي عمل من دفعة أخرى.\n')
    if not left:
        W(f'✅ صورك من الدفعة 1 كلها مكتملة ({done}).\n')
        return
    c = {k: sum(1 for b in left if st[b[2]] == k) for k in ('pending', 'redo', 'todo')}
    W(f"**صورك في الدفعة 1:** ✅ {done} مكتملة · ⏳ {c['pending']} تنتظر المراجعة · 🔁 {c['redo']} يجب إعادتها · ⬜ {c['todo']} لم يُعمل عليها. "
      f"وبوتيرة {rates.IMG_PER_DAY} يومياً تحتاج {-(-(c['redo'] + c['todo']) // rates.IMG_PER_DAY)} {rates.days_word(-(-(c['redo'] + c['todo']) // rates.IMG_PER_DAY))}.\n")
    W('**الطريقة:** مجلداً مجلداً بالترتيب. افتح ملف رسالته، وارفق المكتوب فيه، والصق الرسالة كلها في محادثة Gemini جديدة. الإعادة أولاً في كل مجلد.\n')
    order = []
    for b in left:
        f = os.path.dirname(b[2])
        if f not in order:
            order.append(f)
    W('| | المجلد | 🔁 | ⬜ | ⏳ | الرسالة |'); W('|---|---|---|---|---|---|')
    for i, f in enumerate(order, 1):
        k = {s: sum(1 for b in left if os.path.dirname(b[2]) == f and st[b[2]] == s) for s in ('redo', 'todo', 'pending')}
        msg = f'[`{folders.slug(f)}.md`](art/folders/{folders.slug(f)}.md)' if k['redo'] or k['todo'] else 'تنتظر المراجعة'
        W(f"| {i} | `{f.removeprefix('art/raw/')}/` | {k['redo']} | {k['todo']} | {k['pending']} | {msg} |")
    W('')


def wave1_voice(W, clips, vst):
    """The first priority for the voice: every wave 1 clip not approved yet, with its text."""
    left = [c for c in clips if c[0] == 1 and vst[(c[1], c[2])] != 'done']
    done = sum(1 for c in clips if c[0] == 1 and vst[(c[1], c[2])] == 'done')
    W('## ⭐ الأولوية الآن: الدفعة 1 (المحاكي المصور)\n')
    W('**المحاكي المصور (السبرنتات 3 إلى 8) يُبنى بالدفعة 1 وحدها ولا يبدأ قبل اكتمال صوتها وصورها.** فكل ما تحت يسبق أي مقطع أو صورة من دفعة أخرى.\n')
    if not left:
        W(f'✅ صوت الدفعة 1 كله مكتمل ({done}).\n')
        return
    word = {'redo': '🔁 يجب إعادته', 'check': '👂 تأكد بالسمع', 'missing': '⬜ لم يُسجَّل'}
    c = {k: sum(1 for x in left if vst[(x[1], x[2])] == k) for k in word}
    W(f"**الدفعة 1:** ✅ {done} مكتملة · 🔁 {c['redo']} يجب إعادتها · 👂 {c['check']} تأكد بالسمع · ⬜ {c['missing']} لم تُسجَّل. "
      f"الباقي {len(left)} مقطعاً، أي يوم أو يومان بوتيرة {rates.VOICE_PER_DAY} يومياً.\n")
    W('| | الحالة | الملف | النبرة | النص | ملاحظة |'); W('|---|---|---|---|---|---|')
    order = sorted(left, key=lambda x: ('redo', 'check', 'missing').index(vst[(x[1], x[2])]))
    for i, x in enumerate(order, 1):
        W(f"| {i} | {word[vst[(x[1], x[2])]]} | `audio/raw/{x[1]}/{x[2]}` | {x[3]} | {x[4]} | {voice.status(x[1], x[2])[1]} |")
    boards, _, st = image_states()
    img = [b for b in boards if b[0] == 1 and who_makes(b, st) == 'hamza' and st[b[2]] in ('redo', 'todo')]
    W(f'\n**صورك في الدفعة 1:** {len(img)} باقية.' + (' فلا صور عليك قبل انتهاء صوت الدفعة 1.\n' if not img else ' تأتي بعد صوت الدفعة 1 مباشرة.\n'))


def write_slieman():
    boards, redo, st = image_states()
    waves = sorted({b[0] for b in boards})
    mine = owned(boards, st, 'slieman')
    my_waves = sorted({b[0] for b in mine})
    hamza = owned(boards, st, 'hamza')
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
    W(f'**تقسيم العمل (قرار صاحب المشروع، 2026-10-22):** **الصوت كله عند حمزة.** والصور: **الكم الأكبر عندك** (كل الصور ما عدا الملاعب، {len(mine)} صورة)، و**كل صورة تحتاج إعادة** من أي دفعة. و**جزء بسيط عند حمزة:** لوحات الملاعب ({len(hamza)} صورة) ([`HAMZA.md`](HAMZA.md)). يومك {rates.DAY_HOURS} ساعات: **للصور {rates.IMG_HOURS} منها ({rates.IMG_PER_DAY} صورة معتمدة)، وللكود {rates.CODE_HOURS}** مع Claude. والتقرير الكامل لكل صورة آخر هذا الملف.\n')

    wave1_images(W, boards, redo, st, 'slieman')

    # ------------------------------------------------------------ today
    W('## يومك بالترتيب\n')
    W(f'### 1. الصور ({rates.IMG_HOURS} من {rates.DAY_HOURS} ساعات تقريباً)\n')
    W('**الأولوية للدفعة 1:** المحاكاة المصورة (السبرنتات 3 إلى 8) تُبنى بها وحدها وتنتظرها. لا تبدأ الدفعة 2 قبل إكمالها.\n')
    p_all = [b for b in mine if st[b[2]] == 'pending']
    r1 = [b for b in mine if b[0] == 1 and st[b[2]] == 'redo']
    t1 = [b for b in mine if b[0] == 1 and st[b[2]] == 'todo']
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
    nxt, w = next_images(mine, redo, st, rates.IMG_PER_DAY)
    if nxt and w != 1:
        W(f'الدفعة 1 اكتملت، فصورك الآن من الدفعة {w}.\n')
    image_table(W, 'صور اليوم', nxt, redo)

    later_redo = [b for b in mine if b[0] > 1 and st[b[2]] == 'redo']
    if later_redo:
        W(f'**إعادة من الدفعات اللاحقة ({len(later_redo)}):** بعد صور الدفعة 1، أو حين تصل دفعتها. لكل صورة أمرها وسطر تصحيحها في ملف الإعادة.\n')
        W('| الدفعة | اللوحة | الملف | المشكلة | الأمر في |'); W('|---|---|---|---|---|')
        for wave, code, path, md, group in later_redo:
            W(f'| {wave} | {code} | `{path}` | {redo[path][1]} | {link(redo[path][0])} |')
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

    image_howto(W)

    # ------------------------------------------------------------ numbers
    W('## الحالة بالأرقام\n')
    W('### الصور (أنت)\n')
    count = image_counts(W, mine, st, my_waves)
    hdone = sum(1 for b in hamza if st[b[2]] == 'done')
    W(f'**صور حمزة (لوحات الملاعب):** {hdone} من {len(hamza)} معتمدة. التفاصيل في [`HAMZA.md`](HAMZA.md).\n')
    vdone = sum(1 for k in vst.values() if k == 'done')
    v1 = [c for c in clips if c[0] == 1]
    v1done = sum(1 for c in v1 if vst[(c[1], c[2])] == 'done')
    W(f'### الصوت (حمزة)\n')
    W(f'الدفعة 1: {v1done} من {len(v1)} معتمدة. والكل: {vdone} من {len(clips)} مقطعاً، وأصوات الملعب {sum(1 for k in sst.values() if k == "done")} من {len(sfx)}. التفاصيل في [`HAMZA.md`](HAMZA.md).\n')
    W(f"**السبرنتات المنجزة:** {'، '.join(str(n) for n in sorted(done_sprints))} (والسبرنت 1). السجل في [`SPRINTS.md`](SPRINTS.md).\n")

    # ------------------------------------------------------------ index
    W('## كل الملفات\n')
    W('| الملف | ما فيه |'); W('|---|---|')
    W('| [`art/FOLDERS.md`](art/FOLDERS.md) | **كل مجلد صور برسالة واحدة:** تنسخها كاملة في Gemini فيصنع صور المجلد كلها |')
    W('| [`SCHEDULE.md`](SCHEDULE.md) | الخطة يوماً يوماً: الكود والصور، وتاريخ كل نسخة |')
    W('| [`SPRINTS.md`](SPRINTS.md) | كل السبرنتات ومهامها، وسجل الإنجاز |')
    W('| [`sprints/sprint-02-days.md`](sprints/sprint-02-days.md) | صور الدفعة 1 بالترتيب: المنجز وما بقي |')
    for r in art_redo.REVIEWS:
        W(f"| {link(r['out'])} | إعادة: {r['title']} ({r['date']}) |")
    W('| [`art/images/00-waves.md`](art/images/00-waves.md) | كل الدفعات ومجموعاتها ومجلداتها |')
    W('| [`art/images/00-guide.md`](art/images/00-guide.md) | دليل كتاب الصور: الأسلوب وجمل التصحيح |')
    W('| [`HAMZA.md`](HAMZA.md) | مرجع حمزة: الصوت كله، ولوحات الملاعب |\n')
    W('## التقرير الكامل\n')
    image_report(W, mine, redo, st, made_by())
    open(os.path.join(ROOT, 'docs', 'SLIEMAN.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
    return current, {w: count[w] for w in my_waves[:2]}


def write_hamza():
    clips, vst, sfx, sst = voice_states()
    boards, redo, st = image_states()
    mine = owned(boards, st, 'hamza')
    my_waves = sorted({b[0] for b in mine})
    vwaves = sorted({c[0] for c in clips})
    vcount = {w: {k: sum(1 for c in clips if c[0] == w and vst[(c[1], c[2])] == k) for k in ('done', 'redo', 'check', 'missing')} for w in vwaves}
    scount = {k: sum(1 for v in sst.values() if v == k) for k in ('done', 'redo', 'check', 'missing')}
    o = []
    W = o.append
    W('# دليل حمزة: الصوت والصور\n')
    W('> **مرجعك الوحيد.** منه تعرف ما المطلوب الآن، وكيف تسجله أو ترسمه، وأين تضعه، وكم أُنجز.')
    W('> يولّده `python3 tools/team.py` بعد كل مراجعة، فلا يُعدَّل يدوياً.\n')
    W(f'**تقسيم العمل (قرار صاحب المشروع، 2026-10-22):** **الصوت كله عندك** (المعلق العربي وأصوات الملعب). ومن الصور **جزء بسيط:** لوحات الملاعب من كل الدفعات ({len(mine)} صورة)، بعد الصوت. وباقي الصور وكل إعادة عند سليمان ([`SLIEMAN.md`](SLIEMAN.md)). والتقرير الكامل لكل مقطع ولكل صورة لك آخر هذا الملف.\n')
    wave1_voice(W, clips, vst)
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
    pending = [b for b in mine if st[b[2]] == 'pending']
    if pending:
        steps.append(f"**⏳ {len(pending)} صورة مرفوعة تنتظر المراجعة:** قل لـ Claude «راجع».")
    left = [b for b in mine if st[b[2]] in ('redo', 'todo')]
    if left:
        steps.append(f"**ثم الصور بترتيب الدفعات ({len(left)} صورة):** لوحات الملاعب الجديدة فقط بترتيب الدفعات. من كتاب الصور، وكل دفعة في [`00-waves.md`](art/images/00-waves.md). أول {rates.HAMZA_IMG_PER_DAY} في الجدول تحت.")
    for i, s in enumerate(steps, 1):
        W(f'{i}. {s}')
    W(f'\n**الإيقاع:** حوالي {rates.VOICE_PER_DAY} مقطعاً معتمداً يومياً، ثم {rates.HAMZA_IMG_PER_DAY} صورة معتمدة يومياً. وتواريخ كل دفعة في [`SCHEDULE.md`](SCHEDULE.md)، قسما «مسار الصوت» و«مسار الصور».\n')
    nxt, w = next_images(mine, redo, st, rates.HAMZA_IMG_PER_DAY)
    image_table(W, f'أول صورك بعد الصوت، من الدفعة {w}', nxt, redo)
    W('## طريقة التسجيل\n')
    W('1. **باللهجة المصرية،** بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع (قرار 2026-10-20).')
    W('2. **النص مكتوب بالمصرية كما يُقال، بلا تشكيل:** اقرأه كما هو.')
    W('3. **جملة واحدة لكل مقطع،** بلا جملة من مقطع آخر وبلا تكرار طويل. والمقطع الذي قبل اللحظة (pre) لا يكشف النتيجة.')
    W('4. **الحفظ:** باسم الملف وفي المجلد المكتوبين في قائمة الدفعة. والصيغة WAV أو MP3 أو M4A.')
    W('5. **أصوات الملعب:** بترخيص CC0 أو مولّدة، والحلقات لا يُسمع مكان تكرارها.\n')
    W('### بعد الرفع\n')
    W('- ارفع إلى `main` بالأسماء الصحيحة، وقل: «راجع الصوت».')
    W('- المعتمد يُعلَّم ✅، والمرفوض يُحذف من مجلده وينتقل لقائمة الإعادة بسببه.\n')
    image_howto(W)
    W('## الحالة بالأرقام\n')
    W('### الصوت\n')
    W('| الدفعة | المجموع | ✅ | 🔁 | 👂 | ⬜ | القائمة |'); W('|---|---|---|---|---|---|---|')
    for w in vwaves:
        c = vcount[w]
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['redo']} | {c['check']} | {c['missing']} | [`wave-{w:02d}.md`](audio/todo/wave-{w:02d}.md) |")
    W(f"| أصوات الملعب | {len(sfx)} | {scount['done']} | {scount['redo']} | {scount['check']} | {scount['missing']} | [`sfx.md`](audio/todo/sfx.md) |")
    tot = {k: sum(vcount[w][k] for w in vwaves) for k in ('done', 'redo', 'check', 'missing')}
    W(f"| **المعلق كله** | **{sum(tot.values())}** | **{tot['done']}** | **{tot['redo']}** | **{tot['check']}** | **{tot['missing']}** | |\n")
    W('### الصور (لوحات الملاعب الجديدة، والإعادة عند سليمان)\n')
    image_counts(W, mine, st, my_waves)
    W('## كل الملفات\n')
    W('| الملف | ما فيه |'); W('|---|---|')
    W('| [`audio/todo/README.md`](audio/todo/README.md) | ملخص الصوت، ومنه قائمة كل دفعة |')
    W('| [`audio/ARABIC_VOICE.md`](audio/ARABIC_VOICE.md) | كتالوج المعلق كاملاً والشرح |')
    W('| `audio/raw/<المجلد>/README.md` | أسماء ملفات كل مجلد |')
    W('| [`art/FOLDERS.md`](art/FOLDERS.md) | **كل مجلد صور برسالة واحدة:** تنسخها كاملة في Gemini فيصنع صور المجلد كلها |')
    W('| [`art/images/00-waves.md`](art/images/00-waves.md) | كل دفعات الصور ومجموعاتها ومجلداتها |')
    W('| [`art/images/00-guide.md`](art/images/00-guide.md) | دليل كتاب الصور: الأسلوب وجمل التصحيح |')
    W('| `art/raw/<المجلد>/README.md` | أسماء صور كل مجلد ومرفقاتها |\n')
    W('## التقرير الكامل\n')
    by = made_by()
    audio_report(W, clips, vst, sfx, sst, by)
    image_report(W, mine, redo, st, by)
    open(os.path.join(ROOT, 'docs', 'HAMZA.md'), 'w', encoding='utf-8', newline='\n').write(voice.plain('\n'.join(o)) + '\n')
    return vcount[1]


HAMZA_EMAILS = ('dark20005devil@gmail.com',)
NAME = {'slieman': 'سليمان', 'hamza': 'حمزة'}


def made_by():
    """path -> 'hamza' | 'slieman': who uploaded each file in art/raw/ and audio/raw/, from git history.
    A file Claude saved from Sliman's chat is Sliman's; a moved file keeps its first author."""
    import subprocess
    log = subprocess.run(['git', '-C', ROOT, 'log', '--reverse', '-M', '--name-status', '--diff-filter=AR', '--format=@%ae',
                          '--', 'art/raw', 'audio/raw'], capture_output=True, text=True).stdout
    who, author = {}, ''
    for line in log.split('\n'):
        if line.startswith('@'):
            author = 'hamza' if line[1:] in HAMZA_EMAILS else ('claude' if 'anthropic' in line else 'slieman')
        elif line[:1] in 'AR' and '\t' in line:
            parts = line.split('\t')
            old, new = (parts[1], parts[-1])
            if line[0] == 'R' and old in who:
                who[new] = who.pop(old)          # a move (by anyone, or a squash merge) keeps the first author
            else:
                who[new] = 'slieman' if author == 'claude' else author
    return who


IMG_WORD = {'done': '✅ مكتمل', 'pending': '⏳ مرفوع، ينتظر المراجعة', 'redo': '🔁 يجب إعادته', 'todo': '⬜ لم يتم العمل عليه'}


def image_report(W, mine, redo, st, by):
    """The full report of one person's images: every board by wave and group, its state and who made it."""
    W('### الصور: كل صورة بحالتها\n')
    W('**الحالة:** ✅ مكتمل (معتمد في المراجعة) · ⏳ مرفوع ينتظر المراجعة · 🔁 يجب إعادته · ⬜ لم يتم العمل عليه. '
      '**من:** للمكتمل والمرفوع من رفعه فعلاً (تاريخ git)، ولغيره من عليه أن يعمله.\n')
    W('| الدفعة | المجموع | ✅ | ⏳ | 🔁 | ⬜ |'); W('|---|---|---|---|---|---|')
    for w in sorted({b[0] for b in mine}):
        c = {k: sum(1 for b in mine if b[0] == w and st[b[2]] == k) for k in IMG_WORD}
        W(f"| {w} | {sum(c.values())} | {c['done']} | {c['pending']} | {c['redo']} | {c['todo']} |")
    c = {k: sum(1 for b in mine if st[b[2]] == k) for k in IMG_WORD}
    W(f"| **الكل** | **{len(mine)}** | **{c['done']}** | **{c['pending']}** | **{c['redo']}** | **{c['todo']}** |\n")
    for w in sorted({b[0] for b in mine}):
        W(f'#### الدفعة {w}\n')
        W('| الحالة | من | اللوحة | الملف | الأمر في |'); W('|---|---|---|---|---|')
        for wave, code, path, md, g in [b for b in mine if b[0] == w]:
            k = st[path]
            who = NAME[by.get(path, who_makes((wave, code, path, md, g), st))] if k in ('done', 'pending') else NAME[who_makes((wave, code, path, md, g), st)]
            where = f'{link(redo[path][0])}: {redo[path][1]}' if k == 'redo' else f'[`{md}`](art/images/{md})'
            W(f'| {IMG_WORD[k]} | {who} | {code} | `{path}` | {where} |')
        W('')


def audio_report(W, clips, vst, sfx, sst, by):
    """The full report of the voice: every clip and stadium sound, its state and who recorded it."""
    word = {'done': '✅ مكتمل', 'check': '👂 مسجَّل، ينتظر التأكد بالسمع', 'redo': '🔁 يجب إعادته', 'missing': '⬜ لم يتم العمل عليه'}
    W('### الصوت: كل مقطع بحالته\n')
    W('**الحالة:** ✅ مكتمل · 👂 مسجَّل ينتظر التأكد بالسمع · 🔁 يجب إعادته · ⬜ لم يتم العمل عليه. والصوت كله على حمزة.\n')
    rows = [(c, vst[(c[1], c[2])]) for c in clips] + [(c, sst[(c[1], c[2])]) for c in sfx]
    groups = [(f'الدفعة {w}', [r for r in rows if r[0][1] != 'sfx' and r[0][0] == w]) for w in sorted({c[0] for c in clips})]
    groups.append(('أصوات الملعب', [r for r in rows if r[0][1] == 'sfx']))
    W('| | المجموع | ✅ | 👂 | 🔁 | ⬜ |'); W('|---|---|---|---|---|---|')
    for name, rs in groups:
        c = {k: sum(1 for r in rs if r[1] == k) for k in word}
        W(f"| {name} | {len(rs)} | {c['done']} | {c['check']} | {c['redo']} | {c['missing']} |")
    c = {k: sum(1 for r in rows if r[1] == k) for k in word}
    W(f"| **الكل** | **{len(rows)}** | **{c['done']}** | **{c['check']}** | **{c['redo']}** | **{c['missing']}** |\n")
    for name, rs in groups:
        W(f'#### {name}\n')
        W('| الحالة | من | الملف | النبرة | النص | ملاحظة |'); W('|---|---|---|---|---|---|')
        for cl, k in rs:
            W(f"| {word[k]} | حمزة | `audio/raw/{cl[1]}/{cl[2]}` | {cl[3]} | {cl[4]} | {voice.status(cl[1], cl[2])[1]} |")
        W('')


if __name__ == '__main__':
    cur, img = write_slieman()
    v1 = write_hamza()
    print('docs/SLIEMAN.md: sprint', cur, img, '· docs/HAMZA.md voice wave 1:', v1)
    import folders
    print('docs/art/FOLDERS.md (folders, with work left):', folders.main())
