# Legends image production book: every group stands alone (its own ChatGPT chat).
CAM = ('TV broadcast camera at pitch level, about 1 metre above the grass, 35mm lens, level horizon: '
       'the bottom edge of the advertising boards sits at 55% of the image height from the top.')
ANAT = ('Anatomy must be correct and natural in every pose: real human joints, knees and elbows bend only the natural way, '
        'both legs and both arms complete and in natural positions, feet pointing the way the body moves, five fingers on each hand, '
        'no twisted, broken-looking or extra limbs, balanced weight like a real athlete.')
LIGHT = ('Lit exactly like a night match under stadium floodlights: cool bluish white light from high above and slightly behind, '
         'a bright rim light on the head, shoulders and arms, soft shading, the lower legs a little darker, no studio light, no warm light. '
         'Seen by a TV broadcast camera at pitch level about 1 metre high with a 35mm lens, so we look very slightly up at the person.')
REN = 'Photorealistic 3D sports game character render, like a modern console football game, realistic adult proportions and face, high quality.'
SHEET = ('Character sprite sheet for a game, one image, landscape 1536x1024, solid flat pure green background (chroma key green #00FF00) filling the whole image, no gradient, no checkerboard, no floor. {who_kind} in {n} poses arranged in a grid of '
         '{c} columns and {r} rows, left to right then top to bottom. Every figure full body (head to boots fully visible), all at the same scale, '
         'the feet of standing poses all on the same level, evenly spaced with clear empty space between cells, nothing overlapping or cut off between cells. '
         'No text, no labels, no numbers, no logos, no ball, no ground, no grass, no shadows. Side view facing right unless a pose says otherwise.')
HALF = ('Character sheet for a game, one image, landscape 1536x1024, solid flat pure green background (chroma key green #00FF00) filling the whole image, no gradient, no checkerboard, no floor. The SAME fictional person, not a real person, '
        'in {n} half-body close-ups (from the waist up, front view facing the camera), arranged in a grid of {c} columns and {r} rows, all the same size, '
        'clear empty space between them. No text, no labels, no numbers, no logos.')
FACES = ('Portrait sheet for a game, one image, landscape 1536x1024. The SAME fictional person, not a real person, in {n} close-up portraits '
         '(head and shoulders, three-quarter view facing right), arranged in a grid of {c} columns and {r} rows, every portrait the same size, '
         'each with a blurred night stadium and floodlights behind, separated by thin black gaps. No text, no labels, no numbers, no logos.')
OBJ = ('Asset sheet for a game, one image, landscape 1536x1024, {bg}. Photorealistic render, lit like a night match under floodlights: '
       'cool white light from above. {n} separate items arranged in a grid of {c} columns and {r} rows, left to right then top to bottom, '
       'each centred in its cell with clear empty space around it, nothing overlapping or cut off. No text, no labels, no numbers, no logos.')
WHITE = 'Pure white is required, not coloured: the game paints the team colours on it.'
KIT = f'Kit: plain pure white shirt, white shorts, white socks, black boots. {WHITE}'
GK = f'Goalkeeper kit: plain pure white long-sleeve shirt, white shorts, white socks, black boots, big black goalkeeper gloves. {WHITE}'
BIB = f'Substitute: plain pure white training top and shorts with a plain white bib over it, white socks, black boots. {WHITE}'
REF = 'Referee kit: all-black shirt and shorts, black socks, black boots, whistle on a cord around the neck.'
grid = {1: (1, 1), 2: (2, 1), 3: (3, 1), 4: (2, 2), 5: (3, 2), 6: (3, 2)}
def lines(items): return ' '.join(f'{i+1}) {x}' for i, (_, x) in enumerate(items))
def head(first, word='person'): return '' if first else f'Same {word} as before.'

def char(first, who, poses, kind='The SAME fictional person, not a real person,'):
    c, r = grid[len(poses)]
    return ' '.join(x for x in [head(first), REN, ANAT, SHEET.format(who_kind=kind, n=len(poses), c=c, r=r), LIGHT, who, 'Poses:', lines(poses)] if x)
def duo(first, who, poses):
    c, r = grid[len(poses)]
    kind = 'Fictional people, not real people. Each cell shows a small group (described per cell) together, interacting naturally,'
    return ' '.join(x for x in [head(first, 'style'), REN, ANAT, SHEET.format(who_kind=kind, n=len(poses), c=c, r=r).replace('Side view facing right unless a pose says otherwise.', 'Side view unless a cell says otherwise.'), LIGHT, who, 'Cells:', lines(poses)] if x)
def half(first, who, poses):
    c, r = grid[len(poses)]
    return ' '.join(x for x in [head(first), REN, ANAT, HALF.format(n=len(poses), c=c, r=r), LIGHT, who, 'Close-ups:', lines(poses)] if x)
def faces(who, poses):
    c, r = grid[len(poses)]
    return ' '.join(x for x in ['Same person as before.', REN, FACES.format(n=len(poses), c=c, r=r), LIGHT, who.replace(' ' + WHITE, ''), 'Portraits:', lines(poses)] if x)
GREEN = 'solid flat pure green background (chroma key green #00FF00) filling the whole image, no gradient, no checkerboard, no floor'
MAG = 'solid flat pure magenta background (#FF00FF) filling the whole image, no gradient, no checkerboard'
def obj(first, what, items, bg=GREEN):
    c, r = grid[len(items)]
    return ' '.join(x for x in [head(first, 'style'), OBJ.format(bg=bg, n=len(items), c=c, r=r), what, 'Items:', lines(items)] if x)

