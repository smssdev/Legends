using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// The builds of README.md 7.8, for `build.ps1 webgl | android`. The web build is gzip with the
    /// decompression fallback, so it runs from our server without any special headers.
    /// </summary>
    public static class Builds
    {
        static readonly string[] Scenes = { "Assets/Legends/Scenes/Match.unity" };

        public static void WebGL()
        {
            PlayerSettings.companyName = "Legends";
            PlayerSettings.productName = "Legends";
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Gzip;
            PlayerSettings.WebGL.decompressionFallback = true;
            // [X113] The recorded match is for the editor (SamplePlayback): out of the web build, which the page feeds.
            const string sample = "Assets/StreamingAssets/sample-match.json";
            string aside = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "legends-sample-match.json");
            bool moved = System.IO.File.Exists(sample);
            if (moved)
            {
                System.IO.File.Copy(sample, aside, true);
                AssetDatabase.DeleteAsset(sample);
            }
            try
            {
                Run(BuildTarget.WebGL, "Builds/WebGL");
            }
            finally
            {
                if (moved)
                {
                    System.IO.File.Copy(aside, sample, true);
                    AssetDatabase.ImportAsset(sample);
                }
            }
        }

        public static void Android()
        {
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.legends.match");
            Run(BuildTarget.Android, "Builds/Android/legends-match.apk");
        }

        static void Run(BuildTarget target, string path)
        {
            var report = BuildPipeline.BuildPlayer(Scenes, path, target, BuildOptions.None);
            var s = report.summary;
            Debug.Log($"Legends: {target} {s.result}, {s.totalSize / 1048576f:0.0} MB, {s.totalErrors} errors, at {path}");
            // [X113] What weighs most in the build (Logs/build-assets.txt), to keep the first load small.
            var sizes = new System.Collections.Generic.Dictionary<string, ulong>();
            foreach (var pack in report.packedAssets)
                foreach (var a in pack.contents)
                {
                    string k = string.IsNullOrEmpty(a.sourceAssetPath) ? "(built in)" : a.sourceAssetPath;
                    sizes[k] = (sizes.TryGetValue(k, out var v) ? v : 0) + a.packedSize;
                }
            var lines = new System.Collections.Generic.List<string>();
            foreach (var kv in System.Linq.Enumerable.OrderByDescending(sizes, x => x.Value)) lines.Add($"{kv.Value / 1048576.0:0.00} MB  {kv.Key}");
            System.IO.Directory.CreateDirectory("Logs");
            System.IO.File.WriteAllLines("Logs/build-assets.txt", lines);
            if (s.result != BuildResult.Succeeded) EditorApplication.Exit(1);
        }
    }
}
