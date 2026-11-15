using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// Draws the match: takes the setup once and every minute after it, and moves the players and the ball between
    /// the server's key frames (six, ten in a busy minute) over the minute's length. [Sprint 06 U8] The players are
    /// Legends' own (PlayerArt, PlayerLook): each with his look from his id, his side's kit and his number, the keepers
    /// in theirs, the substitutes at their bench in bibs, and the referee and his assistants from the frames. Without
    /// PlayerArt (a bare project) they are simple shapes in their club's colours, as before.
    /// </summary>
    public sealed class MatchScene : MonoBehaviour
    {
        [Tooltip("Material the kits are made from (a copy per team).")]
        public Material playerMaterial;
        [Tooltip("Material of the ball.")]
        public Material ballMaterial;
        [Tooltip("The contact shadows under the boots and the ball (Players/Shaders/ContactShadow.shader); none without it.")]
        public Material shadowMaterial;

        /// <summary>[Sprint 06, the owner 2026-11-05: "a real ball"] A real ball's size: 22 cm across.</summary>
        public const float BallRadius = 0.11f;
        ContactShadows contacts;
        Vector3 lastBall, spinAxis = Vector3.right;
        bool rolled;

        public MatchSetup Setup { get; private set; }
        public MatchMinute Current { get; private set; }
        /// <summary>[Sprint 26 U1] The coaches on the bench, if the scene has them.</summary>
        public BenchCoaches bench;
        public Transform Ball { get; private set; }

        readonly Queue<MatchMinute> queue = new Queue<MatchMinute>();
        readonly Dictionary<string, Transform> players = new Dictionary<string, Transform>();
        readonly Dictionary<string, Seat> seats = new Dictionary<string, Seat>();
        readonly List<Transform> officials = new List<Transform>();
        float elapsedMs;

        /// <summary>How high a body's origin stands: a capsule's centre 0.9 m up, a real player's feet on the grass.</summary>
        public float BodyLift { get; private set; } = 0.9f;

        /// <summary>A real player's kits (his side's, and the bib he wears at the bench), where he waits, and whether he plays.</summary>
        sealed class Seat
        {
            public PlayerLook Look;
            public KitColours Kit, Bib;
            public int Number;
            public bool Home;
            public Vector3? Bench;     // his seat, given the first time he sits
            public bool OnPitch = true;
        }

        /// <summary>Where each bench starts, in the scene's metres: 3 m behind the near touchline, in front of the boards (5 m), either side of the coaches.</summary>
        public static readonly Vector3 HomeBench = new Vector3(-11.5f, 0, -37f), AwayBench = new Vector3(11.5f, 0, -37f);
        /// <summary>The seats run away from the coaches (BenchCoaches, x = -9 and 9): the substitutes first, then whoever leaves.</summary>
        public const float SeatStep = 0.8f;
        int homeSeats, awaySeats;

        public void Begin(MatchSetup setup)
        {
            foreach (var t in players.Values) Destroy(t.gameObject);
            foreach (var t in officials) Destroy(t.gameObject);
            players.Clear();
            seats.Clear();
            officials.Clear();
            queue.Clear();
            Current = null;
            Setup = setup;
            if (bench != null) bench.Setup(setup.HomeLook, setup.AwayLook);
            if (contacts == null && shadowMaterial != null) contacts = ContactShadows.On(gameObject, shadowMaterial);
            if (contacts != null) contacts.Clear();
            rolled = false;

            var art = PlayerArt.Load();
            if (art != null && art.models != null && art.models.Length == PlayerLook.Builds.Length && art.models[0] != null)
                Dress(setup, art);
            else
                Shapes(setup);

            if (Ball == null)
            {
                var ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                ball.name = "Ball";
                ball.transform.SetParent(transform, false);
                ball.transform.localScale = Vector3.one * BallRadius * 2f;   // a real ball, rolling on the grass (Roll)
                if (ballMaterial != null) ball.GetComponent<Renderer>().sharedMaterial = ballMaterial;
                Destroy(ball.GetComponent<Collider>());
                Ball = ball.transform;
            }
            if (contacts != null) contacts.TrackBall(Ball, BallRadius);
        }

        /// <summary>[Sprint 06 U8] Legends' players, the keepers and the officials, each dressed by the server's colours.</summary>
        void Dress(MatchSetup setup, PlayerArt art)
        {
            BodyLift = 0f;
            var (home, away) = KitColours.ForMatch(setup.Home, setup.Away);
            var (homeKeeper, awayKeeper) = KitColours.Keepers(home.Shirt, away.Shirt);
            var refs = KitColours.Officials(home.Shirt, away.Shirt, homeKeeper.Shirt, awayKeeper.Shirt);
            homeSeats = awaySeats = 0;
            foreach (var p in setup.Players)
            {
                var kit = p.Keeper ? (p.Home ? homeKeeper : awayKeeper) : p.Home ? home : away;
                var bib = KitColours.Bib(kit);
                var look = art.Spawn(PlayerLook.From(p.Id), transform, kit, p.Number, p.Keeper);
                look.name = (p.Home ? "H" : "A") + p.Number + " #" + p.Id;
                var seat = new Seat { Look = look, Kit = kit, Bib = bib, Number = p.Number, Home = p.Home };
                if (!p.Starter) Sit(seat);
                players[p.Id] = look.transform;
                seats[p.Id] = seat;
                if (contacts != null) contacts.Track(look.transform);
            }
            for (int i = 0; i < 3; i++)
            {
                var official = art.Spawn(PlayerLook.From("official-" + i), transform, refs, -1);
                official.name = i == 0 ? "Referee" : i == 1 ? "Far assistant" : "Near assistant";
                if (i > 0) Flag(official.transform);
                official.gameObject.SetActive(false);
                officials.Add(official.transform);
                if (contacts != null) contacts.Track(official.transform);
            }
        }

        /// <summary>At his bench in his bib (a substitute, or a player who has left the pitch).</summary>
        void Sit(Seat seat)
        {
            seat.OnPitch = false;
            seat.Look.Dress(seat.Bib, seat.Number);
            if (seat.Bench == null)
            {
                int n = seat.Home ? homeSeats++ : awaySeats++;
                seat.Bench = seat.Home ? HomeBench + Vector3.left * SeatStep * n : AwayBench + Vector3.right * SeatStep * n;
            }
            seat.Look.transform.localPosition = seat.Bench.Value;
            seat.Look.transform.localRotation = Quaternion.identity;   // facing the pitch
            var stride = seat.Look.GetComponent<PlayerStride>();
            if (stride != null) stride.Restart();
        }

        /// <summary>The assistant's flag in his right hand, in the trim's gold.</summary>
        public static void Flag(Transform official)
        {
            Transform hand = null;
            foreach (var t in official.GetComponentsInChildren<Transform>(true)) if (t.name == "hand_r") hand = t;
            if (hand == null) return;
            var stick = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Drop(stick.GetComponent<Collider>());
            stick.name = "Flag";
            stick.transform.SetParent(hand, false);
            stick.transform.localScale = new Vector3(0.02f, 0.25f, 0.02f);
            var cloth = GameObject.CreatePrimitive(PrimitiveType.Cube);
            Drop(cloth.GetComponent<Collider>());
            cloth.transform.SetParent(stick.transform, false);
            cloth.transform.localScale = new Vector3(15f, 0.9f, 1f);
            cloth.transform.localPosition = new Vector3(7f, 0.55f, 0);
            var lit = Shader.Find("Universal Render Pipeline/Lit");
            if (lit != null)
            {
                var m = new Material(lit);
                m.SetColor("_BaseColor", KitColours.Gold);
                cloth.GetComponent<Renderer>().sharedMaterial = m;
            }
        }

        /// <summary>Destroy in play, at once in the editor (the capture of the officials runs outside play).</summary>
        static void Drop(Object o)
        {
            if (Application.isPlaying) Destroy(o); else DestroyImmediate(o);
        }

        /// <summary>Simple shapes in the club's colours, when the project has no PlayerArt (the scene before Sprint 06).</summary>
        void Shapes(MatchSetup setup)
        {
            BodyLift = 0.9f;
            var home = Kit(setup.Home.Primary);
            // The away side changes to its second colour when the first is too close to the home kit.
            var awayColor = KitColours.Close(setup.Home.Primary, setup.Away.Primary) ? setup.Away.Secondary : setup.Away.Primary;
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

        /// <summary>
        /// A still: the scene stops on minute m at progress t (0..1), everyone facing his way at once. For the pictures
        /// (Editor/Capture.cs, the kits of five matches); playing on needs a Push.
        /// </summary>
        public void Hold(MatchMinute m, float t)
        {
            queue.Clear();
            Current = null;
            Draw(m, t, true);
        }

        void Draw(MatchMinute m, float t, bool snap = false)
        {
            float turn = snap ? 1f : 10f * Time.deltaTime;
            if (m.Frames.Count == 0) return;
            Segment(m.Frames.Count, t, out int i, out float k);
            var a = m.Frames[i];
            var b = m.Frames[Mathf.Min(i + 1, m.Frames.Count - 1)];
            var pf = i > 0 ? m.Frames[i - 1] : null;
            var nf = i + 2 < m.Frames.Count ? m.Frames[i + 2] : null;
            bool flip = Flipped(m.Period);
            // [Sprint 07 U4] how long this stretch between two frames lasts on screen, for each player's speed
            float span = Mathf.Max(0.05f, m.Ms / 1000f / Mathf.Max(1, m.Frames.Count - 1));
            float dt = snap ? 0f : Time.deltaTime;

            foreach (var kv in players)
            {
                // As the golden vectors: a player in frame i only (sent off, replaced) stays where he was, and one who
                // is not in frame i is not drawn until his own frame.
                bool inA = a.Players.ContainsKey(kv.Key);
                if (seats.TryGetValue(kv.Key, out var seat))
                {
                    // A real player off the pitch waits at his bench in his bib; back on, he wears his side's kit.
                    if (!inA)
                    {
                        if (seat.OnPitch) Sit(seat);
                        continue;
                    }
                    if (!seat.OnPitch)
                    {
                        seat.OnPitch = true;
                        seat.Look.Dress(seat.Kit, seat.Number);
                    }
                }
                else
                {
                    kv.Value.gameObject.SetActive(inA);
                    if (!inA) continue;
                }
                var spot = SamplePlayer(pf, a, b, nf, kv.Key, k);
                var ahead = SamplePlayer(pf, a, b, nf, kv.Key, Mathf.Min(1f, k + 0.05f));
                var pos = World(spot, flip);
                var dir = World(ahead, flip) - pos;
                kv.Value.localPosition = pos + Vector3.up * BodyLift;
                if (dir.sqrMagnitude > 0.0004f)
                    kv.Value.localRotation = Quaternion.Slerp(kv.Value.localRotation, Quaternion.LookRotation(dir), turn);
                if (seat != null) Pace(seat.Look, pf, a, b, nf, kv.Key, k, flip, span, dt, snap);
            }

            // [Sprint 31 D1] The officials follow the ball, as the frames place them; older recordings have none.
            for (int o = 0; o < officials.Count; o++)
            {
                bool has = a.Officials.Count > o && b.Officials.Count > o;
                officials[o].gameObject.SetActive(has);
                if (!has) continue;
                var at = World(Vector2.Lerp(a.Officials[o], b.Officials[o], k), flip);
                var to = World(b.Officials[o], flip) - World(a.Officials[o], flip);
                officials[o].localPosition = at;
                var walk = officials[o].GetComponent<PlayerStride>();
                if (walk != null) walk.Go(new Vector2(to.x, to.z).magnitude / span, dt, snap);
                // the referee faces where he runs; the assistants face the pitch from their touchline
                var face = o == 0 && to.sqrMagnitude > 0.0004f ? to : (at.z > 0 ? Vector3.back : Vector3.forward);
                officials[o].localRotation = Quaternion.Slerp(officials[o].localRotation, Quaternion.LookRotation(face), turn);
            }

            var ball = SampleBall(pf, a, b, nf, k);
            Roll(World(new Vector2(ball.x, ball.y), flip) + Vector3.up * (BallRadius + ball.z / 10f));
        }

        /// <summary>
        /// [Sprint 07 U4] A player's speed on the grass at k between frames a and b (m/s on screen: the curve's step over
        /// the time it takes), to his stride. Fast-forward minutes go faster than any stride: Gait caps the pace.
        /// </summary>
        static void Pace(PlayerLook look, Frame p, Frame a, Frame b, Frame n, string id, float k, bool flip, float span, float dt, bool snap)
        {
            var stride = look.GetComponent<PlayerStride>();
            if (stride == null) return;
            stride.Go(Speed(p, a, b, n, id, k, flip, span), dt, snap);
        }

        /// <summary>[Sprint 07 U4] How fast a player goes at k between frames a and b, in m/s when the stretch lasts span seconds.</summary>
        public static float Speed(Frame p, Frame a, Frame b, Frame n, string id, float k, bool flip, float span)
        {
            const float h = 0.025f;
            float k0 = Mathf.Max(0f, k - h), k1 = Mathf.Min(1f, k + h);
            if (k1 - k0 < 1e-4f) return 0f;
            var d = World(SamplePlayer(p, a, b, n, id, k1), flip) - World(SamplePlayer(p, a, b, n, id, k0), flip);
            return d.magnitude / ((k1 - k0) * span);
        }

        /// <summary>
        /// [Sprint 06, the owner 2026-11-05: "a real ball, not a robot's"] The ball to its spot, turning as a real one
        /// does: on the grass it rolls exactly as far as it travels (its turn = the distance / its radius, about the axis
        /// across its path); in the air it keeps the spin it left the grass with, a little slower. A jump of more than 8 m
        /// in one frame (a new minute, a still) is a cut, not a roll.
        /// </summary>
        void Roll(Vector3 to)
        {
            if (rolled)
            {
                var d = to - lastBall;
                d.y = 0f;
                float dist = d.magnitude;
                if (dist > 1e-4f && dist < 8f)
                {
                    bool air = to.y > BallRadius + 0.05f;
                    var axis = Vector3.Cross(Vector3.up, d / dist);
                    if (!air) spinAxis = axis;
                    float turn = dist / BallRadius * Mathf.Rad2Deg * (air ? 0.6f : 1f);
                    Ball.Rotate(transform.TransformDirection(air ? spinAxis : axis), turn, Space.World);
                }
            }
            lastBall = to;
            rolled = true;
            Ball.localPosition = to;
        }

        /// <summary>How far the ball turns rolling `metres` on the grass, in degrees (the tests check the roll with it).</summary>
        public static float RollDegrees(float metres) => metres / BallRadius * Mathf.Rad2Deg;

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

    }
}
