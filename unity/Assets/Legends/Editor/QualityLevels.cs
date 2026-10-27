using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Legends.EditorTools
{
    /// <summary>
    /// URP and the three quality levels of README.md 7.6 (Sprint 2, U4): Low, Medium, High, each with its own
    /// URP asset in Assets/Legends/Quality/. High: soft shadows from the four floodlight banks, 4x MSAA, full
    /// resolution (the computer). Medium: shadows from the main light only, 2x MSAA (a good phone). Low: no
    /// shadows, 80% resolution (a weak phone or a phone's browser). Bridge.OnQuality picks among them by index.
    /// Run by `build.ps1 demo` before the Arena is built, so the materials are made with URP's shaders.
    /// </summary>
    public static class QualityLevels
    {
        const string Dir = "Assets/Legends/Quality";
        static readonly string[] Names = { "Low", "Medium", "High" };

        [MenuItem("Legends/Set up URP and quality levels")]
        public static void Ensure()
        {
            Directory.CreateDirectory(Dir);
            var renderer = Load<UniversalRendererData>(Dir + "/URP-Renderer.asset", () => ScriptableObject.CreateInstance<UniversalRendererData>());
            var assets = new UniversalRenderPipelineAsset[3];
            for (int i = 0; i < 3; i++)
            {
                assets[i] = Load(Dir + "/URP-" + Names[i] + ".asset", () => UniversalRenderPipelineAsset.Create(renderer));
                Configure(assets[i], i);
            }

            GraphicsSettings.defaultRenderPipeline = assets[2];
            ThreeLevels();
            for (int i = 0; i < 3; i++)
            {
                QualitySettings.SetQualityLevel(i, false);
                QualitySettings.renderPipeline = assets[i];
                QualitySettings.vSyncCount = 1;
            }
            QualitySettings.SetQualityLevel(2, true);
            AssetDatabase.SaveAssets();
            Debug.Log("Legends: URP with quality levels Low, Medium, High (" + Dir + ")");
        }

        static T Load<T>(string path, System.Func<T> make) where T : ScriptableObject
        {
            var asset = AssetDatabase.LoadAssetAtPath<T>(path);
            if (asset != null) return asset;
            asset = make();
            AssetDatabase.CreateAsset(asset, path);
            return asset;
        }

        /// <summary>
        /// Through the serialized fields, so it holds across URP versions whose C# setters differ. The floodlights
        /// are spot lights (URP's "additional lights"): per pixel at every level, with shadows on High only.
        /// </summary>
        static void Configure(UniversalRenderPipelineAsset asset, int level)
        {
            var so = new SerializedObject(asset);
            void Set(string field, System.Action<SerializedProperty> set)
            {
                var p = so.FindProperty(field);
                if (p != null) set(p);
                else Debug.LogWarning("Legends: URP asset has no field " + field);
            }
            Set("m_SupportsHDR", p => p.boolValue = level > 0);
            Set("m_MSAA", p => p.intValue = level == 2 ? 4 : level == 1 ? 2 : 1);
            Set("m_RenderScale", p => p.floatValue = level == 0 ? 0.8f : 1f);
            Set("m_MainLightShadowsSupported", p => p.boolValue = level > 0);
            Set("m_MainLightShadowmapResolution", p => p.intValue = level == 2 ? 2048 : 1024);
            Set("m_AdditionalLightsRenderingMode", p => p.intValue = 1);   // per pixel
            Set("m_AdditionalLightsPerObjectLimit", p => p.intValue = 4);
            Set("m_AdditionalLightShadowsSupported", p => p.boolValue = level == 2);
            Set("m_AdditionalLightsShadowmapResolution", p => p.intValue = 2048);
            Set("m_ShadowDistance", p => p.floatValue = level == 2 ? 150f : 90f);
            Set("m_ShadowCascadeCount", p => p.intValue = level == 2 ? 2 : 1);
            Set("m_SoftShadowsSupported", p => p.boolValue = level == 2);
            so.ApplyModifiedPropertiesWithoutUndo();
            EditorUtility.SetDirty(asset);
        }

        /// <summary>Keeps the project's first three levels, renamed Low, Medium, High; every platform starts on its own.</summary>
        static void ThreeLevels()
        {
            var settings = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/QualitySettings.asset");
            if (settings.Length == 0) return;
            var so = new SerializedObject(settings[0]);
            var levels = so.FindProperty("m_QualitySettings");
            if (levels == null) return;
            while (levels.arraySize < 3) levels.InsertArrayElementAtIndex(levels.arraySize);
            levels.arraySize = 3;
            for (int i = 0; i < 3; i++)
            {
                var level = levels.GetArrayElementAtIndex(i);
                level.FindPropertyRelative("name").stringValue = Names[i];
            }
            // The computer and the web start High (the page lowers it for phones), Android starts Medium.
            var defaults = so.FindProperty("m_PerPlatformDefaultQuality");
            if (defaults != null)
            {
                for (int i = 0; i < defaults.arraySize; i++)
                {
                    var entry = defaults.GetArrayElementAtIndex(i);
                    var platform = entry.FindPropertyRelative("first");
                    var index = entry.FindPropertyRelative("second");
                    if (platform == null || index == null) continue;
                    index.intValue = platform.stringValue == "Android" || platform.stringValue == "iPhone" ? 1 : 2;
                }
            }
            var current = so.FindProperty("m_CurrentQuality");
            if (current != null) current.intValue = 2;
            so.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
