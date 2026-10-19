# Book 3: everything in build_book plus many more stadiums, states and situations.
# Runs after build_book's data inside build_nano (same helpers: stadium, person, char, duo, half, faces, obj).
G[:] = [g for g in G if not g['t'].startswith('الملعب')]
for g in G: g.setdefault('part', None)
OLD = {g['t']: g for g in G}

COND = {
 'night': ('ليلاً', 'at night under bright floodlights'),
 'day': ('نهاراً', 'on a bright sunny afternoon, clear blue sky, sharp shadows of the stands on the grass'),
 'dusk': ('عند الغروب', 'at golden hour sunset, warm orange and purple sky, floodlights just switched on'),
 'rain': ('تحت المطر', 'at night in heavy rain, wet shiny grass with small puddles reflecting the lights, rain streaks in the floodlight beams'),
 'snow': ('تحت الثلج', 'on a snowy winter evening under floodlights, snow falling, snow piled at the pitch edges, the playing surface cleared and green'),
 'fog': ('في الضباب', 'on a foggy evening under floodlights, thick mist hanging over the pitch, the far stand fading into the fog, glowing light halos'),
 'heat': ('في الحر', 'on a scorching hot afternoon, hard white sunlight, heat haze shimmering above the grass, deep shadows'),
}
STADIUMS = [
 ('arena', 'الأرينا', 'a huge modern two-tier bowl stadium packed with fans, a dark steel truss roof ring lined with clusters of bright white floodlights along its inner edge, a continuous LED ribbon glowing in a soft gradient of blue, violet and pink running all the way around the bowl between the two tiers, and matching blue-violet-pink LED advertising boards around the pitch', 'night', ['rain', 'day']),
 ('classic', 'الكلاسيكي', 'an old classic European stadium with steep red-brick stands rising right behind the pitch, red seats, a dark green pitched steel roof on thin columns, four tall lattice floodlight towers in the corners and plain white advertising boards', 'day', ['night', 'snow']),
 ('gulf', 'الخليجي', 'a modern Gulf-style stadium with a white sculpted roof cut with Arabic geometric lattice patterns, white and gold seats, slim palm trees visible outside the bowl and warm white LED advertising boards', 'dusk', ['night', 'heat']),
 ('maghreb', 'المغاربي', 'a stadium with sandstone-coloured walls, a row of Moroccan horseshoe arches along the top of the stands, green ceramic tiles on the stand fronts, green seats and warm floodlights on tall masts', 'night', ['day', 'dusk']),
 ('coast', 'الساحلي', 'a stadium beside the sea: one end is open behind the goal with only a low stand, showing the ocean, the waves and the horizon beyond; white and sea-blue seats and a curved white roof over the main stand', 'dusk', ['day', 'rain']),
 ('alpine', 'الجبلي', 'a stadium in a mountain valley: open corners show snowy peaks and dark pine forests behind low wooden-clad stands with a dark grey roof and orange seats', 'day', ['snow', 'fog']),
 ('dome', 'القبة', 'a futuristic indoor stadium under a closed transparent dome roof made of diamond-shaped glass panels, a glowing white LED ring around the base of the dome, purple seats and white LED boards', 'night', ['day']),
 ('terraces', 'المدرجات القديمة', 'a tight old ground with packed standing terraces, a rusty corrugated metal roof on steel posts, four old floodlight pylons in the corners and faded white boards', 'rain', ['night', 'fog']),
 ('cauldron', 'المرجل', 'a steep grey concrete bowl packed with fans, huge plain flags and paper streamers hanging from the stand fronts, yellow and blue seats and floodlights along the roof edge', 'night', ['day', 'rain']),
 ('skyline', 'المدينة', 'a sleek stadium with a white cable-stayed roof hung from tall masts, black seats with white accents, and a neon-lit city skyline of glass skyscrapers rising behind the stands', 'night', ['rain', 'dusk']),
 ('national', 'الوطني', 'a large two-tier national stadium with a red running track around the pitch, a grey concrete bowl with green seats and a white roof canopy lined with floodlights', 'day', ['night', 'heat']),
 ('desert', 'الصحراوي', 'a stadium in the desert with low sand-coloured stands and beige seats, golden sand dunes visible beyond them under a wide sky, and slim white floodlight masts', 'heat', ['night', 'dusk']),
 ('local', 'المحلي', 'a small local ground with one small covered main stand with blue seats, open grass banks on the other sides, four simple floodlight towers, a wire fence and a few small trees', 'night', ['day', 'rain']),
 ('final', 'ملعب النهائي', 'an enormous three-tier stadium dressed for a cup final, plain gold and white banners hanging on every tier, a huge white roof with rows of floodlights and gold LED advertising boards', 'night', ['dusk']),
 ('training', 'ملعب التدريب', 'a training ground with no stands: green fences, a few spectators standing behind a rail, a small clubhouse building and tall trees around', 'day', ['fog']),
]
CORE5 = ['shot', 'run', 'goal-front', 'behind-goal', 'corner']
SG = []
for key, ar, desc, main, variants in STADIUMS:
    c_ar, c_en = COND[main]
    keys = ALL if key != 'training' else ['shot', 'run', 'goal-front', 'behind-goal', 'corner', 'centre']
    nm = ar if ar.startswith('ملعب') else f'ملعب {ar}'
    SG.append(dict(t=f'{nm} {c_ar}', f=f'art/raw/v4/stadiums/{key}/{main}/', note=f'الحالة الأساسية لهذا الملعب: كل زوايا الكاميرا وجمهوره.', part='stadium',
                   items=stadium(key, desc, c_en, keys, crowd=key != 'training')))
    for v in variants:
        v_ar, v_en = COND[v]
        SG.append(dict(t=f'{nm} {v_ar}', f=f'art/raw/v4/stadiums/{key}/{v}/', note=f'نفس الملعب في حالة أخرى: الزوايا الأساسية الخمس.', part='stadium-var', ref_from=f'art/raw/v4/stadiums/{key}/{main}/shot.jpg', variant=True,
                       items=stadium(key, desc, v_en, CORE5, crowd=False)))
