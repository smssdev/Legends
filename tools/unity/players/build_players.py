"""Sprint 06: Legends' players, real-looking and our own (PLAN 7.11, the owner's 2026-11-03): MakeHuman bodies through
MPFB with MakeHuman's CC0 skins, eyes, brows and hair, on the game engine rig. Faces are made up and look like no one.

Every player is one of 3 builds x 6 skin tones x 8 haircuts x 4 faces (U2), picked in Unity from his id (U5).

Needs setup_blender.py once. Then:
  blender -b -P tools/unity/players/build_players.py -- --sheet hair|tones|faces|builds [--preview FILE]

A sheet is one portrait per choice of that table, the others at their first value, to judge them side by side
(unity/Reference/players/<sheet>.png by default). The kit (U3) and the export (U4) follow in this file.
"""
import importlib, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'art'))
import bpy, addon_utils
import common as c


def mpfb(module):
    for mod in addon_utils.modules():
        if mod.__name__.endswith('.mpfb'):
            return importlib.import_module(mod.__name__ + '.' + module)
    sys.exit('Legends: MPFB is not installed: run tools/unity/players/setup_blender.py first')


HumanService = mpfb('services.humanservice').HumanService
AssetService = mpfb('services.assetservice').AssetService
TargetService = mpfb('services.targetservice').TargetService

# The build: MakeHuman's muscle and weight (0..1). Every player is made 1.82 m; Unity scales him to his own height
# (1.70 to 1.92) from his id, so one body serves every height.
BUILDS = {'medium': (0.68, 0.42), 'slim': (0.42, 0.18), 'strong': (0.98, 0.72)}
HEIGHT = 1.82

# The skin tone: the share of each origin in the body and face, MakeHuman's own skin, and a colour it is multiplied
# by (white keeps it as it is). Olive and brown are the Arab, North African and South Asian players the data is full of.
TONES = {
    'olive': ({'caucasian': 0.75, 'african': 0.15, 'asian': 0.10}, 'young_caucasian_male', '#c8976e'),
    'light': ({'caucasian': 1.0}, 'young_caucasian_male', '#f4dccb'),
    'fair': ({'caucasian': 0.9, 'asian': 0.1}, 'young_caucasian_male2', '#e0b892'),
    'east_asian': ({'asian': 0.9, 'caucasian': 0.1}, 'young_asian_male', '#f2d6bc'),
    'brown': ({'caucasian': 0.45, 'african': 0.45, 'asian': 0.10}, 'young_asian_male', '#9a6f55'),
    'dark': ({'african': 1.0}, 'young_african_male', '#ffffff'),
}

# The haircut: one of MakeHuman's (CC0), or made here: 'buzz' (a shaved head) and None (bald).
HAIRS = ['short02', 'buzz', None, 'short01', 'short04', 'afro01', 'ponytail01', 'long01']
# Left out of MakeHuman's: short03 hangs over an eye, the bobs and the braid are not a player's.

# The face: MakeHuman targets and their weights, l- and r- together. Made up, to look like no one.
FACES = {
    'a': {},
    'b': {'chin-prominent-incr': 0.9, 'head-square': 0.8, 'chin-width-incr': 0.7, 'nose-hump-incr': 0.8, 'nose-scale-horiz-incr': 0.4,
          'eyebrows-trans-down': 0.6, 'cheek-bones-incr': 0.6, 'mouth-scale-horiz-incr': 0.3},
    'c': {'head-oval': 1.0, 'head-scale-horiz-decr': 0.4, 'nose-scale-vert-incr': 0.7, 'nose-point-width-decr': 0.6,
          'chin-height-incr': 0.6, 'cheek-volume-decr': 0.8, 'mouth-scale-horiz-decr': 0.4, 'eye-scale-decr': 0.3},
    'd': {'head-round': 0.9, 'head-fat-incr': 0.5, 'cheek-volume-incr': 0.8, 'nose-volume-incr': 0.8, 'nose-flaring-incr': 0.6,
          'nose-scale-horiz-incr': 0.5, 'mouth-lowerlip-volume-incr': 0.6, 'mouth-upperlip-volume-incr': 0.5, 'chin-width-incr': 0.5,
          'eye-scale-incr': 0.2},
}
HAIR_COLOURS = {'dark': '#2b2622', 'brown': '#5a412c', 'blond': '#a8865c'}
BROWS = {'olive': 'eyebrow001', 'light': 'eyebrow007', 'fair': 'eyebrow009', 'east_asian': 'eyebrow003', 'brown': 'eyebrow001', 'dark': 'eyebrow001'}


def find(fragment, subdir, ext):
    """An asset by a fragment of its name, in MPFB's data and the packs we unpacked there."""
    path = AssetService.find_asset_absolute_path(fragment + ext, subdir) or AssetService.find_asset_absolute_path(fragment, subdir)
    if not path:
        print('Legends: no %s %s' % (subdir, fragment))
    return path


