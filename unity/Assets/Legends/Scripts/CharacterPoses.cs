using System;
using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// The nine moods of the Legends characters (Resources/CharacterMoods.json, the same file the Blender script
    /// tools/unity/art/characters.py renders from): where the arms, the head and the body are at any moment of a
    /// mood's loop. Plain arithmetic, no scene, so the tests read it directly.
    /// </summary>
    public sealed class CharacterPoses
    {
        /// <summary>Angles in degrees as (x, y): x leans forward when negative, y swings to the screen's left.</summary>
        public struct Pose
        {
            public Vector2 UpperL, ForeL, UpperR, ForeR, Head;
            public float Lift, ShakeX, Sway, Breathe;
            public bool Blink;
        }

        public readonly float Seconds;
        readonly Dictionary<string, Dictionary<string, object>> moods = new Dictionary<string, Dictionary<string, object>>();

        CharacterPoses(object root)
        {
            var o = (Dictionary<string, object>)root;
            Seconds = Num(Get(o, "seconds"), 1f);
            foreach (var kv in (Dictionary<string, object>)o["moods"])
                moods[kv.Key] = (Dictionary<string, object>)kv.Value;
        }

        public static CharacterPoses Parse(string json) => new CharacterPoses(MiniJson.Parse(json));

        public static CharacterPoses Load()
        {
            var file = Resources.Load<TextAsset>("CharacterMoods");
            if (file == null) throw new InvalidOperationException("Resources/CharacterMoods.json is missing");
            return Parse(file.text);
        }

        public IEnumerable<string> Moods => moods.Keys;

        public bool Has(string mood) => mood != null && moods.ContainsKey(mood);

        /// <summary>The pose at t in [0, 1) of the mood's loop; an unknown mood stands idle.</summary>
        public Pose At(string mood, float t)
        {
            var m = Has(mood) ? moods[mood] : moods["idle"];
            var p = new Pose
            {
                UpperL = Pair(Get(m, "up"), t),
                ForeL = Pair(Get(m, "fo"), t),
                Head = Pair(Get(m, "head"), t),
                Lift = Single(Get(m, "lift"), t),
                Sway = Num(Get(m, "sway"), 0) * Mathf.Sin(2 * Mathf.PI * t),
                Breathe = Num(Get(m, "breathe"), 0) * (0.5f - 0.5f * Mathf.Cos(2 * Mathf.PI * t)),
                Blink = Get(m, "blink") is bool b && b && t >= 0.78f && t < 0.86f,
            };
            p.UpperR = Get(m, "upR") != null ? Pair(Get(m, "upR"), t) : new Vector2(p.UpperL.x, -p.UpperL.y);
            p.ForeR = Get(m, "foR") != null ? Pair(Get(m, "foR"), t) : new Vector2(p.ForeL.x, -p.ForeL.y);
            if (Get(m, "shake") is Dictionary<string, object> shake)
                p.ShakeX = Num(Get(shake, "x"), 0) * Mathf.Sin(2 * Mathf.PI * Num(Get(shake, "cycles"), 1) * t);
            return p;
        }

        static object Get(Dictionary<string, object> o, string key) => o.TryGetValue(key, out var v) ? v : null;

        static float Num(object v, float fallback) => v == null ? fallback : Convert.ToSingle(v, System.Globalization.CultureInfo.InvariantCulture);

        /// <summary>How far along a moving value is: sin eases there and back, hop bounces off the ground.</summary>
        static float Phase(Dictionary<string, object> spec, float t)
        {
            float n = Num(Get(spec, "cycles"), 1);
            return Get(spec, "shape") as string == "hop"
                ? Mathf.Abs(Mathf.Sin(Mathf.PI * n * t))
                : 0.5f - 0.5f * Mathf.Cos(2 * Mathf.PI * n * t);
        }

        static Vector2 Vec(object v) => v is List<object> l ? new Vector2(Num(l[0], 0), Num(l[1], 0)) : Vector2.zero;

        static Vector2 Pair(object v, float t)
        {
            if (!(v is Dictionary<string, object> spec)) return Vec(v);
            return Vector2.Lerp(Vec(Get(spec, "from")), Vec(Get(spec, "to")), Phase(spec, t));
        }

        static float Single(object v, float t)
        {
            if (!(v is Dictionary<string, object> spec)) return Num(v, 0);
            return Mathf.Lerp(Num(Get(spec, "from"), 0), Num(Get(spec, "to"), 0), Phase(spec, t));
        }
    }
}
