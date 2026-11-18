using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

namespace Legends
{
    /// <summary>
    /// Plays the recorded match in StreamingAssets/sample-match.json (a copy of docs/api/samples/, made by
    /// build.ps1) through the bridge, exactly as the page will send it. For trying the scene without the server.
    /// </summary>
    public sealed class SamplePlayback : MonoBehaviour
    {
        public Bridge bridge;
        public string file = "sample-match.json";
        [Range(0.25f, 8f)] public float speed = 1f;

        IEnumerator Start()
        {
            string path = System.IO.Path.Combine(Application.streamingAssetsPath, file);
            if (!path.Contains("://")) path = "file://" + path;
            using (var req = UnityWebRequest.Get(path))
            {
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success)
                {
                    Debug.LogError("Legends: no sample match at " + path + " (" + req.error + "). Run build.ps1 demo.");
                    yield break;
                }
                Play(req.downloadHandler.text);
            }
        }

        void Play(string text)
        {
            var root = MiniJson.Parse(text);
            var ticks = MiniJson.Arr(root, "ticks");
            bridge.OnSetup(Setup(root, ticks));
            foreach (var tick in ticks) bridge.OnMinute(Write(tick));
        }

        void Update()
        {
            Time.timeScale = speed;
        }

        /// <summary>The setup message from the recording: its clubs, timing, and the players of its first minute.</summary>
        public static string Setup(object root, List<object> ticks)
        {
            var match = MiniJson.Obj(root, "match");
            var teams = MiniJson.Obj(ticks[0], "teams");
            var setup = new Dictionary<string, object>
            {
                ["clubs"] = MiniJson.Obj(match, "clubs"),
                ["tick_ms"] = MiniJson.Int(MiniJson.Obj(match, "timing"), "tick_ms", 3000),
                ["seed"] = MiniJson.Int(match, "seed", 1),
                // [Sprint 26 U1] The recording is older than the coaches' looks: two of them, to see the bench.
                ["coach_looks"] = (object)MiniJson.Obj(match, "coach_looks") ?? new Dictionary<string, object> { ["home"] = "C1", ["away"] = "C2" },
                ["players"] = new Dictionary<string, object>
                {
                    ["home"] = MiniJson.Arr(MiniJson.Obj(teams, "home"), "players"),
                    ["away"] = MiniJson.Arr(MiniJson.Obj(teams, "away"), "players"),
                },
            };
            return Write(setup);
        }

        /// <summary>Back to JSON, so the recording goes through the same door as the server's messages.</summary>
        static string Write(object o)
        {
            var sb = new System.Text.StringBuilder();
            Append(sb, o);
            return sb.ToString();
        }

        static void Append(System.Text.StringBuilder sb, object o)
        {
            switch (o)
            {
                case null: sb.Append("null"); break;
                case bool b: sb.Append(b ? "true" : "false"); break;
                case string s:
                    sb.Append('"').Append(s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n")).Append('"');
                    break;
                case long l: sb.Append(l); break;
                case double d: sb.Append(d.ToString(System.Globalization.CultureInfo.InvariantCulture)); break;
                case Dictionary<string, object> obj:
                    sb.Append('{');
                    bool first = true;
                    foreach (var kv in obj)
                    {
                        if (!first) sb.Append(',');
                        first = false;
                        Append(sb, kv.Key);
                        sb.Append(':');
                        Append(sb, kv.Value);
                    }
                    sb.Append('}');
                    break;
                case List<object> list:
                    sb.Append('[');
                    for (int i = 0; i < list.Count; i++)
                    {
                        if (i > 0) sb.Append(',');
                        Append(sb, list[i]);
                    }
                    sb.Append(']');
                    break;
                default: sb.Append(System.Convert.ToString(o, System.Globalization.CultureInfo.InvariantCulture)); break;
            }
        }
    }
}
