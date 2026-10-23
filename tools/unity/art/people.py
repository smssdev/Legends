"""Everyone on the pitch, from MakeHuman's own CC0 body and shape targets: players in three builds and skin tones,
the goalkeeper, the referee, the assistant with his flag, and the coach. A rough look to judge and improve:
the kit painted by body region, short hair on the scalp, the standing A-pose. Sprint 3 makes the finished,
rigged people with MPFB2 (PLAN 7.11); this is where their look is decided first.

Needs MakeHuman's base mesh and targets once, in a folder (default tools/unity/art/makehuman/):
  curl -LO https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/3dobjs/base.obj
  pip download makehuman==1.3.2 --no-deps  then unzip the .whl there (it holds makehuman/data/targets.npz)

  blender -b -P tools/unity/art/people.py -- [--mh FOLDER] [--close]

Writes one FBX per person to unity/Assets/Legends/Art/People/ and unity/Reference/art/people.png
(people-close.png with --close). Change the colours and builds in PEOPLE below, run again, and look.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import bpy
import common as c

# name, {skin share}, muscle 0..1, weight 0..1, skin colour, kit {shirt, shorts, socks, boots}, extras
PEOPLE = [
    ('Player 1', {'african': 1.0}, 0.75, 0.35, '#5b3a29', {'shirt': '#C8102E', 'shorts': '#FFFFFF', 'socks': '#C8102E'}, {}),
    ('Player 2', {'caucasian': 1.0}, 0.55, 0.5, '#d9a98a', {'shirt': '#F2F2F2', 'shorts': c.NAVY, 'socks': '#F2F2F2'}, {}),
    ('Player 3', {'asian': 0.4, 'caucasian': 0.6}, 0.6, 0.25, '#c08a63', {'shirt': c.GOLD, 'shorts': c.NAVY, 'socks': c.NAVY}, {}),
    ('Goalkeeper', {'caucasian': 0.7, 'african': 0.3}, 0.6, 0.45, '#b9876a', {'shirt': '#2E7D32', 'shorts': '#1b1b1b', 'socks': '#2E7D32'}, {'long sleeves': True, 'gloves': '#FFFFFF'}),
    ('Referee', {'caucasian': 1.0}, 0.45, 0.45, '#e0b391', {'shirt': '#111111', 'shorts': '#111111', 'socks': '#111111'}, {}),
    ('Assistant', {'african': 0.5, 'caucasian': 0.5}, 0.45, 0.4, '#8d5b3e', {'shirt': '#111111', 'shorts': '#111111', 'socks': '#111111'}, {'flag': c.GOLD}),
    ('Coach', {'caucasian': 1.0}, 0.35, 0.7, '#d8a585', {'shirt': c.NAVY, 'shorts': c.NAVY, 'socks': c.NAVY, 'boots': '#0e0e0e'}, {'long sleeves': True, 'trousers': True, 'collar': '#FFFFFF'}),
]
HEIGHT = 1.82


def load(folder):
    verts, faces, groups, group = [], [], [], None
    for line in open(os.path.join(folder, 'base.obj')):
        if line.startswith('v '):
            verts.append([float(x) for x in line.split()[1:4]])
        elif line.startswith('g '):
            group = line.split()[1]
        elif line.startswith('f '):
            faces.append([int(t.split('/')[0]) - 1 for t in line.split()[1:]])
            groups.append(group)
    return np.array(verts), faces, groups, np.load(os.path.join(folder, 'makehuman', 'data', 'targets.npz'))


def shape(base, T, race, muscle, weight):
    """MakeHuman's macro shape: the skin share of each ethnic target, then muscle and weight mixed between
    their min, average and max targets (0.5 = average), all for a young man."""
    def target(name):
        d = np.zeros_like(base)
        d[T['targets/' + name + '.index']] = T['targets/' + name + '.vector'] * 1e-3
        return d
    v = base.copy()
    for r, share in race.items():
        v += share * target('macrodetails/%s-male-young' % r)
    def pair(x, lo, hi):
        return [(lo, 1 - 2 * x), ('average' + lo[3:], 2 * x)] if x < 0.5 else [('average' + hi[3:], 2 - 2 * x), (hi, 2 * x - 1)]
    for m, wm in pair(muscle, 'minmuscle', 'maxmuscle'):
        for w, ww in pair(weight, 'minweight', 'maxweight'):
            if wm * ww > 0:
                v += wm * ww * target('macrodetails/universal-male-young-%s-%s' % (m, w))
    return v


def person(data, name, race, muscle, weight, skin, kit, extra):
    base, faces, groups, T = data
    v = shape(base, T, race, muscle, weight)
    keep = [i for i, g in enumerate(groups) if g in ('body', 'helper-l-eye', 'helper-r-eye')]
    used = sorted({i for f in keep for i in faces[f]})
    remap = {o: n for n, o in enumerate(used)}
    pts = v[used]
    y0 = pts[:, 1].min()
    scale = HEIGHT / (pts[:, 1].max() - y0)
    co = [(p[0] * scale, -p[2] * scale, (p[1] - y0) * scale) for p in pts]   # MakeHuman is y-up, Blender z-up
    me = bpy.data.meshes.new(name)
    me.from_pydata(co, [], [[remap[i] for i in faces[f]] for f in keep])
    ob = c.link(bpy.data.objects.new(name, me))
    parts = {
        'skin': c.mat(name + ' skin', skin, 0.45),
        'shirt': c.mat(name + ' shirt', kit['shirt'], 0.7, sheen=0.3),
        'shorts': c.mat(name + ' shorts', kit['shorts'], 0.7, sheen=0.3),
        'socks': c.mat(name + ' socks', kit['socks'], 0.8),
        'boots': c.mat(name + ' boots', kit.get('boots', '#111111'), 0.35),
        'hair': c.mat(name + ' hair', '#1a120c', 0.8),
        'eye': c.mat(name + ' eye', '#e9e6df', 0.2),
        'gloves': c.mat(name + ' gloves', extra.get('gloves', '#FFFFFF'), 0.6),
        'collar': c.mat(name + ' collar', extra.get('collar', kit['shirt']), 0.6),
    }
    order = list(parts)
    for m in parts.values():
        me.materials.append(m)
    long_sleeves, trousers = extra.get('long sleeves'), extra.get('trousers')
    for poly, f in zip(me.polygons, keep):
        p = poly.center
        h = p.z / HEIGHT
        if groups[f].endswith('-eye'):
            k = 'eye'
        elif h > 0.952 or (h > 0.885 and p.y > 0.03) or (h > 0.925 and abs(p.x) > 0.065 and p.y > -0.03):
            k = 'hair'                                  # short hair: the scalp and the back of the head
        elif abs(p.x) > (0.20 if h > 0.66 else 0.25) and h > 0.42:   # the arms
            hand = abs(p.x) > 0.52 or h < 0.5
            k = ('gloves' if 'gloves' in extra else 'skin') if hand else ('shirt' if long_sleeves or h > 0.70 else 'skin')
        elif h < 0.045:
            k = 'boots'
        elif h < 0.275:
            k = 'shorts' if trousers else 'socks'
        elif h < 0.385:
            k = 'shorts' if trousers else 'skin'
        elif h < 0.565:
            k = 'shorts'
        elif h < 0.835 and not (h > 0.80 and abs(p.x) < 0.06 and p.y < -0.02):
            k = 'shirt'
        elif h < 0.85 and 'collar' in extra:
            k = 'collar'
        else:
            k = 'skin'
        poly.material_index = order.index(k)
        poly.use_smooth = True
    sub = ob.modifiers.new('smooth', 'SUBSURF')
    sub.levels = sub.render_levels = 1
    if 'flag' in extra:   # the assistant's flag in his right hand
        hand = max(co, key=lambda q: -q[0])
        stick = c.tube('Flag stick', 0.012, (hand[0], hand[1], hand[2] - 0.05), (hand[0], hand[1] - 0.05, hand[2] + 0.45), c.mat('Stick', '#222222', 0.5), ob)
        c.box('Flag', (0.02, 0.32, 0.26), (hand[0], hand[1] - 0.2, hand[2] + 0.32), c.mat('Assistant flag', extra['flag'], 0.6), ob)
    return ob


def main():
    opts = c.args()
    folder = opts.get('mh') or os.path.join(os.path.dirname(os.path.abspath(__file__)), 'makehuman')
    if not os.path.exists(os.path.join(folder, 'base.obj')):
        sys.exit('Legends: no MakeHuman files in %s: see the top of this script' % folder)
    data = load(folder)
    c.fresh()
    out = c.out_dir(opts, 'People')
    people = []
    for i, (name, race, muscle, weight, skin, kit, extra) in enumerate(PEOPLE):
        ob = person(data, name, race, muscle, weight, skin, kit, extra)
        c.export([ob], os.path.join(out, name.lower().replace(' ', '-') + '.fbx'))
        ob.location.x = (i - (len(PEOPLE) - 1) / 2) * 1.35
        people.append(ob)
    if opts.get('close'):
        cam = c.studio(target=(0, 0, 1.45), distance=2.6, height=0.1, lens=70)
        c.render(c.preview_path(opts, 'people-close'), samples=64)
    else:
        c.studio(target=(0, 0, 0.95), distance=9.5, height=0.4, lens=40)
        c.render(c.preview_path(opts, 'people'), 1800, 900, samples=64)


main()
