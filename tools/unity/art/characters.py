"""The Legends characters in 3D: the three touchline coaches of the characters draft
(docs/design/legends-ui/CharactersDraft.html, C1 to C3) built from soft shapes, with a face for each of the
nine moods, so the same coach moves on the bench in Unity and in the pictures for the web and the app.

Each coach is a hierarchy Unity moves without bones (CharacterMood.cs): Rig > Head > Face.<mood> and Fx.<mood>,
Rig > ArmL > ForeL and ArmR > ForeR. The moods' poses come from unity/Assets/Legends/Resources/CharacterMoods.json,
the same file Unity reads, so a pose changes in one place.

  blender -b -P tools/unity/art/characters.py -- [--only C1] [--renders] [--frames 12] [--size 300] [--samples 24]

Writes one FBX per coach to unity/Assets/Legends/Art/Characters/ and the preview unity/Reference/art/characters.png.
With --renders, also the loop of every mood as an animated WebP with a clear background to
docs/design/legends-ui/characters/<code>-<mood>.webp (needs Pillow: pip install pillow).
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Matrix, Vector
import common as c

MOODS = json.load(open(os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Resources', 'CharacterMoods.json')))['moods']

# the brand (docs/design/tokens.json); skins as in people.py
INK, GOLD, GOLD_D, GOLD_L = '#06111E', '#F5B82E', '#C08A0C', '#FFD36B'
EM, EM_D, NAVY, NAVY_D = '#12A07E', '#0A7559', '#183349', '#102538'
CHROME, WHITE, SILVER, RED, SCLERA = '#F6EEDB', '#F7F4EA', '#C3CCDA', '#EF4444', '#FBFAF6'

COACHES = {
    'C1': dict(skin='#d8a585', iris='#6b4423', hair='side', jacket=NAVY, trousers=NAVY_D, shoes=INK, cuff=WHITE, detail='suit'),
    'C2': dict(skin='#8d5b3e', iris='#241509', hair='buzz', jacket=EM, trousers=EM, shoes=WHITE, stripe=GOLD, detail='track'),
    'C3': dict(skin='#e0b391', iris='#2f5d3a', hair='hijab', jacket=CHROME, trousers=NAVY_D, shoes=GOLD, detail='hijab'),
}

HEAD, RADII = Vector((0, 0, 1.66)), (0.125, 0.135, 0.155)   # the head's centre and radii (x, depth, height)
K, FACE_Z = 0.0028, 1.665                                   # one pixel of the 2D draft's face, in metres


# ------------------------------------------------------------ building blocks

def node(name, world, parent=None):
    """An empty the coach moves around (a pivot), placed at `world` while everything stands at rest."""
    ob = c.link(bpy.data.objects.new(name, None))
    ob['w'] = tuple(world)
    if parent:
        ob.parent = parent
        ob.location = Vector(world) - Vector(parent['w'])
    else:
        ob.location = world
    return ob


def attach(ob, parent):
    ob.parent = parent
    ob.matrix_parent_inverse = Matrix.Translation(-Vector(parent['w']))
    return ob


def smooth(ob):
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def sphere(name, r, at, scale, material, parent, seg=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=at)
    ob = bpy.context.object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(material)
    return attach(smooth(ob), parent)


def cone(name, r1, r2, a, b, material, parent, caps=True):
    """A tapered limb from a (radius r1) to b (radius r2), with round ends."""
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=r1, radius2=r2, depth=d.length, location=(a + b) / 2)
    ob = bpy.context.object
    ob.name = name
    ob.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.ops.object.transform_apply(rotation=True)
    ob.data.materials.append(material)
    attach(smooth(ob), parent)
    if caps:
        sphere(name + ' end a', r1, a, (1, 1, 1), material, parent, 20)
        sphere(name + ' end b', r2, b, (1, 1, 1), material, parent, 20)
    return ob


def rbox(name, size, at, material, parent, bevel=0.06):
    """A box with soft edges, the way cloth falls over a body."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    m = ob.modifiers.new('soft', 'BEVEL')
    m.width, m.segments = bevel, 5
    s = ob.modifiers.new('smooth', 'SUBSURF')
    s.levels = s.render_levels = 1
    ob.data.materials.append(material)
    return attach(smooth(ob), parent)


def to_mesh(ob):
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    ob.select_set(False)
    return ob


