"""The whole plan day by day (docs/SCHEDULE.md): python3 tools/plan/schedule.py

Reads every sprint and its tasks from docs/SPRINTS.md, gives each sprint a length in
working days (5 hours a day, every day), spreads its tasks over those days by size,
and dates every version. Sprint lengths are estimates: re-run it after each sprint
with the real start date of the next one (START, DONE_UNTIL) to move the dates.
"""
import re, os, datetime as dt
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
START = dt.date(2026, 10, 20)        # first working day of sprint 2
S = open(os.path.join(ROOT, 'docs', 'SPRINTS.md')).read()

# working days per sprint: images at 25 a day; code sprints by the size of their tasks
LEN = {2: 1, 3: 5, 4: 4, 5: 4, 6: 4, 7: 4, 8: 5,
       40: 14,                                     # the trial season is played in real days
       41: 7, 42: 5, 43: 6, 44: 8, 45: 5,          # Flutter rebuilds every screen
       46: 4, 47: 4, 48: 4, 49: 3, 50: 5, 51: 5, 52: 4}  # phase Z only builds images already made in the image track
VERSIONS = {8: ('v0.1', 'المحاكي المصوّر: مباراة كاملة بالصور والمعلقين على الويب والجوال'),
            20: ('v0.2', 'أول تجربة مع الأصدقاء: دوري حقيقي ومباراة حية على الويب'),
            21: ('v0.3', 'المعلم الأول: المباراة على الجوال والجهاز المنزلي'),
            31: ('v0.5', 'مزايا OSM كلها: السوق والكشاف والتدريب والملعب والتجسس والأخصائيون'),
            36: ('v0.8', 'دورة الحياة: نهاية الموسم والعملة المميزة والصوت والإشعارات'),
            40: ('v1.0', 'الإطلاق على الويب (PWA) بعد موسم تجريبي'),
            45: ('v1.1', 'تطبيق Android (Flutter)'),
            46: ('v1.2', 'الدفعة 2 من الصور والصوت'), 47: ('v1.3', 'الدفعة 3'), 48: ('v1.4', 'الدفعة 4'),
            49: ('v1.5', 'الدفعة 5: الملاعب الأخرى'), 50: ('v1.6', 'الدفعتان 6 و7: كل اللقطات مصورة'),
            51: ('v1.7', 'الدفعات 8 إلى 11: التنوع'), 52: ('v1.8', 'النسخة النهائية: كل الصور والصوت')}
IMAGES = {46: 279, 47: 364, 48: 348, 49: 250, 50: 322, 51: 213, 52: 94}

def short(t):
    t = re.sub(r'\*\*|`|\[[^\]]*\]', '', t).strip()
    t = re.split(r'[:،(]', t)[0].strip()
    return t[:60]
sprints = {}
for m in re.finditer(r'\n### Sprint (\d+): ([^\n]*)\n(.*?)(?=\n### Sprint |\n## )', S, re.S):
    n = int(m.group(1)); body = m.group(3)
    tasks = [(c.strip(), short(t)) for c, t in re.findall(r'^\| ([A-Z][A-Z0-9.]*(?: إلى [A-Z0-9]+)?) \| (.*?) \|\s*$', body, re.M)]
    sizes = [max(60, len(t)) for c, t in re.findall(r'^\| ([A-Z][A-Z0-9.]*(?: إلى [A-Z0-9]+)?) \| (.*?) \|\s*$', body, re.M)]
    sprints[n] = (m.group(2).strip(), tasks, sizes)
for n in range(46, 53):
    sprints[n] = (f'الصور الكاملة: {VERSIONS[n][1]}', [('W', f'بناء صور الدفعة ({IMAGES[n]}) وصوتها في اللعبة'), ('X', 'مباراة كاملة للتجربة ونشر النسخة')], [3, 1])

