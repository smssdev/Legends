"""The Legends ball: 32 panels (12 pentagons, 20 hexagons) on a 22 cm sphere, in the brand colours.

  blender -b -P tools/unity/art/ball.py -- [--panels navy|gold|ivory] [--patches gold|navy|ivory]

Writes unity/Assets/Legends/Art/Ball/ball.fbx and the picture unity/Reference/art/ball.png. Change the colours
with the two options, or the names below, and run it again until it looks right.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import bmesh
import common as c

COLOURS = {'navy': c.NAVY, 'gold': c.GOLD, 'ivory': c.IVORY, 'gold-dark': c.GOLD_DARK}


def ball(hexes, pents, radius=0.11):
    """A truncated icosahedron (the classic ball), each panel puffed out to the sphere with a thin seam."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=0, radius=radius)     # 12 corners: each becomes a pentagon
    bmesh.ops.bevel(bm, geom=list(bm.verts), offset=33.333, offset_type='PERCENT', affect='VERTICES')
    for f in bm.faces:
        f.material_index = 1 if len(f.verts) == 5 else 0
    # panels inset a little so a dark seam runs between them
    bmesh.ops.inset_individual(bm, faces=list(bm.faces), thickness=radius * 0.018, depth=0)
    seams = [f for f in bm.faces if len(f.verts) == 4]
    for f in seams:
        f.material_index = 2
    bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=7, use_grid_fill=True)
    for v in bm.verts:   # onto the sphere, the seams a hair lower
        v.co = v.co.normalized() * radius
    me = bpy.data.meshes.new('Ball')
    bm.to_mesh(me)
    for p in me.polygons:
        p.use_smooth = True
    ob = c.link(bpy.data.objects.new('Ball', me))
    for m in (c.mat('Ball Panel', hexes, 0.35), c.mat('Ball Patch', pents, 0.35), c.mat('Ball Seam', '#1b1b1b', 0.6)):
        me.materials.append(m)
    return ob


def main():
    opts = c.args()
    c.fresh()
    ob = ball(COLOURS[opts.get('panels', 'ivory')], COLOURS[opts.get('patches', 'navy')])
    ob.location.z = 0.11
    c.export([ob], os.path.join(c.out_dir(opts, 'Ball'), 'ball.fbx'))
    c.studio(target=(0, 0, 0.11), distance=0.9, height=0.25, lens=60)
    c.render(c.preview_path(opts, 'ball'), 1200, 900)


main()
