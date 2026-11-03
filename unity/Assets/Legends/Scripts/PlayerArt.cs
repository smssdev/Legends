using System;
using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 06 U5] Everything a player is drawn with: the three build models and the materials of the skins, hair,
    /// brows, eyes, lashes and kit (Resources/PlayerArt.asset, made by Legends > Players > Build materials, the editor's
    /// PlayerMaterials). PlayerLook picks from it.
    /// </summary>
    [CreateAssetMenu(menuName = "Legends/Player Art")]
    public sealed class PlayerArt : ScriptableObject
    {
        [Serializable]
        public struct Named
        {
            public string name;
            public Material material;
        }

        [Serializable]
        public struct ToneBrows
        {
            public string tone, brows;
        }

        [Tooltip("player_medium, player_slim, player_strong, in PlayerLook.Builds' order")]
        public GameObject[] models = new GameObject[3];
        public Named[] skins, hairs, brows;
        public ToneBrows[] browsOfTone;
        public Material eyes, lashes, kit;
        [Tooltip("dark, brown and blond, in PlayerLook.HairColours' order")]
        public Color[] hairColours = new Color[3];

        public static PlayerArt Load() => Resources.Load<PlayerArt>("PlayerArt");

        public GameObject Model(int build) => models[build];
        public Material Skin(string tone) => Find(skins, tone);
        public Material Hair(string hair) => Find(hairs, hair);
        public Material Brows(string name) => Find(brows, name);

        public string BrowsOf(string tone)
        {
            foreach (var b in browsOfTone) if (b.tone == tone) return b.brows;
            return browsOfTone.Length > 0 ? browsOfTone[0].brows : "";
        }

        public Color HairColour(string name)
        {
            int i = Array.IndexOf(PlayerLook.HairColours, name);
            return i >= 0 && i < hairColours.Length ? hairColours[i] : Color.black;
        }

        static Material Find(Named[] list, string name)
        {
            foreach (var n in list) if (n.name == name) return n.material;
            return list.Length > 0 ? list[0].material : null;
        }

        /// <summary>A player of this look, standing, in his kit. Draws only.</summary>
        public PlayerLook Spawn(Look look, Transform parent, Color kitColour, Color trim)
        {
            var go = Instantiate(Model(look.Build), parent);
            go.name = "Player " + look;
            var player = go.AddComponent<PlayerLook>();
            player.Apply(look, this, kitColour, trim);
            return player;
        }
    }
}