# ---------------- stadiums ----------------
VIEWS = {
 'shot': ('الكاميرا الرئيسية: التسديدة والحارس والهدف', 'L02 L03 L04 L08 L16 L20 L21',
  'Side view along the edge of the penalty area. The whole goal in the right third of the image, seen from the side and slightly from the front so the goal mouth faces left towards the camera: both posts, the crossbar and the full net clearly visible, the goal line running from the near post towards the camera. The left two thirds: empty, well lit grass of the penalty area for the players, the penalty spot visible.'),
 'run': ('الجري والمراوغة والضغط في وسط الملعب', 'L02 L03 L06 L07 L11',
  'Side view of the middle of the pitch, the halfway line and part of the centre circle visible, no goal. Wide empty grass across the whole image for players running.'),
 'wing': ('الجناح على خط التماس والعرضية', 'L02 L03 L05',
  'Side view along the touchline near the corner of the penalty area: the white touchline running across the foreground, the edge of the penalty area and the goal small in the far right, the advertising boards close behind.'),
 'shot-far': ('التسديدة البعيدة والضربة الحرة', 'L08 L16',
  'Side view from further back: the penalty area and the goal in the right quarter of the image, smaller and further away, the whole goal visible. Lots of empty grass on the left.'),
 'goal-front': ('الحارس من الأمام، والضربة الحرة بالحائط', 'L08 L09',
  'View from just behind the penalty spot straight at the goal: the goal in the centre, filling the middle third of the image, the net and the crowd behind it, the penalty spot in the foreground.'),
 'behind-goal': ('ركلة الجزاء من خلف الشبكة، وإعادة الهدف', 'L03 L09 L22',
  'View from behind the goal at the height of a person: the back of the net in the foreground slightly out of focus, through it the goal mouth, the penalty spot in the middle of the image and the pitch beyond.'),
 'corner': ('الركنية والاحتفال عند الراية', 'L03 L10',
  'Corner flag area close up, the advertising boards and the front rows of the crowd right behind it, empty grass in front.'),
 'box-high': ('المنطقة من فوق قليلاً: الركنية والتسلل', 'L05 L10',
  'Slightly raised camera on the side of the penalty area looking across the whole box and the goal, the six-yard box and penalty spot clearly visible, empty pitch.'),
 'bench': ('المدرب والبدلاء والتبديل', 'L02 L03 L12',
  'The touchline technical area: the coaches box marked on the grass and the team bench with empty seats behind it, no people.'),
 'touchline': ('الحكم الرابع ودخول البديل', 'L12 L13 L14',
  'The halfway line meeting the touchline seen from the side, the fourth official area and the bench far behind, empty.'),
 'monitor': ('شاشة الفار', 'L17 L19',
  'The pitchside video review area next to the touchline: an empty review monitor on a stand under a small canopy, the pitch behind.'),
 'centre': ('البداية والاستراحة والنهاية', 'L15',
  'The centre circle and the centre spot seen from the side at pitch level, the stands behind, empty pitch.'),
 'tunnel-out': ('خروج اللاعبين من النفق', 'L15',
  'The players tunnel exit at pitch level, the tunnel opening and the stands around it, the pitch in front, no people.'),
}
CROWD = [
 ('crowd-joy.jpg', 'الجمهور يحتفل بالهدف', 'L03 L08 L09', 'Close-up of the home crowd in the stands celebrating a goal, scarves raised, arms up, some red flares, faces slightly blurred, generic colors.'),
 ('crowd-tense.jpg', 'ترقب قبل ركلة جزاء أو ضربة حرة', 'L08 L09', 'Close-up of the crowd in the stands, fans biting nails and holding their heads in tension, faces slightly blurred, generic colors.'),
 ('crowd-sad.jpg', 'تحسر بعد فرصة أو هدف ملغى', 'L02 L16 L17', 'Close-up of the crowd in the stands, disappointed fans with heads down and hands on heads, faces slightly blurred, generic colors.'),
]
def stadium(name, desc, cond, keys, crowd=True, extras=()):
    items = []
    for i, k in enumerate(keys):
        why, used, view = VIEWS[k]
        p = (('' if i == 0 else 'Same stadium, same camera height, same lens and same light as before. ') +
             f'Photorealistic football stadium: {desc}, {cond}, full crowd blurred in the stands, cinematic, landscape 1536x1024, '
             f'no players, no people on the pitch, no ball, no logos, no text. {CAM} {view}')
        items.append(('plate', f'{k}.jpg', why, used, p))
    if crowd:
        for f, why, used, view in CROWD:
            items.append(('plate', f, why, used, f'Same stadium and same light as before. Photorealistic, cinematic, landscape 1536x1024, no logos, no text. {view}'))
    for f, why, used, view in extras:
        items.append(('plate', f, why, used, f'Same stadium as before. Photorealistic, cinematic, landscape 1536x1024, no logos, no text. {view}'))
    return items

ARENA = 'a huge modern bowl stadium with a steel roof ring and LED advertising boards'
CLASSIC = 'an old classic European stadium with steep stands close to the pitch, brick and steel, a traditional roof'
GULF = 'a modern Gulf-style stadium with a white sculpted roof inspired by Arabic geometric patterns, palm trees outside'
LOCAL = 'a small local stadium with a single covered main stand, open terraces and floodlight towers on the corners'
NIGHT = 'at night under floodlights'
ALL = ['shot', 'run', 'wing', 'shot-far', 'goal-front', 'behind-goal', 'corner', 'box-high', 'bench', 'touchline', 'monitor', 'centre', 'tunnel-out']
CORE = ['shot', 'run', 'wing', 'goal-front', 'behind-goal', 'corner', 'bench', 'centre']
G = []
G.append(dict(t='الملعب 1: الأرينا ليلاً (الملعب الأساسي)', f='art/raw/v3/stadium-arena-night/', note='الملعب الذي تبدأ به اللعبة، فيه كل زوايا الكاميرا.',
 items=stadium('arena', ARENA, NIGHT, ALL, extras=[
  ('aerial.jpg', 'الملعب من الجو قبل المباراة', 'L15', 'Aerial view of the whole stadium at night, floodlights on, the lit pitch, city lights around.'),
  ('tunnel.jpg', 'داخل النفق', 'L15', 'Inside the players tunnel looking out to the bright pitch and the crowd, no people.'),
  ('dressing-room.jpg', 'غرفة الملابس للاستراحة', 'L15', 'The dressing room: benches, hanging plain white shirts without numbers, a blank tactics board, no people.'),
 ])))
G.append(dict(t='الملعب 2: الأرينا تحت المطر', f='art/raw/v3/stadium-arena-rain/', note='نفس الأرينا في ليلة ممطرة: عشب لامع وخيوط مطر في ضوء الكشافات.',
 items=stadium('arena', ARENA, 'at night in heavy rain, wet shiny grass with puddle reflections, rain streaks in the floodlight beams', CORE, crowd=False)))
G.append(dict(t='الملعب 3: الملعب الكلاسيكي نهاراً', f='art/raw/v3/stadium-classic-day/', note='ملعب أوروبي قديم في عصر مشمس.',
 items=stadium('classic', CLASSIC, 'on a bright sunny afternoon, clear blue sky, sharp shadows of the stands on the grass', CORE)))
G.append(dict(t='الملعب 4: ملعب الخليج عند الغروب', f='art/raw/v3/stadium-gulf-dusk/', note='ملعب عربي حديث وقت الغروب الذهبي.',
 items=stadium('gulf', GULF, 'at golden hour sunset, warm orange sky, floodlights just switched on', CORE)))
G.append(dict(t='الملعب 5: الملعب المحلي ليلاً', f='art/raw/v3/stadium-local-night/', note='ملعب صغير لأندية الدرجات الأدنى والدوريات الخاصة.',
 items=stadium('local', LOCAL, NIGHT, CORE, crowd=False)))
G.append(dict(t='الملعب 6: الملعب الكلاسيكي تحت الثلج (اختياري)', f='art/raw/v3/stadium-classic-snow/', note='للمباريات الشتوية.',
 items=stadium('classic', CLASSIC, 'on a snowy winter evening under floodlights, snow falling, white snow at the pitch edges, green playing surface cleared', ['shot', 'run', 'goal-front', 'behind-goal', 'corner'], crowd=False)))

