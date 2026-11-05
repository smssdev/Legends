using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 06, the owner 2026-11-05: "not flying in the air"] Where the players and the ball meet the grass: a soft
    /// dark patch under each boot, a fainter one under the body, and one under the ball that grows fainter and wider as
    /// it rises, so its height reads. The floodlights' own shadows fall far and soft from the feet, and without this the
    /// players look as if they float. One mesh of quads, rebuilt every frame from the bones, in one draw call
    /// (Players/Shaders/ContactShadow.shader); cheap on every quality level. Drawing only.
    /// </summary>
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public sealed class ContactShadows : MonoBehaviour
    {
        const float Lift = 0.012f;                    // over the grass and its lines

        sealed class Feet
        {
            public Transform Root, FootL, FootR, ToeL, ToeR, Pelvis;
        }

        readonly List<Feet> people = new List<Feet>();
        Transform ball;
        float ballRadius;
        Mesh mesh;
        readonly List<Vector3> verts = new List<Vector3>();
        readonly List<Vector2> uvs = new List<Vector2>();
        readonly List<Color> colours = new List<Color>();
        readonly List<int> tris = new List<int>();

        public static ContactShadows On(GameObject host, Material material)
        {
            var c = host.GetComponent<ContactShadows>();
            if (c == null) c = host.AddComponent<ContactShadows>();
            var r = c.GetComponent<MeshRenderer>();
            r.sharedMaterial = material;
            r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            r.receiveShadows = false;
            return c;
        }

        void Awake()
        {
            mesh = new Mesh { name = "Contact shadows" };
            mesh.MarkDynamic();
            GetComponent<MeshFilter>().sharedMesh = mesh;
        }

        public void Clear() => people.Clear();

        /// <summary>A player, keeper, official or substitute: his boots and his body, from his rig's bones.</summary>
        public void Track(Transform person)
        {
            var f = new Feet { Root = person };
            foreach (var t in person.GetComponentsInChildren<Transform>(true))
            {
                switch (t.name)
                {
                    case "foot_l": f.FootL = t; break;
                    case "foot_r": f.FootR = t; break;
                    case "ball_l": f.ToeL = t; break;
                    case "ball_r": f.ToeR = t; break;
                    case "pelvis": f.Pelvis = t; break;
                }
            }
            if (f.FootL != null && f.FootR != null) people.Add(f);
        }

        public void TrackBall(Transform t, float radius)
        {
            ball = t;
            ballRadius = radius;
        }

        void LateUpdate()
        {
            verts.Clear(); uvs.Clear(); colours.Clear(); tris.Clear();
            foreach (var f in people)
            {
                if (f.Root == null || !f.Root.gameObject.activeInHierarchy) continue;
                float s = f.Root.lossyScale.y;
                Boot(f.FootL, f.ToeL, s);
                Boot(f.FootR, f.ToeR, s);
                if (f.Pelvis != null)
                {
                    var p = f.Pelvis.position;
                    Quad(new Vector3(p.x, 0, p.z), Vector3.forward, 0.42f * s, 0.32f * s, 0.32f);
                }
            }
            if (ball != null && ball.gameObject.activeInHierarchy)
            {
                // on the grass a tight dark patch; as it rises, wider and fainter, gone by about 6 m
                var p = ball.position;
                float h = Mathf.Max(0f, p.y - ballRadius);
                float spread = 1f + h * 0.35f;
                Quad(new Vector3(p.x, 0, p.z), Vector3.forward, ballRadius * 1.5f * spread, ballRadius * 1.5f * spread, 0.75f / (1f + h * h * 0.12f));
            }
            mesh.Clear();
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            mesh.SetColors(colours);
            mesh.SetTriangles(tris, 0);
            mesh.bounds = new Bounds(Vector3.zero, new Vector3(400f, 20f, 400f));   // always drawn: it covers the pitch
        }

        /// <summary>Under one boot: from the heel to the toes, darker when the boot is down, gone when it is 30 cm up.</summary>
        void Boot(Transform foot, Transform toe, float scale)
        {
            var heel = foot.position;
            var tip = toe != null ? toe.position : heel + foot.forward * 0.15f * scale;
            var mid = (heel + tip) * 0.5f;
            var along = tip - heel;
            along.y = 0;
            if (along.sqrMagnitude < 1e-6f) along = Vector3.forward;
            float h = Mathf.Max(0f, Mathf.Min(heel.y, tip.y) - 0.04f * scale);
            float a = 0.85f * Mathf.Clamp01(1f - h / (0.3f * scale));
            if (a <= 0.01f) return;
            Quad(new Vector3(mid.x, 0, mid.z), along.normalized, 0.11f * scale, along.magnitude * 0.5f + 0.09f * scale, a);
        }

        /// <summary>A flat quad on the grass at `at`, `half` wide across and `length` half-long along `along`.</summary>
        void Quad(Vector3 at, Vector3 along, float half, float length, float alpha)
        {
            var side = Vector3.Cross(Vector3.up, along).normalized * half;
            var fwd = along.normalized * length;
            at.y = Lift;
            int i = verts.Count;
            verts.Add(transform.InverseTransformPoint(at - side - fwd));
            verts.Add(transform.InverseTransformPoint(at + side - fwd));
            verts.Add(transform.InverseTransformPoint(at + side + fwd));
            verts.Add(transform.InverseTransformPoint(at - side + fwd));
            uvs.Add(new Vector2(0, 0)); uvs.Add(new Vector2(1, 0)); uvs.Add(new Vector2(1, 1)); uvs.Add(new Vector2(0, 1));
            var c = new Color(0, 0, 0, alpha);
            colours.Add(c); colours.Add(c); colours.Add(c); colours.Add(c);
            tris.Add(i); tris.Add(i + 2); tris.Add(i + 1);
            tris.Add(i); tris.Add(i + 3); tris.Add(i + 2);
        }
    }
}