SG.append(dict(t='أجواء ما قبل المباراة وبعدها', f='art/raw/v4/scenes/', note='مشاهد عامة تظهر بين اللقطات.', part='stadium', items=[
 ('plate', f, why, used, f'Same style as before. Photorealistic, cinematic, landscape 1536x1024, no logos, no text. {view}') for f, why, used, view in [
  ('aerial-night.jpg', 'الملعب من الجو ليلاً', 'L15', 'Aerial drone view of a full football stadium at night, floodlights on, the lit pitch, city lights around.'),
  ('aerial-day.jpg', 'الملعب من الجو نهاراً', 'L15', 'Aerial drone view of a football stadium on a sunny day, crowds arriving.'),
  ('tunnel.jpg', 'داخل النفق', 'L15', 'Inside the players tunnel looking out to the bright pitch and the crowd, no people.'),
  ('dressing-room.jpg', 'غرفة الملابس', 'L15', 'A dressing room: benches, hanging plain white shirts without numbers, a blank tactics board, no people.'),
  ('dressing-joy.jpg', 'غرفة الملابس بعد الفوز', 'L15', 'A dressing room after a win: plain white shirts thrown around, confetti, an empty trophy plinth, no people.'),
  ('fans-arrive.jpg', 'الجماهير تصل', 'L15', 'Crowds of fans with plain scarves walking towards a lit stadium at dusk, faces blurred.'),
  ('team-bus.jpg', 'حافلة الفريق', 'L15', 'A plain white team coach bus arriving at a stadium entrance at night, fans behind barriers, faces blurred.'),
  ('press-room.jpg', 'المؤتمر الصحفي', 'L15', 'An empty post-match press conference room: a table with microphones, a plain backdrop, rows of empty chairs.'),
 ]]))
SG[0], SG[-1] = SG[0], SG[-1]

# ---------------- more players, keepers, coaches, referees ----------------
for g in G:
    if g['t'] in ('المهاجم الرئيسي', 'الجناح', 'لاعب الوسط', 'المدافع') or g['t'].startswith('شكل لاعب'): g['part'] = 'players'
    if 'حارس' in g['t']: g['part'] = 'keepers'
    if 'مدرب' in g['t']: g['part'] = 'coaches'
    if 'حكم' in g['t'] or g['t'] in ('الحكم المساعد', 'الحكم الرابع'): g['part'] = 'officials'
    if g['t'] in ('البدلاء', 'الطاقم الطبي'): g['part'] = 'bench'
    if g['t'] == 'لحظات جماعية': g['part'] = 'moments'
    if g['t'] in ('الكرة', 'أدوات الملعب', 'المؤثرات'): g['part'] = 'kit'
G[:] = [g for g in G if g['t'] not in ('الكرة', 'المؤثرات')]  # rebuilt below, bigger

MORE_LOOKS = [
 ('look-9', 'Gulf Arab player: short black hair, trimmed black beard, light brown skin, average height.'),
 ('look-10', 'Egyptian player: short curly black hair, thick moustache and stubble, olive skin, compact.'),
 ('look-11', 'Latin player: slicked-back black hair, tattoo sleeve on the left arm, tanned skin, wiry.'),
 ('look-12', 'Young player: messy light brown hair, freckles, clean shaven, about 18 years old, slim.'),
 ('look-13', 'Bald player: shaved head, dark brown skin, short beard, very muscular.'),
 ('look-14', 'Turkish-style player: short black hair, thick black beard, light skin, strong.'),
 ('look-15', 'Japanese-style player: short dyed blond hair, clean shaven, light skin, small and quick.'),
 ('look-16', 'Afro player: tall rounded afro hairstyle, dark skin, clean shaven, tall and lean.'),
 ('look-17', 'Balkan player: short dark hair, square jaw, stubble, very tall centre-back build.'),
 ('look-18', 'Sudanese-style player: very dark skin, short black hair, slim and very tall.'),
 ('look-19', 'Iranian-style player: wavy black hair, short beard, olive skin, average height.'),
 ('look-20', 'Senior captain: short grey hair, grey beard, light skin, about 36 years old, calm leader.'),
]
CEL = [('celebrate-run','Running in celebration, arms wide open, shouting.'),('fist-pump','Standing fist pump, roaring.'),('point-sky','Standing, both index fingers pointing to the sky.')]
for i, (k, d) in enumerate(MORE_LOOKS, 9):
    person(f'شكل لاعب إضافي {i}', f'art/raw/v3/players/{k}/', 'لاعب عام بشكل مختلف، توزعه اللعبة على الأندية.', f'{KIT} {d}', [
     ('sheet-run.png', [('stand','Standing ready, relaxed.')] + RUN4 + LINEUP[:1]),
     ('sheet-core.png', CORE_POSES), ('sheet-cel.png', CEL),
    ], face=[('face-focus','Focused.'),('face-joy','Shouting with joy.'),('face-sad','Disappointed.'),('face-smile','Smiling in the line-up.')])
    G[-1]['part'] = 'players'

