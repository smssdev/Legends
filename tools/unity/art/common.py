"""What every art script shares: the arguments, materials in the Legends colours, a studio to look at the
result, the preview render, and the FBX export Unity reads.

Each script runs in Blender without opening it (free, blender.org):
  blender -b -P tools/unity/art/<script>.py -- [--out DIR] [--preview FILE]
or with Blender as a Python module (pip install bpy): python tools/unity/art/<script>.py -- ...
"""
import math, os, sys
import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))

# the brand (docs/design/tokens.json, PLAN 1)
NAVY, GOLD, GOLD_DARK, PITCH, IVORY = '#0A1F42', '#F5B82E', '#C08A0C', '#1E9E4A', '#F7F4EA'


def args():
    """--out: where the FBX files go (Unity imports them from there); --preview: the picture to look at."""
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    opts = {}
    for i, k in enumerate(a):
        if k.startswith('--'):
            opts[k[2:]] = a[i + 1] if i + 1 < len(a) and not a[i + 1].startswith('--') else True
    return opts


def fresh():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def srgb(h):
    """A hex colour as Blender's linear RGB."""
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def mat(name, color, rough=0.6, metal=0.0, emit=0.0, sheen=0.0):
    """One material by name, made once; color is a hex string."""
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*srgb(color), 1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if emit:
        p.inputs['Emission Color'].default_value = (*srgb(color), 1)
        p.inputs['Emission Strength'].default_value = emit
    if sheen and 'Sheen Weight' in p.inputs:
        p.inputs['Sheen Weight'].default_value = sheen
    m.diffuse_color = (*srgb(color), 1)   # what Unity shows when it imports the FBX
    return m


def link(ob, parent=None):
    bpy.context.collection.objects.link(ob)
    if parent:
        ob.parent = parent
    return ob


def empty(name, parent=None):
    return link(bpy.data.objects.new(name, None), parent)


def box(name, size, at, material, parent=None, rot=(0, 0, 0)):
    """A box of size (x, y, z) metres centred at `at`."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=at, rotation=rot)
    ob = bpy.context.object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(material)
    if parent:
        ob.parent = parent
    return ob


def tube(name, radius, a, b, material, parent=None, sides=16):
    """A cylinder from point a to point b (the posts, the bars, the masts)."""
    ax, ay, az = a
    bx, by, bz = b
    dx, dy, dz = bx - ax, by - ay, bz - az
    length = math.sqrt(dx * dx + dy * dy + dz * dz)
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=length,
                                        location=((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2))
    ob = bpy.context.object
    ob.name = name
    ob.rotation_euler = (math.acos(dz / length) if length else 0, 0, math.atan2(dy, dx) + math.pi / 2)
    bpy.ops.object.transform_apply(rotation=True)
    ob.data.materials.append(material)
    if parent:
        ob.parent = parent
    return ob


def studio(target=(0, 0, 1), distance=6.0, height=1.6, lens=50, floor=PITCH, night=True):
    """A plain studio to judge the result: a floor, three soft lights and a camera aimed at `target`."""
    scene = bpy.context.scene
    world = bpy.data.worlds.new('world')
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.02, 0.03, 0.06, 1) if night else (0.55, 0.7, 0.9, 1)
    bg.inputs['Strength'].default_value = 0.6 if night else 1.0
    if floor:
        bpy.ops.mesh.primitive_plane_add(size=400)
        bpy.context.object.name = 'Floor'
        bpy.context.object.data.materials.append(mat('Floor', floor, 0.9))
    for name, loc, energy, size in (('Key', (4, -6, 7), 1800, 5), ('Fill', (-6, -5, 4), 600, 6), ('Rim', (0, 6, 6), 1200, 6)):
        d = bpy.data.lights.new(name, 'AREA')
        d.energy, d.size = energy * distance / 6, size
        o = link(bpy.data.objects.new(name, d))
        o.location = (target[0] + loc[0] * distance / 6, target[1] + loc[1] * distance / 6, target[2] + loc[2] * distance / 6)
        aim(o, target)
    cam = bpy.data.cameras.new('Camera')
    cam.lens = lens
    cam.clip_end = 2000
    c = link(bpy.data.objects.new('Camera', cam))
    c.location = (target[0] + distance * 0.55, target[1] - distance, target[2] + height)
    aim(c, target)
    scene.camera = c
    return c


def aim(ob, target):
    from mathutils import Vector
    d = Vector(target) - ob.location
    ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()


def render(path, width=1600, height=1000, samples=48, view='AgX'):
    """The preview picture (Cycles on the processor, so it works on any machine)."""
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.view_settings.view_transform = view
    scene.render.filepath = os.path.abspath(path)
    os.makedirs(os.path.dirname(scene.render.filepath), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    print('Legends: preview', path)


def export(objects, path):
    """FBX for Unity: metres, Y up, only these objects (and their children)."""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:
        ob.select_set(True)
        for child in ob.children_recursive:
            child.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.abspath(path), use_selection=True, apply_unit_scale=True,
                             apply_scale_options='FBX_SCALE_UNITS', axis_forward='-Z', axis_up='Y',
                             mesh_smooth_type='FACE', add_leaf_bones=False)
    print('Legends: exported', path)


def out_dir(opts, name):
    """Default: straight into the Unity project, where it is imported as it is."""
    return opts.get('out') or os.path.join(ROOT, 'unity', 'Assets', 'Legends', 'Art', name)


def preview_path(opts, name):
    return opts.get('preview') or os.path.join(ROOT, 'unity', 'Reference', 'art', name + '.png')
