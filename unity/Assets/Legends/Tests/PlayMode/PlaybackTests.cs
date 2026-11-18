using System.Collections;
using System.Collections.Generic;
using System.IO;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace Legends.Tests
{
    /// <summary>
    /// The recorded Liverpool v Arsenal match through the bridge, as the page sends it (Sprint 2, U7): every player
    /// and the ball stand where the server's frames put them at that moment of the minute, in both halves.
    /// `build.ps1 test`, or Window → General → Test Runner → PlayMode.
    /// </summary>
    public sealed class PlaybackTests
    {
        const float Tolerance = 0.05f;   // metres
        static string SamplePath => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "liverpool-arsenal-48213.json"));

        GameObject root;
        MatchScene scene;
        Bridge bridge;
        List<object> ticks;

        [SetUp]
        public void Load()
        {
            Assert.IsTrue(File.Exists(SamplePath), "missing " + SamplePath);
            var json = MiniJson.Parse(File.ReadAllText(SamplePath));
            ticks = MiniJson.Arr(json, "ticks");

            root = new GameObject("Test Match");
            scene = root.AddComponent<MatchScene>();
            var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            scene.playerMaterial = new Material(shader);
            scene.ballMaterial = new Material(shader);
            bridge = root.AddComponent<Bridge>();
            bridge.scene = scene;

            var match = MiniJson.Obj(json, "match");
            var teams = MiniJson.Obj(ticks[0], "teams");
            bridge.OnSetup(Write(new Dictionary<string, object>
            {
                ["clubs"] = MiniJson.Obj(match, "clubs"),
                ["tick_ms"] = MiniJson.Int(MiniJson.Obj(match, "timing"), "tick_ms", 3000),
                ["players"] = new Dictionary<string, object>
                {
                    ["home"] = MiniJson.Arr(MiniJson.Obj(teams, "home"), "players"),
                    ["away"] = MiniJson.Arr(MiniJson.Obj(teams, "away"), "players"),
                },
            }));
            Time.timeScale = 4f;
        }

        [TearDown]
        public void Clean()
        {
            Time.timeScale = 1f;
            Object.Destroy(root);
        }

        [UnityTest]
        public IEnumerator FirstHalfMinuteFollowsTheFrames() => Follow(11);

        [UnityTest]
        public IEnumerator SecondHalfMinuteIsMirrored() => Follow(60);

        /// <summary>
        /// [X113] The web page's way: the minute played now (OnPlay), then the page's clock (OnClock) a few times a second.
        /// The scene keeps to the page's second, runs at its speed (x2) and stands still when it stops (0).
        /// </summary>
        [UnityTest]
        public IEnumerator TheSceneKeepsToThePagesClock()
        {
            Time.timeScale = 1f;
            var tick = ticks[19];
            int no = (int)MiniJson.Int(tick, "tick");
            bridge.OnPlay(Write(tick));
            yield return null;
            Assert.NotNull(scene.Current, "the page's minute is on");
            bridge.OnClock(no + ",2.500,1");
            yield return null;
            Assert.AreEqual(2.5, scene.Elapsed, 0.2, "jumped to the page's second");
            bridge.OnClock(no + ",2.600,2");
            Assert.AreEqual(2f, Time.timeScale, 1e-6f, "the page's x2");
            bridge.OnClock(no + ",2.700,0");
            Assert.AreEqual(0f, Time.timeScale, 1e-6f, "the page stopped");
            yield return null;   // the page's second taken
            double held = scene.Elapsed;
            yield return null;
            yield return null;
            Assert.AreEqual(held, scene.Elapsed, 1e-6, "still while the page is still");
            bridge.OnClock((no + 5) + ",1.000,1");
            Assert.AreEqual(no, scene.Current.Tick, "a minute it was not given is left alone");
            bridge.OnClock("nonsense");
            Time.timeScale = 4f;
        }

        [UnityTest]
        public IEnumerator TheMinutesPlayInOrder()
        {
            for (int t = 1; t <= 3; t++) bridge.OnMinute(Write(ticks[t - 1]));
            int seen = 0, previous = 0;
            float limit = Time.realtimeSinceStartup + 20f;
            while (seen < 3 && Time.realtimeSinceStartup < limit)
            {
                if (scene.Current != null && scene.Current.Tick != previous)
                {
                    Assert.AreEqual(previous + 1, scene.Current.Tick);
                    previous = scene.Current.Tick;
                    seen++;
                }
                yield return null;
            }
            Assert.AreEqual(3, seen, "three minutes played in order");
        }

        /// <summary>Plays one minute and, on every frame of it, checks each player and the ball against the key frames.</summary>
        IEnumerator Follow(int tick)
        {
            var minute = MatchMinute.From(ticks[tick - 1], 3000);
            bridge.OnMinute(Write(ticks[tick - 1]));
            bool flip = MatchScene.Flipped(minute.Period);
            int checks = 0;
            float limit = Time.realtimeSinceStartup + 20f;
            yield return null;   // the scene takes the minute on its first update
            while (scene.Current != null && Time.realtimeSinceStartup < limit)
            {
                MatchScene.Segment(minute.Frames.Count, scene.Progress, out int i, out float k);
                var a = minute.Frames[i];
                var b = minute.Frames[Mathf.Min(i + 1, minute.Frames.Count - 1)];
                // [Sprint 31 M1] Between frames the scene follows the curve, not a straight line; [Sprint 06 U8] a real
                // player stands on the grass (BodyLift 0), a capsule 0.9 m up.
                var pf = i > 0 ? minute.Frames[i - 1] : null;
                var nf = i + 2 < minute.Frames.Count ? minute.Frames[i + 2] : null;
                foreach (var id in a.Players.Keys)
                {
                    if (!b.Players.ContainsKey(id)) continue;
                    var expected = MatchScene.World(MatchScene.SamplePlayer(pf, a, b, nf, id, k), flip) + Vector3.up * scene.BodyLift;
                    var body = Player(id);
                    Assert.NotNull(body, "player " + id + " is in the scene");
                    Assert.IsTrue(body.gameObject.activeSelf, "player " + id + " is shown");
                    Assert.Less(Vector3.Distance(expected, body.localPosition), Tolerance, $"player {id} in tick {tick} at {scene.Progress:0.00}");
                }
                var ball = MatchScene.SampleBall(pf, a, b, nf, k);
                var ballAt = MatchScene.World(new Vector2(ball.x, ball.y), flip);
                Assert.Less(Vector2.Distance(new Vector2(ballAt.x, ballAt.z), new Vector2(scene.Ball.localPosition.x, scene.Ball.localPosition.z)), Tolerance, $"ball in tick {tick}");
                checks++;
                yield return null;
            }
            Assert.Greater(checks, 5, "the minute was drawn over several frames");
            Assert.IsNull(scene.Current, "the minute ended in its time");
        }

        Transform Player(string id)
        {
            foreach (Transform child in root.transform)
                if (child.name.EndsWith(" #" + id)) return child;
            return null;
        }

        static string Write(object o)
        {
            var sb = new System.Text.StringBuilder();
            Append(sb, o);
            return sb.ToString();
        }

        static void Append(System.Text.StringBuilder sb, object o)
        {
            switch (o)
            {
                case null: sb.Append("null"); break;
                case bool b: sb.Append(b ? "true" : "false"); break;
                case string s: sb.Append('"').Append(s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n")).Append('"'); break;
                case long l: sb.Append(l); break;
                case double d: sb.Append(d.ToString(System.Globalization.CultureInfo.InvariantCulture)); break;
                case Dictionary<string, object> obj:
                    sb.Append('{');
                    bool first = true;
                    foreach (var kv in obj)
                    {
                        if (!first) sb.Append(',');
                        first = false;
                        Append(sb, kv.Key);
                        sb.Append(':');
                        Append(sb, kv.Value);
                    }
                    sb.Append('}');
                    break;
                case List<object> list:
                    sb.Append('[');
                    for (int i = 0; i < list.Count; i++)
                    {
                        if (i > 0) sb.Append(',');
                        Append(sb, list[i]);
                    }
                    sb.Append(']');
                    break;
            }
        }
    }
}
