"""Sprint 07 U1/U2: real people's movements from the CMU motion capture library, onto our rig.

The library (mocap.cs.cmu.edu, here in Bruce Hahne's BVH conversion, github.com/meshula/cmu-mocap) may be copied,
modified and put in products that are sold; only reselling the data itself is not allowed (its licence, reviewed in
sprints/07-unity-motion.md). The files we use are downloaded one by one to tools/unity/players/downloads/cmu/, outside
git; never crawl the library.

Each frame becomes a pose in keyframes.py's own words: where every bone points, how the hips are turned and where
they are. So the actor's movement plays on our rig whatever his size: his directions, our lengths. A walking, jogging
or running clip gives one whole stride (from the left foot down to the left foot down again), turned to face forward,
on the spot (the server moves the player across the pitch), with its own speed in metres per second, so Unity can
play it at the pace the player really goes and the feet do not slide.
"""
import math
import os
import re

import numpy as np
from mathutils import Matrix, Quaternion, Vector

DOWNLOADS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'downloads', 'cmu')
KEY_FPS = 30

# our bone -> (from joint, to joint) in the CMU skeleton; '_end' is a joint's end site
BONES = {
    'spine_01': ('LowerBack', 'Spine'), 'spine_02': ('Spine', 'Spine1'), 'spine_03': ('Spine1', 'Neck'),
    'neck_01': ('Neck', 'Neck1'), 'head': ('Head', 'Head_end'),
    'clavicle_l': ('LeftShoulder', 'LeftArm'), 'upperarm_l': ('LeftArm', 'LeftForeArm'),
    'lowerarm_l': ('LeftForeArm', 'LeftHand'), 'hand_l': ('LeftHand', 'LeftFingerBase'),
    'clavicle_r': ('RightShoulder', 'RightArm'), 'upperarm_r': ('RightArm', 'RightForeArm'),
    'lowerarm_r': ('RightForeArm', 'RightHand'), 'hand_r': ('RightHand', 'RightFingerBase'),
    'thigh_l': ('LeftUpLeg', 'LeftLeg'), 'calf_l': ('LeftLeg', 'LeftFoot'), 'foot_l': ('LeftFoot', 'LeftToeBase'),
    'ball_l': ('LeftToeBase', 'LeftToeBase_end'),
    'thigh_r': ('RightUpLeg', 'RightLeg'), 'calf_r': ('RightLeg', 'RightFoot'), 'foot_r': ('RightFoot', 'RightToeBase'),
    'ball_r': ('RightToeBase', 'RightToeBase_end'),
}

# The strides we take, and which clip each comes from (sprints/07-unity-motion.md, U1).
CYCLES = {
    'walk': '07_01',
    'walk_brisk': '07_12',
    'jog': '16_35',
    'run': '09_01',
    'sprint': '16_55',
}

# [U1/U2] The moves that play once, cut from a clip at its seconds: the file, from, to, and what faces forward.
#   kick: the kicking foot's way at its fastest (where the ball goes), and that instant is the contact;
#   travel: where he goes over the cut; start: the way his hips face at the start (so a turn ends turned).
# The kicks are right-footed in the library; their left-footed twins are the same moves mirrored.
TAKES = {
    'pass': ('10_01', 4.40, 5.45, 'kick'),          # a pass from a few steps
    'shot': ('10_03', 0.55, 1.60, 'kick'),          # a shot from a run
    'shot_power': ('11_01', 2.75, 3.82, 'kick'),    # the long run-up and the full swing
    'stop': ('16_08', 0.15, 1.90, 'travel'),        # from a run to a standstill
    'turn_l': ('16_41', 0.15, 1.30, 'start'),       # running, a quarter turn to his left
    'turn_r': ('16_43', 0.15, 1.72, 'start'),       # and to his right
}
MIRRORED = {'pass_l': 'pass', 'shot_l': 'shot', 'shot_power_l': 'shot_power'}


# ------------------------------------------------------------------ the BVH file

def read(path):
    """The skeleton (joints with their parent, offset and channels) and the frames, from a BVH file."""
    text = open(path, encoding='latin-1').read()
    head, motion = text.split('MOTION', 1)
    joints, stack, current = [], [], None
    tokens = re.findall(r'\{|\}|[^\s{}]+', head)
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t in ('ROOT', 'JOINT'):
            current = {'name': tokens[i + 1], 'parent': stack[-1] if stack else None, 'channels': []}
            joints.append(current)
            i += 2
            continue
        if t == 'End':     # End Site: a joint of its own with no channels, named after its parent
            current = {'name': joints[stack[-1]]['name'] + '_end', 'parent': stack[-1], 'channels': []}
            joints.append(current)
            i += 2
            continue
        if t == '{':
            stack.append(len(joints) - 1)
        elif t == '}':
            stack.pop()
        elif t == 'OFFSET':
            current['offset'] = np.array([float(x) for x in tokens[i + 1:i + 4]])
            i += 4
            continue
        elif t == 'CHANNELS':
            n = int(tokens[i + 1])
            current['channels'] = tokens[i + 2:i + 2 + n]
            i += 2 + n
            continue
        i += 1
    lines = motion.strip().splitlines()
    dt = float(lines[1].split(':')[1])
    data = np.array([[float(x) for x in l.split()] for l in lines[2:] if l.strip()])
    return joints, data, dt


