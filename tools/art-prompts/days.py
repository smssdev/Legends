"""Sprint 2 day plan (docs/sprints/sprint-02-days.md): python3 tools/art-prompts/days.py

Splits the wave 1 boards that are not done yet into days (tools/plan/rates.py), in the order of
docs/art/images/00-waves.md. A board counts as done when its file is in art/raw/ or
it is marked ✅ in the current plan, so running it again keeps the progress.
"""
import re, os, sys, datetime as dt
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(ROOT, 'tools', 'plan'))
import rates  # noqa: E402
IMG = os.path.join(ROOT, 'docs', 'art', 'images')
OUT = os.path.join(ROOT, 'docs', 'sprints', 'sprint-02-days.md')
PER_DAY, START = rates.IMG_PER_DAY, rates.PLAN_START

waves = open(os.path.join(IMG, '00-waves.md'), encoding='utf-8').read()
w1 = waves[waves.index('## الدفعة 1 '):waves.index('## الدفعة 2')]
boards = []
for r in w1.split('\n'):
    if not r.startswith('| ') or 'القسم' in r: continue
    c = [x.strip() for x in r.strip('|').split('|')]
    num = int(c[1].split('.')[0]); md = re.search(r'\((.*?)\)', c[3]).group(1); folder = c[4].strip('`')
    if md in rates.MANUAL_BOOKS: continue   # made by hand outside the plan (docs/SLIEMAN.md, their own section)
    t = open(os.path.join(IMG, md), encoding='utf-8').read()
    a = t.index(f'## المجموعة {num}:'); b = t.find('\n## ', a + 5); g = t[a:b if b > 0 else None]
    boards += [(k, folder + f, md, c[1]) for k, f in re.findall(r'### (\d+\.\d+) `([^`]+)`', g)]
marked = set(re.findall(r'\| ✅ \| [\d.]+ \| `([^`]+)`', open(OUT, encoding='utf-8').read())) if os.path.exists(OUT) else set()
done = [b for b in boards if b[1] in marked or os.path.exists(os.path.join(ROOT, b[1]))]
rem = [b for b in boards if b not in done]

o = []; W = o.append
W('# Sprint 2: خطة الأيام (الدفعة 1 من الصور)\n')
W('> **سليمان يصنع الصور بنفسه بالتوازي مع السبرنتات (قرار 2026-10-20)، ومرجعه اليومي `docs/SLIEMAN.md`.** الصور المرفوضة تبدأ من ملفات الإعادة في `docs/art/redo/`، والجديدة من هنا بالترتيب. وبعد اعتماد كل صورة تُحفظ في مجلدها ويُشغَّل `python3 tools/art-prompts/days.py` فتصير ✅ هنا.\n')
W(f'**الإيقاع:** للصور {rates.IMG_HOURS} من {rates.DAY_HOURS} ساعات كل يوم = **{PER_DAY} صورة معتمدة يومياً**، والباقي للكود. ما لم يُنجز في يومه ينتقل لأول اليوم التالي، والملف يعيد التوزيع كلما شُغّل.\n')
W(f'**الدفعة 1:** {len(boards)} صورة. **المنجز:** {len(done)}. **الباقي:** {len(rem)}، أي {-(-len(rem) // PER_DAY)} {rates.days_word(-(-len(rem) // PER_DAY))}.\n')
W('**تعلمناه حتى الآن:** إذا أعاد Gemini نفس الصورة بلا تغيير، نعيدها في محادثة جديدة. وClaude يرسل ملفات المرفقات مع كل أمر.\n')
W('## المنجز\n')
W('| | اللوحة | الملف | المجموعة | الأوامر |'); W('|---|---|---|---|---|')
for k, f, md, title in done: W(f'| ✅ | {k} | `{f}` | {title} | `{md}` |')
W('')
for d in range(0, len(rem), PER_DAY):
    day = d // PER_DAY + 1; chunk = rem[d:d + PER_DAY]
    W(f'## اليوم {day}: {(START + dt.timedelta(days=day - 1)).isoformat()} ({len(chunk)} صورة)\n')
    W('| | اللوحة | الملف | المجموعة | الأوامر |'); W('|---|---|---|---|---|')
    for k, f, md, title in chunk: W(f'| ⬜ | {k} | `{f}` | {title} | `{md}` |')
    W('')
last = START + dt.timedelta(days=-(-len(rem) // PER_DAY) - 1)
W(f'## بعد آخر يوم\n')
W(f'صور الدفعة 1 كلها معتمدة ({last.isoformat()})، فتبدأ سبرنتات المحاكاة المصورة (3 إلى 8) حين يكتمل صوتها أيضاً (`docs/SCHEDULE.md`). والصور تكمل بالدفعة 2.')
open(OUT, 'w', encoding='utf-8', newline='\n').write('\n'.join(o) + '\n')
print(len(boards), len(done), len(rem))
