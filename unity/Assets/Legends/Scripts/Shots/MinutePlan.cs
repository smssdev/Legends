using System;
using System.Collections.Generic;
using System.Linq;

namespace Legends.Shots
{
    /// <summary>
    /// [Sprint 09 G1] A minute's timeline as the cartoon plays it, ported line by line from web/src/match/feed (timing.ts,
    /// director.ts, plan.ts, clock.ts; the owner's decision of 2026-11-05: Unity's shots are the cartoon's, realer): how long
    /// the minute is, how long its scene (the server's frames in Unity), the director's cutaways after it, a goal's slow
    /// replay, and the TV clock that stands still through them. Pure, and in doubles as JavaScript counts, so the golden
    /// vectors (docs/api/director-golden.json, written from the cartoon) hold it to the cartoon case for case
    /// (Tests/EditMode/DirectorTests). A change there is written here and in the vectors together.
    /// </summary>
    public static class MinutePlan
    {
        /// <summary>timing.ts SCENE_TIME: each scene's own length and when its key moment is (s).</summary>
        public static readonly Dictionary<string, (double length, double key)> SceneTime = new Dictionary<string, (double, double)>
        {
            ["goal"] = (6.0, 3.0), ["save"] = (5.4, 2.9), ["penalty"] = (6.8, 4.05), ["freekick"] = (5.2, 2.65),
            ["card"] = (6.6, 3.4), ["coach"] = (4.6, 1.0), ["sub"] = (5.0, 0.8), ["offside"] = (4.2, 1.5),
            ["corner"] = (4.6, 1.75), ["injury"] = (5.6, 0.4), ["foul"] = (5.2, 1.5), ["whistle"] = (3.6, 0.6),
            ["miss"] = (5.0, 2.9), ["blocked"] = (4.8, 2.6), ["board"] = (3.0, 0.5),
            ["crowd"] = (2.6, 0.3), ["coachReact"] = (2.4, 0.2), ["brawl"] = (2.8, 0.2), ["tunnel"] = (2.8, 0.2),
            ["handshake"] = (3.0, 0.2), ["var"] = (8.2, 6.4),
            ["clearance"] = (4.2, 2.4), ["trap"] = (3.6, 1.5), ["rant"] = (3.6, 0.6), ["slip"] = (3.6, 1.0),
            ["meltdown"] = (2.8, 0.3),
        };

        public enum Tier { Low, Mid, High }

        /// <summary>What the plan reads of the minute's story (the server's `story`: MomentStory).</summary>
        public sealed class Story
        {
            public string Scene;            // null: a quiet minute
            public string Side = "home";
            public bool Goal;
            public Dictionary<string, object> Data = new Dictionary<string, object>();

            public string Str(string key) => Data != null && Data.TryGetValue(key, out var v) && v is string s ? s : null;
        }

        /// <summary>A cutaway after the scene: its name (a shot in Unity), what it shows, and how long (s).</summary>
        public sealed class Cut
        {
            public string Name;
            public Dictionary<string, object> Data = new Dictionary<string, object>();
            public double Dur;
        }

        public sealed class Replay
        {
            public double At, Rate, Off;
        }

        public sealed class Plan
        {
            public double Total, SceneT, CutT, Rate;
            public List<Cut> Cuts = new List<Cut>();
            public Replay Replay;
        }

        public sealed class Ctx
        {
            public Tier Tier = Tier.High;
            public int Seed = 1;
            public Dictionary<string, string> Looks;
            public bool Smooth;
        }

        static readonly string[] Moods = { "joy", "cheer", "angry", "worried", "sad", "surprise" };

        // ------------------------------------------------------------------ director.ts

