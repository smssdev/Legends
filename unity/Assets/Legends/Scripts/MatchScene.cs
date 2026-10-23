using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// Draws the match: takes the setup once and every minute after it, and moves the players and the ball between
    /// the server's six key frames over the minute's length. The first step towards the full scene (docs/PLAN.md 7):
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
                ball.transform.localScale = Vector3.one * 0.22f;
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
            }
            elapsedMs += Time.deltaTime * 1000f;
            Draw(Current, Mathf.Clamp01(elapsedMs / Current.Ms));
            if (elapsedMs >= Current.Ms) Current = null;
        }

        void Draw(MatchMinute m, float t)
        {
            if (m.Frames.Count == 0) return;
            float at = t * (m.Frames.Count - 1);
            int i = Mathf.Clamp((int)at, 0, Mathf.Max(0, m.Frames.Count - 2));
            var a = m.Frames[i];
            var b = m.Frames[Mathf.Min(i + 1, m.Frames.Count - 1)];
            float k = Mathf.SmoothStep(0, 1, at - i);
            bool flip = m.Period == 2 || m.Period == 4;   // the ends change at half time

            foreach (var kv in players)
            {
                bool inA = a.Players.TryGetValue(kv.Key, out var pa);
                bool inB = b.Players.TryGetValue(kv.Key, out var pb);
                kv.Value.gameObject.SetActive(inA || inB);
                if (!inA && !inB) continue;
                if (!inA) pa = pb;
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
            Ball.localPosition = World(new Vector2(ball.x, ball.y), flip) + Vector3.up * (0.11f + ball.z / 10f);
        }

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
