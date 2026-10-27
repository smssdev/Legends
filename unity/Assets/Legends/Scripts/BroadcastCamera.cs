using UnityEngine;

namespace Legends
{
    /// <summary>
    /// The broadcast camera for now: high on the near touchline, following the ball along the pitch. The director
    /// with its angles, cuts and replays (Cinemachine) comes in its sprint (README.md 7.5).
    /// </summary>
    public sealed class BroadcastCamera : MonoBehaviour
    {
        public MatchScene scene;
        // High in the main stand, like a TV gantry: the far touchline and both sides of the ball in the frame,
        // little empty grass in front (Sprint 2 captures).
        public float height = 30f, back = 62f, follow = 2.5f;

        float x;

        void LateUpdate()
        {
            if (scene == null || scene.Ball == null) return;
            var ball = scene.Ball.position;
            x = Mathf.Lerp(x, Mathf.Clamp(ball.x, -35f, 35f), follow * Time.unscaledDeltaTime);
            transform.position = new Vector3(x, height, -back);
            transform.LookAt(new Vector3(x * 0.9f, 0, 6f + ball.z * 0.35f));
        }
    }
}