def line(name, pts, r, material, parent):
    """A stroke along points: brows, closed eyes, a mouth line, the seams."""
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions, cu.bevel_depth, cu.bevel_resolution, cu.use_fill_caps = '3D', r, 3, True
    sp = cu.splines.new('POLY')
    sp.points.add(len(pts) - 1)
    for p, q in zip(sp.points, pts):
        p.co = (*q, 1)
    ob = c.link(bpy.data.objects.new(name, cu))
    cu.materials.append(material)
    return attach(to_mesh(ob), parent)


def disk(name, pts, material, parent, thick=0.003):
    """A flat shape on the face: an open mouth, an iris."""
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(p) for p in pts], [], [list(range(len(pts)))])
    ob = c.link(bpy.data.objects.new(name, me))
    m = ob.modifiers.new('thick', 'SOLIDIFY')
    m.thickness, m.offset = thick, 0
    me.materials.append(material)
    return attach(ob, parent)


def text(name, body, at, size, material, parent):
    bpy.ops.object.text_add(location=at, rotation=(math.pi / 2, 0, 0))
    ob = bpy.context.object
    ob.name = name
    ob.data.body, ob.data.size, ob.data.extrude = body, size, size * 0.12
    ob.data.align_x, ob.data.align_y = 'CENTER', 'CENTER'
    ob.data.materials.append(material)
    return attach(to_mesh(ob), parent)


