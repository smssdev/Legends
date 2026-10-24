using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEngine;

namespace Legends.EditorTools
{
    /// <summary>
    /// Adds the Unity packages the plan uses (docs/PLAN.md 7.2), each at the version this editor recommends.
    /// From the menu Legends → Setup packages, or `build.ps1 setup`, which waits for it and quits.
    /// Adding packages recompiles the scripts and reloads the editor's code, which forgets every static
    /// field: so the command line's "quit when done" is kept in SessionState and checked again after the reload.
    /// </summary>
    [InitializeOnLoad]
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

        const string QuitKey = "Legends.Setup.QuitWhenDone";
        static AddAndRemoveRequest request;

        // After the reload that follows adding the packages: finish the command line's run.
        static Setup()
        {
            if (SessionState.GetBool(QuitKey, false)) EditorApplication.delayCall += Finish;
        }

        [MenuItem("Legends/Setup packages")]
        public static void Menu() => Start(false);

        /// <summary>For the command line: -executeMethod Legends.EditorTools.Setup.Run (without -quit).</summary>
        public static void Run() => Start(true);

        /// <summary>The packages missing from Packages/manifest.json.</summary>
        static string[] Missing()
        {
            string manifest = File.Exists("Packages/manifest.json") ? File.ReadAllText("Packages/manifest.json") : "";
            return Packages.Where(p => !manifest.Contains("\"" + p + "\"")).ToArray();
        }

        static void Start(bool quit)
        {
            SessionState.SetBool(QuitKey, quit);
            string[] missing = Missing();
            if (missing.Length == 0)
            {
                Debug.Log("Legends: packages ready (already in the project)");
                if (quit) Finish();
                return;
            }
            Debug.Log("Legends: adding " + string.Join(", ", missing));
            request = Client.AddAndRemove(missing, null);
            EditorApplication.update += Wait;
        }

        static void Wait()
        {
            if (request == null || !request.IsCompleted) return;
            EditorApplication.update -= Wait;
            if (request.Status != StatusCode.Success)
            {
                Debug.LogError("Legends: packages failed: " + request.Error.message);
                if (SessionState.GetBool(QuitKey, false)) { SessionState.EraseBool(QuitKey); EditorApplication.Exit(1); }
                return;
            }
            // No reload came (nothing new to compile): finish now.
            if (SessionState.GetBool(QuitKey, false)) Finish();
            else Debug.Log("Legends: packages ready");
        }

        static void Finish()
        {
            SessionState.EraseBool(QuitKey);
            string[] missing = Missing();
            if (missing.Length == 0)
            {
                Debug.Log("Legends: packages ready");
                EditorApplication.Exit(0);
            }
            else
            {
                Debug.LogError("Legends: packages still missing: " + string.Join(", ", missing));
                EditorApplication.Exit(1);
            }
        }
    }
}
