using System.IO;
using System.Linq;
using NUnit.Framework;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// The characters' moods (Resources/CharacterMoods.json, CharacterPoses): the nine moods are there, and each
    /// pose comes out of the file as the Blender renders read it. `build.ps1 test`.
    /// </summary>
    public sealed class CharacterPosesTests
    {
        static CharacterPoses Poses => CharacterPoses.Parse(File.ReadAllText(Path.Combine(Application.dataPath, "Legends", "Resources", "CharacterMoods.json")));

        [Test]
        public void TheNineMoodsAreThere()
        {
            var expected = new[] { "idle", "joy", "cheer", "sad", "angry", "worried", "think", "surprise", "sleep" };
            CollectionAssert.AreEquivalent(expected, Poses.Moods.ToArray());
            Assert.AreEqual(1f, Poses.Seconds);
        }

        [Test]
        public void TheRightArmMirrorsTheLeftUnlessTheMoodSaysOtherwise()
        {
            var cheer = Poses.At("cheer", 0.1f);
            Assert.AreEqual(cheer.UpperL.x, cheer.UpperR.x, 1e-4);
            Assert.AreEqual(-cheer.UpperL.y, cheer.UpperR.y, 1e-4);
            var think = Poses.At("think", 0.3f);
            Assert.AreEqual(new Vector2(-42, 28), think.UpperR);
            Assert.AreEqual(new Vector2(-62, 96), think.ForeR);
        }

        [Test]
        public void JoyBouncesOffTheGround()
        {
            Assert.AreEqual(0f, Poses.At("joy", 0f).Lift, 1e-4);
            Assert.AreEqual(0.12f, Poses.At("joy", 0.25f).Lift, 1e-4);   // two hops a second: the top of the first
            Assert.AreEqual(0f, Poses.At("joy", 0.5f).Lift, 1e-4);
        }

        [Test]
        public void AMovingValueGoesThereAndBack()
        {
            Assert.AreEqual(new Vector2(0, 140), Poses.At("joy", 0f).UpperL);
            var top = Poses.At("joy", 0.25f).UpperL;   // cycles 2: the far end at a quarter
            Assert.AreEqual(165f, top.y, 1e-3);
        }

        [Test]
        public void OnlyTheIdleCharacterBlinks()
        {
            Assert.IsTrue(Poses.At("idle", 0.8f).Blink);
            Assert.IsFalse(Poses.At("idle", 0.5f).Blink);
            Assert.IsFalse(Poses.At("sleep", 0.8f).Blink);
        }

        [Test]
        public void AnUnknownMoodStandsIdle()
        {
            var unknown = Poses.At("dancing", 0.3f);
            var idle = Poses.At("idle", 0.3f);
            Assert.AreEqual(idle.UpperL, unknown.UpperL);
            Assert.AreEqual(idle.Breathe, unknown.Breathe, 1e-6);
        }
    }
}
