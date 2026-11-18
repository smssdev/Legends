using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [X113] Unity's scenes tell the story's dramas as the cartoon's clips do, from the same fields of the server's story
    /// (MomentStory): the dive with no tackle, the card's swarm, the double save, the slip, the blackout and the post.
    /// Each on its recorded minute (docs/api/samples/scenes.json).
    /// </summary>
    public sealed class DramaTests
    {
        static readonly Dictionary<string, MatchMinute> Minutes = Load();

        static Dictionary<string, MatchMinute> Load()
        {
            var path = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "scenes.json"));
            var d = new Dictionary<string, MatchMinute>();
            foreach (var e in MiniJson.Arr(MiniJson.Parse(File.ReadAllText(path)), "scenes"))
                d[MiniJson.Str(e, "kind")] = MatchMinute.From(MiniJson.Obj(e, "tick"), 3000);
            return d;
        }

        static List<PlayerMotion.Cue> Cues(string kind) => PlayerMotion.Cues(Minutes[kind]);

        [Test]
        public void ADiveHasNoTackle()
        {
            var dive = Cues("foul:dive");
            Assert.IsTrue(dive.Exists(c => c.Move == "fall"), "he goes down");
            Assert.IsFalse(dive.Exists(c => c.Move.StartsWith("slide_tackle")), "untouched: no one tackles him");
            Assert.IsTrue(Cues("foul:tackle").Exists(c => c.Move.StartsWith("slide_tackle")) || Cues("foul:tackle").Exists(c => c.Move == "fall"), "a real foul still has its tackle or its fall");
        }

        [Test]
        public void ASwarmCrowdsTheReferee()
        {
            int swarm = Cues("card:yellow:swarm").Count(c => c.Move == "protest");
            int tackle = Cues("card:yellow:tackle").Count(c => c.Move == "protest");
            Assert.Greater(swarm, tackle, "team-mates protest with the booked player");
            Assert.GreaterOrEqual(swarm, 3);
        }

        [Test]
        public void ADoubleSaveIsTwoDives()
        {
            Assert.AreEqual(2, Cues("save:double").Count(c => c.Move == PlayerMotion.Dive));
            Assert.AreEqual(1, Cues("save").Count(c => c.Move == PlayerMotion.Dive));
        }

        [Test]
        public void ASlipPutsAPlayerDown() => Assert.IsTrue(Cues("slip").Exists(c => c.Move == "fall"));

        [Test]
        public void TheBlackoutIsRoundTheStrike()
        {
            var m = Minutes["goal:blackout"];
            Assert.IsTrue(MatchScene.LightsOut(m, 3.0, 3.0), "dark at the strike");
            Assert.IsTrue(MatchScene.LightsOut(m, 2.3, 3.0), "dark just before it");
            Assert.IsFalse(MatchScene.LightsOut(m, 3.6, 3.0), "the lights back with the ball in the net");
            Assert.IsFalse(MatchScene.LightsOut(Minutes["goal"], 3.0, 3.0), "only the blackout");
        }

        [Test]
        public void AShotOffThePostGoesToThePost()
        {
            var m = Minutes["miss"];
            Assert.AreEqual("post", m.Story.Str("how"), "the recording's miss is off the post");
            var w = MatchScene.WindowOf(m, PlayerMotion.Cues(m));
            Assert.IsTrue(w.HasKey);
            var at = MatchScene.PostBall(m, w.Key + 1f, Vector3.zero, w);
            Assert.IsTrue(Mathf.Approximately(at.x, 0f) || Mathf.Approximately(at.x, 1050f), "on a goal line");
            Assert.AreEqual(36.6f, Mathf.Abs(at.y - 340f), 0.01f, "at a post");
            Assert.AreEqual(Vector3.one, MatchScene.PostBall(m, w.Key + 3f, Vector3.one, w), "then the frames' path again");
            Assert.AreEqual(Vector3.one, MatchScene.PostBall(Minutes["goal"], 5f, Vector3.one, w), "only off the post");
        }
    }
}