def _axis(name, deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    if name == 'X':
        return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if name == 'Y':
        return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def positions(joints, data):
    """Every joint's position in every frame: {name: array (frames, 3)}, in the file's units and axes (Y up)."""
    out = {j['name']: np.zeros((len(data), 3)) for j in joints}
    for f, row in enumerate(data):
        col = 0
        world = []
        for j in joints:
            rot = np.eye(3)
            pos = j.get('offset', np.zeros(3)).copy()
            for ch in j['channels']:
                v = row[col]
                col += 1
                if ch.endswith('position'):
                    pos['XYZ'.index(ch[0])] = v
                else:
                    rot = rot @ _axis(ch[0], v)
            if j['parent'] is None:
                R, P = rot, pos
            else:
                pr, pp = world[j['parent']]
                R, P = pr @ rot, pp + pr @ pos
            world.append((R, P))
            out[j['name']][f] = P
    return out


def to_ours(p):
    """The file's axes (Y up) to Blender's (Z up): a turn, so left stays left."""
    return np.stack([p[..., 0], -p[..., 2], p[..., 1]], axis=-1)


# ------------------------------------------------------------------ frames to poses

def unit(v):
    n = np.linalg.norm(v)
    return v / n if n > 1e-9 else v


def hips_frame(P, f):
    """The hips' own axes at frame f: his left, his forward, up (each a unit vector in Blender's axes)."""
    left = unit(P['LeftUpLeg'][f] - P['RightUpLeg'][f])
    up = unit(P['Spine'][f] - P['Hips'][f])
    up = unit(up - left * np.dot(up, left))
    fwd = np.cross(left, up)          # ours: left x up = forward (the rig faces -Y with his left at +X)
    return left, fwd, up


def stride(P, dt):
    """One whole stride near the middle of the clip: from the left foot at its furthest ahead of the hips to the next
    time it is. That happens once a stride in a walk and a run alike (the lowest point of a foot does not: a walking
    foot stays down a long time). (start, end) frames."""
    way = unit(P['Hips'][-1, :2] - P['Hips'][0, :2])
    ahead = (P['LeftFoot'][:, :2] - P['Hips'][:, :2]) @ way
    gap = int(0.4 / dt)                      # no stride is shorter than 0.4 s
    peaks = [f for f in range(1, len(ahead) - 1) if ahead[f] == ahead[max(0, f - gap):f + gap + 1].max()]
    if len(peaks) < 2:
        raise ValueError('no whole stride')
    mid = max(0, len(peaks) // 2 - 1)
    return peaks[mid], peaks[mid + 1]


def load(clip, mirrored=False):
    """Every joint's path in Blender's axes, and the seconds per frame. Mirrored: his left and right swapped."""
    joints, data, dt = read(os.path.join(DOWNLOADS, clip + '.bvh'))
    P = {k: to_ours(v) for k, v in positions(joints, data).items()}
    if mirrored:
        flip = np.array([-1.0, 1.0, 1.0])
        swap = lambda n: n.replace('Left', '#').replace('Right', 'Left').replace('#', 'Right')
        P = {swap(k): v * flip for k, v in P.items()}
    return P, dt


def facing(P, heading):
    """The paths turned so that heading (radians, 0 towards -Y) faces forward."""
    turn = np.array(Matrix.Rotation(-heading, 3, 'Z'))
    return {k: v @ turn.T for k, v in P.items()}


def heading_of(v):
    return math.atan2(v[0], -v[1])        # 0 when v goes towards -Y, the way the rig faces


def scale_of(P, a, b, leg_length):
    """Our legs over the actor's: his travel and height on our player."""
    return leg_length / np.mean([np.linalg.norm(P['LeftUpLeg'][f] - P['LeftLeg'][f]) + np.linalg.norm(P['LeftLeg'][f] - P['LeftFoot'][f]) for f in range(a, b)])


def poses(P, dt, a, b, scale):
    """The frames from a to b as keyframes.py poses at their times, on the spot: the hips' straight path from where
    they are at a to where they are at b taken away, their sway, bounce and turn kept."""
    start, end = P['Hips'][a], P['Hips'][b]
    # how high his lowest foot is, measured as keyframes.place measures ours: the toes, or the ankle less its
    # height over the toes when the foot is flat (the least it is over the cut)
    ankle = min(P['LeftFoot'][f, 2] - P['LeftToeBase'][f, 2] for f in range(a, b))
    low = lambda f: min(P['LeftToeBase'][f, 2], P['RightToeBase'][f, 2], P['LeftFoot'][f, 2] - ankle, P['RightFoot'][f, 2] - ankle)
    floor = min(low(f) for f in range(a, b + 1))
    out = []
    step = max(1, round(1 / (KEY_FPS * dt)))
    for f in list(range(a, b, step)) + [b]:
        k = (f - a) / (b - a)
        line = start + (end - start) * k
        hips = (P['Hips'][f] - line) * scale
        left, fwd, up = hips_frame(P, f)
        m = Matrix((left, -fwd, up)).transposed()      # columns: our X (left), Y (back), Z (up)
        bones = {}
        for ours, (j0, j1) in BONES.items():
            if j0 in P and j1 in P:
                v = P[j1][f] - P[j0][f]
                if np.linalg.norm(v) > 1e-6:
                    bones[ours] = tuple(unit(v))
        out.append(((f - a) * dt, {
            'q': m.to_quaternion(), 'frame': 'world', 'bones': bones,
            'at': (hips[0], hips[1], None),
            # the lowest of his feet where the actor's is, on our scale
            'ground': float((low(f) - floor) * scale),
        }))
    return out


def cycle(clip, leg_length):
    """A clip's stride as keyframes.py poses at their times, and its speed (m/s) on our rig.

    leg_length: our thigh + calf in metres, to scale the actor's travel and height to our player.
    """
    P, dt = load(clip)
    a, b = stride(P, dt)
    scale = scale_of(P, a, b, leg_length)
    travel = P['Hips'][b, :2] - P['Hips'][a, :2]
    P = facing(P, heading_of(travel))
    seconds = (b - a) * dt
    speed = float(np.linalg.norm(travel) * scale / seconds)
    out = poses(P, dt, a, b, scale)
    out[-1] = (seconds, out[0][1])           # the loop closes on its first pose
    return out, speed


def take(name, leg_length, mirrored=False):
    """A move that plays once (TAKES), as poses at their times, and what Unity needs to time it: its length, the
    contact (seconds into it) and the kicking foot for a kick, how fast he goes at its start and end (m/s, to blend
    in from the stride and out to the next), and how far it turns him (degrees, + to his left)."""
    clip, t0, t1, ahead = TAKES[name]
    P, dt = load(clip, mirrored)
    a, b = round(t0 / dt), round(t1 / dt)
    scale = scale_of(P, a, b, leg_length)
    info = {'clip': clip}
    if ahead == 'kick':
        foot = 'LeftToeBase' if mirrored else 'RightToeBase'
        v = np.linalg.norm(np.diff(P[foot], axis=0), axis=1)
        fast = a + int(np.argmax(v[a:b]))
        way = P[foot][fast + 1, :2] - P[foot][fast - 1, :2]
        # the ball sits beside the foot he stands on: the swing is fastest just before it, and meets the ball as the
        # kicking toes come level with the standing ones
        plant = 'RightToeBase' if mirrored else 'LeftToeBase'
        ahead = lambda j, f: float(np.dot(P[j][f, :2], unit(way)))
        hit = next((f for f in range(fast, b) if ahead(foot, f) >= ahead(plant, f)), fast)
        info.update(contact=round((hit - a) * dt, 3), foot='left' if mirrored else 'right')
    elif ahead == 'travel':
        way = P['Hips'][b, :2] - P['Hips'][a, :2]
    else:
        _, fwd, _ = hips_frame(P, a)
        way = fwd[:2]
    P = facing(P, heading_of(way))
    span = max(1, round(0.2 / dt))
    pace = lambda f0, f1: float(np.linalg.norm(P['Hips'][f1, :2] - P['Hips'][f0, :2]) * scale / ((f1 - f0) * dt))
    _, f_a, _ = hips_frame(P, a)
    _, f_b, _ = hips_frame(P, b)
    turn = math.degrees(heading_of(f_b) - heading_of(f_a))
    turn = (turn + 180) % 360 - 180
    info.update(seconds=round((b - a) * dt, 3), speed_in=round(pace(a, a + span), 2), speed_out=round(pace(b - span, b), 2), turn=round(turn))
    return poses(P, dt, a, b, scale), info

def cycles(leg_length, names=None):
    """{move: (poses, speed)} for the strides whose clips are downloaded."""
    out = {}
    for name, clip in CYCLES.items():
        if names is not None and name not in names:
            continue
        if not os.path.exists(os.path.join(DOWNLOADS, clip + '.bvh')):
            print('Legends: no %s.bvh in %s (download it first): %s left out' % (clip, DOWNLOADS, name))
            continue
        out[name] = cycle(clip, leg_length)
        print('Legends: stride %-11s from %s: %.2f s, %.2f m/s' % (name, clip, out[name][0][-1][0], out[name][1]))
    return out


def takes(leg_length, names=None):
    """{move: (poses, info)} for the moves that play once (TAKES and their MIRRORED twins) whose clips are here."""
    out = {}
    for name in list(TAKES) + list(MIRRORED):
        if names is not None and name not in names:
            continue
        source = MIRRORED.get(name, name)
        clip = TAKES[source][0]
        if not os.path.exists(os.path.join(DOWNLOADS, clip + '.bvh')):
            print('Legends: no %s.bvh in %s (download it first): %s left out' % (clip, DOWNLOADS, name))
            continue
        out[name] = take(source, leg_length, mirrored=name in MIRRORED)
        print('Legends: take %-13s %s' % (name, out[name][1]))
    return out
