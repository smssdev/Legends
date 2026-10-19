"""The image book for the match scenes (docs/art/images/): python3 tools/art-prompts/book5.py

build_book.py holds the base data, book3_extra.py the stadiums and situations, build_nano.py
turns them into Nano Banana prompts, and this file adds the animation sequences and writes the book.
"""
# Book 5: animation-first. Every action is a sequence of consecutive frames (3 per board,
# 2 for wide poses), each character starts with a reference card, and every board after the
# first attaches the reference card plus the previous board, so the motion flows frame to frame.
import re, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
exec(open('build_nano.py').read().split("o = [" + "]; W = o.append\nPN")[0])   # BOOK of book 4 (plates, kit, props)

KEEP_PARTS = {'stadium', 'stadium-var', 'crowd', 'broadcast'}
KEEP_TITLES = {'غرفة الفار والشاشات', 'الشبكة والقائم عن قرب', 'أدوات الملعب'} | {ar for _, ar, _ in GOALS}
OLD = [b for b in BOOK if b['part'] in KEEP_PARTS or b['t'] in KEEP_TITLES]
for b in OLD:
    if b['t'] in KEEP_TITLES: b['part'] = 'situations' if 'الفار' in b['t'] else 'kit'

ANIM = ('These are consecutive animation frames for a 2D game sprite sheet, evenly spaced in time: each frame moves on one clear step of the motion from the one before, like a real animation cycle, and no two frames are the same. '
        'Every frame shows the whole figure from head to feet at exactly the same scale, standing on the same invisible ground line '
        '(the ground line is at the same height in every frame), with clear space between frames and nothing cut off.')
def an(n): return f'an {n}' if str(n)[0] == '8' or n in (11, 18) else f'a {n}'
def count(n, what='figure'):
    if n == 1: return f'The image shows exactly one {what}, centred, and no other people.'
    return f'The image shows exactly {n} {what}s of this same one person, one per frame, from left to right in frame order: no more, no fewer, and no other people.'
def she(text, who):
    # a woman: every he/his/him in the shared sentences becomes she/her
    if 'female' not in who: return text
    for a, b in (('He', 'She'), ('he', 'she'), ('His', 'Her'), ('his', 'her'), ('him', 'her'), ('himself', 'herself')):
        text = re.sub(rf'\b{a}\b', b, text)
    return text.replace('same fictional man', 'same fictional woman')
def anim_prompt(who, seq_title, total, frames, view, ref_mode):
    n = len(frames)
    pos = {1: ['Frame'], 2: ['Left frame', 'Right frame'], 3: ['Left frame', 'Middle frame', 'Right frame']}[n]
    if ref_mode == 'first':
        start = ''
    elif ref_mode == 'id':
        start = 'Use the attached reference card for this exact same person: the same face, hair, body and clothes, at the same scale. '
    else:
        start = ('Use the attached images: the reference card for this exact same person (same face, hair, body and clothes) and the previous frames, '
                 'to continue the same motion at the same scale and on the same ground line. ')
    a = frames[0][0]
    span = (f'{n} animation frames side by side in one row: frames {a} to {a + n - 1} of {an(total)}-frame {seq_title} sequence'
            if n > 1 else f'one single animation frame, centred: frame {a} of {an(total)}-frame {seq_title} sequence')
    if view in (VIEW['side'], VIEW['backwards']):   # in a side view the model cannot tell left from right: name the near and far limbs
        frames = [(i, re.sub(r'\bthe (right|left) (foot|leg|knee|arm|heel|thigh)', lambda m: f'the {"near" if m.group(1) == "right" else "far"} ({m.group(1)}) {m.group(2)}', d)) for i, d in frames]
    diff = ('Each frame is a clearly different pose from the others in this image; never repeat a pose. ' if n > 1 else '') + \
           ('Do not copy any pose from the attached previous image: draw the next poses of the motion. ' if ref_mode == 'prev' else '')
    body = (f'{start}A wide 3:2 landscape image with {span}. {count(n)} The character is {who}. {view} {ANIM} {diff}'
            + ' '.join(f'{p} (frame {i}): {d}' for p, (i, d) in zip(pos, frames)) + f' {NOBALL} {LIGHT} {ANAT} {GREEN} {NOTEXT}')
    return she(re.sub(r'\s+', ' ', body).strip(), who)

VIEW = {
 'side': 'He is seen exactly from the side, his body and face turned to the right, so the camera sees his right side: his right leg and right arm are the near ones, closest to the camera, and his left leg and left arm are the far ones; whenever he moves, he moves to the right.',
 'q-front': 'He is seen in three-quarter view, his body turned towards the camera and to the right; whenever he moves, he moves diagonally towards the camera and to the right.',
 'q-back': 'He is seen in three-quarter view from behind, his back half turned to the camera; whenever he moves, he moves diagonally away from the camera and to the right.',
 'front': 'He is seen from the front, facing the camera; whenever he moves, he moves straight towards the camera.',
 'back': 'He is seen from behind, his back to the camera; whenever he moves, he moves straight away from the camera.',
 'turn': 'He stays on the same spot and turns round on it; each frame says exactly which way he faces.',
 'line': 'He is seen from the front, facing the camera, on the touchline; when he moves, he side-steps towards the right of the image without turning.',
 'still-front': 'He is seen from the front, facing the camera, standing on the same spot in every frame.',
 'backwards': 'He is seen exactly from the side, his body, face and toes turned to the right, but he moves backwards, to the left of the image.',
}
def cycle(style, frames=8):
    # a stride cycle: contact, down, pass, flight/up for each foot
    up = 'both feet off the ground' if style['air'] else 'rising onto the toes of the standing foot'
    seq = []
    for F, O in (('right', 'left'), ('left', 'right')):
        seq += [f'{style["d"]}: the {F} foot just touching down in front of the body heel first, the {O} leg stretched behind, the {O} arm forward.',
                f'{style["d"]}: the {F} foot flat under the hips taking the weight, knee slightly bent, the {O} leg swinging forward low.',
                f'{style["d"]}: the {F} leg pushing off behind, the {O} knee passing forward at hip height.',
                f'{style["d"]}: {up}, the {O} knee driven forward, the {F} leg extended behind.']
    if frames == 12:  # sprints: six phases per stride for a smoother cycle
        seq = []
        for F, O in (('right', 'left'), ('left', 'right')):
            seq += [f'{style["d"]}: the {F} foot striking the ground under the knee, the {O} heel kicked up high behind.',
                    f'{style["d"]}: the {F} foot flat, knee bent, absorbing the landing, the {O} knee coming through low.',
                    f'{style["d"]}: the body passing over the {F} foot, the {O} thigh swinging forward.',
                    f'{style["d"]}: the {F} leg driving off the toes, nearly straight, the {O} knee high in front.',
                    f'{style["d"]}: both feet off the ground just after the push, the {O} knee at its highest, the {F} leg trailing.',
                    f'{style["d"]}: still in the air, the {O} foot reaching down to land, the {F} heel folding up behind.']
    return seq
STYLE = {
 'walk': dict(d='Walking calmly, upright', air=False),
 'jog': dict(d='Jogging lightly, relaxed (a slow run, not a walk: short strides, elbows bent)', air=True),
 'run': dict(d='Running fast (a real run, not a walk: long strides, body leaning slightly forward, elbows bent at a right angle and pumping)', air=True),
 'sprint': dict(d='Sprinting flat out, body leaning forward, arms pumping hard', air=True),
 'back': dict(d='Back-pedalling, moving backwards while still facing right, arms out for balance', air=False),
 'cel': dict(d='Running in celebration with both arms wide open, shouting with joy', air=True),
 'drib': dict(d='Dribbling at speed, looking down at a ball that is not shown', air=True),
}
def seq(key, title, frames, view='side', wide=False):
    return dict(key=key, title=title, frames=frames, view=view, wide=wide)

