"""A redo list for the image maker: python3 tools/art-prompts/redo.py

For each board that failed review: its problem, its attachments, and its full prompt from the
book with a correction line at the end. Rejected boards are taken out of art/raw/ so the daily
plan (days.py) counts them as not done; their old copies stay in git history.
Edit REVIEW below after each review, then run this and days.py.
"""
import datetime as _dt
import os, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
BG = ('Make it ONE single wide image, not separate panels stitched together. The background is one flat, solid '
      'chroma-key green (#00FF00) from edge to edge: no floodlights, no lamps, no gradient, no floor, no shadows. '
      'The floodlights only light him; they are never visible in the picture.')
GHOST = 'Each figure is drawn once, fully solid: no faded, transparent or ghost copies of legs, arms or bodies anywhere, and nothing between the figures.'
SIDE = 'Do NOT show him in profile from the side.'
WALK = 'A calm walk: one foot always on the ground, no knee lifted high.'
JOG = 'A relaxed jog: low knees, short strides, the feet stay close to the ground; never a high-knee pose.'

RUN_WALK = {
    'date': '2026-10-20', 'title': 'المهاجم: الجري والمشي', 'book': 'docs/art/images/03-players.md', 'out': 'docs/art/redo/2026-10-20-striker-run-walk.md',
    'ok': [('45.1', 'striker/run/run-side-01.png'), ('45.2', 'striker/run/run-side-02.png'), ('45.3', 'striker/run/run-side-03.png'),
           ('45.4', 'striker/run/run-q-front-01.png'), ('45.11', 'striker/run/run-front-02.png'), ('45.12', 'striker/run/run-front-03.png')],
    'notes': [
        '**`run-side-01.png` و`run-side-02.png` و`run-side-03.png`:** كانت معتمدة، ثم استُبدلت بالخطأ في رفع 2026-10-20، وصار `run-side-01.png` البطاقة المرجعية. **أُرجعت النسخ المعتمدة.**',
        '**`run-q-front-01 (2).png`:** نسخة مكررة باسم خطأ، ومحتواها جانبي يطابق `run-side-03` الجديدة. **حُذفت**، والمعتمد `run-q-front-01.png` باقٍ.',
        '**قاعدة للرفع القادم:** لا تُرفع صورة فوق صورة معتمدة (✅). وكل صورة باسمها في `README.md` المجلد بالضبط.',
    ],
    'common': 'صور المشي كلها وصور الانطلاق صُنعت كثلاث لوحات ملصوقة، وخلفيتها خضراء متدرجة فيها كشافات، فلا تُقص. والمطلوب صورة واحدة عريضة بخلفية خضراء واحدة سادة (#00FF00). وأكثر من نصفها جاء بزاوية جانبية بدل المطلوبة.',
    'redo': [
        ('45.5', 'striker/run', 'الزاوية خطأ: جانبية تماماً، والمطلوب ثلاثة أرباع من الأمام مثل run-q-front-01', SIDE + ' He is seen three-quarters from the front, exactly like the attached run-q-front-01.png: his chest and face turned about 45 degrees toward the camera.'),
        ('45.6', 'striker/run', 'الزاوية خطأ: جانبية، والمطلوب ثلاثة أرباع من الأمام', SIDE + ' He is seen three-quarters from the front, exactly like the attached run-q-front-02.png: his chest and face turned about 45 degrees toward the camera.'),
        ('45.7', 'striker/run', 'الزاوية خطأ: جانبية والوجه ظاهر، والمطلوب ثلاثة أرباع من الخلف (يظهر ظهره ومؤخرة رأسه)', SIDE + ' He is seen three-quarters from behind: we see his back and the back of his head, his face is hidden, running away from the camera diagonally to the right.'),
        ('45.8', 'striker/run', 'نفس المشكلة: جانبية بدل ثلاثة أرباع من الخلف', SIDE + ' He is seen three-quarters from behind, exactly like the attached run-q-back-01.png: his back and the back of his head toward the camera, face hidden.'),
        ('45.9', 'striker/run', 'نفس المشكلة: جانبية بدل ثلاثة أرباع من الخلف', SIDE + ' He is seen three-quarters from behind, exactly like the attached run-q-back-02.png: his back and the back of his head toward the camera, face hidden.'),
        ('45.10', 'striker/run', 'الزاوية صحيحة، لكن فيها أرجل شفافة مكررة (أشباح) بين الأشكال', GHOST),
        ('45.13', 'striker/run', 'الزاوية صحيحة، لكن فيها أرجل شفافة مكررة وقطع خضراء عند الأقدام', GHOST),
        ('45.14', 'striker/run', 'الزاوية خطأ (جانبية والوجه ظاهر)، وفيها شكل شفاف في الوسط', SIDE + ' He is seen exactly from behind, like the attached run-back-01.png: his back to the camera, face hidden, running straight away from the camera. ' + GHOST),
        ('45.15', 'striker/run', 'الزاوية خطأ (جانبية)، والخلفية فيها كشافات وتدرج، ودقتها نصف المطلوب', SIDE + ' He is seen exactly from behind, like the attached run-back-02.png: his back to the camera, face hidden. ' + BG),
        ('45.16', 'striker/run', 'الخلفية فيها كشافات وتدرج أخضر (لا تُقص)، ودقتها نصف المطلوب، وشبه مطابقة لـ sprint-02', BG),
        ('45.17', 'striker/run', 'نسخة شبه مطابقة من sprint-01، والخلفية فيها كشافات', BG + ' Each frame here continues from the last frame of the attached sprint-01.png; it must not repeat its poses.'),
        ('45.18', 'striker/run', 'الزاوية خطأ (ثلاثة أرباع من الخلف بدل الجانب)، وفيها شكلان بدل ثلاثة، والخلفية فيها كشافات', 'He is seen exactly from the side, facing right, like the attached sprint-02.png. Exactly 3 figures. ' + BG),
        ('45.19', 'striker/run', 'الخلفية فيها كشافات وتدرج أخضر، ودقتها نصف المطلوب', BG),
        ('46.1', 'striker/walk', 'ثلاث لوحات ملصوقة بخطوط فاصلة، والخلفية فيها كشافات وتدرج، والإطار الثالث ركبة عالية لا هرولة', BG + ' ' + JOG),
        ('46.2', 'striker/walk', 'نفس مشكلة الخلفية واللوحات، وتكاد تطابق jog-03', BG + ' Each frame continues from the attached jog-01.png and never repeats its poses. ' + JOG),
        ('46.3', 'striker/walk', 'نفس مشكلة الخلفية واللوحات، وشبه مطابقة لـ jog-02 وwalk-03، وفيها 3 أشكال والمطلوب 2', BG + ' Exactly 2 figures. ' + JOG),
        ('46.4', 'striker/walk', 'ثلاث لوحات ملصوقة، والخلفية فيها كشافات، والإطار الثالث ركبة عالية لا مشي', BG + ' ' + WALK),
        ('46.5', 'striker/walk', 'نفس المشكلة، والإطار الأول ركبة عالية', BG + ' ' + WALK),
        ('46.6', 'striker/walk', 'نفس المشكلة، وفيها 3 أشكال والمطلوب 2، وفيها ركبتان عاليتان', BG + ' Exactly 2 figures. ' + WALK),
        ('46.7', 'striker/walk', 'الزاوية صحيحة (من الأمام)، لكن الخلفية فيها كشافات وتدرج واللوحات ملصوقة', BG),
        ('46.8', 'striker/walk', 'الزاوية خطأ (جانبية والمطلوب من الأمام)، والخلفية فيها كشافات', SIDE + ' He walks straight toward the camera, seen from the front, like the attached walk-front-01.png. ' + BG),
        ('46.9', 'striker/walk', 'الزاوية خطأ (جانبية)، وتكاد تطابق walk-front-02، وفيها 3 أشكال والمطلوب 2', SIDE + ' He walks straight toward the camera, seen from the front. Exactly 2 figures. ' + BG),
        ('46.10', 'striker/walk', 'الزاوية صحيحة (من الخلف)، لكن الخلفية فيها كشافات واللوحات ملصوقة', BG),
        ('46.11', 'striker/walk', 'الزاوية خطأ (جانبية والوجه ظاهر)، وفيها ركبة عالية', SIDE + ' He walks away from the camera, seen from behind, face hidden, like the attached walk-back-01.png. ' + BG),
        ('46.12', 'striker/walk', 'الزاوية خطأ (جانبية)، وفيها 3 أشكال والمطلوب 2', SIDE + ' He walks away from the camera, seen from behind, face hidden. Exactly 2 figures. ' + BG),
        ('46.13', 'striker/walk', 'يمشي للأمام لا للخلف، والخلفية فيها كشافات', BG + ' He moves BACKWARDS: he faces right but steps toward the left of the image, weight on the balls of his feet, the stepping foot reaching back behind him.'),
        ('46.14', 'striker/walk', 'نفس المشكلة: مشي للأمام، والخلفية فيها كشافات', BG + ' He moves BACKWARDS: he faces right but steps toward the left of the image, like the attached backpedal-01.png.'),
    ],
}