def shell(name, scale, keep, material, parent, thick=0.006):
    """A cap over the head (hair, a beard, the hijab): the head's own shape, a little bigger, cut by `keep`."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=64, radius=1, location=HEAD)
    ob = bpy.context.object
    ob.name = name
    ob.scale = tuple(r * scale for r in RADII)
    bpy.ops.object.transform_apply(scale=True)
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(v.co)], context='VERTS')
    bm.to_mesh(ob.data)
    bm.free()
    m = ob.modifiers.new('thick', 'SOLIDIFY')
    m.thickness = thick
    ob.data.materials.append(material)
    return attach(smooth(ob), parent)


# ------------------------------------------------------------ the face, drawn as in the 2D draft

def F(px, py, lift=0.0015):
    """A point of the 2D face (pixels, y down, centred between the eyes) on the surface of the head."""
    u, z = px * K, FACE_Z - py * K
    a, b, h = RADII
    inside = 1 - (u / a) ** 2 - ((z - HEAD.z) / h) ** 2
    return Vector((u, HEAD.y - b * math.sqrt(max(0.06, inside)) - lift, z))


def Q(p0, p1, p2, n=14):
    return [tuple((1 - t) ** 2 * p0[i] + 2 * (1 - t) * t * p1[i] + t * t * p2[i] for i in (0, 1)) for t in (k / n for k in range(n + 1))]


def L(p0, p1, n=6):
    return [tuple(p0[i] + (p1[i] - p0[i]) * k / n for i in (0, 1)) for k in range(n + 1)]


def mirror(pts):
    return [(-x, y) for x, y in pts]


def ellipse(cx, cy, rx, ry, n=28):
    return [(cx + rx * math.cos(2 * math.pi * k / n), cy + ry * math.sin(2 * math.pi * k / n)) for k in range(n)]


BROWS = {
    'default': Q((-24, -13), (-16, -17), (-8, -13)),
    'sad': L((-24, -9), (-9, -15)),
    'angry': L((-25, -15), (-8, -7)),
    'worried': Q((-23, -9), (-16, -15), (-9, -14)),
    'surprise': Q((-23, -17), (-16, -22), (-9, -17)),
}
MOUTH_LINES = {
    'idle': (Q((-8, 16), (0, 22), (8, 16)), 1.7),
    'sad': (Q((-9, 22), (0, 14), (9, 22)), 1.7),
    'angry': (Q((-10, 21), (0, 15), (10, 21)), 1.9),
    'worried': ([(x / 2, 19 - 2.2 * math.sin(math.pi * (x / 2 + 10) / 6.6)) for x in range(-20, 21)], 1.5),
    'think': (L((-3, 19), (8, 16)), 1.7),
}


def face(mood, head, mats):
    """Face.<mood>: eyes, brows and mouth; Unity shows the one for the mood and hides the rest."""
    root = node('Face.' + mood, (0, -0.1, FACE_Z), head)
    eyes = node('Eyes.' + mood, (0, -0.12, FACE_Z), root)
    ink = mats['ink']
    stroke = lambda name, pts, w, parent=root: line(name, [F(x, y) for x, y in pts], w * K, ink, parent)
    for side, s in (('L', -1), ('R', 1)):
        x0 = 16 * s
        if mood in ('joy', 'cheer'):
            stroke('Eye ' + side, Q((x0 - 7, 2), (x0, -8), (x0 + 7, 2)), 1.9, eyes)
        elif mood == 'sleep':
            stroke('Eye ' + side, Q((x0 - 7, 0), (x0, 6), (x0 + 7, 0)), 1.7, eyes)
        else:
            big = {'surprise': 1.2, 'worried': 0.88, 'angry': 1.0}.get(mood, 1.0)
            tall = 0.72 if mood == 'angry' else 1.0
            y0 = {'think': -2, 'angry': 2}.get(mood, 0)
            look = 2.2 if mood == 'think' else 0
            at = F(x0, y0, -0.004)
            sphere('Eye ' + side, 1, at, (6.5 * K * big, 0.011, 7.5 * K * big * tall), mats['sclera'], eyes, 24)
            iris_r = 4.4 * (0.8 if mood == 'surprise' else 1.0)
            disk('Iris ' + side, [F(x0 + look + x, y0 + 1 + y, 0.0072) for x, y in ellipse(0, 0, iris_r, iris_r * min(1, tall + 0.1))], mats['iris'], eyes, 0.001)
            disk('Pupil ' + side, [F(x0 + look + x, y0 + 1 + y, 0.0082) for x, y in ellipse(0, 0, 2.2, 2.2)], ink, eyes, 0.001)
            sphere('Glint ' + side, 0.0032, F(x0 + look + 1.7, y0 - 1, 0.009), (1, 0.5, 1), mats['glint'], eyes, 12)
        # the brows
        if mood == 'think':
            pts = L((-24, -12), (-9, -12)) if side == 'L' else mirror(Q((-24, -16), (-16, -21), (-8, -15)))
        else:
            pts = BROWS.get(mood, BROWS['default'])
            pts = pts if side == 'L' else mirror(pts)
        stroke('Brow ' + side, pts, 2.1 if mood == 'angry' else 1.6)
    # the mouth
    if mood in MOUTH_LINES:
        pts, w = MOUTH_LINES[mood]
        stroke('Mouth', pts, w)
    elif mood in ('joy', 'cheer'):
        disk('Mouth', [F(x, y, 0.001) for x, y in Q((-12, 13), (0, 31), (12, 13), 20)], ink, root)
        disk('Tongue', [F(x, y, 0.0028) for x, y in Q((-6, 22), (0, 18), (6, 22), 8)[:-1] + Q((6, 22), (0, 27), (-6, 22), 8)[:-1]], mats['tongue'], root, 0.001)
    elif mood == 'surprise':
        disk('Mouth', [F(x, y, 0.001) for x, y in ellipse(0, 20, 5, 7)], ink, root)
    else:   # sleep
        disk('Mouth', [F(x, y, 0.001) for x, y in ellipse(2, 19, 3, 2.2)], ink, root)
    return root


def effects(mood, head, mats):
    """Fx.<mood>: the tear, the sweat, the steam, the thinking dots, the z's, the '!' and the sparkles."""
    root = node('Fx.' + mood, (0, -0.15, FACE_Z), head)
    fx = []
    def drop(name, px, py):
        fx.append((sphere(name, 3 * K, F(px, py, 0.012), (1, 1, 1.45), mats['drop'], root, 16), 'fall'))
    if mood == 'sad':
        drop('Tear', -19, 12)
    elif mood == 'worried':
        drop('Sweat', 30, -20)
    elif mood == 'angry':
        for s in (-1, 1):
            fx.append((sphere('Steam %d' % s, 5 * K, F(36 * s, -34, 0.03), (1, 1, 1), mats['steam'], root, 16), 'rise'))
            fx.append((sphere('Puff %d' % s, 3.6 * K, F(42 * s, -43, 0.03), (1, 1, 1), mats['steam'], root, 16), 'rise'))
    elif mood == 'think':
        for i, (px, py, r) in enumerate(((30, -40, 3), (40, -50, 4.2), (53, -61, 5.6))):
            fx.append((sphere('Dot %d' % i, r * K, F(px, py, 0.03), (1, 1, 1), mats['steam'], root, 16), 'dot%d' % i))
    elif mood == 'surprise':
        fx.append((text('Bang', '!', F(44, -36, 0.03), 30 * K, mats['gold'], root), 'pop'))
    elif mood == 'sleep':
        for i, (px, py, size) in enumerate(((30, -26, 13), (40, -40, 17), (53, -56, 21))):
            fx.append((text('Z %d' % i, 'z', F(px, py, 0.03), size * K, mats['steam'], root), 'z%d' % i))
    elif mood in ('joy', 'cheer'):
        for i, (px, py) in enumerate(((-50, -26), (50, -32), (56, 4))):
            at = F(px, py, 0.03)
            star = [(at.x + 8 * K * (1 if k % 2 == 0 else 0.3) * math.cos(math.pi * k / 4 + math.pi / 2), at.y,
                     at.z + 8 * K * (1 if k % 2 == 0 else 0.3) * math.sin(math.pi * k / 4 + math.pi / 2)) for k in range(8)]
            fx.append((disk('Sparkle %d' % i, star, mats['spark'], root, 0.004), 'spark%d' % i))
    for ob, kind in fx:
        ob['fx'] = kind
        ob['rest'] = tuple(ob.location)
    return root


