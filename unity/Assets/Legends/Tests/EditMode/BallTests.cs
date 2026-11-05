using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace Legends.Tests
{
    /// <summary>
    /// [Sprint 06, the owner 2026-11-05: "a real ball, not a robot's; nothing flying in the air"] The ball is a real
    /// one's size and rolls as far as it travels, and the contact shadows' shader and the ball's panels are there.
    /// </summary>
    public sealed class BallTests
    {
        [Test]
        public void TheBallIsARealOnesSize()
        {
            Assert.AreEqual(0.22f, MatchScene.BallRadius * 2f, 1e-4f, "22 cm across");
        }

        [Test]
        public void OnTheGrassItTurnsOnceForEveryRoundOfItsOwnLength()
        {
            float round = 2f * Mathf.PI * MatchScene.BallRadius;   // 69 cm
            Assert.AreEqual(360f, MatchScene.RollDegrees(round), 0.01f);
            Assert.AreEqual(3600f, MatchScene.RollDegrees(round * 10f), 0.1f);
        }

        [Test]
        public void TheContactShadowsAndThePanelsAreThere()
        {
            var shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Legends/Players/Shaders/ContactShadow.shader");
            Assert.NotNull(shader);
            Assert.IsFalse(ShaderUtil.ShaderHasError(shader), "ContactShadow compiles");
            var panels = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Legends/Art/Ball/ball_panels.png");
            Assert.NotNull(panels, "tools/unity/art/ball_texture.py");
            Assert.AreEqual(2 * panels.height, panels.width, "an equirectangular map");
        }
    }
}
