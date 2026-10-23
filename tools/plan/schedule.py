"""The whole plan day by day (docs/SCHEDULE.md): python3 tools/plan/schedule.py

Reads every sprint and its tasks from docs/SPRINTS.md and what is left of the images and the voice
(tools/team.py), gives each sprint a length in full working days, stretches it over the calendar
while part of every day goes to images (tools/plan/rates.py), spreads its tasks over those days, and
dates every version and both art tracks. Lengths are estimates: re-run it after each sprint and review
(add the finished sprint to DONE) so the dates follow what really happened.
"""
import re, os, sys, datetime as dt
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
S = open(os.path.join(ROOT, 'docs', 'SPRINTS.md'), encoding='utf-8').read()

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

# Owner's decision (2026-10-22, tools/plan/rates.py): Sliman makes the first image waves beside the code, a few
# hours a day, and Hamza records the voice, then makes the image waves built last. The code moves at CODE_HOURS a
# day while Sliman has images left, and full time after.
sys.path[:0] = [os.path.join(ROOT, 'tools', 'plan'), os.path.join(ROOT, 'tools')]
import rates  # noqa: E402
import team   # noqa: E402
START = rates.PLAN_START
_, voice_left = team.left_by_wave()
img_left = team.images_left()
vtrack, v0 = [], START
VGROUPS = [('صوت 1', [1]), ('صوت 2', [2]), ('صوت 3', [3]), ('صوت 4', [4]), ('صوت 5', [5]), ('صوت 6 إلى 12', list(range(6, 13))), ('أصوات الملعب', ['أصوات الملعب'])]
for name, ws in VGROUPS:
    n = sum(voice_left.get(w, 0) for w in ws)
    if not n:
        continue
    k = max(1, -(-n // rates.VOICE_PER_DAY))
    vtrack.append((name, n, v0, v0 + dt.timedelta(days=k - 1)))
    v0 += dt.timedelta(days=k)
voice1 = next((b for nm, n, a, b in vtrack if nm == 'صوت 1'), START - dt.timedelta(days=1))
GROUPS = [(1, [1]), (2, [2]), (3, [3]), (4, [4]), (5, [5]), ('6 و7', [6, 7]), ('8 إلى 11', [8, 9, 10, 11]), ('12 إلى 16', [12, 13, 14, 15, 16])]
WHO = {'slieman': 'سليمان', 'hamza': 'حمزة'}
PER_DAY = {'slieman': rates.IMG_PER_DAY, 'hamza': rates.HAMZA_IMG_PER_DAY}
track, nxt = [], {'slieman': START, 'hamza': v0}   # Sliman from day one, Hamza once his voice is done
for name, ws in GROUPS:
    for who in ('slieman', 'hamza'):
        n = sum(img_left.get((w, who), 0) for w in ws)
        if not n and rates.image_owner(ws[0]) != who:
            continue                                    # a wave shows once its own when nothing of it is left
        k = max(1, -(-n // PER_DAY[who])) if n else 0
        d0 = nxt[who]
        track.append((name, n, d0, d0 + dt.timedelta(days=k - 1) if k else d0 - dt.timedelta(days=1), who))
        nxt[who] += dt.timedelta(days=k)
IMAGES_END = max((b for nm, n, a, b, who in track if who == 'slieman'), default=START - dt.timedelta(days=1))   # Sliman's last image day
ALL_IMAGES_END = max(b for nm, n, a, b, who in track)
img1 = max(b for nm, n, a, b, who in track if nm == 1)

def phase(n):
    return next(p for a, b, p in [(1, 8, '0. المحاكي'), (9, 17, 'أ. الأساس'), (18, 21, 'ب. المباراة المباشرة'), (22, 31, 'ج. مزايا OSM'),
                                  (32, 36, 'د. دورة الحياة'), (37, 40, 'هـ. إطلاق الويب'), (41, 45, 'و. Flutter'), (46, 52, 'ز. الصور الكاملة')] if a <= n <= b)
def code_hours(day):
    return rates.CODE_HOURS if day <= IMAGES_END else rates.DAY_HOURS
# Owner's decision (2026-10-20): the photo simulator sprints (3 to 8) wait for wave 1's images and voice;
# the code goes on with the other sprints meanwhile, and takes up 3 to 8 as soon as the art is ready.
# DONE: sprints whose code is finished, with the day it was: they take no more days.
DONE = {2: dt.date(2026, 10, 20), 9: dt.date(2026, 10, 20), 10: dt.date(2026, 10, 20), 11: dt.date(2026, 10, 20), 12: dt.date(2026, 10, 20), 13: dt.date(2026, 10, 22), 14: dt.date(2026, 10, 22), 15: dt.date(2026, 10, 22), 16: dt.date(2026, 10, 22), 17: dt.date(2026, 10, 22), 18: dt.date(2026, 10, 22), 19: dt.date(2026, 10, 22), 20: dt.date(2026, 10, 22), 21: dt.date(2026, 10, 22), 22: dt.date(2026, 10, 22), 23: dt.date(2026, 10, 23), 24: dt.date(2026, 10, 23), 25: dt.date(2026, 10, 23), 26: dt.date(2026, 10, 23), 27: dt.date(2026, 10, 23), 28: dt.date(2026, 10, 23), 29: dt.date(2026, 10, 23), 30: dt.date(2026, 10, 23), 31: dt.date(2026, 10, 23), 32: dt.date(2026, 10, 23), 33: dt.date(2026, 10, 23), 34: dt.date(2026, 10, 23), 35: dt.date(2026, 10, 23), 36: dt.date(2026, 10, 23), 37: dt.date(2026, 10, 23)}
CALENDAR = {40}                      # the trial season is played in real days, whatever the hours
SIM = [3, 4, 5, 6, 7, 8]
READY = max(img1, voice1)            # wave 1 complete, images and voice
rows, summary, day = [], [], START
for n in sorted(DONE):
    summary.append((n, phase(n), sprints[n][0], 0, DONE[n], DONE[n]))
queue = [n for n in range(9, 53) if n not in DONE]
sim_placed = False
while queue or not sim_placed:
    if not sim_placed and (day > READY or not queue):
        batch, sim_placed = SIM, True
        day = max(day, READY + dt.timedelta(days=1))   # never before its art
    else:
        batch = [queue.pop(0)]
    for n in batch:
        title, tasks, sizes = sprints[n]
        full = LEN.get(n) or max(4, min(8, round(sum(sizes) / 110)))   # full-time days of work
        first, cal = day, []
        if n in CALENDAR:
            cal = [day + dt.timedelta(days=i) for i in range(full)]
        else:
            work = full * rates.DAY_HOURS                                 # hours of work, done at the hours left for code
            while work > 0:
                cal.append(day); work -= code_hours(day); day += dt.timedelta(days=1)
            day -= dt.timedelta(days=len(cal))
        day += dt.timedelta(days=len(cal))
        d = len(cal)
        tot = sum(sizes) or 1; edges = []; acc = 0
        for (c, t), z in zip(tasks, sizes):
            edges.append((acc / tot * d, (acc + z) / tot * d, c, t)); acc += z
        for i, date in enumerate(cal):
            today = [f'{c} {t}' for a, b, c, t in edges if a < i + 1 and b > i]
            if i == d - 1: today.append('تعريف الانتهاء والدمج')
            rows.append((date, n, ' · '.join(today)))
        summary.append((n, phase(n), title, d, first, cal[-1]))

def images_on(date):
    return ' · '.join(f'{WHO[who]}: الدفعة {nm} ({PER_DAY[who]})' for nm, n, a, b, who in track if n and a <= date <= b)

MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
def ar(d): return f'{d.day} {MONTHS[d.month - 1]} {d.year}'
def days(k):  # Arabic counted noun: 100 يوم، 104 أيام، 145 يوماً
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
o = []; W = o.append
total = (summary[-1][5] - START).days + 1
W('# Legends: الخطة كاملة بالأيام\n')
W(f'> يولّده `tools/plan/schedule.py` من `docs/SPRINTS.md` وحالة الصور والصوت الحالية، ووتيرة العمل في `tools/plan/rates.py`. يُعاد في نهاية كل سبرنت وبعد كل مراجعة، فتتحرك التواريخ بالواقع. ومرجع سليمان اليومي `docs/SLIEMAN.md`، ومرجع حمزة `docs/HAMZA.md`.\n')
W(f'**البداية:** {START.isoformat()} (السبرنت 1 منجز، وكود 2 و9 إلى 12 منجز). **النهاية:** {summary[-1][5].isoformat()}. **المجموع:** {total} {days(total)}.\n')
W('**تقسيم العمل (قرار صاحب المشروع، 2026-10-22):**')
W(f'- **سليمان:** {rates.DAY_HOURS} ساعات كل يوم: الكم الأكبر من الصور (كلها ما عدا الملاعب) وكل صورة تحتاج إعادة، في {rates.IMG_HOURS} منها ({rates.IMG_PER_DAY} صورة معتمدة)، والكود الباقي ({rates.CODE_HOURS}) مع Claude. وبعد آخر صورة له ({IMAGES_END.isoformat()}) يصير اليوم كله للكود.')
W(f'- **حمزة:** الصوت كله أولاً ({rates.VOICE_PER_DAY} مقطعاً معتمداً يومياً)، ثم جزء بسيط من الصور: لوحات الملاعب من كل الدفعات ({rates.HAMZA_IMG_PER_DAY} صورة معتمدة يومياً).\n')
W('## متى تخرج كل نسخة\n')
W('| النسخة | ماذا فيها | بعد السبرنت | التاريخ | بعد |'); W('|---|---|---|---|---|')
BIG = {'v1.0', 'v1.1', 'v1.8'}
for n, (v, what) in VERSIONS.items():
    end = next(x[5] for x in summary if x[0] == n); k = (end - START).days + 1
    b = '**' if v in BIG else ''
    W(f'| **{v}** | {b}{what}{b} | {n} | {b}{ar(end)}{b} | {k} {days(k)} |')
W('\n### كيف حُسبت المدد\n')
W(f'- **سبرنتات الكود:** من 4 إلى 8 أيام عمل كاملة حسب حجم مهامها، وتطول بالتقويم ما دام للكود {rates.CODE_HOURS} ساعات فقط من اليوم. Claude يكتب الكود، وسليمان يراجع ويجرّب ويعتمد.')
W('- **المحاكاة المصورة (3 إلى 8):** تبدأ حين تكتمل صور الدفعة 1 وصوتها معاً، والكود يكمل السبرنتات الأخرى بالترتيب حتى ذلك.')
W('- **الموسم التجريبي قبل v1.0:** 14 يوماً بالتقويم، لأن المباريات تُلعب بأيام حقيقية مع الأصدقاء.')
W('- **المرحلة ز (46 إلى 52):** للبناء فقط، لأن صورها وصوتها جاهزة قبلها.')
W('- **أكبر عامل يغيّر التواريخ:** نسبة إعادة الصور. لو صار عدد الصور اليومي أكثر أو أقل، غيّره في `rates.py` وأعد التوليد.')
W('\n## مسار الصور (سليمان بالتوازي مع الكود، وحمزة بعد الصوت)\n')
W('| الدفعة | من يصنعها | الباقي | من | إلى | تُبنى في |'); W('|---|---|---|---|---|---|')
BUILT = {1: '3 إلى 8 (v0.1)', 2: '46 (v1.2)', 3: '47 (v1.3)', 4: '48 (v1.4)', 5: '49 (v1.5)', '6 و7': '50 (v1.6)', '8 إلى 11': '51 (v1.7)', '12 إلى 16': '52 (v1.8)'}
for w, n, a, b, who in track:
    W(f'| {w} | {WHO[who]} | {n} | {ar(a)} | {ar(b)} | السبرنت {BUILT[w]} |' if n else f'| {w} | {WHO[who]} | 0 | | | السبرنت {BUILT[w]} |')
W(f'\n**آخر صورة لسليمان:** {ar(IMAGES_END)}. **كل الصور جاهزة:** {ar(ALL_IMAGES_END)}.')
W('\n## مسار الصوت (حمزة)\n')
W('| الدفعة | الباقي | من | إلى |'); W('|---|---|---|---|')
for w, n, a, b in vtrack:
    W(f'| {w} | {n} | {ar(a)} | {ar(b)} |')
W(f'\n**الدفعة 1 جاهزة صوراً وصوتاً:** {ar(READY)}، فتبدأ المحاكاة المصورة بعدها.')
W('\n## السبرنتات\n')
W('| السبرنت | المرحلة | العنوان | الأيام | من | إلى |'); W('|---|---|---|---|---|---|')
for n, ph, title, d, a, b in summary:
    W(f'| {n} | {ph} | {title} | {d} | {a.isoformat()} | {b.isoformat()} |')
W('\n## كل يوم\n')
cur = None
for date, n, what in sorted(rows, key=lambda r: r[0]):
    if n != cur:
        cur = n; t = sprints[n][0]
        W(f'\n### Sprint {n}: {t}\n'); W('| اليوم | التاريخ | الكود | الصور |'); W('|---|---|---|---|')
    W(f'| {(date - START).days + 1} | {date.isoformat()} | {what} | {images_on(date)} |')
open(os.path.join(ROOT, 'docs', 'SCHEDULE.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
print(total, summary[-1][5], 'images end', IMAGES_END, 'ready', READY)
