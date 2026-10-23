"""The whole plan day by day (docs/SCHEDULE.md): python3 tools/plan/schedule.py

Reads every sprint and its tasks from docs/SPRINTS.md and what is left of the voice (tools/team.py), gives
each sprint a length in full working days, spreads its tasks over those days, and dates every version and
the voice track. Lengths are estimates: re-run it after each sprint and review (add the finished sprint to
DONE) so the dates follow what really happened.
"""
import re, os, sys, datetime as dt
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
S = open(os.path.join(ROOT, 'docs', 'SPRINTS.md'), encoding='utf-8').read()

# working days per sprint; code sprints without a number here go by the size of their tasks
LEN = {4: 4, 5: 4, 6: 4, 7: 4, 8: 5,
       40: 14,                                     # the trial season is played in real days
       41: 7, 42: 5, 43: 6, 44: 8, 45: 5,          # Flutter rebuilds every screen
       46: 6, 47: 7, 48: 7, 49: 5, 50: 6, 51: 5, 52: 5}  # Unity: a new engine, models and animations
VERSIONS = {20: ('v0.2', 'أول تجربة مع الأصدقاء: دوري حقيقي ومباراة حية على الويب'),
            21: ('v0.3', 'المعلم الأول: المباراة على الجوال والجهاز المنزلي'),
            31: ('v0.5', 'مزايا OSM كلها: السوق والكشاف والتدريب والملعب والتجسس والأخصائيون'),
            36: ('v0.8', 'دورة الحياة: نهاية الموسم والعملة المميزة والصوت والإشعارات'),
            8: ('v0.9', 'المحاكي النهائي: الملعب المتحرك والمعلقان وأصوات الملعب على الويب والجوال'),
            40: ('v1.0', 'الإطلاق على الويب (PWA) بعد موسم تجريبي'),
            45: ('v1.1', 'تطبيق Android (Flutter)'),
            52: ('v2.0', 'المباراة الواقعية في Unity: في التطبيق وعلى الكمبيوتر')}
# Owner's decision (2026-10-23): the image tool and the photo scene (sprints 2 and 3) are cancelled with the images.
CANCELLED = {2, 3}

def short(t):
    t = re.sub(r'\*\*|`|\[[^\]]*\]', '', t).strip()
    t = re.split(r'[:،(]', t)[0].strip()
    return t[:60]
sprints = {}
for m in re.finditer(r'\n### Sprint (\d+): ([^\n]*)\n(.*?)(?=\n### Sprint |\n## )', S, re.S):
    n = int(m.group(1)); body = m.group(3)
    rows = re.findall(r'^\| ([A-Z][A-Z0-9.]*(?: إلى [A-Z0-9]+)?) \| (.*?) \|\s*$', body, re.M)
    sprints[n] = (m.group(2).strip(), [(c.strip(), short(t)) for c, t in rows], [max(60, len(t)) for c, t in rows])

