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

        void OnPreprocessModel()
        {
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
