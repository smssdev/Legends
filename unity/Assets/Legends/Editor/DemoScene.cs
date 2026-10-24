using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// Builds Assets/Legends/Scenes/Match.unity: the Arena, the match scene with its bridge, the broadcast camera,
    /// the score, and the recorded Liverpool v Arsenal match (docs/api/samples/) playing through the bridge.
    /// Press Play to watch it. Legends → Build match scene, or `build.ps1 demo`.
    /// </summary>
    public static class DemoScene
    {
        const string ScenePath = "Assets/Legends/Scenes/Match.unity";
        const string Sample = "../docs/api/samples/liverpool-arsenal-48213.json";

        [MenuItem("Legends/Build match scene")]
        public static void Build()
        {
            // URP and the quality levels first, so the Arena's materials are made with URP's shaders (U4).
            QualityLevels.Ensure();
            Directory.CreateDirectory("Assets/Legends/Scenes");
            Directory.CreateDirectory("Assets/StreamingAssets");
            if (File.Exists(Sample)) File.Copy(Sample, "Assets/StreamingAssets/sample-match.json", true);
            else Debug.LogWarning("Legends: no sample at " + Path.GetFullPath(Sample));
            AssetDatabase.Refresh();

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            ArenaBuilder.Build(null);

            var match = new GameObject("Match").AddComponent<Legends.MatchScene>();
            match.playerMaterial = Mat("Player", Color.white);
            match.ballMaterial = Mat("Ball", Color.white);
            // A faint glow, so the ball reads from the broadcast camera under the floodlights.
            match.ballMaterial.EnableKeyword("_EMISSION");
            match.ballMaterial.SetColor("_EmissionColor", Color.white * 0.6f);

            var bridge = new GameObject("Bridge").AddComponent<Legends.Bridge>();   // the page calls it by this name
            bridge.scene = match;
            var playback = bridge.gameObject.AddComponent<Legends.SamplePlayback>();
            playback.bridge = bridge;
            bridge.gameObject.AddComponent<Legends.Scoreboard>().scene = match;

            var cam = new GameObject("Broadcast Camera");
            var camera = cam.AddComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.02f, 0.03f, 0.06f);   // the night sky over the roof
            camera.fieldOfView = 30;
            camera.farClipPlane = 600;
            cam.tag = "MainCamera";
            cam.AddComponent<AudioListener>();
            cam.AddComponent<Legends.BroadcastCamera>().scene = match;
            cam.transform.position = new Vector3(0, 30, -62);
            cam.transform.LookAt(Vector3.zero);

            var moon = new GameObject("Moonlight").AddComponent<Light>();
            moon.type = LightType.Directional;
            moon.intensity = 0.25f;
            moon.color = new Color(0.7f, 0.75f, 1f);
            moon.transform.rotation = Quaternion.Euler(50, -30, 0);

            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
            Debug.Log("Legends: " + ScenePath + " is ready. Press Play.");
        }

        static Material Mat(string name, Color color)
        {
            string path = "Assets/Legends/Materials/" + name + ".mat";
            Directory.CreateDirectory("Assets/Legends/Materials");
            var shader = Shader.Find(UnityEngine.Rendering.GraphicsSettings.currentRenderPipeline != null ? "Universal Render Pipeline/Lit" : "Standard");
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat == null)
            {
                mat = new Material(shader);
                AssetDatabase.CreateAsset(mat, path);
            }
            mat.shader = shader;   // made before URP: moved to its shader
            mat.color = color;
            EditorUtility.SetDirty(mat);
            return mat;
        }
    }
}