# ------------------------------------------------------------ a coach

def materials(code, o):
    m = lambda n, col, rough=0.6, **k: c.mat(code + ' ' + n, col, rough, **k)
    mats = {
        'skin': m('skin', o['skin'], 0.5), 'jacket': m('jacket', o['jacket'], 0.75, sheen=0.08),
        'trousers': m('trousers', o['trousers'], 0.75, sheen=0.08), 'shoes': m('shoes', o['shoes'], 0.3),
        'ink': m('ink', INK, 0.4), 'sclera': m('sclera', SCLERA, 0.25), 'iris': m('iris', o['iris'], 0.3),
        'glint': m('glint', '#FFFFFF', 0.1, emit=4.0), 'tongue': m('tongue', RED, 0.4),
        'drop': m('drop', '#7FD8F5', 0.1), 'steam': m('steam', WHITE, 0.5), 'gold': m('gold', GOLD, 0.35, metal=0.3),
        'spark': m('spark', GOLD_L, 0.3, emit=1.5), 'hair': m('hair', '#17110c', 0.7, sheen=0.1),
        'white': m('white', WHITE, 0.5), 'em': m('em', EM, 0.6), 'emD': m('emD', EM_D, 0.6),
        'goldD': m('goldD', GOLD_D, 0.35, metal=0.4), 'silver': m('silver', SILVER, 0.25, metal=0.8),
    }
    if o.get('cuff'):
        mats['cuff'] = m('cuff', o['cuff'], 0.5)
    if o.get('stripe'):
        mats['stripe'] = m('stripe', o['stripe'], 0.5)
    return mats


def arm(side, s, rig, o, mats):
    """ArmL / ArmR at the shoulder and ForeL / ForeR at the elbow: Unity turns these two."""
    x = 0.235 * s
    up = node('Arm' + side, (x, 0, 1.39), rig)
    cone('Upper arm ' + side, 0.054, 0.049, (x, 0, 1.39), (x, 0, 1.08), mats['jacket'], up)
    fore = node('Fore' + side, (x, 0, 1.08), up)
    cone('Forearm ' + side, 0.05, 0.043, (x, 0, 1.08), (x, 0, 0.82), mats['jacket'], fore)
    if o.get('stripe'):
        cone('Stripe up ' + side, 0.006, 0.006, (x + 0.05 * s, 0, 1.33), (x + 0.046 * s, 0, 1.1), mats['stripe'], up, caps=False)
        cone('Stripe fore ' + side, 0.006, 0.006, (x + 0.045 * s, 0, 1.05), (x + 0.04 * s, 0, 0.85), mats['stripe'], fore, caps=False)
    if o.get('cuff'):
        cone('Cuff ' + side, 0.046, 0.046, (x, 0, 0.83), (x, 0, 0.8), mats['cuff'], fore, caps=False)
    sphere('Hand ' + side, 0.045, (x, -0.005, 0.76), (0.78, 0.6, 1.15), mats['skin'], fore)
    sphere('Thumb ' + side, 0.018, (x - 0.03 * s, -0.03, 0.785), (1, 1, 1.5), mats['skin'], fore, 16)
    return up


