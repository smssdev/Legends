using System.Collections.Generic;
using Unity.Cinemachine;
using UnityEngine;

namespace Legends.Shots
{
    /// <summary>
    /// [Sprint 09 U1] The broadcast's director: a Cinemachine camera for every shot (the wide broadcast camera following the
    /// ball, the close shot at the scene's key moment, and the cartoon's cutaways: the fans, a coach, a fight, the tunnel,
    /// the handshake, the coach losing it), and a cut between them on the instant ShotList says, from the minute's plan, so
    /// every screen cuts together. MatchScene adds it; the main camera gets the Cinemachine brain (cuts, no blends, as TV).
    /// Draws only.
    /// </summary>
    [RequireComponent(typeof(MatchScene))]
    public sealed class Director : MonoBehaviour
    {
        MatchScene scene;
        CinemachineBrain brain;
        readonly Dictionary<string, CinemachineCamera> cams = new Dictionary<string, CinemachineCamera>();
        float follow;

        /// <summary>The shot on air now (for the tests and the pictures).</summary>
        public ShotList.Shot Now { get; private set; }

        /// <summary>Every camera the director has, by the shot it films.</summary>
        public static readonly string[] Kinds =
        {
            ShotList.Broadcast, ShotList.Close, "crowd", "coachReact", "brawl", "tunnel", "handshake", "meltdown",
            ShotList.Spot, ShotList.Line, ShotList.RefereeShot, ShotList.PlayerShot, ShotList.ReplayGoal, ShotList.ReplaySide,
        };

        void Awake() => scene = GetComponent<MatchScene>();

        void Start() => Rig();

        /// <summary>The brain on the main camera, the old fixed camera off, and one virtual camera a shot.</summary>
        public void Rig()
        {
            var main = Camera.main;
            if (main == null || brain != null) return;
            brain = main.GetComponent<CinemachineBrain>() ?? main.gameObject.AddComponent<CinemachineBrain>();
            brain.DefaultBlend = new CinemachineBlendDefinition(CinemachineBlendDefinition.Styles.Cut, 0f);
            brain.UpdateMethod = CinemachineBrain.UpdateMethods.LateUpdate;
            var old = main.GetComponent<BroadcastCamera>();
            if (old != null) old.enabled = false;
            foreach (var kind in Kinds)
            {
                var go = new GameObject("Shot " + kind);
                go.transform.SetParent(transform, false);
                var cam = go.AddComponent<CinemachineCamera>();
                cam.Lens = LensSettings.Default;
                cam.Lens.FieldOfView = Lens(kind);
                cam.Lens.NearClipPlane = 0.1f;
                cam.Lens.FarClipPlane = 600f;
                go.SetActive(false);
                cams[kind] = cam;
            }
        }

        /// <summary>Each shot's lens: wide for the broadcast, tight on the people.</summary>
        static float Lens(string kind) => kind switch
        {
            ShotList.Broadcast => 30f,
            ShotList.Close => 28f,
            "crowd" => 38f,
            "coachReact" or "meltdown" => 24f,
            "handshake" => 34f,
            "tunnel" => 40f,
            ShotList.Spot => 34f,
            ShotList.Line => 40f,
            ShotList.RefereeShot or ShotList.PlayerShot => 26f,
            ShotList.ReplayGoal => 36f,
            ShotList.ReplaySide => 24f,
            _ => 32f,
        };

        void LateUpdate()
        {
            if (cams.Count == 0) Rig();
            if (scene == null || scene.OnAir == null || cams.Count == 0) return;
            Show(ShotList.At(scene.Plan, scene.OnAir.Story, scene.Elapsed, scene.KeyMoment), Time.unscaledDeltaTime);
        }