def outfield_sequences(full=True):
    S = []
    dirs = ['side', 'q-front', 'q-back', 'front', 'back'] if full else ['side']
    for d in dirs:
        S.append(seq(f'run-{d}', 'running', cycle(STYLE['run']), d))
    S += [seq('sprint', 'sprinting', cycle(STYLE['sprint'], 12)), seq('jog', 'jogging', cycle(STYLE['jog'])), seq('walk', 'walking', cycle(STYLE['walk']))]
    if full:
        S += [seq('walk-front', 'walking', cycle(STYLE['walk']), 'front'), seq('walk-back', 'walking', cycle(STYLE['walk']), 'back'),
              seq('backpedal', 'back-pedalling', [f'Back-pedalling: body and face still turned to the right, moving backwards to the left with short quick steps on the balls of the feet, arms out for balance, {x}' for x in (
                  'the right foot reaching back behind the body, toes first, the left foot flat under the hips.', 'the right foot landing behind on its toes, the weight moving back onto it.',
                  'both feet close together under the hips, knees slightly bent.', 'the left foot reaching back behind the body, toes first, the right foot flat under the hips.',
                  'the left foot landing behind on its toes, the weight moving back onto it.', 'both feet close together under the hips again, knees slightly bent.')], 'backwards'),
              seq('start', 'starting to run', ['Standing ready, weight on the balls of the feet.', 'Leaning forward, first push off the left foot.', 'First short step with the right foot, arms driving.', 'Second step, gathering speed.', 'Third step, almost at full running speed.', 'Running at full speed.']),
              seq('stop', 'stopping', ['Running at full speed.', 'Leaning back, the front foot planted to brake.', 'Short braking step, arms out.', 'Almost stopped, knees bent.', 'Standing, catching his balance.', 'Standing ready.']),
              seq('turn', 'turning round', ['Standing, side view, body and face turned to the right.', 'Turning, now in three-quarter view facing the camera.', 'Facing the camera, front view.', 'Still turning, three-quarter view facing left.', 'Side view, body and face turned to the left.', 'Standing, side view, facing left, settled.'], 'turn'),
              seq('idle', 'idle breathing', ['Standing relaxed, breathing in, chest slightly raised.', 'Standing relaxed, shoulders settling.', 'Standing relaxed, breathing out.', 'Standing relaxed, weight shifting to the other foot.'])]
    S += [seq('dribble', 'dribbling', [c.replace('touching down', 'touching the ball down') if i in (0, 4) else c for i, c in enumerate(cycle(STYLE['drib']))])]
    S += [seq('shoot', 'shooting', ['Approach: a long stride with the left foot towards a ball that is not shown.', 'Approach: a stride with the right foot, eyes on the ball.', 'The last long stride, arms opening for balance.',
                                    'The left foot planted beside the ball, the right leg swung far back, body leaning over.', 'The hips turning, the right leg swinging down towards the ball.', 'The moment of contact: the right foot striking low through the ball.',
                                    'Follow-through: the right leg rising forward past the hips.', 'Follow-through: the right leg high in front, body leaning back slightly.', 'Landing on the right foot, recovering balance, eyes following the shot.'])]
    S += [seq('pass', 'passing', ['Approaching a ball that is not shown, short stride.', 'The left foot planted, the right leg drawing back a little.', 'Striking with the inside of the right foot.', 'Short follow-through, foot pointing at the target.', 'Stepping forward after the pass.', 'Standing, watching the pass.'])]
    S += [seq('header', 'jumping header', ['Running in to meet a cross, eyes up.', 'Crouching to jump, knees bent, arms back.', 'Taking off, arms swinging up.', 'Rising in the air, body arched back.', 'At the top of the jump, snapping the head forward to hit a ball that is not shown.', 'Starting to come down, arms out.', 'Landing on both feet, knees bending.', 'Standing up again, watching the ball.'])]
    S += [seq('tackle', 'sliding tackle', ['Running in towards an opponent.', 'Dropping down onto his left hip, the right leg reaching forward.', 'Sliding on his left side along the ground, the right leg fully extended forward, the left leg bent under him.', 'Still sliding, grass flying, arms behind.', 'Slowing down on the ground.', 'Stopped, lying on his side.', 'Pushing himself up with one hand.', 'Back on his feet.'], wide=True)]
    S += [seq('fall', 'falling after a foul', ['Running at speed, balanced.', 'Clipped from behind on the left ankle, his legs tangling.', 'Stumbling forward, losing balance, arms forward.', 'Diving forward to the ground.', 'Hitting the ground, chest first, arms out.', 'Rolling onto his side, holding his leg.', 'Lying on the ground, appealing to the referee.', 'Getting up on one knee.'], wide=True)]
    S += [seq('celebrate', 'celebration run', cycle(STYLE['cel']))]
    S += [seq('sad', 'disappointment', ['Watching the shot go wide, standing.', 'Hands rising towards his head.', 'Both hands on his head, mouth open in disbelief.', 'Bending forward, hands still on his head.', 'Crouching down, head low.', 'Kneeling, head down.'])]
    if full:
        S += [seq('volley', 'volley', ['Watching a ball dropping from the air, arms out.', 'Leaning back, the right leg lifting.', 'Striking at hip height, body tilted back.', 'Follow-through, the right leg swinging across in front of the body.', 'Landing on the right foot.', 'Standing, watching the volley.']),
              seq('chip', 'chip shot', ['Running in, eyes on the keeper.', 'Planting the left foot short of the ball.', 'A short stabbing kick under the ball.', 'Foot stopping just after the touch.', 'Watching the ball float.', 'Arms rising as it drops in.']),
              seq('cross', 'crossing', ['Running down the wing.', 'The left foot planted, body leaning back.', 'The right foot swinging across the body.', 'Contact under the ball, curling it.', 'Follow-through, arms out.', 'Watching the cross.']),
              seq('control', 'first touch', ['Watching a pass coming in.', 'Opening his body, right foot lifting.', 'Cushioning the ball with the inside of the foot.', 'The ball dropping dead at his feet.', 'Pushing it forward.', 'Starting to run.']),
              seq('block', 'blocking a shot', ['Seeing the shot, turning side-on.', 'Throwing his body in the way, the right leg stretching out sideways.', 'Fully stretched, arms behind his back.', 'The impact, turning away.', 'Landing.', 'Getting up.'], wide=True),
              seq('getup', 'getting up', ['Lying face down.', 'Pushing up onto his hands.', 'On one knee.', 'Standing up, brushing grass off.'], wide=True),
              seq('hurt', 'injury', ['Falling to the ground holding his knee.', 'Lying on his side, knee pulled up, in pain.', 'Rolling onto his back, hands on his knee.', 'Lying still, grimacing, one hand raised for help.'], wide=True),
              seq('knee-slide', 'knee slide celebration', ['Running in celebration.', 'Dropping onto both knees.', 'Sliding on his knees, arms rising.', 'Sliding, leaning back, arms wide.', 'Slowing down, roaring.', 'Stopped on his knees, fists clenched.'], wide=True),
              seq('jump-cel', 'jump celebration', ['Running, arms wide.', 'Crouching to jump.', 'Leaping up, punching the air.', 'At the top of the jump, both fists up.', 'Landing.', 'Standing, roaring.']),
              seq('argue', 'protest', ['Turning towards the referee.', 'Arms opening wide.', 'Both arms wide, shouting.', 'Pointing at the ground, angry.']),
              seq('pk-back', 'penalty from behind', ['Seen from behind: standing still behind the penalty spot, hands on hips.', 'Seen from behind: a short step back.', 'Seen from behind: starting the run-up.', 'Seen from behind: the second run-up step.', 'Seen from behind: planting the left foot.', 'Seen from behind: striking the penalty with the right foot.', 'Seen from behind: follow-through.', 'Seen from behind: watching the ball.'], 'back'),
              seq('pk-front', 'penalty from the front', ['Seen from the front: standing still, staring ahead, focused.', 'Seen from the front: starting the run-up.', 'Seen from the front: the second run-up step.', 'Seen from the front: planting the left foot.', 'Seen from the front: striking the penalty with the right foot.', 'Seen from the front: follow-through.'], 'front'),
              seq('freekick', 'free kick', ['Standing behind the ball, hands on hips, focused.', 'Taking a step back.', 'Running in at an angle.', 'Planting the left foot, body leaning left.', 'Curling the ball with the inside of the right foot.', 'Follow-through, leaning, watching.']),
              seq('throwin', 'throw-in', ['Holding a ball that is not shown above his head with both hands, standing on the line.', 'Arching back, hands behind his head.', 'Throwing forward, arms coming over.', 'Arms finishing forward, feet still on the ground.']),
              seq('corner', 'corner kick', ['Standing at the corner, arm raised to signal.', 'Stepping back.', 'Running in.', 'Striking under the ball.', 'Follow-through.', 'Watching the cross.'])]
    return S