def coach(code, o):
    mats = materials(code, o)
    root = node(code, (0, 0, 0))
    rig = node('Rig', (0, 0, 0), root)
    # legs, shoes and the body
    for s in (-1, 1):
        cone('Leg %d' % s, 0.072, 0.088, (0.1 * s, 0, 0.1), (0.105 * s, 0, 0.86), mats['trousers'], rig)
        rbox('Shoe %d' % s, (0.11, 0.27, 0.08), (0.105 * s, -0.04, 0.045), mats['shoes'], rig, 0.035)
        if o.get('stripe'):
            cone('Leg stripe %d' % s, 0.006, 0.006, (0.17 * s, -0.01, 0.14), (0.19 * s, -0.01, 0.84), mats['stripe'], rig, caps=False)
    rbox('Hips', (0.36, 0.23, 0.18), (0, 0, 0.9), mats['trousers'], rig, 0.07)
    rbox('Torso', (0.42, 0.25, 0.6), (0, 0, 1.16), mats['jacket'], rig, 0.11)
    for s in (-1, 1):
        sphere('Shoulder %d' % s, 0.075, (0.2 * s, 0, 1.39), (1, 0.95, 0.8), mats['jacket'], rig)
    cone('Neck', 0.058, 0.055, (0, 0.005, 1.42), (0, 0.005, 1.55), mats['skin'], rig)
    front = -0.127
    if o['detail'] == 'suit':
        disk('Shirt', [(-0.07, front, 1.43), (0.07, front, 1.43), (0, front, 1.24)], mats['white'], rig, 0.004)
        disk('Tie', [(-0.017, front - 0.004, 1.41), (0.017, front - 0.004, 1.41), (0.026, front - 0.004, 1.2), (0, front - 0.004, 1.16), (-0.026, front - 0.004, 1.2)], mats['gold'], rig, 0.006)
        for s in (-1, 1):
            line('Lapel %d' % s, [(0.075 * s, front - 0.003, 1.43), (0.03 * s, front - 0.003, 1.22)], 0.004, mats['ink'], rig)
        for i, z in enumerate((1.09, 1.0)):
            sphere('Button %d' % i, 0.011, (0, front - 0.002, z), (1, 0.5, 1), mats['goldD'], rig, 12)
        disk('Pocket square', [(0.11, front - 0.002, 1.31), (0.16, front - 0.002, 1.31), (0.15, front - 0.002, 1.285), (0.13, front - 0.002, 1.295)], mats['em'], rig, 0.004)
    elif o['detail'] == 'track':
        rbox('Collar', (0.2, 0.2, 0.06), (0, 0, 1.43), mats['emD'], rig, 0.025)
        line('Zip', [(0, front - 0.002, 1.42), (0, front - 0.002, 0.88)], 0.004, mats['emD'], rig)
        line('Cord', [(-0.06, front, 1.43), (-0.02, front - 0.004, 1.27), (0, front - 0.006, 1.23), (0.02, front - 0.004, 1.27), (0.06, front, 1.43)], 0.003, mats['gold'], rig)
        cone('Whistle', 0.014, 0.014, (-0.03, front - 0.02, 1.22), (0.03, front - 0.02, 1.22), mats['silver'], rig)
    else:   # the hijab's coach: buttons, a lanyard and the staff badge
        for i, z in enumerate((1.18, 1.08, 0.98)):
            sphere('Button %d' % i, 0.011, (0.03, front - 0.002, z), (1, 0.5, 1), mats['goldD'], rig, 12)
        line('Lanyard', [(-0.07, front, 1.4), (0.05, front - 0.004, 1.24), (0.1, front - 0.004, 1.2)], 0.004, mats['em'], rig)
        rbox('Badge', (0.06, 0.012, 0.08), (0.1, front - 0.008, 1.16), mats['gold'], rig, 0.008)
    # the head
    head = node('Head', (0, 0, 1.5), rig)
    hd = sphere('Skull', 1, HEAD, RADII, mats['skin'], head, 48)
    sphere('Nose', 0.016, F(0, 6, -0.006), (0.85, 1.1, 1.35), mats['skin'], head, 20)
    if o['hair'] != 'hijab':
        for s in (-1, 1):
            sphere('Ear %d' % s, 0.03, (0.123 * s, 0.01, 1.655), (0.38, 0.62, 1), mats['skin'], head, 20)
    if o['hair'] == 'side':
        def cut(v):
            back = min(1, max(0, (v.y + 0.05) / 0.12))
            z = 1.725 - 0.15 * back
            if abs(v.x) > 0.095:
                z = min(z, 1.66)
            return v.z > z - (0.012 if v.x < -0.02 and v.y < -0.05 else 0)
        shell('Hair', 1.07, cut, mats['hair'], head, 0.008)
        sphere('Quiff', 0.06, (0.03, -0.06, 1.795), (1.25, 0.9, 0.55), mats['hair'], head)
    elif o['hair'] == 'buzz':
        shell('Hair', 1.03, lambda v: v.z > 1.72 - 0.14 * min(1, max(0, (v.y + 0.05) / 0.12)) and not (abs(v.x) > 0.1 and v.z < 1.68), mats['hair'], head, 0.005)
        shell('Beard', 1.04, lambda v: v.y < 0.06 and (v.z < 1.566 or (abs(v.x) > 0.078 and v.z < 1.67)), mats['hair'], head, 0.006)
    else:
        shell('Hijab', 1.15, lambda v: not (v.y < -0.02 and (v.x / 0.103) ** 2 + ((v.z - 1.645) / 0.138) ** 2 < 1), mats['em'], head, 0.01)
        cone('Hijab drape', 0.2, 0.115, (0, 0.012, 1.41), (0, 0.012, 1.56), mats['em'], head, caps=False)
        line('Hijab band', [F(x, y, 0.012) for x, y in Q((-30, -16), (0, -40), (30, -16))], 0.006, mats['emD'], head)
        sphere('Pin', 0.009, (0.085, -0.135, 1.53), (1, 0.6, 1), mats['gold'], head, 12)
    for mood in MOODS:
        face(mood, head, mats)
        effects(mood, head, mats)
    for side, s in (('L', -1), ('R', 1)):
        arm(side, s, rig, o, mats)
    return root