def entry(book, code):
    m = re.search(r'### (' + re.escape(code) + r') `([^`]+)`\n\n.*?\n(\*\*[^\n]*)\n\n```\n(.*?)\n```', book, re.S)
    return m.group(2), m.group(3), m.group(4).strip()


def run(r):
    book = open(os.path.join(ROOT, r['book'])).read()
    rows = [(k, folder, *entry(book, k), why, fix) for k, folder, why, fix in r['redo']]
    later = {k for x in REVIEWS[REVIEWS.index(r) + 1:] for k, *_ in x['redo']}   # a later review of the same board replaces this one
    rows = [row for row in rows if f'{row[1]}/{row[2]}' not in approved() and row[0] not in later]   # never list or remove an approved board
    o = []
    W = o.append
    W(f"# إعادة صور {r['title']} (مراجعة {r['date']})\n")
    W('> - **السليمة** باقية في مجلدها، وهي ✅ في `docs/sprints/sprint-02-days.md`.')
    W('> - **التي تحتاج إعادة** حُذفت من المجلد حتى تُصنع من جديد، وتبقى نسختها في تاريخ git.')
    W('> - **لكل صورة هنا:** المشكلة، والمرفقات، والأمر كاملاً من الكتاب وفي آخره **سطر التصحيح**. انسخ الأمر كما هو في محادثة جديدة، وارفق الملفات المذكورة.\n')
    W('## ما حدث للملفات\n')
    for n in r['notes']:
        W('- ' + n)
    W(f"\n## السليمة ({len(r['ok'])})\n")
    W('| اللوحة | الملف |')
    W('|---|---|')
    for k, f in r['ok']:
        W(f'| {k} | ✅ `art/raw/{f}` |')
    if r.get('chains'):
        W('\n## أمر واحد لكل حركة (الأسهل)\n')
        W('> **محادثة جديدة لكل حركة.** ارفق الملفات، والصق الأمر. يرسم Gemini الصور واحدة بعد الأخرى بنفس الشخص والمقياس. '
          'وإن رسم صورة واحدة فقط وتوقف، اكتب **next** فيرسم التالية في نفس المحادثة. احفظ كل صورة باسمها المكتوب في الأمر (IMAGE 1 = الاسم الأول).\n')
        for title, attach, prompt in r['chains']:
            W(f'### {title}\n')
            W('**ارفق:** ' + ' و'.join(f'`{a}`' for a in attach) + '\n')
            W('```')
            W(prompt)
            W('```\n')
        W('## أو صورة صورة\n')
        W('إن لم ينجح الأمر الواحد، كل صورة بأمرها تحت.')
    W(f"\n## تحتاج إعادة ({len(rows)})\n")
    W('**أكثر مشكلة تكررت:** ' + r['common'] + '\n')
    W('| اللوحة | الملف | المشكلة |')
    W('|---|---|---|')
    for k, folder, f, att, prompt, why, fix in rows:
        W(f'| {k} | `art/raw/{folder}/{f}` | {why} |')
    W('')
    for k, folder, f, att, prompt, why, fix in rows:
        W(f'### {k} `{f}`\n')
        W(f'**المشكلة:** {why}  ')
        W(f'**المجلد:** `art/raw/{folder}/`  ')
        if isinstance(fix, dict):            # a prompt written again from scratch, clearer than the book's
            W('**ارفق:** ' + ' و'.join(f'`{a}`' for a in fix['attach']) + '\n')
            W('```')
            W(fix['prompt'])
        else:
            W(att + '\n')
            W('```')
            W(prompt + ' ' + fix)
        W('```\n')
    out = os.path.join(ROOT, r['out'])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w').write('\n'.join(o) + '\n')
    removed = 0
    for k, folder, f, *_ in rows:
        p = os.path.join(ROOT, 'art', 'raw', folder, f)
        # only the rejected board: one uploaded again after the review stays
        if os.path.exists(p) and os.path.getmtime(p) < _dt.datetime.fromisoformat(r['date'] + 'T23:59:59').timestamp():
            os.remove(p)
            removed += 1
    print(f'{len(rows)} to redo, {removed} removed from art/raw -> {r["out"]}')