# ---------------- characters ----------------
RUN4 = [('run-1','Running, right foot landing on the ground in front, left leg behind.'),('run-2','Running, right foot under the body, left knee lifted high.'),('run-3','Running, left foot landing on the ground in front, right leg behind.'),('run-4','Running, left foot under the body, right knee lifted high.')]
SPRINT4 = [('sprint-1','Full sprint, body leaning forward, right foot striking the ground, arms pumping hard.'),('sprint-2','Full sprint, airborne between strides, left knee driving high.'),('sprint-3','Full sprint, left foot striking the ground, arms pumping hard.'),('sprint-4','Full sprint, airborne between strides, right knee driving high.')]
LINEUP = [('lineup','Front view facing the camera: standing straight in the pre-match line-up, hands behind his back, calm.'),('walk-front','Front view facing the camera: walking towards the camera.')]
def person(t, folder, note, who, sheets, face=None, halfs=None):
    items = []
    k = 0
    for f, poses in sheets:
        parts = [poses[i:i + 3] for i in range(0, len(poses), 3)]
        for pi, part in enumerate(parts):
            name = f if len(parts) == 1 else f.replace('.png', f'-{"abc"[pi]}.png')
            items.append(('char', name, part, char(k == 0, who, part))); k += 1
    for f, poses in (halfs or []):
        items.append(('char', f, poses, half(False, who, poses)))
    if face:
        items.append(('char', 'faces.png', face, faces(who, face)))
    G.append(dict(t=t, f=folder, note=note, items=items))

A = 'Short dark brown hair, light olive skin, light stubble, athletic striker build.'
person('المهاجم الرئيسي', 'art/raw/v3/striker/', 'صاحب أغلب اللقطات: الأهداف والفرص والركلات.', f'{KIT} {A}', [
 ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + [('jog','Jogging lightly, relaxed.')]),
 ('sheet-sprint.png', SPRINT4 + [('dribble-1','Dribbling at speed: looking down, right foot reaching forward low to touch an invisible ball.'),('dribble-2','Dribbling at speed: left foot planted, right foot pulling back to keep an invisible ball close.')]),
 ('sheet-shoot.png', [('shoot-1','Preparing to shoot: left foot planted, right kicking leg swung far back, arms out for balance.'),('shoot-2','Moment of the strike: right foot swinging through low in front of the planted foot, body leaning over.'),('shoot-3','Shot follow-through: right leg extended high forward, body leaning back slightly.'),('volley','Volley in the air: right leg striking at hip height, body leaning back, arms out.'),('chip','Chipping the ball: short stabbing kick under an invisible ball, body upright.'),('pass','Passing with the inside of the right foot, short swing.')]),
 ('sheet-head.png', [('header-1','Taking off to jump for a header, knees bent, arms swinging up.'),('header-2','In the air at the top of the jump, head thrust forward, arms out.'),('diving-header','Diving header: body flying horizontally forward low above the grass, head first, arms back.'),('land','Landing on both feet after a jump, knees bent to absorb it.')]),
 ('sheet-react.png', [('celebrate-run','Running in celebration, arms wide open, shouting with joy.'),('knee-slide','Knee slide celebration on the grass, arms raised, leaning back.'),('fist-pump','Standing fist pump, roaring.'),('point-sky','Standing, both index fingers pointing to the sky, eyes up.'),('sad','Kneeling, both hands on his head, devastated.'),('hands-head','Standing, both hands on top of his head in disbelief.')]),
 ('sheet-ground.png', [('fall-1','Tripped, stumbling forward, losing balance, arms forward.'),('fall-2','Lying face down on the grass after a fall, arms out.'),('hurt','Lying on his side on the grass holding his knee in pain.'),('sit-sad','Sitting on the grass, arms on his knees, head down, disappointed.'),('get-up','Getting up from the grass, one knee down, hand pushing off.'),('argue','Standing, protesting with both arms open, angry face.')]),
 ('sheet-penalty.png', [('pk-back-stand','Back view, seen from behind: standing still behind the ball spot before a penalty, hands on hips.'),('pk-back-run','Back view, seen from behind: short run-up step towards the penalty spot.'),('pk-back-shoot','Back view, seen from behind: striking a penalty with the right foot.'),('pk-front-stand','Front view facing the camera: standing still before a penalty, staring ahead, focused.'),('pk-front-run','Front view facing the camera: running up to take a penalty.'),('pk-front-shoot','Front view facing the camera: striking a penalty with the right foot.')]),
 ('sheet-set.png', [('fk-stand','Standing a few steps behind an invisible ball before a free kick, hands on hips, focused.'),('fk-shoot','Free kick strike: right foot curling through, body leaning to the left.'),('throw-in','Taking a throw-in: both hands holding above and behind his head, feet on the ground.'),('corner','Taking a corner kick: kicking leg swinging, arms out.')] + LINEUP),
 ('sheet-walk.png', [('walk','Walking calmly.'),('walk-off','Walking off the pitch slowly, head down, disappointed.'),('clap-fans','Front view facing the camera: walking and clapping his hands above his head towards the fans.'),('handshake','Reaching out his right hand for a handshake.'),('point','Pointing forward, calling for the ball.'),('wave-off','Waving one hand, dismissing a decision, annoyed.')]),
], face=[('face-focus','Focused, eyes on the target, calm before a shot.'),('face-joy','Screaming with joy after scoring.'),('face-sad','Hands on his head, devastated after a miss.'),('face-angry','Angry, protesting a decision.'),('face-tired','Tired, sweating, breathing hard.'),('face-smile','Smiling, relaxed, in the pre-match line-up.')])

W_ = 'Short blond hair, light skin, clean shaven, slim fast winger build.'
person('الجناح', 'art/raw/v3/winger/', 'الجناح السريع: المراوغة على الخط والعرضيات والتمريرة الحاسمة.', f'{KIT} {W_}', [
 ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + [('jog','Jogging lightly, relaxed.')]),
 ('sheet-skill.png', SPRINT4[:2] + [('step-over','Step-over trick: right leg circling over an invisible ball, body feinting left.'),('cut-inside','Cutting inside sharply, planting the left foot, body turning.'),('cross','Crossing: right foot swinging across the body, leaning back, arms out.'),('through-ball','Through pass: short sharp pass with the inside of the right foot, looking up.')]),
 ('sheet-react.png', [('celebrate-run','Running in celebration, arms wide open.'),('jump-joy','Jumping high with joy, both fists up.'),('sad','Both hands on his head, disappointed.'),('fall','Falling forward after a tackle, arms out.'),('shoot','Striking the ball hard with the right foot, follow-through.')] + LINEUP[:1]),
], face=[('face-focus','Focused, ready to run.'),('face-joy','Shouting with joy.'),('face-sad','Disappointed.'),('face-smile','Smiling in the line-up.')])