# ------------------------------------------------------------ the moods in motion

def value(spec, t):
    """A pose value at t in [0, 1): a fixed list or number, or {from, to, cycles, shape}."""
    if not isinstance(spec, dict):
        return spec
    a, b, n = spec['from'], spec['to'], spec.get('cycles', 1)
    k = abs(math.sin(math.pi * n * t)) if spec.get('shape') == 'hop' else 0.5 - 0.5 * math.cos(2 * math.pi * n * t)
    return [x + (y - x) * k for x, y in zip(a, b)] if isinstance(a, list) else a + (b - a) * k


def pose(root, mood, t):
    """What CharacterMood.cs does in Unity, frame by frame."""
    p = MOODS[mood]
    rig, head = find(root, 'Rig'), find(root, 'Head')
    for side, s in (('L', 1), ('R', -1)):
        for joint, key in (('Arm', 'up'), ('Fore', 'fo')):
            own = p.get(key + 'R') if side == 'R' else None
            x, y = value(own, t) if own is not None else value(p[key], t)
            if own is None:
                y *= s
            find(root, joint + side).rotation_euler = (math.radians(x), math.radians(y), 0)
    hx, hy = value(p.get('head', [0, 0]), t)
    head.rotation_euler = (math.radians(hx), math.radians(hy), 0)
    lift = value(p.get('lift', 0), t)
    shake = p.get('shake')
    rig.location = (shake['x'] * math.sin(2 * math.pi * shake['cycles'] * t) if shake else 0, 0, lift)
    rig.rotation_euler = (0, math.radians(p.get('sway', 0)) * math.sin(2 * math.pi * t), 0)
    b = p.get('breathe', 0) * (0.5 - 0.5 * math.cos(2 * math.pi * t))
    rig.scale = (1 + b * 0.5, 1, 1 + b)
    for o in root.children_recursive:
        if base(o).startswith(('Face.', 'Fx.')):
            show = base(o).split('.', 1)[1] == mood
            for x in [o] + list(o.children_recursive):
                x.hide_render = not show
    eyes = find(root, 'Eyes.' + mood)
    eyes.scale = (1, 1, 0.12 if p.get('blink') and 0.78 <= t < 0.86 else 1)
    for o in find(root, 'Fx.' + mood).children:
        kind, rest = o.get('fx', ''), Vector(o['rest'])
        o.location, o.scale = rest, (1, 1, 1)
        if kind == 'fall':
            o.location = rest + Vector((0, 0, -0.06 * t))
            o.scale = (1, 1, 1) if t < 0.85 else (0.01, 0.01, 0.01)
        elif kind == 'rise':
            o.location = rest + Vector((0, 0, 0.05 * t))
            o.scale = [0.6 + 0.8 * t] * 3
        elif kind.startswith('dot'):
            o.scale = [1.0 if int(t * 3) >= int(kind[-1]) else 0.01] * 3
        elif kind == 'pop':
            o.scale = [min(1.25, 6 * t) if t < 0.2 else 1] * 3
        elif kind.startswith('z'):
            ph = (t + int(kind[-1]) / 3) % 1
            o.location = rest + Vector((0.01 * ph, 0, 0.035 * ph))
            o.scale = [max(0.01, math.sin(math.pi * ph))] * 3
        elif kind.startswith('spark'):
            ph = (t + int(kind[-1]) / 3) % 1
            o.scale = [0.4 + 0.7 * abs(math.sin(math.pi * 2 * ph))] * 3


