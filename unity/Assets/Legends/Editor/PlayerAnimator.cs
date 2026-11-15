using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 07 U4] Animation/Player.controller, built from the moves (Animation/Moves/moves.fbx) and the strides' own
    /// speeds (locomotion.json), and set on Resources/PlayerArt.asset so every player and official gets it:
    /// <list type="bullet">
    /// <item>Locomotion (the default): a 1D blend on Speed of standing and the five strides, each at its own speed in
    /// m/s, so a blend at Speed s covers s metres a second; played at Pace (Gait.Pace) for speeds beyond its ends.</item>
    /// <item>A state for every other move by its name. PlayerStride.Play blends into it; the once-only moves blend back to
    /// Locomotion as they end, the ones that hold (Holds: on the grass) and the loops stay until PlayerStride.Stride.</item>
    /// </list>
    /// `build.ps1 moves` builds it before its pictures; Legends > Players > Build the animator does it alone.
    /// </summary>
    public static class PlayerAnimator
    {
        public const string Path = "Assets/Legends/Animation/Player.controller";
        const string Clips = "Assets/Legends/Animation/Moves/moves.fbx";
        const string Speeds = "Assets/Legends/Animation/Moves/locomotion.json";
        const string ArtPath = "Assets/Legends/Resources/PlayerArt.asset";

        /// <summary>The moves that end on the grass (or on his knees) and stay there until the scene says otherwise.</summary>
        public static readonly string[] Holds =
        {
            "fall", "keeper_dive_l_high", "keeper_dive_l_low", "keeper_dive_r_high", "keeper_dive_r_low", "celebrate_knee_slide",
        };

        /// <summary>The blend back to the stride as a once-only move ends (s).</summary>
        public const float Back = 0.2f;

        [MenuItem("Legends/Players/Build the animator")]
        public static AnimatorController Build()
        {
            AssetDatabase.Refresh();
            var clips = AssetDatabase.LoadAllAssetsAtPath(Clips).OfType<AnimationClip>()
                .Where(c => !c.name.StartsWith("__preview__")).ToDictionary(c => c.name);
            if (clips.Count == 0) throw new System.Exception("no moves in " + Clips + " (run tools/unity/players/keyframes.py)");
            var speeds = MiniJson.Parse(File.ReadAllText(Speeds)) as Dictionary<string, object>;

            AssetDatabase.DeleteAsset(Path);
            var controller = AnimatorController.CreateAnimatorControllerAtPath(Path);
            controller.AddParameter("Speed", AnimatorControllerParameterType.Float);
            controller.AddParameter(new AnimatorControllerParameter { name = "Pace", type = AnimatorControllerParameterType.Float, defaultFloat = 1f });
            var machine = controller.layers[0].stateMachine;

            // the strides, standing first, each at its own speed
            var tree = new BlendTree
            {
                name = PlayerStride.Locomotion, blendType = BlendTreeType.Simple1D, blendParameter = "Speed",
                useAutomaticThresholds = false,
            };
            AssetDatabase.AddObjectToAsset(tree, controller);
            tree.AddChild(clips["idle"], 0f);
            var strides = new HashSet<string> { "idle" };
            foreach (var (clip, _) in Gait.Strides)
            {
                var row = (Dictionary<string, object>)speeds[clip];
                tree.AddChild(clips[clip], System.Convert.ToSingle(row["speed"]));
                strides.Add(clip);
            }
            var locomotion = machine.AddState(PlayerStride.Locomotion, new Vector3(300, 0, 0));
            locomotion.motion = tree;
            locomotion.speedParameter = "Pace";
            locomotion.speedParameterActive = true;
            locomotion.writeDefaultValues = false;
            machine.defaultState = locomotion;

            // every other move a state of its own, in a grid beside it
            int n = 0;
            foreach (var clip in clips.Values.OrderBy(c => c.name))
            {
                if (strides.Contains(clip.name)) continue;
                var state = machine.AddState(clip.name, new Vector3(600 + 250 * (n % 4), 80 * (n / 4) - 400, 0));
                n++;
                state.motion = clip;
                state.writeDefaultValues = false;
                if (clip.isLooping || Holds.Contains(clip.name)) continue;
                var back = state.AddTransition(locomotion);
                back.hasExitTime = true;
                back.hasFixedDuration = true;
                back.duration = Back;
                back.exitTime = Mathf.Clamp01(1f - Back / Mathf.Max(clip.length, 0.01f));
            }
            EditorUtility.SetDirty(controller);

            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            if (art != null)
            {
                art.motion = controller;
                art.strideSpeeds = null;
                art.strideSpeeds = Measure(art);
                EditorUtility.SetDirty(art);
                Debug.Log("Legends: the blend covers " + string.Join(", ", art.strideSpeeds.Select(v => $"{v.x:0.00}: {v.y:0.00}")) + " m/s");
            }
            AssetDatabase.SaveAssets();
            Debug.Log($"Legends: {Path}: the five strides by speed and {n} moves");
            return controller;
        }

        /// <summary>
        /// What each Speed blend really covers on our player, in m/s at pace 1: the medium build strides on the spot, and
        /// the speed his planted foot goes back under him (the frames it is within 2 cm of its lowest) is the speed his
        /// body would go over the grass with no slide. From the walk to the sprint every 0.25, and at every stride.
        /// </summary>
        public static Vector2[] Measure(PlayerArt art)
        {
            var blends = new SortedSet<float>();
            for (float b = Gait.Walk; b < Gait.Sprint; b += 0.25f) blends.Add(Mathf.Round(b * 100f) / 100f);
            foreach (var (_, speed) in Gait.Strides) blends.Add(speed);
            var look = PlayerLook.From("4242");
            look.Build = 0;
            var p = art.Spawn(look, null, KitColours.Of(Color.red, Color.white, "plain"), 9);
            var rows = new List<Vector2>();
            try
            {
                var animator = p.GetComponent<Animator>();
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
                const float dt = 1f / 60f;
                foreach (float b in blends)
                {
                    animator.Rebind();
                    animator.SetFloat(PlayerStride.SpeedId, b);
                    animator.SetFloat(PlayerStride.PaceId, 1f);
                    var feet = new List<(Vector3 l, Vector3 r)>();
                    for (float t = 0; t < 4f; t += dt)
                    {
                        animator.Update(dt);
                        if (t > 1f) feet.Add((animator.GetBoneTransform(HumanBodyBones.LeftToes).position, animator.GetBoneTransform(HumanBodyBones.RightToes).position));
                    }
                    float sum = 0f;
                    int n = 0;
                    foreach (var pick in new System.Func<(Vector3 l, Vector3 r), Vector3>[] { f => f.l, f => f.r })
                    {
                        var path = feet.Select(pick).ToList();
                        float low = path.Min(v => v.y);
                        for (int i = 1; i < path.Count; i++)
                        {
                            if (path[i].y > low + 0.02f || path[i - 1].y > low + 0.02f) continue;
                            sum += -(path[i].z - path[i - 1].z) / dt;     // he faces +Z: a planted foot goes back under him
                            n++;
                        }
                    }
                    rows.Add(new Vector2(b, n > 0 ? sum / n : b));
                }
            }
            finally
            {
                Object.DestroyImmediate(p.gameObject);
            }
            return rows.ToArray();
        }
    }
}
