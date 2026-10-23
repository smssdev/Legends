"""The Arena as one 3D model, after its plates (unity/Reference/stadiums/arena/): a closed bowl round the pitch,
two tiers with the LED ribbon between them, the roof ring on steel trusses with the floodlights under its edge.

  blender -b -P tools/unity/art/stadium.py -- [--name Arena] [--seats-lower 22] [--seats-upper 20]

Writes unity/Assets/Legends/Art/Stadium/<name>.fbx and the pictures unity/Reference/art/stadium-<name>.png
(from the air) and stadium-<name>-pitch.png (from the touchline). Each tier's crowd is a material of its own
("Crowd lower", "Crowd upper"), which Unity covers with the crowd cut from our plates (crowd_textures.py).
Every size is a number below: change one, run again, and look.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import common as c

HALF_L, HALF_W = 52.5, 34.0        # the pitch
RUNOFF_SIDE, RUNOFF_END = 7.0, 6.0  # grass between the lines and the first row
CORNER = 18.0                      # how round the bowl's corners are
ROW = 0.8                          # depth of one row of seats (m)
RISE_LOWER, RISE_UPPER = 0.42, 0.62  # height gained per row: the upper tier is steeper, as in the plates


def ring_point(t, offset):
    """A point on the rounded rectangle round the pitch, `offset` metres out from the first row.
    t runs 0..1 once round. Returns (x, y) and the outward direction."""
    a, b = HALF_L + RUNOFF_END + offset - CORNER, HALF_W + RUNOFF_SIDE + offset - CORNER
    r = CORNER
    straight = [2 * b, 2 * a, 2 * b, 2 * a]
    arc = math.pi / 2 * r
    total = sum(straight) + 4 * arc
    d = t * total
    corners = [(a, -b, 0), (a, b, math.pi / 2), (-a, b, math.pi), (-a, -b, 3 * math.pi / 2)]
    for i in range(4):
        cx, cy, ang = corners[i]
        if d <= straight[i]:
            # along a straight side, starting at the corner centre's start angle
            nx, ny = math.cos(ang), math.sin(ang)
            tx, ty = -ny, nx
            return (cx + nx * r + tx * d, cy + ny * r + ty * d), (nx, ny)
        d -= straight[i]
        if d <= arc:
            th = ang + d / r
            nx, ny = math.cos(th), math.sin(th)
            ncx, ncy, _ = corners[(i + 1) % 4]
            return (ncx + nx * r, ncy + ny * r), (nx, ny)
        d -= arc
    return ring_point(0, offset)


def band(name, inner, outer, z0, z1, material, steps=240, parent=None, repeat=40.0):
    """A sloping band all round the bowl: from `inner` metres out at height z0 to `outer` at z1. Its UVs run
    along the bowl, the picture repeating every `repeat` metres, and across it from the front row (0) to the back (1)."""
    verts, faces = [], []
    for s in range(steps + 1):   # the last column repeats the first, so the UVs close without a jump
        (x0, y0), _ = ring_point(s / steps % 1, inner)
        (x1, y1), _ = ring_point(s / steps % 1, outer)
        verts += [(x0, y0, z0), (x1, y1, z1)]
    for s in range(steps):
        a, b = 2 * s, 2 * (s + 1)
        faces.append((a, b, b + 1, a + 1))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    length = 2 * (2 * (HALF_L + RUNOFF_END + inner - CORNER) + 2 * (HALF_W + RUNOFF_SIDE + inner - CORNER)) + 2 * math.pi * CORNER
    uv = me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            uv.data[li].uv = ((vi // 2) / steps * length / repeat, vi % 2)
    me.materials.append(material)
    for p in me.polygons:
        p.use_smooth = True
    return c.link(bpy.data.objects.new(name, me), parent)


def crowd(name, picture):
    """The crowd material: our photographic crowd where it exists, unlit like a screen, else a dark colour."""
    path = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Stadiums', 'Arena', 'Textures', picture)
    m = c.mat(name, '#2c2833', 0.9)
    if os.path.exists(path):
        nodes, links = m.node_tree.nodes, m.node_tree.links
        tex = nodes.new('ShaderNodeTexImage')
        tex.image = bpy.data.images.load(path)
        p = nodes['Principled BSDF']
        links.new(tex.outputs['Color'], p.inputs['Base Color'])
        links.new(tex.outputs['Color'], p.inputs['Emission Color'])
        p.inputs['Emission Strength'].default_value = 0.8
    return m


def floodlit(target=(0, 0, 0)):
    """Light the pitch for the pictures as the floodlights would (Unity lights its own scene)."""
    for x in (-40, 0, 40):
        for y in (-55, 55):
            d = bpy.data.lights.new('Flood', 'SPOT')
            d.energy, d.spot_size = 300000, math.radians(70)
            o = c.link(bpy.data.objects.new('Flood', d))
            o.location = (x, y, 45)
            c.aim(o, (x * 0.4, 0, 0))


def stadium(name, rows_lower, rows_upper):
    root = c.empty(name)
    concrete = c.mat('Concrete', '#4a4f58', 0.8)
    crowd_lower = crowd('Crowd lower', 'crowd-lower.png')    # our crowd, cut from the plates (crowd_textures.py)
    crowd_upper = crowd('Crowd upper', 'crowd-upper.png')
    ribbon = c.mat('LED ribbon', '#7a5cff', 0.3, emit=3)
    steel = c.mat('Roof steel', '#5f6670', 0.4, metal=1)
    roof = c.mat('Roof', '#1b1e24', 0.7)
    lamp = c.mat('Floodlight', '#FFFFFF', 0.2, emit=30)

    # grass under the whole bowl, the pitch drawn on it by Unity
    c.box('Grass', (2 * (HALF_L + RUNOFF_END + 2), 2 * (HALF_W + RUNOFF_SIDE + 2), 0.02), (0, 0, -0.01), c.mat('Grass', c.PITCH, 0.9), root)
    band('Pitch wall', 0.5, 0.5, 0, 1.2, concrete, parent=root)
    # lower tier
    lo_depth = rows_lower * ROW
    lo_top = 1.2 + rows_lower * RISE_LOWER
    band('Tier lower', 0.5, 0.5 + lo_depth, 1.2, lo_top, crowd_lower, parent=root)
    # the LED ribbon round the bowl between the tiers, and the balcony behind it
    band('Ribbon', 0.5 + lo_depth, 0.5 + lo_depth, lo_top, lo_top + 1.6, ribbon, parent=root)
    band('Balcony', 0.5 + lo_depth, 2.5 + lo_depth, lo_top + 1.6, lo_top + 1.6, concrete, parent=root)
    # upper tier
    up_in = 2.5 + lo_depth
    up_depth = rows_upper * ROW
    up_top = lo_top + 1.6 + rows_upper * RISE_UPPER
    band('Tier upper', up_in, up_in + up_depth, lo_top + 1.6, up_top, crowd_upper, parent=root)
    band('Back wall', up_in + up_depth, up_in + up_depth, 0, up_top + 2, concrete, parent=root)
    # the roof ring: from behind the top row out over the upper tier, with trusses every 8 m
    roof_z = up_top + 6
    roof_in = up_in - 4
    band('Roof', roof_in, up_in + up_depth + 1, roof_z, roof_z + 3, roof, parent=root)
    band('Roof edge', roof_in, roof_in, roof_z - 1.2, roof_z, steel, parent=root)
    trusses = int(2 * (HALF_L + HALF_W) * 2 / 8)
    for i in range(trusses):
        (x0, y0), _ = ring_point(i / trusses, roof_in)
        (x1, y1), _ = ring_point(i / trusses, up_in + up_depth + 1)
        c.tube('Truss', 0.25, (x0, y0, roof_z - 0.6), (x1, y1, roof_z + 2.6), steel, root, sides=6)
        c.tube('Column', 0.35, (x1, y1, 0), (x1, y1, roof_z + 3), steel, root, sides=8)
    # floodlights along the roof's inner edge, facing the pitch
    lights = 64
    for i in range(lights):
        (x, y), (nx, ny) = ring_point(i / lights, roof_in + 0.3)
        lamp_ob = c.box('Floodlight', (1.6, 1.6, 0.25), (x, y, roof_z - 1.4), lamp, root)
        lamp_ob.rotation_euler = (0, 0, math.atan2(ny, nx))
    # two tunnels' mouths and the players' tunnel on the near side
    c.box('Tunnel', (6, 3, 2.6), (0, -(HALF_W + RUNOFF_SIDE + 1.5), 1.3), c.mat('Tunnel', '#0b0d10', 0.9), root)
    return root


def main():
    opts = c.args()
    name = opts.get('name', 'Arena')
    c.fresh()
    root = stadium(name, int(opts.get('seats-lower', 22)), int(opts.get('seats-upper', 20)))
    c.export([root], os.path.join(c.out_dir(opts, 'Stadium'), name + '.fbx'))
    # a pitch in the middle for the pictures (Unity has its own)
    bpy.ops.mesh.primitive_plane_add(size=1)
    p = bpy.context.object
    p.scale = (2 * HALF_L, 2 * HALF_W, 1)
    p.location.z = 0.02
    p.data.materials.append(c.mat('Pitch', '#2f8f3a', 0.9))
    floodlit()
    cam = c.studio(target=(0, 0, 0), distance=150, height=110, lens=24, floor=None)
    air = c.preview_path(opts, 'stadium-' + name.lower())
    c.render(air, samples=32)
    cam.location = (25, -(HALF_W + 2), 3)
    c.aim(cam, (0, 10, 6))
    cam.data.lens = 18
    c.render(air.replace('.png', '-pitch.png'), samples=32)


main()
