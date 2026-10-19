# The full image book in Nano Banana style: the data comes from build_book.py and book3_extra.py,
# every prompt is rewritten as one descriptive paragraph, three figures per board,
# and each board after the first carries the first board as a reference image.
import re
src = open('build_book.py').read()
END = 'o = [' + ']; W = o.append'
data = src[src.index('# ---------------- stadiums ----------------'):src.index(END)]

WHITE = 'The kit must be pure white, because the game paints the team colours on it.'
KIT = f'He wears a plain pure white football kit (white short-sleeve shirt, white shorts, white socks) and black boots, with no logos or numbers. {WHITE}'
GK = f'He wears a plain pure white long-sleeve goalkeeper shirt, white shorts, white socks, black boots and big black goalkeeper gloves, with no logos or numbers. {WHITE}'
BIB = f'They wear plain pure white training tops and shorts with plain white bibs, white socks and black boots. {WHITE}'
REF = 'He wears an all-black referee kit (black shirt, shorts and socks, black boots) with a whistle on a cord around his neck.'
CAM = ('The camera is a TV broadcast camera at pitch level, about one metre above the grass, with a 35mm lens and a level horizon; '
       'the bottom edge of the advertising boards sits a little below the middle of the image.')
LIGHT = ('Photorealistic 3D render in the style of a modern console football game, lit by night stadium floodlights from high above and slightly behind: '
         'cool bluish white light with a bright rim light on the head, shoulders and arms, and slightly darker lower legs.')
ANAT = ('Correct, natural anatomy in every pose: knees and elbows bend the natural way, both legs and both arms complete, '
        'feet pointing where the body moves, five fingers on each hand.')
GREEN = 'The background is one flat, solid chroma-key green (#00FF00) with nothing else on it, no floor and no shadows, so each figure is easy to cut out.'
MAG = 'The background is one flat, solid magenta (#FF00FF) with nothing else on it, so each item is easy to cut out.'
NOTEXT = 'The image has no text, no numbers and no logos.'
POS = {1: ['In the centre'], 2: ['On the left', 'On the right'], 3: ['On the left', 'In the middle', 'On the right'],
       4: ['Top left', 'Top right', 'Bottom left', 'Bottom right']}
grid = {1: (1, 1), 2: (2, 1), 3: (3, 1), 4: (2, 2), 5: (3, 2), 6: (3, 2)}
def lines(cells): return ' '.join(f'{p}: {c[0].lower() + c[1:]}' for p, (_, c) in zip(POS[len(cells)], cells))
def fix_ground(t): return t.replace('on the grass', 'on the ground').replace('to the grass', 'to the ground').replace('from the grass', 'from the ground')

# every prompt function returns a recipe; the expansion below turns recipes into boards
def char(first, who, poses, kind=None): return {'k': 'char', 'who': who, 'cells': poses, 'many': kind is not None, 'per': 3}
def duo(first, who, poses): return {'k': 'duo', 'who': who, 'cells': poses, 'per': 2}
def half(first, who, poses): return {'k': 'half', 'who': who, 'cells': poses, 'per': 4}
def faces(who, poses): return {'k': 'faces', 'who': who, 'cells': poses, 'per': 4}
def obj(first, what, items, bg='green'): return {'k': 'obj', 'who': what, 'cells': items, 'bg': bg, 'per': 3}
data = data.replace(", MAG)", ", 'magenta')").replace("bg=MAG,", "bg='magenta',").replace("'pure black background, not transparent'", "'black'")
data = data.replace("'Photorealistic render, ' + GREEN + ', no people", "'Photorealistic render on a flat solid chroma-key green background (#00FF00), no people")
exec(data)
exec(open('book3_extra.py').read())

