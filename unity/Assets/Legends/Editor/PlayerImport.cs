using System.Linq;
using UnityEditor;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 06 U5] How the players from Blender come in (Assets/Legends/Players, tools/unity/players/export_players.py):
    /// each build a Humanoid with its own avatar, its faces and origins as blend shapes, no materials of its own (PlayerArt
    /// gives them), and the LOD Group from the _LOD0/_LOD1/_LOD2 names. And their textures: the skins sharp, the hair,
    /// brows and lashes with their alpha, the normal maps as normal maps.
    /// </summary>
    public sealed class PlayerImport : AssetPostprocessor
    {
        const string Folder = "Assets/Legends/Players/";
        const string Moves = "Assets/Legends/Animation/Moves/";
        /// <summary>[Sprint 07 U3] The moves that loop (the others play once and hold their last pose).</summary>
        public static readonly string[] Looping = { "idle", "keeper_ready", "celebrate_wings" };

        void OnPreprocessModel()
        {
            if (assetPath.StartsWith(Moves))
            {
                // [Sprint 07 U3] tools/unity/players/keyframes.py: the rig only, every move a take, played on every build
                // through the Humanoid avatar of the medium player (the same rig, so it maps bone for bone).
                var a = (ModelImporter)assetImporter;
                a.animationType = ModelImporterAnimationType.Human;
                a.avatarSetup = ModelImporterAvatarSetup.CopyFromOther;
                a.sourceAvatar = AssetDatabase.LoadAllAssetsAtPath(Folder + "player_medium.fbx").OfType<Avatar>().FirstOrDefault();
                a.importAnimation = true;
                a.materialImportMode = ModelImporterMaterialImportMode.None;
                a.importBlendShapes = false;
                a.importCameras = a.importLights = false;
                a.resampleCurves = true;
                return;
            }
            if (!assetPath.StartsWith(Folder)) return;
            var m = (ModelImporter)assetImporter;
            m.globalScale = 1f;
            m.useFileScale = true;
            m.animationType = ModelImporterAnimationType.Human;
            m.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
            m.importAnimation = false;
            m.importBlendShapes = true;
            m.importBlendShapeNormals = ModelImporterNormals.Calculate;
            m.importCameras = m.importLights = false;
            m.materialImportMode = ModelImporterMaterialImportMode.None;
            m.meshCompression = ModelImporterMeshCompression.Low;
            m.optimizeGameObjects = false;     // PlayerLook finds the parts by name
            m.isReadable = false;
        }

        /// <summary>
        /// [Sprint 07 U3] Each take a clip named as the move. The body stays where the move puts it (its turn, height
        /// and travel baked into the pose, from the move's own start): MatchScene places the player, the move only
        /// moves him around that spot (a dive two metres to the side), and never drifts him off it.
        /// </summary>
        void OnPreprocessAnimation()
        {
            if (!assetPath.StartsWith(Moves)) return;
            var a = (ModelImporter)assetImporter;
            var clips = a.defaultClipAnimations;
            foreach (var clip in clips)
            {
                string name = clip.takeName.Contains("|") ? clip.takeName.Substring(clip.takeName.LastIndexOf('|') + 1) : clip.takeName;
                clip.name = name;
                clip.loopTime = System.Array.IndexOf(Looping, name) >= 0;
                clip.lockRootRotation = clip.keepOriginalOrientation = true;
                clip.lockRootHeightY = clip.keepOriginalPositionY = true;
                clip.lockRootPositionXZ = clip.keepOriginalPositionXZ = true;
            }
            a.clipAnimations = clips;
        }

        void OnPreprocessTexture()
        {
            if (!assetPath.StartsWith(Folder + "Textures/")) return;
            var t = (TextureImporter)assetImporter;
            string file = System.IO.Path.GetFileNameWithoutExtension(assetPath);
            t.mipmapEnabled = true;
            t.textureCompression = TextureImporterCompression.CompressedHQ;
            if (file.EndsWith("_normal"))
            {
                t.textureType = TextureImporterType.NormalMap;
                return;
            }
            t.textureType = TextureImporterType.Default;
            t.sRGBTexture = true;
            bool alpha = !file.StartsWith("skin_");   // the eye keeps its alpha: its clear cornea over the iris
            t.alphaSource = alpha ? TextureImporterAlphaSource.FromInput : TextureImporterAlphaSource.None;
            t.alphaIsTransparency = alpha;
            t.maxTextureSize = file.StartsWith("skin_") ? 1024 : 512;
            if (file == "numbers")
            {
                // The shirt numbers' atlas: ten digits side by side, sharp at its full 1280 pixels, never repeated.
                t.maxTextureSize = 2048;
                t.npotScale = TextureImporterNPOTScale.None;
                t.wrapMode = TextureWrapMode.Clamp;
                t.textureCompression = TextureImporterCompression.Uncompressed;
            }
        }
    }
}
