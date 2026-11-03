using System.Collections.Generic;
using System.Text;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 06 U5] How a player looks, from his id alone, so he looks the same in every match, on every screen and
    /// in every replay: his build, skin tone, haircut, face, hair colour and height. The tables are the Blender export's
    /// (tools/unity/players/build_players.py, Players/looks.json; PlayerLookTests checks they match). Drawing only.
    /// </summary>
    public struct Look
    {
        public int Build, Tone, Hair, Face, HairColour;
        public float Height;

        public string BuildName => PlayerLook.Builds[Build];
        public string ToneName => PlayerLook.Tones[Tone];
        public string HairName => PlayerLook.Hairs[Hair];
        public string FaceName => PlayerLook.Faces[Face];
        public string HairColourName => PlayerLook.HairColours[HairColour];

        public override string ToString() =>
            $"{BuildName} {ToneName} {HairName} face {FaceName} {HairColourName} hair {Height:0.00} m";
    }

    public sealed class PlayerLook : MonoBehaviour
    {
        public static readonly string[] Builds = { "medium", "slim", "strong" };
        public static readonly string[] Tones = { "olive", "light", "fair", "east_asian", "brown", "dark" };
        public static readonly string[] Hairs = { "short02", "buzz", "bald", "short01", "short04", "afro01", "ponytail01", "long01" };
        public static readonly string[] Faces = { "a", "b", "c", "d" };
        public static readonly string[] HairColours = { "dark", "brown", "blond" };
        /// <summary>The tone and face the body is as it is, with no blend shape on (looks.json base_tone, face a).</summary>
        public const string BaseTone = "olive", BaseFace = "a";
        public const float ModelHeight = 1.82f, MinHeight = 1.70f, MaxHeight = 1.92f;

        // How often each comes up, in the same order as the tables: most players medium, olive and brown tones
        // as common as light (the data is full of Arab and African players), few long hair, blond only on light skin.
        static readonly int[] BuildWeights = { 5, 3, 2 };
        static readonly int[] ToneWeights = { 4, 3, 2, 2, 3, 3 };
        static readonly int[] HairWeights = { 4, 3, 1, 4, 3, 2, 1, 1 };

        /// <summary>The look of the player with this id. The same id always gives the same look.</summary>
        public static Look From(string id)
        {
            uint h = Fnv(id ?? "");
            var look = new Look
            {
                Build = Pick(BuildWeights, Next(ref h)),
                Tone = Pick(ToneWeights, Next(ref h)),
                Hair = Pick(HairWeights, Next(ref h)),
                Face = (int)(Next(ref h) % (uint)Faces.Length),
            };
            uint c = Next(ref h) % 10;
            bool lightSkin = look.ToneName == "light" || look.ToneName == "fair";
            look.HairColour = lightSkin ? (c < 4 ? 0 : c < 8 ? 1 : 2) : (c < 8 ? 0 : 1);
            // Taller on average when strong, shorter when slim: 1.70 to 1.92 m in centimetre steps.
            float t = (Next(ref h) % 1000) / 999f;
            float bias = look.BuildName == "strong" ? 0.15f : look.BuildName == "slim" ? -0.1f : 0f;
            look.Height = Mathf.Round(Mathf.Lerp(MinHeight, MaxHeight, Mathf.Clamp01(t * 0.85f + 0.075f + bias)) * 100f) / 100f;
            return look;
        }

        static uint Fnv(string s)
        {
            uint h = 2166136261;
            foreach (var b in Encoding.UTF8.GetBytes(s))
            {
                h ^= b;
                h *= 16777619;
            }
            return h;
        }

        /// <summary>The next number of the player's own sequence (a 32-bit mix), so each choice is independent.</summary>
        static uint Next(ref uint h)
        {
            h += 0x9E3779B9;
            uint z = h;
            z = (z ^ (z >> 16)) * 0x85EBCA6B;
            z = (z ^ (z >> 13)) * 0xC2B2AE35;
            return z ^ (z >> 16);
        }

        static int Pick(int[] weights, uint roll)
        {
            int total = 0;
            foreach (var w in weights) total += w;
            int r = (int)(roll % (uint)total);
            for (int i = 0; i < weights.Length; i++)
            {
                if (r < weights[i]) return i;
                r -= weights[i];
            }
            return 0;
        }

        // ------------------------------------------------------------------------------------- on the model

        public Look Current { get; private set; }

        /// <summary>
        /// Dresses this model (an instance of Players/player_&lt;build&gt;.fbx) as the look says, in the kit's colours:
        /// one haircut and the tone's brows shown, the face and the tone's blend shapes on, the materials, and the height.
        /// </summary>
        public void Apply(Look look, PlayerArt art, Color kit, Color trim)
        {
            Current = look;
            transform.localScale = Vector3.one * (look.Height / ModelHeight);
            var block = new MaterialPropertyBlock();
            string brows = art.BrowsOf(look.ToneName);
            foreach (var r in GetComponentsInChildren<SkinnedMeshRenderer>(true))
            {
                var (part, variant) = Part(r.name);
                bool shown = part switch
                {
                    "Hair" => variant == look.HairName,
                    "Brows" => variant == brows,
                    _ => true,
                };
                r.gameObject.SetActive(shown);
                if (!shown) continue;
                // Every shape is set, not only the chosen one: the FBX brings them all in at full weight.
                foreach (var face in Faces)
                    Shape(r, "face_" + face, face == look.FaceName && face != BaseFace);
                foreach (var tone in Tones)
                    Shape(r, "tone_" + tone, tone == look.ToneName && tone != BaseTone);
                block.Clear();
                switch (part)
                {
                    case "Body":
                        r.sharedMaterial = art.Skin(look.ToneName);
                        break;
                    case "Hair":
                    case "Brows":
                        r.sharedMaterial = part == "Hair" ? art.Hair(variant) : art.Brows(variant);
                        block.SetColor("_BaseColor", art.HairColour(look.HairColourName));
                        break;
                    case "Kit":
                        r.sharedMaterial = art.kit;
                        block.SetColor("_BaseColor", kit);
                        block.SetColor("_TrimColor", trim);
                        break;
                    case "Eyes":
                        r.sharedMaterial = art.eyes;
                        break;
                    case "Lashes":
                        r.sharedMaterial = art.lashes;
                        break;
                }
                r.SetPropertyBlock(block);
            }
            var lod = GetComponent<LODGroup>();
            if (lod != null) lod.RecalculateBounds();
        }

        /// <summary>"Hair_short02_LOD1" is ("Hair", "short02"), "Body_LOD0" is ("Body", "").</summary>
        public static (string part, string variant) Part(string name)
        {
            int lod = name.LastIndexOf("_LOD");
            if (lod >= 0) name = name.Substring(0, lod);
            int cut = name.IndexOf('_');
            return cut < 0 ? (name, "") : (name.Substring(0, cut), name.Substring(cut + 1));
        }

        static void Shape(SkinnedMeshRenderer r, string name, bool on)
        {
            if (r.sharedMesh == null) return;
            int i = r.sharedMesh.GetBlendShapeIndex(name);
            if (i >= 0) r.SetBlendShapeWeight(i, on ? 100f : 0f);
        }
    }
}
