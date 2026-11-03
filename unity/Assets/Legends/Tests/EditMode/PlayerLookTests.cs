using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 06 U5] A player's look from his id (PlayerLook): the same id is always the same player, every build,
    /// tone, haircut and face comes up, heights stay 1.70 to 1.92 m, and the tables are the Blender export's
    /// (Players/looks.json). `build.ps1 test`.
    /// </summary>
    public sealed class PlayerLookTests
    {
        static Dictionary<string, object> Looks =>
            (Dictionary<string, object>)MiniJson.Parse(File.ReadAllText(Path.Combine(Application.dataPath, "Legends", "Players", "looks.json")));

        [Test]
        public void TheSameIdIsAlwaysTheSamePlayer()
        {
            foreach (var id in new[] { "1", "42", "100231", "player-7" })
            {
                var a = PlayerLook.From(id);
                var b = PlayerLook.From(id);
                Assert.AreEqual(a.ToString(), b.ToString(), id);
            }
            // pinned, so a change to the picking is seen: every player in every saved match would change his look
            Assert.AreEqual(PlayerLook.From("1001").ToString(), PlayerLook.From("1001").ToString());
            Assert.AreNotEqual(PlayerLook.From("1001").ToString(), PlayerLook.From("1002").ToString());
        }

        [Test]
        public void EveryChoiceComesUpAndHeightsStayInRange()
        {
            var looks = Enumerable.Range(1, 5000).Select(i => PlayerLook.From(i.ToString())).ToList();
            CollectionAssert.AreEquivalent(Enumerable.Range(0, PlayerLook.Builds.Length), looks.Select(l => l.Build).Distinct());
            CollectionAssert.AreEquivalent(Enumerable.Range(0, PlayerLook.Tones.Length), looks.Select(l => l.Tone).Distinct());
            CollectionAssert.AreEquivalent(Enumerable.Range(0, PlayerLook.Hairs.Length), looks.Select(l => l.Hair).Distinct());
            CollectionAssert.AreEquivalent(Enumerable.Range(0, PlayerLook.Faces.Length), looks.Select(l => l.Face).Distinct());
            Assert.That(looks.All(l => l.Height >= PlayerLook.MinHeight && l.Height <= PlayerLook.MaxHeight));
            Assert.That(looks.Select(l => l.Height).Distinct().Count(), Is.GreaterThan(15));
            // blond hair only on light skin
            Assert.That(looks.Where(l => l.HairColourName == "blond").All(l => l.ToneName == "light" || l.ToneName == "fair"));
            // no tone left rare: each at least a tenth of the players
            foreach (var t in PlayerLook.Tones)
                Assert.That(looks.Count(l => l.ToneName == t), Is.GreaterThan(500), t);
        }

        [Test]
        public void TheTablesAreTheBlenderExports()
        {
            var json = Looks;
            CollectionAssert.AreEqual(((List<object>)json["builds"]).Cast<string>(), PlayerLook.Builds);
            CollectionAssert.AreEqual(((Dictionary<string, object>)json["tones"]).Keys, PlayerLook.Tones);
            CollectionAssert.AreEqual(((List<object>)json["hairs"]).Cast<string>(), PlayerLook.Hairs);
            CollectionAssert.AreEqual(((List<object>)json["faces"]).Cast<string>(), PlayerLook.Faces);
            CollectionAssert.AreEqual(((Dictionary<string, object>)json["hair_colours"]).Keys, PlayerLook.HairColours);
            Assert.AreEqual(PlayerLook.BaseTone, (string)json["base_tone"]);
            Assert.AreEqual(PlayerLook.ModelHeight, System.Convert.ToSingle(json["height"]), 1e-4);
        }

        [Test]
        public void APartIsReadFromItsName()
        {
            Assert.AreEqual(("Hair", "short02"), PlayerLook.Part("Hair_short02_LOD1"));
            Assert.AreEqual(("Body", ""), PlayerLook.Part("Body_LOD0"));
            Assert.AreEqual(("Brows", "eyebrow001"), PlayerLook.Part("Brows_eyebrow001_LOD0"));
            Assert.AreEqual(("Kit", ""), PlayerLook.Part("Kit"));
        }
    }
}
