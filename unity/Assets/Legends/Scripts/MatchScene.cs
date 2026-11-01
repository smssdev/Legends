using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// Draws the match: takes the setup once and every minute after it, and moves the players and the ball between
    /// the server's key frames (six, ten in a busy minute) over the minute's length. The first step towards the full scene (README.md 7):
    /// the players are still simple shapes in their club's colours.
    /// </summary>
    public sealed class MatchScene : MonoBehaviour
    {
        [Tooltip("Material the kits are made from (a copy per team).")]
        public Material playerMaterial;
        [Tooltip("Material of the ball.")]
        public Material ballMaterial;

        public MatchSetup Setup { get; private set; }
        public MatchMinute Current { get; private set; }
        /// <summary>[Sprint 26 U1] The coaches on the bench, if the scene has them.</summary>
        public BenchCoaches bench;
        public Transform Ball { get; private set; }

        readonly Queue<MatchMinute> queue = new Queue<MatchMinute>();
        readonly Dictionary<string, Transform> players = new Dictionary<string, Transform>();
        float elapsedMs;

        public void Begin(MatchSetup setup)
        {
            foreach (var t in players.Values) Destroy(t.gameObject);
            players.Clear();
            queue.Clear();
            Current = null;
            Setup = setup;
            if (bench != null) bench.Setup(setup.HomeLook, setup.AwayLook);

            var home = Kit(setup.Home.Primary);
            // The away side changes to its second colour when the first is too close to the home kit.
            var awayColor = Close(setup.Home.Primary, setup.Away.Primary) ? setup.Away.Secondary : setup.Away.Primary;
            var away = Kit(awayColor);
            var keeper = Kit(new Color(0.2f, 0.2f, 0.22f));
            foreach (var p in setup.Players)
            {
                var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                body.name = (p.Home ? "H" : "A") + p.Number + " #" + p.Id;
                body.transform.SetParent(transform, false);
                body.transform.localScale = new Vector3(0.6f, 0.9f, 0.6f);   // 1.8 m tall
                body.GetComponent<Renderer>().sharedMaterial = p.Keeper ? keeper : p.Home ? home : away;
                Destroy(body.GetComponent<Collider>());
                body.SetActive(false);
                players[p.Id] = body.transform;
            }

            if (Ball == null)
            {
                var ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                ball.name = "Ball";
                ball.transform.SetParent(transform, false);
                ball.transform.localScale = Vector3.one * 0.32f;   // a real ball is 0.22 m: a little bigger reads on TV
                if (ballMaterial != null) ball.GetComponent<Renderer>().sharedMaterial = ballMaterial;
                Destroy(ball.GetComponent<Collider>());
                Ball = ball.transform;
            }
        }

        public void Push(MatchMinute minute) => queue.Enqueue(minute);

        public bool Idle => Current == null && queue.Count == 0;

        void Update()
        {
            if (Current == null)
            {
                if (queue.Count == 0) return;
                Current = queue.Dequeue();
                elapsedMs = 0;
                if (bench != null) bench.Feel(Current.HomeMood, Current.AwayMood);
            }
            elapsedMs += Time.deltaTime * 1000f;
            Draw(Current, Mathf.Clamp01(elapsedMs / Current.Ms));
            if (elapsedMs >= Current.Ms) Current = null;
        }

        void Draw(MatchMinute m, float t)
        {
            if (m.Frames.Count == 0) return;
            Segment(m.Frames.Count, t, out int i, out float k);
            var a = m.Frames[i];
            var b = m.Frames[Mathf.Min(i + 1, m.Frames.Count - 1)];
            var pf = i > 0 ? m.Frames[i - 1] : null;
            var nf = i + 2 < m.Frames.Count ? m.Frames[i + 2] : null;
            bool flip = Flipped(m.Period);

            foreach (var kv in players)
            {
                // As the golden vectors: a player in frame i only (sent off, replaced) stays where he was, and one who
                // is not in frame i is not drawn until his own frame.
                bool inA = a.Players.ContainsKey(kv.Key);
                kv.Value.gameObject.SetActive(inA);
                if (!inA) continue;
                var spot = SamplePlayer(pf, a, b, nf, kv.Key, k);
                var ahead = SamplePlayer(pf, a, b, nf, kv.Key, Mathf.Min(1f, k + 0.05f));
                var pos = World(spot, flip);
                var dir = World(ahead, flip) - pos;
                kv.Value.localPosition = pos + Vector3.up * 0.9f;
                if (dir.sqrMagnitude > 0.0004f)
                    kv.Value.localRotation = Quaternion.Slerp(kv.Value.localRotation, Quaternion.LookRotation(dir), 10f * Time.deltaTime);
            }

            var ball = SampleBall(pf, a, b, nf, k);
            Ball.localPosition = World(new Vector2(ball.x, ball.y), flip) + Vector3.up * (0.16f + ball.z / 10f);
        }

        /// <summary>
        /// [Sprint 31 M1] The tangent at cur from its neighbours (NaN when missing): Catmull-Rom, 0 at a turn, at most 3 x
        /// the smaller step, one-sided at the ends. Exactly as web/src/match/frames.ts and docs/api/frame-golden.json.
        /// </summary>
        public static float Tangent(float prev, float cur, float next)
        {
            bool hp = !float.IsNaN(prev), hn = !float.IsNaN(next);
            if (!hp && !hn) return 0f;
            if (!hp) return next - cur;
            if (!hn) return cur - prev;
            float d0 = cur - prev, d1 = next - cur;
            if (d0 * d1 <= 0f) return 0f;
            float m = (d0 + d1) / 2f, lim = 3f * Mathf.Min(Mathf.Abs(d0), Mathf.Abs(d1));
            return Mathf.Sign(m) * Mathf.Min(Mathf.Abs(m), lim);
        }

        /// <summary>[Sprint 31 M1] One coordinate between a and b: a cubic Hermite curve that never overshoots.</summary>
        public static float Curve(float p, float a, float b, float n, float k)
        {
            float ma = Tangent(p, a, b), mb = Tangent(a, b, n), k2 = k * k, k3 = k2 * k;
            return (2 * k3 - 3 * k2 + 1) * a + (k3 - 2 * k2 + k) * ma + (-2 * k3 + 3 * k2) * b + (k3 - k2) * mb;
        }

        /// <summary>[Sprint 31 M1] The ball's arc: a lofted ball (the next frame in the air) over 15 m rises by its length / 10, at most 6 m.</summary>
        public static float Loft(Vector3 a, Vector3 b)
        {
            if (!(b.z > 0f)) return 0f;
            float d = Vector2.Distance(new Vector2(a.x, a.y), new Vector2(b.x, b.y));
            return d < 150f ? 0f : Mathf.Min(60f, Mathf.Floor(d / 10f));
        }

        /// <summary>[Sprint 31 M1] The ball (x, y, height) between frames a and b, with p before a and n after b (null if none).</summary>
        public static Vector3 SampleBall(Frame p, Frame a, Frame b, Frame n, float k)
        {
            if (ReferenceEquals(a, b)) return a.Ball;
            float N(Frame f, int c) => f == null ? float.NaN : f.Ball[c];
            return new Vector3(
                Curve(N(p, 0), a.Ball.x, b.Ball.x, N(n, 0), k),
                Curve(N(p, 1), a.Ball.y, b.Ball.y, N(n, 1), k),
                Curve(N(p, 2), a.Ball.z, b.Ball.z, N(n, 2), k) + 4f * k * (1f - k) * Loft(a.Ball, b.Ball));
        }

        /// <summary>[Sprint 31 M1] A player's spot between frames a and b (he must be in a; missing from b, he stays).</summary>
        public static Vector2 SamplePlayer(Frame p, Frame a, Frame b, Frame n, string id, float k)
        {
            var pa = a.Players[id];
            if (ReferenceEquals(a, b) || !b.Players.TryGetValue(id, out var pb)) return pa;
            Vector2 pp = default, pn = default;
            bool hp = p != null && p.Players.TryGetValue(id, out pp);
            bool hn = n != null && n.Players.TryGetValue(id, out pn);
            return new Vector2(
                Curve(hp ? pp.x : float.NaN, pa.x, pb.x, hn ? pn.x : float.NaN, k),
                Curve(hp ? pp.y : float.NaN, pa.y, pb.y, hn ? pn.y : float.NaN, k));
        }

        /// <summary>How far through the current minute's shot, 0 to 1 (the tests compare the scene with the frames at it).</summary>
        public float Progress => Current == null ? 0f : Mathf.Clamp01(elapsedMs / Current.Ms);

        /// <summary>
        /// Where a minute's progress t (0..1) falls among its key frames: between frame i and i + 1, by k (0..1).
        /// Exactly as the cartoon player and docs/api/frame-golden.json (Sprint 20 S5); between i and i + 1 the spot
        /// follows Curve (Sprint 31 M1). Past the end the last frame holds, never an extrapolation.
        /// </summary>
        public static void Segment(int frames, float t, out int i, out float k)
        {
            float at = Mathf.Clamp01(t) * (frames - 1);
            i = Mathf.Clamp((int)at, 0, Mathf.Max(0, frames - 2));
            k = frames < 2 ? 0f : Mathf.Clamp01(at - i);
        }

        /// <summary>The ends change at half time, and again in extra time's second half.</summary>
        public static bool Flipped(int period) => period == 2 || period == 4;

        /// <summary>Decimetres on the 1050 x 680 pitch to metres in the scene, the centre spot at the origin.</summary>
        public static Vector3 World(Vector2 dm, bool flip)
        {
            if (flip) dm = new Vector2(1050 - dm.x, 680 - dm.y);
            return new Vector3(dm.x / 10f - 52.5f, 0, 34f - dm.y / 10f);
        }

        Material Kit(Color c)
        {
            var m = new Material(playerMaterial);
            m.color = c;
            return m;
        }

        static bool Close(Color a, Color b)
        {
            return Mathf.Abs(a.r - b.r) + Mathf.Abs(a.g - b.g) + Mathf.Abs(a.b - b.b) < 0.45f;
        }
    }
}
