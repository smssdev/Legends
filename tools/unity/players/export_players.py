"""Sprint 06 U4: the players for Unity. One FBX per build (slim, medium, strong) in unity/Assets/Legends/Players/,
each holding everything a player of that build can look like, so Unity picks his look from his id (U5):

  the rig (game engine), the body with the faces and the origins as blend shapes (face_b, face_c, face_d and
  tone_<name>: the olive tone and face a are the body as it is), the kit (one mesh, its pieces told apart by its
  vertex colour), the eyes, the brows of every tone, the lashes, and every haircut (Hair_<name>), each fitted to
  every face and origin by the same blend shapes. Three LODs of each (Unity's _LOD0, _LOD1, _LOD2 names make the
  LOD Group by themselves). The skin under the kit is left out, so it never shows through it in motion.

And the textures (skins, hair, eyes, brows, lashes) in Players/Textures/, with looks.json: the tables Unity's
PlayerLook reads the same way (its test checks they match).

  blender -b -P tools/unity/players/export_players.py -- [--build medium] [--out DIR]
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bmesh
import bpy
import numpy as np
from mathutils import kdtree
import build_players as bp
import kit as kits

c = bp.c
OUT = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Players')
ClothesService = bp.mpfb('services.clothesservice').ClothesService
HumanObjectProperties = bp.mpfb('entities.objectproperties').HumanObjectProperties
Mhclo = bp.mpfb('entities.clothes.mhclo').Mhclo
LODS = ((1, 0.35), (2, 0.12))          # LOD1 and LOD2: the share of the triangles kept
LOD_PARTS = {'Body': 2, 'Kit': 2, 'Hair': 2, 'Brows': 1, 'Eyes': 1, 'Lashes': 0}   # the last LOD each part has
BASE_TONE = 'olive'


def sides(target):
    return [target] if target.split('-')[0] not in ('cheek', 'eye') else ['l-' + target, 'r-' + target]


def coords(ob):
    a = np.empty(len(ob.data.vertices) * 3, dtype=np.float32)
    ob.data.vertices.foreach_get('co', a)
    return a


def mix_of(body):
    """The body as its shape keys make it now."""
    body.shape_key_add(name='__mix', from_mix=True)
    key = body.data.shape_keys.key_blocks['__mix']
    a = np.empty(len(key.data) * 3, dtype=np.float32)
    key.data.foreach_get('co', a)
    body.shape_key_remove(key)
    return a


def set_race(body, race):
    for k in ('african', 'asian', 'caucasian'):
        HumanObjectProperties.set_value(k, race.get(k, 0.0), entity_reference=body)
    bp.TargetService.reapply_macro_details(body, remove_zero_weight_targets=False)


def human(build):
    """The body of this build at MakeHuman's own size, with every face's targets loaded at 0, and every asset."""
    muscle, weight = bp.BUILDS[build]
    race = bp.TONES[BASE_TONE][0]
    macro = {'gender': 1.0, 'age': 0.5, 'muscle': muscle, 'weight': weight, 'proportions': 0.8, 'height': 0.6,
             'cupsize': 0.5, 'firmness': 0.5, 'race': {'african': 0.0, 'asian': 0.0, 'caucasian': 0.0, **race}}
    body = bp.HumanService.create_human(macro_detail_dict=macro, scale=0.1)
    body.name = 'Body'
    faces = {}
    for face, targets in bp.FACES.items():
        for target, w in targets.items():
            for t in sides(target):
                key = bp.TargetService.load_target(body, bp.TargetService.target_full_path(t), weight=0.0)
                faces.setdefault(face, []).append((key.name, w))
    rig = bp.HumanService.add_builtin_rig(body, 'game_engine')
    rig.name = 'Player'
    assets = {}
    wanted = [('Eyes', 'Eyes', 'high-poly', 'eyes'), ('Lashes', 'Eyelashes', 'eyelashes01', 'eyelashes')]
    wanted += [('Brows_' + b, 'Eyebrows', b, 'eyebrows') for b in sorted(set(bp.BROWS.values()))]
    wanted += [('Hair_' + h, 'Clothes', h, 'hair') for h in bp.HAIRS if h and h != 'buzz']
    for name, kind, fragment, folder in wanted:
        before = set(bpy.data.objects)
        path = bp.find(fragment, folder, '.mhclo')
        bp.HumanService.add_mhclo_asset(path, body, asset_type=kind, subdiv_levels=0, material_type='GAMEENGINE')
        ob = next(o for o in bpy.data.objects if o not in before and o.type == 'MESH')
        ob.name = name
        ob['legends_mhclo'] = path       # MPFB looks for hair among the clothes when it refits: we tell it
        assets[name] = ob
    return rig, body, faces, assets


def refit(ob, body):
    m = Mhclo()
    m.load(ob['legends_mhclo'])
    m.clothes = ob
    ClothesService.fit_clothes_to_human(ob, body, mhclo=m, set_parent=False)


def variants(body, faces, assets):
    """Every face and origin other than the base: the body's shape and each asset fitted to it."""
    out = {}
    def capture(name):
        for ob in assets.values():
            refit(ob, body)
        out[name] = {'Body': mix_of(body), **{n: coords(ob) for n, ob in assets.items()}}
    for face, keys in faces.items():
        if face == 'a':
            continue
        for k, w in keys:
            body.data.shape_keys.key_blocks[k].value = w
        capture('face_' + face)
        for k, _ in keys:
            body.data.shape_keys.key_blocks[k].value = 0.0
    for tone, (race, _, _) in bp.TONES.items():
        if tone == BASE_TONE:
            continue
        set_race(body, race)
        capture('tone_' + tone)
    set_race(body, bp.TONES[BASE_TONE][0])
    for ob in assets.values():
        refit(ob, body)
    return out