def board_prompt(rec, cells, ref):
    n = len(cells); k = rec['k']
    start = 'Use the attached image as the reference for this exact same person: the same face, hair, body and clothes. ' if ref else ''
    if k == 'char':
        if rec['many']:
            start = 'Use the attached image as the reference for the style, light and kit. ' if ref else ''
            subj, lay = f'{n} different fictional footballers, each with a different look', 'side by side in one row'
        else:
            subj = 'the same fictional man' if n > 1 else 'a fictional man'
            lay = {1: 'once, centred', 2: 'twice, side by side in one row, with plenty of room for wide poses', 3: 'three times, side by side in one row'}[n]
        body = (f'{start}A wide 3:2 landscape image showing {subj} {lay}, every figure full body from head to boots, all at the same size and scale, '
                f'with clear space between them and nothing cut off. Unless a pose says otherwise he is seen from the side, facing right. '
                f'{fix_ground(rec["who"])} {fix_ground(lines(cells))} {LIGHT} {ANAT} {GREEN} {NOTEXT}')
    elif k == 'duo':
        start = 'Use the attached image as the reference for the style and light. ' if ref else ''
        body = (f'{start}A wide 3:2 landscape image with {n} separate scenes side by side in one row, each showing fictional people together, '
                f'full body from head to boots, interacting naturally, with clear space between the scenes and nothing cut off. '
                f'{fix_ground(rec["who"]).replace("He wears", "Everyone wears")} {fix_ground(lines(cells))} {LIGHT} {ANAT} {GREEN} {NOTEXT}')
    elif k == 'half':
        body = (f'{start}A wide 3:2 landscape image with {n} close-ups in a 2 by 2 grid, from the waist up, seen from the front facing the camera, '
                f'all the same size with clear space between them. {rec["who"]} {lines(cells)} {LIGHT} {ANAT} {GREEN} {NOTEXT}')
    elif k == 'faces':
        body = (f'{start}A wide 3:2 landscape image with {n} close-up portraits of the same fictional man in a 2 by 2 grid, head and shoulders, '
                f'three-quarter view facing right, each with a blurred night stadium and floodlights behind him, separated by thin black lines. '
                f'{rec["who"].replace(" " + WHITE, "")} {lines(cells)} Photorealistic 3D render like a modern console football game, '
                f'lit by cool stadium floodlights with a rim light on his hair. {NOTEXT}')
    else:
        start = 'Use the attached image as the reference for the style and light, and for the exact same object where it repeats. ' if ref else ''
        bg = {'green': GREEN.replace('each figure', 'each item'), 'magenta': MAG, 'black': 'The background is pure black, because these are light effects.'}[rec['bg']]
        lay = {1: 'one item, centred', 2: 'two separate items side by side in one row', 3: 'three separate items side by side in one row'}[n]
        body = (f'{start}A wide 3:2 landscape image with {lay}, each with clear space around it and nothing cut off. {rec["who"]} '
                f'{lines(cells)} Photorealistic render lit by cool night stadium floodlights from above. {bg} {NOTEXT}')
    return re.sub(r'\s+', ' ', body).strip()

def plate_prompt(p, first, variant=False):
    m = re.search(r'Photorealistic football stadium: (.*?), full crowd blurred in the stands', p)
    if m:
        v = p.split(CAM)[-1].strip()
        start = ('Use the attached image as the reference for the same stadium architecture, the same camera height and lens; the weather and light are as described here. ' if variant else
                 '' if first else 'Use the attached image as the reference: the same stadium, the same camera height and lens, the same light and colours. ')
        same = '' if first else ' This must be exactly the same stadium as the attached image: the same roof, seats, LED ribbons, advertising boards, floodlights and colours.'
        return (f'{start}A wide 16:9 landscape photograph of a football stadium: {m.group(1)}, with a full crowd blurred in the stands. {v} {CAM} '
                'The pitch is completely empty: no players, no people on the grass and no ball. Photorealistic and cinematic, like a live TV broadcast. ' + NOTEXT + same)
    body = p
    for junk in ['Same style as before.', 'Same stadium as before.', 'Same stadium and same light as before.', 'Photorealistic, cinematic, landscape 1536x1024.',
                 'Photorealistic, cinematic, landscape 1536x1024,', 'no logos, no text,', 'no logos, no text.', ', no logos, no text.', 'no logos, no text']:
        body = body.replace(junk, ' ')
    body = re.sub(r'\s+([,.])', r'\1', re.sub(r'\s+', ' ', body)).strip(' ,.') + '.'
    body = body[0].upper() + body[1:]
    return re.sub(r'\s+', ' ', ('Use the attached image as the reference for the style, light and colours. ' if not first else '') +
                  'A wide 16:9 landscape photograph. ' + body + ' Photorealistic and cinematic, like a live TV broadcast. ' + NOTEXT)

BOOK = []
for g in G:
    boards = []; first_done = bool(g.get('ref_from')); first_ref = g.get('ref_from')
    for it in g['items']:
        if it[0] == 'plate':
            _, f, why, used, p = it
            boards.append(dict(f=f, why=why, used=used, ref=first_ref or first_done, p=plate_prompt(p, not first_done, g.get('variant', False)))); first_done = True; first_ref = None
        elif it[0] == 'single':
            _, f, p = it
            boards.append(dict(f=f, why='صورة واحدة تملأ الشاشة', ref=False, p=re.sub(r'\s+', ' ', p.replace('landscape 1536x1024', 'wide 3:2 landscape image'))))
        else:
            rec = it[3]; f = it[1]
            cells = rec['cells']; per = rec['per']
            parts = [cells[i:i + per] for i in range(0, len(cells), per)]
            for pi, part in enumerate(parts):
                name = f if len(parts) == 1 else f.replace('.png', f'-{"abcdef"[pi]}.png')
                boards.append(dict(f=name, names='، '.join(x for x, _ in part), ref=first_ref or first_done, p=board_prompt(rec, part, first_done)))
                first_done = True; first_ref = None
    BOOK.append(dict(t=g['t'], folder=g['f'], note=g['note'], boards=boards, part=g.get('part')))