START = {
    'date': '2026-10-20', 'title': 'المهاجم: البداية والتوقف والدوران والوقوف (الدفعة 2)', 'book': 'docs/art/images/03-players.md',
    'out': 'docs/art/redo/2026-10-20-striker-start.md',
    'ok': [('47.1', 'striker/start/start-01.png'), ('47.8', 'striker/start/idle-02.png')],
    'notes': [
        '**هذا المجلد من الدفعة 2.** الأولوية للدفعة 1، لأن المحاكاة تُبنى بها. ما اعتُمد هنا يبقى، والباقي يُعاد بعد إنهاء الدفعة 1.',
        '**`turn-01.png.jpeg`:** اسمه خطأ (امتدادان)، ويُعاد على كل حال. احفظ الجديد باسم `turn-01.png`.',
        '**الصيغة:** الصور كلها JPEG باسم `.png`. الأداة تقرؤها، لكن الأفضل حفظها PNG فعلاً، لأن ضغط JPEG يترك حواف خضراء.',
    ],
    'common': 'ترتيب الحركة: كل لوحة تكمل ما قبلها كما يصفها الأمر إطاراً إطاراً، ولا تعود لوضعية سابقة.',
    'redo': [
        ('47.2', 'striker/start', 'الإطار 4 وقوف (يكرر الإطار 1 من start-01)، والمطلوب الخطوة الثانية فالثالثة فالجري الكامل', 'Frame 4 is NOT standing: it is the second running step, already moving. The three frames continue on from the last frame of the attached start-01.png and get faster; never go back to standing.'),
        ('47.3', 'striker/start', 'الإطاران 1 و2 شبه متطابقين، والإطار 1 ليس جرياً بأقصى سرعة، والإطار 3 وقوف', 'Frame 1 is a full-speed running stride, frame 2 leans back with the front foot planted, frame 3 a short braking step with the arms out: three clearly different poses, none of them standing still.'),
        ('47.4', 'striker/start', 'الإطار 4 خطوة جري (رجوع للخلف في الحركة)، والمطلوب: شبه متوقف بركبتين منثنيتين، ثم يستعيد توازنه، ثم يقف', 'Frame 4 is almost stopped with the knees bent (not a running stride); frame 5 standing, catching his balance; frame 6 standing ready. Continue from the last frame of the attached stop-01.png.'),
        ('47.5', 'striker/start', 'الترتيب معكوس: يبدأ من الأمام وينتهي جانبياً، والمطلوب العكس (جانبي، ثم ثلاثة أرباع، ثم من الأمام). واسم الملف خطأ', 'The order is: frame 1 side view facing right, frame 2 three-quarter view toward the camera, frame 3 facing the camera from the front. Save it as turn-01.png.'),
        ('47.6', 'striker/start', 'الزوايا خطأ: من الخلف وجانبي لليمين، والمطلوب: ثلاثة أرباع لليسار، ثم جانبي لليسار، ثم واقف لليسار', 'He keeps turning the same way from the front view of the attached turn-01.png: frame 4 three-quarter view facing LEFT, frame 5 side view facing LEFT, frame 6 standing still facing LEFT. Never show his back.'),
        ('47.7', 'striker/start', 'الخلفية فيها كشافات وتدرج أخضر فلا تُقص', BG),
    ],
}
LOOK_DOWN = 'He looks down at the ball that is not drawn, his head tilted forward.'
DIFFERENT = 'The three frames are three clearly different poses in the order described; none repeats a pose from this image or from the attached earlier image.'
BALL = {
    'date': '2026-10-20', 'title': 'المهاجم: الكرة', 'book': 'docs/art/images/03-players.md',
    'out': 'docs/art/redo/2026-10-20-striker-ball.md',
    'ok': [('48.6', 'striker/ball/shoot-03.png'), ('48.16', 'striker/ball/cross-01.png')],
    'notes': [
        '**سبب الكشافات في الخلفية:** في الأمر جملة الإضاءة («lit by night stadium floodlights»)، فيرسم Gemini الكشافات نفسها. سطر التصحيح يقول له: الضوء على اللاعب فقط، والكشافات لا تظهر.',
        '**أكثر خطأ بعده:** إطاران أو ثلاثة بنفس وضعية الجري. فلوحة التسديد تبدأ بخطوتي جري مكررتين بدل وضعيات التسديد.',
        '**الصيغة:** الصور JPEG باسم `.png`. احفظها PNG فعلاً.',
    ],
    'common': 'الخلفية فيها كشافات وتدرج، والوضعيات مكررة. لكل لوحة سطر تصحيح يذكر وضعية كل إطار.',
    'redo': [
        ('48.1', 'striker/ball', 'جري عادي بلا نظر للكرة، والإطاران 1 و2 شبه متطابقين', LOOK_DOWN + ' ' + DIFFERENT),
        ('48.2', 'striker/ball', 'الإطاران 4 و5 يكرران dribble-01، والإطار 6 مشي منتصب', LOOK_DOWN + ' Frame 4 has both feet off the ground. ' + DIFFERENT),
        ('48.3', 'striker/ball', 'الإطاران 7 و8 متطابقان تقريباً', LOOK_DOWN + ' Frame 7 and frame 8 are two different moments of the stride. ' + DIFFERENT),
        ('48.4', 'striker/ball', 'الإطاران 1 و2 متطابقان، واللوحة كلها تكاد تطابق pass-01', DIFFERENT + ' The third frame opens the arms wide for balance.'),
        ('48.5', 'striker/ball', 'بدل القدم المزروعة ثم الرجل المسحوبة ثم لحظة الضربة: خطوتا جري مكررتان ثم ركلة', 'Frame 4: the left foot planted, the right leg swung far back. Frame 5: the hips turning, the right leg swinging down. Frame 6: the right foot striking low through the ball. No running strides in this image. ' + DIFFERENT),
        ('48.7', 'striker/ball', 'الخلفية فيها كشافات، والإطاران 1 و2 متطابقان', BG + ' ' + DIFFERENT),
        ('48.8', 'striker/ball', 'الإطاران 4 و5 خطوتا جري، والمطلوب: متابعة قصيرة بالقدم نحو الهدف، ثم خطوة للأمام، ثم وقوف', 'Frame 4: a short follow-through, the foot pointing at the target. Frame 5: one step forward. Frame 6: standing, watching. ' + DIFFERENT),
        ('48.9', 'striker/ball', 'الخلفية فيها كشافات (الوضعيات صحيحة)', BG),
        ('48.10', 'striker/ball', 'الخلفية فيها كشافات', BG),
        ('48.11', 'striker/ball', 'لوحتان ملصوقتان، والخلفية فيها كشافات', BG),
        ('48.12', 'striker/ball', 'الخلفية فيها كشافات', BG),
        ('48.13', 'striker/ball', 'الإطارات تكرر بداية الضربة، والمطلوب: متابعة الرجل عبر الجسم، ثم الهبوط على القدم اليمنى، ثم الوقوف', 'Frame 4: the right leg swinging across in front of the body. Frame 5: landing on the right foot. Frame 6: standing, watching. ' + DIFFERENT),
        ('48.14', 'striker/ball', 'الخلفية فيها كشافات', BG),
        ('48.15', 'striker/ball', 'الخلفية فيها كشافات', BG),
        ('48.17', 'striker/ball', 'الإطاران 4 و5 جري مكرر، والمطلوب: لحظة لمس الكرة من تحتها، ثم المتابعة بذراعين مفتوحتين، ثم مراقبة العرضية', 'Frame 4: the right foot under the ball at contact, curling it. Frame 5: the follow-through, arms out. Frame 6: standing, watching the cross. ' + DIFFERENT),
        ('48.18', 'striker/ball', 'لوحات ملصوقة، والخلفية فيها كشافات', BG),
        ('48.19', 'striker/ball', 'ثلاث خطوات جري، والمطلوب: الكرة تموت عند قدمه (وقوف)، ثم يدفعها، ثم يبدأ الجري', 'Frame 4: standing over the ball that has stopped dead at his feet. Frame 5: pushing it forward with the right foot. Frame 6: the first running step. ' + DIFFERENT),
    ],
}
SCALE = ('Make it a wide 3:2 landscape image (like 1264x848), never square. Draw every figure as tall as in the attached '
         'run-side-01.png: from the top of the head to the soles about four fifths of the image height. Keep exactly the poses '
         'of your earlier square version, attached as the pose guide.')
