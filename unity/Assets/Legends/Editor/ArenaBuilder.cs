using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Legends.EditorTools
{
    /// <summary>
    /// Builds «the Arena» at night from code (docs/PLAN.md 7.3): a real-size pitch with its lines and goals, LED
    /// boards, two tiers of stands on every side dressed in the crowd cut from our own Arena plates
    /// (tools/unity/crowd_textures.py), the LED ribbon between the tiers, the roof and its floodlights. Its look
    /// follows the plates in unity/Reference/stadiums/arena/. Rebuilt whole each time: Legends → Build Arena.
    /// </summary>
    public static class ArenaBuilder
    {
        const string Dir = "Assets/Legends/Stadiums/Arena";
        const float HalfLength = 52.5f, HalfWidth = 34f;

        [MenuItem("Legends/Build Arena")]
        public static void Menu() => Build(null);

        public static GameObject Build(Transform parent)
        {
            var old = GameObject.Find("Arena");
            if (old != null) Object.DestroyImmediate(old);
            Directory.CreateDirectory(Dir + "/Materials");
            Directory.CreateDirectory(Dir + "/Textures");

            var root = new GameObject("Arena");
            if (parent != null) root.transform.SetParent(parent, false);

            Pitch(root.transform);
            Lines(root.transform);
            Goal(root.transform, 1);
            Goal(root.transform, -1);
            Boards(root.transform);
            Stands(root.transform);
            Lights(root.transform);
            AssetDatabase.SaveAssets();
            return root;
        }

        // ------------------------------------------------------------ pitch

        static void Pitch(Transform root)
        {
            var grass = GameObject.CreatePrimitive(PrimitiveType.Plane);   // 10 x 10 m
            grass.name = "Grass";
            grass.transform.SetParent(root, false);
            grass.transform.localScale = new Vector3(12.5f, 1, 8.8f);     // 125 x 88 m: the pitch and its run-off
            var mat = Mat("Grass", Lit(), Color.white);
            mat.mainTexture = Stripes();
            grass.GetComponent<Renderer>().sharedMaterial = mat;
        }

        /// <summary>Mown stripes across the pitch, two greens like the plates, 18 bands over the 125 m.</summary>
        static Texture2D Stripes()
        {
            string path = Dir + "/Textures/grass.png";
            var tex = new Texture2D(1024, 8);
            var light = new Color32(64, 150, 52, 255);
            var dark = new Color32(46, 124, 40, 255);
            for (int x = 0; x < tex.width; x++)
                for (int y = 0; y < tex.height; y++)
                    tex.SetPixel(x, y, (x * 18 / tex.width) % 2 == 0 ? light : dark);
            File.WriteAllBytes(path, tex.EncodeToPNG());
            AssetDatabase.ImportAsset(path);
            return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        }

        static void Lines(Transform root)
        {
            var lines = new GameObject("Lines").transform;
            lines.SetParent(root, false);
            var white = Mat("Line", Lit(), new Color(0.95f, 0.95f, 0.95f));
            void Line(Vector3 a, Vector3 b)
            {
                var l = GameObject.CreatePrimitive(PrimitiveType.Cube);
                Object.DestroyImmediate(l.GetComponent<Collider>());
                l.transform.SetParent(lines, false);
                l.transform.localPosition = (a + b) / 2 + Vector3.up * 0.01f;
                l.transform.localRotation = Quaternion.LookRotation(b - a);
                l.transform.localScale = new Vector3(0.14f, 0.01f, (b - a).magnitude + 0.14f);   // 12 cm by the laws, a little more to hold at 100 m
                l.GetComponent<Renderer>().sharedMaterial = white;
            }
            Vector3 P(float x, float z) => new Vector3(x, 0, z);

            // touchlines, goal lines, halfway
            Line(P(-HalfLength, -HalfWidth), P(HalfLength, -HalfWidth));
            Line(P(-HalfLength, HalfWidth), P(HalfLength, HalfWidth));
            Line(P(-HalfLength, -HalfWidth), P(-HalfLength, HalfWidth));
            Line(P(HalfLength, -HalfWidth), P(HalfLength, HalfWidth));
            Line(P(0, -HalfWidth), P(0, HalfWidth));
            foreach (int side in new[] { -1, 1 })
            {
                float g = side * HalfLength;
                // penalty area 16.5 x 40.32, goal area 5.5 x 18.32
                Box(Line, P, g, side, 16.5f, 20.16f);
                Box(Line, P, g, side, 5.5f, 9.16f);
                Circle(Line, P(g - side * 11f, 0), 0.15f, 0, 360, 8);                   // penalty spot
                Circle(Line, P(g - side * 11f, 0), 9.15f, side > 0 ? 127 : -53, side > 0 ? 233 : 53, 12);   // the D
            }
            Circle(Line, P(0, 0), 9.15f, 0, 360, 48);
            Circle(Line, P(0, 0), 0.15f, 0, 360, 8);
        }

        static void Box(System.Action<Vector3, Vector3> line, System.Func<float, float, Vector3> p, float g, int side, float depth, float half)
        {
            float x = g - side * depth;
            line(p(g, -half), p(x, -half));
            line(p(g, half), p(x, half));
            line(p(x, -half), p(x, half));
        }

        /// <summary>An arc from one angle to another (degrees from +x), outside the penalty area for the D.</summary>
        static void Circle(System.Action<Vector3, Vector3> line, Vector3 c, float r, float from, float to, int parts)
        {
            for (int i = 0; i < parts; i++)
            {
                float a = Mathf.Deg2Rad * Mathf.Lerp(from, to, i / (float)parts);
                float b = Mathf.Deg2Rad * Mathf.Lerp(from, to, (i + 1) / (float)parts);
                line(c + new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a)) * r, c + new Vector3(Mathf.Cos(b), 0, Mathf.Sin(b)) * r);
            }
        }

        static void Goal(Transform root, int side)
        {
            var goal = new GameObject(side > 0 ? "Goal East" : "Goal West").transform;
            goal.SetParent(root, false);
            goal.localPosition = new Vector3(side * HalfLength, 0, 0);
            var white = Mat("Post", Lit(), Color.white);
            void Bar(Vector3 at, Vector3 scale)
            {
                var b = GameObject.CreatePrimitive(PrimitiveType.Cube);
                Object.DestroyImmediate(b.GetComponent<Collider>());
                b.transform.SetParent(goal, false);
                b.transform.localPosition = at;
                b.transform.localScale = scale;
                b.GetComponent<Renderer>().sharedMaterial = white;
            }
            // 7.32 x 2.44 m, posts 12 cm, the net frame 2 m deep
            Bar(new Vector3(0, 1.22f, -3.66f), new Vector3(0.12f, 2.44f, 0.12f));
            Bar(new Vector3(0, 1.22f, 3.66f), new Vector3(0.12f, 2.44f, 0.12f));
            Bar(new Vector3(0, 2.44f, 0), new Vector3(0.12f, 0.12f, 7.44f));
            Bar(new Vector3(side * 2f, 0.02f, 0), new Vector3(0.05f, 0.05f, 7.32f));
            // the net (cloth that shakes where the ball goes in) comes with the shots (Sprint 6)
        }

        // ------------------------------------------------------------ boards and stands

        static void Boards(Transform root)
        {
            var mat = Mat("Boards", Unlit(), Color.white);
            mat.mainTexture = Tex("boards.png");
            mat.mainTextureScale = new Vector2(4, 1);
            // a ring of LED boards 5 m from the touchlines and 4 m behind the goals, 0.9 m high
            Slab(root, "Boards N", 0, HalfWidth + 5, 0.45f, 120, 0.9f, mat);
            Slab(root, "Boards S", 180, HalfWidth + 5, 0.45f, 120, 0.9f, mat);
            Slab(root, "Boards E", 90, HalfLength + 4, 0.45f, 78, 0.9f, mat);
            Slab(root, "Boards W", -90, HalfLength + 4, 0.45f, 78, 0.9f, mat);
        }

        /// <summary>
        /// Two tiers on every side, as in the plates: the lower tier rising from just behind the boards, the LED
        /// ribbon, then the upper tier under the roof. The crowd repeats every 40 m along each stand.
        /// </summary>
        static void Stands(Transform root)
        {
            var concrete = Mat("Stand", Lit(), new Color(0.12f, 0.13f, 0.16f));
            var ribbon = Mat("Ribbon", Unlit(), Color.white);
            ribbon.mainTexture = Tex("boards.png");
            ribbon.mainTextureScale = new Vector2(3, 1);
            foreach (var (yaw, edge, length) in new[] { (0f, HalfWidth, 150f), (180f, HalfWidth, 150f), (90f, HalfLength, 112f), (-90f, HalfLength, 112f) })
            {
                var lower = Mat("Crowd Lower " + length, Unlit(), Color.white);
                lower.mainTexture = Tex("crowd-lower.png");
                lower.mainTextureScale = new Vector2(length / 40f, 1);
                var upper = Mat("Crowd Upper " + length, Unlit(), Color.white);
                upper.mainTexture = Tex("crowd-upper.png");
                upper.mainTextureScale = new Vector2(length / 40f, 1);

                string n = "Stand " + yaw;
                Tier(root, n + " lower", yaw, edge + 7, edge + 30, 1.2f, 13f, length, lower);
                Slab(root, n + " ribbon", yaw, edge + 30.5f, 14.5f, length, 3f, ribbon);
                Tier(root, n + " upper", yaw, edge + 31, edge + 52, 16f, 31f, length + 16, upper);
                Tier(root, n + " roof", yaw, edge + 24, edge + 58, 40f, 44f, length + 30, concrete);
            }
        }

        /// <summary>A sloping tier: from (inner distance, low height) to (outer distance, high height), facing the pitch.</summary>
        static void Tier(Transform root, string name, float yaw, float r0, float r1, float h0, float h1, float length, Material mat)
        {
            var dir = Quaternion.Euler(0, yaw, 0) * Vector3.forward;
            float run = r1 - r0, rise = h1 - h0;
            var t = Cube(root, name, mat);
            t.localPosition = dir * ((r0 + r1) / 2) + Vector3.up * ((h0 + h1) / 2);
            t.localRotation = Quaternion.Euler(-Mathf.Atan2(rise, run) * Mathf.Rad2Deg, yaw, 0);
            t.localScale = new Vector3(length, 0.3f, Mathf.Sqrt(run * run + rise * rise));
        }

        /// <summary>An upright panel at a distance from the centre, facing the pitch.</summary>
        static void Slab(Transform root, string name, float yaw, float r, float h, float length, float height, Material mat)
        {
            var t = Cube(root, name, mat);
            t.localPosition = Quaternion.Euler(0, yaw, 0) * Vector3.forward * r + Vector3.up * h;
            t.localRotation = Quaternion.Euler(0, yaw, 0);
            t.localScale = new Vector3(length, height, 0.2f);
        }

        static Transform Cube(Transform root, string name, Material mat)
        {
            var c = GameObject.CreatePrimitive(PrimitiveType.Cube);
            c.name = name;
            Object.DestroyImmediate(c.GetComponent<Collider>());
            c.transform.SetParent(root, false);
            c.GetComponent<Renderer>().sharedMaterial = mat;
            return c.transform;
        }

        // ------------------------------------------------------------ night lights

        static void Lights(Transform root)
        {
            RenderSettings.ambientMode = AmbientMode.Flat;
            RenderSettings.ambientLight = new Color(0.22f, 0.24f, 0.3f);
            var lamp = Mat("Floodlight", Lit(), Color.white);
            lamp.EnableKeyword("_EMISSION");
            lamp.SetColor("_EmissionColor", Color.white * 4f);

            // the four banks of floodlights along the roof edge, each aimed at the centre spot
            foreach (var (x, z) in new[] { (-38f, 1f), (38f, 1f), (-38f, -1f), (38f, -1f) })
            {
                var at = new Vector3(x, 40f, z * (HalfWidth + 26));
                var bank = Cube(root, "Floodlights", lamp);
                bank.localPosition = at;
                bank.localScale = new Vector3(24f, 0.8f, 0.8f);
                var go = new GameObject("Floodlight");
                go.transform.SetParent(root, false);
                go.transform.localPosition = at;
                go.transform.LookAt(root.TransformPoint(new Vector3(x * 0.3f, 0, 0)));
                var light = go.AddComponent<Light>();
                light.type = LightType.Spot;
                light.range = 160f;
                light.spotAngle = 80f;
                // URP lights fall off with the square of the distance (about 80 m from a bank to the centre spot);
                // the built-in pipeline's spot light does not, so it needs far less.
                light.intensity = GraphicsSettings.currentRenderPipeline != null ? 2500f : 2.2f;
                light.shadows = LightShadows.Soft;
            }
        }

        // ------------------------------------------------------------ materials

        /// <summary>The lit shader of whichever pipeline is active (URP once Sprint 2 switches to it).</summary>
        static Shader Lit() => Shader.Find(GraphicsSettings.currentRenderPipeline != null ? "Universal Render Pipeline/Lit" : "Standard");

        /// <summary>Unlit, for the crowd and the LEDs: their light is already in the photographs.</summary>
        static Shader Unlit() => Shader.Find(GraphicsSettings.currentRenderPipeline != null ? "Universal Render Pipeline/Unlit" : "Unlit/Texture");

        static Material Mat(string name, Shader shader, Color color)
        {
            string path = Dir + "/Materials/" + name + ".mat";
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat == null)
            {
                mat = new Material(shader);
                AssetDatabase.CreateAsset(mat, path);
            }
            mat.shader = shader;
            if (mat.HasProperty("_Color") || mat.HasProperty("_BaseColor")) mat.color = color;
            EditorUtility.SetDirty(mat);
            return mat;
        }

        static Texture2D Tex(string file)
        {
            var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(Dir + "/Textures/" + file);
            if (tex == null) Debug.LogWarning("Legends: missing " + file + ": run python3 tools/unity/crowd_textures.py");
            return tex;
        }
    }
}