KEEPER_SEQ = [
 seq('ready', 'keeper ready bounce', ['In the ready stance, knees bent, arms out, hands open.', 'Bouncing lightly on his toes, slightly up.', 'Settling down again.', 'Low set position just before the shot, weight forward.']),
 seq('shuffle', 'side shuffle along the goal line', ['Ready stance.', 'Side step, feet apart.', 'Feet together.', 'Side step again.', 'Feet together.', 'Set position.'], 'q-front'),
 seq('dive-high', 'high dive to the right of the image', ['Set position, eyes on the ball.', 'A small step to the right.', 'Pushing off the right leg, body starting to lean to the right.', 'Launching upward, arms reaching up.', 'Rising in the air, body stretching out.', 'Full stretch at the highest point, body horizontal, hands reaching.', 'Starting to fall, arms still reaching.', 'Falling, one shoulder coming down first.', 'Landing on his side.', 'Sliding to a stop on his side.'], wide=True),
 seq('dive-low', 'low dive to the right of the image', ['Set position.', 'Pushing off low to the right.', 'Diving low along the ground, both hands reaching.', 'Body stretched along the ground.', 'Landing on his side.', 'Stopped, lying on his side.'], wide=True),
 seq('catch-high', 'high catch', ['Set position, looking up.', 'Jumping up, arms rising.', 'At the top, both hands above his head, gloves shaped around a ball that is not shown.', 'Pulling the ball down to his chest.', 'Landing, holding the ball at his chest.', 'Standing, holding the ball.']),
 seq('catch-chest', 'chest catch', ['Set position.', 'Leaning forward, arms forming a basket.', 'Catching at the chest, gloves wrapped around a ball that is not shown.', 'Holding the ball tight, bending over it.']),
 seq('punch', 'punching clear', ['Looking up at a cross.', 'Jumping, one arm pulling back.', 'Punching forward with one fist.', 'Arm fully extended.', 'Coming down.', 'Landing.']),
 seq('tip-over', 'tipping over the bar', ['Backpedalling, looking up.', 'Leaping backwards, arm rising.', 'Fingertips pushing a ball that is not shown over the bar.', 'Falling backwards.', 'Landing on his back.', 'Sitting up.'], wide=True),
 seq('save-land', 'save and hold', ['Diving, both hands on a ball that is not shown.', 'Landing with the ball against his chest.', 'Curling around the ball on the ground.', 'Lying still, holding the ball.'], wide=True),
 seq('beaten', 'beaten', ['Diving, the ball beyond his reach.', 'Landing on his side.', 'Lying on the ground, looking back at the net.', 'Propped on one arm, frustrated.'], wide=True),
 seq('getup', 'getting up', ['Lying on his side.', 'Pushing up with one arm.', 'On one knee.', 'Standing.'], wide=True),
 seq('kick', 'goal kick', ['Standing behind a ball that is not shown.', 'Running in.', 'Planting the left foot.', 'The right leg swinging back.', 'Striking the ball hard.', 'Follow-through high.', 'Landing.', 'Watching the kick.']),
 seq('throw', 'overarm throw', ['Holding a ball that is not shown at his side.', 'Arm drawing back.', 'Arm high behind him.', 'Arm whipping over.', 'Releasing forward.', 'Follow-through.']),
 seq('celebrate', 'save celebration', ['Standing up after a save.', 'Fists clenching.', 'Roaring, both fists up, legs straight and natural.', 'Pointing at his team-mates, shouting.']),
 seq('front-dive', 'penalty dive seen from the front', ['Seen from the front: ready on the line, arms wide.', 'Seen from the front: a small hop.', 'Seen from the front: pushing off to his left.', 'Seen from the front: in the air, body tilting to his left.', 'Seen from the front: body horizontal in the air, arms reaching to his left.', 'Seen from the front: falling.', 'Seen from the front: landing on his side.', 'Seen from the front: lying on the ground.'], 'front', wide=True),
 seq('front-catch', 'penalty catch seen from the front', ['Seen from the front: ready on the line.', 'Seen from the front: catching at his chest.', 'Seen from the front: holding the ball, celebrating.', 'Seen from the front: arms wide, roaring.'], 'front'),
 seq('back-dive', 'penalty dive seen from behind', ['Seen from behind: ready on the line, arms wide.', 'Seen from behind: pushing off to his left.', 'Seen from behind: in the air, body tilting to his left.', 'Seen from behind: body horizontal in the air, arms reaching to his left.', 'Seen from behind: falling.', 'Seen from behind: lying on the ground.'], 'back', wide=True),
]
REF_SEQ = [
 seq('run', 'running', cycle(STYLE['run'])), seq('walk', 'walking', cycle(STYLE['walk'])),
 seq('run-back', 'running', cycle(STYLE['run']), 'q-back'),
 seq('whistle', 'blowing the whistle', ['Standing, whistle to his lips.', 'Blowing hard, one arm rising.', 'Arm raised high, blowing.', 'Lowering the arm.']),
 seq('card', 'showing a card', ['Running in.', 'Stopping, reaching into his shirt pocket.', 'Pulling out a plain white card.', 'Raising the card.', 'Holding the card straight up high, stern.', 'Lowering the card, writing in a small notebook.']),
 seq('point-spot', 'awarding a penalty', ['Running towards the box.', 'Blowing the whistle.', 'Pointing firmly to the penalty spot.', 'Holding the point, stern.']),
 seq('advantage', 'playing advantage', ['Running.', 'Both arms swept forward.', 'Arms fully forward.', 'Running on.']),
 seq('var', 'video review sign', ['Hand on his earpiece, listening.', 'Raising both index fingers.', 'Drawing the top of a rectangle in the air.', 'Drawing the sides of the rectangle.', 'Finishing the rectangle.', 'Walking towards the touchline.']),
 seq('monitor', 'watching the review screen', ['Arriving at a screen that is not shown.', 'Bending forward, hands on hips, watching.', 'Leaning closer.', 'Straightening up, decision made.']),
]
LIN_SEQ = [seq('side-run', 'side-running along the line', ['Side-stepping to the right, flag down in the right hand.', 'Feet wide apart, flag down.', 'Feet together, flag down.', 'Feet wide apart again, flag down.', 'Feet together again, flag down.', 'Side-stepping on to the right, flag down.'], 'line'),
           seq('flag', 'raising the flag', ['Standing, flag down in the right hand.', 'Lifting the flag in the right hand.', 'Flag held straight up above his head.', 'Flag held out straight forward at shoulder height: offside.'], 'still-front')]
FOURTH_SEQ = [seq('board', 'raising the substitution board', ['Standing, holding a blank digital board low.', 'Lifting the board.', 'Board at chest height.', 'Board raised above his head, the screen dark and empty.', 'Holding it high.', 'Lowering the board.'], 'still-front')]
COACH_SEQ = [
 seq('idle', 'touchline idle', ['Standing, arms crossed.', 'Shifting his weight.', 'Hand on his chin, thinking.', 'Arms crossed again.']),
 seq('instruct', 'shouting instructions', ['Stepping forward.', 'Pointing forward.', 'Shouting, arm pointing.', 'Hands cupped around his mouth, shouting.']),
 seq('celebrate', 'celebrating a goal', ['Watching, tense.', 'Arms rising.', 'Jumping with fists up.', 'Landing, fist pump.', 'Turning to the bench, arms wide.', 'Clapping.']),
 seq('despair', 'despair', ['Watching, tense.', 'Hands going to his head.', 'Both hands on his head.', 'Turning away.', 'Crouching down.', 'Standing, arms crossed, frowning.']),
 seq('argue', 'protesting', ['Stepping towards the fourth official.', 'Arms wide open.', 'Shouting.', 'Pointing at the pitch.', 'Throwing his arms down.', 'Walking back, shaking his head.']),
]
def ref_card(who):
    who = who.rstrip('.')
    return she(re.sub(r'\s+', ' ', ('A wide 3:2 landscape character reference card: exactly four full body views of the same one person side by side in one row, '
                                 'no more and no fewer, at exactly the same scale, standing on the same ground line, relaxed with arms slightly away from the body, nothing cut off. '
                                 f'The character is {who}. From left to right: front view facing the camera, three-quarter view facing right, side view facing right, back view. '
                                 f'{NOBALL} {LIGHT} {ANAT} {GREEN} {NOTEXT}')), who)
