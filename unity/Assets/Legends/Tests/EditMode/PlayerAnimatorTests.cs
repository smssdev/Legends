using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 07 U4] Animation/Player.controller (made by `build.ps1 players`): standing and the five strides blended by
    /// Speed at their own speeds (locomotion.json), so the feet keep to the grass; a state for every one-off move; and
    /// every player the art spawns carries it.
    /// </summary>
    public sealed class PlayerAnimatorTests
    {
        [Test]
        public void LocomotionBlendsTheStridesAtTheirOwnSpeeds()
        {
            var ctrl = AssetDatabase.LoadAssetAtPath<AnimatorController>("Assets/Legends/Animation/Player.controller");
            Assert.NotNull(ctrl, "build.ps1 players makes it");
            var machine = ctrl.layers[0].stateMachine;
            Assert.AreEqual(PlayerMotion.Locomotion, machine.defaultState.name);
            var tree = machine.defaultState.motion as BlendTree;
            Assert.NotNull(tree);
            Assert.AreEqual("Speed", tree.blendParameter);
            Assert.AreEqual("Pace", machine.defaultState.speedParameter);
            var table = (Dictionary<string, object>)MiniJson.Parse(System.IO.File.ReadAllText("Assets/Legends/Animation/Moves/locomotion.json"));
            var children = tree.children;
            Assert.AreEqual("idle", children[0].motion.name);
            Assert.AreEqual(0f, children[0].threshold);
            var names = new[] { "walk", "walk_brisk", "jog", "run", "sprint" };
            Assert.AreEqual(names.Length + 1, children.Length);
            for (int i = 0; i < names.Length; i++)
            {
                Assert.AreEqual(names[i], children[i + 1].motion.name);
                float speed = System.Convert.ToSingle(((Dictionary<string, object>)table[names[i]])["speed"]);
                Assert.AreEqual(speed, children[i + 1].threshold, 1e-3f, names[i] + " at its own speed");
            }
        }

        [Test]
        public void EveryOneOffMoveHasItsStateAndEveryPlayerTheAnimator()
        {
            var ctrl = AssetDatabase.LoadAssetAtPath<AnimatorController>("Assets/Legends/Animation/Player.controller");
            var states = ctrl.layers[0].stateMachine.states.Select(s => s.state.name).ToList();
            foreach (var move in new[] { "keeper_dive_l_high", "keeper_dive_r_low", "keeper_catch", "celebrate_knee_slide", "ref_card", "assistant_flag_up" })
                Assert.Contains(move, states);
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>("Assets/Legends/Resources/PlayerArt.asset");
            Assert.AreEqual(ctrl, art.controller);
            var p = art.Spawn(PlayerLook.From("31"), null, KitColours.Of(Color.red, Color.white, "plain"), 7);
            try
            {
                Assert.AreEqual(ctrl, p.GetComponent<Animator>().runtimeAnimatorController);
                Assert.NotNull(p.GetComponent<PlayerMotion>());
            }
            finally { Object.DestroyImmediate(p.gameObject); }
        }
    }
}