M_ = 'Long dark curly hair tied back, medium brown skin, short beard, strong midfielder build.'
person('لاعب الوسط', 'art/raw/v3/midfielder/', 'يمرر ويقطع ويضغط: بداية الهجمات والمرتدات.', f'{KIT} {M_}', [
 ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + [('jog','Jogging lightly, relaxed.')]),
 ('sheet-play.png', [('long-pass','Long pass: right foot striking under an invisible ball, leaning back, arms out.'),('short-pass','Short pass with the inside of the right foot.'),('tackle-stand','Standing tackle: stretching his right leg to poke an invisible ball away.'),('intercept','Intercepting: stretching to block a pass with his left foot.'),('press','Pressing: running at an opponent, arms out, low and aggressive.'),('shoot','Striking the ball hard from distance, follow-through.')]),
 ('sheet-react.png', [('celebrate-run','Running in celebration, arms wide open.'),('hug-open','Arms open wide, about to hug a team-mate.'),('sad','Both hands on his head, disappointed.'),('argue','Protesting to the referee, both arms open.')] + LINEUP),
], face=[('face-focus','Focused.'),('face-joy','Shouting with joy.'),('face-angry','Angry at the referee.'),('face-smile','Smiling in the line-up.')])

D_ = 'Darker skin, short curly black hair, short beard, tall strong centre-back build.'
person('المدافع', 'art/raw/v3/defender/', 'قلب الدفاع: التزحلق والصد والرأسيات والحائط والهدف العكسي.', f'{KIT} {D_}', [
 ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + [('backpedal','Back-pedalling, facing right, moving backwards, arms out for balance.')]),
 ('sheet-defend.png', [('tackle-1','Starting a sliding tackle, dropping to the grass, leading leg reaching forward.'),('tackle-2','Mid sliding tackle, sliding on his side on the grass, leg fully extended.'),('block','Throwing his body to block a shot, one leg stretched out, arms behind his back.'),('jockey','Side-on defensive stance, knees bent, arms out, watching the attacker.'),('shoulder','Shoulder-to-shoulder challenge, leaning into an invisible opponent.'),('clear-line','Clearing the ball off the goal line with a desperate stretched right leg.')]),
 ('sheet-head.png', [('header-1','Taking off to jump for a header, knees bent, arms swinging up.'),('header-2','In the air at the top of the jump, heading the ball away powerfully, arms out.'),('wall','Front view facing the camera: standing in a free kick wall, hands crossed in front of his body.'),('wall-jump','Front view facing the camera: jumping in the free kick wall, hands crossed in front of his body.')]),
 ('sheet-react.png', [('own-goal','Lying on his back on the grass, hands over his face, after scoring an own goal.'),('sad','Both hands on his head, disappointed.'),('argue','Protesting to the referee, both arms open.'),('fall-back','Falling backwards after a challenge.'),('celebrate-run','Running in celebration, arms wide open.')] + LINEUP[:1]),
], face=[('face-focus','Focused.'),('face-angry','Angry, shouting.'),('face-sad','Devastated after an own goal.'),('face-smile','Smiling in the line-up.')])

K_ = 'Short black hair, tanned skin, clean shaven, tall goalkeeper build.'
person('حارس المرمى', 'art/raw/v3/keeper/', 'كل ما يفعله الحارس: الارتماء والإمساك والإبعاد وركلات الجزاء من الأمام والخلف.', f'{GK} {K_}', [
 ('sheet-dive.png', [('ready','Ready stance on his line, knees bent, arms out, hands open.'),('set','Low set position just before the shot, weight forward, hands low.'),('dive-1','Pushing off to dive upwards and forwards, body starting to lean, one leg driving.'),('dive-2','Full-stretch dive in the air, body horizontal, both arms reaching forward, hands open.'),('dive-3','Falling to the grass after the dive, one shoulder reaching the ground first.'),('beaten','Lying on the grass after conceding, propped on one arm, looking back in frustration.')]),
 ('sheet-hands.png', [('catch-high','Jumping to catch high: both hands above his head, gloves shaped to hold a ball.'),('catch-chest','Catching at his chest, gloves wrapped around an invisible ball.'),('punch','Jumping and punching forward with one fist.'),('tip-over','Leaping backwards, fingertips pushing an invisible ball over the bar.'),('dive-low','Low dive along the ground, body stretched, both hands reaching.'),('save-land','Lying on the grass after a save, both gloves holding an invisible ball against his chest.')]),
 ('sheet-play.png', [('kick','Goal kick: kicking leg extended forward.'),('throw','Throwing the ball out overarm, arm high.'),('roll','Rolling the ball out underarm, crouching.'),('point','Pointing forward, organising his defence, shouting.'),('celebrate','Celebrating a save: standing on both feet, legs straight and natural, both fists clenched, roaring.'),('get-up','Getting up from the grass after a dive.')]),
 ('sheet-front.png', [('front-ready','Front view facing the camera: on the goal line, ready stance, arms wide.'),('front-dive-left','Front view facing the camera: diving to his left, body horizontal in the air, arms reaching.'),('front-dive-right','Front view facing the camera: diving to his right, body horizontal in the air, arms reaching.'),('front-catch','Front view facing the camera: catching at his chest, gloves together.'),('front-beaten','Front view facing the camera: on his knees after conceding, head down.'),('front-celebrate','Front view facing the camera: celebrating a penalty save, arms wide, roaring.')]),
 ('sheet-back.png', [('back-ready','Back view, seen from behind: on the goal line, ready stance, arms wide.'),('back-dive-left','Back view, seen from behind: diving to his left, body horizontal in the air.'),('back-dive-right','Back view, seen from behind: diving to his right, body horizontal in the air.'),('back-beaten','Back view, seen from behind: lying on the grass after conceding.')]),
], face=[('face-focus','Focused, crouched, waiting for a penalty.'),('face-joy','Roaring after a big save.'),('face-beaten','Disappointed after conceding.'),('face-shout','Shouting instructions to his defenders.')])

R_ = f'{REF} Bald head, short dark beard, fit build.'
person('حكم الساحة', 'art/raw/v3/referee/', 'الصافرة والبطاقات وركلة الجزاء والفار.', R_, [
 ('sheet-1.png', [('stand','Standing.'),('run-1','Running, right foot landing in front.'),('run-2','Running, left foot landing in front.'),('whistle','Blowing the whistle, one arm raised.'),('point-spot','Pointing firmly to the penalty spot with the right arm.'),('advantage','Both arms stretched forward, signalling advantage.')]),
 ('sheet-2.png', [('card-side','Raising one arm straight up high, hand holding a plain white card.'),('calm','Both palms down, calming the players.'),('ear','Hand on his earpiece, listening, the other arm stopping play.'),('var-sign','Drawing a rectangle in the air with both index fingers, the video review sign.'),('monitor','Bending forward slightly, watching a screen in front of him, hands on hips.'),('end','Both arms raised, blowing the final whistle.')]),
], halfs=[('sheet-close.png', [('close-card','Raising a plain white card high with the right hand, stern face.'),('close-whistle','Blowing the whistle hard.'),('close-point','Pointing firmly to the side with the right arm.'),('close-ear','Hand on his earpiece, listening, serious.')])])

L_ = 'Assistant referee: all-black shirt and shorts, black socks, black boots, holding a red and yellow flag. Short grey hair, fit build.'
person('الحكم المساعد', 'art/raw/v3/linesman/', 'الراية والتسلل.', L_, [
 ('sheet-1.png', [('stand','Standing on the line, flag down.'),('run-side-1','Running sideways along the line, flag down.'),('run-side-2','Running sideways along the line, the other leg leading.'),('flag-up','Raising the flag straight up, standing still.'),('offside','Flag held straight out forward at shoulder height, signalling offside.'),('flag-wave','Waving the flag above his head, signalling a foul.')]),
])

