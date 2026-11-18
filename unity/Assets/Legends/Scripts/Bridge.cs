using UnityEngine;

namespace Legends
{
    /// <summary>
    /// Where the web page (Vue) and the app (Flutter) talk to the scene. Its object is named "Bridge", so the page
    /// calls unityInstance.SendMessage('Bridge', 'OnSetup', json) once, then 'OnMinute' for every minute it gets
    /// from the server, in the shape of README.md appendix A.
    /// </summary>
    public sealed class Bridge : MonoBehaviour
    {
        public MatchScene scene;

        public void OnSetup(string json)
        {
            var setup = MatchSetup.From(MiniJson.Parse(json));
            scene.Begin(setup);
        }

        public void OnMinute(string json)
        {
            scene.Push(MatchMinute.From(MiniJson.Parse(json), scene.Setup != null ? scene.Setup.TickMs : 3000));
        }

        /// <summary>
        /// [Sprint 11 W3] The web page's minute, played now in place of what was on (the page keeps the time: its cartoon
        /// plays under the scene). `into` in the minute: how far into it the page already is (s).
        /// </summary>
        public void OnPlay(string json)
        {
            scene.PlayNow(MatchMinute.From(MiniJson.Parse(json), scene.Setup != null ? scene.Setup.TickMs : 3000));
        }

        /// <summary>[Sprint 11 W3] The page skipped to the result: the scene stops where it is.</summary>
        public void OnSkip(string _) => scene.Skip();

        /// <summary>
        /// [Sprint 09 U3] The match's highlights: a JSON array of minutes (the goals and the big moments the page chose,
        /// in the shape of OnMinute), played one after the other in place of whatever was on.
        /// </summary>
        public void OnHighlights(string json)
        {
            int ms = scene.Setup != null ? scene.Setup.TickMs : 3000;
            var list = new System.Collections.Generic.List<MatchMinute>();
            if (MiniJson.Parse(json) is System.Collections.Generic.List<object> ticks)
                foreach (var t in ticks) list.Add(MatchMinute.From(t, ms));
            scene.Highlights(list);
        }

        /// <summary>"high" | "medium" | "low": the quality levels of README.md 7.6.</summary>
        public void OnQuality(string level)
        {
            int index = level == "low" ? 0 : level == "medium" ? 1 : QualitySettings.names.Length - 1;
            QualitySettings.SetQualityLevel(Mathf.Clamp(index, 0, QualitySettings.names.Length - 1), true);
        }

        public void OnPause(string paused)
        {
            Time.timeScale = paused == "true" ? 0 : 1;
        }
    }
}