        /// <summary>Puts the shot's camera where it films from and cuts to it (dt: how far the broadcast camera eases after the ball).</summary>
        public void Show(ShotList.Shot shot, float dt)
        {
            // [Sprint 09 U3] the replay from two sides: behind the goal, then low from the far touchline
            string angle = ShotList.ReplayAngle(shot, scene.Elapsed);
            string kind = angle ?? (cams.ContainsKey(shot.Name) ? shot.Name : ShotList.Broadcast);
            var cam = cams[kind];
            Place(cam.transform, kind, shot, dt);
            foreach (var kv in cams)
                if (kv.Value.gameObject.activeSelf != (kv.Key == kind)) kv.Value.gameObject.SetActive(kv.Key == kind);
            if (kind != Now.Name && (kind == "coachReact" || kind == "meltdown") && scene.bench != null)
            {
                // the coach in the cutaway feels as the director says; the other keeps the minute's mood
                string mood = shot.Data != null && shot.Data.TryGetValue("mood", out var m) && m is string md ? md : kind == "meltdown" ? "angry" : "idle";
                bool home = shot.Side == "home";
                scene.bench.Feel(home ? mood : scene.OnAir.HomeMood, home ? scene.OnAir.AwayMood : mood);
            }
            Now = new ShotList.Shot { Name = kind, Data = shot.Data, From = shot.From, To = shot.To };
        }

        readonly List<Vector3> people = new List<Vector3>();

        /// <summary>
        /// [Sprint 09 U2] Where to film `target` from: the preferred place, unless someone stands between it and the target;
        /// then, at the same distance and height, whichever of twelve sides leaves the most room between the camera's line
        /// and everyone else, never behind the boards or the goal lines. Pure: the same frames give the same angle on every screen.
        /// </summary>
        public static Vector3 Clear(Vector3 target, Vector3 preferred, List<Vector3> others)
        {
            const float Room = 0.9f;   // a body's half width and a little
            var off = preferred - target;
            float r = new Vector2(off.x, off.z).magnitude, h = off.y, a0 = Mathf.Atan2(off.z, off.x);
            float Gap(Vector3 at)
            {
                float least = float.MaxValue;
                Vector2 s0 = new Vector2(at.x, at.z), s1 = new Vector2(target.x, target.z);
                foreach (var p in others)
                {
                    var q = new Vector2(p.x, p.z);
                    if (Vector2.Distance(q, s1) < 0.6f) continue;   // beside the target: in the picture, not in the way
                    float t = Mathf.Clamp01(Vector2.Dot(q - s0, s1 - s0) / Mathf.Max(1e-4f, (s1 - s0).sqrMagnitude));
                    least = Mathf.Min(least, Vector2.Distance(q, Vector2.Lerp(s0, s1, t * 0.9f)));
                }
                return least;
            }
            bool Inside(Vector3 at) => at.z > -36f && at.z < 36f && Mathf.Abs(at.x) < 54f;
            if (Gap(preferred) >= Room) return preferred;
            var best = preferred;
            float room = Gap(preferred);
            for (int i = 1; i < 12; i++)
            {
                float a = a0 + i * Mathf.PI / 6f;
                var at = target + new Vector3(Mathf.Cos(a) * r, h, Mathf.Sin(a) * r);
                if (!Inside(at)) continue;
                float g = Gap(at);
                if (g > room + 0.05f) { room = g; best = at; }
                if (room >= Room) break;
            }
            return best;
        }