F_ = 'Fourth official: black referee jacket, black trousers, black shoes. Short brown hair, glasses, older.'
person('الحكم الرابع', 'art/raw/v3/fourth/', 'لوحة التبديل والوقت الإضافي. شاشة اللوحة فارغة، والأرقام تكتبها اللعبة.', F_, [
 ('sheet-1.png', [('board-up','Front view facing the camera: holding up a blank glowing digital board above his head with both hands, the screen dark and empty.'),('board-side','Side view: holding up the blank digital board above his head.'),('stand','Standing on the touchline, hands behind his back.'),('talk','Talking to a coach, one hand raised calmly.')]),
], halfs=[('sheet-close.png', [('close-board','Holding the blank glowing digital board up high, the screen dark and empty, filling the lower half of the frame.'),('close-talk','Talking, one hand raised calmly.')])])

MED = 'Medical staff: plain dark blue tracksuit with a plain white cross patch, black trainers. Fictional people.'
G.append(dict(t='الطاقم الطبي', f='art/raw/v3/medics/', note='لقطة الإصابة.', items=[
 ('char', 'sheet-1.png', [('run-bag','One medic running with a medical bag.'),('kneel-treat','One medic kneeling, treating the leg of an invisible lying player.'),('stretcher-carry','Two medics carrying an empty stretcher between them.'),('signal','One medic standing, crossing his arms above his head, signalling a substitution is needed.')],
  duo(True, MED, [('run-bag','One medic running with a medical bag.'),('kneel-treat','One medic kneeling, treating the leg of an invisible lying player.'),('stretcher-carry','Two medics carrying an empty stretcher between them, side view.'),('signal','One medic standing, crossing his arms above his head, signalling a substitution is needed.')])),
]))

C1 = 'Football head coach: dark navy suit, white shirt, no tie, smart black shoes. Short grey hair, short grey beard, around 55 years old.'
person('مدرب الفريق الأول', 'art/raw/v3/coach-home/', 'يظهر في لقطات فريقك.', C1, [
 ('sheet-1.png', [('stand','Standing on the touchline, arms crossed.'),('point','Pointing forward, shouting instructions.'),('yell','Hands cupped around his mouth, shouting.'),('celebrate','Fist pump celebration, jumping slightly.'),('despair','Hands on head in disbelief.'),('clap','Clapping.')]),
 ('sheet-2.png', [('argue','Protesting to the fourth official, both arms open.'),('sit','Sitting on the bench, leaning forward, elbows on knees.'),('handshake','Reaching out his right hand for a handshake.'),('kneel','Crouching on the touchline, watching intently.')]),
], face=[('face-tense','Tense, hand on his chin.'),('face-joy','Celebrating, fist clenched, shouting.'),('face-angry','Angry at the referee.'),('face-think','Thinking, arms crossed, calm.')])
C2 = 'Football head coach: plain black tracksuit jacket and trousers, black trainers. Shaved head, black stubble, around 40 years old, energetic.'
person('مدرب الفريق الثاني', 'art/raw/v3/coach-away/', 'مدرب الخصم، بشكل مختلف تماماً عن الأول.', C2, [
 ('sheet-1.png', [('stand','Standing on the touchline, hands in pockets.'),('point','Pointing forward, shouting instructions.'),('yell','Hands cupped around his mouth, shouting.'),('celebrate','Jumping with both fists up.'),('despair','Turning away, both hands on head.'),('argue','Protesting to the fourth official, both arms open.')]),
], face=[('face-tense','Tense, biting his lip.'),('face-joy','Celebrating, shouting.'),('face-angry','Furious at the referee.'),('face-think','Thinking, hand on mouth.')])

SUB_ = f'{BIB} Different fictional people in each cell, varied looks.'
G.append(dict(t='البدلاء', f='art/raw/v3/bench/', note='على الدكة وفي الإحماء والاحتفال مع المدرب.', items=[
 ('char', 'sheet-1.png', None, char(True, SUB_, [('sit','Sitting on a bench seat, leaning forward, watching.'),('stand-cheer','Standing, cheering with both arms up.'),('jump','Jumping with joy, fists up.'),('warm-up','Jogging and warming up, knees high.'),('hands-head','Standing, both hands on his head.'),('applaud','Standing and applauding.')], kind='Fictional people, not real people, a different person in each pose,')),
]))

TEAM = f'{KIT} Players of the same team, fictional people with varied looks.'
G.append(dict(t='لحظات جماعية', f='art/raw/v3/team/', note='الاحتفال الجماعي والالتحامات واللحظات بين أكثر من شخص.', items=[
 ('char', 'sheet-1.png', None, duo(True, TEAM, [('hug','Two players hugging in celebration, side view.'),('jump-together','Two players jumping together chest to chest in celebration.'),('high-five','Two players giving each other a high five.'),('pile','Four players piling onto the scorer in a group hug.')])),
 ('char', 'sheet-2.png', None, duo(False, f'{TEAM} When a cell has two teams, the other team also wears pure white.', [('header-duel','Two players from different teams jumping together for a header, shoulder to shoulder.'),('tackle-duel','A defender sliding in and an attacker jumping over the tackle.'),('console','One player consoling a disappointed team-mate, hand on his shoulder.'),('surround-ref','Three players surrounding and protesting to a referee in all black.')])),
 ('char', 'sheet-3.png', None, duo(False, TEAM + ' Coaches wear suits as described per cell.', [('coaches-handshake','Two football coaches shaking hands, one in a dark navy suit with grey beard, one in a black tracksuit with shaved head.'),('captains','Two captains shaking hands in front of a referee in all black before kick-off, front view.'),('lineup','Five players standing side by side in the pre-match line-up, front view, hands behind their backs.'),('walk-tunnel','Four players walking away towards the tunnel, back view.')])),
]))


# ---------------- more looks: so every club does not field the same faces ----------------
CORE_POSES = [('shoot','Striking the ball hard with the right foot, follow-through.'),('pass','Passing with the inside of the right foot, short swing.'),('tackle','Sliding tackle on the grass, one leg extended forward.'),('header','In the air at the top of a jump, heading the ball, arms out.'),('celebrate-run','Running in celebration, arms wide open, shouting.'),('sad','Both hands on his head, disappointed.')]
LOOKS = [
 ('look-1', 'Arab player: short black hair with a fade, neat full black beard, light brown skin, average height.'),
 ('look-2', 'West African player: dark skin, short dreadlocks tied up, clean shaven, very athletic and tall.'),
 ('look-3', 'North African player: black mohawk haircut, thin moustache, tanned skin, compact and quick.'),
 ('look-4', 'East Asian player: straight black hair with a side part, clean shaven, light skin, slim.'),
 ('look-5', 'Red-haired player: short ginger hair, freckles, pale skin, short ginger beard, stocky.'),
 ('look-6', 'Veteran player: short salt-and-pepper hair, grey stubble, light skin, about 35 years old, experienced.'),
 ('look-7', 'Brazilian-style player: long dark curly hair with a headband, tanned skin, slim and skilful.'),
 ('look-8', 'Tall Nordic player: long blond hair in a man bun, full blond beard, very tall and strong.'),
]
for i, (k, d) in enumerate(LOOKS, 1):
    person(f'شكل لاعب إضافي {i}', f'art/raw/v3/players/{k}/', 'لاعب عام بشكل مختلف. اللعبة توزع الأشكال على لاعبي كل نادٍ، فلا يتكرر الوجه نفسه.', f'{KIT} {d}', [
     ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + LINEUP[:1]),
     ('sheet-core.png', CORE_POSES),
    ], face=[('face-focus','Focused.'),('face-joy','Shouting with joy.'),('face-sad','Disappointed.'),('face-smile','Smiling in the line-up.')])

