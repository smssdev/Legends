using System.Collections.Generic;

namespace Legends.Shots
{
    /// <summary>
    /// [Sprint 09 U1] Which shot is on air at t seconds into a minute, from its plan (MinutePlan) alone, so every screen
    /// cuts on the same instant: the broadcast camera on the scene (the server's frames), a close shot round the scene's
    /// key moment (the strike, the save, the card), then the director's cutaways in the cartoon's order and lengths, then
    /// a goal's replay window, then the broadcast again. Pure.
    /// </summary>
    public static class ShotList
    {
        public const string Broadcast = "broadcast", Close = "close", Replay = "replay";
        /// <summary>[Sprint 09 U2] The scenes' own cameras: behind the ball, on the line, on the referee, on a player.</summary>
        public const string Spot = "spot", Line = "line", RefereeShot = "referee", PlayerShot = "player";

        /// <summary>
        /// [Sprint 09 U2] The camera a scene is told with outside its close shot (README 7.5): a penalty or a free kick from
        /// behind the ball, the offside trap on its line, the end of a half and the VAR on the referee, an injury on the man
        /// down, the coach's rant on the coach; the rest the broadcast camera.
        /// </summary>
        public static string SceneCamera(string scene) => scene switch
        {
            "penalty" or "freekick" => Spot,
            "trap" or "offside" => Line,
            "whistle" or "var" => RefereeShot,
            "injury" => PlayerShot,
            "rant" or "coach" => "coachReact",
            _ => Broadcast,
        };

        /// <summary>Every camera a scene may be told with (none of them a cutaway).</summary>
        public static readonly HashSet<string> SceneCameras = new HashSet<string> { Broadcast, Close, Replay, Spot, Line, RefereeShot, PlayerShot };

        /// <summary>The scenes whose key moment is a strike at goal or a decision worth a close shot.</summary>
        static readonly HashSet<string> Struck = new HashSet<string>
        {
            "goal", "save", "miss", "blocked", "penalty", "freekick", "var", "clearance", "card", "offside", "foul",
        };

        /// <summary>How long before the key moment the close shot comes in, and how long after it stays (s).</summary>
        public const double Before = 0.7, After = 1.0;

        public struct Shot
        {
            /// <summary>broadcast, close, replay, or a cutaway's name (crowd, coachReact, brawl, tunnel, handshake, meltdown).</summary>
            public string Name;
            /// <summary>The cutaway's data (its side, the coach's look and mood), none for the others.</summary>
            public Dictionary<string, object> Data;
            /// <summary>When it went on air and when it comes off (s into the minute).</summary>
            public double From, To;

            public string Side => Data != null && Data.TryGetValue("side", out var s) && s is string side ? side : "home";
            public override string ToString() => $"{Name} {From:0.00}-{To:0.00}";
        }

        /// <summary>When the scene reaches its key moment (s), as the cartoon times it (timing.ts, the scene played at its rate).</summary>
        public static double KeyAt(MinutePlan.Plan p, MinutePlan.Story s)
        {
            if (string.IsNullOrEmpty(s?.Scene) || !MinutePlan.SceneTime.TryGetValue(s.Scene, out var time)) return 0;
            return time.key / time.length * p.SceneT;
        }

        /// <param name="key">
        /// When the scene's key moment really happens in Unity (s): the strike in the server's frames (MatchScene.KeyMoment,
        /// from PlayerMotion), which the cartoon's clip times for itself (KeyAt). None: the cartoon's.
        /// </param>
        public static Shot At(MinutePlan.Plan p, MinutePlan.Story s, double t, double? key = null)
        {
            if (p == null || s == null || string.IsNullOrEmpty(s.Scene)) return new Shot { Name = Broadcast, From = 0, To = p?.Total ?? 0 };
            if (t < p.SceneT)
            {
                // the scene's own camera (with its side, for a coach), and a close shot round its strike or call
                string own = SceneCamera(s.Scene);
                var data = own == "coachReact" ? new Dictionary<string, object> { ["side"] = s.Side, ["mood"] = s.Scene == "rant" ? "angry" : "worried" } : null;
                // the referee's and the line's cameras are the call itself (the VAR, the trap): no close shot over them
                if (!Struck.Contains(s.Scene) || own == RefereeShot || own == Line || own == "coachReact") return new Shot { Name = own, Data = data, From = 0, To = p.SceneT };
                double k = System.Math.Min(p.SceneT, key ?? KeyAt(p, s)), from = System.Math.Max(0, k - Before), to = System.Math.Min(p.SceneT, k + After);
                if (t >= from && t < to) return new Shot { Name = Close, From = from, To = to };
                return t < from ? new Shot { Name = own, From = 0, To = from } : new Shot { Name = own, From = to, To = p.SceneT };
            }
            double c0 = p.SceneT;
            foreach (var c in p.Cuts)
            {
                if (t < c0 + c.Dur) return new Shot { Name = c.Name, Data = c.Data, From = c0, To = c0 + c.Dur };
                c0 += c.Dur;
            }
            if (p.Replay != null)
            {
                double end = p.Total - 0.8;
                if (t >= p.Replay.At && t < end) return new Shot { Name = Replay, From = p.Replay.At, To = end };
                if (t < p.Replay.At) return new Shot { Name = Broadcast, From = c0, To = p.Replay.At };
                return new Shot { Name = Broadcast, From = end, To = p.Total };
            }
            return new Shot { Name = Broadcast, From = c0, To = p.Total };
        }

        /// <summary>
        /// [Sprint 09 U3] The replay's two angles, as the cartoon's (X41: the goal again from two sides): behind the goal
        /// for its first half, then low from the far touchline. None outside the replay window.
        /// </summary>
        public const string ReplayGoal = "replayGoal", ReplaySide = "replaySide";

        public static string ReplayAngle(Shot shot, double t) =>
            shot.Name != Replay ? null : t < (shot.From + shot.To) / 2 ? ReplayGoal : ReplaySide;

        /// <summary>Every shot of the minute in order (for the tests, and for the pictures).</summary>
        public static List<Shot> All(MinutePlan.Plan p, MinutePlan.Story s, double? key = null)
        {
            var list = new List<Shot>();
            double t = 0;
            while (p != null && t < p.Total)
            {
                var shot = At(p, s, t, key);
                list.Add(shot);
                if (shot.To <= t) break;
                t = shot.To;
            }
            return list;
        }
    }
}