def bake(body, assets, shapes):
    """The base shape becomes each mesh's own, and the variants its blend shapes (MPFB's keys are dropped)."""
    base = mix_of(body)
    body.shape_key_clear()
    body.data.vertices.foreach_set('co', base)
    for ob, name in [(body, 'Body')] + [(o, n) for n, o in assets.items()]:
        if ob.data.shape_keys:
            ob.shape_key_clear()
        ob.shape_key_add(name='Basis')
        for variant, data in shapes.items():
            key = ob.shape_key_add(name=variant)
            key.data.foreach_set('co', data[name])
            key.value = 0.0          # Blender starts a new key at 1: every shape is off until Unity turns it on
        ob.data.update()


def drop_helpers(body):
    """MakeHuman's helper geometry (the tights, the skirt, the joints...) is hidden by a modifier; here it goes."""
    keep = body.vertex_groups['body'].index
    body.active_shape_key_index = 0     # bmesh writes into the active shape: it must be the Basis
    bm = bmesh.new()
    bm.from_mesh(body.data)
    deform = bm.verts.layers.deform.active
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if keep not in v[deform]], context='VERTS')
    bm.to_mesh(body.data)
    bm.free()
    for m in [m for m in body.modifiers if m.type == 'MASK']:
        body.modifiers.remove(m)


def one_material(ob, name):
    """One slot: Unity gives each part its material (PlayerLook), the FBX carries none of its own."""
    for p in ob.data.polygons:
        p.material_index = 0
    ob.data.materials.clear()
    ob.data.materials.append(bpy.data.materials.get(name) or bpy.data.materials.new(name))