# the image track: the images are made in parallel with the code, 25 a day, from day 1
# wave 1's Arabic voice (98 clips) comes right after its images: the simulator sprints need both
WAVES = [(1, 246), ('صوت 1', 'audio'), (2, 279), (3, 364), (4, 348), (5, 250), ('6 و7', 322), ('8 إلى 11', 213), ('12 إلى 16', 94)]
track, d0 = [], START
for w, n in WAVES:
    k = 3 if n == 'audio' else -(-n // 25); track.append((w, n, d0, d0 + dt.timedelta(days=k - 1))); d0 += dt.timedelta(days=k)

def phase(n):
    return next(p for a, b, p in [(1, 8, '0. المحاكي'), (9, 17, 'أ. الأساس'), (18, 21, 'ب. المباراة المباشرة'), (22, 31, 'ج. مزايا OSM'),
                                  (32, 36, 'د. دورة الحياة'), (37, 40, 'هـ. إطلاق الويب'), (41, 45, 'و. Flutter'), (46, 52, 'ز. الصور الكاملة')] if a <= n <= b)
# Owner's decision (2026-10-20): the photo simulator sprints (3 to 8) wait for wave 1's images and voice;
# the code goes on with the other sprints meanwhile, and takes up 3 to 8 as soon as the art is ready.
# DONE: sprints whose code is finished, with the day it was: they take no more days.
DONE = {2: dt.date(2026, 10, 20), 9: dt.date(2026, 10, 20), 10: dt.date(2026, 10, 20), 11: dt.date(2026, 10, 20)}
SIM = [3, 4, 5, 6, 7, 8]
READY = next(b for w, n, a, b in track if w == 'صوت 1')   # wave 1 complete, images and voice
rows, summary, day = [], [], START + dt.timedelta(days=1) if DONE else START
for n in sorted(DONE):
    summary.append((n, phase(n), sprints[n][0], 0, DONE[n], DONE[n]))
queue = [n for n in [9, 10, 11] + list(range(12, 53)) if n not in DONE]
sim_placed = False
while queue or not sim_placed:
    if not sim_placed and (day > READY or not queue):
        batch, sim_placed = SIM, True
        day = max(day, READY + dt.timedelta(days=1))   # never before its art
    else:
        batch = [queue.pop(0)]
    for n in batch:
        title, tasks, sizes = sprints[n]
        d = LEN.get(n) or max(4, min(8, round(sum(sizes) / 110)))
        first = day
        tot = sum(sizes) or 1; edges = []; acc = 0
        for (c, t), z in zip(tasks, sizes):
            edges.append((acc / tot * d, (acc + z) / tot * d, c, t)); acc += z
        for i in range(d):
            today = [f'{c} {t}' for a, b, c, t in edges if a < i + 1 and b > i]
            if i == d - 1: today.append('تعريف الانتهاء والدمج')
            rows.append((day, n, ' · '.join(today)))
            day += dt.timedelta(days=1)
        summary.append((n, phase(n), title, d, first, day - dt.timedelta(days=1)))

MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
def ar(d): return f'{d.day} {MONTHS[d.month - 1]} {d.year}'
def days(k):  # Arabic counted noun: 100 يوم، 104 أيام، 145 يوماً
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
o = []; W = o.append
W('# Legends: الخطة كاملة بالأيام\n')
W('> يولّده `tools/plan/schedule.py` من `docs/SPRINTS.md`. **5 ساعات عمل كل يوم**، بلا أيام راحة. مدة كل سبرنت تقدير: سبرنتات الصور بعدد الصور (25 صورة معتمدة يومياً)، وسبرنتات الكود بحجم مهامها (4 إلى 8 أيام). يُعاد توليده في نهاية كل سبرنت بتاريخ بدء التالي، فتتحرك التواريخ بالواقع.\n')
W(f'**البداية:** {START.isoformat()} (السبرنت 1 منجز، وكود 2 و9 و10 و11 منجز {START.isoformat()}). **النهاية:** {summary[-1][5].isoformat()}. **المجموع:** {len(rows)} {days(len(rows))} عمل.\n')
W('## متى تخرج كل نسخة\n')
W(f'**المشروع كاملاً: {len(rows)} {days(len(rows))} عمل** بواقع 5 ساعات يومياً، من {ar(START)} إلى **{ar(summary[-1][5])}**. وبيوم راحة في الأسبوع يصير قرابة {round(len(rows) * 7 / 6)} يوماً.\n')
W('| النسخة | ماذا فيها | بعد السبرنت | التاريخ | بعد |'); W('|---|---|---|---|---|')
BIG = {'v1.0', 'v1.1', 'v1.8'}
for n, (v, what) in VERSIONS.items():
    end = next(x[5] for x in summary if x[0] == n); k = (end - START).days + 1
    b = '**' if v in BIG else ''
    W(f'| **{v}** | {b}{what}{b} | {n} | {b}{ar(end)}{b} | {k} {days(k)} |')
W('\n### كيف حُسبت المدد\n')
W('- **الصور:** 25 صورة معتمدة يومياً في مسارها الموازي (حمزة)، والصوت العربي للدفعة 1 بعد صورها مباشرة. سبرنتات المحاكاة المصورة (3 إلى 8) تنتظر الدفعة 1 صوراً وصوتاً، فالكود يكمل الأساس (9 إلى 11) قبلها ثم يرجع لها. وسبرنتات المرحلة ز للبناء فقط لأن صورها جاهزة قبلها.')
W('- **سبرنتات الكود:** من 4 إلى 8 أيام حسب حجم مهامها. Claude يكتب الكود، وصاحب المشروع يراجع ويجرّب ويعتمد.')
W('- **الموسم التجريبي قبل v1.0:** 14 يوماً، لأن المباريات تُلعب بأيام حقيقية مع الأصدقاء.')
W('- **سبرنتات Flutter:** أطول، لأن كل شاشة تُبنى من جديد في التطبيق.')
W('- **تقديرات:** يُعاد توليد الملف في نهاية كل سبرنت بالتاريخ الفعلي. وأكبر عامل يغيّرها نسبة إعادة الصور.')
W('\n## مسار الصور (بالتوازي مع الكود)\n')
W('**قرار صاحب المشروع (2026-10-20):** صانع الصور (حمزة) يصنع كل الدفعات بلا توقف من اليوم الأول، 25 صورة معتمدة يومياً، والصوت العربي معها، بالتوازي مع سبرنتات الكود. فتكون كل الصور جاهزة قبل المرحلة ز، وسبرنتاتها للبناء والتجربة والنشر فقط.\n')
W('| الدفعة | العدد | من | إلى | تُبنى في |'); W('|---|---|---|---|---|')
BUILT = {1: '3 إلى 8 (v0.1)', 'صوت 1': '3 و7 (v0.1)', 2: '46 (v1.2)', 3: '47 (v1.3)', 4: '48 (v1.4)', 5: '49 (v1.5)', '6 و7': '50 (v1.6)', '8 إلى 11': '51 (v1.7)', '12 إلى 16': '52 (v1.8)'}
for w, n, a, b in track: W(f'| {w} | {"98 مقطعاً" if n == "audio" else n} | {ar(a)} | {ar(b)} | السبرنت {BUILT[w]} |')
W(f'\n**كل الصور جاهزة:** {ar(track[-1][3])}.')
W('\n## السبرنتات\n')
W('| السبرنت | المرحلة | العنوان | الأيام | من | إلى |'); W('|---|---|---|---|---|---|')
for n, ph, title, d, a, b in summary:
    W(f'| {n} | {ph} | {title} | {d} | {a.isoformat()} | {b.isoformat()} |')
W('\n## كل يوم\n')
cur = None
for date, n, what in rows:
    if n != cur:
        cur = n; t = sprints[n][0]
        W(f'\n### Sprint {n}: {t}\n'); W('| اليوم | التاريخ | المهام |'); W('|---|---|---|')
    W(f'| {(date - START).days + 1} | {date.isoformat()} | {what} |')
open(os.path.join(ROOT, 'docs', 'SCHEDULE.md'), 'w').write('\n'.join(o) + '\n')
print(len(rows), summary[-1][5])