# states of the main striker: rain and fatigue
person('المهاجم الرئيسي: حالات خاصة', 'art/raw/v3/striker-states/', 'نفس المهاجم في مباريات المطر والإرهاق. ارفق صورة من لوحات المهاجم الأولى لتبقى الملامح.', f'{KIT} {A} His white kit is soaked and splattered with mud and grass stains, his hair wet.', [
 ('sheet-rain.png', [('wet-run','Running in the rain, wet hair, mud on his socks.'),('wet-slide','Sliding on the wet ground, water spraying.'),('wet-shoot','Striking the ball in the rain, water flying off his boot.'),('wet-celebrate','Celebrating in the rain, arms wide, face up to the sky.'),('wet-sad','Kneeling in the rain, head down.'),('wipe-face','Wiping rain from his face with his shirt.')]),
 ('sheet-tired.png', [('tired-hands-knees','Bent over with hands on his knees, exhausted.'),('tired-walk','Walking slowly, exhausted, head back.'),('cramp','Lying on his back, one leg raised, suffering a cramp.'),('drink','Drinking from a plain water bottle, head tilted back.')]),
])
G[-1]['part'] = 'players'

person('المهاجم الرئيسي: أهداف استعراضية', 'art/raw/v3/striker-skills/', 'لقطات الأهداف الخاصة. ارفق صورة من لوحات المهاجم الأولى لتبقى الملامح.', f'{KIT} {A}', [
 ('sheet-bicycle.png', [('bicycle-1','Bicycle kick: jumping backwards, body rising, kicking leg swinging up.'),('bicycle-2','Bicycle kick: body horizontal in the air upside down, kicking leg striking above his head.'),('bicycle-3','Landing on his back on the ground after a bicycle kick, arms out.')]),
 ('sheet-skill.png', [('scorpion','Scorpion kick: diving forward, heel flicking up behind his back.'),('heel','Back-heel flick: right heel striking backwards.'),('rabona','Rabona: right leg wrapping behind the standing left leg to strike.'),('stretch','Stretching to poke the ball in at the far post, leg fully extended, sliding.'),('header-dive','Diving header, body flying horizontally forward, head first.'),('chest','Chest control: leaning back, chest out, arms wide.')]),
])
G[-1]['part'] = 'players'

MORE_KEEPERS = [
 ('keeper-3', 'Ginger hair in a short ponytail, pale skin, red beard, very tall.'),
 ('keeper-4', 'Short black curly hair, dark skin, clean shaven, very athletic.'),
]
for i, (k, d) in enumerate(MORE_KEEPERS, 3):
    person(f'حارس مرمى {i}', f'art/raw/v3/{k}/', 'حارس بشكل مختلف.', f'{GK} {d}', [
     ('sheet-dive.png', [('ready','Ready stance on his line, knees bent, arms out, hands open.'),('set','Low set position just before the shot.'),('dive-1','Pushing off to dive upwards and forwards.'),('dive-2','Full-stretch dive in the air, body horizontal, both arms reaching.'),('dive-3','Falling to the ground after the dive.'),('beaten','Lying on the ground after conceding, looking back in frustration.')]),
     ('sheet-hands.png', [('catch-high','Jumping to catch high, both hands above his head.'),('catch-chest','Catching at his chest.'),('celebrate','Celebrating a save, both fists clenched, legs straight and natural.')]),
     ('sheet-front.png', [('front-ready','Front view facing the camera: ready stance, arms wide.'),('front-dive-left','Front view facing the camera: diving to his left.'),('front-dive-right','Front view facing the camera: diving to his right.')]),
    ], face=[('face-focus','Focused.'),('face-joy','Roaring after a save.'),('face-beaten','Disappointed.'),('face-shout','Shouting.')])
    G[-1]['part'] = 'keepers'

MORE_COACHES = [
 ('coach-7', 'Head coach: plain beige trench coat over a dark jumper, dark trousers, brown shoes. Long grey hair tied back, around 60 years old, philosopher look.'),
 ('coach-8', 'Head coach: plain black puffer jacket, black trousers, black trainers. Shaved head, thick black beard, around 45 years old, fiery.'),
 ('coach-9', 'Female head coach: dark navy blazer, white blouse, dark trousers, black shoes. Short dark bob haircut, around 45 years old, composed.'),
 ('coach-10', 'Head coach: plain grey hoodie and grey track trousers, white trainers, a plain grey cap. Glasses, short beard, around 38 years old, analytical.'),
]
for i, (k, d) in enumerate(MORE_COACHES, 7):
    person(f'مدرب {i}', f'art/raw/v3/{k}/', 'مدرب بشخصية مختلفة.', d, [('sheet-1.png', COACH_POSES)],
           face=[('face-tense','Tense.'),('face-joy','Celebrating.'),('face-angry','Angry at the referee.'),('face-think','Thinking.')])
    G[-1]['part'] = 'coaches'

