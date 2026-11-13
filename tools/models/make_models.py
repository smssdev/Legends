"""[Sprint 50 M23] The app's 3D models, made from code (ours, no outside asset): the trophy of the sign-in stage, the
player card that flips in the market, the stadium with its buildings, and the three store chests.

    python3 tools/models/make_models.py          # writes tools/models/glb/*.glb (then render_spins.cjs and spins.py)

Each model is a few simple shapes (turned profiles, boxes and tori) with PBR materials in the game's colours
(docs/design/tokens.json): gold, emerald, navy, bronze and silver. Needs numpy and pygltflib (free, pip).
"""

import math
import pathlib

import numpy as np
from pygltflib import (GLTF2, Accessor, Asset, Buffer, BufferView, Material, Mesh, Node, PbrMetallicRoughness, Primitive,
                       Scene, ARRAY_BUFFER, ELEMENT_ARRAY_BUFFER, FLOAT, UNSIGNED_INT, VEC3, SCALAR)

# [Sprint 61 F2] The sources of the app's spins (render_spins.cjs, then spins.py): the app no longer carries a .glb.
OUT = pathlib.Path(__file__).resolve().parent / 'glb'


def hexrgb(h, a=1.0):
    h = h.lstrip('#')
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)] + [a]


# The game's colours (tokens.json "color").
GOLD, GOLD_DARK, EMERALD, MINT, NAVY, NAVY_DEEP = '#F5B82E', '#C08A0C', '#12A07E', '#4FE0B5', '#183349', '#0B1A2C'
PITCH, BRONZE, SILVER, CREAM, RED = '#1E9E4A', '#B4692A', '#C3CCDA', '#F7F4EA', '#FF8A8A'


