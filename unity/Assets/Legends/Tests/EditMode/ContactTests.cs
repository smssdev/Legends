using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 07 U5] The touch on the ball (BallContact): a kick's foot finds the ball at its contact even when the ball
    /// is a hand's breadth off where the move alone would strike (the sprint's test: the ball leaves his foot, less than
    /// 30 cm away), the keeper's hands find it in a dive, and the head turns to it.
    /// </summary>
    public sealed class ContactTests
    {
        const string ArtPath = "Assets/Legends/Resources/PlayerArt.asset";

        /// <summary>A player in move at t seconds through the controller, with a ball at ball (or none); the bones then.</summary>
        static (Vector3 foot, Vector3 toes, Vector3 hands, Vector3 head, Quaternion headTurn) Pose(string move, float t, Vector3? ball, bool keeper = false, bool left = false)
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            var look = PlayerLook.From("4242");
            look.Build = 0;
            var p = art.Spawn(look, null, KitColours.Of(Color.red, Color.white, "plain"), keeper ? 1 : 9, keeper);
            GameObject sphere = null;
            try
            {
                var animator = p.GetComponent<Animator>();
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
                var touch = p.GetComponent<BallContact>();
                Assert.NotNull(touch, "every player has his BallContact");
                if (ball != null)
                {
                    sphere = new GameObject("Ball");
                    sphere.transform.position = ball.Value;
                    touch.Ball = sphere.transform;
                }
                animator.Rebind();
                animator.Update(0f);
                animator.Play(move, 0, 0f);
                const float dt = 1f / 60f;
                animator.Update(0f);
                for (float s = 0; s < t - 1e-4f; s += dt) animator.Update(Mathf.Min(dt, t - s));
                var foot = animator.GetBoneTransform(left ? HumanBodyBones.LeftFoot : HumanBodyBones.RightFoot).position;
                var toes = animator.GetBoneTransform(left ? HumanBodyBones.LeftToes : HumanBodyBones.RightToes).position;
                var hands = (animator.GetBoneTransform(HumanBodyBones.LeftHand).position + animator.GetBoneTransform(HumanBodyBones.RightHand).position) / 2f;
                var head = animator.GetBoneTransform(HumanBodyBones.Head);
                return (foot, toes, hands, head.position, head.rotation);
            }
            finally
            {
                Object.DestroyImmediate(p.gameObject);
                if (sphere != null) Object.DestroyImmediate(sphere);
            }
        }

        static float ContactOf(string move)
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            foreach (var x in art.touches) if (x.move == move) return x.contact;
            Assert.Fail(move + " has no contact in PlayerArt.touches");
            return 0f;
        }

        [Test]
        public void EveryKickFindsTheBallAtItsContactEvenWhenItIsOffItsLine()
        {
            foreach (var move in new[] { "pass", "shot", "shot_power", "pass_l", "shot_l", "shot_power_l", "slide_tackle", "slide_tackle_l" })
            {
                bool left = move.EndsWith("_l");
                float t = ContactOf(move);
                var alone = Pose(move, t, null, left: left);
                // the ball 20 cm to his side and 15 cm further ahead than the move alone would strike
                var ball = alone.toes + new Vector3(left ? -0.2f : 0.2f, 0f, 0.15f);
                ball.y = MatchScene.BallRadius;
                var met = Pose(move, t, ball, left: left);
                float before = Vector3.Distance(alone.foot, ball), after = Vector3.Distance(met.foot, ball);
                Assert.Less(after, 0.3f, $"{move}: the foot at the ball at the contact (was {before:0.00} m, now {after:0.00} m)");
                Assert.Less(after, before, move + ": nearer the ball than the move alone");
                Assert.Less(Vector3.Distance(met.toes, ball), 0.3f, move + ": the toes at the ball");
            }
        }

        [Test]
        public void TheKeepersHandsFindTheBallInADive()
        {
            foreach (var move in new[] { "keeper_dive_l_high", "keeper_dive_r_low", "keeper_catch" })
            {
                float t = ContactOf(move);
                var alone = Pose(move, t, null, keeper: true);
                var ball = alone.hands + new Vector3(0.15f, 0.25f, 0.2f);
                var met = Pose(move, t, ball, keeper: true);
                // at full stretch the arms reach no further: the dive itself must go to the ball (U6 picks it), the hands
                // close the rest, to within the sprint's 30 cm
                float before = Vector3.Distance(alone.hands, ball), after = Vector3.Distance(met.hands, ball);
                Assert.Less(after, 0.3f, $"{move}: the hands at the ball (alone {before:0.00} m off, now {after:0.00} m)");
                Assert.Less(after, before - 0.08f, move + ": the hands went to the ball");
            }
        }

        [Test]
        public void TheHeadTurnsToTheBall()
        {
            // standing, a ball high to his left: his head turns that way
            var ahead = Pose("idle", 0.5f, null);
            var ball = ahead.head + new Vector3(-3f, 1.5f, 2f);
            var turned = Pose("idle", 0.5f, ball);
            Assert.Greater(Quaternion.Angle(ahead.headTurn, turned.headTurn), 10f, "his head turned at least 10 degrees to the ball");
            // and towards it: the head's turn brings it to face nearer the ball than before
            var away = Pose("idle", 0.5f, ahead.head + new Vector3(3f, 1.5f, 2f));
            Assert.Greater(Quaternion.Angle(turned.headTurn, away.headTurn), 20f, "a ball to his right turns it the other way");
        }
    }
}
