using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 46, the owner's choice 2026-11-06] The app's opening picture: real-looking people, our own, in place of the
    /// cartoon. Seven of our MakeHuman players (Sprint 06) in the game's own kits stand in a V under two floodlights at
    /// night, the middle one nearest, in our own poses (Animation/Moves: idle, the fist, the wings). The background is
    /// left clear, so the app lays them over its stadium. `build.ps1 splash` saves mobile/assets/splash/squad.png
    /// (2000 × 800) and a copy in unity/Captures; then the APK is built and the app's opening shows them
    /// (intro_screen.dart). Nothing of another game: our players, our kits, our poses.
    /// </summary>
    public static class SplashCapture
    {
        const string Clips = "Assets/Legends/Animation/Moves/moves.fbx";
        const string ArtPath = "Assets/Legends/Resources/PlayerArt.asset";

        public static void Run()
        {
            int code = 0;
            try { Capture(); }
            catch (System.Exception e) { Debug.LogError("Legends: " + e); code = 1; }
            EditorApplication.Exit(code);
        }

        // Where each stands (x across, z toward the camera), his look's id, the kit (0 our navy and gold, 1 white), his
        // number and his pose with its moment.
        static readonly (float x, float z, string id, int kit, int number, string clip, float at)[] Squad =
        {
            (0f, 1.2f, "9001", 0, 10, "celebrate_fist", 0.55f),
            (-1.35f, 0.4f, "9002", 1, 9, "idle", 0.2f),
            (1.35f, 0.4f, "9003", 1, 7, "idle", 0.6f),
            (-2.6f, -0.4f, "9004", 0, 4, "celebrate_wings", 0.5f),
            (2.6f, -0.4f, "9005", 0, 8, "idle", 0.4f),
            (-3.8f, -1.2f, "9006", 1, 1, "idle", 0.8f),
            (3.8f, -1.2f, "9007", 1, 11, "celebrate_fist", 0.4f),
        };

        [MenuItem("Legends/Players/Capture the app's opening squad")]
        public static void Capture()
        {
            AssetDatabase.Refresh();
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            if (art == null) throw new System.Exception("no PlayerArt: run build.ps1 players first");
            var clips = AssetDatabase.LoadAllAssetsAtPath(Clips).OfType<AnimationClip>().Where(c => !c.name.StartsWith("__preview__")).GroupBy(c => c.name).ToDictionary(g => g.Key, g => g.First());
            var cam = Stage();
            var kits = new[]
            {
                KitColours.Of(new Color32(0x0F, 0x22, 0x48, 0xFF), new Color32(0xF5, 0xB8, 0x2E, 0xFF), "plain"),
                KitColours.Of(new Color32(0xF3, 0xF0, 0xE6, 0xFF), new Color32(0x2A, 0x62, 0xC6, 0xFF), "plain"),
            };
            AnimationMode.StartAnimationMode();
            AnimationMode.BeginSampling();
            foreach (var s in Squad)
            {
                var look = PlayerLook.From(s.id);
                var p = art.Spawn(look, null, kits[s.kit], s.number);
                p.transform.position = new Vector3(s.x, 0, s.z);
                // Each turned a little toward the middle, as a team stands for its picture.
                p.transform.rotation = Quaternion.Euler(0, -s.x * 4f, 0);
                if (clips.TryGetValue(s.clip, out var clip)) MovesCapture.Pose(p.gameObject, clip, clip.length * s.at);
            }
            AnimationMode.EndSampling();
            float bias = QualitySettings.lodBias;
            QualitySettings.lodBias = 100f;
            var png = Render(cam, 2000, 800);
            QualitySettings.lodBias = bias;
            AnimationMode.StopAnimationMode();

            string repo = Path.GetDirectoryName(Path.GetDirectoryName(Application.dataPath));
            string app = Path.Combine(repo, "mobile", "assets", "splash");
            Directory.CreateDirectory(app);
            File.WriteAllBytes(Path.Combine(app, "squad.png"), png);
            string captures = Path.Combine(Path.GetDirectoryName(Application.dataPath), "Captures");
            Directory.CreateDirectory(captures);
            File.WriteAllBytes(Path.Combine(captures, "splash-squad.png"), png);
            Debug.Log("Legends: saved mobile/assets/splash/squad.png and Captures/splash-squad.png");
        }

        /// <summary>Night: no sun, a cool low ambient, two floodlights from high at the sides and a soft key from the front.</summary>
        static Camera Stage()
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.32f, 0.38f, 0.55f);
            RenderSettings.ambientEquatorColor = new Color(0.22f, 0.26f, 0.36f);
            RenderSettings.ambientGroundColor = new Color(0.10f, 0.16f, 0.12f);
            foreach (var side in new[] { -1f, 1f })
            {
                var flood = new GameObject("Floodlight").AddComponent<Light>();
                flood.type = LightType.Spot;
                flood.range = 60;
                flood.spotAngle = 55;
                flood.intensity = 70;
                flood.color = new Color(1f, 0.95f, 0.85f);
                flood.shadows = LightShadows.Soft;
                flood.transform.position = new Vector3(side * 9f, 14f, 9f);
                flood.transform.LookAt(new Vector3(0, 0.9f, 0));
            }
            var key = new GameObject("Key").AddComponent<Light>();
            key.type = LightType.Directional;
            key.intensity = 0.55f;
            key.color = new Color(0.85f, 0.9f, 1f);
            key.transform.rotation = Quaternion.Euler(18, 180, 0);
            var cam = new GameObject("Camera").AddComponent<Camera>();
            cam.transform.position = new Vector3(0, 1.15f, 9.5f);   // the players face +Z
            cam.transform.LookAt(new Vector3(0, 1.0f, 0));
            cam.fieldOfView = 30;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0, 0, 0, 0);   // clear: the app's stadium shows through
            return cam;
        }

        static byte[] Render(Camera cam, int w, int h)
        {
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32) { antiAliasing = 8 };
            cam.targetTexture = rt;
            cam.Render();
            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            RenderTexture.active = null;
            cam.targetTexture = null;
            return tex.EncodeToPNG();
        }
    }
}
