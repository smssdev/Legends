using System.IO;
using NUnit.Framework;
using UnityEngine;
using Legends.Shots;

namespace Legends.Tests
{
    /// <summary>
    /// [X113] A scene on the cartoon's timeline: it plays its event, not the whole minute's frames (the frames before go
    /// by as the clock runs), and its strike falls on the cartoon's key second, where the page plays the goal's sound,
    /// shows the score and the commentator speaks.
    /// </summary>
    public sealed class WarpTests
    {
        [Test]
        public void TheStrikeFallsOnTheCartoonsSecond()
        {
            var w = new MatchScene.Window { From = 5, Key = 8f, HasKey = true };
            const double len = 6.0, keyT = 3.0;
            const int n = 9;
            Assert.AreEqual(0f, MatchScene.Warp(0, len, n, w, keyT), 1e-6f);
            Assert.AreEqual(5f / n, MatchScene.Warp(MatchScene.Lead, len, n, w, keyT), 1e-5f, "the window from the end of the lead");
            Assert.AreEqual(8f / n, MatchScene.Warp(keyT, len, n, w, keyT), 1e-5f, "the strike on the key second");
            Assert.AreEqual(1f, MatchScene.Warp(len, len, n, w, keyT), 1e-6f);
            float last = -1;
            for (double s = 0; s <= len; s += 0.05)
            {
                float f = MatchScene.Warp(s, len, n, w, keyT);
                Assert.GreaterOrEqual(f, last, $"never back at {s:0.00}");
                last = f;
            }
        }

        [Test]
        public void WithoutAWindowTheFramesGoEvenly()
        {
            var none = new MatchScene.Window();
            Assert.AreEqual(0.5f, MatchScene.Warp(1.5, 3.0, 9, none, 0), 1e-6f);
            Assert.AreEqual(1f, MatchScene.Warp(9, 3.0, 9, none, 0), 1e-6f);
        }

        [Test]
        public void EverySceneOfTheRecordingsHasItsEventInItsWindow()
        {
            var path = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "scenes.json"));
            int windows = 0;
            foreach (var e in MiniJson.Arr(MiniJson.Parse(File.ReadAllText(path)), "scenes"))
            {
                var m = MatchMinute.From(MiniJson.Obj(e, "tick"), 3000);
                var cues = PlayerMotion.Cues(m);
                var w = MatchScene.WindowOf(m, cues);
                if (!w.HasKey) continue;
                windows++;
                Assert.Less(w.From, w.Key, MiniJson.Str(e, "kind"));
                Assert.LessOrEqual(w.Key, m.Frames.Count - 1, MiniJson.Str(e, "kind"));
                Assert.GreaterOrEqual(w.Key - w.From, 1f, MiniJson.Str(e, "kind") + ": the event has frames to play");
            }
            Assert.Greater(windows, 8, "the goals, saves, misses, set pieces and cards have their strike");
        }
    }
}
