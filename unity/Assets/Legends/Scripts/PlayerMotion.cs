using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 07 U6] Who does what in a minute, from what the server sent (the frames' holder `h`, and the events:
    /// README appendix A), never from the tactics. Pure: the same minute gives the same moves in every view and replay.
    /// MatchScene starts each move so that its contact (takes.json) falls on the frame the ball is met, and draws it.
    /// <list type="bullet">
    /// <item>The holder of a frame whose ball then travels 3 m or more passes it (a header when the ball is in the air).</item>
    /// <item>An attack's shooter shoots from the frame he is nearest the ball (a power shot from 20 m or more); when the
    /// frames never bring him near it, the last kick before the ball's end is the shot.</item>
    /// <item>Its keeper, when it ends saved or in a goal, goes for the ball where it reaches him (MatchScene picks the dive
    /// or the catch from where the ball is to him).</item>
    /// <item>A foul's victim falls where the two are nearest, the foul's player slides in; a card's player protests and the
    /// referee shows it; the scorer celebrates; the shooter who missed holds his head.</item>
    /// </list>
    /// </summary>
    public static class PlayerMotion
    {
        /// <summary>One move: whose (a player's id, or Referee), which (a state of Player.controller, or Dive), and when.</summary>
        public sealed class Cue
        {
            public string Id, Move;
            /// <summary>Where in the minute, in frames (2.5 is half way from frame 2 to 3).</summary>
            public float At;
            /// <summary>At is the move's contact (it starts earlier by its contact); otherwise the move starts at At.</summary>
            public bool OnContact;
            /// <summary>For a Dive: the ball's frame, so its side and height are measured there.</summary>
            public int BallFrame;
            /// <summary>For a Dive into a goal: he is beaten, so he dives and his hands do not find the ball.</summary>
            public bool Beaten;
            /// <summary>For a Dive: the frame of the shot, so he faces where it came from.</summary>
            public int ShotFrame;

            public override string ToString() => $"{Id} {Move} @{At:0.0}";
        }

        public const string Dive = "dive", Referee = "referee";
        /// <summary>A ball that goes this far (dm) after its holder's frame has been kicked.</summary>
        public const float Kicked = 30f;
        /// <summary>A ball this high (dm) is headed, not kicked.</summary>
        public const float Headed = 10f;
        /// <summary>A shooter this near the ball (dm) is the one who strikes it.</summary>
        public const float Near = 30f;
        /// <summary>From this far out (dm) a shot is a power shot.</summary>
        public const float Far = 200f;

        static readonly string[] Celebrations = { "celebrate_wings", "celebrate_fist", "celebrate_knee_slide" };

        public static List<Cue> Cues(MatchMinute m)
        {
            var cues = new List<Cue>();
            int n = m.Frames.Count;
            if (n < 2) return cues;
            int last = n - 1;

            // passes: a holder whose ball then travels
            for (int i = 0; i < last; i++)
            {
                var f = m.Frames[i];
                if (string.IsNullOrEmpty(f.Holder) || !f.Players.ContainsKey(f.Holder)) continue;
                if (Flat(m.Frames[i + 1].Ball - f.Ball) < Kicked) continue;
                cues.Add(new Cue { Id = f.Holder, Move = Kick(f.Ball.z >= Headed, Right(m, i, f.Holder), "pass"), At = i, OnContact = true });
            }

            foreach (var e in m.Events)
            {
                string type = MiniJson.Str(e, "type");
                if (type == "attack") Attack(m, e, cues);
                else if (type == "goal")
                {
                    string scorer = MiniJson.Str(e, "scorer", null);
                    if (scorer != null) cues.Add(new Cue { Id = scorer, Move = Celebrations[Hash(m.Tick, 0, scorer) % Celebrations.Length], At = last });
                }
                else if (type == "foul") Foul(m, e, cues);
                else if (type == "card")
                {
                    string player = MiniJson.Str(e, "player", null);
                    if (player != null) cues.Add(new Cue { Id = player, Move = "protest", At = Mathf.Max(0, last - 1) });
                    cues.Add(new Cue { Id = Referee, Move = "ref_card", At = Mathf.Max(0, last - 1) });
                }
            }
            // one move a player at a time: a later, more telling one (a shot) replaces his pass at the same frame
            cues.Sort((a, b) => a.At.CompareTo(b.At));
            for (int i = cues.Count - 1; i > 0; i--)
                for (int j = i - 1; j >= 0; j--)
                    if (cues[j].Id == cues[i].Id && Mathf.Abs(cues[j].At - cues[i].At) < 0.75f)
                    {
                        if (Rank(cues[i].Move) >= Rank(cues[j].Move)) cues.RemoveAt(j);
                        else cues.RemoveAt(i);
                        break;
                    }
            return cues;
        }

        static void Attack(MatchMinute m, Dictionary<string, object> e, List<Cue> cues)
        {
            string result = MiniJson.Str(e, "result"), shooter = MiniJson.Str(e, "shooter", null);
            if (shooter == null || !(result == "goal" || result == "saved" || result == "missed" || result == "blocked")) return;
            int k = Nearest(m, shooter, out float d);
            if (k < 0 || d > Near)
            {
                // the frames put someone else on the ball for the strike (the event's shooter is never near it): the
                // picture follows the frames, so the shot is the last kick before the ball's end
                k = -1;
                for (int i = m.Frames.Count - 2; i >= 0 && k < 0; i--)
                {
                    var h = m.Frames[i].Holder;
                    if (!string.IsNullOrEmpty(h) && m.Frames[i].Players.ContainsKey(h) && Flat(m.Frames[i + 1].Ball - m.Frames[i].Ball) >= Kicked)
                    {
                        k = i;
                        shooter = h;
                    }
                }
                if (k < 0) return;
            }
            var f = m.Frames[k];
            float toGoal = Mathf.Min(Mathf.Abs(f.Ball.x), Mathf.Abs(1050f - f.Ball.x));
            bool header = f.Ball.z >= Headed;
            cues.Add(new Cue { Id = shooter, Move = Kick(header, Right(m, k, shooter), toGoal >= Far ? "shot_power" : "shot"), At = k, OnContact = true });
            int last = m.Frames.Count - 1;
            if (result == "missed") cues.Add(new Cue { Id = shooter, Move = "despair_hands_head", At = last });

            string keeper = MiniJson.Str(e, "keeper", null);
            if (keeper == null || !(result == "saved" || result == "goal") || k >= last) return;
            // where the ball reaches him: the first frame after the shot it is nearest him
            int j = k + 1;
            float best = float.MaxValue;
            for (int i = k + 1; i <= last; i++)
            {
                if (!m.Frames[i].Players.TryGetValue(keeper, out var at)) continue;
                float dd = Vector2.Distance(at, new Vector2(m.Frames[i].Ball.x, m.Frames[i].Ball.y));
                if (dd < best) { best = dd; j = i; }
            }
            cues.Add(new Cue { Id = keeper, Move = Dive, At = j, OnContact = true, BallFrame = j, ShotFrame = k, Beaten = result == "goal" });
        }

        static void Foul(MatchMinute m, Dictionary<string, object> e, List<Cue> cues)
        {
            string player = MiniJson.Str(e, "player", null), victim = MiniJson.Str(e, "victim", null);
            if (player == null || victim == null) return;
            int at = -1;
            float best = float.MaxValue;
            for (int i = 0; i < m.Frames.Count; i++)
            {
                var f = m.Frames[i];
                if (!f.Players.TryGetValue(player, out var a) || !f.Players.TryGetValue(victim, out var b)) continue;
                float dd = Vector2.Distance(a, b);
                if (dd < best) { best = dd; at = i; }
            }
            if (at < 0) return;
            // fouled as he plays the ball: the ball leaves his foot, then he goes down
            bool played = cues.Exists(c => c.Id == victim && c.OnContact && Mathf.Abs(c.At - at) < 0.75f);
            cues.Add(new Cue { Id = victim, Move = "fall", At = played ? Mathf.Min(m.Frames.Count - 1, at + 0.8f) : at, OnContact = false });
            if (best < 25f) cues.Add(new Cue { Id = player, Move = Right(m, at, player) ? "slide_tackle" : "slide_tackle_l", At = at, OnContact = true });
        }

        /// <summary>The frame a player is nearest the ball before the last (where he can strike it), and how near (dm).</summary>
        static int Nearest(MatchMinute m, string id, out float d)
        {
            int k = -1;
            d = float.MaxValue;
            for (int i = 0; i < m.Frames.Count - 1; i++)
            {
                var f = m.Frames[i];
                if (!f.Players.TryGetValue(id, out var at)) continue;
                float dd = Vector2.Distance(at, new Vector2(f.Ball.x, f.Ball.y));
                if (dd <= d) { d = dd; k = i; }     // the later of two as near: the strike, not the first touch
            }
            return k;
        }

        /// <summary>
        /// The keeper's answer to a ball at local (in his own space: +x his right, +y up, +z ahead, metres): a catch when
        /// it comes at his body (unless he is beaten), else a dive to its side, high when it is above his waist.
        /// </summary>
        public static string DiveFor(Vector3 local, bool beaten = false)
        {
            // beaten (a goal): never a catch, he goes the ball's way
            if (!beaten && Mathf.Abs(local.x) < 1.0f && local.y < 1.8f) return "keeper_catch";
            return "keeper_dive_" + (local.x > 0f ? "r" : "l") + (local.y >= 1.0f ? "_high" : "_low");
        }

        static string Kick(bool header, bool right, string kick) => header ? "header" : right ? kick : kick + "_l";

        /// <summary>Which foot: the right seven times in ten, from the minute, the frame and the player (the same in every view).</summary>
        static bool Right(MatchMinute m, int frame, string id) => Hash(m.Tick, frame, id) % 10 < 7;

        static int Hash(int tick, int frame, string id)
        {
            unchecked
            {
                int h = tick * 7919 + frame * 104729;
                foreach (char c in id) h = h * 31 + c;
                return h & 0x7fffffff;
            }
        }

        /// <summary>Which of two moves of a player at the same moment shows: a shot over a pass, a fall over anything.</summary>
        static int Rank(string move) =>
            move == "fall" ? 5 : move.StartsWith("shot") ? 4 : move == "header" ? 3 : move.StartsWith("slide") ? 3 : move == Dive ? 4 : 1;

        static float Flat(Vector3 v) => new Vector2(v.x, v.y).magnitude;
    }
}
