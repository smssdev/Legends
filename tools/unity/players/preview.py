"""The raw MakeHuman look (unity/Reference/players/makehuman-raw*.png): three footballers from MakeHuman's own
CC0 base mesh and shape targets, rendered in Blender (Cycles, CPU). A rough look only: no textures, short hair
painted on the scalp, the kit painted by body region, the standing A-pose. Sprint 3 makes the real players.

  python3 -m venv venv && venv/bin/pip install bpy          (Blender as a Python module, free)
  mkdir mh && cd mh
  curl -LO https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/3dobjs/base.obj
  pip download makehuman==1.3.2 --no-deps && python3 -m zipfile -e makehuman-1.3.2-py3-none-any.whl .
  ../venv/bin/python tools/unity/players/preview.py --data mh -- out.png      (CLOSE=1 for the close-up)
"""
import math, os, sys
import numpy as np
import bpy

HERE = os.path.abspath(sys.argv[sys.argv.index('--data') + 1]) if '--data' in sys.argv else os.getcwd()   # base.obj and makehuman/
OUT = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else os.path.join(HERE, 'players.png')

# ---------------------------------------------------------------- the base mesh
verts, faces, groups = [], [], []
group = None
for line in open(os.path.join(HERE, 'base.obj')):
    if line.startswith('v '):
        verts.append([float(x) for x in line.split()[1:4]])
    elif line.startswith('g '):
        group = line.split()[1]
    elif line.startswith('f '):
        faces.append([int(t.split('/')[0]) - 1 for t in line.split()[1:]])
        groups.append(group)
base = np.array(verts, dtype=np.float64)
T = np.load(os.path.join(HERE, 'makehuman', 'data', 'targets.npz'))


def target(name):
    d = np.zeros_like(base)
    d[T['targets/' + name + '.index']] = T['targets/' + name + '.vector'] * 1e-3
    return d


def body(race, muscle, weight):
    """race: {african|asian|caucasian: share}; muscle, weight in 0..1 (0.5 average)."""
    v = base.copy()
    for r, share in race.items():
        v += share * target('macrodetails/%s-male-young' % r)
    # the universal shape: bilinear between min/average/max muscle and weight, as MakeHuman does
    def pair(x, lo, hi):
        return [(lo, 1 - 2 * x), ('average' + lo[3:], 2 * x)] if x < 0.5 else [('average' + hi[3:], 2 - 2 * x), (hi, 2 * x - 1)]
    for m, wm in pair(muscle, 'minmuscle', 'maxmuscle'):
        for w, ww in pair(weight, 'minweight', 'maxweight'):
            if wm * ww > 0:
                v += wm * ww * target('macrodetails/universal-male-young-%s-%s' % (m, w))
    return v