def faces_card(who, items):
    who = who.rstrip('.')
    return she(re.sub(r'\s+', ' ', ('Use the attached reference card for this exact same person. A wide 3:2 landscape image with exactly four close-up portraits of him in a 2 by 2 grid, '
                                'head and shoulders, all of the same person, three-quarter view facing right, each with a blurred night stadium and floodlights behind, separated by thin black lines. '
                                f'The character is {who}. ' + ' '.join(f'{p}: {c}' for p, c in zip(['Top left', 'Top right', 'Bottom left', 'Bottom right'], items)) +
                                ' Photorealistic 3D render like a modern console football game, lit by cool stadium floodlights with a rim light on the hair. ' + NOTEXT)), who)
FACE4 = ['focused and calm.', 'screaming with joy.', 'devastated, hands on head.', 'angry, protesting.']

CH = []  # (part, title, folder, who, sequences, faces)
def character(part, title, folder, who, seqs, note, faces=True):
    groups = []
    ref = f'{folder}ref.png'
    boards = [dict(f='ref.png', names='البطاقة المرجعية: أمام، ثلاثة أرباع، جانب، خلف', ref=False, p=ref_card(who))]
    if faces: boards.append(dict(f='faces.png', names='الوجه: تركيز، فرحة، حسرة، غضب', ref=True, p=faces_card(who, FACE4)))
    groups.append(dict(t=f'{title}: البطاقة المرجعية', folder=folder, note=f'{note} ابدأ بها: كل مجموعات هذه الشخصية ترفقها.', boards=boards, part=part))
    fam = {}
    for s in seqs:
        fam.setdefault(FAMILY.get(s['key'].split('-')[0], FAMILY.get(s['key'], 'الحركة')), []).append(s)
    for fname, ss in fam.items():
        boards = []
        for s in ss:
            per = 2 if s['wide'] else 3
            fr = list(enumerate(s['frames'], 1)); total = len(fr)
            chunks = [fr[i:i + per] for i in range(0, total, per)]
            for ci, ch in enumerate(chunks):
                mode = 'id' if ci == 0 else 'prev'
                att = f'{ref}' if ci == 0 else f'{ref} + اللوحة السابقة'
                boards.append(dict(f=f'{s["key"]}-{ci + 1:02d}.png', names=f'{s["title"]}: الإطارات {ch[0][0]} إلى {ch[-1][0]} من {total}', ref=att,
                                   p=anim_prompt(who.rstrip('.'), s['title'], total, ch, VIEW[s['view']], mode)))
        groups.append(dict(t=f'{title}: {fname}', folder=f'{folder}{FOLD[fname]}/', note='كل لوحة 3 إطارات متتالية (2 للحركات العريضة). ارفق البطاقة المرجعية، ومن الإطار الثاني فصاعداً ارفق معها اللوحة السابقة.', boards=boards, part=part))
    CH.extend(groups)
FAMILY = {'run': 'الجري بالاتجاهات', 'sprint': 'الجري بالاتجاهات', 'jog': 'المشي والهرولة', 'walk': 'المشي والهرولة', 'backpedal': 'المشي والهرولة',
          'start': 'الانطلاق والتوقف والدوران', 'stop': 'الانطلاق والتوقف والدوران', 'turn': 'الانطلاق والتوقف والدوران', 'idle': 'الانطلاق والتوقف والدوران',
          'dribble': 'الكرة', 'shoot': 'الكرة', 'pass': 'الكرة', 'header': 'الكرة', 'volley': 'الكرة', 'chip': 'الكرة', 'cross': 'الكرة', 'control': 'الكرة',
          'tackle': 'الالتحام والسقوط', 'fall': 'الالتحام والسقوط', 'block': 'الالتحام والسقوط', 'getup': 'الالتحام والسقوط', 'hurt': 'الالتحام والسقوط',
          'celebrate': 'المشاعر', 'sad': 'المشاعر', 'knee': 'المشاعر', 'jump': 'المشاعر', 'argue': 'المشاعر',
          'pk': 'الكرات الثابتة', 'freekick': 'الكرات الثابتة', 'throwin': 'الكرات الثابتة', 'corner': 'الكرات الثابتة',
          'ready': 'الاستعداد', 'shuffle': 'الاستعداد', 'dive': 'الارتماء', 'catch': 'الإمساك والإبعاد', 'punch': 'الإمساك والإبعاد', 'tip': 'الإمساك والإبعاد',
          'save': 'الإمساك والإبعاد', 'beaten': 'الارتماء', 'kick': 'التوزيع', 'throw': 'التوزيع', 'front': 'ركلات الجزاء', 'back': 'ركلات الجزاء',
          'whistle': 'الإشارات', 'card': 'الإشارات', 'point': 'الإشارات', 'advantage': 'الإشارات', 'var': 'الفار', 'monitor': 'الفار',
          'side': 'الحركة', 'flag': 'الحركة', 'board': 'الحركة', 'instruct': 'الحركة', 'despair': 'المشاعر'}
FOLD = {'الجري بالاتجاهات': 'run', 'المشي والهرولة': 'walk', 'الانطلاق والتوقف والدوران': 'start', 'الكرة': 'ball', 'الالتحام والسقوط': 'ground', 'المشاعر': 'emotion',
        'الكرات الثابتة': 'setpiece', 'الاستعداد': 'ready', 'الارتماء': 'dive', 'الإمساك والإبعاد': 'hands', 'التوزيع': 'distribute', 'ركلات الجزاء': 'penalty',
        'الإشارات': 'signals', 'الفار': 'var', 'الحركة': 'move'}

W_KIT = 'a fictional male footballer in a plain pure white kit (white shirt, white shorts, white socks) and black boots, no logos or numbers (the game paints the team colours on the white)'
W_GK = 'a fictional male goalkeeper in a plain pure white long-sleeve shirt, white shorts, white socks, black boots and big black gloves, no logos or numbers (the game paints the keeper colours on the white)'
W_REF = 'a fictional male referee in an all-black kit (black shirt, shorts and socks, black boots) with a whistle on a cord'
MAIN = [('المهاجم الرئيسي', 'striker', A), ('الجناح', 'winger', W_), ('لاعب الوسط', 'midfielder', M_), ('المدافع', 'defender', D_)]
for t, k, d in MAIN:
    character('players', t, f'art/raw/v5/{k}/', f'{W_KIT}, {d[0].lower() + d[1:]}', outfield_sequences(True), 'لاعب رئيسي بكل الحركات وكل الاتجاهات.')
for i, (k, d) in enumerate(LOOKS + MORE_LOOKS, 1):
    character('looks', f'شكل لاعب {i}', f'art/raw/v5/players/{k}/', f'{W_KIT}, {d[0].lower() + d[1:]}', outfield_sequences(False), 'لاعب عام بالحركات الأساسية.')
for i, (k, d) in enumerate([('keeper', K_), ('keeper-2', K2)] + MORE_KEEPERS, 1):
    character('keepers', f'حارس المرمى {i}', f'art/raw/v5/{k}/', f'{W_GK}, {d[0].lower() + d[1:]}', KEEPER_SEQ, 'حارس بكل الحركات: من الجانب والأمام والخلف.')
for i, d in enumerate(['bald head, short dark beard, fit build', 'short black hair, clean shaven, tall, around 40', 'a woman with dark hair in a tight bun, fit, around 35'], 1):
    who = W_REF if i < 3 else W_REF.replace('male referee', 'female referee')
    character('officials', f'الحكم {i}', f'art/raw/v5/referee-{i}/', f'{who}, {d}', REF_SEQ, 'حكم الساحة بكل إشاراته.')
character('officials', 'الحكم المساعد', 'art/raw/v5/linesman/', 'a fictional assistant referee in an all-black kit holding a red and yellow flag, short grey hair', LIN_SEQ, 'حكم الراية.', faces=False)
character('officials', 'الحكم الرابع', 'art/raw/v5/fourth/', 'a fictional fourth official in a black referee jacket and black trousers, short brown hair, glasses', FOURTH_SEQ, 'لوحة التبديل.', faces=False)
for i, d in enumerate([C1, C2] + [c for _, c in COACHES + MORE_COACHES], 1):
    rest = d.split(': ', 1)[1]; kind = 'female football head coach' if 'Female' in d else 'football head coach'
    character('coaches', f'المدرب {i}', f'art/raw/v5/coach-{i}/', f'a fictional {kind} wearing a {rest[0].lower() + rest[1:]}', COACH_SEQ, 'مدرب على خط التماس.')