K2 = 'Shaved head, dark brown skin, short black beard, very tall goalkeeper build.'
person('حارس مرمى ثانٍ', 'art/raw/v3/keeper-2/', 'حارس بشكل مختلف للفريق الآخر.', f'{GK} {K2}', [
 ('sheet-dive.png', [('ready','Ready stance on his line, knees bent, arms out, hands open.'),('set','Low set position just before the shot, weight forward, hands low.'),('dive-1','Pushing off to dive upwards and forwards, body starting to lean, one leg driving.'),('dive-2','Full-stretch dive in the air, body horizontal, both arms reaching forward, hands open.'),('dive-3','Falling to the grass after the dive, one shoulder reaching the ground first.'),('beaten','Lying on the grass after conceding, propped on one arm, looking back in frustration.')]),
 ('sheet-hands.png', [('catch-high','Jumping to catch high: both hands above his head, gloves shaped to hold a ball.'),('catch-chest','Catching at his chest, gloves wrapped around an invisible ball.'),('punch','Jumping and punching forward with one fist.'),('save-land','Lying on the grass after a save, both gloves holding an invisible ball against his chest.'),('celebrate','Celebrating a save: standing on both feet, legs straight and natural, both fists clenched, roaring.'),('point','Pointing forward, organising his defence, shouting.')]),
 ('sheet-front.png', [('front-ready','Front view facing the camera: on the goal line, ready stance, arms wide.'),('front-dive-left','Front view facing the camera: diving to his left, body horizontal in the air.'),('front-dive-right','Front view facing the camera: diving to his right, body horizontal in the air.'),('back-ready','Back view, seen from behind: on the goal line, ready stance, arms wide.'),('back-dive-left','Back view, seen from behind: diving to his left, body horizontal in the air.'),('back-dive-right','Back view, seen from behind: diving to his right, body horizontal in the air.')]),
], face=[('face-focus','Focused.'),('face-joy','Roaring after a save.'),('face-beaten','Disappointed.'),('face-shout','Shouting.')])

COACH_POSES = [('stand','Standing on the touchline, arms crossed.'),('point','Pointing forward, shouting instructions.'),('yell','Hands cupped around his mouth, shouting.'),('celebrate','Celebrating a goal, fists up.'),('despair','Hands on head in disbelief.'),('argue','Protesting to the fourth official, both arms open.')]
COACHES = [
 ('coach-3', 'Arab head coach: dark grey suit, white shirt, thin black tie, black shoes. Black hair combed back, thick black moustache, around 50 years old.'),
 ('coach-4', 'Head coach: long black wool overcoat over a dark suit, a plain grey scarf, black shoes. Silver hair, clean shaven, around 65 years old, elegant.'),
 ('coach-5', 'Young head coach: plain navy quilted jacket, dark trousers, white trainers, a plain navy cap. Short beard, around 35 years old.'),
 ('coach-6', 'Head coach: plain white shirt with rolled sleeves, dark waistcoat, dark trousers, brown shoes. Bald, glasses, around 45 years old, intense.'),
]
for i, (k, d) in enumerate(COACHES, 3):
    person(f'مدرب {i}', f'art/raw/v3/{k}/', 'مدرب بشخصية مختلفة، توزعه اللعبة على الأندية.', d, [('sheet-1.png', COACH_POSES)],
           face=[('face-tense','Tense, hand on his chin.'),('face-joy','Celebrating, shouting.'),('face-angry','Angry at the referee.'),('face-think','Thinking, calm.')])

R2 = f'{REF} Short black hair, clean shaven, tall, around 40 years old.'
person('حكم ثانٍ', 'art/raw/v3/referee-2/', 'حكم بشكل مختلف حتى لا يتكرر الحكم نفسه كل مباراة.', R2, [
 ('sheet-1.png', [('stand','Standing.'),('run-1','Running, right foot landing in front.'),('run-2','Running, left foot landing in front.'),('whistle','Blowing the whistle, one arm raised.'),('point-spot','Pointing firmly to the penalty spot with the right arm.'),('card-side','Raising one arm straight up high, hand holding a plain white card.')]),
], halfs=[('sheet-close.png', [('close-card','Raising a plain white card high with the right hand, stern face.'),('close-whistle','Blowing the whistle hard.'),('close-point','Pointing firmly to the side with the right arm.'),('close-ear','Hand on his earpiece, listening, serious.')])])

