using UnityEditor;
using UnityEditor.SceneManagement;

namespace Legends.EditorTools
{
    /// <summary>`build.ps1 open`: the editor opens on the match scene, ready for Play (README.md 7.13).</summary>
    public static class OpenMatch
    {
        public const string Scene = "Assets/Legends/Scenes/Match.unity";

        [MenuItem("Legends/Open the match scene")]
        public static void Run()
        {
            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(Scene) == null)
            {
                UnityEngine.Debug.LogError("Legends: no " + Scene + " yet. Run: build.ps1 demo");
                return;
            }
            EditorSceneManager.OpenScene(Scene);
        }
    }
}
