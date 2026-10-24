using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// Claude's eye (docs/PLAN.md Sprint 2, U5): plays the recorded match in the match scene and saves what the
    /// broadcast camera sees at minutes 5, 20, 45, 70 and 90 to unity/Captures/, then quits. `build.ps1 capture`.
    /// Entering Play reloads the editor's code, so the run's state lives in SessionState, picked up again by the
    /// static constructor once the scene is playing.
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

        static bool QuitWhenDone => SessionState.GetBool("Legends.Capture.Quit", false);

        static void Begin(bool quit)
        {
            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(OpenMatch.Scene) == null)
            {
                Debug.LogError("Legends: no " + OpenMatch.Scene + ". Run: build.ps1 demo");
                if (quit) EditorApplication.Exit(1);
                return;
            }
            Directory.CreateDirectory(Folder);
            foreach (var old in Directory.GetFiles(Folder, "minute-*.png")) File.Delete(old);
            SessionState.SetBool("Legends.Capture.Quit", quit);
            SessionState.SetBool(RunKey, true);
            SessionState.SetInt(NextKey, 0);
            SessionState.SetFloat(StartKey, (float)EditorApplication.timeSinceStartup);
            EditorSceneManager.OpenScene(OpenMatch.Scene);
            Debug.Log("Legends: capturing minutes " + string.Join(", ", Minutes) + " to " + Folder);
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

        static void Shoot(Legends.MatchScene scene, Legends.MatchMinute m, int target)
        {
            var cam = Camera.main;
            if (cam == null) { Debug.LogError("Legends: no main camera to capture"); return; }
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

            string file = Path.Combine(Folder, $"minute-{target:00}.png");
            File.WriteAllBytes(file, tex.EncodeToPNG());
            Object.DestroyImmediate(tex);
            string minute = m.Added > 0 ? m.Minute + "+" + m.Added : m.Minute.ToString();
            Debug.Log($"Legends: captured {Path.GetFileName(file)}: {scene.Setup.Home.Code} {m.HomeGoals}-{m.AwayGoals} {scene.Setup.Away.Code}, minute {minute}', period {m.Period}, moment {m.Moment}");
        }

        static void Finish(string what, bool ok)
        {
            EditorApplication.update -= Tick;
            bool quit = QuitWhenDone;
            SessionState.EraseBool(RunKey);
            SessionState.EraseInt(NextKey);
            SessionState.EraseFloat(StartKey);
            SessionState.EraseBool("Legends.Capture.Quit");
            if (ok) Debug.Log("Legends: capture done, " + what + " in " + Folder);
            else Debug.LogError("Legends: capture failed, " + what);
            EditorApplication.isPlaying = false;
            if (quit) EditorApplication.Exit(ok ? 0 : 1);
        }
    }
}