# objects in motion
def obj_seq(title, folder, part, what, seqs, bg='green'):
    boards = []; first = True
    bgt = {'green': GREEN.replace('each figure', 'each frame'), 'magenta': MAG, 'black': 'The background is pure black, because these are light effects.'}[bg]
    for key, name, frames in seqs:
        fr = list(enumerate(frames, 1)); total = len(fr)
        for ci in range(0, total, 3):
            ch = fr[ci:ci + 3]; pos = ['Left frame', 'Middle frame', 'Right frame'][:len(ch)]
            start = '' if first else 'Use the attached images (the first board and the previous one) to keep the exact same object, scale and style. '
            cell = {1: 'centred in the image', 2: 'centred in its half of the image', 3: 'centred in its third of the image'}[len(ch)]
            loop = ' It is a seamless loop: the last frame leads smoothly back into the first.' if 'loop' in name else ''
            p = re.sub(r'\s+', ' ', f'{start}A wide 3:2 landscape image with ' + (f'exactly {len(ch)} consecutive animation frames side by side in one row, no more and no fewer: frames {ch[0][0]} to {ch[-1][0]}' if len(ch) > 1 else f'one single animation frame, centred: frame {ch[0][0]}') + f' of {an(total)}-frame {name} for a 2D game, '
                       f'evenly spaced in time, each frame the same size and {cell}, each moving on only slightly from the one before.{loop} {what} ' + ' '.join(f'{p} (frame {i}): {d}' for p, (i, d) in zip(pos, ch)) +
                       f' Photorealistic render lit by cool night stadium floodlights from above. {bgt} {NOTEXT}')
            boards.append(dict(f=f'{key}-{ci // 3 + 1:02d}.png', names=f'{name}: {ch[0][0]} إلى {ch[-1][0]} من {total}', ref=not first and 'اللوحة الأولى + السابقة', p=p)); first = False
    return dict(t=title, folder=folder, note='إطارات متتالية تُعرض بسرعة فتصير حركة ناعمة.', boards=boards, part=part)
OBJ = []
for k, ar, d in BALLS:
    OBJ.append(obj_seq(ar, f'art/raw/v5/balls/{k}/', 'kit', f'The same original football in every frame: {d}, perfectly round, no brand, a bright highlight on top and a darker underside; the light stays fixed while the ball turns.', [
     ('spin', 'ball rotation', [f'The ball rotated {a} degrees forward.' for a in range(0, 360, 30)]),
     ('kick', 'ball impact', ['The ball round.', 'The ball slightly squashed on one side by a kick.', 'The ball strongly squashed.', 'The ball springing back, slightly stretched.', 'The ball round again.', 'The ball flying off with a faint motion blur.']),
    ]))
for k, ar, d in GOALS:
    OBJ.append(obj_seq(f'{ar}: حركة الشبكة', f'art/raw/v5/goals/{k}/', 'kit', f'The same football goal in every frame: {d}, seen exactly from the side at pitch level, the goal mouth facing left.', [
     ('bulge', 'net bulge', ['The net still.', 'The back of the net starting to push out at the top corner.', 'The net bulging out strongly.', 'Maximum bulge, the mesh stretched.', 'The net springing back.', 'The net bouncing out a little again.', 'Smaller bounce.', 'The net settling.', 'The net still again.']),
     ('shake', 'post shaking after a hit', ['The goal still.', 'The near post vibrating, a small white impact flash.', 'The post still vibrating, the net trembling.', 'The vibration fading.', 'The goal still.', 'The goal still, the net swaying gently.']),
    ]))
OBJ.append(obj_seq('الراية والأعلام', 'art/raw/v5/flags/', 'kit', 'Plain white flags on poles fluttering in the wind; the pole stays fixed in the same place in every frame and only the cloth moves.', [
 ('corner-flag', 'corner flag fluttering', ['A corner flag on its pole, the plain white flag fluttering, phase %d of the wave.' % i for i in range(1, 7)]),
 ('fan-flag', 'big fan flag waving', ['A big plain white flag waved on a pole, phase %d of the wave.' % i for i in range(1, 7)]),
 ('linesman-flag', 'assistant referee flag waving', ['A red and yellow assistant referee flag waved above a hand in a black sleeve, phase %d.' % i for i in range(1, 7)]),
]))
FXA = [
 ('ground', 'مؤثرات الأرض', 'magenta', [('grass', 'grass spray', ['A small burst at the point where a kick hits the turf, only the first specks of grass.', 'Grass and soil starting to fly up.', 'A spray of grass and soil in the air.', 'The spray spreading and rising.', 'Clumps falling back.', 'Last bits settling.']),
                                        ('water', 'water splash', ['The first small splash where a foot hits wet grass.', 'Water starting to splash.', 'A wide splash of water.', 'Drops flying outward.', 'Drops falling.', 'Last drops.']),
                                        ('snow', 'snow burst', ['The first small puff where a kick hits snow.', 'Snow bursting up.', 'A cloud of snow.', 'The cloud spreading.', 'Snow falling back.', 'Last flakes.']),
                                        ('dust', 'landing dust', ['The first small puff where a body hits the ground.', 'A puff of dust and grass rising.', 'The puff spreading.', 'Fading.'])]),
 ('weather', 'مؤثرات الطقس', 'green', [('rain', 'rain loop', ['Rain streaks across the whole frame, phase %d of a seamless loop.' % i for i in range(1, 5)]),
                                       ('snow', 'snowfall loop', ['Snowflakes across the whole frame, phase %d of a seamless loop.' % i for i in range(1, 5)]),
                                       ('fog', 'drifting fog loop', ['A soft layer of white fog drifting, phase %d of a seamless loop.' % i for i in range(1, 5)])]),
 ('fire', 'نار ودخان', 'black', [('flare-red', 'red flare loop', ['A burning red stadium flare with smoke, phase %d of a seamless loop.' % i for i in range(1, 7)]),
                                 ('flare-green', 'green flare loop', ['A burning green stadium flare with smoke, phase %d of a seamless loop.' % i for i in range(1, 7)]),
                                 ('smoke', 'smoke drift loop', ['White smoke drifting, phase %d of a seamless loop.' % i for i in range(1, 7)]),
                                 ('firework', 'firework burst', ['A rocket trail rising.', 'A small flash.', 'The burst opening.', 'A full round burst of gold sparks.', 'Sparks falling.', 'Sparks fading.', 'Last glows.', 'Faint smoke.'])]),
 ('light', 'أضواء', 'black', [('flashes', 'camera flashes loop', ['Scattered camera flashes in the dark, phase %d.' % i for i in range(1, 5)]),
                              ('flare', 'lens flare pulse', ['A floodlight lens flare, small.', 'The flare growing.', 'The flare at its brightest.', 'The flare shrinking.']),
                              ('spark', 'impact spark', ['A tiny white flash.', 'A bright star-shaped spark.', 'The spark spreading.', 'Fading.'])]),
 ('party', 'احتفال', 'green', [('confetti', 'confetti fall loop', ['Gold and white confetti falling across the frame, phase %d of a seamless loop.' % i for i in range(1, 5)]),
                               ('streamers', 'streamers fall loop', ['Paper streamers falling, phase %d of a seamless loop.' % i for i in range(1, 5)])]),
 ('crowd', 'جمهور أمامي متحرك', 'green', [('jump', 'fans jumping loop', ['A row of fans seen from behind, blurred, all jumping, phase %d of a seamless loop.' % i for i in range(1, 7)]),
                                          ('scarves', 'scarves waving loop', ['Raised arms and plain scarves of fans seen from behind, blurred, waving, phase %d.' % i for i in range(1, 7)]),
                                          ('clap', 'fans clapping loop', ['A row of fans seen from behind, blurred, clapping above their heads, phase %d.' % i for i in range(1, 5)])]),
]
for k, ar, bg, seqs in FXA:
    OBJ.append(obj_seq(f'مؤثرات متحركة: {ar}', f'art/raw/v5/fx/{k}/', 'fx', 'Visual effects for a football game. Only the effect itself is drawn: no people, no feet, no ball, no grass field and no ground, unless a frame names fans.', seqs, bg))

