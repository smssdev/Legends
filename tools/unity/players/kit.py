"""Sprint 06 U3: the kit, cut from the player's own body: the shirt (short sleeves and a collar), the shorts, the socks
and the boots. Each piece is the body's surface between planes across its bones, lifted off the skin, so its hems are
straight, it fits every build and face, and it moves with the body (it keeps the body's bone weights).

Every piece carries what Unity's kit shader needs (U6), the same for every club:
  vertex colour 'kit': R the trim (collar, cuffs, hems, sock band: the second colour), G the front (1) or back (0),
                       B the piece (0 shirt, 0.33 shorts, 0.66 socks, 1 boots)
  UV 'pattern':        u across the body (0.5 the middle, 0 and 1 the sides of the chest), v up the shirt (0 the hem,
                       1 the shoulders): stripes, hoops, halves and the sash are drawn from it, as App\\Data\\KitPattern names them
"""
import bmesh
import bpy
from mathutils import Vector

ARM = ('clavicle', 'upperarm', 'lowerarm', 'hand', 'index', 'middle', 'ring', 'pinky', 'thumb')
LEG = ('thigh', 'calf', 'foot', 'ball')
PIECES = {'shirt': 0.0, 'shorts': 0.33, 'socks': 0.66, 'boots': 1.0}
# The keeper's gloves are drawn as the boots' piece (B 1) with half alpha, so the shader colours them apart.
GLOVES = {'gloves': 1.0}
PATTERNS = ('plain', 'stripes', 'hoops', 'halves', 'sash')


class Body:
    """The body's evaluated surface in its own space, and where its bones are in that space."""

    def __init__(self, top, body):
        self.top, self.body = top, body
        self.inv = body.matrix_world.inverted()
        self.scale = body.matrix_world.to_scale().x
        self.bones = {b.name: (self.local(top.matrix_world @ b.head_local), self.local(top.matrix_world @ b.tail_local))
                      for b in top.data.bones}
        self.names = [g.name for g in body.vertex_groups]

    def local(self, p):
        return self.inv @ p

    def m(self, metres):
        """Metres in the world as lengths in the body's own space."""
        return metres / self.scale

    def at(self, bone, t):
        """A point along a bone (0 its head, 1 its tail) and the bone's direction."""
        h, tl = self.bones[bone]
        return h.lerp(tl, t), (tl - h).normalized()

    def surface(self):
        dg = bpy.context.evaluated_depsgraph_get()
        ev = self.body.evaluated_get(dg)
        me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
        bm = bmesh.new()
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
        return bm


def bone_of(names, deform, v):
    """The bone that moves this vertex most."""
    best, w = None, 0.0
    for i, weight in v[deform].items():
        n = names[i]
        if weight > w and (n.startswith(ARM) or n.startswith(LEG) or n in ('pelvis', 'neck_01', 'head') or n.startswith('spine')):
            best, w = n, weight
    return best or ''


def keep_bones(bm, names, keep):
    deform = bm.verts.layers.deform.active
    drop = [f for f in bm.faces if not all(keep(bone_of(names, deform, v)) for v in f.verts)]
    bmesh.ops.delete(bm, geom=drop, context='FACES')


