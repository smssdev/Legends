using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 06 U6] The kit: its colours by the cartoon's rules (KitColours), the change kit, the patterns in the
    /// shader's order, and what the shader reads from the exported kit mesh and the numbers' atlas. `build.ps1 test`.
    /// </summary>
    public sealed class KitColoursTests
    {
        static Color Hex(string h) => ColorUtility.TryParseHtmlString(h, out var c) ? c : Color.magenta;

        static ClubKit Club(string primary, string secondary, string pattern = null, string away = null, string awayPattern = null)
        {
            var c = new ClubKit { Primary = Hex(primary), Secondary = Hex(secondary), Pattern = pattern };
            if (away != null)
            {
                c.HasAwayKit = true;
                c.AwayColor = Hex(away);
                c.AwayPattern = awayPattern;
            }
            return c;
        }

        [Test]
        public void ShortsAreNavyUnderALightShirtElseTheShirtDarker()
        {
            Assert.AreEqual(KitColours.Navy, KitColours.ShortsUnder(Color.white));
            Assert.AreEqual(KitColours.Navy, KitColours.ShortsUnder(Hex("#F5B82E")));
            var red = KitColours.ShortsUnder(Hex("#C8102E"));
            Assert.AreEqual((0xC8 - 80) / 255f, red.r, 1e-3);
            Assert.AreEqual(0f, red.g, 1e-3);
        }

        [Test]
        public void TheNumberStandsOutFromTheShirt()
        {
            Assert.AreEqual(Hex("#F5B82E"), KitColours.NumberOn(Hex("#0A1F42"), Hex("#F5B82E")));   // the second colour
            Assert.AreEqual(Color.white, KitColours.NumberOn(Hex("#C8102E"), Hex("#B0102A")));      // too close: white
            Assert.AreEqual(KitColours.Navy, KitColours.NumberOn(Color.white, Hex("#F2F2F2")));      // on white: navy
        }

        [Test]
        public void PatternsAreTheDataEditorsInTheShadersOrder()
        {
            CollectionAssert.AreEqual(new[] { "plain", "stripes", "hoops", "halves", "sash" }, KitColours.Patterns);
            Assert.AreEqual(0, KitColours.PatternIndex(null));
            Assert.AreEqual(4, KitColours.PatternIndex("sash"));
            Assert.AreEqual(0, KitColours.PatternIndex("zigzag"));
            Assert.AreEqual(2, KitColours.Of(Color.red, Color.white, "hoops").Pattern);
        }

        [Test]
        public void TheAwaySideWearsItsChangeKitWhenTheShirtsClash()
        {
            var home = Club("#C8102E", "#FFFFFF");
            // no clash: each its own
            var (_, blue) = KitColours.ForMatch(home, Club("#1B4F9C", "#FFFFFF", "stripes"));
            Assert.AreEqual(Hex("#1B4F9C"), blue.Shirt);
            Assert.AreEqual(1, blue.Pattern);
            // a clash and a change kit: the change kit and its pattern, the club's colour as its trim
            var (_, change) = KitColours.ForMatch(home, Club("#A0102A", "#F5B82E", null, "#F2F2F2", "hoops"));
            Assert.AreEqual(Hex("#F2F2F2"), change.Shirt);
            Assert.AreEqual(Hex("#A0102A"), change.Trim);
            Assert.AreEqual(2, change.Pattern);
            // a clash and no change kit: the colours swapped
            var (_, swapped) = KitColours.ForMatch(home, Club("#B0102A", "#FFFFFF"));
            Assert.AreEqual(Color.white, swapped.Shirt);
            // a change kit that clashes too: swapped instead
            var (_, still) = KitColours.ForMatch(home, Club("#B0102A", "#111111", null, "#C0142E"));
            Assert.AreEqual(Hex("#111111"), still.Shirt);
        }

        [Test]
        public void TheSceneReadsAClubsPatternAndChangeKit()
        {
            var json = (Dictionary<string, object>)MiniJson.Parse(
                "{\"code\":\"RED\",\"primary\":\"#C8102E\",\"secondary\":\"#FFFFFF\",\"pattern\":\"stripes\",\"away_kit\":{\"color\":\"#F2F2F2\",\"pattern\":null}}");
            var club = ClubKit.From(json);
            Assert.AreEqual("stripes", club.Pattern);
            Assert.IsTrue(club.HasAwayKit);
            Assert.AreEqual(Hex("#F2F2F2"), club.AwayColor);
            Assert.IsNull(club.AwayPattern);
            var plain = ClubKit.From((Dictionary<string, object>)MiniJson.Parse("{\"primary\":\"#000000\",\"pattern\":null,\"away_kit\":null}"));
            Assert.IsNull(plain.Pattern);
            Assert.IsFalse(plain.HasAwayKit);
        }

        [Test]
        public void TheKitMeshCarriesItsPiecesAndPattern()
        {
            foreach (var build in PlayerLook.Builds)
            {
                var path = $"Assets/Legends/Players/player_{build}.fbx";
                var kit = AssetDatabase.LoadAllAssetsAtPath(path).OfType<Mesh>().FirstOrDefault(m => m.name == "Kit_LOD0");
                Assert.NotNull(kit, path + " has Kit_LOD0");
                var colours = kit.colors;
                Assert.AreEqual(kit.vertexCount, colours.Length, build + ": a colour for every vertex");
                // the four pieces: shirt 0, shorts 0.33, socks 0.66, boots 1, each where the shader looks for it
                var pieces = colours.Select(c => c.b < 0.17f ? 0 : c.b < 0.5f ? 1 : c.b < 0.83f ? 2 : 3).Distinct().OrderBy(x => x);
                CollectionAssert.AreEqual(new[] { 0, 1, 2, 3 }, pieces, build);
                Assert.That(colours.Any(c => c.r > 0.5f), build + ": the trim");
                Assert.That(colours.Any(c => c.g > 0.5f) && colours.Any(c => c.g < 0.5f), build + ": front and back");
                var pattern = new List<Vector2>();
                kit.GetUVs(1, pattern);
                Assert.AreEqual(kit.vertexCount, pattern.Count, build + ": the 'pattern' UV is the second");
                Assert.That(pattern.Max(p => p.y), Is.GreaterThan(0.9f), build + ": v reaches the shoulders");
            }
        }

        [Test]
        public void TheShadersAndTheNumbersAreThere()
        {
            foreach (var name in new[] { "Legends/Kit", "Legends/Stubble" })
            {
                var shader = Shader.Find(name);
                Assert.NotNull(shader, name);
                Assert.IsFalse(ShaderUtil.ShaderHasError(shader), name + " compiles");
            }
            var numbers = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Legends/Players/Textures/numbers.png");
            Assert.NotNull(numbers);
            Assert.AreEqual(1280, numbers.width, "ten cells of 128");
            Assert.AreEqual(192, numbers.height);
        }
    }
}
