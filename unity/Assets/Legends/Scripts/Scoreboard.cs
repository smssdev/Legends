using UnityEngine;

namespace Legends
{
    /// <summary>
    /// The score and the minute in the corner, for trying the scene alone. On the web and in the app the page draws
    /// all text over the scene in Arabic (docs/PLAN.md 7.2), so this stays numbers and club codes only.
    /// </summary>
    public sealed class Scoreboard : MonoBehaviour
    {
        public MatchScene scene;
        GUIStyle style;

        void OnGUI()
        {
            if (scene == null || scene.Setup == null || scene.Current == null) return;
            if (style == null)
                style = new GUIStyle(GUI.skin.box) { fontSize = Mathf.Max(14, Screen.height / 32), alignment = TextAnchor.MiddleCenter };
            var m = scene.Current;
            string minute = m.Added > 0 ? m.Minute + "+" + m.Added : m.Minute.ToString();
            string text = scene.Setup.Home.Code + "  " + m.HomeGoals + " - " + m.AwayGoals + "  " + scene.Setup.Away.Code + "   " + minute + "'";
            GUI.Box(new Rect(16, 16, style.fontSize * 16, style.fontSize * 2), text, style);
        }
    }
}
