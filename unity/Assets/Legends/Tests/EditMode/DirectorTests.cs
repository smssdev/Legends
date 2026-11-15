using System;
using System.Collections.Generic;
using System.IO;
using NUnit.Framework;
using UnityEngine;
using Legends.Shots;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 09 G1] Unity's port of the cartoon's minute (Shots/MinutePlan.cs) against the director's golden vectors
    /// (docs/api/director-golden.json, written by web/scripts/director-golden.mjs from plan.ts, director.ts, timing.ts and
    /// clock.ts): every minute of the sample match and a story for every scene, at every tier: the same scene length, the
    /// same cutaways with the same data, the same replay, and the same TV clock.
    /// </summary>
    public sealed class DirectorTests
    {
        static string GoldenPath => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "director-golden.json"));

        static double D(object o) => Convert.ToDouble(o, System.Globalization.CultureInfo.InvariantCulture);

        static Dictionary<string, string> Strings(object o)
        {
            if (!(o is Dictionary<string, object> d)) return null;
            var r = new Dictionary<string, string>();
            foreach (var kv in d) r[kv.Key] = kv.Value as string;
            return r;
        }

        static bool Same(object a, object b) =>
            a is bool || b is bool ? Equals(a, b)
            : a is string || b is string ? Equals(a, b)
            : Math.Abs(D(a) - D(b)) < 1e-9;

        [Test]
        public void ThePortGivesEveryCaseOfTheCartoon()
        {
            Assert.IsTrue(File.Exists(GoldenPath), "missing " + GoldenPath + " (node web/scripts/director-golden.mjs)");
            var cases = MiniJson.Arr(MiniJson.Parse(File.ReadAllText(GoldenPath)), "cases");
            Assert.Greater(cases.Count, 500, "the vectors cover the sample and every scene");
            int scenes = 0, replays = 0, cutaways = 0;
            for (int i = 0; i < cases.Count; i++)
            {
                var c = cases[i];
                string at = $"case {i}";
                var st = MiniJson.Obj(c, "story");
                var story = new MinutePlan.Story
                {
                    Scene = MiniJson.Str(st, "scene", null), Side = MiniJson.Str(st, "side", "home"),
                    Goal = st.TryGetValue("goal", out var g) && g is bool gb && gb, Data = MiniJson.Obj(st, "data") ?? new Dictionary<string, object>(),
                };
                var tick = MiniJson.Obj(c, "tick");
                var minute = MiniJson.Arr(tick, "minute");
                var cx = MiniJson.Obj(c, "ctx");
                var ctx = new MinutePlan.Ctx
                {
                    Tier = (MinutePlan.Tier)Array.IndexOf(new[] { "low", "mid", "high" }, MiniJson.Str(cx, "tier")),
                    Seed = (int)MiniJson.Int(cx, "seed", 1), Looks = Strings(cx.TryGetValue("looks", out var lk) ? lk : null),
                    Smooth = cx.TryGetValue("smooth", out var sm) && sm is bool smb && smb,
                };
                int tickNo = (int)MiniJson.Int(tick, "tick");
                var moods = Strings(tick.TryGetValue("moods", out var md) ? md : null);
                var plan = MinutePlan.Of(story, tickNo, moods, (int)MiniJson.Int(tick, "ms", 3000), ctx);

                var want = MiniJson.Obj(c, "plan");
                Assert.AreEqual(D(want["total"]), plan.Total, 1e-9, at + " total");
                Assert.AreEqual(D(want["sceneT"]), plan.SceneT, 1e-9, at + " sceneT");
                Assert.AreEqual(D(want["cutT"]), plan.CutT, 1e-9, at + " cutT");
                Assert.AreEqual(D(want["rate"]), plan.Rate, 1e-9, at + " rate");
                var cuts = MiniJson.Arr(want, "cuts");
                Assert.AreEqual(cuts.Count, plan.Cuts.Count, at + " cutaways: " + string.Join(",", plan.Cuts.ConvertAll(x => x.Name)));
                for (int k = 0; k < cuts.Count; k++)
                {
                    Assert.AreEqual(MiniJson.Str(cuts[k], "name"), plan.Cuts[k].Name, $"{at} cut {k}");
                    Assert.AreEqual(D(((Dictionary<string, object>)cuts[k])["dur"]), plan.Cuts[k].Dur, 1e-9, $"{at} cut {k} dur");
                    var data = MiniJson.Obj(cuts[k], "data");
                    Assert.AreEqual(data.Count, plan.Cuts[k].Data.Count, $"{at} cut {k} data");
                    foreach (var kv in data)
                        Assert.IsTrue(plan.Cuts[k].Data.TryGetValue(kv.Key, out var v) && Same(kv.Value, v), $"{at} cut {k} {kv.Key}: {kv.Value} vs {v}");
                }
                var replay = MiniJson.Obj(want, "replay");
                Assert.AreEqual(replay != null, plan.Replay != null, at + " replay");
                if (replay != null)
                {
                    Assert.AreEqual(D(replay["at"]), plan.Replay.At, 1e-9, at + " replay at");
                    Assert.AreEqual(D(replay["rate"]), plan.Replay.Rate, 1e-9, at + " replay rate");
                    Assert.AreEqual(D(replay["off"]), plan.Replay.Off, 1e-9, at + " replay off");
                    replays++;
                }

                foreach (var k in MiniJson.Arr(c, "clock"))
                {
                    double u = D(((Dictionary<string, object>)k)["u"]);
                    var clock = MinutePlan.Clock(Convert.ToInt32(minute[0]), Convert.ToInt32(minute[1]), tickNo, u, story.Scene != null ? plan : null);
                    Assert.AreEqual(MiniJson.Str(k, "text"), clock.Text, $"{at} clock at {u}");
                    Assert.AreEqual(((Dictionary<string, object>)k)["frozen"], clock.Frozen, $"{at} clock frozen at {u}");
                    Assert.AreEqual(MiniJson.Str(k, "half"), clock.Half, $"{at} half");
                    Assert.AreEqual(D(((Dictionary<string, object>)k)["progress"]), clock.Progress, 1e-9, $"{at} progress at {u}");
                }
                if (story.Scene != null) scenes++;
                cutaways += plan.Cuts.Count;
            }
            Assert.Greater(scenes, 100, "scenes");
            Assert.Greater(replays, 10, "replays");
            Assert.Greater(cutaways, 100, "cutaways");
        }
    }
}