DRIBBLE_SCALE = {
    'date': '2026-10-20', 'title': 'المهاجم: الدريبل بالمقياس الصحيح', 'book': 'docs/art/images/03-players.md',
    'out': 'docs/art/redo/2026-10-20-striker-dribble-scale.md',
    'ok': [],
    'notes': [
        '**الوضعيات صحيحة،** واعتُمدت أولاً. لكن اللوحتين مربعتان (1024x1024)، فرسم Gemini الأشكال أصغر: في اللعبة يصغر اللاعب حوالي 25% حين يبدأ الدريبل.',
        '**الإصلاح:** نفس الوضعيات في صورة عريضة 3:2 وبطول الجري. ارفق نسختك المربعة القديمة (عندك على جهازك، وفي تاريخ git) دليلاً للوضعيات، و`run-side-01.png` دليلاً للحجم.',
        '**أداة البناء** صارت تنبّه لأي لوحة ليست 3:2، وتوحّد دقة الصور (1024x687 و2528x1696 تُعامل مثل 1264x848).',
    ],
    'common': 'لوحة مربعة بدل 3:2، فالأشكال أصغر من باقي الحركات.',
    'redo': [
        ('48.1', 'striker/ball', 'مربعة 1:1، فالأشكال أصغر 25% من الجري (الوضعيات صحيحة)', SCALE + ' ' + LOOK_DOWN),
        ('48.2', 'striker/ball', 'مربعة 1:1، فالأشكال أصغر 25% من الجري (الوضعيات صحيحة)', SCALE + ' ' + LOOK_DOWN),
    ],
}
HEADER = ('Use the attached reference card: exactly the same man, same face, hair and body, same plain white kit '
          '(shirt, shorts, socks) and black boots, no logos or numbers. ')
