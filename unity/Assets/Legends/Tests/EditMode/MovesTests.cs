using System.Linq;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 07 U3] The moves we keyframe ourselves (tools/unity/players/keyframes.py, Animation/Moves/moves.fbx):
    /// every one is a Humanoid clip of its length, the right ones loop, and they move the body as written on any build:
    /// a dive ends on the grass well to the side, the card is held up high.
    /// </summary>
    public sealed class MovesTests
    {
        const string Clips = "Assets/Legends/Animation/Moves/moves.fbx";
        static readonly (string name, float length)[] Expected =
        {
            ("idle", 2.0f), ("keeper_ready", 2.0f), ("keeper_catch", 1.1f), ("keeper_punch", 0.85f),
            ("keeper_dive_l_high", 1.6f), ("keeper_dive_l_low", 1.4f), ("keeper_dive_r_high", 1.6f), ("keeper_dive_r_low", 1.4f),
            ("celebrate_wings", 1.95f), ("celebrate_fist", 2.0f), ("celebrate_knee_slide", 2.0f),
            ("despair_hands_head", 2.0f), ("protest", 1.4f), ("walk_off_sad", 2.0f),
            ("ref_card", 1.8f), ("ref_point_spot", 1.5f), ("ref_whistle_free_kick", 1.6f), ("assistant_flag_up", 1.6f),
        };

        static readonly string[] Loops = { "idle", "keeper_ready", "celebrate_wings" };

        static AnimationClip Clip(string name) =>
            AssetDatabase.LoadAllAssetsAtPath(Clips).OfType<AnimationClip>().FirstOrDefault(c => c.name == name);

        [Test]
        public void EveryMoveIsAHumanoidClipOfItsLength()
        {
            foreach (var (name, length) in Expected)
            {
                var clip = Clip(name);
                Assert.NotNull(clip, name + " in " + Clips);
                Assert.IsTrue(clip.humanMotion, name + " plays through the avatar, on every build");
                Assert.AreEqual(length, clip.length, 0.05f, name + "'s length");
                Assert.AreEqual(Loops.Contains(name), clip.isLooping, name + " loops or holds (Editor/PlayerImport.Looping)");
            }
        }

        /// <summary>Where a player's bone is at time t of a move (the player stands at the origin, facing +Z).</summary>
        static Vector3 BoneAt(int build, string move, float t, HumanBodyBones bone)
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>("Assets/Legends/Resources/PlayerArt.asset");
            var look = PlayerLook.From("4242");
            look.Build = build;
            var p = art.Spawn(look, null, KitColours.Of(Color.red, Color.white, "plain"), 9);
            try
            {
                AnimationMode.StartAnimationMode();
                AnimationMode.BeginSampling();
                AnimationMode.SampleAnimationClip(p.gameObject, Clip(move), t);
                AnimationMode.EndSampling();
                return p.GetComponent<Animator>().GetBoneTransform(bone).position;
            }
            finally
            {
                AnimationMode.StopAnimationMode();
                Object.DestroyImmediate(p.gameObject);
            }
        }

        [Test]
        public void ADiveEndsOnTheGrassToHisSideOnEveryBuild()
        {
            for (int build = 0; build < PlayerLook.Builds.Length; build++)
            {
                var start = BoneAt(build, "keeper_dive_l_high", 0f, HumanBodyBones.Hips);
                var end = BoneAt(build, "keeper_dive_l_high", 1.6f, HumanBodyBones.Hips);
                Assert.Greater(start.y, 0.75f, PlayerLook.Builds[build] + ": standing at the start");
                Assert.Less(end.y, 0.35f, PlayerLook.Builds[build] + ": on the grass at the end");
                // facing +Z, his left is -X in Unity (Blender's +X, mirrored by the FBX axes)
                Assert.Greater(Mathf.Abs(end.x - start.x), 1.4f, PlayerLook.Builds[build] + ": well to his side");
                var right = BoneAt(build, "keeper_dive_r_high", 1.6f, HumanBodyBones.Hips);
                Assert.Less(Mathf.Sign(end.x - start.x) * Mathf.Sign(right.x - start.x), 0f, "the left and right dives go opposite ways");
            }
        }

        [Test]
        public void TheRefereeHoldsTheCardHighAndTheKneeSlideIsOnHisKnees()
        {
            var hand = BoneAt(1, "ref_card", 1.8f, HumanBodyBones.RightHand);
            var head = BoneAt(1, "ref_card", 1.8f, HumanBodyBones.Head);
            Assert.Greater(hand.y, head.y + 0.25f, "the card above his head");
            var hips = BoneAt(1, "celebrate_knee_slide", 1.3f, HumanBodyBones.Hips);
            Assert.Less(hips.y, 0.75f, "down on his knees");
        }
    }
}
