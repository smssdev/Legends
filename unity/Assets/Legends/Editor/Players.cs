using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace Legends.EditorTools
{
    /// <summary>
    /// [Sprint 06 U5] The players in Unity: Build makes the materials (URP Lit for now; the kit's own shader is U6) and
    /// Resources/PlayerArt.asset from the Blender export; Capture lines up players of different ids in their kits and
    /// saves unity/Captures/players.png, so Claude sees them. `build.ps1 players` runs both.
    /// </summary>
    public static class Players
    {
        const string Root = "Assets/Legends/Players";
        const string Materials = Root + "/Materials";
        const string ArtPath = "Assets/Legends/Resources/PlayerArt.asset";

        [MenuItem("Legends/Players/Build materials")]
        public static void Build()
        {
            AssetDatabase.Refresh();
            Directory.CreateDirectory(Materials);
            var looks = JsonUtility.FromJson<LooksFile>(File.ReadAllText(Root + "/looks.json"));
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            if (art == null)
            {
                art = ScriptableObject.CreateInstance<PlayerArt>();
                Directory.CreateDirectory(Path.GetDirectoryName(ArtPath));
                AssetDatabase.CreateAsset(art, ArtPath);
            }
            art.models = new GameObject[PlayerLook.Builds.Length];
            for (int i = 0; i < PlayerLook.Builds.Length; i++)
                art.models[i] = AssetDatabase.LoadAssetAtPath<GameObject>($"{Root}/player_{PlayerLook.Builds[i]}.fbx");

            var skins = new List<PlayerArt.Named>();
            var browsOfTone = new List<PlayerArt.ToneBrows>();
            var tones = ToneTable();
            foreach (var tone in PlayerLook.Tones)
            {
                var (skin, tint, browsName) = tones[tone];
                var m = Lit("Skin_" + tone, Tex("skin_" + skin), Hex(tint), 0.35f);
                skins.Add(new PlayerArt.Named { name = tone, material = m });
                browsOfTone.Add(new PlayerArt.ToneBrows { tone = tone, brows = browsName });
            }
            art.skins = skins.ToArray();
            art.browsOfTone = browsOfTone.ToArray();

            var hairs = new List<PlayerArt.Named>();
            foreach (var hair in PlayerLook.Hairs)
            {
                if (hair == "bald") continue;
                var m = hair == "buzz"
                    ? Lit("Hair_buzz", null, Color.white, 0.1f, transparent: 0.55f)
                    : Lit("Hair_" + hair, Tex(hair), Color.white, 0.25f, cutout: true);
                hairs.Add(new PlayerArt.Named { name = hair, material = m });
            }
            art.hairs = hairs.ToArray();
            var brows = new List<PlayerArt.Named>();
            foreach (var b in new HashSet<string>(browsOfTone.ConvertAll(x => x.brows)))
                brows.Add(new PlayerArt.Named { name = b, material = Lit("Brows_" + b, Tex(b), Color.white, 0.1f, cutout: true) });
            art.brows = brows.ToArray();
            art.eyes = Lit("Eyes", Tex("eye_brown"), Color.white, 0.85f);
            art.lashes = Lit("Lashes", Tex("eyelashes01"), Color.black, 0.1f, cutout: true);
            art.kit = Lit("Kit", null, Color.white, 0.3f, twoSided: true);
            art.hairColours = new[] { Hex(looks.hair_colours.dark), Hex(looks.hair_colours.brown), Hex(looks.hair_colours.blond) };
            EditorUtility.SetDirty(art);
            AssetDatabase.SaveAssets();
            Debug.Log($"Legends: PlayerArt with {art.skins.Length} skins, {art.hairs.Length} haircuts, {art.brows.Length} brows, 3 builds");
        }

        /// <summary>For the command line: build, capture, quit (-executeMethod Legends.EditorTools.Players.Run).</summary>
        public static void Run()
        {
            int code = 0;
            try
            {
                Build();
                Capture();
            }
            catch (System.Exception e)
            {
                Debug.LogError("Legends: " + e);
                code = 1;
            }
            EditorApplication.Exit(code);
        }

        static readonly (string id, string kit, string trim)[] Lineup =
        {
            ("1001", "#C8102E", "#FFFFFF"), ("1002", "#1B4F9C", "#F2F2F2"), ("1003", "#C8102E", "#FFFFFF"),
            ("1004", "#1B4F9C", "#F2F2F2"), ("1005", "#C8102E", "#FFFFFF"), ("1006", "#1B4F9C", "#F2F2F2"),
            ("1007", "#C8102E", "#FFFFFF"), ("1008", "#1B4F9C", "#F2F2F2"),
        };

        [MenuItem("Legends/Players/Capture a lineup")]
        public static void Capture()
        {
            var art = AssetDatabase.LoadAssetAtPath<PlayerArt>(ArtPath);
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var sun = new GameObject("Sun").AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 1.2f;
            sun.shadows = LightShadows.Soft;
            sun.transform.rotation = Quaternion.Euler(40, 210, 0);
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.75f, 0.8f, 0.9f);
            RenderSettings.ambientEquatorColor = new Color(0.5f, 0.55f, 0.5f);
            RenderSettings.ambientGroundColor = new Color(0.25f, 0.3f, 0.22f);
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.transform.localScale = Vector3.one * 4;
            // The ground only frames the players: unlit, so it is the same green whatever the sun does.
            var grass = new Material(Shader.Find("Universal Render Pipeline/Unlit"));
            grass.SetColor("_BaseColor", new Color(0.2f, 0.42f, 0.22f));
            ground.GetComponent<Renderer>().sharedMaterial = grass;

            var lines = new List<string>();
            for (int i = 0; i < Lineup.Length; i++)
            {
                var look = PlayerLook.From(Lineup[i].id);
                var p = art.Spawn(look, null, Hex(Lineup[i].kit), Hex(Lineup[i].trim));
                p.transform.position = new Vector3((i - (Lineup.Length - 1) / 2f) * 1.1f, 0, 0);
                lines.Add($"{Lineup[i].id}: {look}");
            }
            var cam = new GameObject("Camera").AddComponent<Camera>();
            cam.transform.position = new Vector3(0, 1.25f, 8.6f);   // the players face +Z, as Unity's characters do
            cam.transform.LookAt(new Vector3(0, 0.95f, 0));
            cam.fieldOfView = 34;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.62f, 0.72f, 0.85f);
            float bias = QualitySettings.lodBias;
            QualitySettings.lodBias = 100f;            // the full models, as in a close-up
            Save(cam, 2400, 1000, "players.png");
            QualitySettings.lodBias = 0.05f;           // the lightest, as on a far phone screen
            Save(cam, 2400, 1000, "players-far.png");
            QualitySettings.lodBias = bias;
            Debug.Log("Legends: lineup\n" + string.Join("\n", lines));
        }

        static void Save(Camera cam, int w, int h, string file)
        {
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32) { antiAliasing = 4 };
            cam.targetTexture = rt;
            cam.Render();
            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            RenderTexture.active = null;
            cam.targetTexture = null;
            string folder = Path.Combine(Path.GetDirectoryName(Application.dataPath), "Captures");
            Directory.CreateDirectory(folder);
            File.WriteAllBytes(Path.Combine(folder, file), tex.EncodeToPNG());
            Debug.Log("Legends: saved Captures/" + file);
        }

        static Material Lit(string name, Texture tex, Color colour, float smooth, bool cutout = false, float transparent = 0f, bool twoSided = false)
        {
            string path = $"{Materials}/{name}.mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (m == null)
            {
                m = new Material(Shader.Find("Universal Render Pipeline/Lit"));
                AssetDatabase.CreateAsset(m, path);
            }
            m.SetTexture("_BaseMap", tex);
            m.SetColor("_BaseColor", transparent > 0 ? new Color(colour.r, colour.g, colour.b, transparent) : colour);
            m.SetFloat("_Smoothness", smooth);
            m.SetFloat("_Metallic", 0);
            m.SetFloat("_Cull", (float)(cutout || twoSided ? CullMode.Off : CullMode.Back));
            m.SetFloat("_AlphaClip", cutout ? 1 : 0);
            m.SetFloat("_Cutoff", 0.45f);
            m.SetFloat("_Surface", transparent > 0 ? 1 : 0);
            if (cutout) m.EnableKeyword("_ALPHATEST_ON"); else m.DisableKeyword("_ALPHATEST_ON");
            if (transparent > 0)
            {
                m.SetFloat("_Blend", 0);
                m.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
                m.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
                m.SetFloat("_ZWrite", 0);
                m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
                m.renderQueue = (int)RenderQueue.Transparent;
                m.SetOverrideTag("RenderType", "Transparent");
            }
            else
            {
                m.SetFloat("_ZWrite", 1);
                m.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
                m.renderQueue = cutout ? (int)RenderQueue.AlphaTest : -1;
                m.SetOverrideTag("RenderType", cutout ? "TransparentCutout" : "Opaque");
            }
            m.doubleSidedGI = cutout || twoSided;
            EditorUtility.SetDirty(m);
            return m;
        }

        static Texture Tex(string name)
        {
            foreach (var ext in new[] { ".png", ".jpg" })
            {
                var t = AssetDatabase.LoadAssetAtPath<Texture2D>($"{Root}/Textures/{name}{ext}");
                if (t != null) return t;
            }
            Debug.LogWarning("Legends: no texture " + name);
            return null;
        }

        static Color Hex(string hex) => ColorUtility.TryParseHtmlString(hex, out var c) ? c : Color.magenta;

        /// <summary>looks.json's tones (JsonUtility reads no dictionaries, so they are read by name).</summary>
        static Dictionary<string, (string skin, string tint, string brows)> ToneTable()
        {
            var json = (Dictionary<string, object>)MiniJson.Parse(File.ReadAllText(Root + "/looks.json"));
            var tones = (Dictionary<string, object>)json["tones"];
            var table = new Dictionary<string, (string, string, string)>();
            foreach (var kv in tones)
            {
                var t = (Dictionary<string, object>)kv.Value;
                table[kv.Key] = ((string)t["skin"], (string)t["tint"], (string)t["brows"]);
            }
            return table;
        }

        [System.Serializable]
        class LooksFile
        {
            public HairColours hair_colours;
        }

        [System.Serializable]
        class HairColours
        {
            public string dark, brown, blond;
        }
    }
}
