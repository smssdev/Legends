using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// The builds of docs/PLAN.md 7.8, for `build.ps1 webgl | android`. The web build is gzip with the
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
            Run(BuildTarget.WebGL, "Builds/WebGL");
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
            if (s.result != BuildResult.Succeeded) EditorApplication.Exit(1);
        }
    }
}
