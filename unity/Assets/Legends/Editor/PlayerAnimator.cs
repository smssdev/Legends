using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 07 U4] Animation/Player.controller, made from the moves (Animation/Moves/moves.fbx) each time the players
    /// are built (`build.ps1 players`): one state "Locomotion", a blend on Speed of standing (0 m/s) and the strides at
    /// their own speeds from locomotion.json (walk, walk_brisk, jog, run, sprint), played faster by Pace above the
    /// sprint; and a state for every other move, named as it, for PlayerMotion.Play. Never edited by hand.
    /// </summary>
    public static class PlayerAnimator
    {
        public const string Path = "Assets/Legends/Animation/Player.controller";
        const string Clips = "Assets/Legends/Animation/Moves/moves.fbx";
        const string Speeds = "Assets/Legends/Animation/Moves/locomotion.json";
        public static readonly string[] Strides = { "walk", "walk_brisk", "jog", "run", "sprint" };

        [MenuItem("Legends/Players/Build the animator")]
        public static RuntimeAnimatorController Build()
        {
            var clips = AssetDatabase.LoadAllAssetsAtPath(Clips).OfType<AnimationClip>()
                .Where(c => !c.name.StartsWith("__preview__")).ToDictionary(c => c.name);
            if (!clips.ContainsKey("idle")) { Debug.LogWarning("Legends: no moves yet in " + Clips + ": no animator"); return null; }
            var speeds = new Dictionary<string, float>();
            if (File.Exists(Speeds) && MiniJson.Parse(File.ReadAllText(Speeds)) is Dictionary<string, object> table)
                foreach (var kv in table)
                    if (kv.Value is Dictionary<string, object> row) speeds[kv.Key] = System.Convert.ToSingle(row["speed"]);

            AssetDatabase.DeleteAsset(Path);
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(Path));
            var ctrl = AnimatorController.CreateAnimatorControllerAtPath(Path);
            ctrl.AddParameter("Speed", AnimatorControllerParameterType.Float);
            ctrl.AddParameter(new AnimatorControllerParameter { name = "Pace", type = AnimatorControllerParameterType.Float, defaultFloat = 1f });
            var machine = ctrl.layers[0].stateMachine;

            var loco = ctrl.CreateBlendTreeInController(PlayerMotion.Locomotion, out var tree, 0);
            tree.blendType = BlendTreeType.Simple1D;
            tree.blendParameter = "Speed";
            tree.useAutomaticThresholds = false;
            tree.AddChild(clips["idle"], 0f);
            float sprint = 0f;
            foreach (var s in Strides)
            {
                if (!clips.TryGetValue(s, out var clip) || !speeds.TryGetValue(s, out var at)) continue;
                tree.AddChild(clip, at);
                sprint = at;
            }
            loco.speedParameterActive = true;
            loco.speedParameter = "Pace";
            machine.defaultState = loco;

            foreach (var kv in clips.OrderBy(k => k.Key))
            {
                if (kv.Key == "idle" || Strides.Contains(kv.Key)) continue;
                var state = machine.AddState(kv.Key);
                state.motion = kv.Value;
            }
            EditorUtility.SetDirty(ctrl);
            AssetDatabase.SaveAssets();
            Debug.Log($"Legends: animator with {tree.children.Length} strides (to {sprint:0.00} m/s) and {machine.states.Length - 1} moves");
            return ctrl;
        }
    }
}