def cut(bm, names, co, no, only=None):
    """Cuts along the plane and drops what is on its normal's side (only faces moved by `only` bones, when given)."""
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co, plane_no=no, dist=1e-6)
    deform = bm.verts.layers.deform.active
    drop = [f for f in bm.faces if (f.calc_center_median() - co).dot(no) > 1e-6
            and (only is None or any(bone_of(names, deform, v).startswith(only) for v in f.verts))]
    bmesh.ops.delete(bm, geom=drop, context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')


def shirt(b, bm):
    keep_bones(bm, b.names, lambda n: not n.startswith(LEG))
    neck, _ = b.at('neck_01', 0.0)
    cut(bm, b.names, neck + Vector((0, 0, -b.m(0.03))), Vector((0, -0.45, 1)).normalized())  # lower at the front
    pelvis, _ = b.at('pelvis', 0.0)
    cut(bm, b.names, pelvis + Vector((0, 0, b.m(0.01))), Vector((0, 0, -1)))   # over the shorts' waist, above the crotch
    trims = []
    for side in 'lr':
        # Short sleeves to mid upper arm; the keeper's long ones to the wrist.
        co, d = b.at('lowerarm_' + side, 0.9) if b.long else b.at('upperarm_' + side, 0.55)
        cut(bm, b.names, co, d, only=ARM)
        trims.append((co, d, b.m(0.025), ARM))
    return trims


def gloves(b, bm):
    """The keeper's gloves: the hands and a little of the wrist."""
    keep_bones(bm, b.names, lambda n: n.startswith(('lowerarm', 'hand', 'index', 'middle', 'ring', 'pinky', 'thumb')))
    # Each wrist's plane goes on for ever: on its own arm only, or the left wrist's would take the right hand too.
    arm = ('lowerarm', 'hand', 'index', 'middle', 'ring', 'pinky', 'thumb')
    for side in 'lr':
        co, d = b.at('lowerarm_' + side, 0.86)
        cut(bm, b.names, co, -d, only=tuple(n for n in b.names if n.startswith(arm) and n.endswith('_' + side)))
    return []


def shorts(b, bm):
    keep_bones(bm, b.names, lambda n: not n.startswith(ARM) and n not in ('neck_01', 'head', 'spine_03'))
    pelvis, _ = b.at('pelvis', 0.0)
    cut(bm, b.names, pelvis + Vector((0, 0, b.m(0.08))), Vector((0, 0, 1)))
    trims = []
    for side in 'lr':
        co, d = b.at('thigh_' + side, 0.52)
        cut(bm, b.names, co, d, only=LEG)
        trims.append((co, d, b.m(0.02), LEG))
    return trims


def socks(b, bm):
    keep_bones(bm, b.names, lambda n: n.startswith(('calf', 'foot', 'ball')))
    trims = []
    for side in 'lr':
        co, d = b.at('calf_' + side, 0.12)
        cut(bm, b.names, co, -d)
        trims.append((co, -d, b.m(0.035), LEG))
        end, d = b.at('calf_' + side, 0.93)     # into the boot, which covers the foot
        cut(bm, b.names, end, d)
    return trims


def boots(b, bm):
    keep_bones(bm, b.names, lambda n: n.startswith(('calf', 'foot', 'ball')))
    for side in 'lr':
        co, d = b.at('calf_' + side, 0.86)
        cut(bm, b.names, co, -d)
    # A boot, not a foot: each foot's convex hull, one toe cap and a flat sole. The hull is made of the foot's own
    # vertices, so it keeps their bone weights.
    old = list(bm.faces)
    for side in (1, -1):
        bmesh.ops.convex_hull(bm, input=[v for v in bm.verts if v.co.x * side > 0])
    bmesh.ops.delete(bm, geom=old, context='FACES_ONLY')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces], context='EDGES')
    return []


# how far each piece stands off the skin, and how much more at its open ends (loose sleeves and shorts legs), in metres
LIFT = {'shirt': (0.008, 0.010), 'shorts': (0.011, 0.028), 'socks': (0.0025, 0.0), 'boots': (0.004, 0.0), 'gloves': (0.008, 0.0)}


def collar(b, bm, trim):
    """The shirt's collar: the neck opening's edge turned up 1.4 cm, in the trim colour."""
    neck, _ = b.at('neck_01', 0.0)
    edges = [e for e in bm.edges if e.is_boundary and all((v.co - neck).length < b.m(0.14) for v in e.verts)]
    if not edges:
        return
    new = bmesh.ops.extrude_edge_only(bm, edges=edges)['geom']
    for v in [g for g in new if isinstance(g, bmesh.types.BMVert)]:
        out = Vector((v.co.x - neck.x, v.co.y - neck.y, 0)).normalized()
        v.co += Vector((0, 0, b.m(0.014))) - out * b.m(0.003)
    for f in [g for g in new if isinstance(g, bmesh.types.BMFace)]:
        for loop in f.loops:
            loop[trim] = (1.0, loop[trim][1], loop[trim][2], 1.0)


def piece(b, kind):
    bm = b.surface()
    trims = globals()[kind](b, bm)
    lift, flare = LIFT[kind]
    for co, d, w, _ in trims:      # an edge loop on the band's line, so the trim's edge is straight
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=co - d * w, plane_no=d, dist=1e-6)
    bm.normal_update()
    pelvis, _ = b.at('pelvis', 0.0)
    deform = bm.verts.layers.deform.active
    limb = {v: bone_of(b.names, deform, v) for v in bm.verts}
    for v in bm.verts:
        extra = 0.0
        for co, d, _, bones in trims:
            if kind in ('shirt', 'shorts') and limb[v].startswith(bones):
                reach = (v.co - co).dot(d)               # the open end is where the cut is: 0 there, negative inside
                extra = max(extra, flare * max(0.0, 1 + reach / b.m(0.12)))
        v.co += v.normal * b.m(lift + extra)
    colour = bm.loops.layers.color.new('kit')
    uv = bm.loops.layers.uv.new('pattern')
    top, _ = b.at('clavicle_l', 1.0)
    hem = pelvis.z - b.m(0.05)
    for f in bm.faces:
        front = 1.0 if f.normal.y < 0 else 0.0               # MakeHuman faces -Y
        centre = f.calc_center_median()
        band = any(0 >= (centre - co).dot(d) > -w and any(limb.get(v, bone_of(b.names, deform, v)).startswith(bones) for v in f.verts)
                   for co, d, w, bones in trims)
        for loop in f.loops:
            p = loop.vert.co
            loop[colour] = (1.0 if band else 0.0, front, {**PIECES, **GLOVES}[kind], 0.5 if kind == 'gloves' else 1.0)
            loop[uv].uv = (0.5 + p.x / b.m(0.5), (p.z - hem) / (top.z - hem))
    if kind == 'shirt':
        collar(b, bm, colour)
    me = bpy.data.meshes.new(b.body.name + '.' + kind)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(me.name, me)
    bpy.context.collection.objects.link(ob)
    for name in b.names:
        ob.vertex_groups.new(name=name)
    ob.parent = b.body.parent
    ob.matrix_parent_inverse = b.body.matrix_parent_inverse.copy()
    ob.matrix_basis = b.body.matrix_basis.copy()
    if b.body.parent:
        arm = ob.modifiers.new('Armature', 'ARMATURE')
        arm.object = b.body.parent
    solid = ob.modifiers.new('Cloth thickness', 'SOLIDIFY')
    solid.thickness, solid.offset, solid.use_rim = b.m(0.006 if kind == 'boots' else 0.0025), -1, True
    for poly in me.polygons:
        poly.use_smooth = True
    return ob


