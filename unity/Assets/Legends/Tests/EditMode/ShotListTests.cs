using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using Legends.Shots;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 09 U1] Which shot is on air (ShotList) from the minute's plan: the broadcast camera on the scene with the
    /// close shot at its key moment, then the director's cutaways at exactly the cartoon's seconds, then the replay
    /// window; the shots follow each other with no gap from the first second to the last, the same for every screen.
    /// </summary>
    public sealed class ShotListTests
    {
        static readonly MinutePlan.Ctx High = new MinutePlan.Ctx { Tier = MinutePlan.Tier.High, Seed = 48213 };

        static MinutePlan.Story Goal() => new MinutePlan.Story { Scene = "goal", Side = "home", Goal = true };

        [Test]
        public void AGoalIsTheSceneThenTheCloseShotThenTheCutawaysThenTheReplay()
        {
            var p = MinutePlan.Of(Goal(), 20, null, 20000, High);
            var shots = ShotList.All(p, Goal());
            Assert.AreEqual("broadcast,close,broadcast,crowd,coachReact,coachReact,broadcast,replay,broadcast", string.Join(",", shots.Select(s => s.Name)), string.Join(" | ", shots));
            var close = shots[1];
            Assert.AreEqual(ShotList.KeyAt(p, Goal()) - ShotList.Before, close.From, 1e-9, "the close shot comes in before the strike");
            Assert.AreEqual(p.SceneT, shots[3].From, 1e-9, "the cutaways start as the scene ends");
            Assert.AreEqual(p.Replay.At, shots[7].From, 1e-9, "the replay at the plan's second");
        }

        [Test]
        public void TheShotsCoverTheMinuteWithNoGap()
        {
            foreach (var scene in MinutePlan.SceneTime.Keys)
                foreach (var ms in new[] { 3300, 9000, 20000 })
                {
                    var s = new MinutePlan.Story { Scene = scene, Side = "away", Goal = scene == "goal" };
                    var p = MinutePlan.Of(s, 7, null, ms, High);
                    var shots = ShotList.All(p, s);
                    Assert.AreEqual(0, shots[0].From, 1e-9, scene);
                    for (int i = 1; i < shots.Count; i++) Assert.AreEqual(shots[i - 1].To, shots[i].From, 1e-9, $"{scene} {ms}: {string.Join(" | ", shots)}");
                    Assert.AreEqual(p.Total, shots[shots.Count - 1].To, 1e-9, scene + " to the minute's end");
                    // the cutaways are the plan's, in its order
                    var cuts = shots.Where(x => x.From >= p.SceneT - 1e-9 && x.Name != ShotList.Broadcast && x.Name != ShotList.Replay).Select(x => x.Name);
                    CollectionAssert.AreEqual(p.Cuts.Select(c => c.Name).ToList(), cuts.ToList(), scene);
                }
        }

        [Test]
        public void AQuietMinuteIsTheBroadcastCameraThroughout()
        {
            var quiet = new MinutePlan.Story();
            var p = MinutePlan.Of(quiet, 3, null, 3000, High);
            Assert.AreEqual(ShotList.Broadcast, ShotList.At(p, quiet, 0).Name);
            Assert.AreEqual(ShotList.Broadcast, ShotList.At(p, quiet, 2.9).Name);
            Assert.AreEqual(1, ShotList.All(p, quiet).Count);
        }

        [Test]
        public void EveryShotOfTheSampleHasACamera()
        {
            var path = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "liverpool-arsenal-48213.json"));
            var ticks = MiniJson.Arr(MiniJson.Parse(File.ReadAllText(path)), "ticks");
            int stories = 0;
            foreach (var t in ticks)
            {
                var m = MatchMinute.From(t, 3000);
                if (m.Story.Scene != null) stories++;
                foreach (var shot in ShotList.All(MinutePlan.Of(m.Story, m.Tick, null, m.Ms, High), m.Story))
                    Assert.IsTrue(Director.Kinds.Contains(shot.Name) || shot.Name == ShotList.Replay, $"tick {m.Tick}: {shot.Name} has a camera");
            }
            Assert.Greater(stories, 10, "the sample's minutes carry the server's story (sim:golden --write)");
        }
    }
}
