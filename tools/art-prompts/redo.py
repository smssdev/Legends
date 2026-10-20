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
      'chroma-key green (#00FF00) from edge to edge: no floodlights, no lamps, no gradient, no floor, no shadows.')
GHOST = 'Each figure is drawn once, fully solid: no faded, transparent or ghost copies of legs, arms or bodies anywhere, and nothing between the figures.'
SIDE = 'Do NOT show him in profile from the side.'
WALK = 'A calm walk: one foot always on the ground, no knee lifted high.'
JOG = 'A relaxed jog: low knees, short strides, the feet stay close to the ground; never a high-knee pose.'

REVIEW = {
    'date': '2026-10-20', 'title': 'المهاجم: الجري والمشي', 'book': 'docs/art/images/03-players.md', 'out': 'docs/art/redo/2026-10-20-striker-run-walk.md',
    'ok': [('45.1', 'run/run-side-01.png'), ('45.2', 'run/run-side-02.png'), ('45.3', 'run/run-side-03.png'),
           ('45.4', 'run/run-q-front-01.png'), ('45.11', 'run/run-front-02.png'), ('45.12', 'run/run-front-03.png')],
    'notes': [
        '**`run-side-01.png` و`run-side-02.png` و`run-side-03.png`:** كانت معتمدة، ثم استُبدلت بالخطأ في رفع 2026-10-20، وصار `run-side-01.png` البطاقة المرجعية. **أُرجعت النسخ المعتمدة.**',
        '**`run-q-front-01 (2).png`:** نسخة مكررة باسم خطأ، ومحتواها جانبي يطابق `run-side-03` الجديدة. **حُذفت**، والمعتمد `run-q-front-01.png` باقٍ.',
        '**قاعدة للرفع القادم:** لا تُرفع صورة فوق صورة معتمدة (✅). وكل صورة باسمها في `README.md` المجلد بالضبط.',
    ],
    'common': 'صور المشي كلها وصور الانطلاق صُنعت كثلاث لوحات ملصوقة، وخلفيتها خضراء متدرجة فيها كشافات، فلا تُقص. والمطلوب صورة واحدة عريضة بخلفية خضراء واحدة سادة (#00FF00). وأكثر من نصفها جاء بزاوية جانبية بدل المطلوبة.',
    'redo': [
        ('45.5', 'run', 'الزاوية خطأ: جانبية تماماً، والمطلوب ثلاثة أرباع من الأمام مثل run-q-front-01', SIDE + ' He is seen three-quarters from the front, exactly like the attached run-q-front-01.png: his chest and face turned about 45 degrees toward the camera.'),
        ('45.6', 'run', 'الزاوية خطأ: جانبية، والمطلوب ثلاثة أرباع من الأمام', SIDE + ' He is seen three-quarters from the front, exactly like the attached run-q-front-02.png: his chest and face turned about 45 degrees toward the camera.'),
        ('45.7', 'run', 'الزاوية خطأ: جانبية والوجه ظاهر، والمطلوب ثلاثة أرباع من الخلف (يظهر ظهره ومؤخرة رأسه)', SIDE + ' He is seen three-quarters from behind: we see his back and the back of his head, his face is hidden, running away from the camera diagonally to the right.'),
        ('45.8', 'run', 'نفس المشكلة: جانبية بدل ثلاثة أرباع من الخلف', SIDE + ' He is seen three-quarters from behind, exactly like the attached run-q-back-01.png: his back and the back of his head toward the camera, face hidden.'),
        ('45.9', 'run', 'نفس المشكلة: جانبية بدل ثلاثة أرباع من الخلف', SIDE + ' He is seen three-quarters from behind, exactly like the attached run-q-back-02.png: his back and the back of his head toward the camera, face hidden.'),
        ('45.10', 'run', 'الزاوية صحيحة، لكن فيها أرجل شفافة مكررة (أشباح) بين الأشكال', GHOST),
        ('45.13', 'run', 'الزاوية صحيحة، لكن فيها أرجل شفافة مكررة وقطع خضراء عند الأقدام', GHOST),
        ('45.14', 'run', 'الزاوية خطأ (جانبية والوجه ظاهر)، وفيها شكل شفاف في الوسط', SIDE + ' He is seen exactly from behind, like the attached run-back-01.png: his back to the camera, face hidden, running straight away from the camera. ' + GHOST),
        ('45.15', 'run', 'الزاوية خطأ (جانبية)، والخلفية فيها كشافات وتدرج، ودقتها نصف المطلوب', SIDE + ' He is seen exactly from behind, like the attached run-back-02.png: his back to the camera, face hidden. ' + BG),
        ('45.16', 'run', 'الخلفية فيها كشافات وتدرج أخضر (لا تُقص)، ودقتها نصف المطلوب، وشبه مطابقة لـ sprint-02', BG),
        ('45.17', 'run', 'نسخة شبه مطابقة من sprint-01، والخلفية فيها كشافات', BG + ' Each frame here continues from the last frame of the attached sprint-01.png; it must not repeat its poses.'),
        ('45.18', 'run', 'الزاوية خطأ (ثلاثة أرباع من الخلف بدل الجانب)، وفيها شكلان بدل ثلاثة، والخلفية فيها كشافات', 'He is seen exactly from the side, facing right, like the attached sprint-02.png. Exactly 3 figures. ' + BG),
        ('45.19', 'run', 'الخلفية فيها كشافات وتدرج أخضر، ودقتها نصف المطلوب', BG),
        ('46.1', 'walk', 'ثلاث لوحات ملصوقة بخطوط فاصلة، والخلفية فيها كشافات وتدرج، والإطار الثالث ركبة عالية لا هرولة', BG + ' ' + JOG),
        ('46.2', 'walk', 'نفس مشكلة الخلفية واللوحات، وتكاد تطابق jog-03', BG + ' Each frame continues from the attached jog-01.png and never repeats its poses. ' + JOG),
        ('46.3', 'walk', 'نفس مشكلة الخلفية واللوحات، وشبه مطابقة لـ jog-02 وwalk-03، وفيها 3 أشكال والمطلوب 2', BG + ' Exactly 2 figures. ' + JOG),
        ('46.4', 'walk', 'ثلاث لوحات ملصوقة، والخلفية فيها كشافات، والإطار الثالث ركبة عالية لا مشي', BG + ' ' + WALK),
        ('46.5', 'walk', 'نفس المشكلة، والإطار الأول ركبة عالية', BG + ' ' + WALK),
        ('46.6', 'walk', 'نفس المشكلة، وفيها 3 أشكال والمطلوب 2، وفيها ركبتان عاليتان', BG + ' Exactly 2 figures. ' + WALK),
        ('46.7', 'walk', 'الزاوية صحيحة (من الأمام)، لكن الخلفية فيها كشافات وتدرج واللوحات ملصوقة', BG),
        ('46.8', 'walk', 'الزاوية خطأ (جانبية والمطلوب من الأمام)، والخلفية فيها كشافات', SIDE + ' He walks straight toward the camera, seen from the front, like the attached walk-front-01.png. ' + BG),
        ('46.9', 'walk', 'الزاوية خطأ (جانبية)، وتكاد تطابق walk-front-02، وفيها 3 أشكال والمطلوب 2', SIDE + ' He walks straight toward the camera, seen from the front. Exactly 2 figures. ' + BG),
        ('46.10', 'walk', 'الزاوية صحيحة (من الخلف)، لكن الخلفية فيها كشافات واللوحات ملصوقة', BG),
        ('46.11', 'walk', 'الزاوية خطأ (جانبية والوجه ظاهر)، وفيها ركبة عالية', SIDE + ' He walks away from the camera, seen from behind, face hidden, like the attached walk-back-01.png. ' + BG),
        ('46.12', 'walk', 'الزاوية خطأ (جانبية)، وفيها 3 أشكال والمطلوب 2', SIDE + ' He walks away from the camera, seen from behind, face hidden. Exactly 2 figures. ' + BG),
        ('46.13', 'walk', 'يمشي للأمام لا للخلف، والخلفية فيها كشافات', BG + ' He moves BACKWARDS: he faces right but steps toward the left of the image, weight on the balls of his feet, the stepping foot reaching back behind him.'),
        ('46.14', 'walk', 'نفس المشكلة: مشي للأمام، والخلفية فيها كشافات', BG + ' He moves BACKWARDS: he faces right but steps toward the left of the image, like the attached backpedal-01.png.'),
    ],
}