        /// <summary>Where each camera stands and what it looks at, in the scene's metres (the centre spot at the origin).</summary>
        void Place(Transform cam, string kind, ShotList.Shot shot, float dt)
        {
            var ball = scene.Ball != null ? transform.InverseTransformPoint(scene.Ball.position) : Vector3.zero;
            float end = ball.x >= 0 ? 1f : -1f;   // the goal the play is nearer
            // [Sprint 09 U2] where the scene starts: the ball on the spot or at the free kick, the line of the trap
            var m = scene.OnAir;
            var start = m != null && m.Frames.Count > 0 ? MatchScene.World(new Vector2(m.Frames[0].Ball.x, m.Frames[0].Ball.y), MatchScene.Flipped(m.Period)) : ball;
            float goal = start.x >= 0 ? 1f : -1f;
            // [Sprint 09 U3] the goal the scene ends at (where the ball goes in), for the replay
            var last = m != null && m.Frames.Count > 0 ? MatchScene.World(new Vector2(m.Frames[m.Frames.Count - 1].Ball.x, m.Frames[m.Frames.Count - 1].Ball.y), MatchScene.Flipped(m.Period)) : ball;
            float net = last.x >= 0 ? 1f : -1f;
            Vector3 at, look;
            switch (kind)
            {
                case ShotList.Close:
                    // low on the near side, a little back from the goal the ball is going to, the ball and its strikers in
                    // frame; [U2] from another side when someone stands in the way
                    scene.People(people);
                    at = Clear(ball, ball + new Vector3(-end * 3.5f, 2.2f, -9f), people);
                    look = ball + Vector3.up * 0.8f;
                    break;
                case "crowd":
                    // the fans on the far side by the goal the play is at: the lower tier and the ribbon over it, from the grass
                    at = new Vector3(end * 16f, 4.5f, 8f);
                    look = new Vector3(end * 34f, 9f, 50f);
                    break;
                case "coachReact":
                case "meltdown":
                {
                    var spot = scene.bench != null ? (shot.Side == "home" ? scene.bench.homeSpot : scene.bench.awaySpot) : new Vector3(shot.Side == "home" ? -9f : 9f, 0, -37.5f);
                    // in front of his face: he stands turned to the broadcast camera in the main stand (BenchCoaches)
                    at = spot + new Vector3(0.6f, 1.6f, -3.4f);
                    look = spot + Vector3.up * 1.45f;
                    break;
                }
                case ShotList.Spot:
                    // behind the ball, low, the goal and the keeper beyond it
                    at = start + new Vector3(-goal * 7f, 1.9f, start.z > 0 ? 1.5f : -1.5f);
                    look = new Vector3(goal * 52.5f, 1.4f, start.z * 0.4f);
                    break;
                case ShotList.Line:
                    // on the near touchline, square to the line of the trap
                    at = new Vector3(start.x, 3f, -38f);
                    look = new Vector3(start.x, 0.5f, 4f);
                    break;
                case ShotList.RefereeShot:
                {
                    var r = scene.Referee != null ? transform.InverseTransformPoint(scene.Referee.position) : ball;
                    // from the pitch's side of him (never behind the boards on the near touchline), with no one in the way
                    scene.People(people, scene.Referee);
                    at = Clear(r, r + new Vector3(2.2f, 1.7f, r.z < -20f ? 5f : -5f), people);
                    look = r + Vector3.up * 1.5f;
                    break;
                }
                case ShotList.PlayerShot:
                {
                    // the man down (an injury): low beside him
                    string id = null;
                    if (m != null) foreach (var e in m.Events) if (MiniJson.Str(e, "type") == "injury") id = MiniJson.Str(e, "player", null);
                    var who = scene.Player(id);
                    var p = who != null ? transform.InverseTransformPoint(who.position) : ball;
                    // from the pitch's side of him: by the near touchline the bench and the boards are behind the camera
                    scene.People(people, who);
                    at = Clear(p, p + new Vector3(3.2f, 2.1f, p.z < -20f ? 4.8f : -4.8f), people);
                    look = p + Vector3.up * 0.4f;
                    break;
                }
                case ShotList.ReplayGoal:
                    // high behind the net the ball goes into, the shooter running at the camera
                    at = new Vector3(net * 57f, 8f, Mathf.Clamp(ball.z, -12f, 12f) * 0.5f);
                    look = ball + Vector3.up * 0.6f;
                    break;
                case ShotList.ReplaySide:
                    // low from the far touchline, close on the ball (the reverse angle)
                    at = ball + new Vector3(-net * 4f, 1.6f, 11f);
                    look = ball + Vector3.up * 0.7f;
                    break;
                case "brawl":
                    at = ball + new Vector3(5f, 3f, -10f);
                    look = ball + Vector3.up * 1f;
                    break;
                case "tunnel":
                    // the players walking off to the tunnel under the main stand
                    at = new Vector3(6f, 5f, -31f);
                    look = new Vector3(0f, 1f, -10f);
                    break;
                case "handshake":
                    at = new Vector3(7f, 2.6f, -9f);
                    look = new Vector3(0f, 1.2f, 0f);
                    break;
                default:
                    // the broadcast camera: high in the main stand, following the ball along the pitch (as BroadcastCamera)
                    follow = Mathf.Lerp(follow, Mathf.Clamp(ball.x, -35f, 35f), dt <= 0f ? 1f : 2.5f * dt);
                    at = new Vector3(follow, 30f, -62f);
                    look = new Vector3(follow * 0.9f, 0f, 6f + ball.z * 0.35f);
                    break;
            }
            cam.position = transform.TransformPoint(at);
            cam.rotation = Quaternion.LookRotation(transform.TransformPoint(look) - cam.position);
        }
    }
}