# group moments as short sequences of two-person scenes
DUO = [('hug', 'celebration hug', ['Exactly two players in white kits running towards each other.', 'The two jumping into a hug.', 'Hugging, one lifting the other.', 'Setting him down, both roaring.']),
       ('high-five', 'high five', ['Exactly two players in white kits approaching each other.', 'Hands rising.', 'Hands slapping together.', 'Turning away, smiling.']),
       ('header-duel', 'header duel', ['Two players from different teams, both in white kits, waiting for a cross.', 'Both crouching to jump.', 'Both rising, shoulder to shoulder.', 'One heading a ball that is not shown, the other beaten.', 'Coming down.', 'Landing, one stumbling.']),
       ('tackle-duel', 'tackle duel', ['Exactly two players: an attacker in white running, a defender in white closing in.', 'The defender sliding in.', 'The attacker jumping over the slide.', 'The attacker landing and running on.', 'The defender sliding past.', 'The defender stopping on the ground.']),
       ('pile', 'team pile-on', ['The scorer in white sliding on his knees, alone.', 'Four team-mates in white running in towards him.', 'The four team-mates jumping on him.', 'A pile of exactly five players, the scorer underneath.']),
       ('shake', 'handshake', ['Exactly two players in white kits facing each other.', 'Reaching out right hands.', 'Shaking hands.', 'Patting each other on the shoulder.']),
       ('push', 'push and separate', ['Exactly two players in white face to face.', 'One pushing the other.', 'A referee in black arriving and stepping between them: three people now.', 'The referee separating them, arms out.'])]
boards = []
for i, (k, name, fr) in enumerate(DUO):
    frs = list(enumerate(fr, 1))
    for ci in range(0, len(frs), 2):
        ch = frs[ci:ci + 2]
        start = '' if not boards else 'Use the attached images (the first board and the previous one) to keep the same people, scale and style. '
        p = re.sub(r'\s+', ' ', f'{start}A wide 3:2 landscape image with exactly {len(ch)} consecutive animation frames side by side in one row: frames {ch[0][0]} to {ch[-1][0]} of {an(len(fr))}-frame {name} sequence for a 2D game, '
                   f'each frame showing the fictional people full body at the same scale on the same ground line, seen from the side. Each frame shows exactly the people it names and no one else. {ANIM} ' +
                   ' '.join(f'{p} (frame {j}): {d}' for p, (j, d) in zip(['Left frame', 'Right frame'], ch)) + f' {NOBALL} {LIGHT} {ANAT} {GREEN} {NOTEXT}')
        boards.append(dict(f=f'{k}-{ci // 2 + 1:02d}.png', names=f'{name}: {ch[0][0]} إلى {ch[-1][0]} من {len(fr)}', ref=bool(boards) and 'اللوحة الأولى + السابقة', p=p))
OBJ.append(dict(t='لحظات جماعية متحركة', folder='art/raw/v5/team/', note='مشاهد بين لاعبين بإطارات متتالية.', boards=boards, part='moments'))

POSE_GROUPS = {'البطاقة الصفراء': 'situations', 'البطاقة الحمراء': 'situations', 'الحكم: الأخطاء والقرارات': 'situations', 'مراجعة الفار': 'situations',
               'شجار ودفع': 'situations', 'احتفالات الهدف': 'moments', 'احتفالات جماعية': 'moments', 'الكأس والتتويج': 'moments', 'ركلات الترجيح': 'moments',
               'المهاجم الرئيسي: حالات خاصة': 'players', 'المهاجم الرئيسي: أهداف استعراضية': 'players', 'البدلاء': 'bench', 'الطاقم الطبي': 'bench'}
for b in BOOK:
    if b['t'] in POSE_GROUPS:
        b = dict(b); b['part'] = POSE_GROUPS[b['t']]
        b['t'] = b['t'] + ' (وضعيات ثابتة)'
        b['note'] = b['note'] + ' هذه وضعيات مفردة للحظات التي تتوقف فيها الحركة (تجميد، لقطة قريبة).'
        b['boards'] = [dict(x, ref=(x['ref'].replace('art/raw/v3/striker/sheet-run-a.png', 'art/raw/v5/striker/ref.png').replace('art/raw/v3/referee/sheet-1-a.png', 'art/raw/v5/referee-1/ref.png') if isinstance(x['ref'], str) else x['ref'])) for x in b['boards']]
        OLD.append(b)
ALLB = CH + OBJ + OLD  # within a part: reference cards and sequences first, single poses after
PARTS5 = [('stadium', 'الجزء 1: الملاعب'), ('stadium-var', 'الجزء 2: الملاعب في حالات أخرى'), ('players', 'الجزء 3: اللاعبون الرئيسيون (كل الحركات والاتجاهات)'),
          ('looks', 'الجزء 4: أشكال اللاعبين (الحركات الأساسية)'), ('keepers', 'الجزء 5: الحراس'), ('officials', 'الجزء 6: الحكام'),
          ('situations', 'الجزء 7: الفار والشاشات'), ('moments', 'الجزء 8: اللحظات الجماعية'), ('coaches', 'الجزء 9: المدربون'), ('bench', 'الجزء 9ب: الدكة والطاقم الطبي'),
          ('crowd', 'الجزء 10: الجمهور'), ('broadcast', 'الجزء 11: البث المباشر'), ('kit', 'الجزء 12: الكرات والمرامي والأعلام والأدوات'), ('fx', 'الجزء 13: المؤثرات المتحركة')]
order = [p for p, _ in PARTS5]
ALLB.sort(key=lambda g: order.index(g['part']))
# one tidy tree: art/raw/<what>/..., without the book version in the path
def tidy(x): return re.sub(r'art/raw/v\d/', 'art/raw/', x) if isinstance(x, str) else x
for g in ALLB:
    g['folder'] = tidy(g['folder']); g['note'] = tidy(g['note'])
    for b in g['boards']: b['ref'] = tidy(b['ref'])
print(len(ALLB), sum(len(g['boards']) for g in ALLB))

# ---------------- waves: the first item of every section, then the second, ... ----------------
# Each wave is a playable slice: made as images, built into the simulator, checked, then the next.
# A character's first wave takes its essential moves; the rest of its moves come in the next wave.
SKEYS = [k for k, *_ in STADIUMS]
CORE = {'البطاقة المرجعية', 'الجري بالاتجاهات', 'الكرة', 'الالتحام والسقوط', 'المشاعر', 'الاستعداد', 'الارتماء', 'الإمساك والإبعاد', 'الإشارات'}
MAIN = {'المهاجم الرئيسي': 1, 'المدافع': 2, 'الجناح': 3, 'لاعب الوسط': 4}
BALLW = {ar: i for i, (_, ar, _) in enumerate(BALLS, 1)}
GOALW = {ar: i for i, (_, ar, _) in enumerate(GOALS, 1)}
FXW = {'مؤثرات الأرض': 1, 'مؤثرات الطقس': 2, 'نار ودخان': 3, 'أضواء': 4, 'احتفال': 5, 'جمهور أمامي متحرك': 6}
def wave_of(g):
    t, p = g['t'], g['part']
    head, _, fam = t.partition(': ')
    if p in ('stadium', 'stadium-var'):
        if t.startswith('أجواء'): return 2
        key = g['folder'].split('/stadiums/')[1].split('/')[0]
        return SKEYS.index(key) + (1 if p == 'stadium' else 2)
    if p == 'players':
        if head in MAIN: return MAIN[head] + (0 if fam.split(' (')[0] in CORE else 1)
        return 5                                       # the striker's states and trick goals
    if p == 'looks': return 2 + (int(re.search(r'\d+', t).group()) - 1) // 3
    if p == 'keepers':
        k = int(re.search(r'\d+', head).group())
        return (1 if fam in CORE else 2) if k == 1 else k + 1
    if p == 'officials':
        if head == 'الحكم 1': return 1 if fam in CORE else 2
        if head in ('الحكم المساعد', 'الحكم الرابع'): return 2
        return int(re.search(r'\d+', head).group()) + 1
    if p == 'situations':
        if 'شجار' in t: return 4
        return 3 if 'الفار' in t else 2
    if p == 'moments':
        if t.startswith('احتفالات الهدف'): return 1
        return 4 if ('الكأس' in t or 'الترجيح' in t) else 2
    if p == 'coaches': return int(re.search(r'\d+', head).group())
    if p == 'bench': return 2
    if p == 'crowd': return 1
    if p == 'broadcast': return 3
    if p == 'kit':
        if head in BALLW: return BALLW[head]
        if head in GOALW: return GOALW[head]
        return 2                                       # flags, props, close-ups of the net
    if p == 'fx': return FXW.get(fam, 6)
    return 9