# ---------------- ball, props, fx ----------------
G.append(dict(t='الكرة', f='art/raw/v3/ball/', note='تصميم واحد من كل الزوايا.', items=[
 ('obj', 'sheet.png', [('ball','The ball.'),('ball-2','Rotated a quarter turn, different panels facing the camera.'),('ball-3','Rotated half a turn.'),('ball-4','Rotated three quarters of a turn.'),('ball-blur','The ball flying fast to the right with a motion blur streak trailing to the left.'),('ball-net','The ball pressed into white net mesh, the net wrapping around it.')],
  obj(True, 'The same original match ball in every cell: white with dark charcoal panels, no brand, perfectly round, the same size, a bright highlight on top and a darker underside.', [('ball','The ball.'),('ball-2','Rotated a quarter turn, different panels facing the camera.'),('ball-3','Rotated half a turn.'),('ball-4','Rotated three quarters of a turn.'),('ball-blur','The ball flying fast to the right with a motion blur streak trailing to the left.'),('ball-net','The ball pressed into white net mesh, the net wrapping around it.')])),
 ('obj', 'sheet-2.png', [('ball-mud','The ball dirty with mud and grass stains.'),('ball-wet','The ball wet with water drops.'),('ball-snow','The ball with a little snow on it.'),('ball-spot','The ball sitting on the white penalty spot on the grass, close up.')],
  obj(False, 'The same match ball in every cell.', bg=MAG, items=[('ball-mud','The ball dirty with mud and grass stains.'),('ball-wet','The ball wet with water drops.'),('ball-snow','The ball with a little snow on it.'),('ball-spot','The ball sitting on the white penalty spot on a small round patch of grass, close up.')])),
]))
P1 = [('corner-flag','A corner flag on a thin pole with a plain white flag, side view, the whole pole visible.'),('hand-card','A hand raised up holding a plain white referee card, black sleeve, no face.'),('flag','An assistant referee flag, red and yellow, on its own.'),('board','A blank digital substitution board, front view, dark empty screen, glowing edge.'),('monitor','A pitchside video review monitor on a stand, blank dark screen.'),('stretcher','A medical stretcher for a football pitch, side view.')]
P2 = [('trophy','An original golden league trophy, elegant cup with two handles on a dark base.'),('medal','An original gold winner medal with a ribbon.'),('armband','A plain white captain armband.'),('whistle','A black referee whistle on a black cord.'),('bottle','A plain squeezy water bottle without labels.'),('bag','A plain dark blue medical bag with a white cross.')]
P3 = [('scarf','A plain white football scarf held up with both hands, no text, no face.'),('flag-wave','A plain white flag on a pole, waving.'),('tifo','A huge plain white banner held across a section of the stand by fans, seen from the pitch.'),('smoke','A cloud of white smoke drifting.')]
G.append(dict(t='أدوات الملعب', f='art/raw/v3/props/', note='كل ما يحمله الحكام واللاعبون والجمهور. البطاقة والراية واللوحة بيضاء لتلوّنها اللعبة.', items=[
 ('obj', 'sheet-1.png', P1, obj(True, '', P1)), ('obj', 'sheet-2.png', P2, obj(False, '', P2)), ('obj', 'sheet-3.png', P3, obj(False, 'White items so the game can colour them.', P3)),
]))
F1 = [('grass-spray','Clumps of grass and soil flying up and to the right, as from a hard kick.'),('water-spray','A low spray of water droplets and grass bits along the ground, as from a sliding tackle on wet grass.'),('divot','A small chunk of turf flying in the air.'),('net-mesh','A flat square of white football net mesh, straight on.'),('snow-burst','A small burst of snow kicked up from the ground.'),('dust','A light puff of dust and grass from a landing.')]
F2 = [('flare','A stadium floodlight lens flare with a bright star and light rays.'),('pyro-red','Red stadium flares glowing with drifting smoke.'),('flash','Many small camera flashes and phone lights sparkling like a crowd in the dark.'),('spark','A bright white impact spark, as when a ball hits the metal post.')]
G.append(dict(t='المؤثرات', f='art/raw/v3/fx/', note='ما خلفيته سوداء ندمجه بالإضاءة، فلا تجعله شفافاً.', items=[
 ('obj', 'sheet-1.png', F1, obj(True, 'Nothing green in the items except grass.', F1, MAG)), ('obj', 'sheet-2.png', F2, obj(False, 'Light effects only.', F2, 'pure black background, not transparent')),
 ('single', 'confetti.png', 'Photorealistic render, ' + GREEN + ', no people, no text, no logos. Falling confetti and paper strips in gold and white, spread across the whole frame, landscape 1536x1024.'),
 ('single', 'rain.png', 'Photorealistic render, ' + GREEN + ', no people, no text, no logos. Only rain streaks falling slightly diagonally, spread evenly across the whole frame, landscape 1536x1024.'),
 ('single', 'snow.png', 'Photorealistic render, ' + GREEN + ', no people, no text, no logos. Only snowflakes falling gently, spread evenly across the whole frame, landscape 1536x1024.'),
]))

# ---------------- moments → assets ----------------
MAP = [
 ('L01', 'الدقائق الهادئة', 'رسم من اللعبة', '—'),
 ('L02', 'فرصة ضائعة', 'run · wing · shot · bench · crowd-sad', 'الجناح، المدافع، المهاجم، الحارس، المدرب'),
 ('L03', 'هدف', 'run · shot · corner · behind-goal · bench · crowd-joy', 'لاعب الوسط، الجناح، المهاجم، الحارس، لحظات جماعية، المدربان'),
 ('L04', 'تصدٍّ', 'run · shot · crowd-joy · bench', 'المهاجم، الحارس، المدرب'),
 ('L05', 'تسلل', 'run · wing · box-high', 'المدافع، المهاجم، الحكم المساعد'),
 ('L06', 'بطاقة صفراء', 'run · ثم لقطة الحكم القريبة', 'الجناح، المدافع، الحكم (قريب)، المهاجم يعترض'),
 ('L07', 'بطاقة حمراء', 'run · bench', 'المدافع، الحكم (قريب)، المدرب'),
 ('L08', 'ضربة حرة', 'shot-far · goal-front · crowd-tense', 'المهاجم (ضربة حرة)، المدافع (الحائط)، الحارس'),
 ('L09', 'ركلة جزاء', 'shot · behind-goal · goal-front · crowd-tense', 'الحكم (يشير)، المهاجم (أمامي وخلفي)، الحارس (أمامي وخلفي)'),
 ('L10', 'ركنية', 'corner · box-high · bench', 'الجناح، لحظات جماعية (التحام رأسي)، المدرب'),
 ('L11', 'مرتدة', 'run · shot', 'لاعب الوسط، المهاجم، المدافع'),
 ('L12', 'تبديل', 'touchline · bench', 'الحكم الرابع، اللاعب الخارج والداخل، البدلاء'),
 ('L13', 'إصابة', 'run · touchline', 'المهاجم (مصاب)، الطاقم الطبي، الحكم'),
 ('L14', 'بدل الضائع', 'touchline', 'الحكم الرابع (قريب)'),
 ('L15', 'البداية والاستراحة والنهاية', 'aerial · tunnel · tunnel-out · centre · dressing-room', 'لحظات جماعية (الاصطفاف، المصافحة، النفق)، كل اللاعبين'),
 ('L16', 'القائم', 'shot-far · shot · crowd-sad', 'المهاجم، الحارس، مؤثر الشرارة'),
 ('L17', 'فار وهدف ملغى', 'shot · monitor · crowd-sad', 'الحكم (الأذن، الإشارة)، المدرب يعترض'),
 ('L18', 'هدف ملغى لخطأ', 'shot · monitor', 'لحظات جماعية (التحام)، الحكم'),
 ('L19', 'فار لركلة جزاء أو بطاقة', 'monitor · run', 'الحكم (يشاهد الشاشة)'),
 ('L20', 'إنقاذ على الخط', 'shot', 'المدافع (يبعد عن الخط)، الحارس مهزوم'),
 ('L21', 'هدف عكسي', 'shot', 'المدافع (هدف عكسي)'),
 ('L22', 'إعادة ركلة الجزاء', 'behind-goal · goal-front', 'الحكم، الحارس، المهاجم'),
]