def uncover(body, kit):
    """Leaves out the skin the kit covers: a vertex within 2.5 cm under the kit and 3 cm from its open edges."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts, rims = [], []
    me = kit.evaluated_get(dg).to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    for v in bm.verts:
        pts.append(kit.matrix_world @ v.co)
        if v.is_boundary:
            rims.append(kit.matrix_world @ v.co)
    bm.free()
    kit.evaluated_get(dg).to_mesh_clear()
    near, rim = kdtree.KDTree(len(pts)), kdtree.KDTree(max(1, len(rims)))
    for i, p in enumerate(pts):
        near.insert(p, i)
    for i, p in enumerate(rims):
        rim.insert(p, i)
    near.balance()
    rim.balance()
    covered = set()
    for v in body.data.vertices:
        p = body.matrix_world @ v.co
        if near.find(p)[2] < 0.025 and (not rims or rim.find(p)[2] > 0.03):
            covered.add(v.index)
    body.active_shape_key_index = 0     # bmesh writes into the active shape: it must be the Basis
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if all(v.index in covered for v in f.verts)], context='FACES_ONLY')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.to_mesh(body.data)
    bm.free()
    print('Legends: %d skin vertices under the kit left out' % len(covered))


def follow(body, ob):
    """Gives a mesh made from the body (the kit, the shaved head) the body's blend shapes: each vertex moves as the
    body's nearest vertex does, so a rounder hip or head never pokes through it."""
    keys = body.data.shape_keys.key_blocks
    base = np.empty(len(body.data.vertices) * 3, dtype=np.float32)
    keys['Basis'].data.foreach_get('co', base)
    base = base.reshape(-1, 3)
    tree = kdtree.KDTree(len(base))
    for i, p in enumerate(base):
        tree.insert(p, i)
    tree.balance()
    to_body = body.matrix_world.inverted() @ ob.matrix_world
    nearest = np.array([tree.find(to_body @ v.co)[1] for v in ob.data.vertices])
    mine = coords(ob).reshape(-1, 3)
    ob.shape_key_add(name='Basis')
    for k in keys[1:]:
        co = np.empty(len(base) * 3, dtype=np.float32)
        k.data.foreach_get('co', co)
        delta = (co.reshape(-1, 3) - base)[nearest]
        key = ob.shape_key_add(name=k.name)
        key.data.foreach_set('co', (mine + delta).ravel())
        key.value = 0.0
    ob.data.update()


def one_kit(pieces):
    """The four pieces as one mesh (Unity draws it in one call, the vertex colour tells the pieces apart)."""
    for ob in pieces.values():
        for m in [m for m in ob.modifiers if m.type == 'SOLIDIFY']:
            ob.modifiers.remove(m)          # Unity draws the kit from both sides instead
    obs = list(pieces.values())
    with bpy.context.temp_override(active_object=obs[0], selected_editable_objects=obs, object=obs[0]):
        bpy.ops.object.join()
    obs[0].name = 'Kit'
    return obs[0]


def lods(ob, part):
    """_LOD0 (this mesh, with its blend shapes) and the lighter ones, decimated, without them."""
    made = [ob]
    for level, ratio in LODS:
        if level > LOD_PARTS[part]:
            break
        copy = ob.copy()
        copy.data = ob.data.copy()
        bpy.context.collection.objects.link(copy)
        if copy.data.shape_keys:
            copy.shape_key_clear()
        dec = copy.modifiers.new('Decimate', 'DECIMATE')
        dec.ratio = ratio
        with bpy.context.temp_override(object=copy, active_object=copy):
            bpy.ops.object.modifier_move_to_index(modifier='Decimate', index=0)
            bpy.ops.object.modifier_apply(modifier='Decimate')
        copy.name = ob.name + '_LOD%d' % level
        made.append(copy)
    ob.name = ob.name + '_LOD0'
    return made


