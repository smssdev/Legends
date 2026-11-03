"""Sprint 06: Legends' players, real-looking and our own (PLAN 7.11, the owner's 2026-11-03): MakeHuman bodies through
MPFB with MakeHuman's CC0 skins, eyes, brows and short hair, on the game engine rig. Faces are made up and look
like no one.

Needs setup_blender.py once. Then:
  blender -b -P tools/unity/players/build_players.py -- [--only NAME] [--close] [--preview FILE]

Day 1 makes the first people to judge the look (U0); the kit (U3), the export (U4) and the full set of builds,
skins, hair and faces (U2) follow in this file.
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

# name, race share, muscle, weight, height (0..1, MakeHuman's macro sliders), skin, hair, brows, hair colour
PEOPLE = [
    ('Player A', {'african': 1.0}, 0.80, 0.45, 0.62, 'young_african_male', 'short02', 'eyebrow001', '#3a3a3a'),
    ('Player B', {'caucasian': 1.0}, 0.65, 0.45, 0.55, 'young_caucasian_male', 'short04', 'eyebrow007', '#8a6a48'),
    ('Player C', {'caucasian': 0.6, 'african': 0.4}, 0.70, 0.40, 0.50, 'middleage_caucasian_male', 'short01', 'eyebrow009', '#4a3424'),
    ('Player D', {'asian': 0.8, 'caucasian': 0.2}, 0.60, 0.40, 0.45, 'young_asian_male', 'short03', 'eyebrow003', '#3a3a3a'),
]


def find(fragment, subdir, ext):
    """An asset by a fragment of its name, in MPFB's data and the packs we unpacked there."""
    path = AssetService.find_asset_absolute_path(fragment + ext, subdir) or AssetService.find_asset_absolute_path(fragment, subdir)
    if not path:
        print('Legends: no %s %s' % (subdir, fragment))
    return path


def person(name, race, muscle, weight, height, skin, hair, brows, hair_colour):
    macro = {'gender': 1.0, 'age': 0.5, 'muscle': muscle, 'weight': weight, 'proportions': 0.7, 'height': height,
             'cupsize': 0.5, 'firmness': 0.5, 'race': {'african': 0.0, 'asian': 0.0, 'caucasian': 0.0, **race}}
    body = HumanService.create_human(macro_detail_dict=macro, scale=0.1)
    body.name = name
    rig = HumanService.add_builtin_rig(body, 'game_engine')
    print('Legends: %s is %.2f m tall' % (name, body.dimensions.z))
    skin_file = find(skin, 'skins', '.mhmat')
    if skin_file:
        # The game engine skin: one Principled material on the skin's own textures, what Unity reads from the FBX.
        HumanService.set_character_skin(skin_file, body, skin_type='GAMEENGINE')
    for part, fragment in (('eyes', 'brown'), ('eyebrows', brows), ('eyelashes', 'eyelashes01'), ('hair', hair)):
        path = find(fragment, part, '.mhclo') if part != 'eyes' else find('high-poly', 'eyes', '.mhclo')
        if path:
            HumanService.add_mhclo_asset(path, body, asset_type=part.capitalize() if part != 'eyelashes' else 'Eyelashes',
                                         subdiv_levels=0, material_type='MAKESKIN')
    tint_hair(body, hair_colour)
    return rig or body


def tint_hair(body, colour):
    """The hair and brows in their colour: the asset's texture keeps its strands, its colour comes from ours."""
    for ob in bpy.data.objects:
        if ob.parent not in (body, body.parent) or not any(k in ob.name for k in ('short', 'afro', 'eyebrow')):
            continue
        for slot in ob.material_slots:
            for n in slot.material.node_tree.nodes:
                if n.bl_idname == 'ShaderNodeMixRGB':
                    n.blend_type = 'MULTIPLY'
                    n.inputs[0].default_value = 1.0
                    n.inputs[1 if n.inputs[2].is_linked else 2].default_value = (*c.srgb(colour), 1)


def clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def head_of(top):
    """Where the head is, from the game engine rig's head bone (the camera aims there)."""
    if top.type == 'ARMATURE' and 'head' in top.pose.bones:
        b = top.pose.bones['head']
        return tuple(top.matrix_world @ ((b.head + b.tail) / 2))
    return (top.location.x, 0, 1.65)


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


def main():
    opts = c.args()
    clear()
    chosen = [p for p in PEOPLE if not opts.get('only') or p[0] == opts['only']]
    tops = []
    for i, p in enumerate(chosen):
        top = person(*p)
        top.location.x = (i - (len(chosen) - 1) / 2) * 0.9
        bpy.context.view_layer.update()
        tops.append(top)
    # Judged in plain daylight on a grey floor, so the skin is its own colour.
    if opts.get('close'):
        # One portrait each, side by side in one picture (A-posed arms would cover the faces in one shot).
        path = c.preview_path(opts, 'players-close')
        parts = []
        for i, t in enumerate(tops):
            for ob in tops:
                for o in [ob, *ob.children_recursive]:
                    o.hide_render = ob is not t
            hx, hy, hz = head_of(t)
            for ob in [o for o in bpy.data.objects if o.type in ('LIGHT', 'CAMERA') or o.name == 'Floor']:
                bpy.data.objects.remove(ob, do_unlink=True)
            c.studio(target=(hx, hy, hz - 0.1), distance=1.5, height=0.05, lens=85, floor='#6f6f6f', night=False)
            part = path[:-4] + '-%d.png' % i
            c.render(part, 700, 900, samples=96)
            parts.append(part)
        sheet(parts, path)
    else:
        c.studio(target=(0, 0, 0.95), distance=5.2, height=0.3, lens=50, floor='#6f6f6f', night=False)
        c.render(c.preview_path(opts, 'players'), 1600, 900, samples=96)


main()