o = []; W = o.append
W('# Legends: كتاب صور اللقطات\n')
W('الملف الكامل والوحيد. **يحل محل كل الملفات السابقة.** كل الصور تُصنع من جديد بأسلوب واحد، حتى التي صنعتها من قبل.\n')
W('## الفكرة في سطرين\n')
W('- **الملاعب** صور كاملة لزوايا كاميرا ثابتة، والمرمى جزء منها.')
W('- **التنوع:** 12 شكل لاعب، وحارسان، و6 مدربين، وحكمان، و6 ملاعب. اللعبة توزع الأشكال على الأندية فلا تتكرر الوجوه.')
W('- **الشخصيات** لوحات حركة على خلفية خضراء مصمتة وقميص أبيض. أنا أقصها، وألوّنها بألوان كل نادٍ، وأحركها فوق الملعب، وأضع كل شخص بحجمه حسب بعده عن الكاميرا، مع الظل والإضاءة.\n')
W('## المواصفات الثابتة (مكتوبة داخل كل أمر، لا تغيرها)\n')
W('| البند | القيمة |')
W('|---|---|')
W('| الكاميرا | كاميرا البث على مستوى الأرض، ارتفاع متر، عدسة 35mm، وأسفل لوحات الإعلانات عند 55% من ارتفاع الصورة |')
W('| الإضاءة | كشافات ليلية: ضوء أبيض مائل للأزرق من الأعلى والخلف، وحافة مضيئة على الرأس والكتفين. أنا أعدّلها للملاعب النهارية |')
W('| المقاس | أفقي 1536×1024 لكل الصور |')
W('| الشخصيات | خلفية خضراء مصمتة (كروما)، 3 حركات في صف واحد لتبقى كل حركة كبيرة وواضحة، بلا ظل ولا أرضية ولا كرة، تشريح صحيح |')
W('| الأطقم | بيضاء خالصة (اللاعبون والحارس والبدلاء)، واللعبة تلوّنها. الحكام بالأسود |')
W('| ممنوع | أي نص أو رقم أو شعار، أو أشخاص حقيقيون |\n')
W('## طريقة العمل\n')
W('1. **كل مجموعة مستقلة تماماً:** افتح لها محادثة جديدة (Nano Banana أو ChatGPT)، وانسخ أوامرها بالترتيب من الأول للأخير. لا تحتاج أي شيء من مجموعة أخرى.')
W('2. **انسخ النص كما هو** من داخل المربع. أول أمر يصف الشخص أو الملعب، وما بعده يبدأ بـ Same ... as before ليبقى نفسه.')
W('3. **احفظ كل صورة باسمها المكتوب** داخل مجلدها. لا تقص اللوحات.')
W('4. **أرسلها لي** بعد كل مجموعة (4 صور في الرسالة على الأكثر، واكتب أسماءها)، أو ارفع مجلد `art` على GitHub: **Add file** ← **Upload files** ← **Commit directly to the main branch**.\n')
W('## افحص كل صورة قبل حفظها\n')
W('- [ ] **العدد والترتيب:** كل الخانات موجودة بالترتيب المكتوب.')
W('- [ ] **الجسم كامل:** من الرأس إلى الحذاء، غير مقصوص، ولا خانة تلمس أخرى.')
W('- [ ] **التشريح:** الركبة تنثني للأمام فقط، والساقان واليدان طبيعية، والقدم باتجاه الحركة، وخمسة أصابع، ولا رِجل تبدو مكسورة أو ملتوية.')
W('- [ ] **نفس الشخص** في كل الخانات (إلا الخانات الجماعية).')
W('- [ ] **القميص أبيض** للاعبين والحارس والبدلاء.')
W('- [ ] **الملاعب:** بلا لاعبين ولا كرة، والمرمى كامل حين يكون في الصورة.\n')
W('**جمل جاهزة للتصحيح:**\n')
W('- حركة خاطئة: `Redo pose N, the leg looks broken/unnatural, keep everything else the same`')
W('- قميص ملون: `Same image, but the kit must be pure white`')
W('- خانة ناقصة: `Redo the sheet with exactly N poses, same person, same order`')
W('- شخص مختلف: `Redo the sheet, the face must be exactly the same person as before`')
W('- ملعب فيه لاعبون: `Same image without any people on the pitch`')
W('- جاءت الخلفية مربعات شطرنج أو بيضاء بدل الأخضر: `Same image on a solid flat pure green background #00FF00` (وإن لم ينجح فلا بأس، أزيلها أنا).\n')
W('## مراحل الإنتاج\n')
W('| المرحلة | المجموعات | ما يصبح جاهزاً |')
W('|---|---|---|')
W('| 1 | الملعب 1، المهاجم، الحارس، الكرة | الهدف، والتصدي، والفرصة الضائعة، وركلة الجزاء |')
W('| 2 | المدافع، الجناح، لاعب الوسط، حكم الساحة، الحكم المساعد | البطاقات، والتسلل، والضربة الحرة، والركنية، والمرتدة |')
W('| 3 | المدربان، الحكم الرابع، البدلاء، الطاقم الطبي، لحظات جماعية | التبديل، والإصابة، والبداية والنهاية، والاحتفال الجماعي |')
W('| 4 | الأدوات، المؤثرات، الملاعب 2 إلى 6 | الفار، والقائم، والمطر، والملاعب المتنوعة |')
W('| 5 | أشكال اللاعبين الإضافية، الحارس الثاني، المدربون 3 إلى 6، الحكم الثاني | تنوع الوجوه: كل نادٍ بلاعبين ومدرب وحارس مختلفين |')
W('|---|---|---|---|')
for m in MAP: W(f'| {m[0]} | {m[1]} | {m[2]} | {m[3]} |')
W('')
W('## فهرس المجموعات\n')
tot_cmd = 0; tot_img = 0
for i, g in enumerate(G, 1):
    W(f'{i}. **{g["t"]}**: {len(g["items"])} {"أوامر" if len(g["items"]) <= 10 else "أمراً"}')
    tot_cmd += len(g['items'])
W('\n---\n')
for gi, g in enumerate(G, 1):
    W(f'## المجموعة {gi}: {g["t"]}\n')
    W(f'**المجلد:** `{g["f"]}`  ')
    W(f'**المحادثة:** جديدة. {g["note"]}\n')
    for j, it in enumerate(g['items'], 1):
        kind = it[0]
        if kind == 'plate':
            _, f, why, used, p = it; tot_img += 1
            W(f'### {gi}.{j} `{f}`\n'); W(f'{why} · **تُستخدم في:** {used}\n')
        elif kind == 'single':
            _, f, p = it; tot_img += 1
            W(f'### {gi}.{j} `{f}`\n'); W('صورة واحدة تملأ الشاشة.\n')
        else:
            _, f, poses, p = it
            if poses is None:
                import re
                cells = re.findall(r'(\d)\) ', p.split('Poses:' if 'Poses:' in p else 'Cells:')[-1])
                n = len(cells); names = None
            else:
                n = len(poses); names = '، '.join(x for x, _ in poses)
            tot_img += n; c, r = grid[n]
            W(f'### {gi}.{j} `{f}`\n')
            W(f'**{n} خانات** ({c}×{r})' + (f' بالترتيب: {names}' if names else '') + '\n')
        W('```\n' + p + '\n```\n')
W('---\n')
W(f'المجموع: **{len(G)} مجموعة**، **{tot_cmd} أمراً**، تعطي نحو **{tot_img} صورة**.')
open('LEGENDS-IMAGES.md', 'w').write('\n'.join(o) + '\n')
print(len(G), tot_cmd, tot_img)