for g in ALLB: g['wave'] = wave_of(g)

# every attachment named: the exact earlier files to attach, not "the first board" or "the previous one"
def path(g, b): return g['folder'] + b['f']
for g in ALLB:
    first, prev = None, None
    for b in g['boards']:
        r = b['ref']; att = []
        if r is True:
            att = [path(g, first)]
        elif isinstance(r, str):
            for part in r.split(' + '):
                part = part.strip()
                if part.startswith('art/'): att.append(part)
                elif 'الأولى' in part: att.append(path(g, first))
                elif 'السابقة' in part: att.append(path(g, prev))
        b['attach'] = [a for i, a in enumerate(att) if a and a not in att[:i]]
        if first is None: first = b
        prev = b
def attach_md(b):
    return ('**ارفق:** ' + ' و'.join(f'`{a}`' for a in b['attach'])) if b['attach'] else '**بلا مرفق** (أول صورة)'
WAVES = sorted({g['wave'] for g in ALLB})
SPRINT_OF = {1: 'السبرنت 2 (الصور) و3 (المحاكاة)', 2: 'السبرنت 4', 3: 'السبرنت 5', 4: 'السبرنت 6', 5: 'السبرنت 7', 6: 'السبرنت 8', 7: 'السبرنت 8'}
def sprint_of(w): return SPRINT_OF.get(w, 'السبرنت 9' if w <= 11 else 'السبرنت 10')

# ---------------- write: one guide + one file per part ----------------
OUT = os.path.join('..', '..', 'docs', 'art', 'images')
os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT): os.remove(os.path.join(OUT, f))
PN = dict(PARTS5)
parts = [p for p in order if any(g['part'] == p for g in ALLB)]
fname = {p: f'{i:02d}-{p}.md' for i, p in enumerate(parts, 1)}
total = sum(len(g['boards']) for g in ALLB)

o = []; W = o.append
W('# Legends: كتاب صور اللقطات، الإصدار الخامس (Nano Banana)\n')
W(f'**{len(ALLB)} مجموعة** و**{total} لوحة**. هذا الملف هو الدليل، وكل جزء في ملف منفصل حتى يسهل فتحه على الجوال. يحل محل كل الإصدارات السابقة.\n')
W('## الهدف: محاكاة سلسة بلا تقطيع\n')
W('التقطيع يأتي من قلة الإطارات: لاعب يجري بـ4 صور يقفز من وضعية لوضعية. في هذا الإصدار:\n')
W('- **كل حركة سلسلة إطارات متتالية:** الجري 8 إطارات، والانطلاق 12، والتسديدة 9، والارتماء 10، والرأسية 8، والسقوط 8. اللعبة تعرضها بسرعة 12 إلى 15 إطاراً في الثانية، وتمزج كل إطارين، فتصير الحركة ناعمة.')
W('- **الجري في 5 اتجاهات:** جانبي، وثلاثة أرباع نحو الكاميرا، وثلاثة أرباع بعيداً عنها، ونحو الكاميرا، وبعيداً عنها. فيتحرك اللاعب في عمق الملعب لا على خط واحد. الاتجاه المعاكس تعكسه اللعبة تلقائياً.')
W('- **حركات الانتقال:** الانطلاق من الوقوف، والتوقف، والدوران، والتنفس وقت الوقوف، فلا يقفز اللاعب من الوقوف إلى الجري.')
W('- **البطاقة المرجعية لكل شخصية:** أمام وثلاثة أرباع وجانب وخلف، ترفقها مع كل لوحة فيبقى الوجه والجسم والحجم نفسه في مئات الإطارات.')
W('- **الكرة تدور بـ12 إطاراً**، وتنضغط لحظة الركلة. **الشبكة تنتفخ بـ9 إطارات**، والقائم يهتز، والرايات ترفرف.')
W('- **المؤثرات حلقات متكررة:** المطر، والثلج، والضباب، والشماريخ، والدخان، والقصاصات، والجمهور الأمامي يقفز ويلوّح.\n')
W('## طريقة العمل\n')
W('**الترتيب بالدفعات:** لا تصنع الكتاب جزءاً جزءاً. اتبع `00-waves.md`: الدفعة 1 (أول عنصر من كل قسم) صوراً ثم محاكاة ثم اعتماد، ثم الدفعة 2، وهكذا.\n')
W('1. **ابدأ كل شخصية ببطاقتها المرجعية** (`ref.png`)، ولا ترفق معها شيئاً.')
W('2. **كل مجموعة حركة في محادثة جديدة.** ارفق مع أول لوحة فيها البطاقة المرجعية.')
W('   **المرفقات مكتوبة بأسمائها عند كل لوحة** (مثل «ارفق: `art/raw/striker/ref.png` و`art/raw/striker/run/run-side-01.png`»): ارفق هذه الملفات بالضبط، فهي صور صنعتها قبلها.')
W('3. **من اللوحة الثانية في كل سلسلة:** ارفق البطاقة المرجعية **واللوحة السابقة** معاً، فيكمل الحركة من حيث توقفت بنفس الحجم ونفس خط الأرض.')
W('4. **الملاعب:** أول صورة بلا مرفق، والباقي ترفق معه الأولى. وحالات الملعب (مطر، ثلج...) ترفق معها `shot.jpg` من حالته الأساسية.')
W('5. **احفظ كل لوحة باسمها المكتوب** داخل مجلدها، ولا تقصها.')
W('6. **أرسل لي أول 3 لوحات من كل نوع جديد** قبل أن تكمله. أو ارفع مجلد `art` على GitHub: **Add file** ← **Upload files** ← **Commit directly to the main branch**.\n')
W('## قبل حفظ كل لوحة\n')
W('- [ ] عدد الإطارات صحيح، بالترتيب من اليسار إلى اليمين.')
W('- [ ] عدد الأشخاص والعناصر كما يذكر الأمر بالضبط، ولا كرة في صور الشخصيات (اللعبة ترسم الكرة).')
W('- [ ] كل إطار يتقدم قليلاً عن الذي قبله، لا قفزة كبيرة ولا تكرار.')
W('- [ ] الحجم نفسه وخط الأرض نفسه في كل الإطارات وفي كل لوحات السلسلة.')
W('- [ ] الجسم كامل، والتشريح طبيعي: الركبة تنثني للأمام، ولا طرف مكسور أو ملتوٍ، وخمسة أصابع.')
W('- [ ] نفس الوجه والجسم كما في البطاقة المرجعية.')
W('- [ ] القميص أبيض، والخلفية خضراء مصمتة (أو وردية أو سوداء حين يُطلب ذلك).\n')
W('## جمل التصحيح (في نفس المحادثة)\n')
W('| المشكلة | الجملة |')
W('|---|---|')
W('| إطار خاطئ | `Redo only the right frame: the leg looks unnatural. Keep the other frames the same.` |')
W('| قفزة بين الإطارات | `The frames jump too much. Redo them so each frame moves on only slightly from the previous one.` |')
W('| الحجم تغيّر | `Redo it at exactly the same scale and on the same ground line as the attached previous frames.` |')
W('| وجه مختلف | `The face must be exactly the same person as in the attached reference card. Redo it.` |')
W('| الخلفية ليست خضراء | `Same image, but on a flat solid chroma-key green background (#00FF00).` |')
W('| القميص ملوّن | `Same image, but the kit must be pure white.` |')
W('| الصورة مربعة | `Make it a wide 3:2 landscape image.` (والملاعب: `16:9`) |')
W('| ناس في صورة الملعب | `Same image, but with the pitch completely empty.` |')
W('| كتابة على شاشة | `Same image, but every screen must be blank and dark.` |\n')
W('## مراحل الإنتاج\n')
W('| المرحلة | ما تصنعه | ما يصبح جاهزاً |')
W('|---|---|---|')
W('| 1 | الأرينا ليلاً، المهاجم الرئيسي (كل مجموعاته)، حارس المرمى 1، الكرة الكلاسيكية، المرمى العادي | الهدف، والتصدي، والفرصة الضائعة، وركلة الجزاء، بحركة كاملة |')
W('| 2 | المدافع، الجناح، لاعب الوسط، الحكم 1، الحكم المساعد، البطاقات، الفار | البطاقات، والتسلل، والضربة الحرة، والركنية، والمرتدة، والفار |')
W('| 3 | المدربان الأول والثاني، الحكم الرابع، الدكة، اللحظات الجماعية، الاحتفالات | التبديل، والإصابة، والاحتفالات، والبداية والنهاية |')
W('| 4 | الجمهور، البث المباشر، المؤثرات المتحركة، الرايات | الأجواء، والشاشات، والطقس |')
W('| 5 | الملاعب الأخرى وحالاتها | تنوع الملاعب |')
W('| 6 | أشكال اللاعبين، الحراس والحكام والمدربون الآخرون، الكرات والمرامي الأخرى | تنوع الوجوه بين الأندية |\n')
W('## كل لقطة وما تحتاجه\n')
W('| اللقطة | الاسم | زوايا الملعب | الصور |')
W('|---|---|---|---|')
for m in MAP: W(f'| {m[0]} | {m[1]} | {m[2]} | {m[3]} |')
W('\nالمقاطع من L23 إلى L33 جديدة: صورها هنا، وأحداثها في المحرك تُضاف لاحقاً بقرار منك.\n')
W('## الأجزاء\n')
W('| الملف | الجزء | المجموعات | اللوحات |')
W('|---|---|---|---|')
for p in parts:
    gs = [g for g in ALLB if g['part'] == p]
    W(f'| `{fname[p]}` | {PN[p]} | {len(gs)} | {sum(len(g["boards"]) for g in gs)} |')
