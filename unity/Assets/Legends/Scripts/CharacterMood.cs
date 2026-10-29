using System.Collections.Generic;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// A Legends character in a mood (Art/Characters, from tools/unity/art/characters.py): turns its arms and head
    /// and lifts its body as CharacterPoses says, and shows the face and effects of that mood (Face.&lt;mood&gt;,
    /// Fx.&lt;mood&gt;). It draws only: the mood comes from the server with the event (SetMood), never from a rule here.
    /// The model has no bones, so it works with the hierarchy the script exports: Rig > Head, Rig > ArmL > ForeL.
    /// </summary>
    public sealed class CharacterMood : MonoBehaviour
    {
        [Tooltip("idle, joy, cheer, sad, angry, worried, think, surprise or sleep")]
        public string mood = "idle";

        static CharacterPoses poses;

        sealed class Joint
        {
            public Transform T;
            public Quaternion Rest;
            public Vector3 R, B, U;   // the character's right, back and up, in the parent's own space
        }

        Transform rig, eyes;
        Joint upperL, foreL, upperR, foreR, head, body;
        Vector3 rigRest, rigScale, eyesScale, lift, side;
        int blinkAxis;
        readonly Dictionary<string, GameObject> faces = new Dictionary<string, GameObject>();
        readonly Dictionary<string, GameObject> effects = new Dictionary<string, GameObject>();
        string shown;
        float started;

        public void SetMood(string next)
        {
            if (next == mood) return;
            mood = next;
            started = Time.time;
        }

        void Awake()
        {
            poses ??= CharacterPoses.Load();
            rig = Find("Rig");
            var headT = Find("Head");
            var armL = Find("ArmL");
            var armR = Find("ArmR");
            // the character's own directions, read from its body so the importer's axes do not matter:
            // up from the feet to the head, right from the left shoulder to the right, back away from the nose
            Vector3 u = (headT.position - rig.position).normalized;
            Vector3 r = Vector3.ProjectOnPlane(armR.position - armL.position, u).normalized;
            var nose = Find("Nose");
            Vector3 f = nose != null ? Vector3.ProjectOnPlane(Center(nose) - headT.position, u) : Vector3.Cross(r, u);
            Vector3 b = -Vector3.ProjectOnPlane(f, r).normalized;
            upperL = Make(armL, r, b, u);
            foreL = Make(Find("ForeL"), r, b, u);
            upperR = Make(armR, r, b, u);
            foreR = Make(Find("ForeR"), r, b, u);
            head = Make(headT, r, b, u);
            body = Make(rig, r, b, u);
            rigRest = rig.localPosition;
            rigScale = rig.localScale;
            var parent = rig.parent != null ? rig.parent : rig;
            lift = parent.InverseTransformVector(u);
            side = parent.InverseTransformVector(r);
            foreach (Transform t in GetComponentsInChildren<Transform>(true))
            {
                string n = t.name;
                if (n.StartsWith("Face.")) faces[n.Substring(5)] = t.gameObject;
                else if (n.StartsWith("Fx.")) effects[n.Substring(3)] = t.gameObject;
            }
            eyes = Find("Eyes.idle");
            if (eyes != null)
            {
                eyesScale = eyes.localScale;
                Vector3 local = eyes.InverseTransformDirection(u);
                blinkAxis = Mathf.Abs(local.x) > Mathf.Abs(local.y) ? (Mathf.Abs(local.x) > Mathf.Abs(local.z) ? 0 : 2) : (Mathf.Abs(local.y) > Mathf.Abs(local.z) ? 1 : 2);
            }
            started = Time.time;
        }

        void Update()
        {
            float t = Mathf.Repeat((Time.time - started) / Mathf.Max(0.1f, poses.Seconds), 1f);
            var p = poses.At(mood, t);
            Turn(upperL, p.UpperL);
            Turn(foreL, p.ForeL);
            Turn(upperR, p.UpperR);
            Turn(foreR, p.ForeR);
            Turn(head, p.Head);
            Turn(body, new Vector2(0, p.Sway));
            rig.localPosition = rigRest + lift * p.Lift + side * p.ShakeX;
            rig.localScale = rigScale * (1 + p.Breathe * 0.75f);
            if (eyes != null)
            {
                var s = eyesScale;
                if (p.Blink) s[blinkAxis] *= 0.12f;
                eyes.localScale = s;
            }
            string key = poses.Has(mood) ? mood : "idle";
            if (key != shown)
            {
                foreach (var kv in faces) kv.Value.SetActive(kv.Key == key);
                foreach (var kv in effects) kv.Value.SetActive(kv.Key == key);
                shown = key;
            }
        }

        /// <summary>
        /// The Blender rotation (x about the character's right, then y about its back) built from the character's own
        /// directions, then put on top of the joint's resting turn.
        /// </summary>
        static void Turn(Joint j, Vector2 deg)
        {
            if (j == null) return;
            float x = deg.x * Mathf.Deg2Rad, y = deg.y * Mathf.Deg2Rad;
            float sx = Mathf.Sin(x), cx = Mathf.Cos(x), sy = Mathf.Sin(y), cy = Mathf.Cos(y);
            Vector3 back = sy * sx * j.R + cx * j.B + cy * sx * j.U;
            Vector3 up = sy * cx * j.R - sx * j.B + cy * cx * j.U;
            j.T.localRotation = Quaternion.LookRotation(back, up) * Quaternion.Inverse(Quaternion.LookRotation(j.B, j.U)) * j.Rest;
        }

        static Joint Make(Transform t, Vector3 r, Vector3 b, Vector3 u)
        {
            if (t == null) return null;
            var parent = t.parent;
            System.Func<Vector3, Vector3> local = v => parent != null ? parent.InverseTransformDirection(v).normalized : v;
            return new Joint { T = t, Rest = t.localRotation, R = local(r), B = local(b), U = local(u) };
        }

        static Vector3 Center(Transform t)
        {
            var r = t.GetComponent<Renderer>();
            return r != null ? r.bounds.center : t.position;
        }

        Transform Find(string name)
        {
            foreach (Transform t in GetComponentsInChildren<Transform>(true))
                if (t.name == name) return t;
            return null;
        }
    }
}
