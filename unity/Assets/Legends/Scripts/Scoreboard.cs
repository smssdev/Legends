using UnityEngine;

namespace Legends
{
    /// <summary>
    /// The score and the clock in the corner. On the web and in the app the page draws all text over the scene in
    /// Arabic (README.md 7.2), so this stays numbers and club codes only. [Sprint 09 U4] The clock is the broadcast's
    /// (MinutePlan.Clock, the cartoon's clock.ts): it runs to the moment's second, stands still through the scene and
    /// its cutaways, then runs on; and the score turns only when the ball is in the net, as the cartoon reveals it.
    /// </summary>
    public sealed class Scoreboard : MonoBehaviour
    {
        public MatchScene scene;
        GUIStyle style;

        /// <summary>What the board says at `seconds` into minute m: the clock and the score shown then (pure, for the tests).</summary>
        public static (string clock, bool frozen, int home, int away) At(MatchMinute m, Shots.MinutePlan.Plan p, double seconds, double? key)
        {
            double u = p != null && p.Total > 0 ? Mathf.Clamp01((float)(seconds / p.Total)) : 0;
            var c = Shots.MinutePlan.Clock(m.Minute, m.Added, m.Tick, u, p);
            var (h, a) = Shown(m, p, seconds, key);
            return (c.Text, c.Frozen, h, a);
        }

        /// <summary>
        /// The score shown: a goal's minute keeps the score before it until the ball goes in (the scene's key moment: the
        /// strike in the frames, else the cartoon's), then the minute's own. Every other minute, its own.
        /// </summary>
        public static (int home, int away) Shown(MatchMinute m, Shots.MinutePlan.Plan p, double seconds, double? key)
        {
            if (m.Story == null || !m.Story.Goal || p == null || p.SceneT <= 0) return (m.HomeGoals, m.AwayGoals);
            double inNet = key ?? Shots.ShotList.KeyAt(p, m.Story);
            if (seconds >= inNet) return (m.HomeGoals, m.AwayGoals);
            bool home = m.Story.Side == "home";
            return (Mathf.Max(0, m.HomeGoals - (home ? 1 : 0)), Mathf.Max(0, m.AwayGoals - (home ? 0 : 1)));
        }

        void OnGUI()
        {
            var m = scene != null ? scene.OnAir : null;
            if (m == null || scene.Setup == null) return;
            if (style == null)
                style = new GUIStyle(GUI.skin.box) { fontSize = Mathf.Max(14, Screen.height / 32), alignment = TextAnchor.MiddleCenter };
            var (clock, _, home, away) = At(m, scene.Plan, scene.Elapsed, scene.KeyMoment);
            string text = scene.Setup.Home.Code + "  " + home + " - " + away + "  " + scene.Setup.Away.Code + "   " + clock + (scene.Replaying ? "   R" : "");
            GUI.Box(new Rect(16, 16, style.fontSize * 16, style.fontSize * 2), text, style);
        }
    }
}
