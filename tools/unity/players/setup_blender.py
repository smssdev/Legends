"""Sprint 06 U1: MPFB (MakeHuman's own Blender extension) and MakeHuman's CC0 asset packs, installed once in the
Blender on this machine, so build_players.py can make Legends' people (PLAN 7.11).

  blender -b -P tools/unity/players/setup_blender.py

Downloads what is missing into tools/unity/players/downloads/ (outside git), installs MPFB into Blender's user
extensions, then unpacks the packs into MPFB's own data folder. Run it again any time: what is there is kept.
MPFB is GPL (the tool); the packs and what we make from them are CC0, ours to ship.
"""
import hashlib, os, sys, urllib.request, zipfile
import bpy, addon_utils

HERE = os.path.dirname(os.path.abspath(__file__))
DOWNLOADS = os.path.join(HERE, 'downloads')

MPFB = ('mpfb-2.0.18.zip', 'https://extensions.blender.org/download/sha256:c075b3e9b94b8e5556a5f03f4653602d02ea306de08126e8f55ed6dee28a2dad/add-on-mpfb-v2.0.18.zip?repository=%2Fapi%2Fv1%2Fextensions%2F&blender_version_min=4.2.0',
        'c075b3e9b94b8e5556a5f03f4653602d02ea306de08126e8f55ed6dee28a2dad')
# MakeHuman's official packs (static.makehumancommunity.org/assets/assetpacks.html), all CC0: the system assets
# (eyes, eyebrows, short hair, proxies, the game engine rig's weights), and the natural male skins.
PACKS = [
    ('makehuman_system_assets_cc0.zip', 'https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip'),
    ('skins02_cc0.zip', 'https://files.makehumancommunity.org/asset_packs/skins02/skins02_cc0.zip'),
]


def fetch(name, url, sha=None):
    path = os.path.join(DOWNLOADS, name)
    if not os.path.exists(path):
        os.makedirs(DOWNLOADS, exist_ok=True)
        print('Legends: downloading', name)
        urllib.request.urlretrieve(url, path + '.part')
        os.replace(path + '.part', path)
    if sha:
        h = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        if h != sha:
            sys.exit('Legends: %s is not the file we expect (sha256 %s)' % (name, h))
    return path


def mpfb_module():
    for mod in addon_utils.modules(refresh=True):
        if mod.__name__.endswith('.mpfb'):
            return mod.__name__
    return None


def main():
    if not mpfb_module():
        zip_path = fetch(*MPFB)
        bpy.ops.extensions.package_install_files(filepath=zip_path, repo='user_default', enable_on_install=True)
    name = mpfb_module()
    if not name:
        sys.exit('Legends: MPFB did not install')
    addon_utils.enable(name, default_set=True, persistent=True)
    bpy.ops.wm.save_userpref()
    data = os.path.join(bpy.utils.extension_path_user(name, create=True), 'data')
    os.makedirs(data, exist_ok=True)
    for pack, url in PACKS:
        mark = os.path.join(data, '.legends-' + pack)
        if os.path.exists(mark):
            continue
        with zipfile.ZipFile(fetch(pack, url)) as z:
            z.extractall(data)
        open(mark, 'w').close()
        print('Legends: unpacked', pack)
    print('Legends: MPFB ready (%s), assets in %s' % (name, data))


main()
