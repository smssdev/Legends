using System.Collections.Generic;
using System.IO;
using NUnit.Framework;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// Reading the server's messages (README.md appendix A) and placing them on the pitch (Sprint 2, U7).
    /// `build.ps1 test`, or Window → General → Test Runner → EditMode.
    /// </summary>
    public sealed class FeedTests
    {
        static string SamplePath => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "liverpool-arsenal-48213.json"));

        // ------------------------------------------------------------ MiniJson

        [Test]
        public void MiniJsonReadsEveryKindOfValue()
        {
            var o = MiniJson.Parse("{\"i\": -12, \"d\": 1.5, \"s\": \"a\\\"b\\u0645\", \"t\": true, \"f\": false, \"n\": null, \"a\": [1, [2]], \"o\": {}}") as Dictionary<string, object>;
            Assert.NotNull(o);
            Assert.AreEqual(-12L, o["i"]);
            Assert.AreEqual(1.5, o["d"]);
            Assert.AreEqual("a\"bم", o["s"]);
            Assert.AreEqual(true, o["t"]);
            Assert.AreEqual(false, o["f"]);
            Assert.IsNull(o["n"]);
            var a = (List<object>)o["a"];
            Assert.AreEqual(1L, a[0]);
            Assert.AreEqual(2L, ((List<object>)a[1])[0]);
            Assert.AreEqual(0, ((Dictionary<string, object>)o["o"]).Count);
        }

        [Test]
        public void MiniJsonKeepsArabicText()
        {
            var o = MiniJson.Parse("{\"text\": \"هدف!\"}");
            Assert.AreEqual("هدف!", MiniJson.Str(o, "text"));
        }

        [Test]
        public void MiniJsonRefusesBrokenText()
        {
            Assert.Throws<System.FormatException>(() => MiniJson.Parse("{\"a\": 1} x"));
            Assert.Throws<System.FormatException>(() => MiniJson.Parse("{\"a\" 1}"));
        }

        [Test]
        public void MiniJsonHelpersFallBack()
        {
            var o = MiniJson.Parse("{\"a\": 3}");
            Assert.AreEqual(3, MiniJson.Int(o, "a"));
            Assert.AreEqual(7, MiniJson.Int(o, "missing", 7));
            Assert.AreEqual("x", MiniJson.Str(o, "missing", "x"));
            Assert.IsNull(MiniJson.Obj(o, "a"));
            Assert.IsNull(MiniJson.Arr(null, "a"));
        }

        // ------------------------------------------------------------ the setup and a minute (appendix A)

        const string SetupJson = "{\"clubs\": {\"home\": {\"code\": \"LIV\", \"primary\": \"#C8102E\", \"secondary\": \"#F6C343\"}," +
            " \"away\": {\"code\": \"ARS\", \"primary\": \"#DB0007\", \"secondary\": \"#FFFFFF\"}}, \"tick_ms\": 2500," +
            " \"players\": {\"home\": [{\"id\": 25, \"no\": 1, \"pos\": \"GK\"}, {\"id\": 2, \"no\": 4, \"pos\": \"CB\"}], \"away\": [{\"id\": 181, \"no\": 9, \"pos\": \"ST\"}]}}";

        [Test]
        public void SetupReadsClubsPlayersAndTiming()
        {
            var setup = MatchSetup.From(MiniJson.Parse(SetupJson));
            Assert.AreEqual("LIV", setup.Home.Code);
            Assert.AreEqual("ARS", setup.Away.Code);
            Assert.AreEqual(new Color32(0xC8, 0x10, 0x2E, 0xFF), (Color32)setup.Home.Primary);
            Assert.AreEqual(new Color32(0xFF, 0xFF, 0xFF, 0xFF), (Color32)setup.Away.Secondary);
            Assert.AreEqual(2500, setup.TickMs);
            Assert.AreEqual(3, setup.Players.Count);
            var keeper = setup.Players[0];
            Assert.AreEqual("25", keeper.Id);
            Assert.AreEqual(1, keeper.Number);
            Assert.IsTrue(keeper.Keeper);
            Assert.IsTrue(keeper.Home);
            Assert.IsFalse(setup.Players[1].Keeper);
            Assert.IsFalse(setup.Players[2].Home);
        }

        const string MinuteJson = "{\"tick\": 96, \"period\": 2, \"minute\": [90, 3], \"score\": {\"home\": 2, \"away\": 1}," +
            " \"finished\": true, \"moment\": {\"kind\": \"goal\", \"ms\": 9000}, \"events\": [], \"danger\": 4," +
            " \"frames\": [{\"t\": 0, \"b\": [525, 340, 0], \"p\": {\"25\": [49, 353], \"181\": [515, 401]}, \"h\": 181}," +
            " {\"t\": 1, \"b\": [1040, 340, 12], \"p\": {\"25\": [60, 340]}, \"h\": null}]}";

        [Test]
        public void MinuteReadsEveryFieldTheSceneUses()
        {
            var m = MatchMinute.From(MiniJson.Parse(MinuteJson), 3000);
            Assert.AreEqual(96, m.Tick);
            Assert.AreEqual(2, m.Period);
            Assert.AreEqual(90, m.Minute);
            Assert.AreEqual(3, m.Added);
            Assert.AreEqual(2, m.HomeGoals);
            Assert.AreEqual(1, m.AwayGoals);
            Assert.IsTrue(m.Finished);
            Assert.AreEqual("goal", m.Moment);
            Assert.AreEqual(9000, m.Ms);
            Assert.AreEqual(2, m.Frames.Count);
            Assert.AreEqual(new Vector3(525, 340, 0), m.Frames[0].Ball);
            Assert.AreEqual(new Vector2(515, 401), m.Frames[0].Players["181"]);
            Assert.AreEqual("181", m.Frames[0].Holder);
            Assert.AreEqual(new Vector3(1040, 340, 12), m.Frames[1].Ball);
            Assert.IsFalse(m.Frames[1].Players.ContainsKey("181"));
            Assert.IsNull(m.Frames[1].Holder);
        }

        [Test]
        public void MinuteWithoutAMomentLastsTheTick()
        {
            var m = MatchMinute.From(MiniJson.Parse("{\"tick\": 1, \"minute\": [1, 0], \"frames\": []}"), 3000);
            Assert.AreEqual("quiet", m.Moment);
            Assert.AreEqual(3000, m.Ms);
            Assert.AreEqual(1, m.Period);
            Assert.IsFalse(m.Finished);
            m = MatchMinute.From(MiniJson.Parse("{\"tick\": 1, \"moment\": {\"kind\": \"attack\", \"ms\": 0}}"), 2000);
            Assert.AreEqual(2000, m.Ms);
        }

        // ------------------------------------------------------------ the pitch: decimetres to metres, and the ends

        [Test]
        public void DecimetresBecomeMetresAroundTheCentreSpot()
        {
            Assert.AreEqual(Vector3.zero, MatchScene.World(new Vector2(525, 340), false));
            Assert.AreEqual(new Vector3(-52.5f, 0, 34f), MatchScene.World(new Vector2(0, 0), false));
            Assert.AreEqual(new Vector3(52.5f, 0, -34f), MatchScene.World(new Vector2(1050, 680), false));
            Assert.AreEqual(new Vector3(10f, 0, -5f), MatchScene.World(new Vector2(625, 390), false));
        }

        [Test]
        public void TheEndsChangeInTheSecondHalves()
        {
            Assert.IsFalse(MatchScene.Flipped(1));
            Assert.IsTrue(MatchScene.Flipped(2));
            Assert.IsFalse(MatchScene.Flipped(3));
            Assert.IsTrue(MatchScene.Flipped(4));
            Assert.IsFalse(MatchScene.Flipped(5));
            // the home side attacks +x in the first half, -x after it
            Assert.AreEqual(new Vector3(52.5f, 0, -34f), MatchScene.World(new Vector2(0, 0), true));
            Assert.AreEqual(MatchScene.World(new Vector2(625, 390), false), -MatchScene.World(new Vector2(625, 390), true));
        }

        // ------------------------------------------------------------ between the frames

        [Test]
        public void ProgressFallsBetweenTheRightFrames()
        {
            MatchScene.Segment(6, 0f, out int i, out float k);
            Assert.AreEqual(0, i); Assert.AreEqual(0f, k, 1e-5f);
            MatchScene.Segment(6, 1f, out i, out k);
            Assert.AreEqual(4, i); Assert.AreEqual(1f, k, 1e-5f);
            MatchScene.Segment(6, 0.5f, out i, out k);     // 2.5 frames in: halfway from frame 2 to 3
            Assert.AreEqual(2, i); Assert.AreEqual(0.5f, k, 1e-5f);
            MatchScene.Segment(6, 0.6f, out i, out k);     // exactly frame 3
            Assert.AreEqual(3, i); Assert.AreEqual(0f, k, 1e-4f);
            MatchScene.Segment(6, 0.04f, out i, out k);    // 0.2 of the way to frame 1, linear (Sprint 20 S5)
            Assert.AreEqual(0, i); Assert.AreEqual(0.2f, k, 1e-5f);
            MatchScene.Segment(1, 0.7f, out i, out k);     // one frame: stays on it
            Assert.AreEqual(0, i); Assert.AreEqual(0f, k);
            MatchScene.Segment(6, 2f, out i, out k);       // past the end: the last frame
            Assert.AreEqual(4, i); Assert.AreEqual(1f, k, 1e-5f);
        }

        static string GoldenPath => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "frame-golden.json"));

        /// <summary>
        /// [Sprint 20 S5] The scene places the frames exactly as the cartoon player: every case of the shared golden
        /// vectors (docs/api/frame-golden.json, checked by `npm run frames` on the web).
        /// </summary>
        [Test]
        public void SegmentFollowsTheGoldenVectors()
        {
            var golden = MiniJson.Parse(File.ReadAllText(GoldenPath));
            var cases = MiniJson.Arr(golden, "segments");
            Assert.Greater(cases.Count, 0);
            foreach (var c in cases)
            {
                var o = (Dictionary<string, object>)c;
                float u = System.Convert.ToSingle(o["u"], System.Globalization.CultureInfo.InvariantCulture);
                MatchScene.Segment((int)MiniJson.Int(c, "count"), u, out int i, out float k);
                Assert.AreEqual(MiniJson.Int(c, "i"), i, "i at u " + u);
                Assert.AreEqual(System.Convert.ToSingle(o["k"], System.Globalization.CultureInfo.InvariantCulture), k, 1e-4f, "k at u " + u);
            }
        }

        // ------------------------------------------------------------ the recording

        [Test]
        public void TheRecordedMatchReadsWhole()
        {
            Assert.IsTrue(File.Exists(SamplePath), "missing " + SamplePath);
            var root = MiniJson.Parse(File.ReadAllText(SamplePath));
            var ticks = MiniJson.Arr(root, "ticks");
            Assert.Greater(ticks.Count, 90);
            int last = 0;
            foreach (var t in ticks)
            {
                var m = MatchMinute.From(t, 3000);
                Assert.AreEqual(last + 1, m.Tick, "ticks in order");
                last = m.Tick;
                Assert.AreEqual(6, m.Frames.Count, "six key frames in tick " + m.Tick);
                Assert.Greater(m.Ms, 0);
                foreach (var f in m.Frames)
                {
                    Assert.That(f.Ball.x, Is.InRange(-60, 1110), "ball x in tick " + m.Tick);
                    Assert.That(f.Ball.y, Is.InRange(-60, 740), "ball y in tick " + m.Tick);
                    Assert.LessOrEqual(f.Players.Count, 22);
                }
            }
            var final = MatchMinute.From(ticks[ticks.Count - 1], 3000);
            Assert.IsTrue(final.Finished);
            Assert.AreEqual(1, final.HomeGoals);
            Assert.AreEqual(1, final.AwayGoals);
        }
    }
}
