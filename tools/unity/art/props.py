"""Everything around the pitch, at real sizes: the goal and its net, the corner flag, the LED boards with the
LEGENDS name, the dugout with its seats, and a floodlight mast.

  blender -b -P tools/unity/art/props.py -- [--only goal|flag|boards|dugout|mast]

Writes one FBX per piece to unity/Assets/Legends/Art/Props/ and the picture unity/Reference/art/props.png.
The sizes are the Laws of the Game (goal 7.32 x 2.44 m, posts 12 cm, corner flag 1.5 m); change the numbers
below, run again, and look.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import common as c

GOAL_W, GOAL_H, POST = 7.32, 2.44, 0.12      # inside width and height, post thickness (m)
NET_DEPTH_TOP, NET_DEPTH_BOTTOM, MESH = 1.0, 2.0, 0.12


def goal():
    root = c.empty('Goal')
    white = c.mat('Post', '#F4F4F4', 0.3)
    r = POST / 2
    for y in (-GOAL_W / 2 - r, GOAL_W / 2 + r):
        c.tube('Post', r, (0, y, 0), (0, y, GOAL_H + r), white, root)
    c.tube('Crossbar', r, (0, -GOAL_W / 2 - POST, GOAL_H + r), (0, GOAL_W / 2 + POST, GOAL_H + r), white, root)
    # the net frame behind: thin white supports, back bar on the grass
    frame = c.mat('Net Frame', '#DADADA', 0.4)
    for y in (-GOAL_W / 2 - r, GOAL_W / 2 + r):
        c.tube('Support', 0.02, (0, y, GOAL_H), (NET_DEPTH_TOP, y, GOAL_H), frame, root)
        c.tube('Support', 0.02, (NET_DEPTH_TOP, y, GOAL_H), (NET_DEPTH_BOTTOM, y, 0.02), frame, root)
    c.tube('Back bar', 0.02, (NET_DEPTH_BOTTOM, -GOAL_W / 2 - r, 0.02), (NET_DEPTH_BOTTOM, GOAL_W / 2 + r, 0.02), frame, root)
    # the net: a grid of 12 cm cells over roof, back and sides, made into strings by a wireframe modifier.
    # Unity's Cloth makes it bulge where the ball goes in (Sprint 5).
    net = c.mat('Net', '#FFFFFF', 0.8)
    def sheet(name, corners, nu, nv):
        (a, b, d, e) = corners   # four corners in order
        verts, faces = [], []
        for j in range(nv + 1):
            for i in range(nu + 1):
                u, v = i / nu, j / nv
                p = [a[k] * (1 - u) * (1 - v) + b[k] * u * (1 - v) + e[k] * (1 - u) * v + d[k] * u * v for k in range(3)]
                verts.append(p)
        for j in range(nv):
            for i in range(nu):
                q = j * (nu + 1) + i
                faces.append((q, q + 1, q + nu + 2, q + nu + 1))
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], faces)
        ob = c.link(bpy.data.objects.new(name, me), root)
        w = ob.modifiers.new('strings', 'WIREFRAME')
        w.thickness = 0.008
        me.materials.append(net)
        return ob
    hw = GOAL_W / 2
    nu = int(GOAL_W / MESH)
    sheet('Net roof', ((0, -hw, GOAL_H), (0, hw, GOAL_H), (NET_DEPTH_TOP, hw, GOAL_H), (NET_DEPTH_TOP, -hw, GOAL_H)), nu, int(NET_DEPTH_TOP / MESH))
    back = math.hypot(NET_DEPTH_BOTTOM - NET_DEPTH_TOP, GOAL_H)
    sheet('Net back', ((NET_DEPTH_TOP, -hw, GOAL_H), (NET_DEPTH_TOP, hw, GOAL_H), (NET_DEPTH_BOTTOM, hw, 0), (NET_DEPTH_BOTTOM, -hw, 0)), nu, int(back / MESH))
    for s in (-1, 1):
        y = s * hw
        sheet('Net side', ((0, y, 0), (0, y, GOAL_H), (NET_DEPTH_TOP, y, GOAL_H), (NET_DEPTH_BOTTOM, y, 0)), int(GOAL_H / MESH), int(NET_DEPTH_BOTTOM / MESH))
    return root


def flag():
    root = c.empty('Corner flag')
    c.tube('Pole', 0.02, (0, 0, 0), (0, 0, 1.5), c.mat('Flag pole', '#F4F4F4', 0.4), root)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0.22, 0, 1.33))
    f = bpy.context.object
    f.name = 'Flag'
    f.scale = (0.4, 1, 0.3)
    f.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    f.data.materials.append(c.mat('Flag cloth', c.GOLD, 0.7))
    f.parent = root
    return root


def boards(length=10.0, height=0.9):
    """An LED board: navy face with the LEGENDS name in gold, lit from inside."""
    root = c.empty('LED board')
    c.box('Board', (length, 0.3, height), (0, 0, height / 2), c.mat('Board body', '#111318', 0.5), root)
    c.box('Screen', (length - 0.1, 0.02, height - 0.1), (0, -0.16, height / 2), c.mat('Board screen', c.NAVY, 0.3, emit=1.5), root)
    for i, x in enumerate((-length / 4, length / 4)):
        bpy.ops.object.text_add(location=(x, -0.18, height / 2))
        t = bpy.context.object
        t.data.body = 'LEGENDS'
        t.data.align_x, t.data.align_y = 'CENTER', 'CENTER'
        t.data.size = height * 0.55
        t.data.extrude = 0.005
        t.rotation_euler = (math.radians(90), 0, 0)
        t.data.materials.append(c.mat('Board text', c.GOLD, 0.3, emit=4))
        bpy.ops.object.convert(target='MESH')
        bpy.context.object.name = 'Name %d' % i
        bpy.context.object.parent = root
    return root


def dugout(seats=12):
    """The bench under a curved clear roof, with its seats in a row."""
    root = c.empty('Dugout')
    width = seats * 0.55 + 0.6
    shell = c.mat('Dugout roof', '#9fb3c8', 0.1)
    if hasattr(shell, 'blend_method'):
        shell.blend_method = 'BLEND'
    shell.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value = 0.35
    c.box('Floor', (width, 1.6, 0.1), (0, 0, 0.05), c.mat('Dugout floor', '#2a2d33', 0.8), root)
    c.box('Back', (width, 0.08, 2.1), (0, 0.8, 1.05), shell, root)
    c.box('Roof', (width, 1.7, 0.06), (0, -0.05, 2.1), shell, root, rot=(math.radians(-6), 0, 0))
    for s in (-1, 1):
        c.box('Side', (0.06, 1.6, 2.1), (s * width / 2, 0, 1.05), shell, root)
    seat = c.mat('Seat', c.NAVY, 0.4)
    for i in range(seats):
        x = -width / 2 + 0.6 + i * 0.55
        c.box('Seat', (0.48, 0.48, 0.12), (x, 0.3, 0.5), seat, root)
        c.box('Seat back', (0.48, 0.1, 0.7), (x, 0.58, 0.9), seat, root, rot=(math.radians(-10), 0, 0))
    return root


def mast(height=40.0, lamps=(6, 4)):
    """A floodlight mast: the steel column and a frame of lamps tilted to the pitch."""
    root = c.empty('Floodlight mast')
    steel = c.mat('Steel', '#7d838c', 0.35, metal=1)
    c.tube('Column', 0.45, (0, 0, 0), (0, 0, height), steel, root, sides=24)
    cols, rows = lamps
    lamp = c.mat('Lamp', '#FFFFFF', 0.2, emit=25)
    housing = c.mat('Lamp housing', '#2a2d33', 0.5)
    c.box('Frame', (cols * 0.9 + 0.4, 0.3, rows * 0.9 + 0.4), (0, -0.6, height + rows * 0.45), steel, root, rot=(math.radians(25), 0, 0))
    for i in range(cols):
        for j in range(rows):
            x = (i - (cols - 1) / 2) * 0.9
            z = height + 0.45 + j * 0.9
            c.box('Lamp housing', (0.7, 0.4, 0.7), (x, -0.85, z), housing, root, rot=(math.radians(25), 0, 0))
            c.box('Lamp', (0.6, 0.05, 0.6), (x, -1.07, z - 0.1), lamp, root, rot=(math.radians(25), 0, 0))
    return root


PIECES = {'goal': goal, 'flag': flag, 'boards': boards, 'dugout': dugout, 'mast': mast}
LAYOUT = {'goal': (0, 0, 0), 'flag': (-3, -7, 0), 'boards': (8, -6, 0), 'dugout': (-9, 2, 0), 'mast': (13, 30, 0)}


def main():
    opts = c.args()
    c.fresh()
    names = [opts['only']] if 'only' in opts else list(PIECES)
    out = c.out_dir(opts, 'Props')
    made = []
    for n in names:
        ob = PIECES[n]()
        c.export([ob], os.path.join(out, n + '.fbx'))
        ob.location = LAYOUT[n]
        made.append(ob)
    c.studio(target=(2, 0, 2.5) if len(made) > 1 else (0, 0, 1.2), distance=24 if len(made) > 1 else 9, height=4, lens=35)
    c.render(c.preview_path(opts, 'props'))


main()
