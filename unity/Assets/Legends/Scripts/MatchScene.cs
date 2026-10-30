using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// Draws the match: takes the setup once and every minute after it, and moves the players and the ball between
    /// the server's six key frames over the minute's length. The first step towards the full scene (README.md 7):
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
            bool flip = Flipped(m.Period);

            foreach (var kv in players)
            {
                // As the golden vectors: a player in frame i only (sent off, replaced) stays where he was, and one who
                // is not in frame i is not drawn until his own frame.
                bool inA = a.Players.TryGetValue(kv.Key, out var pa);
                bool inB = b.Players.TryGetValue(kv.Key, out var pb);
                kv.Value.gameObject.SetActive(inA);
                if (!inA) continue;
                if (!inB) pb = pa;
                var from = World(pa, flip);
                var to = World(pb, flip);
                var pos = Vector3.Lerp(from, to, k);
                var dir = to - from;
                kv.Value.localPosition = pos + Vector3.up * 0.9f;
                if (dir.sqrMagnitude > 0.0004f)
                    kv.Value.localRotation = Quaternion.Slerp(kv.Value.localRotation, Quaternion.LookRotation(dir), 10f * Time.deltaTime);
            }

            var ball = Vector3.Lerp(a.Ball, b.Ball, k);
            Ball.localPosition = World(new Vector2(ball.x, ball.y), flip) + Vector3.up * (0.16f + ball.z / 10f);
        }

        /// <summary>How far through the current minute's shot, 0 to 1 (the tests compare the scene with the frames at it).</summary>
        public float Progress => Current == null ? 0f : Mathf.Clamp01(elapsedMs / Current.Ms);

        /// <summary>
        /// Where a minute's progress t (0..1) falls among its key frames: between frame i and i + 1, by k (0..1).
        /// Linear, exactly as the cartoon player and docs/api/frame-golden.json (Sprint 20 S5, the owner's decision):
        /// past the end the last frame holds, never an extrapolation.
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
