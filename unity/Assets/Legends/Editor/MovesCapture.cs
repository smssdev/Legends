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
            PlayerAnimator.Build();     // [U4] the stride and every move, before their pictures
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
            Gaits();
            Contacts();
        }

        /// <summary>
        /// [Sprint 07 U4] The strides through the Animator (Animation/Player.controller), seen from the side: five players
        /// running on the spot at 0, 1.2, 3, 4.5 and 8 m/s (standing, a slow walk, a jog, a sprint, and a fast-forward
        /// sprint at its MaxPace), each after a second and a half on his stride. Saved as unity/Captures/moves/gaits.png.
        /// </summary>
        [MenuItem("Legends/Players/Capture the strides")]
        public static void Gaits()
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            string folder = Path.Combine(Path.GetDirectoryName(Application.dataPath), "Captures", "moves");
            Directory.CreateDirectory(folder);
            Stage(out var cam);
            cam.transform.position = new Vector3(13f, 1.4f, 0f);
            cam.transform.LookAt(new Vector3(0, 0.85f, 0));
            cam.fieldOfView = 34;
            var field = KitColours.Of(new Color32(0xC8, 0x10, 0x2E, 0xFF), Color.white, "plain");
            float[] speeds = { 0f, 1.2f, 3f, 4.5f, 8f };
            const float dt = 1f / 60f;
            var people = new List<GameObject>();
            for (int i = 0; i < speeds.Length; i++)
            {
                var look = PlayerLook.From((7100 + i * 17).ToString());
                look.Build = i % PlayerLook.Builds.Length;
                var p = art.Spawn(look, null, field, 9);
                // in a row across the picture, all running towards its left
                p.transform.position = new Vector3(0, 0, (i - 2) * 2.4f);
                var animator = p.GetComponent<Animator>();
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
                animator.Rebind();
                var stride = p.GetComponent<PlayerStride>();
                for (float t = 0; t < 1.5f + i * 0.13f; t += dt)
                {
                    stride.Go(speeds[i], dt, true);
                    animator.Update(dt);
                }
                people.Add(p.gameObject);
            }
            float bias = QualitySettings.lodBias;
            QualitySettings.lodBias = 100f;
            Save(cam, Path.Combine(folder, "gaits.png"));
            QualitySettings.lodBias = bias;
            foreach (var p in people) Object.DestroyImmediate(p);
            Debug.Log("Legends: strides at " + string.Join(", ", speeds) + " m/s");
        }

        /// <summary>
        /// [Sprint 07 U5] The touch on the ball (BallContact): five players at the contact of a pass, a power shot, a header,
        /// a keeper's dive and a catch, each with a real ball put a little off where the move alone would meet it, so the
        /// foot, the head or the hands go to where it is. Saved as unity/Captures/moves/contacts.png.
        /// </summary>
        [MenuItem("Legends/Players/Capture the touches")]
        public static void Contacts()
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            string folder = Path.Combine(Path.GetDirectoryName(Application.dataPath), "Captures", "moves");
            Directory.CreateDirectory(folder);
            Stage(out var cam);
            cam.transform.position = new Vector3(3.5f, 1.6f, 9.5f);
            cam.transform.LookAt(new Vector3(0, 0.8f, 0));
            var field = KitColours.Of(new Color32(0xC8, 0x10, 0x2E, 0xFF), Color.white, "plain");
            var keeper = KitColours.Keepers(Color.red, Color.blue).home;
            var white = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            white.SetColor("_BaseColor", Color.white);
            (string move, string with)[] shots = { ("pass", "right"), ("shot_power", "right"), ("header", "head"), ("keeper_dive_l_high", "hands"), ("keeper_catch", "hands") };
            var made = new List<GameObject>();
            for (int i = 0; i < shots.Length; i++)
            {
                var (move, with) = shots[i];
                float t = 0f;
                foreach (var x in art.touches) if (x.move == move) t = x.contact;
                bool isKeeper = with == "hands";
                var look = PlayerLook.From((7300 + i * 19).ToString());
                look.Build = i % PlayerLook.Builds.Length;
                var p = art.Spawn(look, null, isKeeper ? keeper : field, isKeeper ? 1 : 9, isKeeper);
                p.transform.position = new Vector3((i - 2) * 3.2f, 0, 0);
                var animator = p.GetComponent<Animator>();
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
                // where the move alone meets the ball, then the ball a little off it, and the pose again with the touch
                At(animator, move, t);
                Vector3 spot = with == "head" ? animator.GetBoneTransform(HumanBodyBones.Head).position + new Vector3(0, 0.14f, 0.12f)
                    : with == "hands" ? (animator.GetBoneTransform(HumanBodyBones.LeftHand).position + animator.GetBoneTransform(HumanBodyBones.RightHand).position) / 2f + new Vector3(0.12f, 0.2f, 0.15f)
                    : animator.GetBoneTransform(HumanBodyBones.RightToes).position + new Vector3(0.15f, 0, 0.12f);
                if (with == "right") spot.y = MatchScene.BallRadius;
                var ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                ball.transform.position = spot;
                ball.transform.localScale = Vector3.one * MatchScene.BallRadius * 2f;
                ball.GetComponent<Renderer>().sharedMaterial = white;
                p.GetComponent<BallContact>().Ball = ball.transform;
                At(animator, move, t);
                made.Add(p.gameObject);
                made.Add(ball);
            }
            float bias = QualitySettings.lodBias;
            QualitySettings.lodBias = 100f;
            Save(cam, Path.Combine(folder, "contacts.png"));
            QualitySettings.lodBias = bias;
            foreach (var g in made) Object.DestroyImmediate(g);
            Debug.Log("Legends: touches " + string.Join(", ", shots.Select(x => x.move)));
        }

        /// <summary>A player through his Animator to t seconds into move (the IK pass with it).</summary>
        static void At(Animator animator, string move, float t)
        {
            const float dt = 1f / 60f;
            animator.Rebind();
            animator.Update(0f);
            animator.Play(move, 0, 0f);
            animator.Update(0f);
            for (float s = 0; s < t - 1e-4f; s += dt) animator.Update(Mathf.Min(dt, t - s));
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