LOOK = ('ONE wide 3:2 landscape image (not square, not separate panels) with exactly {n} figures of him in one row, '
        'left to right, all the same size, feet on the same ground line, each figure about four fifths of the image '
        'height, clear space between them, nothing cut off. '
        'Background: one flat solid chroma green (#00FF00) only: no floor, no shadows, no lights, no text. '
        'Photorealistic 3D render like a modern console football game. No ball. ')
SPRINT = ('He is sprinting in every figure: body leaning forward, both elbows bent at 90 degrees and pumping, '
          'never arms hanging down, never walking. Every figure is a different pose. ')


def clear(n, view, figures, rule=''):
    """A short prompt written from scratch: who, how the image looks, then one line per figure."""
    lines = [f'Figure {i}: {f}' for i, f in enumerate(figures, 1)]
    return HEADER + LOOK.format(n=n) + f'{view} ' + SPRINT + ' '.join(lines) + (' ' + rule if rule else '')


def chain(view, images):
    """One message that makes a whole motion, image after image: [(file, frames, figures, rule)]."""
    total = len(images)
    parts = [HEADER, f'Make {total} separate images, one after another, in this order: each one continues the same run '
             'from the last pose of the one before, with the same man, the same camera, the same size and the same ground line. ',
             'Every image: ' + LOOK.format(n='the given number of') + f'{view} ' + SPRINT]
    for i, (name, frames, figures, rule) in enumerate(images, 1):
        lines = ' '.join(f'Figure {j}: {f}' for j, f in enumerate(figures, 1))
        parts.append(f'IMAGE {i} of {total} ({name}, frames {frames}, exactly {len(figures)} figures): {lines}' + (f' {rule}' if rule else '') + ' ')
    parts.append(f'If you can only make one image per answer: make IMAGE 1 now, then stop; each time I write "next", make the next image, until IMAGE {total}.')
    return ''.join(parts)


