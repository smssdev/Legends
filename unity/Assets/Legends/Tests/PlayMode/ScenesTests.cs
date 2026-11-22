using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using Legends.Shots;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 09, the definition of done] Every kind of scene the engine tells, in its own recorded minute
    /// (docs/api/samples/scenes.json, sim:golden --write), and every other scene the cartoon has told on a recorded
    /// minute: through the minute, a quarter second at a time, the director has on air exactly the shot the minute's
    /// plan says (its scene's camera, the close shot on the strike, the cutaways, the replay from its two sides), and the
    /// last shot ends on the minute's own length (the server's moment.ms). Every screen runs this same pure plan, so two
    /// screens on the same minute show the same shot at the same instant.
    /// </summary>
    public sealed class ScenesTests
    {
        static string Samples => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples"));

        GameObject root, cam;
        MatchScene scene;

        [SetUp]
        public void Make()
        {
            cam = new GameObject("Main Camera", typeof(Camera)) { tag = "MainCamera" };
            root = new GameObject("Scenes Match");
            scene = root.AddComponent<MatchScene>();
            var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            scene.playerMaterial = new Material(shader);
            scene.ballMaterial = new Material(shader);
        }

        [TearDown]
        public void Clean()
        {
            Object.Destroy(root);
            Object.Destroy(cam);
        }

        /// <summary>The recorded scenes, and a recorded minute retold as each scene the recordings lack (a red card, a corner...).</summary>
        static List<(string kind, object entry, MatchMinute minute)> All()
        {
            var list = new List<(string, object, MatchMinute)>();
            var scenes = MiniJson.Arr(MiniJson.Parse(File.ReadAllText(Path.Combine(Samples, "scenes.json"))), "scenes");
            foreach (var e in scenes) list.Add((MiniJson.Str(e, "kind"), e, MatchMinute.From(MiniJson.Obj(e, "tick"), 3000)));
            var told = new HashSet<string>(list.Select(x => x.Item3.Story.Scene));
            var host = scenes.First(e => MiniJson.Str(e, "kind").StartsWith("card"));
            var cutaways = new HashSet<string> { "crowd", "coachReact", "brawl", "tunnel", "handshake", "meltdown" };
            foreach (var name in MinutePlan.SceneTime.Keys.Where(k => !told.Contains(k) && !cutaways.Contains(k)))
            {
                var m = MatchMinute.From(MiniJson.Obj(host, "tick"), 3000);
                m.Story = new MinutePlan.Story { Scene = name, Side = "away", Data = new Dictionary<string, object>() };
                list.Add((name + " (retold)", host, m));
            }
            // and the red card, with its fight and its coach
            var red = MatchMinute.From(MiniJson.Obj(host, "tick"), 3000);
            red.Story = new MinutePlan.Story { Scene = "card", Side = "home", Data = new Dictionary<string, object> { ["type"] = "red" } };
            list.Add(("card:red (retold)", host, red));
            return list;
        }

        [Test]
        public void TheRecordingsHoldEveryKindTheEngineTells()
        {
            var kinds = All().Select(x => x.minute.Story.Scene).ToList();
            foreach (var s in new[] { "goal", "save", "miss", "penalty", "freekick", "card", "foul", "injury", "sub", "var", "trap", "whistle", "clearance", "slip", "rant" })
                CollectionAssert.Contains(kinds, s, s + " is recorded");
            foreach (var k in MinutePlan.SceneTime.Keys)
                if (!new[] { "crowd", "coachReact", "brawl", "tunnel", "handshake", "meltdown" }.Contains(k)) CollectionAssert.Contains(kinds, k, k + " is told");
        }

        [UnityTest]
        public IEnumerator EverySceneHasItsShotOnTheSecond()
        {
            int checks = 0;
            foreach (var (kind, entry, m) in All())
            {
                scene.Begin(MatchSetup.From(MiniJson.Parse(SamplePlayback.Setup(entry, new List<object> { MiniJson.Obj(entry, "tick") }))));
                yield return null;   // the director rigs its cameras
                var director = root.GetComponent<Director>();
                Assert.NotNull(director, kind);
                var plan = scene.PlanFor(m);
                double total = m.Ms / 1000.0;
                Assert.AreEqual(total, plan.Total, 1e-9, kind + ": the minute's length is the server's");
                var shots = ShotList.All(plan, m.Story, null);
                Assert.AreEqual(total, shots[shots.Count - 1].To, 1e-9, kind + ": the last shot ends with the minute");
                for (double t = 0; t < total; t += 0.25)
                {
                    scene.HoldAt(m, t);
                    yield return null;   // the director cuts in LateUpdate
                    var expected = ShotList.At(scene.Plan, m.Story, t, scene.KeyMoment);
                    string name = ShotList.ReplayAngle(expected, t) ?? (Director.Kinds.Contains(expected.Name) ? expected.Name : ShotList.Broadcast);
                    Assert.AreEqual(name, director.Now.Name, $"{kind} at {t:0.00} s ({string.Join(" | ", ShotList.All(scene.Plan, m.Story, scene.KeyMoment))})");
                    // the same minute planned again (another screen) has the same shot then
                    var again = ShotList.At(scene.PlanFor(m), m.Story, t, scene.KeyMoment);
                    Assert.AreEqual(expected.ToString(), again.ToString(), kind + ": every screen the same");
                    checks++;
                }
                // the frames end with the scene and hold through what follows it
                if (plan.SceneT > 0) Assert.AreEqual(1f, MatchScene.FramesAt(plan, plan.SceneT), 1e-6f, kind);
            }
            Assert.Greater(checks, 300);
        }

        /// <summary>
        /// [X113] The strike on the cartoon's second: every recorded scene with a strike (a shot, a save, a card, a foul)
        /// has it in Unity at the cartoon's key second (SCENE_TIME's key over its length, as told.ts), where the page plays
        /// its sound, turns the score and the commentator says his key line; and the ball is struck there in the frames.
        /// </summary>
        [UnityTest]
        public IEnumerator TheStrikeIsOnTheCartoonsKeySecond()
        {
            int checkedScenes = 0;
            foreach (var (kind, entry, m) in All())
            {
                if (kind.EndsWith("(retold)")) continue;
                scene.Begin(MatchSetup.From(MiniJson.Parse(SamplePlayback.Setup(entry, new List<object> { MiniJson.Obj(entry, "tick") }))));
                yield return null;
                var w = MatchScene.WindowOf(m, PlayerMotion.Cues(m));
                if (!w.HasKey) continue;
                var plan = scene.PlanFor(m);
                double cartoonKey = ShotList.KeyAt(plan, m.Story);
                scene.HoldAt(m, cartoonKey);
                yield return null;
                Assert.AreEqual(cartoonKey, scene.KeyMoment ?? -1, 1e-6, kind + ": the strike's second is the cartoon's");
                int n = m.Frames.Count - 1;
                Assert.AreEqual(w.Key / n, scene.FramesOf(m, cartoonKey), 1e-4f, kind + ": the frames are at the strike then");
                checkedScenes++;
            }
            Assert.Greater(checkedScenes, 8);
        }

        [UnityTest]
        public IEnumerator AGoalsReplayIsSlowAndComesBackLive()
        {
            var (kind, entry, m) = All().First(x => x.minute.Story.Goal && x.minute.Ms >= 9000);
            scene.Begin(MatchSetup.From(MiniJson.Parse(SamplePlayback.Setup(entry, new List<object> { MiniJson.Obj(entry, "tick") }))));
            yield return null;
            var plan = scene.PlanFor(m);
            if (plan.Replay == null) Assert.Inconclusive(kind + " has no room for a replay at this tier");
            scene.HoldAt(m, plan.Replay.At + 0.2);
            yield return null;
            Assert.IsTrue(scene.Replaying, kind);
            var anyone = root.GetComponentsInChildren<Animator>().FirstOrDefault();
            if (anyone != null) Assert.Less(anyone.speed, 1f, "the players move slowly in the replay");
            scene.HoldAt(m, plan.Total - 0.2);
            yield return null;
            Assert.IsFalse(scene.Replaying);
            if (anyone != null) Assert.AreEqual(1f, anyone.speed, 1e-6f, "live again after it");
        }
    }
}