o = []; W = o.append
PN = dict(PARTS)
nb = sum(len(b['boards']) for b in BOOK)
W('# Legends: كتاب صور اللقطات، الإصدار الرابع (Nano Banana)\n')
W(f'الملف الكامل والوحيد، **يحل محل كل الملفات السابقة**: **{len(BOOK)} مجموعة** و**{nb} لوحة**، أوامرها مكتوبة لـ Nano Banana (تطبيق Gemini)، وتصلح لـ ChatGPT أيضاً.\n')
W('## ما الجديد في هذا الإصدار\n')
W('- **15 ملعباً بهوية مختلفة**، كل واحد في حالته الأساسية بكل زوايا الكاميرا، ومعه حالتان أخريان: ليل، نهار، غروب، مطر، ثلج، ضباب، حر.')
W('- **24 شكل لاعب**، و**4 حراس**، و**10 مدربين** (منهم مدربة)، و**3 حكام** (منهم حكمة)، ومعهم الحكم المساعد والحكم الرابع.')
W('- **مجموعات للمواقف:** البطاقة الصفراء، والبطاقة الحمراء، وقرارات الحكم، ومراحل الفار وغرفته، والشجار، والاحتفالات الفردية والجماعية، والكأس، وركلات الترجيح.')
W('- **البث المباشر:** الشاشة العملاقة، ولوحة النتيجة، والاستوديو، والمعلقون، والمصورون، وغرفة الإخراج. كل الشاشات فارغة، واللعبة تعرض عليها النتيجة والإعادات.')
W('- **6 كرات** بتصاميم مختلفة، و**5 مرامٍ** بأنواع شباك مختلفة، ولقطات قريبة للشبكة والقائم.')
W('- **36 مؤثراً** في 6 مجموعات: أرض، طقس، أضواء، نار ودخان، احتفال، حركة.')
W('- **11 مقطعاً جديداً** (L23 إلى L33) أُضيفت إلى جدول اللقطات.\n')
W('## الفكرة\n')
W('- **الملاعب** صور كاملة لزوايا كاميرا ثابتة، والمرمى جزء منها.')
W('- **الشخصيات** لوحات من 3 حركات على خلفية خضراء وبقميص أبيض. أنا أقصها، وألوّنها بألوان كل نادٍ، وأحركها فوق الملعب بحجمها الصحيح مع الظل والإضاءة.')
W('- **البطاقات** في مجموعتيها بلونها الحقيقي، وفي باقي اللوحات بيضاء تلوّنها اللعبة.\n')
W('## طريقة العمل في Nano Banana\n')
W('1. **كل مجموعة في محادثة جديدة.**')
W('2. **اللوحة الأولى** في المجموعة (مكتوب عندها «بلا مرفق»): الصق الأمر كما هو.')
W('3. **كل لوحة بعدها** (مكتوب عندها «ارفق اللوحة الأولى»): ارفق صورة اللوحة الأولى من نفس المجموعة، ثم الصق الأمر.')
W('4. **مجموعات المهاجم الإضافية** (الحالات الخاصة، والأهداف الاستعراضية، والاحتفالات): ارفق مع لوحتها الأولى صورة `sheet-run-a.png` من مجموعة المهاجم الرئيسي، حتى يبقى نفس الوجه.')
W('5. **احفظ كل صورة باسمها المكتوب** داخل مجلدها، ولا تقصها.')
W('6. **أرسل لي أول لوحتين من كل مجموعة جديدة** قبل أن تكملها، 4 صور في الرسالة على الأكثر مع أسمائها. أو ارفع مجلد `art` على GitHub: **Add file** ← **Upload files** ← **Commit directly to the main branch**.\n')
W('## قبل حفظ كل لوحة\n')
W('- [ ] كل الحركات موجودة بالترتيب، من اليسار إلى اليمين.')
W('- [ ] كل جسم كامل من الرأس إلى الحذاء، غير مقصوص.')
W('- [ ] التشريح طبيعي: الركبة تنثني للأمام، ولا رِجل أو يد مكسورة أو ملتوية، وخمسة أصابع.')
W('- [ ] نفس الوجه في اللوحة وفي كل لوحات المجموعة.')
W('- [ ] القميص أبيض (اللاعبون والحارس والبدلاء)، والخلفية خضراء مصمتة.')
W('- [ ] صور الملاعب بلا لاعبين ولا كرة، والمرمى كامل حين يظهر.')
W('- [ ] الشاشات فارغة بلا كتابة.\n')
W('## جمل التصحيح (اكتبها في نفس المحادثة)\n')
W('| المشكلة | الجملة |')
W('|---|---|')
W('| حركة خاطئة | `Redo only the figure on the right: the leg looks unnatural. Keep everything else the same.` (بدّل right بـ left أو middle) |')
W('| الخلفية ليست خضراء | `Same image, but on a flat solid chroma-key green background (#00FF00).` |')
W('| القميص ملوّن | `Same image, but the kit must be pure white.` |')
W('| وجه مختلف | `The face must be exactly the same person as in the attached image. Redo it.` |')
W('| الصورة مربعة | `Make it a wide 3:2 landscape image.` (والملاعب: `16:9`) |')
W('| ناس في صورة الملعب | `Same image, but with the pitch completely empty.` |')
W('| كتابة على شاشة | `Same image, but every screen must be blank and dark.` |')
W('| حركة ناقصة | `Redo it with exactly three figures in one row, same person, same order.` |\n')
W('## مراحل الإنتاج\n')
W('| المرحلة | ما تصنعه | ما يصبح جاهزاً |')
W('|---|---|---|')
W('| 1 | ملعب الأرينا ليلاً، المهاجم الرئيسي، حارس المرمى، الكرة الكلاسيكية، المرمى العادي | الهدف، والتصدي، والفرصة الضائعة، وركلة الجزاء |')
W('| 2 | المدافع، الجناح، لاعب الوسط، حكم الساحة، الحكم المساعد، البطاقتان | البطاقات، والتسلل، والضربة الحرة، والركنية، والمرتدة |')
W('| 3 | الفار وغرفته، المدربان الأولان، الحكم الرابع، البدلاء، الطاقم الطبي، الاحتفالات | التبديل، والإصابة، والفار، والاحتفالات |')
W('| 4 | البث المباشر، الجمهور، المؤثرات، المرامي والكرات الأخرى | الشاشات، والأجواء، والإعادات |')
W('| 5 | الملاعب الأخرى وحالاتها | تنوع الملاعب والطقس |')
W('| 6 | أشكال اللاعبين والحراس والمدربين والحكام الإضافية، الكأس، ركلات الترجيح، الأهداف الاستعراضية | تنوع الوجوه والمقاطع الجديدة |\n')
W('## كل لقطة وما تحتاجه\n')
W('| اللقطة | الاسم | زوايا الملعب | الصور |')
W('|---|---|---|---|')
for m in MAP: W(f'| {m[0]} | {m[1]} | {m[2]} | {m[3]} |')
W('\nالمقاطع من L23 إلى L33 جديدة: صورها هنا، وأحداثها في المحرك تُضاف لاحقاً بقرار منك.\n')
W('## الفهرس\n')
cur = None; i = 0
for g in BOOK:
    i += 1
    if g['part'] != cur:
        cur = g['part']; W(f'\n**{PN[cur]}**\n')
    W(f'{i}. {g["t"]} ({len(g["boards"])} لوحة)')
W('\n---\n')
n = 0; cur = None
for gi, g in enumerate(BOOK, 1):
    if g['part'] != cur:
        cur = g['part']; W(f'# {PN[cur]}\n')
    W(f'## المجموعة {gi}: {g["t"]}\n')
    W(f'**المجلد:** `{g["folder"]}`  ')
    W(f'**المحادثة:** جديدة. {g["note"]}\n')
    for j, b in enumerate(g['boards'], 1):
        n += 1
        W(f'### {gi}.{j} `{b["f"]}`\n')
        what = b.get('why') or b.get('names')
        extra = f' · **تُستخدم في:** {b["used"]}' if b.get('used') else ''
        att = f'**ارفق `{b["ref"]}`**' if isinstance(b['ref'], str) else ('**ارفق اللوحة الأولى**' if b['ref'] else 'بلا مرفق')
        W(f'{what}{extra} · {att}\n')
        W('```\n' + b['p'] + '\n```\n')
W('---\n')
W(f'المجموع: **{len(BOOK)} مجموعة**، **{n} لوحة**.')
open('LEGENDS-IMAGES-v4.md', 'w').write('\n'.join(o) + '\n')
print(len(BOOK), n)