Q_BACK = ('Camera: three-quarter view from behind. We see his back and the back of his head, his face is hidden, '
          'and he runs away from the camera diagonally to the right, with the same camera angle as the attached run-q-back-01.png. '
          'That image shows the EARLIER frames 1 to 3, which are already made: use it only for the angle and the size, and never '
          'redraw its poses. Every figure here is a NEW pose that comes after them.')
BACK = ('Camera: straight from behind. We see only his back and the back of his head, and he runs straight away '
        'from the camera. Because we see his back, his RIGHT leg is on the RIGHT side of the image and his LEFT leg '
        'is on the LEFT side.')
FRONT = ('Camera: straight from the front. He faces the camera and runs straight towards it. Because he faces us, '
         'his RIGHT leg is on the LEFT side of the image and his LEFT leg is on the RIGHT side.')
AIR = 'in the air: BOTH boots clearly off the ground, with a visible gap of green under each boot'
TOE_VS_AIR = 'The two figures must look clearly different: in the first one toe touches the ground, in the second nothing touches the ground.'
# The figures of each board, shared by its own prompt and by the one-message prompt for the whole motion.
QB2 = (['%s; the left knee driven forward, the right leg stretched out behind.' % AIR,
        'the left foot just landing on the ground in front of him, heel first; the right leg stretched behind; the right arm swinging forward.',
        'standing on the left foot, flat, right under his hips, knee slightly bent; the right foot off the ground, swinging forward low next to the left ankle.'],
       'Figures 2 and 3 must look clearly different: in figure 2 the feet are far apart, in figure 3 they are close together.')