class Model:
    """A list of (vertices, normals, indices, material) parts, written as one glb."""

    def __init__(self):
        self.parts = []
        self.materials = {}

    def material(self, name, colour, metal=0.0, rough=0.6):
        if name not in self.materials:
            self.materials[name] = Material(name=name, pbrMetallicRoughness=PbrMetallicRoughness(
                baseColorFactor=hexrgb(colour), metallicFactor=metal, roughnessFactor=rough), doubleSided=True)
        return name

    def add(self, mesh, mat, at=(0, 0, 0), rot_y=0.0, rot_z=0.0, scale=(1, 1, 1)):
        v, n, i = mesh
        v = v * np.array(scale, dtype=np.float32)
        for angle, axis in ((rot_z, 'z'), (rot_y, 'y')):
            if angle:
                c, s = math.cos(angle), math.sin(angle)
                r = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]] if axis == 'z' else [[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=np.float32)
                v, n = v @ r.T, n @ r.T
        self.parts.append((v + np.array(at, dtype=np.float32), n, i, mat))

    def save(self, name):
        names = list(self.materials)
        blob = bytearray()
        views, accessors, prims = [], [], []
        for v, n, i, mat in self.parts:
            v, n, i = v.astype(np.float32), n.astype(np.float32), i.astype(np.uint32)
            ids = []
            for data, target, kind, ctype in ((v, ARRAY_BUFFER, VEC3, FLOAT), (n, ARRAY_BUFFER, VEC3, FLOAT), (i, ELEMENT_ARRAY_BUFFER, SCALAR, UNSIGNED_INT)):
                while len(blob) % 4:
                    blob.append(0)
                raw = data.tobytes()
                views.append(BufferView(buffer=0, byteOffset=len(blob), byteLength=len(raw), target=target))
                blob.extend(raw)
                acc = Accessor(bufferView=len(views) - 1, componentType=ctype, count=len(data) if kind != SCALAR else data.size, type=kind)
                if kind == VEC3 and len(accessors) % 3 == 0:
                    acc.min, acc.max = v.min(axis=0).tolist(), v.max(axis=0).tolist()
                accessors.append(acc)
                ids.append(len(accessors) - 1)
            prims.append(Primitive(attributes={'POSITION': ids[0], 'NORMAL': ids[1]}, indices=ids[2], material=names.index(mat)))
        g = GLTF2(asset=Asset(generator='Legends tools/models'), scene=0, scenes=[Scene(nodes=[0])], nodes=[Node(mesh=0)],
                  meshes=[Mesh(primitives=prims)], materials=[self.materials[k] for k in names], accessors=accessors,
                  bufferViews=views, buffers=[Buffer(byteLength=len(blob))])
        g.set_binary_blob(bytes(blob))
        OUT.mkdir(parents=True, exist_ok=True)
        g.save_binary(str(OUT / f'{name}.glb'))
        print(f'{name}.glb', (OUT / f'{name}.glb').stat().st_size, 'bytes')


def lathe(profile, segments=48):
    """A shape turned around the y axis from (radius, height) points, bottom to top."""
    verts, norms, idx = [], [], []
    rows = len(profile)
    for j, (r, y) in enumerate(profile):
        a, b = profile[max(j - 1, 0)], profile[min(j + 1, rows - 1)]
        dr, dy = b[0] - a[0], b[1] - a[1]
        nr, ny = dy, -dr
        ln = math.hypot(nr, ny) or 1
        for k in range(segments + 1):
            t = 2 * math.pi * k / segments
            c, s = math.cos(t), math.sin(t)
            verts.append((r * c, y, r * s))
            norms.append((nr / ln * c, ny / ln, nr / ln * s))
    for j in range(rows - 1):
        for k in range(segments):
            p = j * (segments + 1) + k
            q = p + segments + 1
            idx += [p, q, p + 1, p + 1, q, q + 1]
    return np.array(verts, np.float32), np.array(norms, np.float32), np.array(idx, np.uint32)


def box(w, h, d):
    """A box on the ground (y from 0 to h), centred on x and z."""
    x, z = w / 2, d / 2
    faces = [((0, 1, 0), [(-x, h, -z), (x, h, -z), (x, h, z), (-x, h, z)]), ((0, -1, 0), [(-x, 0, z), (x, 0, z), (x, 0, -z), (-x, 0, -z)]),
             ((0, 0, 1), [(-x, 0, z), (-x, h, z), (x, h, z), (x, 0, z)]), ((0, 0, -1), [(x, 0, -z), (x, h, -z), (-x, h, -z), (-x, 0, -z)]),
             ((1, 0, 0), [(x, 0, z), (x, h, z), (x, h, -z), (x, 0, -z)]), ((-1, 0, 0), [(-x, 0, -z), (-x, h, -z), (-x, h, z), (-x, 0, z)])]
    verts, norms, idx = [], [], []
    for n, quad in faces:
        b = len(verts)
        verts += quad
        norms += [n] * 4
        idx += [b, b + 1, b + 2, b, b + 2, b + 3]
    return np.array(verts, np.float32), np.array(norms, np.float32), np.array(idx, np.uint32)


def torus(R, r, arc=math.pi, seg=24, tube=12):
    """Part of a torus in the x-y plane (a cup's handle)."""
    verts, norms, idx = [], [], []
    for i in range(seg + 1):
        u = -arc / 2 + arc * i / seg
        cu, su = math.cos(u), math.sin(u)
        for j in range(tube + 1):
            v = 2 * math.pi * j / tube
            cv, sv = math.cos(v), math.sin(v)
            verts.append(((R + r * cv) * cu, (R + r * cv) * su, r * sv))
            norms.append((cv * cu, cv * su, sv))
    for i in range(seg):
        for j in range(tube):
            p = i * (tube + 1) + j
            q = p + tube + 1
            idx += [p, q, p + 1, p + 1, q, q + 1]
    return np.array(verts, np.float32), np.array(norms, np.float32), np.array(idx, np.uint32)


def trophy():
    m = Model()
    gold = m.material('gold', GOLD, metal=1.0, rough=0.22)
    navy = m.material('navy', NAVY_DEEP, metal=0.2, rough=0.5)
    rim = m.material('rim', MINT, metal=0.6, rough=0.3)
    m.add(box(0.9, 0.28, 0.9), navy)
    m.add(box(0.94, 0.04, 0.94), rim, at=(0, 0.28, 0))
    m.add(lathe([(0.0, 0.32), (0.28, 0.32), (0.22, 0.38), (0.08, 0.46), (0.06, 0.62), (0.07, 0.7), (0.14, 0.76), (0.36, 0.9), (0.46, 1.15),
                 (0.48, 1.4), (0.44, 1.42), (0.40, 1.18), (0.30, 0.96), (0.0, 0.92)]), gold)
    for side in (-1, 1):
        m.add(torus(0.17, 0.035, arc=math.pi * 1.1), gold, at=(side * 0.46, 1.12, 0), rot_z=0 if side > 0 else math.pi)
    m.save('trophy')


def player_card():
    m = Model()
    front = m.material('front', GOLD, metal=0.85, rough=0.3)
    edge = m.material('edge', GOLD_DARK, metal=0.9, rough=0.35)
    back = m.material('back', EMERALD, metal=0.3, rough=0.45)
    m.add(box(0.7, 1.0, 0.02), back, at=(0, 0, -0.012))
    m.add(box(0.7, 1.0, 0.02), front, at=(0, 0, 0.012))
    m.add(box(0.74, 0.03, 0.05), edge, at=(0, -0.015, 0))
    m.add(box(0.74, 0.03, 0.05), edge, at=(0, 0.985, 0))
    m.save('player_card')


def stadium():
    m = Model()
    grass = m.material('grass', PITCH, rough=0.9)
    stand = m.material('stand', NAVY, rough=0.6)
    roof = m.material('roof', CREAM, metal=0.2, rough=0.4)
    light = m.material('light', GOLD, metal=0.7, rough=0.3)
    academy = m.material('academy', MINT, rough=0.5)
    medic = m.material('medic', RED, rough=0.5)
    office = m.material('office', GOLD_DARK, metal=0.4, rough=0.4)
    m.add(box(2.2, 0.04, 1.4), grass)
    bowl = lathe([(1.0, 0.0), (1.05, 0.05), (1.45, 0.42), (1.5, 0.48), (1.0, 0.0)], 64)
    m.add(bowl, stand, scale=(1.18, 1, 0.82))
    m.add(lathe([(1.42, 0.5), (1.6, 0.56), (1.6, 0.6), (1.42, 0.54)], 64), roof, scale=(1.18, 1, 0.82))
    for x, z in ((1.8, 1.25), (-1.8, 1.25), (1.8, -1.25), (-1.8, -1.25)):
        m.add(box(0.05, 0.9, 0.05), stand, at=(x, 0, z))
        m.add(box(0.2, 0.08, 0.06), light, at=(x, 0.9, z))
    m.add(box(0.6, 0.35, 0.4), academy, at=(-2.05, 0, 0.9))
    m.add(box(0.5, 0.45, 0.4), medic, at=(2.05, 0, 0.9))
    m.add(box(0.7, 0.55, 0.35), office, at=(0.0, 0, -1.6))
    m.save('stadium')


def chest(name, body, metal):
    m = Model()
    wood = m.material('body', body, metal=metal, rough=0.35)
    band = m.material('band', NAVY_DEEP, metal=0.4, rough=0.4)
    lock = m.material('lock', MINT if name == 'legend' else CREAM, metal=0.8, rough=0.2)
    m.add(box(1.0, 0.55, 0.65), wood)
    lid = lathe([(0.0, -0.5), (0.33, -0.5), (0.33, 0.5), (0.0, 0.5)], 24)
    # The lid: a half cylinder lying along x on top of the body.
    m.add(lid, wood, at=(0, 0.55, 0), rot_z=math.pi / 2)
    for x in (-0.36, 0.36):
        m.add(box(0.08, 0.57, 0.67), band, at=(x, 0, 0))
    m.add(box(0.14, 0.18, 0.04), lock, at=(0, 0.42, 0.33))
    m.save(f'chest_{name}')


if __name__ == '__main__':
    trophy()
    player_card()
    stadium()
    chest('bronze', BRONZE, 0.7)
    chest('silver', SILVER, 0.9)
    chest('legend', GOLD, 1.0)
