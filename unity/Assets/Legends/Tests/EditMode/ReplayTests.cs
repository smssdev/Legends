using System.Linq;
using NUnit.Framework;
using UnityEngine;
using Legends.Shots;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 09 U3 and U4] A goal's replay and the scoreboard, from the minute's plan alone: in the replay window the
    /// frames go through the scene again from the plan's offset at its slow rate, the moves slow by the same ratio, and
    /// it is filmed from behind the goal then from the far side; the clock stands still through the scene and the score
    /// turns only when the ball is in the net.
    /// </summary>
    public sealed class ReplayTests
    {
        static readonly MinutePlan.Ctx High = new MinutePlan.Ctx { Tier = MinutePlan.Tier.High, Seed = 48213 };

        static MinutePlan.Story Goal(string side = "home") => new MinutePlan.Story { Scene = "goal", Side = side, Goal = true };

        [Test]
        public void TheReplayPlaysTheSceneAgainSlowed()
        {
            var p = MinutePlan.Of(Goal(), 20, null, 20000, High);
            Assert.NotNull(p.Replay, "a goal at 20 s has its replay");
            double nominal = p.SceneT * p.Rate;
            // live: the frames through the scene's time, then held at its end through the cutaways
            Assert.AreEqual(0.5f, MatchScene.FramesAt(p, p.SceneT / 2), 1e-4f);
            Assert.AreEqual(1f, MatchScene.FramesAt(p, p.SceneT + 0.1), 1e-6f);
            Assert.AreEqual(1f, MatchScene.FramesAt(p, p.Replay.At - 0.01), 1e-6f);
            Assert.IsFalse(MatchScene.InReplay(p, p.Replay.At - 0.01));
            // the replay: from Off into the scene, at Rate
            Assert.IsTrue(MatchScene.InReplay(p, p.Replay.At));
            Assert.AreEqual((float)(p.Replay.Off / nominal), MatchScene.FramesAt(p, p.Replay.At), 1e-4f);
            Assert.AreEqual((float)((p.Replay.Off + p.Replay.Rate) / nominal), MatchScene.FramesAt(p, p.Replay.At + 1), 1e-4f);
            // the last 0.8 s: the ball in the net again, live
            Assert.IsFalse(MatchScene.InReplay(p, p.Total - 0.5));
            Assert.AreEqual(1f, MatchScene.FramesAt(p, p.Total - 0.5), 1e-6f);
        }

        [Test]
        public void TheReplayReachesTheBallInTheNet()
        {
            foreach (var ms in new[] { 9000, 14000, 20000 })
            {
                var p = MinutePlan.Of(Goal("away"), 33, null, ms, High);
                if (p.Replay == null) continue;
                float end = MatchScene.FramesAt(p, p.Total - 0.8 - 1e-6);
                Assert.Greater(end, 0.97f, ms + " ms: the replay ends on the goal");
            }
        }

        [Test]
        public void TheMovesSlowAsTheFramesDo()
        {
            var p = MinutePlan.Of(Goal(), 20, null, 20000, High);
            float slow = MatchScene.Slowness(p, p.Replay.At + 0.5);
            Assert.Less(slow, 1f, "slower than live");
            Assert.Greater(slow, 0f);
            // the frames' pace in the replay over their pace live
            double live = 1 / p.SceneT, replay = p.Replay.Rate / (p.SceneT * p.Rate);
            Assert.AreEqual((float)(replay / live), slow, 1e-4f);
            Assert.AreEqual(1f, MatchScene.Slowness(p, 1), "live outside the replay");
            Assert.AreEqual(1f, MatchScene.Slowness(MinutePlan.Of(new MinutePlan.Story { Scene = "save", Side = "home" }, 5, null, 20000, High), 10));
        }

        [Test]
        public void TheReplayIsFilmedFromTwoSides()
        {
            var p = MinutePlan.Of(Goal(), 20, null, 20000, High);
            var shot = ShotList.All(p, Goal()).Single(s => s.Name == ShotList.Replay);
            Assert.AreEqual(ShotList.ReplayGoal, ShotList.ReplayAngle(shot, shot.From));
            Assert.AreEqual(ShotList.ReplaySide, ShotList.ReplayAngle(shot, shot.To - 0.01));
            Assert.IsNull(ShotList.ReplayAngle(ShotList.At(p, Goal(), 0.1), 0.1), "no replay angle on the scene");
            Assert.Contains(ShotList.ReplayGoal, Director.Kinds);
            Assert.Contains(ShotList.ReplaySide, Director.Kinds);
        }

        [Test]
        public void ASetPieceKeepsItsCloseShotOnTheStrike()
        {
            foreach (var scene in new[] { "penalty", "freekick" })
            {
                var s = new MinutePlan.Story { Scene = scene, Side = "home" };
                var p = MinutePlan.Of(s, 12, null, 20000, High);
                var names = ShotList.All(p, s).Where(x => x.From < p.SceneT).Select(x => x.Name).ToList();
                CollectionAssert.AreEqual(new[] { ShotList.Spot, ShotList.Close, ShotList.Spot }, names, scene);
            }
            var trap = new MinutePlan.Story { Scene = "trap", Side = "home" };
            Assert.AreEqual(ShotList.Line, ShotList.At(MinutePlan.Of(trap, 12, null, 9000, High), trap, 1).Name, "the trap on its line throughout");
        }

        [Test]
        public void TheCloseShotsGoRoundWhoeverStandsInTheWay()
        {
            var target = new Vector3(10f, 0f, 5f);
            var preferred = target + new Vector3(2.2f, 1.7f, -5f);
            var none = new System.Collections.Generic.List<Vector3> { new Vector3(-20f, 0, 0) };
            Assert.AreEqual(preferred, Director.Clear(target, preferred, none), "a clear line: the preferred place");
            var blocker = new System.Collections.Generic.List<Vector3> { Vector3.Lerp(preferred, target, 0.5f) };
            var at = Director.Clear(target, preferred, blocker);
            Assert.AreNotEqual(preferred, at, "someone in the way: another side");
            Assert.AreEqual(Vector2.Distance(new Vector2(preferred.x, preferred.z), new Vector2(target.x, target.z)),
                Vector2.Distance(new Vector2(at.x, at.z), new Vector2(target.x, target.z)), 1e-3f, "at the same distance");
            Assert.AreEqual(preferred.y, at.y, 1e-4f, "and height");
            Assert.AreEqual(at, Director.Clear(target, preferred, blocker), "the same angle every time");
            // by the near touchline it never goes behind the boards
            var byLine = new Vector3(0, 0, -33f);
            var far = Director.Clear(byLine, byLine + new Vector3(2.6f, 1.4f, 3.6f), new System.Collections.Generic.List<Vector3> { byLine + new Vector3(1.3f, 0, 1.8f) });
            Assert.Greater(far.z, -36f);
        }

        static MatchMinute Minute(int home, int away, MinutePlan.Story s) =>
            new MatchMinute { Tick = 20, Minute = 20, HomeGoals = home, AwayGoals = away, Ms = 20000, Story = s };

        [Test]
        public void TheScoreTurnsWhenTheBallIsInTheNet()
        {
            var m = Minute(2, 1, Goal("away"));
            var p = MinutePlan.Of(m.Story, m.Tick, null, m.Ms, High);
            double key = ShotList.KeyAt(p, m.Story);
            Assert.AreEqual((2, 0), Scoreboard.Shown(m, p, key - 0.1, null), "before the goal: the score before it");
            Assert.AreEqual((2, 1), Scoreboard.Shown(m, p, key, null), "the ball in the net");
            Assert.AreEqual((2, 0), Scoreboard.Shown(m, p, 1.5, 2.0), "the strike in the frames decides when");
            Assert.AreEqual((2, 1), Scoreboard.Shown(m, p, 2.0, 2.0));
            var quiet = Minute(2, 1, new MinutePlan.Story());
            Assert.AreEqual((2, 1), Scoreboard.Shown(quiet, MinutePlan.Of(quiet.Story, 20, null, 3000, High), 0, null));
        }

        [Test]
        public void TheClockStandsStillThroughTheScene()
        {
            var m = Minute(1, 0, Goal());
            var p = MinutePlan.Of(m.Story, m.Tick, null, m.Ms, High);
            var during = Scoreboard.At(m, p, p.SceneT / 2, null);
            var later = Scoreboard.At(m, p, p.SceneT * 0.9, null);
            Assert.IsTrue(during.frozen);
            Assert.AreEqual(during.clock, later.clock, "the same second through the scene");
            Assert.AreEqual(MinutePlan.Clock(20, 0, 20, p.SceneT / 2 / p.Total, p).Text, during.clock, "the cartoon's clock");
            Assert.IsTrue(during.clock.StartsWith("19:"), during.clock);
            Assert.IsFalse(Scoreboard.At(m, p, p.Total - 0.1, null).frozen, "running again at the end");
        }
    }
}
