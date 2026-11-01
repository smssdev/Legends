using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// What the server sends, read into plain classes (README.md, appendix A). The scene draws only this:
    /// no result and no movement is decided in Unity.
    /// </summary>
    public sealed class MatchSetup
    {
        public ClubKit Home, Away;
        public readonly List<PlayerInfo> Players = new List<PlayerInfo>();
        /// <summary>[Sprint 26 U1] Each human coach's look on the bench (C1 to C3); empty for a club with no coach.</summary>
        public string HomeLook = "", AwayLook = "";
        public int TickMs = 3000;

        /// <summary>
        /// {clubs: {home, away}, players: {home: [...], away: [...]}, tick_ms}. The same shape the sample recording
        /// gives once its match object and first minute are put together (SamplePlayback.Setup).
        /// </summary>
        public static MatchSetup From(object json)
        {
            var setup = new MatchSetup();
            var clubs = MiniJson.Obj(json, "clubs");
            setup.Home = ClubKit.From(MiniJson.Obj(clubs, "home"));
            setup.Away = ClubKit.From(MiniJson.Obj(clubs, "away"));
            setup.TickMs = (int)MiniJson.Int(json, "tick_ms", 3000);
            var looks = MiniJson.Obj(json, "coach_looks");
            setup.HomeLook = MiniJson.Str(looks, "home");
            setup.AwayLook = MiniJson.Str(looks, "away");
            var players = MiniJson.Obj(json, "players");
            foreach (var side in new[] { "home", "away" })
            {
                foreach (var p in MiniJson.Arr(players, side) ?? new List<object>())
                {
                    setup.Players.Add(new PlayerInfo
                    {
                        Id = MiniJson.Str(p, "id"),
                        Number = (int)MiniJson.Int(p, "no"),
                        Keeper = MiniJson.Str(p, "pos") == "GK",
                        Home = side == "home",
                    });
                }
            }
            return setup;
        }
    }

    public sealed class ClubKit
    {
        public string Code = "";
        public Color Primary = Color.white, Secondary = Color.black;

        public static ClubKit From(Dictionary<string, object> club)
        {
            var kit = new ClubKit { Code = MiniJson.Str(club, "code") };
            ColorUtility.TryParseHtmlString(MiniJson.Str(club, "primary", "#FFFFFF"), out kit.Primary);
            ColorUtility.TryParseHtmlString(MiniJson.Str(club, "secondary", "#000000"), out kit.Secondary);
            return kit;
        }
    }

    public sealed class PlayerInfo
    {
        public string Id;
        public int Number;
        public bool Keeper, Home;
    }

    /// <summary>One minute of play: the six key frames, the shot and how long it lasts, the score.</summary>
    public sealed class MatchMinute
    {
        public int Tick, Period, Minute, Added, HomeGoals, AwayGoals, Ms;
        public string Moment = "quiet";
        /// <summary>[Sprint 26 U1] How each coach feels after the minute, as the server says (App\Characters\Mood).</summary>
        public string HomeMood = "idle", AwayMood = "idle";
        public bool Finished;
        public readonly List<Frame> Frames = new List<Frame>();

        public static MatchMinute From(object json, int tickMs)
        {
            var m = new MatchMinute
            {
                Tick = (int)MiniJson.Int(json, "tick"),
                Period = (int)MiniJson.Int(json, "period", 1),
            };
            if (json is Dictionary<string, object> d && d.TryGetValue("finished", out var f) && f is bool done) m.Finished = done;
            var minute = MiniJson.Arr(json, "minute");
            if (minute != null && minute.Count == 2)
            {
                m.Minute = System.Convert.ToInt32(minute[0]);
                m.Added = System.Convert.ToInt32(minute[1]);
            }
            var score = MiniJson.Obj(json, "score");
            m.HomeGoals = (int)MiniJson.Int(score, "home");
            m.AwayGoals = (int)MiniJson.Int(score, "away");
            var moment = MiniJson.Obj(json, "moment");
            m.Moment = MiniJson.Str(moment, "kind", "quiet");
            var moods = MiniJson.Obj(json, "moods");
            m.HomeMood = MiniJson.Str(moods, "home", "idle");
            m.AwayMood = MiniJson.Str(moods, "away", "idle");
            m.Ms = (int)MiniJson.Int(moment, "ms", tickMs);
            if (m.Ms <= 0) m.Ms = tickMs;
            foreach (var fr in MiniJson.Arr(json, "frames") ?? new List<object>())
            {
                var frame = new Frame { Holder = MiniJson.Str(fr, "h", null) };
                var ball = MiniJson.Arr(fr, "b");
                // The height may be left out (0), as in the golden vectors [Sprint 31 M1].
                if (ball != null && ball.Count >= 2)
                    frame.Ball = new Vector3(System.Convert.ToSingle(ball[0]), System.Convert.ToSingle(ball[1]), ball.Count > 2 ? System.Convert.ToSingle(ball[2]) : 0f);
                foreach (var kv in MiniJson.Obj(fr, "p") ?? new Dictionary<string, object>())
                {
                    var xy = kv.Value as List<object>;
                    if (xy != null && xy.Count == 2)
                        frame.Players[kv.Key] = new Vector2(System.Convert.ToSingle(xy[0]), System.Convert.ToSingle(xy[1]));
                }
                m.Frames.Add(frame);
            }
            return m;
        }
    }

    /// <summary>A key frame from MatchChoreographer: decimetres on a 1050 x 680 pitch, home attacking +x.</summary>
    public sealed class Frame
    {
        public Vector3 Ball;   // x, y, height
        public readonly Dictionary<string, Vector2> Players = new Dictionary<string, Vector2>();
        public string Holder;
    }
}