R3 = f'Female referee: {REF[3:]} Dark hair tied in a tight bun, fit build, around 35 years old.'.replace('Female referee: wears', 'Female referee who wears')
person('حكم ثالث', 'art/raw/v3/referee-3/', 'حكمة بشكل مختلف.', R3, [
 ('sheet-1.png', [('stand','Standing.'),('run-1','Running, right foot landing in front.'),('run-2','Running, left foot landing in front.'),('whistle','Blowing the whistle, one arm raised.'),('point-spot','Pointing firmly to the penalty spot.'),('card-side','Raising one arm straight up high, hand holding a plain white card.')]),
], halfs=[('sheet-close.png', [('close-card','Raising a plain white card high, stern face.'),('close-whistle','Blowing the whistle hard.'),('close-point','Pointing firmly to the side.'),('close-ear','Hand on her earpiece, listening.')])])
G[-1]['part'] = 'officials'

# ---------------- situations: cards, VAR, discipline ----------------
REFA = f'{REF} Bald head, short dark beard, fit build.'
def situation(t, folder, note, who, sheets, part='situations', kind=None):
    items = []
    for f, cells, k in sheets:
        fn = {'char': char, 'duo': duo, 'half': half}[k]
        items.append(('char', f, None, fn(True, who, cells)))
    G.append(dict(t=t, f=folder, note=note, part=part, items=items))
YEL = 'The card is a plain bright yellow referee card.'
RED = 'The card is a plain bright red referee card.'
situation('البطاقة الصفراء', 'art/raw/v4/cards/yellow/', 'كل مشاهد البطاقة الصفراء: الحكم من زوايا مختلفة وردود اللاعبين.', f'{REFA} {YEL} Players wear plain pure white kits.', [
 ('ref-angles.png', [('show-side','The referee seen from the side, arm raised straight up holding the yellow card.'),('show-front','The referee seen from the front facing the camera, holding the yellow card up high.'),('show-back','The referee seen from behind, holding the yellow card up towards a player.')], 'char'),
 ('ref-pocket.png', [('pocket','The referee reaching into his shirt pocket for a card.'),('note','The referee writing in a small notebook.'),('point-away','The referee pointing away, telling a player to step back.')], 'char'),
 ('close.png', [('close-show','Close-up from the waist up: the referee holding the yellow card high, stern face.'),('close-hand','Close-up of a hand holding the yellow card up against the floodlights.'),('close-player','Close-up from the waist up: a player in a white kit looking at the yellow card, hands raised in apology.'),('close-argue','Close-up from the waist up: a player in a white kit arguing, face angry.')], 'half'),
 ('reactions.png', [('apology','A player in a white kit raising both hands in apology.'),('smile','A player in a white kit smiling ironically, hands on hips.'),('argue','A player in a white kit protesting, both arms open.'),('walk-away','A player in a white kit walking away shaking his head.')], 'duo'),
])
situation('البطاقة الحمراء', 'art/raw/v4/cards/red/', 'الطرد: الحكم، واللاعب المطرود، واحتجاج الزملاء.', f'{REFA} {RED} Players wear plain pure white kits.', [
 ('ref-angles.png', [('show-side','The referee seen from the side, arm raised straight up holding the red card.'),('show-front','The referee seen from the front facing the camera, holding the red card up high.'),('show-back','The referee seen from behind, holding the red card up towards a player.')], 'char'),
 ('close.png', [('close-show','Close-up from the waist up: the referee holding the red card high, stern face.'),('close-hand','Close-up of a hand holding the red card up against the floodlights.'),('close-shock','Close-up from the waist up: a player in a white kit in shock, hands on his head.'),('close-rage','Close-up from the waist up: a player in a white kit shouting in rage.')], 'half'),
 ('sent-off.png', [('walk-off','A player in a white kit walking off, head down, pulling his shirt over his mouth.'),('walk-tunnel','A player in a white kit walking down towards the tunnel, back view.'),('kick-bottle','A player in a white kit kicking a plain water bottle in frustration on the touchline.')], 'char'),
 ('protest.png', [('surround','Three players in white kits surrounding and protesting to the referee.'),('held-back','One player in a white kit being held back by a team-mate.'),('captain-talk','A captain in a white kit talking calmly to the referee, hands together.'),('coach-rage','A coach in a dark suit shouting from the touchline, arms wide.')], 'duo'),
])
situation('الحكم: الأخطاء والقرارات', 'art/raw/v4/referee-calls/', 'إشارات الحكم الأخرى: ضربة حرة، استمرار، إصابة، حائط.', REFA, [
 ('calls-1.png', [('freekick-direct','Pointing his arm straight in the direction of a direct free kick.'),('freekick-indirect','Holding one arm straight up for an indirect free kick.'),('play-on','Both arms swept forward: play on.')], 'char'),
 ('calls-2.png', [('spray','Crouching and spraying a white foam line on the grass with a small spray can.'),('pace-wall','Pacing out the distance for the wall, arm stretched forward.'),('stop-play','Blowing the whistle, both arms crossed above his head to stop play for an injury.')], 'char'),
 ('calls-3.png', [('penalty-run','Running towards the box, pointing at the penalty spot.'),('dropped-ball','Crouched, dropping a ball that is not shown from waist height, alone, no other people.'),('wave-medics','Waving the medical staff on with one arm.')], 'char'),
])
situation('مراجعة الفار', 'art/raw/v4/var/', 'كل مراحل الفار: التواصل، الإشارة، الشاشة، القرار.', REFA, [
 ('steps-1.png', [('ear','Hand on his earpiece, listening, the other arm raised to stop play.'),('wait','Standing still, hand on his earpiece, alone, no other people.'),('var-sign','Drawing a rectangle in the air with both index fingers, the video review sign.')], 'char'),
 ('steps-2.png', [('walk-monitor','Walking quickly towards the touchline.'),('watch-side','Bending forward, watching a screen in front of him, hands on hips, side view.'),('watch-back','Watching a screen, seen from behind over his shoulder.')], 'char'),
 ('steps-3.png', [('decision-no-goal','Waving both arms crossed low in front of him: no goal.'),('decision-penalty','Pointing firmly to the penalty spot after the review.'),('decision-card','Running back onto the pitch, reaching for his pocket.')], 'char'),
 ('close.png', [('close-ear','Close-up from the waist up: hand on his earpiece, eyes closed, concentrating.'),('close-screen','Close-up from the waist up: watching a screen, the screen glow lighting his face.'),('close-sign','Close-up from the waist up: drawing the review rectangle in the air.'),('close-decide','Close-up from the waist up: pointing firmly, decision made.')], 'half'),
])
G.append(dict(t='غرفة الفار والشاشات', f='art/raw/v4/var-room/', note='خلفيات الفار. الشاشات فارغة، واللعبة تعرض عليها اللقطة.', part='situations', items=[
 ('plate', f, why, used, f'Same style as before. Photorealistic, cinematic, landscape 1536x1024, no logos, no text, all screens blank and dark. {view}') for f, why, used, view in [
  ('room.jpg', 'غرفة الفار', 'L17 L18 L19', 'A dark video review operations room: a row of large blank screens, desks, three officials in black seen from behind wearing headsets.'),
  ('room-close.jpg', 'حكم الفار عن قرب', 'L17', 'A video review official in black with a headset, seen from the side, watching a blank screen, the glow on his face.'),
  ('monitor-pitch.jpg', 'شاشة جانب الملعب', 'L19', 'A pitchside review monitor on a stand next to the touchline at night, its blank screen glowing, the crowd blurred behind.'),
  ('monitor-close.jpg', 'الشاشة عن قرب', 'L19', 'A close view of a blank glowing pitchside review screen, the hood around it, raindrops on top, stadium lights blurred behind.'),
 ]]))
