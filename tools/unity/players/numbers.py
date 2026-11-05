"""Sprint 06 U6: the shirt numbers' atlas, the digits 0 to 9 in Barlow Condensed Bold (the game's numbers font,
docs/design/tokens.json; SIL Open Font License, fonts/OFL.txt) side by side, white on clear. Unity's kit shader puts
one or two of them on the back and the chest, so every number from 0 to 99 is drawn from these ten.

  blender -b -P tools/unity/players/numbers.py

Writes unity/Assets/Legends/Players/Textures/numbers.png (10 cells of 128 x 192: each digit fills its cell's height).
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'art'))
import bpy
import common as c

FONT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fonts', 'BarlowCondensed-Bold.ttf')
CELL_W, CELL_H = 128, 192
OUT = os.path.join(c.ROOT, 'unity', 'Assets', 'Legends', 'Players', 'Textures', 'numbers.png')


def main():
    c.fresh()
    scene = bpy.context.scene
    font = bpy.data.fonts.load(FONT)
    white = bpy.data.materials.new('Digit')
    white.use_nodes = True
    nodes = white.node_tree.nodes
    out = nodes['Material Output']
    emit = nodes.new('ShaderNodeEmission')
    emit.inputs['Color'].default_value = (1, 1, 1, 1)
    white.node_tree.links.new(emit.outputs[0], out.inputs['Surface'])
    cell = CELL_H / 100.0                       # a cell is 1.92 units high, 1.28 wide
    for d in range(10):
        curve = bpy.data.curves.new('Digit %d' % d, 'FONT')
        curve.body = str(d)
        curve.font = font
        curve.align_x, curve.align_y = 'CENTER', 'CENTER'
        curve.size = cell * 1.62                # the figure's own height then fills about 90% of the cell
        ob = bpy.data.objects.new(curve.name, curve)
        ob.data.materials.append(white)
        scene.collection.objects.link(ob)
        ob.location = ((d + 0.5) * CELL_W / 100.0, cell / 2 + 0.12, 0)   # the font's centre sits a little low
    cam = bpy.data.cameras.new('Camera')
    cam.type = 'ORTHO'
    cam.ortho_scale = 10 * CELL_W / 100.0
    cam_ob = bpy.data.objects.new('Camera', cam)
    scene.collection.objects.link(cam_ob)
    cam_ob.location = (5 * CELL_W / 100.0, cell / 2, 10)
    scene.camera = cam_ob
    scene.render.engine = 'BLENDER_EEVEE' if 'BLENDER_EEVEE' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE_NEXT'
    scene.render.film_transparent = True
    scene.render.resolution_x, scene.render.resolution_y = 10 * CELL_W, CELL_H
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.view_settings.view_transform = 'Standard'
    scene.render.filepath = OUT
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    print('Legends: numbers', OUT)


main()
