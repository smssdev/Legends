using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 08 U4] The stadium's light as the setup says (light: night, dusk or day; the page sends the cartoon's,
    /// the /scene route the kick-off's hour): at night the floodlights and their many shadows under a black sky, by day
    /// the sun and a blue sky with the floodlights off, at dusk the two together under an orange sky. Draws only: the
    /// light is decided outside Unity. MatchScene applies it with every setup.
    /// </summary>
    public static class StadiumLight
    {
        public struct Look
        {
            /// <summary>The floodlights' share of their full intensity, and the sun's intensity (0: none).</summary>
            public float Flood, Sun;
            /// <summary>The sun's height over the horizon and its bearing (degrees).</summary>
            public float SunHeight, SunBearing;
            public Color SunColour, Ambient, Sky;
        }

        /// <summary>The look for a light (anything unknown is the night, the arena's own).</summary>
        public static Look Of(string light) => light switch
        {
            "day" => new Look
            {
                Flood = 0f, Sun = 1.6f, SunHeight = 52f, SunBearing = 35f,
                SunColour = new Color(1f, 0.97f, 0.9f), Ambient = new Color(0.58f, 0.62f, 0.68f), Sky = new Color(0.47f, 0.68f, 0.9f),
            },
            "dusk" => new Look
            {
                Flood = 0.7f, Sun = 0.75f, SunHeight = 9f, SunBearing = 250f,
                SunColour = new Color(1f, 0.62f, 0.36f), Ambient = new Color(0.38f, 0.32f, 0.36f), Sky = new Color(0.55f, 0.32f, 0.3f),
            },
            _ => new Look
            {
                Flood = 1f, Sun = 0f, SunHeight = 30f, SunBearing = 0f,
                SunColour = Color.white, Ambient = new Color(0.22f, 0.24f, 0.3f), Sky = new Color(0.02f, 0.027f, 0.05f),
            },
        };

        /// <summary>Lights the scene under `root`'s stadium: its floodlights (as ArenaBuilder made them), the moon, a sun, the sky.</summary>
        public static void Apply(string light, Transform root)
        {
            var look = Of(light);
            foreach (var l in Object.FindObjectsByType<Light>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (l.name == "Floodlight")
                {
                    if (!Full.TryGetValue(l, out var full)) Full[l] = full = l.intensity;
                    l.intensity = full * look.Flood;
                    l.enabled = look.Flood > 0f;
                }
                else if (l.name == "Moonlight") l.enabled = look.Sun <= 0f;
            }
            var sun = GameObject.Find("Sun")?.GetComponent<Light>();
            if (sun == null && look.Sun > 0f)
            {
                sun = new GameObject("Sun").AddComponent<Light>();
                sun.type = LightType.Directional;
                sun.shadows = LightShadows.Soft;
                if (root != null) sun.transform.SetParent(root, false);
            }
            if (sun != null)
            {
                sun.enabled = look.Sun > 0f;
                sun.intensity = look.Sun;
                sun.color = look.SunColour;
                sun.transform.rotation = Quaternion.Euler(look.SunHeight, look.SunBearing, 0f);
            }
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = look.Ambient;
            foreach (var cam in Object.FindObjectsByType<Camera>(FindObjectsSortMode.None))
            {
                cam.clearFlags = CameraClearFlags.SolidColor;
                cam.backgroundColor = look.Sky;
            }
        }

        /// <summary>Each floodlight's own intensity, kept the first time it is dimmed.</summary>
        static readonly System.Collections.Generic.Dictionary<Light, float> Full = new System.Collections.Generic.Dictionary<Light, float>();
    }
}
