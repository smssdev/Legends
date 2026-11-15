using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 07 U4] Which stride a player's speed calls for, and how fast to play it, so his feet do not slide on the
    /// grass. Pure: the Animator (Animation/Player.controller, Editor/PlayerAnimator) blends the five strides from motion
    /// capture by their own speeds (Animation/Moves/locomotion.json), so a blend at Speed s covers s metres a second;
    /// below the walk he walks slower, above the sprint he sprints faster, up to MaxPace. Faster than that the frames are
    /// fast-forward (a whole minute in a few seconds) and no stride keeps up: he sprints at MaxPace and the feet slide.
    /// </summary>
    public static class Gait
    {
        /// <summary>The strides by their speed (m/s), as Animation/Moves/locomotion.json (MovesTests checks they match).</summary>
        public static readonly (string clip, float speed)[] Strides =
        {
            ("walk", 1.552f), ("walk_brisk", 2.185f), ("jog", 3.051f), ("run", 3.885f), ("sprint", 4.477f),
        };

        /// <summary>Slower than this he stands (m/s).</summary>
        public const float Still = 0.25f;
        /// <summary>The most a stride is sped up: twice the sprint's own pace, about 9 m/s, a real player's fastest.</summary>
        public const float MaxPace = 2f;

        public static float Walk => Strides[0].speed;
        public static float Sprint => Strides[Strides.Length - 1].speed;

        /// <summary>The Animator's Speed: 0 standing, else the speed held between the walk's and the sprint's.</summary>
        public static float Blend(float speed) => speed < Still ? 0f : Mathf.Clamp(speed, Walk, Sprint);

        /// <summary>
        /// How fast the stride plays (1 its own pace): his speed over the speed the blend really covers, at most MaxPace.
        /// measured: (blend, metres a second its planted foot goes back at pace 1) as Unity measured them on our player
        /// (PlayerArt.strideSpeeds, Editor/PlayerAnimator): a blend of two strides is not the mean of their speeds, and
        /// the strides themselves are a little off the speeds Blender measured. Without it the blend is taken at its word.
        /// </summary>
        public static float Pace(float speed, Vector2[] measured = null)
        {
            float blend = Blend(speed);
            if (blend <= 0f) return 1f;
            float covers = Covers(blend, measured);
            return Mathf.Min(MaxPace, speed / Mathf.Max(0.1f, covers));
        }

        /// <summary>The speed a blend covers at pace 1: from the measured table (by blend, rising), between its rows.</summary>
        public static float Covers(float blend, Vector2[] measured)
        {
            if (measured == null || measured.Length == 0) return blend;
            if (blend <= measured[0].x) return measured[0].y * blend / Mathf.Max(0.01f, measured[0].x);
            for (int i = 1; i < measured.Length; i++)
                if (blend <= measured[i].x)
                    return Mathf.Lerp(measured[i - 1].y, measured[i].y, Mathf.InverseLerp(measured[i - 1].x, measured[i].x, blend));
            var last = measured[measured.Length - 1];
            return last.y * blend / Mathf.Max(0.01f, last.x);
        }
    }

    /// <summary>
    /// [Sprint 07 U4] On every player and official: his speed from MatchScene (the frames' curve) and the Animator's
    /// stride and pace for it (Gait); Play starts a move (a kick, a dive) that hands back to the stride when it
    /// ends. Draws only: the server says where he is, this only moves his legs to match.
    /// </summary>
    public sealed class PlayerStride : MonoBehaviour
    {
        public static readonly int SpeedId = Animator.StringToHash("Speed"), PaceId = Animator.StringToHash("Pace");
        public const string Locomotion = "Locomotion";
        /// <summary>How quickly the stride follows the speed (s): smooth, but no lag a viewer sees.</summary>
        public const float Damp = 0.12f;

        Animator found;
        bool placed;

        /// <summary>His Animator, found when first needed: outside play (the tests, the pictures) Awake never runs.</summary>
        Animator animator
        {
            get
            {
                if (found == null)
                {
                    found = GetComponent<Animator>();
                    if (found != null) found.applyRootMotion = false;
                }
                return found;
            }
        }

        /// <summary>What each blend really covers on our player (PlayerArt.strideSpeeds), given by PlayerArt.Spawn.</summary>
        public Vector2[] Measured;

        /// <summary>His speed now (m/s on the grass), smoothed.</summary>
        public float Speed { get; private set; }

        /// <summary>
        /// He goes at speed (m/s on the grass, from the frames' curve) for the next dt seconds: the stride and pace for
        /// it. A still (snap) takes the speed as it is; play eases into it over Damp.
        /// </summary>
        public void Go(float speed, float dt, bool snap = false)
        {
            if (float.IsNaN(speed) || speed < 0f) speed = 0f;
            Speed = snap || !placed ? speed : Mathf.Lerp(Speed, speed, 1f - Mathf.Exp(-Mathf.Max(0f, dt) / Damp));
            placed = true;
            if (animator == null || animator.runtimeAnimatorController == null) return;
            animator.SetFloat(SpeedId, Gait.Blend(Speed));
            animator.SetFloat(PaceId, Gait.Pace(Speed, Measured));
        }

        /// <summary>Taken off the pitch or put somewhere new: no run from where he was.</summary>
        public void Restart()
        {
            placed = false;
            Speed = 0f;
            if (animator != null && animator.runtimeAnimatorController != null) animator.SetFloat(SpeedId, 0f);
        }

        /// <summary>A move by its name in Animation/Moves (a kick, a header, a dive), blended in (from `into` seconds into it, when it started earlier); the once-only ones blend back to the stride.</summary>
        public void Play(string move, float fade = 0.12f, float into = 0f)
        {
            if (animator == null || animator.runtimeAnimatorController == null) return;
            animator.CrossFadeInFixedTime(move, fade, 0, Mathf.Max(0f, into));
        }

        /// <summary>[U6] A new minute: whoever is still down from the last (a fall, a dive) gets up onto his stride.</summary>
        public void Settle()
        {
            if (animator == null || animator.runtimeAnimatorController == null || animator.IsInTransition(0)) return;
            if (!animator.GetCurrentAnimatorStateInfo(0).IsName(Locomotion)) Stride();
        }

        /// <summary>Back to the stride from a move that holds (a fall, a dive on the grass).</summary>
        public void Stride(float fade = 0.25f) => Play(Locomotion, fade);
    }
}
