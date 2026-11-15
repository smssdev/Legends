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
        public static readonly string[] Kinds = { ShotList.Broadcast, ShotList.Close, "crowd", "coachReact", "brawl", "tunnel", "handshake", "meltdown" };

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
            string kind = cams.ContainsKey(shot.Name) ? shot.Name : ShotList.Broadcast;
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

        /// <summary>Where each camera stands and what it looks at, in the scene's metres (the centre spot at the origin).</summary>
        void Place(Transform cam, string kind, ShotList.Shot shot, float dt)
        {
            var ball = scene.Ball != null ? transform.InverseTransformPoint(scene.Ball.position) : Vector3.zero;
            float end = ball.x >= 0 ? 1f : -1f;   // the goal the play is nearer
            Vector3 at, look;
            switch (kind)
            {
                case ShotList.Close:
                    // low on the near side, a little back from the goal the ball is going to, the ball and its strikers in frame
                    at = ball + new Vector3(-end * 3.5f, 2.2f, -9f);
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