situation('شجار ودفع', 'art/raw/v4/scuffle/', 'التدافع بعد خطأ: الحكم يفصل بين اللاعبين.', f'Players wear plain pure white kits. {REF.replace("He wears", "The referee wears")}', [
 ('scuffle.png', [('push','Two players in white kits pushing each other chest to chest.'),('separate','A referee in black stepping between two players in white kits, arms out.'),('face-off','Two players in white kits face to face, foreheads almost touching, angry.'),('teammates-pull','Two team-mates in white kits pulling an angry third player away by his arms.')], 'duo'),
])

# ---------------- celebrations and team moments ----------------
CELEB = f'{KIT} {A}'
situation('احتفالات الهدف', 'art/raw/v4/celebrations/', 'احتفالات متنوعة للهداف. ارفق صورة من لوحات المهاجم الأولى لتبقى الملامح.', CELEB, [
 ('solo-1.png', [('airplane','Running with both arms stretched out like aeroplane wings.'),('knee-slide','Knee slide on the ground, arms raised, leaning back.'),('belly-slide','Diving and sliding forward on his belly, arms forward.')], 'char'),
 ('solo-2.png', [('silence','Standing, one finger on his lips: silence.'),('heart','Making a heart shape with his hands towards the fans.'),('cup-ear','Running with a hand cupped behind his ear.')], 'char'),
 ('solo-3.png', [('jump-punch','Jumping high and punching the air.'),('flag-kick','Kicking out at a corner flag that is not shown, arms wide.'),('kneel-pray','Kneeling, looking up, both hands raised to the sky.')], 'char'),
 ('solo-4.png', [('dance','A short dance step, hips swinging, arms up.'),('salute','A military-style salute, standing straight.'),('shirt-kiss','Kissing the badge area of his plain white shirt, holding it out.')], 'char'),
])
situation('احتفالات جماعية', 'art/raw/v4/team-celebrations/', 'الفريق كله يحتفل.', f'{KIT} Players of the same team, fictional people with varied looks.', [
 ('team-1.png', [('pile','Five players piling onto the scorer on the ground.'),('lift','Two players lifting the scorer onto their shoulders.')], 'duo'),
 ('team-2.png', [('chain','Four players running together arm in arm.'),('bench-run','Three substitutes in white bibs running side by side onto the pitch to join a celebration.')], 'duo'),
 ('team-3.png', [('coach-hug','The scorer hugging a coach in a dark suit on the touchline.'),('fans-run','The scorer running towards the crowd boards, arms wide, back view.')], 'duo'),
 ('final-whistle.png', [('win-circle','Six players in a circle, arms on each other\'s shoulders, jumping together after the final whistle.'),('lose-sit','Three players sitting on the ground, heads down, after a defeat, a team-mate consoling them.')], 'duo'),
])
situation('الكأس والتتويج', 'art/raw/v4/trophy/', 'نهاية الموسم والنهائيات.', f'{KIT} Players of the same team, fictional people with varied looks. The trophy is an original golden cup with two handles.', [
 ('lift.png', [('captain-lift','The captain lifting the golden trophy above his head, roaring, front view.'),('team-lift','Seven players gathered close behind the captain lifting the trophy, confetti falling, front view.')], 'duo'),
 ('moments.png', [('kiss','A player kissing the golden trophy.'),('medal','A player biting a gold medal on a ribbon, smiling.')], 'duo'),
])
situation('ركلات الترجيح', 'art/raw/v4/shootout/', 'الأطقم بيضاء للفريقين، واللعبة تلوّن كل فريق.', f'{KIT} Players of two teams, all in pure white kits, fictional people with varied looks.', [
 ('line.png', [('arms-linked','Six players standing in a line on the centre circle, arms around each other, front view.'),('kneel-line','Players kneeling in a line, hands clasped, watching tensely, front view.')], 'duo'),
 ('walk.png', [('walk-spot','A player walking alone from the centre circle towards the penalty spot, back view.'),('miss-return','A player walking back with his head down after missing, team-mates reaching out.')], 'duo'),
])

