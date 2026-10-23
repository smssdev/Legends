"""The team's two daily references: python3 tools/team.py (after tools/plan/schedule.py)

Owner's decision (2026-10-23): the match images and the Flow videos are cancelled, and the realistic match is
built in Unity after the sprints (phase Z). So Sliman's whole day is code with Claude, and the voice is all
Hamza's (tools/plan/rates.py).
- docs/SLIEMAN.md: Sliman's day (the current sprint), what waits on his decisions, the next sprints with their
  dates, and the numbers.
- docs/HAMZA.md: the voice in order, with how to record it, the numbers, and a full report of every clip:
  its state and who recorded it.
Both come from what is in audio/raw/, the voice lists (tools/commentary/todo.py), docs/SPRINTS.md and
docs/SCHEDULE.md. Run it after every review and every merged sprint.
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path[:0] = [os.path.join(ROOT, 'tools', 'commentary'), os.path.join(ROOT, 'tools', 'plan')]
import todo as voice      # noqa: E402
import rates             # noqa: E402


# Things only Sliman can unblock: keep this list current (remove a line once it is done).
OPEN_DECISIONS = [
    ('D0 / D1', 'اعتماد نظام التصميم وشاشات السبرنتات 9 و10 و11 و13 إلى 17 و20 و22 إلى 34 (المكونات، والحساب، والفريق، والدوريات والانضمام، والدعوة والإجازة والطرد، والترتيب والمباريات والكأس، والتشكيلة، والتكتيك والمباراة القادمة، وشاشة المباراة وتقريرها، وصندوق الرسائل، والمالية، والسوق والعروض، والكشاف، والتدريب والمعسكر والتدريب السري، والملعب، والتجسس، والأخصائيون، وزر الاستقالة، وقاعة الشرف وملف المدرب، والمحفظة والمتجر، وبطاقة التطبيق والإشعارات، ولوحة الإدارة)', 'الشاشات المكتوبة تنتظره، ولا تُكتب شاشة جديدة قبل تصميمها'),
    ('التجارب المؤجلة', 'تجارب الجهاز المنزلي والجوال والأصدقاء T1 إلى T12 (PWA، وجوجل، والرابط العام، والمشغّل، والحمل، وأول تجربة مع الأصدقاء، والحارس وتنبيه ntfy، والاستماع للصوت، والإشعارات، والاسترجاع على جهاز نظيف، والنشر أثناء مباراة)', 'مؤجلة بقرارك (2026-10-22) ومسجلة في «التجارب المؤجلة» بـ `docs/SPRINTS.md`، ولا توقف السبرنتات'),
    ('مواصفات مزايا OSM', 'موافقة المواصفات المكتوبة على آلية OSM بأرقام مبدئية: الكشاف (`docs/features/scout.md`)، والمعسكر (`camp.md`)، والتدريب السري (`secret-training.md`)، والتجسس (`spy.md`)، والأخصائيون (`specialists.md`)، وأسعار الكوينز ومكافآتها (`premium.md`)', 'الكود مبني عليها وكل رقم في `config/game.php`'),
    ('سقف المال بين ناديين', 'طُبق على ما يُدفع فوق القيمة (لا على كل المال) حتى لا تُمنع الصفقات العادلة (`docs/sprints/sprint-25.md`)', 'يُغيَّر بسطر في `App\\Market\\Transfers` لو أردت غيره'),
    ('الدوري النزيه', 'الكوينز مقفلة فيه، فالتجسس والتدريب السري والأخصائيون تُدفع فيه بأموال النادي، والإنهاء الفوري غير متاح (`docs/features/premium.md`)', 'أو تُقفل هذه المزايا فيه كلياً لو أردت'),
    ('استقالة المنشئ', 'منشئ الدوري لا يستقيل منه لأنه يديره (الخطة لا تقول)', 'يُسمح له بسطر في `Leaving::resign` لو أردت، ويبقى منشئاً بلا فريق'),
    ('معادلة هدف النادي', 'الأقوى: اللقب. ربع القمة: ترتيبه + 1. الباقي: + 2. ولا أحد أقل من الخروج من آخر الخُمس. والكأس بربع الترتيب (`docs/sprints/sprint-33.md`)', 'الأرقام في `config(\'game.objectives\')`'),
    ('صوت المعلق العربي', 'خمسة أصوات كاملة (428 مقطعاً لكل صوت) سليمة تقنياً ومبنية في المحاكي باسم «صوت 1» إلى «صوت 5» (زر «المعلق»). أسماء مجلداتها أسماء معلقين حقيقيين (الشوالي، ومدحت، وفارس، وفهد، وعلي): لو كانت مستنسخة من أصواتهم فلا تُنشر في اللعبة، كالمدرب 2 المرفوض لشبهه بمدرب حقيقي', 'اسمعها في المحاكي واختر صوتاً واحداً مخترعاً، ويُحذف الباقي'),
    ('ميزة الأرض', 'اعتماد +5% من القدرة و+4.5% من المبادرة بدل 2.5% (`docs/sprints/sprint-12.md`)', 'الرقم في `config/game.php` ويُغيَّر بسطر'),
]


def voice_states():
    clips = voice.catalog()
    vst = {(c[1], c[2]): voice.status(c[1], c[2])[0] for c in clips}
    sfx = voice.sfx()
    sst = {(c[1], c[2]): voice.status(c[1], c[2])[0] for c in sfx}
    return clips, vst, sfx, sst


def left_by_wave():
    """Voice clips still to make, by wave (the plan uses them): {wave: n}."""
    clips, vst, sfx, sst = voice_states()
    vo = {}
    for c in clips:
        if vst[(c[1], c[2])] != 'done':
            vo[c[0]] = vo.get(c[0], 0) + 1
    left_sfx = sum(1 for k in sst.values() if k != 'done')
    if left_sfx:
        vo['أصوات الملعب'] = left_sfx
    return vo


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


def wave1_voice(W, clips, vst):
    """The first priority for the voice: every wave 1 clip not approved yet, with its text."""
    left = [c for c in clips if c[0] == 1 and vst[(c[1], c[2])] != 'done']
    done = sum(1 for c in clips if c[0] == 1 and vst[(c[1], c[2])] == 'done')
    W('## ⭐ الأولوية الآن: الدفعة 1 (المعلق العربي في المحاكي)\n')
    W('**المعلق العربي في المحاكي (السبرنت 7) يُبنى بالدفعة 1.** فكل ما تحت يسبق أي مقطع من دفعة أخرى.\n')
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
    W('')


def write_slieman():
    rows, versions = schedule_rows()
    done_sprints = {int(r[0]) for r in rows if r[3] == '0'}
    upcoming = [r for r in rows if r[3] != '0']
    current = int(upcoming[0][0])
    title, tasks, dod, goal = sprint_block(current)
    clips, vst, sfx, sst = voice_states()

    o = []
    W = o.append
    W('# دليل سليمان: السبرنتات\n')
    W('> **مرجعك اليومي.** منه تعرف ماذا تعمل اليوم، وما ينتظر قرارك، وما القادم بتواريخه.')
    W('> يولّده `python3 tools/team.py` بعد كل مراجعة وكل دمج، فلا يُعدَّل يدوياً. والخطة كاملة في [`SCHEDULE.md`](SCHEDULE.md).\n')
    W(f'**تقسيم العمل (قرار صاحب المشروع، 2026-10-23):** الصور وفيديوهات Flow **ملغاة**، والمباراة الواقعية تُبنى في **Unity** بعد تطبيق Flutter (السبرنتات 46 إلى 52، v2.0). فيومك كله ({rates.DAY_HOURS} ساعات) **للكود** مع Claude. و**الصوت كله عند حمزة** ([`HAMZA.md`](HAMZA.md)).\n')

    # ------------------------------------------------------------ today
    W(f'## يومك: Sprint {current}، {title}\n')
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
    W('### آخر الجلسة\n')
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
    W('\n**النسخ:** ' + '، '.join(f'{v[0]} في {v[3]}' for v in versions if v[0] in ('v0.9', 'v1.0', 'v1.1', 'v2.0')) + '.\n')

    # ------------------------------------------------------------ numbers
    W('## الحالة بالأرقام\n')
    vdone = sum(1 for k in vst.values() if k == 'done')
    v1 = [c for c in clips if c[0] == 1]
    v1done = sum(1 for c in v1 if vst[(c[1], c[2])] == 'done')
    W('### الصوت (حمزة)\n')
    W(f'الدفعة 1: {v1done} من {len(v1)} معتمدة. والكل: {vdone} من {len(clips)} مقطعاً، وأصوات الملعب {sum(1 for k in sst.values() if k == "done")} من {len(sfx)}. التفاصيل في [`HAMZA.md`](HAMZA.md).\n')
    W(f"**السبرنتات المنجزة:** {'، '.join(str(n) for n in sorted(done_sprints))} (والسبرنت 1). السجل في [`SPRINTS.md`](SPRINTS.md).\n")

    # ------------------------------------------------------------ index
    W('## كل الملفات\n')
    W('| الملف | ما فيه |'); W('|---|---|')
    W('| [`SCHEDULE.md`](SCHEDULE.md) | الخطة يوماً يوماً، وتاريخ كل نسخة |')
    W('| [`SPRINTS.md`](SPRINTS.md) | كل السبرنتات ومهامها، وسجل الإنجاز، والتجارب المؤجلة |')
    W('| [`MATCH_VIEW.md`](MATCH_VIEW.md) | عرض المباراة، والمباراة الواقعية في Unity (4.7) |')
    W('| [`MOMENTS.md`](MOMENTS.md) | اللقطات، ومجسمات Unity وحركات Mixamo |')
    W('| [`HAMZA.md`](HAMZA.md) | مرجع حمزة: الصوت كله |')
    open(os.path.join(ROOT, 'docs', 'SLIEMAN.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
    return current


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
    W('**تقسيم العمل (قرار صاحب المشروع، 2026-10-23):** **الصوت كله عندك** (المعلق العربي وأصوات الملعب). والصور **ملغاة**، فلا لوحات ملاعب عليك: الملاعب والمباراة الواقعية تُبنى في Unity بعد تطبيق Flutter، ومقاطعك تُستخدم فيها كما هي. والتقرير الكامل لكل مقطع آخر هذا الملف.\n')
    wave1_voice(W, clips, vst)
    W('## المطلوب الآن، بالترتيب\n')
    steps = []
    v1 = vcount[1]
    if v1['redo'] or v1['check']:
        steps.append(f"**🔁 أعد المقاطع المرفوضة من الدفعة 1 ({v1['redo']})، و👂 تأكد بالسمع من ({v1['check']}):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، أول قسمين.")
    if v1['missing']:
        steps.append(f"**⬜ سجّل باقي الدفعة 1 ({v1['missing']} مقطعاً):** [`audio/todo/wave-01.md`](audio/todo/wave-01.md)، قسم «لم يُسجَّل بعد».")
    rest = [w for w in vwaves if w > 1 and vcount[w]['done'] < sum(vcount[w].values())]
    if rest:
        n = sum(sum(vcount[w].values()) - vcount[w]['done'] for w in rest)
        steps.append(f"**ثم الدفعات {rest[0]} إلى {rest[-1]} بالترتيب ({n} مقطعاً):** كل دفعة في قائمتها، أولها [`audio/todo/wave-{rest[0]:02d}.md`](audio/todo/wave-{rest[0]:02d}.md). وكل دفعة تدخل اللعبة حين تُعتمد.")
    if scount['missing'] or scount['redo']:
        steps.append(f"**ثم أصوات الملعب ({scount['missing'] + scount['redo']}):** [`audio/todo/sfx.md`](audio/todo/sfx.md).")
    for i, s in enumerate(steps, 1):
        W(f'{i}. {s}')
    W(f'\n**الإيقاع:** حوالي {rates.VOICE_PER_DAY} مقطعاً معتمداً يومياً. وتواريخ كل دفعة في [`SCHEDULE.md`](SCHEDULE.md)، قسم «مسار الصوت».\n')
    W('## طريقة التسجيل\n')
    W('1. **باللهجة المصرية،** بنفس الصوت ونفس الإعدادات من أول مقطع لآخر مقطع (قرار 2026-10-20).')
    W('2. **النص مكتوب بالمصرية كما يُقال، بلا تشكيل:** اقرأه كما هو.')
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
    W('| `audio/raw/<المجلد>/README.md` | أسماء ملفات كل مجلد |\n')
    W('## التقرير الكامل\n')
    audio_report(W, clips, vst, sfx, sst)
    open(os.path.join(ROOT, 'docs', 'HAMZA.md'), 'w', encoding='utf-8', newline='\n').write(voice.plain('\n'.join(o)) + '\n')
    return vcount[1]


def audio_report(W, clips, vst, sfx, sst):
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
    cur = write_slieman()
    v1 = write_hamza()
    print('docs/SLIEMAN.md: sprint', cur, '· docs/HAMZA.md voice wave 1:', v1)
