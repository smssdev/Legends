"""Sprint 07 U3: the moves no free library has, keyframed on our own rig (the game engine rig of every Legends player).

  blender -b -P tools/unity/players/keyframes.py -- [--moves keeper_dive_l_high,...] [--sheet]  [--no-export]

A pose is written as where each bone points, seen from the player (left, forward, up), and how the whole body leans,
tilts, turns and how high it is: the script turns that into rotations on the rig, bone by bone from the hips out, so
no limb ever leaves the body and a pose reads like a sentence. The legs of a grounded pose are written as the ground
sees them (they do not lean with the body), and its feet are put back on the grass. A move is a list of poses at
times; Blender eases between them.

Writes every move as one take of unity/Assets/Legends/Animation/Moves/moves.fbx (the rig only: Unity plays the takes
on every build through the Humanoid avatar), and with --sheet a picture of each move at its poses to
unity/Reference/moves/<move>.jpg, to judge it before Unity does.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'art'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Matrix, Quaternion, Vector

import build_players as bp
import common as c
import kit as kits
import mocap

FPS = 30
OUT = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Animation', 'Moves', 'moves.fbx')
# each stride's natural speed (m/s) and length, for Unity to play it at the pace the player really goes
SPEEDS = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Animation', 'Moves', 'locomotion.json')
# [U2] each move that plays once from motion capture: its length, the contact and kicking foot of a kick, its speed in
# and out, how far it turns him
TAKES = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Animation', 'Moves', 'takes.json')
SHEETS = os.path.join(c.ROOT, 'unity', 'Reference', 'moves')
# from the hips out: a bone is aimed once its parent has its pose
ORDER = ['spine_01', 'spine_02', 'spine_03', 'neck_01', 'head',
         'clavicle_l', 'upperarm_l', 'lowerarm_l', 'hand_l', 'clavicle_r', 'upperarm_r', 'lowerarm_r', 'hand_r',
         'thigh_l', 'calf_l', 'foot_l', 'ball_l', 'thigh_r', 'calf_r', 'foot_r', 'ball_r']
LEGS = ('thigh', 'calf', 'foot', 'ball')


def d(left, fwd, up):
    """A direction seen from the player: to his left, forward, up. The rig faces -Y with his left at +X."""
    return Vector((left, -fwd, up)).normalized()


def mirror(pose):
    """The same pose to his other side: left and right bones swapped, every direction and tilt mirrored."""
    swap = lambda n: n[:-1] + ('r' if n.endswith('_l') else 'l') if n.endswith(('_l', '_r')) else n
    out = dict(pose)
    out['bones'] = {swap(k): (-v[0], v[1], v[2]) for k, v in pose.get('bones', {}).items()}
    out['side'] = -pose.get('side', 0)
    out['turn'] = -pose.get('turn', 0)
    if 'shift' in pose:
        out['shift'] = (-pose['shift'][0], pose['shift'][1])
    return out


# ------------------------------------------------------------------ the poses
# lean: forward (degrees), side: tilt towards his left, turn: towards his left; height: the hips in metres (None:
# the feet on the grass); shift: the hips moved (left, forward) in metres; bones: where each points (left, fwd, up).

STAND = {}
# The keeper's set position: knees bent, weight forward, hands out low and open, as before every shot.
READY = {'lean': 24, 'bones': {
    'thigh_l': (0.25, 0.62, -0.74), 'calf_l': (0.04, -0.42, -0.9), 'foot_l': (0.15, 0.92, -0.35),
    'thigh_r': (-0.25, 0.62, -0.74), 'calf_r': (-0.04, -0.42, -0.9), 'foot_r': (-0.15, 0.92, -0.35),
    'spine_03': (0, 0.12, 1), 'neck_01': (0, -0.2, 1), 'head': (0, -0.35, 1),
    'upperarm_l': (0.5, 0.55, -0.65), 'lowerarm_l': (0.3, 0.9, -0.25), 'hand_l': (0.2, 0.95, -0.1),
    'upperarm_r': (-0.5, 0.55, -0.65), 'lowerarm_r': (-0.3, 0.9, -0.25), 'hand_r': (-0.2, 0.95, -0.1),
}}
# A dive to his left. Loading: a short step that way, the far knee bent deep, arms swinging up.
DIVE_LOAD_L = {'lean': 12, 'side': -8, 'shift': (0.25, 0), 'bones': {
    'thigh_l': (0.45, 0.35, -0.82), 'calf_l': (-0.05, -0.3, -0.95), 'foot_l': (0.3, 0.85, -0.4),
    'thigh_r': (-0.1, 0.45, -0.88), 'calf_r': (-0.2, -0.2, -0.96), 'foot_r': (-0.1, 0.9, -0.4),
    'spine_03': (0.15, 0.1, 1),
    'upperarm_l': (0.8, 0.4, 0.1), 'lowerarm_l': (0.6, 0.6, 0.4), 'hand_l': (0.5, 0.5, 0.6),
    'upperarm_r': (0.1, 0.7, -0.2), 'lowerarm_r': (0.4, 0.8, 0.2), 'hand_r': (0.4, 0.7, 0.4),
}}
# Full stretch, high: the body flat in the air, both arms past his head towards the top corner, legs together.
DIVE_HIGH_L = {'side': 78, 'lean': 8, 'height': 1.15, 'shift': (1.55, 0.1), 'legs': 'body', 'bones': {
    'spine_03': (0.05, 0.05, 1), 'head': (0.15, 0.1, 1),
    'upperarm_l': (0.15, 0.25, 1), 'lowerarm_l': (0.05, 0.2, 1), 'hand_l': (0, 0.25, 1),
    'upperarm_r': (-0.05, 0.3, 1), 'lowerarm_r': (0.05, 0.25, 1), 'hand_r': (0.05, 0.3, 1),
    'thigh_l': (0.1, 0.05, -1), 'calf_l': (0.08, -0.1, -1), 'foot_l': (0.05, 0.6, -0.8),
    'thigh_r': (-0.05, 0.2, -1), 'calf_r': (-0.05, -0.25, -1), 'foot_r': (0, 0.6, -0.8),
}}
# Full stretch, low: flatter and lower, the arms along the grass towards the post.
DIVE_LOW_L = {'side': 84, 'lean': 4, 'height': 0.42, 'shift': (1.45, 0.15), 'legs': 'body', 'bones': {
    'spine_03': (0.05, 0.1, 1), 'head': (0.1, 0.2, 1),
    'upperarm_l': (0.3, 0.35, 0.9), 'lowerarm_l': (0.2, 0.3, 0.95), 'hand_l': (0.15, 0.3, 0.95),
    'upperarm_r': (0.1, 0.55, 0.85), 'lowerarm_r': (0.2, 0.45, 0.9), 'hand_r': (0.2, 0.45, 0.9),
    'thigh_l': (0.05, 0.15, -1), 'calf_l': (0.05, -0.2, -1), 'foot_l': (0.05, 0.6, -0.8),
    'thigh_r': (-0.05, 0.3, -1), 'calf_r': (-0.05, -0.3, -1), 'foot_r': (0, 0.6, -0.8),
}}
# On the grass on his side, the ball gathered to his chest, knees drawn up.
DIVE_LAND_L = {'side': 88, 'lean': 10, 'height': 0.16, 'shift': (1.85, 0.1), 'legs': 'body', 'bones': {
    'spine_03': (0, 0.2, 1), 'head': (-0.1, 0.35, 1),
    'upperarm_l': (0.2, 0.9, 0.3), 'lowerarm_l': (-0.6, 0.6, 0.1), 'hand_l': (-0.7, 0.5, 0.1),
    'upperarm_r': (-0.2, 0.9, 0.1), 'lowerarm_r': (0.6, 0.6, 0.2), 'hand_r': (0.7, 0.5, 0.1),
    'thigh_l': (0.05, 0.55, -0.83), 'calf_l': (0, -0.4, -0.9), 'foot_l': (0, 0.7, -0.7),
    'thigh_r': (-0.05, 0.75, -0.66), 'calf_r': (0, -0.2, -0.98), 'foot_r': (0, 0.7, -0.7),
}}

# Standing at ease: the arms down by the sides (the rig rests in an A, arms out).
IDLE = {'bones': {
    'upperarm_l': (0.14, 0.02, -1), 'lowerarm_l': (0.06, 0.18, -1), 'hand_l': (0.03, 0.12, -1),
    'upperarm_r': (-0.14, 0.02, -1), 'lowerarm_r': (-0.06, 0.18, -1), 'hand_r': (-0.03, 0.12, -1),
}}


def pose(base, **change):
    """A pose from another: its bones with these replaced, and its body with these set."""
    bones = {**base.get('bones', {}), **change.pop('bones', {})}
    return {**base, **change, 'bones': bones}


def arms(l=None, r=None):
    """Both arms' three bones at once: each a (upperarm, lowerarm, hand) of directions; the right one mirrored when
    only the left is given."""
    r = r or tuple((-x, y, z) for x, y, z in l)
    return {'upperarm_l': l[0], 'lowerarm_l': l[1], 'hand_l': l[2], 'upperarm_r': r[0], 'lowerarm_r': r[1], 'hand_r': r[2]}


# The keeper: reaching for a ball at him, gathering it to his chest; punching it away with both fists.
REACH = pose(READY, lean=20, bones=arms(((0.15, 0.95, -0.25), (0.06, 1, -0.05), (0.02, 1, 0.05))))
GATHER = pose(READY, lean=8, bones=arms(((0.3, 0.45, -0.85), (-0.65, 0.7, 0.3), (-0.6, 0.5, 0.6))))
FISTS = pose(READY, lean=10, bones=arms(((0.25, 0.4, -0.88), (0.1, 0.4, 0.9), (0.05, 0.3, 0.95))))
PUNCH = pose(READY, lean=-6, bones=arms(((0.1, 0.45, 0.88), (0.06, 0.4, 0.92), (0.04, 0.4, 0.92))))

# A goal. The aeroplane: arms out like wings, banking one way then the other.
WINGS = pose(IDLE, lean=8, bones=arms(((1, 0.12, 0.15), (1, 0.15, 0.2), (1, 0.15, 0.2))))
# The fist pump: the right fist up by his face, then pulled down hard, knees bent, a shout to the sky.
FIST_UP = pose(IDLE, bones={
    'upperarm_r': (-0.35, 0.25, -0.9), 'lowerarm_r': (-0.15, 0.45, 0.88), 'hand_r': (-0.1, 0.4, 0.9)})
FIST_PUMP = pose(IDLE, lean=12, bones={
    'thigh_l': (0.15, 0.45, -0.88), 'calf_l': (0.03, -0.35, -0.93), 'foot_l': (0.1, 0.92, -0.35),
    'thigh_r': (-0.15, 0.45, -0.88), 'calf_r': (-0.03, -0.35, -0.93), 'foot_r': (-0.1, 0.92, -0.35),
    'upperarm_r': (-0.3, 0.35, -0.89), 'lowerarm_r': (-0.2, 0.85, 0.45), 'hand_r': (-0.15, 0.85, 0.5),
    'upperarm_l': (0.35, 0.3, -0.88), 'lowerarm_l': (0.2, 0.75, -0.2), 'hand_l': (0.15, 0.8, -0.1)})
SHOUT = pose(IDLE, lean=-14, bones={
    'neck_01': (0, -0.35, 1), 'head': (0, -0.5, 0.85),
    'upperarm_r': (-0.45, 0.1, -0.88), 'lowerarm_r': (-0.2, 0.5, 0.85), 'hand_r': (-0.15, 0.45, 0.88),
    'upperarm_l': (0.45, 0.1, -0.88), 'lowerarm_l': (0.2, 0.5, 0.85), 'hand_l': (0.15, 0.45, 0.88)})
# The knee slide: down on both knees, leaning back, arms wide to the crowd.
KNEES = {'lean': -22, 'height': 0.62, 'bones': {
    'thigh_l': (0.18, 0.2, -0.97), 'calf_l': (0.06, -1, -0.04), 'foot_l': (0.03, -0.25, -0.97),
    'thigh_r': (-0.18, 0.2, -0.97), 'calf_r': (-0.06, -1, -0.04), 'foot_r': (-0.03, -0.25, -0.97),
    'neck_01': (0, -0.2, 1), 'head': (0, -0.35, 0.95),
    **arms(((0.85, 0.15, 0.45), (0.85, 0.2, 0.5), (0.8, 0.2, 0.55)))}}

# A chance gone: both hands on the head, leaning back, looking at the sky.
HANDS_ON_HEAD = pose(IDLE, lean=-6, bones={'neck_01': (0, -0.12, 1), 'head': (0, -0.18, 1),
    **arms(((0.8, -0.1, 0.58), (-0.92, -0.05, 0.38), (-0.85, -0.1, -0.3)))})   # elbows out, palms on the crown
# A protest at the referee: arms out, palms up, leaning in.
PROTEST = pose(IDLE, lean=12, bones={'head': (0, 0.1, 1), **arms(((0.5, 0.45, -0.74), (0.4, 0.9, 0.15), (0.35, 0.9, 0.2)))})
# Walking off after a red card or a defeat: head down, shoulders in, arms hanging.
SLUMP = pose(IDLE, lean=6, bones={'spine_03': (0, 0.3, 1), 'neck_01': (0, 0.45, 0.9), 'head': (0, 0.75, 0.66),
    **arms(((0.08, 0.15, -1), (0.03, 0.25, -1), (0.02, 0.2, -1)))})

# The referee: the card held straight up; pointing to the spot; the whistle to his mouth then the arm out for a free
# kick. The assistant's flag straight up (offside).
CARD_DRAW = pose(IDLE, bones={'upperarm_r': (-0.3, 0.5, -0.8), 'lowerarm_r': (0.55, 0.6, 0.55), 'hand_r': (0.5, 0.5, 0.7)})
CARD_UP = pose(IDLE, lean=-3, bones={'upperarm_r': (-0.1, 0.12, 1), 'lowerarm_r': (-0.06, 0.1, 1), 'hand_r': (-0.04, 0.08, 1),
    'head': (0, 0.2, 1)})
POINT_SPOT = pose(IDLE, lean=4, bones={'upperarm_r': (-0.25, 0.85, -0.45), 'lowerarm_r': (-0.22, 0.88, -0.42), 'hand_r': (-0.2, 0.9, -0.4)})
WHISTLE = pose(IDLE, bones={'upperarm_r': (-0.4, 0.45, -0.8), 'lowerarm_r': (0.5, 0.45, 0.75), 'hand_r': (0.55, 0.35, 0.75)})
ARM_OUT = pose(IDLE, bones={'upperarm_r': (-0.55, 0.75, 0.35), 'lowerarm_r': (-0.5, 0.78, 0.38), 'hand_r': (-0.5, 0.8, 0.35)})

# [U2] The three ball moves no clip we have holds, made here: the jumping header, the slide tackle, the fall.
# A header: down on bent knees, up off both feet arched back with the arms out, the head snapped through the ball at the
# top, and down again on bent knees.
CROUCH = pose(IDLE, lean=14, bones={
    'thigh_l': (0.12, 0.55, -0.83), 'calf_l': (0.03, -0.45, -0.89), 'foot_l': (0.08, 0.92, -0.38),
    'thigh_r': (-0.12, 0.55, -0.83), 'calf_r': (-0.03, -0.45, -0.89), 'foot_r': (-0.08, 0.92, -0.38),
    **arms(((0.25, -0.45, -0.86), (0.2, -0.3, -0.93), (0.15, -0.25, -0.95)))})
RISE = pose(IDLE, lean=-14, height=1.3, bones={
    'neck_01': (0, -0.25, 1), 'head': (0, -0.4, 0.9),
    'thigh_l': (0.08, -0.05, -1), 'calf_l': (0.04, -0.3, -0.95), 'foot_l': (0.05, 0.3, -0.95),
    'thigh_r': (-0.08, 0.1, -1), 'calf_r': (-0.04, -0.35, -0.94), 'foot_r': (-0.05, 0.3, -0.95),
    **arms(((0.8, 0.55, -0.1), (0.5, 0.85, 0.05), (0.45, 0.88, 0.05)))})
HEAD_IT = pose(RISE, lean=16, height=1.38, bones={
    'neck_01': (0, 0.3, 1), 'head': (0, 0.55, 0.85),
    'thigh_l': (0.08, -0.25, -0.97), 'calf_l': (0.04, -0.55, -0.83), 'foot_l': (0.05, 0.1, -1),
    'thigh_r': (-0.08, -0.2, -0.98), 'calf_r': (-0.04, -0.5, -0.86), 'foot_r': (-0.05, 0.1, -1),
    **arms(((0.9, -0.1, 0.1), (0.75, 0.55, 0.05), (0.7, 0.6, 0.05)))})
FALLING = pose(HEAD_IT, lean=4, height=1.12, bones={'head': (0, 0.2, 1),
    **arms(((0.75, 0.3, -0.55), (0.5, 0.75, -0.3), (0.45, 0.8, -0.3)))})
LANDED = pose(CROUCH, lean=10, bones=arms(((0.4, 0.3, -0.86), (0.3, 0.55, -0.78), (0.25, 0.55, -0.8))))

# A slide tackle on his left side: down onto the left hip, the right leg out straight along the grass at the ball (its
# studs up), the left folded under him, the left hand on the grass behind, the right arm out for balance; then up.
# The legs as the ground sees them (the body leans back over them).
SLIDE_DROP = pose(IDLE, lean=-8, side=12, height=0.74, shift=(0, 0.45), bones={
    'thigh_r': (-0.05, 0.75, -0.66), 'calf_r': (0, 0.55, -0.83), 'foot_r': (0, 0.85, -0.5),
    'thigh_l': (0.3, 0.4, -0.86), 'calf_l': (0.1, -0.7, -0.7), 'foot_l': (0.05, 0.3, -0.95),
    **arms(((0.6, -0.3, -0.75), (0.5, -0.4, -0.75), (0.4, -0.4, -0.8)), ((-0.8, 0.4, 0.2), (-0.7, 0.6, 0.2), (-0.6, 0.7, 0.2)))})
SLIDE = pose(IDLE, lean=-38, side=22, height=0.34, shift=(0, 1.15), bones={
    'neck_01': (0, 0.35, 1), 'head': (0, 0.6, 0.8),
    'thigh_r': (-0.05, 0.92, -0.38), 'calf_r': (0, 0.99, -0.12), 'foot_r': (0, 0.45, 0.89),
    'thigh_l': (0.45, 0.83, -0.33), 'calf_l': (0.12, -0.99, -0.05), 'foot_l': (0, -0.95, -0.3),
    **arms(((0.55, -0.55, -0.62), (0.4, -0.55, -0.73), (0.3, -0.5, -0.81)), ((-0.85, 0.35, 0.35), (-0.7, 0.6, 0.35), (-0.6, 0.7, 0.3)))})
SLIDE_STILL = pose(SLIDE, lean=-30, height=0.33, shift=(0, 1.6))
SLIDE_RISE = pose(CROUCH, lean=28, shift=(0, 1.65), bones={
    **arms(((0.5, 0.2, -0.85), (0.3, 0.45, -0.84), (0.25, 0.45, -0.86)))})

# A fall when he is fouled: a stumble with the leg clipped behind him, the arms thrown out to catch himself, flat on
# his front on the grass, then the head up to look for the referee (the free kick is his).
STUMBLE = pose(IDLE, lean=28, shift=(0, 0.3), bones={
    'thigh_r': (-0.05, -0.55, -0.83), 'calf_r': (-0.03, -0.85, -0.5), 'foot_r': (0, -0.2, -0.98),
    'thigh_l': (0.08, 0.35, -0.94), 'calf_l': (0.03, -0.25, -0.97), 'foot_l': (0.05, 0.92, -0.38),
    **arms(((0.6, 0.6, -0.5), (0.4, 0.85, -0.3), (0.35, 0.85, -0.4)))})
GOING_DOWN = pose(IDLE, lean=62, height=0.62, shift=(0, 0.95), legs='body', bones={
    'thigh_r': (-0.05, -0.35, -0.94), 'calf_r': (-0.03, -0.6, -0.8), 'foot_r': (0, -0.95, -0.3),
    'thigh_l': (0.08, 0.05, -1), 'calf_l': (0.03, -0.3, -0.95), 'foot_l': (0.05, -0.6, -0.8),
    **arms(((0.35, 0.94, 0.0), (0.25, 0.96, 0.1), (0.2, 0.97, 0.1)))})
DOWN = pose(IDLE, lean=86, height=0.17, shift=(0, 1.45), legs='body', bones={
    'neck_01': (0, -0.2, 1), 'head': (0, -0.35, 0.95),
    'thigh_r': (-0.08, -0.1, -1), 'calf_r': (-0.05, -0.15, -1), 'foot_r': (0, -0.9, -0.4),
    'thigh_l': (0.12, -0.05, -1), 'calf_l': (0.05, -0.1, -1), 'foot_l': (0, -0.9, -0.4),
    **arms(((0.9, 0.15, 0.4), (0.3, -0.2, 0.93), (0.2, -0.3, 0.93)))})
HURT = pose(DOWN, lean=78, bones={
    'neck_01': (0, -0.45, 0.9), 'head': (0, -0.65, 0.75),
    'thigh_r': (-0.08, 0.35, -0.94), 'calf_r': (-0.05, -0.7, -0.7),
    **arms(((0.9, 0.15, 0.4), (0.3, -0.2, 0.93), (0.2, -0.3, 0.93)), ((-0.3, 0.1, -0.95), (-0.1, 0.6, -0.8), (-0.05, 0.7, -0.7)))})

MOVES = {
    'idle': [(0.0, IDLE), (2.0, IDLE)],
    'header': [(0.0, IDLE), (0.2, CROUCH), (0.34, RISE), (0.46, HEAD_IT), (0.68, FALLING), (0.86, LANDED), (1.3, IDLE)],
    'slide_tackle': [(0.0, pose(IDLE, lean=14)), (0.22, SLIDE_DROP), (0.45, SLIDE), (0.95, SLIDE_STILL), (1.3, SLIDE_RISE), (1.7, pose(IDLE, shift=(0, 1.65)))],
    'fall': [(0.0, pose(IDLE, lean=14)), (0.2, STUMBLE), (0.45, GOING_DOWN), (0.72, DOWN), (1.2, HURT), (2.0, HURT)],
    'keeper_catch': [(0.0, READY), (0.25, REACH), (0.55, GATHER), (1.1, pose(GATHER, lean=4))],
    'keeper_punch': [(0.0, READY), (0.18, FISTS), (0.38, PUNCH), (0.85, READY)],
    'celebrate_wings': [(0.0, IDLE), (0.3, pose(WINGS, side=14)), (0.85, pose(WINGS, side=-14)), (1.4, pose(WINGS, side=14)), (1.95, pose(WINGS, side=-14))],
    'celebrate_fist': [(0.0, IDLE), (0.25, FIST_UP), (0.45, FIST_PUMP), (0.9, FIST_PUMP), (1.4, SHOUT), (2.0, SHOUT)],
    'celebrate_knee_slide': [(0.0, IDLE), (0.35, KNEES), (1.3, pose(KNEES, lean=-28)), (2.0, pose(KNEES, lean=-28))],
    'despair_hands_head': [(0.0, IDLE), (0.4, HANDS_ON_HEAD), (1.4, pose(HANDS_ON_HEAD, lean=-12)), (2.0, HANDS_ON_HEAD)],
    'protest': [(0.0, IDLE), (0.35, PROTEST), (0.8, pose(PROTEST, lean=16)), (1.4, PROTEST)],
    'walk_off_sad': [(0.0, IDLE), (0.6, SLUMP), (2.0, SLUMP)],
    'ref_card': [(0.0, IDLE), (0.3, CARD_DRAW), (0.6, CARD_UP), (1.8, CARD_UP)],
    'ref_point_spot': [(0.0, IDLE), (0.4, POINT_SPOT), (1.5, POINT_SPOT)],
    'ref_whistle_free_kick': [(0.0, IDLE), (0.25, WHISTLE), (0.6, WHISTLE), (0.9, ARM_OUT), (1.6, ARM_OUT)],
    'assistant_flag_up': [(0.0, IDLE), (0.35, CARD_UP), (1.6, CARD_UP)],
    'keeper_ready': [(0.0, READY), (1.0, {**READY, 'lean': 20}), (2.0, READY)],
    'keeper_dive_l_high': [(0.0, READY), (0.22, DIVE_LOAD_L), (0.62, DIVE_HIGH_L), (1.05, DIVE_LAND_L), (1.6, DIVE_LAND_L)],
    'keeper_dive_l_low': [(0.0, READY), (0.2, DIVE_LOAD_L), (0.5, DIVE_LOW_L), (0.85, DIVE_LAND_L), (1.4, DIVE_LAND_L)],
}
MOVES['keeper_dive_r_high'] = [(t, mirror(p)) for t, p in MOVES['keeper_dive_l_high']]
MOVES['keeper_dive_r_low'] = [(t, mirror(p)) for t, p in MOVES['keeper_dive_l_low']]
MOVES['slide_tackle_l'] = [(t, mirror(p)) for t, p in MOVES['slide_tackle']]
# [U2] What Unity needs to time the ball moves we make (as takes.json gives for those from motion capture): the
# instant the ball is met, and with what.
CONTACTS = {
    'header': {'contact': 0.46, 'foot': 'head'},
    'slide_tackle': {'contact': 0.45, 'foot': 'right'},
    'slide_tackle_l': {'contact': 0.45, 'foot': 'left'},
    'fall': {},
    # the keeper's hands meet the ball at full stretch, at the reach, at the punch
    'keeper_dive_l_high': {'contact': 0.62, 'foot': 'hands'},
    'keeper_dive_r_high': {'contact': 0.62, 'foot': 'hands'},
    'keeper_dive_l_low': {'contact': 0.5, 'foot': 'hands'},
    'keeper_dive_r_low': {'contact': 0.5, 'foot': 'hands'},
    'keeper_catch': {'contact': 0.25, 'foot': 'hands'},
    'keeper_punch': {'contact': 0.38, 'foot': 'hands'},
}


# ------------------------------------------------------------------ poses onto the rig

def update():
    bpy.context.view_layer.update()


def place(rig, pose):
    """Puts the rig in the pose (armature space), from the rest pose."""
    for pb in rig.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    update()
    # mocap.py gives the hips' turn itself (q) and every direction as the scene sees it (frame: world)
    q = pose.get('q') or (Quaternion((0, 0, 1), math.radians(pose.get('turn', 0)))
                          @ Quaternion((0, 1, 0), math.radians(pose.get('side', 0)))
                          @ Quaternion((1, 0, 0), math.radians(pose.get('lean', 0))))
    world = pose.get('frame') == 'world'
    ground = Quaternion((0, 0, 1), math.radians(pose.get('turn', 0)))
    legs_in_body = pose.get('legs') == 'body'
    pelvis = rig.pose.bones['pelvis']
    m = pelvis.matrix.copy()
    sl, sf = pose.get('shift', (0, 0))
    at = m.translation + Vector((sl, -sf, 0))
    if pose.get('at'):
        ax, ay, az = pose['at']
        at = m.translation + Vector((ax, ay, 0))
        if az is not None:
            at.z = az
    if pose.get('height') is not None:
        at.z = pose['height']
    # the hips turn about their own head; spine and legs follow
    pelvis.matrix = Matrix.LocRotScale(at, q @ m.to_quaternion(), None)
    update()
    for name in ORDER:
        want = pose.get('bones', {}).get(name)
        if want is None:
            continue
        pb = rig.pose.bones[name]
        frame = q if (legs_in_body or not name.startswith(LEGS)) else ground
        m = pb.matrix.copy()
        now = m.to_quaternion() @ Vector((0, 1, 0))
        turn = now.rotation_difference(Vector(want).normalized() if world else frame @ d(*want))
        pb.matrix = Matrix.LocRotScale(m.translation, turn @ m.to_quaternion(), None)
        update()
    if pose.get('height') is None:
        # the lowest of the toes and the heels back on the grass (rest: the toes 1 cm up, the ankle 8 cm)
        low = min(min(rig.pose.bones['ball_' + s].head.z - 0.01, rig.pose.bones['ball_' + s].tail.z - 0.01,
                      rig.pose.bones['foot_' + s].head.z - 0.08) for s in 'lr')
        m = pelvis.matrix.copy()
        m.translation.z += pose.get('ground', 0.0) - low      # mocap: as high as the actor's lowest foot
        pelvis.matrix = m
        update()


def key(rig, frame):
    for pb in rig.pose.bones:
        pb.keyframe_insert('rotation_quaternion', frame=frame)
        if pb.name == 'pelvis':
            pb.keyframe_insert('location', frame=frame)


def build(rig, name, steps):
    """One action: the poses keyed at their times, eased between."""
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    for t, pose in steps:
        place(rig, pose)
        key(rig, round(t * FPS) + 1)
    return act


# ------------------------------------------------------------------ pictures and export

def sheet(rig, name, steps, path):
    """The move at each of its poses, side by side, from the front."""
    import numpy as np
    rig.animation_data.action = bpy.data.actions[name]
    if len(steps) > 8:      # a move from motion capture has a pose every frame: six of them tell it
        steps = [steps[round(i * (len(steps) - 1) / 5)] for i in range(6)]
    # the camera in front, a little to the side the move goes, so the whole move is in the picture
    reach = max((p.get('shift', (0, 0))[0] for _, p in steps), key=abs, default=0)
    target = Vector((reach / 2, 0, 0.8))
    cam = bpy.context.scene.camera
    cam.location = target + Vector((3.2, -5.4, 0.5))   # three quarters: the lean and the depth show
    c.aim(cam, target)
    parts = []
    for i, (t, _) in enumerate(steps):
        bpy.context.scene.frame_set(round(t * FPS) + 1)
        part = path[:-4] + '-%d.png' % i
        c.render(part, 520, 620, samples=16, view='Standard')
        parts.append(part)
    imgs = [bpy.data.images.load(p) for p in parts]
    w, h = imgs[0].size
    rows = [np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4) for im in imgs]
    out = bpy.data.images.new('sheet-' + name, w * len(rows), h, alpha=True)
    out.pixels = np.concatenate(rows, axis=1).ravel().tolist()
    out.filepath_raw, out.file_format = path, 'JPEG'      # light in the repository
    bpy.context.scene.render.image_settings.quality = 85
    out.save()
    for im in imgs:
        bpy.data.images.remove(im)
    for p in parts:
        os.remove(p)
    print('Legends: move sheet', path)


def main():
    opts = c.args()
    names = opts['moves'].split(',') if opts.get('moves') else list(MOVES) + list(mocap.CYCLES) + list(mocap.TAKES) + list(mocap.MIRRORED)
    bp.clear()
    bpy.context.scene.render.fps = FPS     # the keys are at FPS: the scene must play at it too
    rig, body = bp.person(build='medium', tone='olive', hair='short02', name='Player')
    keeper = 'keeper' in ','.join(names)
    kits.materials(kits.dress(rig, body, keeper=keeper), '#2BB673', '#111827', 'plain', c.srgb)
    steps = {}
    for n in names:
        if n in MOVES:
            steps[n] = MOVES[n]
            build(rig, n, MOVES[n])
            print('Legends: move %-22s %.1f s' % (n, MOVES[n][-1][0]))
    # [U1] walking, jogging and running from real people (mocap.py), on the spot, with their speeds
    legs = rig.data.bones['thigh_l'].length + rig.data.bones['calf_l'].length
    strides = mocap.cycles(legs, [n for n in names if n in mocap.CYCLES])
    for n, (poses, speed) in strides.items():
        steps[n] = poses
        build(rig, n, poses)
    if strides and 'no-export' not in opts:
        import json
        os.makedirs(os.path.dirname(SPEEDS), exist_ok=True)
        with open(SPEEDS, 'w', encoding='utf-8', newline=chr(10)) as f:
            json.dump({n: {'speed': round(sp, 3), 'seconds': round(p[-1][0], 3), 'clip': mocap.CYCLES[n]} for n, (p, sp) in strides.items()}, f, indent=2)
            f.write(chr(10))
    # [U2] kicking the ball, stopping and turning from real people too, once each
    once = mocap.takes(legs, [n for n in names if n in mocap.TAKES or n in mocap.MIRRORED])
    for n, (poses, info) in once.items():
        steps[n] = poses
        build(rig, n, poses)
    made = {n: {'clip': 'keyframes', **CONTACTS[n], 'seconds': MOVES[n][-1][0]} for n in CONTACTS if n in steps}
    if (once or made) and 'no-export' not in opts:
        import json
        table = {}
        if os.path.exists(TAKES):           # a run for a few moves keeps the others' rows
            with open(TAKES, encoding='utf-8') as f:
                table = json.load(f)
        table.update({n: info for n, (_, info) in once.items()})
        table.update(made)
        with open(TAKES, 'w', encoding='utf-8', newline=chr(10)) as f:
            json.dump(table, f, indent=2)
            f.write(chr(10))
    if 'sheet' in opts:
        os.makedirs(SHEETS, exist_ok=True)
        c.studio(target=(0.9, 0, 0.8), distance=6.5, height=0.2, lens=55, floor='#6f6f6f', night=False)
        bpy.context.scene.view_settings.exposure = -0.4
        for n in steps:
            sheet(rig, n, steps[n], os.path.join(SHEETS, n + '.jpg'))
    if 'no-export' not in opts:
        export(rig)


def export(rig):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    bpy.ops.object.select_all(action='DESELECT')
    # An empty beside the rig: a file with one object becomes that object in Unity, and the rig's 'Player' would be
    # renamed to the file's name, so its bones would not match the players' avatar (Root's parent must be 'Player').
    keep = bpy.data.objects.get('Legends') or c.link(bpy.data.objects.new('Legends', None))
    # and the rig named as in the players' files (MPFB calls it '<name>.rig')
    for ob in bpy.data.objects:
        if ob.name == 'Player' and ob is not rig:
            ob.name = 'Player body'
    rig.name = 'Player'
    keep.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
                             axis_forward='-Z', axis_up='Y', add_leaf_bones=False, use_armature_deform_only=True,
                             object_types={'ARMATURE', 'EMPTY'}, bake_anim=True, bake_anim_use_all_actions=True,
                             bake_anim_use_nla_strips=False, bake_anim_force_startend_keying=True,
                             bake_anim_simplify_factor=0.0, path_mode='STRIP')
    print('Legends: exported', OUT)


if __name__ == '__main__':
    main()