def person(build='medium', tone='olive', hair='short02', face='a', hair_colour='dark', name='Player'):
    muscle, weight = BUILDS[build]
    race, skin, tint = TONES[tone]
    macro = {'gender': 1.0, 'age': 0.5, 'muscle': muscle, 'weight': weight, 'proportions': 0.8, 'height': 0.6,
             'cupsize': 0.5, 'firmness': 0.5, 'race': {'african': 0.0, 'asian': 0.0, 'caucasian': 0.0, **race}}
    body = HumanService.create_human(macro_detail_dict=macro, scale=0.1)
    body.name = name
    for target, w in FACES[face].items():
        for t in ([target] if target.split('-')[0] not in ('cheek', 'eye') else ['l-' + target, 'r-' + target]):
            path = TargetService.target_full_path(t)
            if not path:
                sys.exit('Legends: no target ' + t)
            TargetService.load_target(body, path, weight=w)
    rig = HumanService.add_builtin_rig(body, 'game_engine')
    # The game engine skin: one Principled material on the skin's own textures, what Unity reads from the FBX.
    HumanService.set_character_skin(find(skin, 'skins', '.mhmat'), body, skin_type='GAMEENGINE')
    for slot in body.material_slots:
        multiply(slot.material, tint)
    parts = [('Eyes', find('high-poly', 'eyes', '.mhclo')), ('Eyebrows', find(BROWS[tone], 'eyebrows', '.mhclo')),
             ('Eyelashes', find('eyelashes01', 'eyelashes', '.mhclo'))]
    if hair and hair != 'buzz':
        parts.append(('Hair', find(hair, 'hair', '.mhclo')))
    for kind, path in parts:
        HumanService.add_mhclo_asset(path, body, asset_type=kind, subdiv_levels=0, material_type='MAKESKIN')
    top = rig or body
    fit_height(top, body)
    if hair == 'buzz':
        buzz(body, HAIR_COLOURS[hair_colour])
    for ob in top.children_recursive:
        if any(k in ob.name for k in ('eyebrow', *(h for h in HAIRS if h))):
            for slot in ob.material_slots:
                multiply(slot.material, HAIR_COLOURS[hair_colour])
    return top, body


def multiply(material, colour):
    """Multiplies a material's colour (its texture, or its plain colour) by ours; white leaves it as it is."""
    if not material or not material.use_nodes or colour.lower() == '#ffffff':
        return
    tree = material.node_tree
    bsdf = next((n for n in tree.nodes if n.bl_idname == 'ShaderNodeBsdfPrincipled'), None)
    if not bsdf:
        return
    base = bsdf.inputs['Base Color']
    mix = tree.nodes.new('ShaderNodeMixRGB')
    mix.blend_type, mix.inputs[0].default_value = 'MULTIPLY', 1.0
    mix.inputs[2].default_value = (*c.srgb(colour), 1)
    if base.is_linked:
        tree.links.new(base.links[0].from_socket, mix.inputs[1])
    else:
        mix.inputs[1].default_value = base.default_value[:]
    tree.links.new(mix.outputs[0], base)


def evaluated_height(body):
    """The body's own height: the evaluated mesh, so the helpers MPFB hides are left out."""
    bpy.context.view_layer.update()
    ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    zs = [(ev.matrix_world @ v.co).z for v in ev.to_mesh().vertices]
    ev.to_mesh_clear()
    return max(zs) - min(zs), max(zs)


def fit_height(top, body):
    h, _ = evaluated_height(body)
    top.scale = [s * HEIGHT / h for s in top.scale]
    bpy.context.view_layer.update()


def buzz(body, colour):
    """A shaved head: the scalp lifted 1.5 mm off the skin, fading out at the hairline (its vertex colour's alpha,
    which Unity's hair shader reads too), with stubble in the hair's colour."""
    import bmesh
    from mathutils import Vector
    ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    me = bpy.data.meshes.new_from_object(ev)
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(body.matrix_world)
    _, top = evaluated_height(body)
    ys = [v.co.y for v in bm.verts if v.co.z > top - 0.12]
    centre = Vector((0, (max(ys) + min(ys)) / 2, top - 0.115))

    def scalp(p):
        """1 on the scalp, 0 off it, fading over 2.5 cm at the hairline."""
        d = p - centre
        front = max(-1.0, min(1.0, -d.y / 0.1))  # MakeHuman faces -Y: 1 at the forehead, -1 at the nape
        line = 0.04 - 0.015 * (1 - front) if front > 0 else 0.025 + 0.1 * front
        s = max(0.0, min(1.0, (d.z - line) / 0.025))
        if abs(d.x) > 0.068:                     # above the ears the line rises
            s *= max(0.0, min(1.0, (d.z - 0.01) / 0.02))
        return s
    weight = {v.index: scalp(v.co) for v in bm.verts}
    drop = [f for f in bm.faces if all(weight[v.index] == 0 for v in f.verts)]
    bmesh.ops.delete(bm, geom=drop, context='FACES')
    fade = bm.loops.layers.color.new('fade')
    for f in bm.faces:
        for loop in f.loops:
            loop[fade] = (1, 1, 1, scalp(loop.vert.co))
    for v in bm.verts:
        v.co += v.normal * 0.0015
    bm.to_mesh(me)
    bm.free()
    ob = c.link(bpy.data.objects.new(body.name + '.buzz', me))
    ob.data.materials.clear()
    ob.data.materials.append(stubble(colour))
    ob.parent = body.parent or body
    ob.matrix_parent_inverse = ob.parent.matrix_world.inverted()
    return ob