def triangles(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def save_texture(src, dst, size=1024):
    """A texture for Unity, at most `size` pixels a side (a player is never closer than a close-up). JPEG unless it
    needs its alpha (.png), to keep the repository light."""
    img = bpy.data.images.load(src)
    w, h = img.size
    if max(w, h) > size:
        img.scale(size * w // max(w, h), size * h // max(w, h))
    img.filepath_raw, img.file_format = dst, 'PNG' if dst.endswith('.png') else 'JPEG'
    bpy.context.scene.render.image_settings.quality = 90
    img.save()
    bpy.data.images.remove(img)


def mhmat_texture(path, key='diffuseTexture'):
    for line in open(path, encoding='utf-8', errors='replace'):
        m = re.match(r'\s*%s\s+(\S+)' % key, line)
        if m:
            return os.path.join(os.path.dirname(path), m.group(1))
    return None


def textures(out):
    """The skins of every tone, and the hair, eyes, brows and lashes, with looks.json."""
    folder = os.path.join(out, 'Textures')
    os.makedirs(folder, exist_ok=True)
    tones = {}
    for tone, (race, skin, tint) in bp.TONES.items():
        mat = bp.find(skin, 'skins', '.mhmat')
        save_texture(mhmat_texture(mat), os.path.join(folder, 'skin_%s.jpg' % skin))
        normal = mhmat_texture(mat, 'normalmapTexture')
        if normal and os.path.exists(normal):
            save_texture(normal, os.path.join(folder, 'skin_%s_normal.png' % skin), 512)
        tones[tone] = {'skin': skin, 'tint': tint, 'brows': bp.BROWS[tone], 'normal': bool(normal and os.path.exists(normal))}
    for name, folder_name in [(h, 'hair') for h in bp.HAIRS if h and h != 'buzz'] + \
                             [(b, 'eyebrows') for b in sorted(set(bp.BROWS.values()))] + [('eyelashes01', 'eyelashes')]:
        mhclo = bp.find(name, folder_name, '.mhclo')
        mat = next((os.path.join(os.path.dirname(mhclo), f) for f in os.listdir(os.path.dirname(mhclo)) if f.endswith('.mhmat')), None)
        tex = mat and mhmat_texture(mat)
        if tex and os.path.exists(tex):
            save_texture(tex, os.path.join(folder, '%s.png' % name), 512)
    eye = bp.find('brown_eye.png', 'eyes', '') or os.path.join(os.path.dirname(bp.find('high-poly', 'eyes', '.mhclo')), '..', 'materials', 'brown_eye.png')
    save_texture(eye, os.path.join(folder, 'eye_brown.png'), 256)
    looks = {
        'builds': list(bp.BUILDS), 'base_tone': BASE_TONE, 'tones': tones, 'faces': list(bp.FACES),
        'hairs': [h or 'bald' for h in bp.HAIRS], 'hair_colours': bp.HAIR_COLOURS, 'height': bp.HEIGHT,
        'height_range': [1.70, 1.92],
    }
    with open(os.path.join(out, 'looks.json'), 'w', encoding='utf-8') as f:
        json.dump(looks, f, indent=2)
        f.write('\n')


def scale_all(rig, k):
    """Every mesh and bone k times bigger, in their own data: nothing in the file is scaled."""
    from mathutils import Matrix
    for ob in rig.children_recursive:
        if ob.type == 'MESH':
            ob.data.transform(Matrix.Scale(k, 4), shape_keys=True)
            ob.data.update()
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    for b in rig.data.edit_bones:
        b.head *= k
        b.tail *= k
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.context.view_layer.update()


def export(build, out):
    bp.clear()
    rig, body, faces, assets = human(build)
    shapes = variants(body, faces, assets)
    bake(body, assets, shapes)
    drop_helpers(body)
    # The size: every player 1.82 m, Unity scales him to his own height.
    h, _ = bp.evaluated_height(body)
    scale_all(rig, bp.HEIGHT / h)
    buzz = bp.buzz(body, bp.HAIR_COLOURS['dark'])
    buzz.name = 'Hair_buzz'
    for g in body.vertex_groups:
        buzz.vertex_groups.new(name=g.name)
    buzz.modifiers.new('Armature', 'ARMATURE').object = rig
    kit = one_kit(kits.dress(rig, body))
    follow(body, kit)
    follow(body, buzz)
    uncover(body, kit)
    parts = [(body, 'Body', 'Skin'), (kit, 'Kit', 'Kit'), (buzz, 'Hair', 'Hair_buzz')]
    parts += [(o, n.split('_')[0] if not n.startswith('Hair') else 'Hair', n) for n, o in assets.items()]
    made = []
    for ob, part, material in parts:
        one_material(ob, material)
        made += lods(ob, part)
    for ob in made:
        print('Legends: %-22s %6d triangles%s' % (ob.name, triangles(ob), '' if not ob.data.shape_keys else ', blend shapes: ' + ' '.join(k.name for k in ob.data.shape_keys.key_blocks[1:])))
    path = os.path.join(out, 'player_%s.fbx' % build)
    os.makedirs(out, exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in [rig] + made:
        ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, apply_scale_options='FBX_SCALE_UNITS',
                             axis_forward='-Z', axis_up='Y', mesh_smooth_type='FACE', add_leaf_bones=False,
                             use_armature_deform_only=True, bake_anim=False, use_mesh_modifiers=False, path_mode='STRIP',
                             object_types={'ARMATURE', 'MESH'})
    print('Legends: exported', path, '%.1f MB' % (os.path.getsize(path) / 1e6))


def main():
    opts = c.args()
    out = opts.get('out') or OUT
    for build in ([opts['build']] if opts.get('build') else list(bp.BUILDS)):
        export(build, out)
    textures(out)


if __name__ == '__main__':
    main()