def dress(top, body, keeper=False):
    """The four pieces on this player, parented to his rig (the keeper's: long sleeves, and gloves). By name."""
    b = Body(top, body)
    b.long = keeper
    return {kind: piece(b, kind) for kind in [*PIECES, *(GLOVES if keeper else [])]}


# ---------------------------------------------------------------- the preview's materials (Unity's shader does this in U6)

def shorts_colour(primary):
    """As the cartoon (web/src/match/feed/art.ts): navy under a light shirt, else the shirt's colour darkened."""
    r, g, b = (int(primary[i:i + 2], 16) for i in (1, 3, 5))
    if 0.299 * r + 0.587 * g + 0.114 * b > 160:
        return '#1C2B48'
    return '#%02x%02x%02x' % tuple(max(0, x - 80) for x in (r, g, b))


def materials(pieces, primary, secondary, pattern, srgb):
    """Blender's look of the kit shader: the trim and the pattern in the second colour on the shirt."""
    def node_mat(name, base_hex, trim_hex, with_pattern):
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        t = m.node_tree
        p = t.nodes['Principled BSDF']
        p.inputs['Roughness'].default_value = 0.62
        col = t.nodes.new('ShaderNodeVertexColor')
        col.layer_name = 'kit'
        sep = t.nodes.new('ShaderNodeSeparateColor')
        t.links.new(col.outputs['Color'], sep.inputs['Color'])
        fac = sep.outputs['Red']
        if with_pattern and pattern != 'plain':
            fac = maximum(t, fac, pattern_factor(t, pattern))
        mix = t.nodes.new('ShaderNodeMix')
        mix.data_type = 'RGBA'
        mix.inputs['A'].default_value = (*srgb(base_hex), 1)
        mix.inputs['B'].default_value = (*srgb(trim_hex), 1)
        t.links.new(fac, mix.inputs['Factor'])
        t.links.new(mix.outputs['Result'], p.inputs['Base Color'])
        m.diffuse_color = (*srgb(base_hex), 1)
        return m
    looks = {
        'shirt': node_mat('Shirt', primary, secondary, True),
        'shorts': node_mat('Shorts', shorts_colour(primary), secondary, False),
        'socks': node_mat('Socks', primary, secondary, False),
        'boots': node_mat('Boots', '#15171c', '#15171c', False),
        'gloves': node_mat('Gloves', '#E4FF5A', '#E4FF5A', False),   # the keeper's (Sprint 06 U7)
    }
    for kind, ob in pieces.items():
        ob.data.materials.clear()
        ob.data.materials.append(looks[kind])


def math(t, op, a, b=None):
    n = t.nodes.new('ShaderNodeMath')
    n.operation = op
    for i, x in enumerate((a, b)):
        if x is None:
            continue
        if isinstance(x, (int, float)):
            n.inputs[i].default_value = x
        else:
            t.links.new(x, n.inputs[i])
    return n.outputs[0]


def maximum(t, a, b):
    return math(t, 'MAXIMUM', a, b)


def pattern_factor(t, pattern):
    """1 where the pattern takes the second colour, from the 'pattern' UV."""
    uv = t.nodes.new('ShaderNodeUVMap')
    uv.uv_map = 'pattern'
    sep = t.nodes.new('ShaderNodeSeparateXYZ')
    t.links.new(uv.outputs['UV'], sep.inputs['Vector'])
    u, v = sep.outputs['X'], sep.outputs['Y']
    if pattern == 'stripes':      # nine vertical stripes across the chest
        return math(t, 'FLOORED_MODULO', math(t, 'FLOOR', math(t, 'MULTIPLY', u, 9.0)), 2.0)
    if pattern == 'hoops':        # seven bands up the shirt
        return math(t, 'FLOORED_MODULO', math(t, 'FLOOR', math(t, 'MULTIPLY', v, 7.0)), 2.0)
    if pattern == 'halves':       # the wearer's left half
        return math(t, 'GREATER_THAN', u, 0.5)
    # the sash: a band from the right shoulder to the left hip
    return math(t, 'LESS_THAN', math(t, 'ABSOLUTE', math(t, 'SUBTRACT', math(t, 'ADD', u, v), 1.0)), 0.16)
