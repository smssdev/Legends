using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 06 U6] What the kit shader (Players/Shaders/Kit.shader) paints, from a club's colours and pattern as the
    /// server sends them (`scene`: primary, secondary, pattern, away_kit). The same rules as the cartoon's
    /// (web/src/match/feed/art.ts): the socks the shirt's colour, the shorts navy under a light shirt or the shirt's
    /// colour darkened, the trim and the pattern in the second colour, and the away side in its change kit when the two
    /// shirts are too close. Drawing only.
    /// </summary>
    public struct KitColours
    {
        /// <summary>App\Data\KitPattern's names, in the shader's order.</summary>
        public static readonly string[] Patterns = { "plain", "stripes", "hoops", "halves", "sash" };
        public static readonly Color Navy = new Color32(0x1C, 0x2B, 0x48, 0xFF);
        public static readonly Color BootsBlack = new Color32(0x15, 0x17, 0x1C, 0xFF);
        public static readonly Color GlovesNeon = Hex("#E4FF5A"), DarkShorts = Hex("#111827"), Gold = Hex("#F5B82E");
        // The cartoon's choices, in its order (art.ts keeperKit, officialKit): the first far enough from the shirts.
        static readonly Color[] HomeKeepers = { Hex("#2BB673"), Hex("#7B3FE4"), Hex("#F2994A"), Hex("#14B8C4") };
        static readonly Color[] AwayKeepers = { Hex("#F2994A"), Hex("#14B8C4"), Hex("#7B3FE4"), Hex("#2BB673") };
        static readonly Color[] BibColours = { Hex("#E4FF5A"), Hex("#FF7A1A") };
        static readonly Color[] OfficialShirts = { Hex("#15171C"), Hex("#F2E205"), Hex("#E85D9A"), Hex("#7B3FE4") };

        public Color Shirt, Trim, Shorts, Socks, Boots, Gloves, Number;
        /// <summary>Round the number on a patterned shirt (the shader draws it only there): the shirt's own colour.</summary>
        public Color Outline;
        public int Pattern;

        public static KitColours Of(Color primary, Color secondary, string pattern)
        {
            return new KitColours
            {
                Shirt = primary,
                Trim = secondary,
                Shorts = ShortsUnder(primary),
                Socks = primary,
                Boots = BootsBlack,
                Gloves = GlovesNeon,
                Number = NumberOn(primary, secondary),
                Outline = primary,
                Pattern = PatternIndex(pattern),
            };
        }

        /// <summary>The kits both sides wear: the home side its own, the away side its change kit when the shirts clash.</summary>
        public static (KitColours home, KitColours away) ForMatch(ClubKit home, ClubKit away)
        {
            var homeKit = Of(home.Primary, home.Secondary, home.Pattern);
            if (!Close(home.Primary, away.Primary))
                return (homeKit, Of(away.Primary, away.Secondary, away.Pattern));
            // The change kit the owner set in the data editor (Sprint 34 V1), unless it clashes too; else the colours swapped.
            if (away.HasAwayKit && !Close(home.Primary, away.AwayColor))
                return (homeKit, Of(away.AwayColor, away.Primary, away.AwayPattern));
            return (homeKit, Of(away.Secondary, away.Primary, away.Pattern));
        }

        /// <summary>The keepers' kits: a colour far from both shirts (the away keeper's from the home keeper's too), dark shorts, neon gloves.</summary>
        public static (KitColours home, KitColours away) Keepers(Color homeShirt, Color awayShirt)
        {
            var home = Pick(HomeKeepers, homeShirt, awayShirt);
            var away = Pick(AwayKeepers, homeShirt, awayShirt, home);
            return (Keeper(home), Keeper(away));
        }

        static KitColours Keeper(Color shirt) => new KitColours
        {
            Shirt = shirt, Trim = DarkShorts, Shorts = DarkShorts, Socks = shirt, Boots = BootsBlack, Gloves = GlovesNeon,
            Number = NumberOn(shirt, DarkShorts), Outline = shirt, Pattern = 0,
        };

        /// <summary>The referee and his assistants: black, or the first colour far from both teams and both keepers; a gold trim.</summary>
        public static KitColours Officials(Color homeShirt, Color awayShirt, Color homeKeeper, Color awayKeeper)
        {
            var shirt = Pick(OfficialShirts, homeShirt, awayShirt, homeKeeper, awayKeeper);
            return new KitColours
            {
                Shirt = shirt, Trim = Gold, Shorts = DarkShorts, Socks = DarkShorts, Boots = BootsBlack, Gloves = GlovesNeon,
                Number = Color.white, Outline = shirt, Pattern = 0,
            };
        }

        /// <summary>
        /// A substitute's bib over his side's kit: neon yellow, or orange when the shirt is close to it, the kit's shirt
        /// colour on its edges and plain. The shorts and boots stay his side's.
        /// </summary>
        public static KitColours Bib(KitColours kit)
        {
            var bib = kit;
            bib.Shirt = bib.Socks = Pick(BibColours, kit.Shirt);
            bib.Trim = bib.Outline = kit.Shirt;
            bib.Number = NumberOn(bib.Shirt, kit.Shirt);
            bib.Pattern = 0;
            return bib;
        }

        /// <summary>The cartoon's "apart": the three channels differ by more than 150 of 255 in all.</summary>
        public static bool Apart(Color a, Color b) =>
            Mathf.Abs(a.r - b.r) + Mathf.Abs(a.g - b.g) + Mathf.Abs(a.b - b.b) > 150f / 255f;

        static Color Pick(Color[] choices, params Color[] avoid)
        {
            foreach (var c in choices)
            {
                bool ok = true;
                foreach (var a in avoid) ok &= Apart(c, a);
                if (ok) return c;
            }
            return choices[0];
        }

        static Color Hex(string h) => ColorUtility.TryParseHtmlString(h, out var c) ? c : Color.magenta;

        public static int PatternIndex(string pattern)
        {
            int i = System.Array.IndexOf(Patterns, pattern ?? "plain");
            return i < 0 ? 0 : i;
        }

        /// <summary>The cartoon's rule: navy under a light shirt, else the shirt 80/255 darker.</summary>
        public static Color ShortsUnder(Color shirt)
        {
            if (Brightness(shirt) > 160f / 255f) return Navy;
            const float d = 80f / 255f;
            return new Color(Mathf.Max(0, shirt.r - d), Mathf.Max(0, shirt.g - d), Mathf.Max(0, shirt.b - d), 1);
        }

        /// <summary>The number in the second colour when it stands out from the shirt, else white or navy, whichever does.</summary>
        public static Color NumberOn(Color shirt, Color second)
        {
            if (Mathf.Abs(Brightness(shirt) - Brightness(second)) > 0.3f) return second;
            return Brightness(shirt) > 0.55f ? Navy : Color.white;
        }

        /// <summary>The same weights as the cartoon's (0.299, 0.587, 0.114), 0..1.</summary>
        public static float Brightness(Color c) => 0.299f * c.r + 0.587f * c.g + 0.114f * c.b;

        /// <summary>Two shirts a viewer could mix up (the scene's rule since Sprint 02, MatchScene).</summary>
        public static bool Close(Color a, Color b) =>
            Mathf.Abs(a.r - b.r) + Mathf.Abs(a.g - b.g) + Mathf.Abs(a.b - b.b) < 0.45f;

        static readonly int ShirtId = Shader.PropertyToID("_BaseColor"), TrimId = Shader.PropertyToID("_TrimColor"),
            ShortsId = Shader.PropertyToID("_ShortsColor"), SocksId = Shader.PropertyToID("_SocksColor"),
            BootsId = Shader.PropertyToID("_BootsColor"), GlovesId = Shader.PropertyToID("_GlovesColor"),
            NumberColourId = Shader.PropertyToID("_NumberColor"),
            OutlineId = Shader.PropertyToID("_OutlineColor"),
            PatternId = Shader.PropertyToID("_Pattern"), NumberId = Shader.PropertyToID("_Number");

        /// <summary>Into a player's property block, with his shirt number (-1: none, 0 to 99).</summary>
        public void Into(MaterialPropertyBlock b, int number)
        {
            b.SetColor(ShirtId, Shirt);
            b.SetColor(TrimId, Trim);
            b.SetColor(ShortsId, Shorts);
            b.SetColor(SocksId, Socks);
            b.SetColor(BootsId, Boots);
            b.SetColor(GlovesId, Gloves);
            b.SetColor(NumberColourId, Number);
            b.SetColor(OutlineId, Outline);
            b.SetFloat(PatternId, Pattern);
            b.SetFloat(NumberId, number >= 0 && number <= 99 ? number : -1);
        }
    }
}