        /// <summary>
        /// As on a broadcast. A goal: the scorers' fans, their coach's joy, then the other coach. A red card: the players
        /// squaring up, then the sent-off player's coach. A big chance missed or saved: the shooter's coach. The moods are
        /// the server's when it has an expressive one. None on low, one on mid, up to three on high; only what fits.
        /// </summary>
        public static List<Cut> Director(Story s, int tick, IDictionary<string, string> moods, double total, double sceneT, Ctx ctx)
        {
            var fit = new List<Cut>();
            if (s == null || string.IsNullOrEmpty(s.Scene) || ctx.Tier == Tier.Low) return fit;
            string side = s.Side, other = side == "home" ? "away" : "home";
            moods = moods ?? new Dictionary<string, string>();
            int seed = ctx.Seed != 0 ? ctx.Seed : 1;
            string Look(string sd) => ctx.Looks != null && ctx.Looks.TryGetValue(sd, out var l) && l != null ? l : (sd == "home" ? "C1" : "C2");
            string Felt(string sd, string fallback) => moods.TryGetValue(sd, out var m) && Moods.Contains(m) ? m : fallback;
            Cut Coach(string sd, string fallback) => new Cut
            {
                Name = "coachReact",
                Data = new Dictionary<string, object> { ["side"] = sd, ["look"] = Look(sd), ["mood"] = Felt(sd, fallback) },
                Dur = SceneTime["coachReact"].length,
            };
            Cut Crowd() => new Cut
            {
                Name = "crowd",
                Data = new Dictionary<string, object>
                {
                    ["side"] = side, ["v"] = (double)(seed * 7 + tick), ["count"] = ctx.Tier == Tier.High ? 110.0 : 60.0, ["flares"] = ctx.Tier == Tier.High,
                },
                Dur = SceneTime["crowd"].length,
            };
            Cut Named(string name, Dictionary<string, object> data) => new Cut { Name = name, Data = data, Dur = SceneTime[name].length };

            var list = new List<Cut>();
            string type = s.Str("type"), drama = s.Str("drama");
            if (s.Goal) list = new List<Cut> { Crowd(), Coach(side, "joy"), Coach(other, "angry") };
            else if (s.Scene == "card" && type == "red" && (drama == "brawl" || drama == "spit")) list = new List<Cut> { Coach(side, "angry") };
            else if (s.Scene == "card")
                list = type == "red"
                    ? new List<Cut> { Named("brawl", new Dictionary<string, object> { ["side"] = side, ["v"] = (double)(seed * 13 + tick) }), Coach(side, "angry") }
                    : ctx.Tier == Tier.High ? new List<Cut> { Coach(side, "angry") } : new List<Cut>();
            else if (s.Scene == "miss" && s.Str("how") == "over")
                list = new List<Cut> { Named("meltdown", new Dictionary<string, object> { ["side"] = side, ["v"] = (double)(seed * 5 + tick) }) };
            else if (s.Scene == "miss" || s.Scene == "save" || s.Scene == "penalty" || s.Scene == "freekick") list = new List<Cut> { Coach(side, "worried") };
            else if (s.Scene == "whistle" && s.Str("name") == "halftime")
                list = new List<Cut> { Named("tunnel", new Dictionary<string, object> { ["side"] = "home" }) };
            else if (s.Scene == "whistle" && s.Str("name") == "fulltime")
                list = new List<Cut> { Named("handshake", new Dictionary<string, object> { ["side"] = "home" }), Coach("home", "idle"), Coach("away", "idle") };
            else if (s.Scene == "var") list = new List<Cut> { Coach(side, "angry"), Coach(other, "joy") };
            list = list.Take(ctx.Tier == Tier.High ? 3 : 1).ToList();
            // What fits: a goal keeps room for its replay (4.5 s), the rest for the commentator's line (1.2 s).
            double keep = s.Goal ? 4.5 : 1.2, used = 0;
            foreach (var c in list)
                if (sceneT + used + c.Dur + keep <= total)
                {
                    fit.Add(c);
                    used += c.Dur;
                }
            return fit;
        }

        // ------------------------------------------------------------------ plan.ts

        /// <summary>The minute's timeline: its length (the server's moment.ms), its scene's, the cutaways and a goal's replay.</summary>
        public static Plan Of(Story s, int tick, IDictionary<string, string> moods, int? ms, Ctx ctx)
        {
            double total = (ms ?? 3000) / 1000.0;
            bool scene = !string.IsNullOrEmpty(s.Scene);
            double nominal = scene ? SceneTime[s.Scene].length : 0;
            // the scene takes most of the minute; at the live pace (3.3 s) up to nine tenths of it, a little faster
            double sceneT = scene ? Math.Min(nominal, total * ((ms ?? 0) <= 3400 ? 0.9 : 0.72)) : 0;
            var cuts = Director(s, tick, moods, total, sceneT, ctx);
            double cutT = 0;
            foreach (var c in cuts) cutT += c.Dur;
            double at = sceneT + (cuts.Count > 0 ? cutT + 0.5 : 2.6), room = total - at - 0.8;
            double rate = s.Goal && scene && room > 1.6 && !ctx.Smooth ? Math.Max(0.4, Math.Min(0.8, nominal / room)) : 0;
            return new Plan
            {
                Total = total, SceneT = sceneT, Cuts = cuts, CutT = cutT, Rate = scene ? nominal / sceneT : 1,
                Replay = rate != 0 ? new Replay { At = at, Rate = rate, Off = Math.Max(0, nominal - room * rate) } : null,
            };
        }

        // ------------------------------------------------------------------ clock.ts

        public struct ClockAt
        {
            public string Text, Half;
            public bool Frozen;
            public double Progress;
        }

        /// <summary>
        /// The TV clock at u (0..1 of the minute): with a scene it runs to the moment's second in the first 0.4 s, stands
        /// still through the scene and its cutaways, then runs on. minute: [minute, added]; tickNo: the minute's number.
        /// </summary>
        public static ClockAt Clock(int minute, int added, int tickNo, double u, Plan p)
        {
            int @base = minute - 1 + added;
            double sec = Math.Min(59, Math.Floor(u * 60));
            bool scene = p != null && p.SceneT > 0;
            double hold = scene && p.Total != 0 ? Math.Min(0.95, (p.SceneT + p.CutT) / p.Total) : 0;
            bool frozen = scene && hold > 0 && u < hold && u * p.Total >= 0.4;
            if (scene && hold > 0)
            {
                double at = 12 + ((tickNo != 0 ? tickNo : 1) * 37) % 40, run = Math.Min(hold, 0.4 / p.Total);
                sec = Math.Min(59, Math.Floor(u < run ? at * u / run : u < hold ? at : at + (59 - at) * (u - hold) / (1 - hold)));
            }
            int mm = minute + added;
            string half = minute > 120 ? "shootout" : minute > 90 ? "extra" : minute > 45 ? "second" : "first";
            double progress = Math.Min(1, Math.Floor((mm - 1 + u) / 90 * 200 + 0.5) / 200);    // JavaScript's Math.round
            return new ClockAt { Text = $"{@base:00}:{(int)sec:00}", Frozen = frozen, Half = half, Progress = progress };
        }
    }
}