QB3 = (['pushing off: only the toes of the left foot still touch the ground far behind him, the left leg almost straight; the right knee lifted high in front at hip height, the right foot off the ground.',
        '%s; the right knee driven forward, the left leg stretched out behind.' % AIR], TOE_VS_AIR)
F1 = (['his right foot (on the LEFT side of the image) landing on the ground in front of him; his left foot (on the RIGHT side of the image) lifted off the ground behind him; his left arm forward.',
       'his weight on his right foot (LEFT side of the image), flat under his body, knee slightly bent; his left foot (RIGHT side) off the ground, passing forward low next to the standing ankle.',
       'his right foot (LEFT side) pushing off on its toes; his left knee (RIGHT side) lifted high in front at hip height.'],
      'In all three figures he stands on the leg on the LEFT side of the image, and the foot on the RIGHT side of the image is off the ground.')
B1 = (['his right foot (RIGHT side of the image) landing on the ground; his left foot (LEFT side) kicked up behind him, the sole of the boot visible.',
       'his weight on his right foot (RIGHT side), flat under his body, knee slightly bent; his left foot (LEFT side) off the ground, swinging forward low.',
       'his right foot (RIGHT side) pushing off on its toes; his left knee (LEFT side) lifted high in front of him, so his left lower leg is partly hidden by his body.'],
      'In all three figures he stands on the leg on the RIGHT side of the image, and the foot on the LEFT side of the image is off the ground.')
B2 = (['%s; his left knee forward, his right foot (RIGHT side of the image) kicked up behind him, the sole of the boot visible.' % AIR,
       'his left foot (LEFT side of the image) landing on the ground; his right foot (RIGHT side) kicked up behind him, the sole visible.',
       'his weight on his left foot (LEFT side), flat under his body, knee slightly bent; his right foot (RIGHT side) off the ground, swinging forward low.'],
      'In figures 2 and 3 he stands on the leg on the LEFT side of the image, and the foot on the RIGHT side is off the ground.')
B3 = (['his left foot (LEFT side of the image) pushing off on its toes behind him; his right knee (RIGHT side) lifted high in front, so his right lower leg is partly hidden by his body.',
       '%s; his right knee forward, his left foot (LEFT side) kicked up behind him, the sole of the boot visible.' % AIR], TOE_VS_AIR)