sys.path[:0] = [os.path.join(ROOT, 'tools', 'plan'), os.path.join(ROOT, 'tools')]
import rates  # noqa: E402
import team   # noqa: E402
START = rates.PLAN_START
# DONE: sprints whose code is finished, with the day it was: they take no more days.
DONE = {9: dt.date(2026, 10, 20), 10: dt.date(2026, 10, 20), 11: dt.date(2026, 10, 20), 12: dt.date(2026, 10, 20), 13: dt.date(2026, 10, 22), 14: dt.date(2026, 10, 22), 15: dt.date(2026, 10, 22), 16: dt.date(2026, 10, 22), 17: dt.date(2026, 10, 22), 18: dt.date(2026, 10, 22), 19: dt.date(2026, 10, 22), 20: dt.date(2026, 10, 22), 21: dt.date(2026, 10, 22), 22: dt.date(2026, 10, 22), 23: dt.date(2026, 10, 23), 24: dt.date(2026, 10, 23), 25: dt.date(2026, 10, 23), 26: dt.date(2026, 10, 23), 27: dt.date(2026, 10, 23), 28: dt.date(2026, 10, 23), 29: dt.date(2026, 10, 23), 30: dt.date(2026, 10, 23), 31: dt.date(2026, 10, 23), 32: dt.date(2026, 10, 23), 33: dt.date(2026, 10, 23), 34: dt.date(2026, 10, 23), 35: dt.date(2026, 10, 23), 36: dt.date(2026, 10, 23), 37: dt.date(2026, 10, 23)}
NEXT = max(START, max(DONE.values()) + dt.timedelta(days=1))   # the first day still ahead
voice_left = team.left_by_wave()
vtrack, v0 = [], NEXT
VGROUPS = [('صوت 1', [1]), ('صوت 2', [2]), ('صوت 3', [3]), ('صوت 4', [4]), ('صوت 5', [5]), ('صوت 6 إلى 12', list(range(6, 13))), ('أصوات الملعب', ['أصوات الملعب'])]
for name, ws in VGROUPS:
    n = sum(voice_left.get(w, 0) for w in ws)
    if not n:
        continue
    k = max(1, -(-n // rates.VOICE_PER_DAY))
    vtrack.append((name, n, v0, v0 + dt.timedelta(days=k - 1)))
    v0 += dt.timedelta(days=k)
voice1 = next((b for nm, n, a, b in vtrack if nm == 'صوت 1'), NEXT - dt.timedelta(days=1))

def phase(n):
    return next(p for a, b, p in [(1, 8, '0. المحاكي'), (9, 17, 'أ. الأساس'), (18, 21, 'ب. المباراة المباشرة'), (22, 31, 'ج. مزايا OSM'),
                                  (32, 36, 'د. دورة الحياة'), (37, 40, 'هـ. إطلاق الويب'), (41, 45, 'و. Flutter'), (46, 52, 'ز. Unity')] if a <= n <= b)
CALENDAR = {40}                      # the trial season is played in real days, whatever the hours
# Owner's decision (2026-10-23): the simulator sprints (4 to 8) no longer wait for images, only for wave 1 of the
# Arabic voice (sprint 7), and they come before the trial season (40), which needs their match screens approved.
SIM = [4, 5, 6, 7, 8]
rows, summary = [], []
day = NEXT
for n in sorted(DONE):
    summary.append((n, phase(n), sprints[n][0], 0, DONE[n], DONE[n]))
queue = [n for n in range(9, 53) if n not in DONE]
queue[queue.index(40):queue.index(40)] = SIM
for n in queue:
    if n == SIM[0]:
        day = max(day, voice1 + dt.timedelta(days=1))    # never before its voice
    title, tasks, sizes = sprints[n]
    full = LEN.get(n) or max(4, min(8, round(sum(sizes) / 110)))   # full-time days of work
    cal = [day + dt.timedelta(days=i) for i in range(full)]
    first = day
    day += dt.timedelta(days=full)
    tot = sum(sizes) or 1; edges = []; acc = 0
    for (c, t), z in zip(tasks, sizes):
        edges.append((acc / tot * full, (acc + z) / tot * full, c, t)); acc += z
    for i, date in enumerate(cal):
        today = [f'{c} {t}' for a, b, c, t in edges if a < i + 1 and b > i]
        if i == full - 1: today.append('تعريف الانتهاء والدمج')
        rows.append((date, n, ' · '.join(today)))
    summary.append((n, phase(n), title, full, first, cal[-1]))
end_of = {x[0]: x[5] for x in summary}

MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
def ar(d): return f'{d.day} {MONTHS[d.month - 1]} {d.year}'
days = rates.days_word
o = []; W = o.append
last = max(x[5] for x in summary)
total = (last - START).days + 1
W('# Legends: الخطة كاملة بالأيام\n')
W(f'> يولّده `tools/plan/schedule.py` من `docs/SPRINTS.md` وحالة الصوت الحالية، ووتيرة العمل في `tools/plan/rates.py`. يُعاد في نهاية كل سبرنت وبعد كل مراجعة، فتتحرك التواريخ بالواقع. ومرجع سليمان اليومي `docs/SLIEMAN.md`، ومرجع حمزة `docs/HAMZA.md`.\n')
W(f'**البداية:** {START.isoformat()} (السبرنت 1 منجز، وكود 9 إلى 37 منجز). **النهاية:** {last.isoformat()}. **المجموع:** {total} {days(total)}.\n')
W('**تقسيم العمل (قرار صاحب المشروع، 2026-10-23):** الصور وفيديوهات Flow ملغاة، والمباراة الواقعية في Unity بعد تطبيق Flutter.')
W(f'- **سليمان:** {rates.DAY_HOURS} ساعات كل يوم للكود مع Claude.')
W(f'- **حمزة:** الصوت كله ({rates.VOICE_PER_DAY} مقطعاً معتمداً يومياً).\n')
W('## متى تخرج كل نسخة\n')
W('| النسخة | ماذا فيها | بعد السبرنت | التاريخ | بعد |'); W('|---|---|---|---|---|')
BIG = {'v1.0', 'v1.1', 'v2.0'}
for n, (v, what) in sorted(VERSIONS.items(), key=lambda x: end_of[x[0]]):
    end = end_of[n]; k = (end - START).days + 1
    b = '**' if v in BIG else ''
    W(f'| **{v}** | {b}{what}{b} | {n} | {b}{ar(end)}{b} | {k} {days(k)} |')
W('\n### كيف حُسبت المدد\n')
W('- **سبرنتات الكود:** من 4 إلى 8 أيام عمل حسب حجم مهامها. Claude يكتب الكود، وسليمان يراجع ويجرّب ويعتمد.')
W('- **المحاكي (4 إلى 8):** الملعب المتحرك المرسوم بالكود، قبل الموسم التجريبي، وبعد اكتمال صوت الدفعة 1. والسبرنتان 2 و3 (أداة الصور والمشهد المصوّر) ملغيان.')
W('- **الموسم التجريبي قبل v1.0:** 14 يوماً بالتقويم، لأن المباريات تُلعب بأيام حقيقية مع الأصدقاء.')
W('- **المرحلة ز (46 إلى 52):** المباراة الواقعية في Unity، وأيامها أطول لأنها محرك جديد بمجسمات وحركات.')
W('\n## مسار الصوت (حمزة)\n')
W('| الدفعة | الباقي | من | إلى |'); W('|---|---|---|---|')
for w, n, a, b in vtrack:
    W(f'| {w} | {n} | {ar(a)} | {ar(b)} |')
W(f'\n**صوت الدفعة 1 جاهز:** {ar(voice1)}، فيبدأ المحاكي (4 إلى 8) بعده متى وصله الكود.')
W('\n## السبرنتات\n')
W('| السبرنت | المرحلة | العنوان | الأيام | من | إلى |'); W('|---|---|---|---|---|---|')
for n, ph, title, d, a, b in summary:
    W(f'| {n} | {ph} | {title} | {d} | {a.isoformat()} | {b.isoformat()} |')
W('\n## كل يوم\n')
cur = None
for date, n, what in sorted(rows, key=lambda r: r[0]):
    if n != cur:
        cur = n; t = sprints[n][0]
        W(f'\n### Sprint {n}: {t}\n'); W('| اليوم | التاريخ | الكود |'); W('|---|---|---|')
    W(f'| {(date - START).days + 1} | {date.isoformat()} | {what} |')
open(os.path.join(ROOT, 'docs', 'SCHEDULE.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
print(total, last, 'voice wave 1', voice1)
