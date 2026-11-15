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
            ("header", 1.3f), ("slide_tackle", 1.7f), ("slide_tackle_l", 1.7f), ("fall", 2.0f),
        };

        static readonly string[] Loops = { "idle", "keeper_ready", "celebrate_wings", "walk", "walk_brisk", "jog", "run", "sprint" };

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

        /// <summary>[U1] The strides from motion capture (mocap.py): their lengths as locomotion.json says, and their speeds in order.</summary>
        [Test]
        public void TheStridesAreThereWithTheirLengthsAndSpeeds()
        {
            var json = System.IO.File.ReadAllText("Assets/Legends/Animation/Moves/locomotion.json");
            var table = MiniJson.Parse(json) as System.Collections.Generic.Dictionary<string, object>;
            Assert.NotNull(table, "locomotion.json");
            float last = 0f;
            foreach (var name in new[] { "walk", "walk_brisk", "jog", "run", "sprint" })
            {
                var row = table[name] as System.Collections.Generic.Dictionary<string, object>;
                var clip = Clip(name);
                Assert.NotNull(clip, name);
                Assert.IsTrue(clip.isLooping && clip.humanMotion, name + " loops through the avatar");
                Assert.AreEqual(System.Convert.ToSingle(row["seconds"]), clip.length, 0.04f, name + "'s stride");
                float speed = System.Convert.ToSingle(row["speed"]);
                Assert.Greater(speed, last, name + " faster than the one before");
                last = speed;
            }
            Assert.That(last, Is.InRange(4f, 6f), "the sprint");
        }

        [Test]
        public void AStrideEndsWhereItStartsSoItLoopsWithoutASeam()
        {
            foreach (var name in new[] { "walk", "jog", "run" })
            {
                float end = Clip(name).length;
                foreach (var bone in new[] { HumanBodyBones.Hips, HumanBodyBones.LeftFoot, HumanBodyBones.RightHand })
                {
                    var a = BoneAt(1, name, 0f, bone);
                    var b = BoneAt(1, name, end, bone);
                    Assert.Less(Vector3.Distance(a, b), 0.04f, $"{name}: the {bone} at its end as at its start");
                }
                Assert.That(BoneAt(1, name, end * 0.5f, HumanBodyBones.Hips).y, Is.InRange(0.8f, 1.15f), name + ": upright");
            }
        }

        /// <summary>
        /// [U2] The moves that play once from motion capture (mocap.TAKES): each a clip of the length takes.json says,
        /// none loops, and a kick meets the ball at its contact: the kicking foot swinging fast, low and level with the
        /// foot he stands on (the ball beside it). The left-footed twins kick with the left.
        /// </summary>
        [Test]
        public void TheKicksMeetTheBallAtTheirContactWithTheRightFoot()
        {
            var table = MiniJson.Parse(System.IO.File.ReadAllText("Assets/Legends/Animation/Moves/takes.json")) as System.Collections.Generic.Dictionary<string, object>;
            Assert.NotNull(table, "takes.json");
            foreach (var name in new[] { "pass", "shot", "shot_power", "stop", "turn_l", "turn_r", "pass_l", "shot_l", "shot_power_l" })
            {
                var row = table[name] as System.Collections.Generic.Dictionary<string, object>;
                var clip = Clip(name);
                Assert.NotNull(clip, name);
                Assert.IsFalse(clip.isLooping, name + " plays once");
                Assert.AreEqual(System.Convert.ToSingle(row["seconds"]), clip.length, 0.04f, name + "'s length");
                if (!row.ContainsKey("contact")) continue;
                float t = System.Convert.ToSingle(row["contact"]);
                bool left = (string)row["foot"] == "left";
                Assert.AreEqual(name.EndsWith("_l"), left, name + "'s kicking foot");
                var kick = left ? HumanBodyBones.LeftToes : HumanBodyBones.RightToes;
                var stand = left ? HumanBodyBones.RightFoot : HumanBodyBones.LeftFoot;
                // the ball beside the foot he stands on: the kicking toes low and level with it there
                var foot = BoneAt(1, name, t, kick);
                Assert.Less(foot.y, 0.3f, name + ": the kicking foot down at the ball at the contact");
                Assert.That(foot.z - BoneAt(1, name, t, stand).z, Is.InRange(-0.15f, 0.35f), name + ": level with the foot he stands on");
                float swing = Vector3.Distance(BoneAt(1, name, t - 0.05f, kick), BoneAt(1, name, t + 0.05f, kick)) / 0.1f;
                Assert.Greater(swing, 6f, name + ": the foot swinging fast (m/s) through the ball");
            }
            Assert.That(System.Convert.ToSingle(((System.Collections.Generic.Dictionary<string, object>)table["turn_l"])["turn"]), Is.InRange(45f, 135f), "turn_l turns him to his left");
            Assert.That(System.Convert.ToSingle(((System.Collections.Generic.Dictionary<string, object>)table["turn_r"])["turn"]), Is.InRange(-135f, -45f), "turn_r to his right");
        }

        /// <summary>
        /// [U2] The ball moves we make (keyframes.py): the header meets the ball at its contact well above a standing
        /// man's head, the slide tackle is on the grass with the leg out ahead of him, the fall ends flat on the grass.
        /// </summary>
        [Test]
        public void TheHeaderIsInTheAirTheSlideOnTheGrassAndTheFallFlat()
        {
            var table = MiniJson.Parse(System.IO.File.ReadAllText("Assets/Legends/Animation/Moves/takes.json")) as System.Collections.Generic.Dictionary<string, object>;
            float At(string move) => System.Convert.ToSingle(((System.Collections.Generic.Dictionary<string, object>)table[move])["contact"]);
            float standing = BoneAt(1, "idle", 0f, HumanBodyBones.Head).y;
            Assert.Greater(BoneAt(1, "header", At("header"), HumanBodyBones.Head).y, standing + 0.25f, "the header: up off the ground");
            foreach (var (move, foot) in new[] { ("slide_tackle", HumanBodyBones.RightFoot), ("slide_tackle_l", HumanBodyBones.LeftFoot) })
            {
                var hips = BoneAt(1, move, At(move), HumanBodyBones.Hips);
                Assert.Less(hips.y, 0.45f, move + ": down on the grass");
                Assert.Greater(BoneAt(1, move, At(move), foot).z - hips.z, 0.6f, move + ": the leg out ahead at the ball");
            }
            var fall = Clip("fall");
            Assert.IsFalse(fall.isLooping, "the fall plays once and holds");
            Assert.Less(BoneAt(1, "fall", fall.length, HumanBodyBones.Hips).y, 0.35f, "the fall: flat on the grass");
            Assert.Less(BoneAt(1, "fall", fall.length, HumanBodyBones.Head).y, 0.75f, "his head down too");
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