W(f'\n**المجموع:** {len(ALLB)} مجموعة، {total} لوحة.')
open(f'{OUT}/00-guide.md', 'w').write('\n'.join(o) + '\n')

gi = 0
for p in parts:
    o = []; W = o.append
    gs = [g for g in ALLB if g['part'] == p]
    W(f'# {PN[p]}\n')
    W(f'{len(gs)} مجموعة، {sum(len(g["boards"]) for g in gs)} لوحة. طريقة العمل وجمل التصحيح في `00-guide.md`.\n')
    W('## الفهرس\n')
    start = gi
    for g in gs:
        start += 1; W(f'{start}. {g["t"]} ({len(g["boards"])} لوحة)')
    W('\n---\n')
    for g in gs:
        gi += 1
        W(f'## المجموعة {gi}: {g["t"]}\n')
        W(f'**الدفعة {g["wave"]}** ({sprint_of(g["wave"])})  ')
        W(f'**المجلد:** `{g["folder"]}`  ')
        W(f'**المحادثة:** جديدة. {g["note"]}\n')
        for j, b in enumerate(g['boards'], 1):
            W(f'### {gi}.{j} `{b["f"]}`\n')
            what = b.get('why') or b.get('names')
            extra = f' · **تُستخدم في:** {b["used"]}' if b.get('used') else ''
            W(f'{what}{extra}  ')
            W(f'{attach_md(b)}\n')
            W('```\n' + b['p'] + '\n```\n')
    open(f'{OUT}/{fname[p]}', 'w').write('\n'.join(o) + '\n')
print(len(ALLB), total, parts)

# 00-waves.md: what to make in each wave, with where to find its prompts
gnum = {id(g): i for i, g in enumerate(ALLB, 1)}
o = ['# الدفعات: ترتيب صنع الصور\n',
     'نصنع **أول عنصر من كل قسم** (ملعب، ولاعب، وحارس، وحكم، ومدرب، وكرة، ومرمى، ومؤثرات، وجمهور) فنضعه في المحاكاة ونتأكد أنه ممتاز، ثم **الثاني من كل قسم**، وهكذا حتى تكتمل كل الأقسام. '
     'كل دفعة قطعة قابلة للعب: بعد أن تكتمل صورها نبني بها لقطات المحاكاة ونجربها، ولا نبدأ الدفعة التالية قبل اعتماد هذه.\n',
     '## دورة كل دفعة\n',
     '1. **الصور:** صاحب المشروع يصنع مجموعات الدفعة بـ Gemini ويرفعها إلى مجلداتها.',
     '2. **الفحص:** Claude يراجع كل صورة، ويعطي جملة تصحيح لكل خطأ، حتى تُعتمد كلها.',
     '3. **المحاكاة:** Claude يقصها ويجهزها ويضعها في لقطات المحاكي على الكمبيوتر والجوال.',
     '4. **التجربة:** مباراة كاملة بالدفعة الجديدة، والملاحظات في ملف السبرنت.',
     '5. **الاعتماد:** صاحب المشروع يعتمد، فتبدأ الدفعة التالية.\n',
     '**الشخصيات:** في دفعتها الأولى تأخذ حركاتها الأساسية (البطاقة المرجعية، والجري، والكرة أو الارتماء، والسقوط، والمشاعر)، وباقي حركاتها في الدفعة التالية. والملعب في دفعته الأولى بكل زواياه، وحالاته الأخرى في الدفعة التالية.\n',
     '## ملخص الدفعات\n', '| الدفعة | السبرنت | المجموعات | اللوحات |', '|---|---|---|---|']
for w in WAVES:
    gs = [g for g in ALLB if g['wave'] == w]
    o.append(f'| {w} | {sprint_of(w)} | {len(gs)} | {sum(len(g["boards"]) for g in gs)} |')
o.append('')
for w in WAVES:
    gs = [g for g in ALLB if g['wave'] == w]
    o += [f'## الدفعة {w} ({sprint_of(w)})\n', '| القسم | المجموعة | اللوحات | الملف | المجلد |', '|---|---|---|---|---|']
    for g in gs:
        o.append(f'| {PN[g["part"]].split(": ", 1)[1]} | {gnum[id(g)]}. {g["t"]} | {len(g["boards"])} | [`{fname[g["part"]]}`]({fname[g["part"]]}) | `{g["folder"]}` |')
    o.append('')
open(os.path.join(OUT, '00-waves.md'), 'w').write('\n'.join(o) + '\n')

# a README in every folder of art/raw/ naming the boards that go in it
RAW = os.path.join('..', '..', 'art', 'raw')
folders = {}
gi = 0
for p in parts:
    for g in [g for g in ALLB if g['part'] == p]:
        gi += 1
        folders.setdefault(g['folder'], []).append((gi, g, fname[p]))
for folder, entries in folders.items():
    path = os.path.join('..', '..', folder)
    os.makedirs(path, exist_ok=True)
    o = [f'# {" · ".join(g["t"] for _, g, _ in entries)}\n',
         'احفظ هنا كل لوحة باسمها كما هي (لا تقصها). أوامرها في '
         + '، '.join(f'`docs/art/images/{f}` (المجموعة {i})' for i, _, f in entries) + '.\n',
         f'**الدفعة:** {min(g["wave"] for _, g, _ in entries)}.\n',
         '| الملف | المحتوى | المرفق |', '|---|---|---|']
    for _, g, _ in entries:
        for b in g['boards']:
            att = ' و'.join(f'`{x}`' for x in b['attach']) if b['attach'] else 'بلا مرفق'
            o.append(f'| `{b["f"]}` | {b.get("why") or b.get("names")} | {att} |')
    open(os.path.join(path, 'README.md'), 'w').write('\n'.join(o) + '\n')
idx = ['# الصور الخام\n', f'**{len(folders)} مجلداً.** كل مجلد فيه `README.md` بأسماء لوحاته. الشرح في `docs/art/images/00-guide.md`، وترتيب الصنع بالدفعات في `docs/art/images/00-waves.md`.\n',
       '| الدفعة | المجلد | المحتوى | اللوحات |', '|---|---|---|---|']
for folder, entries in sorted(folders.items(), key=lambda kv: (min(g['wave'] for _, g, _ in kv[1]), kv[0])):
    idx.append(f'| {min(g["wave"] for _, g, _ in entries)} | `{folder[len("art/raw/"):]}` | {" · ".join(g["t"] for _, g, _ in entries)} | {sum(len(g["boards"]) for _, g, _ in entries)} |')
open(os.path.join(RAW, 'README.md'), 'w').write('\n'.join(idx) + '\n')
print(len(folders), 'folders')
