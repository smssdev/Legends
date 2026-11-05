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
            int checks = 0, motions = 0, running = 0;
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
                // [Sprint 07 U4] a real player who moves runs in his Animator at the pace he goes (none on the capsules)
                if (scene.Progress > 0.3f && scene.Progress < 0.7f)
                    foreach (var id in a.Players.Keys)
                    {
                        var motion = Player(id)?.GetComponent<PlayerMotion>();
                        if (motion == null) continue;
                        motions++;
                        var anim = motion.GetComponent<Animator>();
                        if (motion.CurrentSpeed > 1f && anim.GetFloat(PlayerMotion.Speed) > 0.5f) running++;
                    }
                checks++;
                yield return null;
            }
            if (motions > 0) Assert.Greater(running, motions / 10, "players run through their Animator while they move");
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