REF = 'art/raw/striker/ref.png'
RUN = 'art/raw/striker/run/'
RUN_BACK = {
    'date': '2026-10-20', 'title': 'المهاجم: الجري ثلاثة أرباع من الخلف، ومن الأمام، ومن الخلف (الإعادة الأولى)', 'book': 'docs/art/images/03-players.md',
    'out': 'docs/art/redo/2026-10-20-striker-run-back.md',
    'ok': [('45.7', 'striker/run/run-q-back-01.png')],
    'notes': [
        '**تحسن واضح:** الزوايا كلها صحيحة الآن، والخلفية سادة، والأشباح اختفت. run-q-back-01 معتمدة.',
        '**المشكلة الجديدة في الأمام والخلف: الرجل الواقفة تتبدل كل إطار.** في الإطارات 1 و2 و3 يجب أن يقف على نفس الرجل (هبوط، ثم حمل، ثم دفع)، والإطار 4 والإطار 8 طيران. لو تبدلت كل إطار، يبدو في اللعبة كأنه يرتجف في مكانه. الأوامر الجديدة تحدد كل رجل بجهتها في الصورة، لأن Gemini يخلط اليمين واليسار من الخلف.',
        '**الأوامر مكتوبة من جديد** أقصر وأوضح: من هو، وشكل الصورة، ثم سطر لكل شكل.',
        '**الصيغة:** الصور كلها JPEG بدقة 1024x687. أداة البناء توحّد المقياس، لكن الأفضل تنزيل الصورة بحجمها الكامل وحفظها PNG.',
    ],
    'chains': [
        ('الجري ثلاثة أرباع من الخلف: run-q-back-02 ثم run-q-back-03', [REF, RUN + 'run-q-back-01.png'],
         chain(Q_BACK, [('run-q-back-02', '4 to 6', *QB2), ('run-q-back-03', '7 to 8', *QB3)])),
        ('الجري من الأمام: run-front-01 وحدها', [REF, RUN + 'run-front-02.png'],
         clear(3, FRONT + ' Match the size and style of the attached run-front-02.png.', *F1)),
        ('الجري من الخلف: run-back-01 ثم run-back-02 ثم run-back-03', [REF],
         chain(BACK, [('run-back-01', '1 to 3', *B1), ('run-back-02', '4 to 6', *B2), ('run-back-03', '7 to 8', *B3)])),
    ],
    'common': 'الرجل الواقفة تتبدل كل إطار بدل أن تبقى نفسها في الإطارات 1 إلى 3 و5 إلى 7، وإطارات الطيران على الأرض.',
    'redo': [
        ('45.8', 'striker/run', 'الإطاران 5 و6 بذراعين متدليتين فيبدوان مشياً، وهما شبه متطابقين',
         {'attach': [REF, RUN + 'run-q-back-01.png'], 'prompt': clear(3, Q_BACK, *QB2)}),
        ('45.9', 'striker/run', 'الإطار 8 ليس طيراناً ويكاد يكرر الإطار 7',
         {'attach': [REF, RUN + 'run-q-back-02.png'], 'prompt': clear(2, Q_BACK.replace('run-q-back-01.png', 'run-q-back-02.png').replace('frames 1 to 3', 'frames 4 to 6'), *QB3)}),
        ('45.10', 'striker/run', 'الإطار 2 يقف على الرجل اليسرى، والمطلوب نفس الرجل اليمنى في الإطارات الثلاثة (وإلا يرتجف)',
         {'attach': [REF, RUN + 'run-front-02.png'], 'prompt': clear(3, FRONT + ' Match the size and style of the attached run-front-02.png.', *F1)}),
        ('45.13', 'striker/run', 'الرجل الواقفة تتبدل كل إطار (يسرى، يمنى، يسرى)، والمطلوب اليمنى في الثلاثة',
         {'attach': [REF], 'prompt': clear(3, BACK, *B1)}),
        ('45.14', 'striker/run', 'الإطار 4 بقدمين على الأرض والمطلوب طيران، والإطاران 5 و6 على رجلين مختلفتين',
         {'attach': [REF, RUN + 'run-back-01.png'], 'prompt': clear(3, BACK + ' Continue the attached run-back-01.png at the same size.', *B2)}),
        ('45.15', 'striker/run', 'الإطاران 7 و8 متطابقان تقريباً، والإطار 8 ليس طيراناً',
         {'attach': [REF, RUN + 'run-back-02.png'], 'prompt': clear(2, BACK + ' Continue the attached run-back-02.png at the same size.', *B3)}),
    ],
}
REVIEWS = [RUN_WALK, START, BALL, DRIBBLE_SCALE, RUN_BACK]

# Boards approved before these reviews (wave 1), in docs/sprints/sprint-02-days.md.
APPROVED_BEFORE = ['stadiums/arena/night/' + n + '.jpg' for n in ('shot', 'run', 'wing', 'shot-far', 'goal-front', 'behind-goal', 'corner', 'box-high', 'bench', 'touchline', 'monitor', 'centre', 'tunnel-out', 'crowd-joy', 'crowd-tense', 'crowd-sad')] + ['striker/ref.png', 'striker/faces.png']


# Boards rejected in a review, made again and approved afterwards (path: day of approval).
# They leave their redo list, and a rerun never removes them.
REDONE_OK = {
    'striker/run/run-q-front-02.png': '2026-10-20',
    'striker/run/run-q-front-03.png': '2026-10-20',
}


def approved():
    """Every board that passed review, as paths under art/raw/."""
    return set(APPROVED_BEFORE) | set(REDONE_OK) | {path for r in REVIEWS for _, path in r['ok']}


def main():
    for r in REVIEWS:
        run(r)


if __name__ == '__main__':
    main()
