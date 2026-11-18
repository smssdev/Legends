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
        /// <summary>[Sprint 09 U1] The match's seed: the director's crowd and fights vary by it, as the cartoon's (MinutePlan).</summary>
        public int Seed = 1;
        /// <summary>[Sprint 08 U4] The stadium's light: night, dusk or day (the page's, or the /scene route's by the kick-off's hour).</summary>
        public string Light = "night";

        /// <summary>
        /// {clubs: {home, away}, players: {home: [...], away: [...]}, tick_ms}. The same shape the sample recording
        /// gives once its match object and first minute are put together (SamplePlayback.Setup).
        /// </summary>
        static bool? Flag(object o, string key) =>
            o is Dictionary<string, object> d && d.TryGetValue(key, out var v) && v is bool b ? b : (bool?)null;

        public static MatchSetup From(object json)
        {
            var setup = new MatchSetup();
            var clubs = MiniJson.Obj(json, "clubs");
            setup.Home = ClubKit.From(MiniJson.Obj(clubs, "home"));
            setup.Away = ClubKit.From(MiniJson.Obj(clubs, "away"));
            setup.TickMs = (int)MiniJson.Int(json, "tick_ms", 3000);
            setup.Seed = (int)MiniJson.Int(json, "seed", 1);
            setup.Light = MiniJson.Str(json, "light", "night");
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
                        // the scene route says starter; the live minutes' teams say on
                        Starter = Flag(p, "starter") ?? Flag(p, "on") ?? true,
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
        /// <summary>[Sprint 06 U6] The shirt's pattern (App\Data\KitPattern; null is plain) and the change kit, if the club has one.</summary>
        public string Pattern, AwayPattern;
        public bool HasAwayKit;
        public Color AwayColor = Color.white;

        public static ClubKit From(Dictionary<string, object> club)
        {
            var kit = new ClubKit { Code = MiniJson.Str(club, "code"), Pattern = MiniJson.Str(club, "pattern", null) };
            ColorUtility.TryParseHtmlString(MiniJson.Str(club, "primary", "#FFFFFF"), out kit.Primary);
            ColorUtility.TryParseHtmlString(MiniJson.Str(club, "secondary", "#000000"), out kit.Secondary);
            var away = MiniJson.Obj(club, "away_kit");
            if (away != null && ColorUtility.TryParseHtmlString(MiniJson.Str(away, "color", ""), out kit.AwayColor))
            {
                kit.HasAwayKit = true;
                kit.AwayPattern = MiniJson.Str(away, "pattern", null);
            }
            return kit;
        }
    }

    public sealed class PlayerInfo
    {
        public string Id;
        public int Number;
        public bool Keeper, Home;
        /// <summary>[Sprint 06 U8] On the pitch at kick-off; the others wait on the bench.</summary>
        public bool Starter = true;
    }

    /// <summary>One minute of play: its key frames (six, ten in a busy minute), the shot and how long it lasts, the score.</summary>
    public sealed class MatchMinute
    {
        public int Tick, Period, Minute, Added, HomeGoals, AwayGoals, Ms;
        public string Moment = "quiet";
        /// <summary>[Sprint 26 U1] How each coach feels after the minute, as the server says (App\Characters\Mood).</summary>
        public string HomeMood = "idle", AwayMood = "idle";
        public bool Finished;
        /// <summary>[Sprint 11 W3] How far into the minute the page already is (s): a minute it started before the scene got it.</summary>
        public double Into;
        public readonly List<Frame> Frames = new List<Frame>();
        /// <summary>[Sprint 09 U1] The minute's story from the server (MomentStory): the scene the director tells it with.</summary>
        public Shots.MinutePlan.Story Story = new Shots.MinutePlan.Story();
        /// <summary>[Sprint 07 U6] The minute's events as the server sent them (README appendix A): who does what (PlayerMotion).</summary>
        public readonly List<Dictionary<string, object>> Events = new List<Dictionary<string, object>>();

        public static MatchMinute From(object json, int tickMs)
        {
            var m = new MatchMinute
            {
                Tick = (int)MiniJson.Int(json, "tick"),
                Period = (int)MiniJson.Int(json, "period", 1),
            };
            if (json is Dictionary<string, object> d && d.TryGetValue("finished", out var f) && f is bool done) m.Finished = done;
            if (json is Dictionary<string, object> di && di.TryGetValue("into", out var into) && (into is double || into is long)) m.Into = System.Math.Max(0, System.Convert.ToDouble(into));
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
            var story = MiniJson.Obj(json, "story");
            if (story != null)
                m.Story = new Shots.MinutePlan.Story
                {
                    Scene = MiniJson.Str(story, "scene", null),
                    Side = MiniJson.Str(story, "side", "home"),
                    Goal = story.TryGetValue("goal", out var g) && g is bool goal && goal,
                    Data = MiniJson.Obj(story, "data") ?? new Dictionary<string, object>(),
                };
            foreach (var ev in MiniJson.Arr(json, "events") ?? new List<object>())
                if (ev is Dictionary<string, object> e) m.Events.Add(e);
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
                foreach (var o in MiniJson.Arr(fr, "r") ?? new List<object>())
                {
                    var xy = o as List<object>;
                    if (xy != null && xy.Count == 2)
                        frame.Officials.Add(new Vector2(System.Convert.ToSingle(xy[0]), System.Convert.ToSingle(xy[1])));
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
        /// <summary>[Sprint 31 D1] The referee, the far assistant and the near one (none in older recordings).</summary>
        public readonly List<Vector2> Officials = new List<Vector2>();
    }
}