def entry(book, code):
    m = re.search(r'### (' + re.escape(code) + r') `([^`]+)`\n\n.*?\n(\*\*[^\n]*)\n\n```\n(.*?)\n```', book, re.S)
    return m.group(2), m.group(3), m.group(4).strip()


def main(r=REVIEW):
    book = open(os.path.join(ROOT, r['book'])).read()
    rows = [(k, folder, *entry(book, k), why, fix) for k, folder, why, fix in r['redo']]
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
        W(f'| {k} | ✅ `art/raw/striker/{f}` |')
    W(f"\n## تحتاج إعادة ({len(rows)})\n")
    W('**أكثر مشكلة تكررت:** ' + r['common'] + '\n')
    W('| اللوحة | الملف | المشكلة |')
    W('|---|---|---|')
    for k, folder, f, att, prompt, why, fix in rows:
        W(f'| {k} | `art/raw/striker/{folder}/{f}` | {why} |')
    W('')
    for k, folder, f, att, prompt, why, fix in rows:
        W(f'### {k} `{f}`\n')
        W(f'**المشكلة:** {why}  ')
        W(f'**المجلد:** `art/raw/striker/{folder}/`  ')
        W(att + '\n')
        W('```')
        W(prompt + ' ' + fix)
        W('```\n')
    out = os.path.join(ROOT, r['out'])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w').write('\n'.join(o) + '\n')
    removed = 0
    for k, folder, f, *_ in rows:
        p = os.path.join(ROOT, 'art', 'raw', 'striker', folder, f)
        # only the rejected board: one uploaded again after the review stays
        if os.path.exists(p) and os.path.getmtime(p) < _dt.datetime.fromisoformat(r['date'] + 'T23:59:59').timestamp():
            os.remove(p)
            removed += 1
    print(f'{len(rows)} to redo, {removed} removed from art/raw -> {r["out"]}')


if __name__ == '__main__':
    main()