def stubble(colour):
    """Short hair seen from a metre: the hair's colour, its cover from the fade times fine noise."""
    m = bpy.data.materials.new('Stubble ' + colour)
    m.use_nodes = True
    t = m.node_tree
    p = t.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*c.srgb(colour), 1)
    p.inputs['Roughness'].default_value = 0.9
    attr = t.nodes.new('ShaderNodeVertexColor')
    attr.layer_name = 'fade'
    noise = t.nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 900
    ramp = t.nodes.new('ShaderNodeMapRange')
    ramp.inputs['From Min'].default_value, ramp.inputs['From Max'].default_value = 0.3, 0.55
    ramp.inputs['To Min'].default_value = 0.4                     # the skin shows through, never bare
    t.links.new(noise.outputs['Fac'], ramp.inputs['Value'])
    mul = t.nodes.new('ShaderNodeMath')
    mul.operation = 'MULTIPLY'
    t.links.new(attr.outputs['Alpha'], mul.inputs[0])
    t.links.new(ramp.outputs['Result'], mul.inputs[1])
    cover = t.nodes.new('ShaderNodeMath')
    cover.operation, cover.inputs[1].default_value = 'MULTIPLY', 0.9    # never as dark as a cap
    t.links.new(mul.outputs[0], cover.inputs[0])
    t.links.new(cover.outputs[0], p.inputs['Alpha'])
    m.diffuse_color = (*c.srgb(colour), 1)
    return m


def head_of(top):
    """Where the head is, from the game engine rig's head bone (the camera aims there)."""
    if top.type == 'ARMATURE' and 'head' in top.pose.bones:
        b = top.pose.bones['head']
        return tuple(top.matrix_world @ ((b.head + b.tail) / 2))
    return (top.location.x, 0, 1.65)


def clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.armatures):
        for d in list(block):
            if not d.users:
                block.remove(d)


def portrait(path, chest=False, **look):
    """One player's head and shoulders (or chest, to judge a build), in plain daylight on a grey floor, so the skin
    is its own colour."""
    clear()
    top, _ = person(**look)
    hx, hy, hz = head_of(top)
    if chest:
        c.studio(target=(hx, hy, hz - 0.26), distance=2.0, height=0.05, lens=85, floor='#6f6f6f', night=False)
    else:
        c.studio(target=(hx, hy, hz - 0.1), distance=1.5, height=0.05, lens=85, floor='#6f6f6f', night=False)
    bpy.context.scene.view_settings.exposure = -0.25
    c.render(path, 600, 800, samples=64)


def sheet(parts, path):
    """The portraits in one row, saved as one picture."""
    import numpy as np
    imgs = [bpy.data.images.load(p) for p in parts]
    w, h = imgs[0].size
    rows = [np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4) for im in imgs]
    out = bpy.data.images.new('sheet', w * len(rows), h, alpha=True)
    out.pixels = np.concatenate(rows, axis=1).ravel().tolist()
    out.filepath_raw, out.file_format = path, 'PNG'
    out.save()
    for p in parts:
        os.remove(p)
    print('Legends: preview', path)


SHEETS = {
    'hair': ('hair', HAIRS),
    'tones': ('tone', list(TONES)),
    'faces': ('face', list(FACES)),
    'builds': ('build', ['slim', 'medium', 'strong']),
}


def main():
    opts = c.args()
    key, values = SHEETS[opts.get('sheet', 'tones')]
    if opts.get('values'):
        values = [None if v == 'none' else v for v in opts['values'].split(',')]
    path = opts.get('preview') or os.path.join(c.ROOT, 'unity', 'Reference', 'players', opts.get('sheet', 'tones') + '.png')
    parts = []
    for i, v in enumerate(values):
        part = path[:-4] + '-%d.png' % i
        look = {k: opts[k] for k in ('build', 'tone', 'hair', 'face', 'hair_colour') if k in opts}
        portrait(part, chest=key == 'build', **{**look, key: v})
        parts.append(part)
    sheet(parts, path)


main()
