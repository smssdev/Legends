using UnityEngine;

namespace Legends
{
    /// <summary>
    /// The broadcast camera for now: high on the near touchline, following the ball along the pitch. The director
    /// with its angles, cuts and replays (Cinemachine) comes in its sprint (docs/PLAN.md 7.5).
    /// </summary>
    public sealed class BroadcastCamera : MonoBehaviour
    {
        public MatchScene scene;
        public float height = 22f, back = 48f, follow = 2.5f;

        float x;

        void LateUpdate()
        {
            if (scene == null || scene.Ball == null) return;
            var ball = scene.Ball.position;
            x = Mathf.Lerp(x, Mathf.Clamp(ball.x, -35f, 35f), follow * Time.unscaledDeltaTime);
            transform.position = new Vector3(x, height, -back);
            transform.LookAt(new Vector3(x * 0.85f, 0, ball.z * 0.3f));
        }
    }
}
