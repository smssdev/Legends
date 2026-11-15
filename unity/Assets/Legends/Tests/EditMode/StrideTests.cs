using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 07 U4] The stride follows the speed: Gait picks the blend and the pace, the controller blends the five
    /// strides by their own speeds, and a player running through it at a steady speed keeps his planted foot still on the
    /// grass (the sprint's test: a foot slides less than 10 cm a second).
    /// </summary>
    public sealed class StrideTests
    {
        const string ArtPath = "Assets/Legends/Resources/PlayerArt.asset";

        [Test]
        public void TheStridesAreTheOnesInLocomotionJson()
        {
            var table = (Dictionary<string, object>)MiniJson.Parse(System.IO.File.ReadAllText("Assets/Legends/Animation/Moves/locomotion.json"));
            foreach (var (clip, speed) in Gait.Strides)
                Assert.AreEqual(System.Convert.ToSingle(((Dictionary<string, object>)table[clip])["speed"]), speed, 0.002f, clip);
        }

        [Test]
        public void GaitStandsWalksRunsAndSpeedsUpTheSprintToItsLimit()
        {
            Assert.AreEqual(0f, Gait.Blend(0.1f), "standing");
            Assert.AreEqual(1f, Gait.Pace(0.1f));
            Assert.AreEqual(Gait.Walk, Gait.Blend(0.8f), "a slow walk is the walk...");
            Assert.AreEqual(0.8f / Gait.Walk, Gait.Pace(0.8f), 1e-4f, "...played slower");
            Assert.AreEqual(3f, Gait.Blend(3f), "between the walk and the sprint the blend is the speed");
            Assert.AreEqual(1f, Gait.Pace(3f), 1e-4f, "at its own pace");
            Assert.AreEqual(Gait.Sprint, Gait.Blend(7f), "faster than the sprint is the sprint...");
            Assert.AreEqual(7f / Gait.Sprint, Gait.Pace(7f), 1e-4f, "...played faster");
            Assert.AreEqual(Gait.MaxPace, Gait.Pace(40f), "a fast-forward minute: no faster than MaxPace");
        }

        [Test]
        public void TheControllerBlendsTheStridesByTheirSpeedsAndHasEveryMove()
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            Assert.NotNull(art.motion, "PlayerArt.motion (Legends > Players > Build the animator)");
            var controller = (AnimatorController)art.motion;
            var states = controller.layers[0].stateMachine.states.Select(s => s.state).ToList();
            var locomotion = states.First(s => s.name == PlayerStride.Locomotion);
            Assert.AreEqual(locomotion, controller.layers[0].stateMachine.defaultState, "he starts on his stride");
            Assert.IsTrue(locomotion.speedParameterActive && locomotion.speedParameter == "Pace", "the stride plays at Pace");
            var tree = (BlendTree)locomotion.motion;
            Assert.AreEqual("Speed", tree.blendParameter);
            Assert.AreEqual(0f, tree.children[0].threshold, "standing at 0");
            for (int i = 0; i < Gait.Strides.Length; i++)
            {
                Assert.AreEqual(Gait.Strides[i].clip, tree.children[i + 1].motion.name);
                Assert.AreEqual(Gait.Strides[i].speed, tree.children[i + 1].threshold, 0.002f, Gait.Strides[i].clip + " at its own speed");
            }
            foreach (var move in new[] { "pass", "shot_power_l", "header", "slide_tackle", "fall", "keeper_dive_r_low", "celebrate_wings", "turn_l", "stop" })
                Assert.IsTrue(states.Any(s => s.name == move), move + " is a state");
            var pass = states.First(s => s.name == "pass");
            Assert.IsTrue(pass.transitions.Any(t => t.destinationState == locomotion && t.hasExitTime), "a pass hands back to the stride");
            Assert.IsEmpty(states.First(s => s.name == "fall").transitions, "a fall stays on the grass");
        }

        /// <summary>A player running at speed through the controller; each frame where each foot is (the scene's metres).</summary>
        static List<(Vector3 l, Vector3 r)> Run(float speed, int build, float seconds = 3f, float dt = 1f / 60f)
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            var look = PlayerLook.From("4242");
            look.Build = build;
            var p = art.Spawn(look, null, KitColours.Of(Color.red, Color.white, "plain"), 9);
            var feet = new List<(Vector3, Vector3)>();
            try
            {
                var animator = p.GetComponent<Animator>();
                animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
                var stride = p.GetComponent<PlayerStride>();
                Assert.NotNull(stride, "every player has his PlayerStride");
                animator.Rebind();
                for (float t = 0; t < seconds; t += dt)
                {
                    p.transform.position += Vector3.forward * speed * dt;
                    stride.Go(speed, dt, true);
                    animator.Update(dt);
                    if (t > 1f)     // settled into the stride
                        feet.Add((animator.GetBoneTransform(HumanBodyBones.LeftToes).position, animator.GetBoneTransform(HumanBodyBones.RightToes).position));
                }
            }
            finally
            {
                Object.DestroyImmediate(p.gameObject);
            }
            return feet;
        }

        /// <summary>
        /// How a planted foot moves on the grass (m/s along his way, the mean over the frames each foot is down: within 2 cm
        /// of its lowest). On a real stride it is still while the body goes over it: ahead (+) when the stride is too short
        /// for his speed, back (-) when too long.
        /// </summary>
        static float Slide(List<(Vector3 l, Vector3 r)> feet, float dt = 1f / 60f)
        {
            float sum = 0f;
            int n = 0;
            foreach (var pick in new System.Func<(Vector3 l, Vector3 r), Vector3>[] { f => f.l, f => f.r })
            {
                var path = feet.Select(pick).ToList();
                float low = path.Min(v => v.y);
                for (int i = 1; i < path.Count; i++)
                {
                    if (path[i].y > low + 0.02f || path[i - 1].y > low + 0.02f) continue;
                    sum += (path[i].z - path[i - 1].z) / dt;
                    n++;
                }
            }
            Assert.Greater(n, 10, "his feet come down");
            return sum / n;
        }

        [Test]
        public void APlantedFootStaysOnTheGrassAtEverySpeedOfTheStrides()
        {
            var report = new List<string>();
            float worst = 0f;
            foreach (var speed in new[] { 1.2f, Gait.Walk, 2.6f, Gait.Strides[3].speed, Gait.Sprint, 6f })
                for (int build = 0; build < PlayerLook.Builds.Length; build++)
                {
                    float slide = Slide(Run(speed, build));
                    report.Add($"{speed:0.0} m/s {PlayerLook.Builds[build]}: {slide * 100:+0;-0} cm/s");
                    worst = Mathf.Max(worst, Mathf.Abs(slide));
                }
            Debug.Log("Legends: foot slide " + string.Join(", ", report));
            Assert.Less(worst, 0.10f, string.Join(", ", report));
        }
    }
}
