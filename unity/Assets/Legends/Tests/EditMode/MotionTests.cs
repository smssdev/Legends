using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 07 U6] Who does what (PlayerMotion), on the recorded match (docs/api/samples): every holder who lets the
    /// ball go passes it at his frame, a goal has its shot, its keeper's dive and its scorer's celebration, a foul its
    /// fall, a card its referee; the same minute always gives the same moves; and the keeper's answer follows the ball.
    /// </summary>
    public sealed class MotionTests
    {
        static string SamplePath => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "docs", "api", "samples", "liverpool-arsenal-48213.json"));

        static List<MatchMinute> Minutes()
        {
            var root = MiniJson.Parse(File.ReadAllText(SamplePath));
            return MiniJson.Arr(root, "ticks").Select(t => MatchMinute.From(t, 3000)).ToList();
        }

        static Dictionary<string, object> Event(MatchMinute m, string type) => m.Events.FirstOrDefault(e => MiniJson.Str(e, "type") == type);

        [Test]
        public void EveryGoalHasItsShotItsKeepersAnswerAndItsCelebration()
        {
            var goals = Minutes().Where(m => Event(m, "goal") != null).ToList();
            Assert.Greater(goals.Count, 0, "the sample has goals");
            foreach (var m in goals)
            {
                var cues = PlayerMotion.Cues(m);
                string scorer = MiniJson.Str(Event(m, "goal"), "scorer");
                var attack = m.Events.FirstOrDefault(e => MiniJson.Str(e, "type") == "attack" && MiniJson.Str(e, "result") == "goal");
                Assert.IsTrue(cues.Any(c => c.Id == scorer && c.Move.StartsWith("celebrate") && c.At == m.Frames.Count - 1), $"tick {m.Tick}: the scorer celebrates at the end ({string.Join(", ", cues)})");
                if (attack == null) continue;     // a penalty or a free kick: no attack event to strike from
                // the event's shooter, or whoever the frames put on the ball for the strike
                var shot = cues.LastOrDefault(c => c.OnContact && (c.Move.StartsWith("shot") || c.Move == "header"));
                Assert.NotNull(shot, $"tick {m.Tick}: the shooter strikes ({string.Join(", ", cues)})");
                string keeper = MiniJson.Str(attack, "keeper");
                var dive = cues.FirstOrDefault(c => c.Id == keeper && c.Move == PlayerMotion.Dive);
                Assert.NotNull(dive, $"tick {m.Tick}: the keeper goes for it");
                Assert.Greater(dive.At, shot.At, "after the shot");
                Assert.IsTrue(dive.Beaten, "a goal: the keeper is beaten");
            }
        }

        [Test]
        public void AHolderWhoLetsTheBallGoPassesItAtHisFrame()
        {
            int passes = 0;
            foreach (var m in Minutes())
            {
                var cues = PlayerMotion.Cues(m);
                for (int i = 0; i < m.Frames.Count - 1; i++)
                {
                    var f = m.Frames[i];
                    if (string.IsNullOrEmpty(f.Holder) || !f.Players.ContainsKey(f.Holder)) continue;
                    var go = m.Frames[i + 1].Ball - f.Ball;
                    if (new Vector2(go.x, go.y).magnitude < PlayerMotion.Kicked) continue;
                    // his kick, or something he does that shows more (a shot) at that moment
                    Assert.IsTrue(cues.Any(c => c.Id == f.Holder && Mathf.Abs(c.At - i) < 0.75f), $"tick {m.Tick} frame {i}: {f.Holder} lets the ball go");
                    passes++;
                }
            }
            Assert.Greater(passes, 50, "the sample is full of passes");
        }

        [Test]
        public void AFoulHasItsFallAndACardItsReferee()
        {
            var all = Minutes();
            var foul = all.First(m => Event(m, "foul") != null);
            Assert.IsTrue(PlayerMotion.Cues(foul).Any(c => c.Id == MiniJson.Str(Event(foul, "foul"), "victim") && c.Move == "fall"), "the victim falls");
            // fouled as he plays the ball: his pass stays, the fall comes after it
            foreach (var m in all.Where(x => Event(x, "foul") != null))
            {
                var moves = PlayerMotion.Cues(m);
                foreach (var fall in moves.Where(c => c.Move == "fall"))
                    Assert.IsFalse(moves.Any(c => c.Id == fall.Id && c.OnContact && c.At > fall.At - 0.75f && c.At <= fall.At), $"tick {m.Tick}: {fall.Id} plays the ball before he falls ({string.Join(", ", moves)})");
            }
            var card = all.First(m => Event(m, "card") != null);
            var cues = PlayerMotion.Cues(card);
            Assert.IsTrue(cues.Any(c => c.Id == PlayerMotion.Referee && c.Move == "ref_card"), "the referee shows it");
            Assert.IsTrue(cues.Any(c => c.Id == MiniJson.Str(Event(card, "card"), "player") && c.Move == "protest"), "and its player protests");
        }

        [Test]
        public void TheSameMinuteAlwaysGivesTheSameMoves()
        {
            foreach (var m in Minutes().Take(30))
                Assert.AreEqual(string.Join(", ", PlayerMotion.Cues(m)), string.Join(", ", PlayerMotion.Cues(m)), "tick " + m.Tick);
        }

        [Test]
        public void EveryMoveItAsksForIsAStateOfThePlayer()
        {
            var art = UnityEditor.AssetDatabase.LoadAssetAtPath<PlayerArt>("Assets/Legends/Resources/PlayerArt.asset");
            var states = ((UnityEditor.Animations.AnimatorController)art.motion).layers[0].stateMachine.states.Select(s => s.state.name).ToHashSet();
            foreach (var m in Minutes())
                foreach (var c in PlayerMotion.Cues(m))
                    if (c.Move != PlayerMotion.Dive) Assert.IsTrue(states.Contains(c.Move), c.Move + " is a state of Player.controller");
            foreach (var x in new[] { new Vector3(0.3f, 0.6f, 1f), new Vector3(2.5f, 1.6f, 0f), new Vector3(-2f, 0.3f, 0f) })
                Assert.IsTrue(states.Contains(PlayerMotion.DiveFor(x)), PlayerMotion.DiveFor(x));
        }

        [Test]
        public void TheKeeperCatchesAtHisBodyAndDivesToTheBallsSide()
        {
            Assert.AreEqual("keeper_catch", PlayerMotion.DiveFor(new Vector3(0.3f, 0.9f, 1f)));
            Assert.AreEqual("keeper_dive_r_high", PlayerMotion.DiveFor(new Vector3(2.5f, 1.6f, 0f)), "his right, high");
            Assert.AreEqual("keeper_dive_l_low", PlayerMotion.DiveFor(new Vector3(-2f, 0.3f, 0f)), "his left, low");
            Assert.AreEqual("keeper_dive_r_low", PlayerMotion.DiveFor(new Vector3(0.3f, 0.5f, 1f), beaten: true), "beaten: a dive the ball's way, never a catch");
        }
    }
}