# ---------------- crowd ----------------
FANS = 'Fictional fans, faces slightly blurred, plain scarves and shirts in generic colours.'
G.append(dict(t='الجمهور', f='art/raw/v4/crowd/', note='لقطات الجمهور، وطبقات أمامية تضيف عمقاً للملعب.', part='crowd', items=[
 ('plate', f, why, used, f'Same style as before. Photorealistic, cinematic, landscape 1536x1024. {FANS} {view}') for f, why, used, view in [
  ('ultras.jpg', 'الألتراس بالطبول', 'L03', 'An ultras section at night: drummers, a capo with a megaphone on a fence, everyone jumping, smoke drifting.'),
  ('tifo.jpg', 'لوحة جماهيرية', 'L15', 'A whole stand holding up coloured cards to form a huge plain pattern of stripes, before kick-off.'),
  ('phones.jpg', 'أضواء الهواتف', 'L15', 'A stand at night lit by thousands of phone torches.'),
  ('family.jpg', 'عائلات', 'L15', 'Families and children in a stand on a sunny day, smiling and clapping.'),
  ('anguish.jpg', 'صدمة', 'L17 L21', 'Fans in shock, hands on heads, mouths open, after a late goal against them.'),
  ('pray.jpg', 'دعاء قبل ركلة الترجيح', 'L09', 'Fans with hands together, eyes closed, praying before a penalty.'),
  ('away-end.jpg', 'جمهور الضيف', 'L03', 'A small away section behind a fence, fans celebrating wildly, the rest of the stadium empty seats around them.'),
  ('rain-fans.jpg', 'جمهور تحت المطر', 'L03', 'Fans in rain ponchos cheering in heavy rain under floodlights.'),
 ]] + [
 ('char', 'foreground.png', None, obj(True, 'Foreground layers for depth, seen from behind at the bottom of the frame, out of focus.', [('heads','A row of the backs of fans heads and shoulders, blurred, wide strip.'),('arms','Raised arms and plain scarves of fans, blurred, wide strip.'),('flags','Plain white flags waving on poles, blurred, wide strip.')])),
]))

# ---------------- broadcast ----------------
G.append(dict(t='البث المباشر', f='art/raw/v4/broadcast/', note='كل ما يخص البث: الشاشات فارغة، واللعبة تكتب عليها النتيجة والإعادة.', part='broadcast', items=[
 ('plate', f, why, used, f'Same style as before. Photorealistic, cinematic, landscape 1536x1024, no logos, no text, all screens blank and dark. {view}') for f, why, used, view in [
  ('big-screen.jpg', 'الشاشة العملاقة في الملعب', 'L03 L17', 'A giant blank video screen high in the corner of a stadium at night, the crowd below.'),
  ('scoreboard.jpg', 'لوحة النتيجة', 'L15', 'A large blank digital scoreboard on a stadium roof at night.'),
  ('studio.jpg', 'استوديو التحليل', 'L15', 'A modern TV football studio: a curved desk, a large blank video wall, studio lights, no people.'),
  ('studio-hosts.jpg', 'محللو الاستوديو', 'L15', 'Two fictional TV pundits in suits seen from behind at a studio desk, facing a large blank video wall.'),
  ('booth.jpg', 'غرفة المعلق', 'L01', 'A commentary booth high in the stand at night: two fictional commentators with headsets seen from behind, the lit pitch below.'),
  ('camera-op.jpg', 'المصور على خط الملعب', 'L03', 'A TV camera operator with a big broadcast camera on the touchline, seen from behind, the pitch beyond.'),
  ('spider-cam.jpg', 'الكاميرا الطائرة', 'L01', 'A view from a cable camera high above the pitch looking down on an empty lit pitch at night.'),
  ('control-room.jpg', 'غرفة الإخراج', 'L15', 'A TV outside broadcast control room: a wall of blank monitors, a mixing desk, two people seen from behind.'),
  ('pitchside-led.jpg', 'لوحات الإعلانات', 'L01', 'A close view along the pitchside LED advertising boards at night, all boards glowing plain blank colours.'),
  ('flash-interview.jpg', 'مقابلة ما بعد المباراة', 'L15', 'A post-match interview spot by the tunnel: a plain blank backdrop board, lights and a microphone stand, no people.'),
 ]] + [
 ('char', 'gear.png', None, obj(True, 'Broadcast equipment, all screens blank.', [('tv-camera','A big broadcast TV camera on a tripod.'),('handheld','A handheld TV camera.'),('mic','A plain microphone with no logo on the cube.')])),
]))

