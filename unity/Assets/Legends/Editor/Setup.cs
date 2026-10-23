using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// Adds the Unity packages the plan uses (docs/PLAN.md 7.2), each at the version this editor recommends.
    /// From the menu Legends → Setup packages, or `build.ps1 setup`, which waits for it and quits.
    /// </summary>
    public static class Setup
    {
        static readonly string[] Packages =
        {
            "com.unity.render-pipelines.universal",
            "com.unity.cinemachine",
            "com.unity.timeline",
            "com.unity.animation.rigging",
            "com.unity.addressables",
            "com.unity.probuilder",
            "com.unity.test-framework",
        };

        static AddAndRemoveRequest request;
        static bool quitWhenDone;

        [MenuItem("Legends/Setup packages")]
        public static void Menu() => Start(false);

        /// <summary>For the command line: -executeMethod Legends.EditorTools.Setup.Run (without -quit).</summary>
        public static void Run() => Start(true);

        static void Start(bool quit)
        {
            quitWhenDone = quit;
            Debug.Log("Legends: adding " + string.Join(", ", Packages));
            request = Client.AddAndRemove(Packages, null);
            EditorApplication.update += Wait;
        }

        static void Wait()
        {
            if (!request.IsCompleted) return;
            EditorApplication.update -= Wait;
            bool ok = request.Status == StatusCode.Success;
            if (ok) Debug.Log("Legends: packages ready");
            else Debug.LogError("Legends: packages failed: " + request.Error.message);
            if (quitWhenDone) EditorApplication.Exit(ok ? 0 : 1);
        }
    }
}
