using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 07 U3] Claude's eye on the moves in Unity (`build.ps1 moves`): each move of Animation/Moves/moves.fbx at
    /// five moments (its start, a quarter, half, three quarters, its end), on players of the three builds in a row, saved
    /// as unity/Captures/moves/&lt;move&gt;.png. The same moves Blender drew in unity/Reference/moves, now through the
    /// Humanoid avatar on every build: if a limb goes wrong here and not there, the import is at fault, not the move.
    /// </summary>
    public static class MovesCapture
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

        [MenuItem("Legends/Players/Capture the moves")]
        public static void Capture()
        {
            AssetDatabase.Refresh();
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            var clips = AssetDatabase.LoadAllAssetsAtPath(Clips).OfType<AnimationClip>().Where(c => !c.name.StartsWith("__preview__")).ToList();
            if (clips.Count == 0) throw new System.Exception("no moves in " + Clips + " (run tools/unity/players/keyframes.py)");
            string folder = Path.Combine(Path.GetDirectoryName(Application.dataPath), "Captures", "moves");
            Directory.CreateDirectory(folder);
            var keeper = KitColours.Keepers(Color.red, Color.blue).home;
            var field = KitColours.Of(new Color32(0xC8, 0x10, 0x2E, 0xFF), Color.white, "plain");
            var refs = KitColours.Officials(Color.red, Color.blue, keeper.Shirt, KitColours.Keepers(Color.red, Color.blue).away.Shirt);
            foreach (var clip in clips)
            {
                Stage(out var cam);
                AnimationMode.StartAnimationMode();
                AnimationMode.BeginSampling();      // one session for the five: a new one undoes the last
                bool isKeeper = clip.name.StartsWith("keeper"), isRef = clip.name.StartsWith("ref") || clip.name.StartsWith("assistant");
                var people = new List<GameObject>();
                for (int i = 0; i < 5; i++)
                {
                    var look = PlayerLook.From((7000 + i * 13).ToString());
                    look.Build = i % PlayerLook.Builds.Length;
                    var p = art.Spawn(look, null, isKeeper ? keeper : isRef ? refs : field, isRef ? -1 : isKeeper ? 1 : 9, isKeeper);
                    p.transform.position = new Vector3((i - 2) * 3.0f, 0, 0);
                    Pose(p.gameObject, clip, clip.length * i / 4f);
                    people.Add(p.gameObject);
                }
                AnimationMode.EndSampling();
                float bias = QualitySettings.lodBias;
                QualitySettings.lodBias = 100f;
                Save(cam, Path.Combine(folder, clip.name + ".png"));
                QualitySettings.lodBias = bias;
                AnimationMode.StopAnimationMode();
                Debug.Log($"Legends: move {clip.name} ({clip.length:0.00} s, {(clip.isLooping ? "loops" : "once")})");
            }
        }

        /// <summary>
        /// Puts a player in a clip's pose at time t through his Animator and avatar, outside play mode, as Unity's own
        /// Animation window does (inside AnimationMode's sampling, which stays until the picture is taken).
        /// </summary>
        public static void Pose(GameObject player, AnimationClip clip, float t)
        {
            var animator = player.GetComponent<Animator>();
            if (animator == null) throw new System.Exception(player.name + " has no Animator");
            animator.applyRootMotion = false;
            AnimationMode.SampleAnimationClip(player, clip, t);
        }

        static void Stage(out Camera cam)
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var sun = new GameObject("Sun").AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 1.2f;
            sun.shadows = LightShadows.Soft;
            sun.transform.rotation = Quaternion.Euler(40, 210, 0);
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.75f, 0.8f, 0.9f);
            RenderSettings.ambientEquatorColor = new Color(0.5f, 0.55f, 0.5f);
            RenderSettings.ambientGroundColor = new Color(0.25f, 0.3f, 0.22f);
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.transform.localScale = Vector3.one * 6;
            var grass = new Material(Shader.Find("Universal Render Pipeline/Unlit"));
            grass.SetColor("_BaseColor", new Color(0.2f, 0.42f, 0.22f));
            ground.GetComponent<Renderer>().sharedMaterial = grass;
            cam = new GameObject("Camera").AddComponent<Camera>();
            // the players face +Z; a little from his right and above, so the lean and the dives read
            cam.transform.position = new Vector3(2.5f, 2.0f, 11f);
            cam.transform.LookAt(new Vector3(0, 0.7f, 0));
            cam.fieldOfView = 44;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.62f, 0.72f, 0.85f);
        }

        static void Save(Camera cam, string file)
        {
            const int w = 2400, h = 800;
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32) { antiAliasing = 4 };
            cam.targetTexture = rt;
            cam.Render();
            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            RenderTexture.active = null;
            cam.targetTexture = null;
            File.WriteAllBytes(file, tex.EncodeToPNG());
        }
    }
}