# ---------------- balls, goals, nets ----------------
BALLS = [
 ('classic', 'الكرة الكلاسيكية', 'white with dark charcoal pentagon panels, a classic design'),
 ('league', 'كرة الدوري الحديثة', 'white with bold swooping dark blue and gold curved panels, a modern design'),
 ('winter', 'كرة الشتاء', 'bright orange with dark blue panels, made to be seen in snow'),
 ('final', 'كرة النهائي', 'metallic gold and white with fine geometric patterns, a special final ball'),
 ('retro', 'الكرة القديمة', 'brown leather with stitched panels and laces, an old vintage ball'),
 ('futsal', 'كرة الصالات', 'white and green, smaller and heavier, for indoor football'),
]
for k, ar, d in BALLS:
    rot = [('ball','The ball.'),('ball-2','The same ball turned a quarter turn.'),('ball-3','The same ball turned half a turn.')]
    rot2 = [('ball-4','The same ball turned three quarters of a turn.'),('ball-blur','The same ball flying fast to the right, a motion blur streak trailing behind.'),('ball-spin','The same ball spinning, its panels slightly blurred by the spin.')]
    states = [('ball-mud','The same ball dirty with mud and grass.'),('ball-wet','The same ball wet with water drops.'),('ball-spot','The same ball resting on a small round patch of grass with a white penalty spot.')]
    G.append(dict(t=ar, f=f'art/raw/v4/balls/{k}/', note='كرة بتصميم أصلي بلا علامة تجارية.', part='kit', items=[
     ('char', 'rot-a.png', None, obj(True, f'The same original football in every position: {d}, perfectly round, no brand, no text, a bright highlight on top and a darker underside.', rot)),
     ('char', 'rot-b.png', None, obj(False, 'The same football as in the attached image.', rot2)),
     ('char', 'states.png', None, obj(False, 'The same football as in the attached image.', states, 'magenta')),
    ]))
GOALS = [
 ('standard', 'المرمى العادي', 'a standard white goal with a classic white box net'),
 ('deep', 'المرمى العميق', 'a white goal with a deep sloping net held by curved stanchions behind it'),
 ('hex', 'مرمى الشبكة السداسية', 'a white goal with a hexagonal honeycomb pattern net'),
 ('black-net', 'مرمى بشبكة سوداء', 'a white goal with a black net'),
 ('training', 'مرمى التدريب', 'a portable aluminium training goal with a white net and wheels'),
]
for k, ar, d in GOALS:
    views = [('side','Seen exactly from the side at pitch level, the goal mouth facing left, the whole goal and net visible.'),('front','Seen from the front, straight on, at the height of a person.'),('back','Seen from behind the net, looking through it.')]
    hits = [('bulge-side','Seen from the side, the back of the net bulging outward at the top corner as if a ball just hit it.'),('ripple-front','Seen from the front, the net rippling in the top right corner as if a ball just hit it.'),('post-hit','Close view of a post shaking, a small white flash of impact on it.')]
    G.append(dict(t=ar, f=f'art/raw/v4/goals/{k}/', note='المرمى وحده لنحرك شبكته في الكود.', part='kit', items=[
     ('char', 'views.png', None, obj(True, f'The same football goal in every position: {d}.', views)),
     ('char', 'hits.png', None, obj(False, 'The same goal as in the attached image.', hits)),
    ]))
G.append(dict(t='الشبكة والقائم عن قرب', f='art/raw/v4/net/', note='لقطات قريبة للحظة دخول الكرة وارتطامها.', part='kit', items=[
 ('plate', f, why, used, f'Photorealistic, cinematic, landscape 1536x1024, no logos, no text. {view}') for f, why, used, view in [
  ('net-inside.jpg', 'الكرة في الشبكة من الداخل', 'L03', 'A close view from inside the goal: a white ball stretching the white net, floodlights and the blurred crowd behind, at night.'),
  ('net-top.jpg', 'الكرة في الزاوية العليا', 'L03', 'A close view of a ball hitting the top corner of the net just under the crossbar, the net rippling, at night.'),
  ('post-close.jpg', 'ارتطام بالقائم', 'L16', 'A close slow-motion view of a ball hitting a white goal post, the post vibrating, a small spray of water, at night.'),
  ('line-close.jpg', 'الكرة على خط المرمى', 'L20', 'A low close view of a ball on the white goal line, the post beside it, at night.'),
 ]]))