# ---------------------------------------------------------------- materials
def mat(name, rgb, rough=0.6, sheen=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = rough
    if sheen and 'Sheen Weight' in p.inputs:
        p.inputs['Sheen Weight'].default_value = sheen
    return m


def srgb(h):
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def player(name, race, muscle, weight, skin, shirt, shorts, socks, number_side, x):
    v = body(race, muscle, weight)
    keep = [i for i, g in enumerate(groups) if g in ('body', 'helper-l-eye', 'helper-r-eye')]
    used = sorted({i for f in keep for i in faces[f]})
    remap = {o: n for n, o in enumerate(used)}
    pts = v[used]
    y0, y1 = pts[:, 1].min(), pts[:, 1].max()
    H = y1 - y0
    scale = 1.82 / H                                  # every player 1.82 m
    co = [((p[0]) * scale, -(p[2]) * scale, (p[1] - y0) * scale) for p in pts]   # MakeHuman y-up to Blender z-up
    fs = [[remap[i] for i in faces[f]] for f in keep]

    me = bpy.data.meshes.new(name)
    me.from_pydata(co, [], fs)
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    mats = {
        'skin': mat(name + ' skin', srgb(skin), 0.45),
        'shirt': mat(name + ' shirt', srgb(shirt), 0.7, 0.3),
        'shorts': mat(name + ' shorts', srgb(shorts), 0.7, 0.3),
        'socks': mat(name + ' socks', srgb(socks), 0.8),
        'boots': mat(name + ' boots', srgb('#111111'), 0.35),
        'hair': mat(name + ' hair', srgb('#1a120c'), 0.8),
        'eye': mat(name + ' eye', srgb('#e9e6df'), 0.2),
    }
    order = list(mats)
    for m in mats.values():
        me.materials.append(m)

    # the kit by height along the body (fractions of 1.82 m), sleeves to just above the elbow
    shoulder = 0.815 * 1.82
    for poly, f in zip(me.polygons, keep):
        g = groups[f]
        c = poly.center
        h = c.z / 1.82
        if g.endswith('-eye'):
            k = 'eye'
        else:
            arm = abs(c.x) > (0.20 if h > 0.66 else 0.25) and h > 0.42
            # short hair: the scalp above the brow, and the back of the head down to the nape
            if h > 0.952 or (h > 0.885 and c.y > 0.03) or (h > 0.925 and abs(c.x) > 0.065 and c.y > -0.03):
                k = 'hair'
            elif arm:
                k = 'shirt' if h > 0.70 else 'skin'
            elif h < 0.045:
                k = 'boots'
            elif h < 0.275:
                k = 'socks'
            elif h < 0.385:
                k = 'skin'
            elif h < 0.565:
                k = 'shorts'
            elif h < 0.835 and not (h > 0.80 and abs(c.x) < 0.06 and c.y < -0.02):
                k = 'shirt'
            else:
                k = 'skin'
        poly.material_index = order.index(k)
        poly.use_smooth = True
    ob.location.x = x
    ob.rotation_euler.z = math.radians(number_side)
    sub = ob.modifiers.new('smooth', 'SUBSURF')
    sub.levels = sub.render_levels = 1
    return ob


# ---------------------------------------------------------------- scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 96
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.filepath = OUT
scene.view_settings.view_transform = 'AgX'

world = bpy.data.worlds.new('w')
scene.world = world
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.02, 0.03, 0.06, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.6

# three Legends players: slim, average, strong; three skin tones; kits in club colours
player('P1', {'african': 1.0}, 0.75, 0.35, '#5b3a29', '#C8102E', '#FFFFFF', '#C8102E', -12, -1.25)   # red home kit
player('P2', {'caucasian': 1.0}, 0.55, 0.5, '#d9a98a', '#F2F2F2', '#0B1F42', '#F2F2F2', 0, 0)           # white and navy
player('P3', {'asian': 0.4, 'caucasian': 0.6}, 0.6, 0.25, '#c08a63', '#F5B82E', '#0A1F42', '#0A1F42', 12, 1.25)  # Legends gold

# a pitch underfoot
bpy.ops.mesh.primitive_plane_add(size=30)
grass = bpy.context.object
grass.data.materials.append(mat('grass', srgb('#2f7d32'), 0.9))

def light(kind, loc, energy, size=1.0, rot=(0, 0, 0)):
    d = bpy.data.lights.new(kind + str(len(bpy.data.lights)), 'AREA')
    d.energy, d.size = energy, size
    o = bpy.data.objects.new(d.name, d)
    o.location, o.rotation_euler = loc, rot
    bpy.context.collection.objects.link(o)
    return o

light('key', (3.5, -5, 6), 1500, 4, (math.radians(45), 0, math.radians(35)))
light('fill', (-5, -4, 3), 500, 5, (math.radians(65), 0, math.radians(-50)))
light('rim', (0, 5, 5), 1100, 6, (math.radians(-45), 0, 0))

cam_data = bpy.data.cameras.new('cam')
cam_data.lens = 50
cam = bpy.data.objects.new('cam', cam_data)
bpy.context.collection.objects.link(cam)
if os.environ.get('CLOSE'):
    cam.location = (0.9, -2.6, 1.45)          # the middle player, head and chest, from three-quarters
    cam.rotation_euler = (math.radians(85), 0, math.radians(19))
    cam_data.lens = 70
else:
    cam.location = (0, -7.2, 1.25)
    cam.rotation_euler = (math.radians(88), 0, 0)
scene.camera = cam

bpy.ops.render.render(write_still=True)
print('wrote', OUT)
