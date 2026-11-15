using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// Claude's eye (README.md Sprint 2, U5): plays the recorded match in the match scene and saves what the
    /// broadcast camera sees at minutes 5, 20, 45, 70 and 90 to unity/Captures/, then quits. `build.ps1 capture`.
    /// Entering Play reloads the editor's code, so the run's state lives in SessionState, picked up again by the
    /// static constructor once the scene is playing.
    /// [Sprint 06 X1] `build.ps1 kits`: the same match stopped at minute 20 and dressed as five others (real clubs'
    /// colours from the data, the patterns as the owner may set them), each from the broadcast camera and close up, and
    /// the home bench: unity/Captures/kits-*.png, for the owner to judge the kits.
    /// </summary>
    [InitializeOnLoad]
    public static class Capture
    {
        static readonly int[] Minutes = { 5, 20, 45, 70, 90 };
        const string RunKey = "Legends.Capture.Run";
        const string NextKey = "Legends.Capture.Next";
        const string StartKey = "Legends.Capture.Started";
        const float Speed = 8f;             // the recording at 8x: about a minute of real time for the match
        const double TimeoutSeconds = 900;  // never hang the command line
        const int Width = 1600, Height = 900;

        static Capture()
        {
            if (!SessionState.GetBool(RunKey, false)) return;
            EditorApplication.update -= Tick;
            EditorApplication.update += Tick;
        }

        [MenuItem("Legends/Capture the match (5, 20, 45, 70, 90)")]
        public static void Menu() => Begin(false);

        /// <summary>For the command line: -executeMethod Legends.EditorTools.Capture.Run (without -quit).</summary>
        public static void Run() => Begin(true);

        [MenuItem("Legends/Capture the kits of five matches")]
        public static void KitsMenu() => Begin(false, true);

        /// <summary>For the command line: -executeMethod Legends.EditorTools.Capture.RunKits (without -quit).</summary>
        public static void RunKits() => Begin(true, true);

        [MenuItem("Legends/Capture the plays of a goal")]
        public static void PlaysMenu() => Begin(false, false, true);

        /// <summary>[Sprint 07 U6] For the command line: -executeMethod Legends.EditorTools.Capture.RunPlays (without -quit).</summary>
        public static void RunPlays() => Begin(true, false, true);

        const string PlaysKey = "Legends.Capture.Plays";
        const string KitsKey = "Legends.Capture.Kits";
        const int KitsMinute = 20;

        /// <summary>
        /// The five matches: a clash of reds (the away side in its colours swapped), white against stripes, stripes
        /// against white, two striped reds, and a small club in sky blue against another in sky blue.
        /// </summary>
        static readonly (string file, ClubKit home, ClubKit away)[] KitMatches =
        {
            ("liverpool-arsenal", Club("LIV", "#C8102E", "#F6C343"), Club("ARS", "#DB0007", "#FFFFFF")),
            ("realmadrid-barcelona", Club("RMA", "#FFFFFF", "#FEBE10"), Club("BAR", "#A50044", "#004D98", "stripes")),
            ("milano-realmadrid", Club("MIL", "#FB090B", "#000000", "stripes"), Club("RMA", "#FFFFFF", "#FEBE10")),
            ("barcelona-milano", Club("BAR", "#A50044", "#004D98", "stripes"), Club("MIL", "#FB090B", "#000000", "stripes")),
            ("hatta-mancity", Club("HAT", "#75AADB", "#FFFFFF"), Club("MCI", "#6CABDD", "#FFFFFF")),
        };

        static ClubKit Club(string code, string primary, string secondary, string pattern = null)
        {
            var c = new ClubKit { Code = code, Pattern = pattern };
            ColorUtility.TryParseHtmlString(primary, out c.Primary);
            ColorUtility.TryParseHtmlString(secondary, out c.Secondary);
            return c;
        }

        // The kits run lives in one play session, so plain statics hold it (SessionState only crosses the reload).
        static int kitStep = -1, kitFrame;
        static MatchMinute kitMinute;
        static float kitAt;

        static bool QuitWhenDone => SessionState.GetBool("Legends.Capture.Quit", false);

        static void Begin(bool quit, bool kits = false, bool plays = false)
        {
            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(OpenMatch.Scene) == null)
            {
                Debug.LogError("Legends: no " + OpenMatch.Scene + ". Run: build.ps1 demo");
                if (quit) EditorApplication.Exit(1);
                return;
            }
            Directory.CreateDirectory(Folder);
            foreach (var old in Directory.GetFiles(Folder, plays ? "play-*.png" : kits ? "kits-*.png" : "minute-*.png")) File.Delete(old);
            SessionState.SetBool(PlaysKey, plays);
            SessionState.SetBool("Legends.Capture.Quit", quit);
            SessionState.SetBool(KitsKey, kits);
            SessionState.SetBool(RunKey, true);
            SessionState.SetInt(NextKey, 0);
            SessionState.SetFloat(StartKey, (float)EditorApplication.timeSinceStartup);
            EditorSceneManager.OpenScene(OpenMatch.Scene);
            Debug.Log(kits ? "Legends: capturing minute " + KitsMinute + " in the kits of " + KitMatches.Length + " matches to " + Folder
                           : "Legends: capturing minutes " + string.Join(", ", Minutes) + " to " + Folder);
            EditorApplication.update -= Tick;
            EditorApplication.update += Tick;
            EditorApplication.isPlaying = true;
        }

        static string Folder => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "Captures"));

        static void Tick()
        {
            if (!SessionState.GetBool(RunKey, false)) { EditorApplication.update -= Tick; return; }
            if (EditorApplication.timeSinceStartup - SessionState.GetFloat(StartKey, 0) > TimeoutSeconds)
            {
                Finish("timed out after " + TimeoutSeconds + " s", false);
                return;
            }
            if (!EditorApplication.isPlaying) return;

            var playback = Object.FindFirstObjectByType<Legends.SamplePlayback>();
            if (playback != null) playback.speed = Speed;
            var scene = Object.FindFirstObjectByType<Legends.MatchScene>();
            if (scene == null || scene.Setup == null) return;

            if (SessionState.GetBool(KitsKey, false))
            {
                Kits(scene);
                return;
            }
            if (SessionState.GetBool(PlaysKey, false))
            {
                Plays(scene);
                return;
            }
            int next = SessionState.GetInt(NextKey, 0);
            var m = scene.Current;
            bool over = scene.Idle && next > 0;   // the recording ran out before the last minute
            if (m != null && next < Minutes.Length && m.Minute >= Minutes[next])
            {
                Shoot(scene, m, Minutes[next]);
                SessionState.SetInt(NextKey, ++next);
            }
            if (next >= Minutes.Length) Finish("saved " + Minutes.Length + " pictures", true);
            else if (over) Finish("the match ended after " + next + " of " + Minutes.Length + " pictures", next > 0);
        }

        /// <summary>
        /// One step a frame: at minute 20, hold it; then for each match dress the scene, wait two frames (the old players
        /// go at the frame's end), and shoot it far and close; then the bench.
        /// </summary>
        static void Kits(Legends.MatchScene scene)
        {
            if (kitStep < 0)
            {
                var m = scene.Current;
                if (m == null || m.Minute < KitsMinute) return;
                kitMinute = m;
                kitAt = scene.Progress;
                kitStep = 0;
                kitFrame = 0;
                var playback = Object.FindFirstObjectByType<Legends.SamplePlayback>();
                if (playback != null) playback.speed = 1f;
            }
            if (Time.frameCount < kitFrame) return;
            int match = kitStep / 2;
            if (match < KitMatches.Length)
            {
                var (file, home, away) = KitMatches[match];
                if (kitStep % 2 == 0)
                {
                    var setup = new MatchSetup { Home = home, Away = away, HomeLook = scene.Setup.HomeLook, AwayLook = scene.Setup.AwayLook, TickMs = scene.Setup.TickMs };
                    setup.Players.AddRange(scene.Setup.Players);
                    scene.Begin(setup);
                    scene.Hold(kitMinute, kitAt);
                }
                else
                {
                    Save(Camera.main, $"kits-{file}.png");
                    var ball = scene.Ball.position;
                    Save(Still(Clear(scene, ball), ball + Vector3.up * 0.6f, 34f), $"kits-{file}-close.png");
                    Debug.Log($"Legends: captured kits-{file}: {home.Code} v {away.Code}");
                }
                kitStep++;
                kitFrame = Time.frameCount + 2;
                return;
            }
            // the home bench: its substitutes in their bibs, beside their coach
            var bench = scene.transform.TransformPoint(Legends.MatchScene.HomeBench + Vector3.left * 2.5f);
            Save(Still(bench + new Vector3(2f, 2.4f, 9f), bench + Vector3.up * 0.9f, 40f), "kits-bench.png");
            kitStep = -1;
            Finish("saved the kits of " + KitMatches.Length + " matches and the bench", true);
        }

        // [Sprint 07 U6] the plays run, in one play session as the kits
        static int playStep = -1, playFrame;
        static MatchMinute playMinute;
        static readonly System.Collections.Generic.List<(string file, string who, float t)> playShots = new System.Collections.Generic.List<(string, string, float)>();

        /// <summary>
        /// [Sprint 07 U6] Who does what, seen: the first goal from open play, held at its moves (PlayerMotion) one after the
        /// other, each from close by: a pass at its contact, the shot at its contact, the keeper as the ball reaches him,
        /// and the scorer a second into his celebration. Saved as unity/Captures/play-*.png.
        /// </summary>
        static void Plays(Legends.MatchScene scene)
        {
            if (playStep < 0)
            {
                var m = scene.Current;
                if (m == null) return;
                var attack = m.Events.Find(e => MiniJson.Str(e, "type") == "attack" && MiniJson.Str(e, "result") == "goal");
                if (attack == null) return;
                var cues = PlayerMotion.Cues(m);
                float last = Mathf.Max(1, m.Frames.Count - 1);
                string shooter = MiniJson.Str(attack, "shooter"), keeper = MiniJson.Str(attack, "keeper");
                var shot = cues.Find(c => c.Id == shooter && c.OnContact);
                var save = cues.Find(c => c.Id == keeper && c.Move == PlayerMotion.Dive);
                var pass = cues.Find(c => c.OnContact && c.Id != shooter && (shot == null || c.At < shot.At));
                var party = cues.Find(c => c.Move.StartsWith("celebrate"));
                playShots.Clear();
                if (pass != null) playShots.Add(("play-1-pass.png", pass.Id, pass.At / last));
                if (shot != null) playShots.Add(("play-2-shot.png", shot.Id, shot.At / last));
                if (save != null) playShots.Add(("play-3-keeper.png", save.Id, save.At / last));
                if (party != null) playShots.Add(("play-4-celebration.png", party.Id, Mathf.Min(1f, party.At / last + 1000f / m.Ms)));
                playMinute = m;
                playStep = 0;
                playFrame = 0;
                var playback = Object.FindFirstObjectByType<Legends.SamplePlayback>();
                if (playback != null) playback.speed = 1f;
                Debug.Log($"Legends: the plays of tick {m.Tick}: " + string.Join(", ", cues));
            }
            if (playStep >= playShots.Count * 2)
            {
                playStep = -1;
                Finish("saved " + playShots.Count + " plays", playShots.Count > 0);
                return;
            }
            var (file, who, t) = playShots[playStep / 2];
            // hold every frame (the playback would move on); shoot once the moves have had a few frames to pose
            scene.Hold(playMinute, t);
            if (playStep % 2 == 0)
            {
                playFrame = Time.frameCount + 3;
                playStep++;
                return;
            }
            if (Time.frameCount < playFrame) return;
            Transform person = null;
            foreach (Transform c in scene.transform) if (c.name.EndsWith("#" + who)) person = c;
            var at = person != null ? person.position : scene.Ball.position;
            Save(Still(Clear(scene, at), at + Vector3.up * 0.9f, 28f), file);
            Debug.Log($"Legends: captured {file}: {who} at {t:0.00}");
            playStep++;
        }

        /// <summary>
        /// Where to stand for a close-up of the ball and the players by it: 6 m off and 1.4 m up, on whichever of twelve
        /// sides leaves the most room between the camera's line and every player (no back in front of the ball).
        /// </summary>
        static Vector3 Clear(Legends.MatchScene scene, Vector3 ball)
        {
            var people = new System.Collections.Generic.List<Vector3>();
            foreach (var r in scene.GetComponentsInChildren<SkinnedMeshRenderer>())
                if (r.name.StartsWith("Body") && r.gameObject.activeInHierarchy) people.Add(r.bounds.center);
            Vector3 best = ball + new Vector3(-4f, 1.4f, -4.5f);
            float room = -1f;
            for (int i = 0; i < 12; i++)
            {
                float a = i * Mathf.PI / 6f;
                var at = ball + new Vector3(Mathf.Cos(a) * 6f, 1.4f, Mathf.Sin(a) * 6f);
                float least = float.MaxValue;
                foreach (var p in people)
                {
                    var q = new Vector2(p.x, p.z);
                    Vector2 s0 = new Vector2(at.x, at.z), s1 = new Vector2(ball.x, ball.z);
                    float t = Mathf.Clamp01(Vector2.Dot(q - s0, s1 - s0) / Mathf.Max(1e-4f, (s1 - s0).sqrMagnitude));
                    float d = Vector2.Distance(q, Vector2.Lerp(s0, s1, t * 0.85f));   // a player just behind the ball is fine
                    least = Mathf.Min(least, d);
                }
                if (least > room) { room = least; best = at; }
            }
            return best;
        }

        /// <summary>A camera of its own for a still, set as the broadcast camera is (the broadcast camera keeps its place).</summary>
        static Camera Still(Vector3 at, Vector3 look, float fov)
        {
            var cam = new GameObject("Still camera").AddComponent<Camera>();
            var main = Camera.main;
            if (main != null) cam.CopyFrom(main);
            cam.enabled = false;
            cam.transform.position = at;
            cam.transform.LookAt(look);
            cam.fieldOfView = fov;
            return cam;
        }

        static void Save(Camera cam, string name)
        {
            if (cam == null) { Debug.LogError("Legends: no camera to capture"); return; }
            Render(cam, Path.Combine(Folder, name));
            if (cam != Camera.main) Object.Destroy(cam.gameObject);
        }

        static void Shoot(Legends.MatchScene scene, Legends.MatchMinute m, int target)
        {
            var cam = Camera.main;
            if (cam == null) { Debug.LogError("Legends: no main camera to capture"); return; }
            string file = Path.Combine(Folder, $"minute-{target:00}.png");
            Render(cam, file);
            string minute = m.Added > 0 ? m.Minute + "+" + m.Added : m.Minute.ToString();
            Debug.Log($"Legends: captured {Path.GetFileName(file)}: {scene.Setup.Home.Code} {m.HomeGoals}-{m.AwayGoals} {scene.Setup.Away.Code}, minute {minute}', period {m.Period}, moment {m.Moment}");
        }

        static void Render(Camera cam, string file)
        {
            // 4x MSAA like the High level on screen: without it the far lines break into dashes.
            var rt = RenderTexture.GetTemporary(Width, Height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default, 4);
            var before = cam.targetTexture;
            cam.targetTexture = rt;
            cam.Render();
            cam.targetTexture = before;
            var active = RenderTexture.active;
            RenderTexture.active = rt;
            var tex = new Texture2D(Width, Height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, Width, Height), 0, 0);
            tex.Apply();
            RenderTexture.active = active;
            RenderTexture.ReleaseTemporary(rt);
            File.WriteAllBytes(file, tex.EncodeToPNG());
            Object.DestroyImmediate(tex);
        }

        static void Finish(string what, bool ok)
        {
            EditorApplication.update -= Tick;
            bool quit = QuitWhenDone;
            SessionState.EraseBool(RunKey);
            SessionState.EraseInt(NextKey);
            SessionState.EraseFloat(StartKey);
            SessionState.EraseBool("Legends.Capture.Quit");
            SessionState.EraseBool(KitsKey);
            if (ok) Debug.Log("Legends: capture done, " + what + " in " + Folder);
            else Debug.LogError("Legends: capture failed, " + what);
            EditorApplication.isPlaying = false;
            if (quit) EditorApplication.Exit(ok ? 0 : 1);
        }
    }
}