def base(o):
    """An object's own name: the coaches built first carry their code (C1:Head), so the next one gets clean names."""
    return o.name.split(':', 1)[-1]


def find(root, name):
    return next(o for o in root.children_recursive if base(o) == name)


def in_face(x):
    return any(base(o).startswith(('Face.', 'Fx.')) for o in [x] + list(parents(x)))


def show_only(roots, root):
    """The body of one coach; pose() then shows the face and effects of the mood."""
    for r in roots:
        for x in [r] + list(r.children_recursive):
            x.hide_render = r is not root or in_face(x)


def parents(x):
    p = x.parent
    while p:
        yield p
        p = p.parent


def stage(size, samples):
    """A clear background and a shadow on an invisible floor, so the pictures sit on any page."""
    scene = bpy.context.scene
    c.studio(target=(0, 0, 1.1), distance=5.2, height=0.15, lens=88, floor=None)
    bpy.ops.mesh.primitive_plane_add(size=20)
    bpy.context.object.is_shadow_catcher = True
    scene.render.film_transparent = True
    scene.render.engine = 'CYCLES'
    scene.cycles.device, scene.cycles.samples, scene.cycles.use_denoising = 'CPU', samples, True
    scene.render.resolution_x, scene.render.resolution_y = size, int(size * 1.3)
    scene.view_settings.view_transform = 'AgX'
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'


def main():
    opts = c.args()
    only = opts.get('only')
    frames, size, samples = int(opts.get('frames', 12)), int(opts.get('size', 300)), int(opts.get('samples', 24))
    c.fresh()
    out = c.out_dir(opts, 'Characters')
    built = {}
    for code, o in COACHES.items():
        if only and code != only:
            continue
        root = coach(code, o)
        pose(root, 'idle', 0)
        c.export([root], os.path.join(out, code.lower() + '.fbx'))
        for x in root.children_recursive:
            x.name = code + ':' + x.name
        built[code] = root
    roots = list(built.values())
    stage(size, samples)
    scene = bpy.context.scene
    if opts.get('renders'):
        from PIL import Image
        tmp = os.path.join(c.ROOT, 'unity', 'Captures', 'characters')
        dest = os.path.join(c.ROOT, 'docs', 'design', 'legends-ui', 'characters')
        os.makedirs(tmp, exist_ok=True)
        os.makedirs(dest, exist_ok=True)
        for code, root in built.items():
            show_only(roots, root)
            for mood in (opts['mood'].split(',') if opts.get('mood') else MOODS):
                pics = []
                for f in range(frames):
                    pose(root, mood, f / frames)
                    path = os.path.join(tmp, '%s-%s-%02d.png' % (code, mood, f))
                    scene.render.filepath = path
                    bpy.ops.render.render(write_still=True)
                    pics.append(Image.open(path).convert('RGBA'))
                pics[0].save(os.path.join(dest, '%s-%s.webp' % (code.lower(), mood)), save_all=True, append_images=pics[1:],
                             duration=int(1000 / frames), loop=0, quality=82, method=6)
                print('Legends: %s %s' % (code, mood))
    # the preview: the coaches side by side, cheering
    for k, root in enumerate(roots):
        for x in [root] + list(root.children_recursive):
            x.hide_render = in_face(x)
        root.location.x = (k - (len(roots) - 1) / 2) * 1.0
        pose(root, 'cheer', 0.2)
    scene.render.film_transparent = False
    scene.camera.data.lens = 45
    c.render(c.preview_path(opts, 'characters'), 1500, 900, samples=max(samples, 32))


main()