# ---------------- effects ----------------
FX = [
 ('أرض وعشب', 'ground', 'magenta', [('grass-spray','Clumps of grass and soil flying up and to the right.'),('divot','A chunk of turf flying in the air.'),('dust','A light puff of dust and grass bits.'),('mud','A splash of brown mud.'),('water-spray','A spray of water droplets along the ground.'),('snow-burst','A burst of snow kicked up.')]),
 ('طقس', 'weather', 'green', [('rain','Only rain streaks falling diagonally, spread across the frame.'),('snow','Only snowflakes falling gently, spread across the frame.'),('fog','A soft layer of white fog, wide.'),('breath','Puffs of white breath vapour in cold air.'),('drops','Big water drops splashing.'),('heat','Heat haze shimmering distortion, faint.')]),
 ('أضواء', 'light', 'black', [('flare','A stadium floodlight lens flare with a bright star and light rays.'),('beam','Floodlight beams cutting down through the air.'),('bokeh','Soft round out-of-focus stadium light circles.'),('leak','A warm orange light leak glow at the edge of the frame.'),('flash','Camera flashes sparkling like a crowd in the dark.'),('spark','A bright white impact spark.')]),
 ('نار ودخان', 'fire', 'black', [('pyro-red','A red stadium flare burning with smoke.'),('pyro-green','A green stadium flare burning with smoke.'),('pyro-blue','A blue stadium flare burning with smoke.'),('smoke-white','A cloud of white smoke drifting.'),('smoke-color','Coloured smoke in plain white, ready to be tinted.'),('fireworks','Fireworks bursting in the night sky.')]),
 ('احتفال', 'party', 'green', [('confetti','Falling gold and white confetti spread across the frame.'),('streamers','Long paper streamers falling.'),('ticker','Ticker tape paper strips raining down.'),('scarf-wave','Plain white scarves waving.'),('balloons','Plain white balloons floating up.'),('sparkle','Gold sparkles glittering.')]),
 ('حركة وسرعة', 'motion', 'black', [('speed-lines','White speed streak lines, horizontal.'),('ball-trail','A curved white motion trail of a ball in flight.'),('shock-ring','A faint circular shockwave ring of air.'),('swoosh','A curved white swoosh streak.'),('impact-dust','A ring of dust at a point of impact.'),('glow-trail','A glowing golden trail.')]),
]
for ar, k, bg, items in FX:
    G.append(dict(t=f'مؤثرات: {ar}', f=f'art/raw/v4/fx/{k}/', note='ما خلفيته سوداء ندمجه بالإضاءة.', part='fx', items=[
     ('char', 'fx-a.png', None, obj(True, 'Visual effects for a football game.', items[:3], bg)),
     ('char', 'fx-b.png', None, obj(False, 'Visual effects in the same style as the attached image.', items[3:], bg)),
    ]))

G[:] = SG + G
PARTS = [('stadium', 'الجزء الأول: الملاعب'), ('stadium-var', 'الجزء الثاني: الملاعب في حالات أخرى'), ('players', 'الجزء الثالث: اللاعبون'),
         ('keepers', 'الجزء الرابع: الحراس'), ('officials', 'الجزء الخامس: الحكام'), ('situations', 'الجزء السادس: البطاقات والفار والقرارات'),
         ('moments', 'الجزء السابع: الاحتفالات واللحظات الجماعية'), ('coaches', 'الجزء الثامن: المدربون'), ('bench', 'الجزء التاسع: الدكة والطاقم الطبي'),
         ('crowd', 'الجزء العاشر: الجمهور'), ('broadcast', 'الجزء الحادي عشر: البث المباشر'), ('kit', 'الجزء الثاني عشر: الكرات والمرامي والأدوات'),
         ('fx', 'الجزء الثالث عشر: المؤثرات')]
for g in G:
    if g['t'] in ('احتفالات الهدف', 'احتفالات جماعية', 'الكأس والتتويج', 'ركلات الترجيح'): g['part'] = 'moments'
    g['part'] = g.get('part') or 'kit'
order = [p for p, _ in PARTS]
G.sort(key=lambda g: order.index(g['part']))

MAP += [
 ('L23', 'هدف استعراضي (مقصية، كعب)', 'shot · net-inside', 'المهاجم: أهداف استعراضية'),
 ('L24', 'تسديدة صاروخية من بعيد', 'shot-far · net-top', 'المهاجم، الحارس، مؤثرات الحركة'),
 ('L25', 'هدف رأسي من ركنية', 'corner · box-high', 'الجناح، المهاجم (رأسية)، المدافع'),
 ('L26', 'هدف في الوقت القاتل', 'shot · crowd · big-screen', 'احتفالات جماعية، الجمهور (صدمة/فرح)، المدربان'),
 ('L27', 'ركلات الترجيح', 'behind-goal · centre', 'ركلات الترجيح، الحراس، الجمهور (دعاء)'),
 ('L28', 'شجار بعد خطأ', 'run', 'شجار ودفع، الحكم'),
 ('L29', 'استراحة شرب الماء في الحر', 'bench · heat', 'المهاجم: حالات خاصة'),
 ('L30', 'مباراة تحت المطر والثلج', 'rain · snow', 'المهاجم: حالات خاصة، مؤثرات الطقس'),
 ('L31', 'التتويج بالكأس', 'final · centre', 'الكأس والتتويج، مؤثرات الاحتفال'),
 ('L32', 'رجل المباراة والمقابلة', 'flash-interview · press-room', 'وجوه اللاعبين القريبة'),
 ('L33', 'تحليل الاستوديو بين الشوطين', 'studio · studio-hosts', 'البث المباشر'),
]

STRIKER_REF = 'art/raw/v3/striker/sheet-run-a.png'
REF_REF = 'art/raw/v3/referee/sheet-1-a.png'
for g in G:
    if g['t'] in ('المهاجم الرئيسي: حالات خاصة', 'المهاجم الرئيسي: أهداف استعراضية', 'احتفالات الهدف'): g['ref_from'] = STRIKER_REF
    if g['t'] in ('البطاقة الصفراء', 'البطاقة الحمراء', 'الحكم: الأخطاء والقرارات', 'مراجعة الفار'): g['ref_from'] = REF_REF
