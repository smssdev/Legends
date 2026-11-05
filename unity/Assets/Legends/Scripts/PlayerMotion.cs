using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 07 U4] How a player moves his body: the server places him (MatchScene, from the frames), and this only
    /// says how fast he goes, so his Animator (Animation/Player.controller) blends standing, walking, jogging, running
    /// and sprinting at that pace. Each stride plays at its own natural speed at its threshold (locomotion.json), so
    /// his feet keep to the grass; faster than a sprint, the sprint plays faster. A one-off move (a dive, a
    /// celebration, a card) is played by name and held until he moves on. Drawing only: nothing here decides where he is.
    /// </summary>
    [RequireComponent(typeof(Animator))]
    public sealed class PlayerMotion : MonoBehaviour
    {
        public static readonly int Speed = Animator.StringToHash("Speed"), Pace = Animator.StringToHash("Pace");
        /// <summary>The state of the walk-to-sprint blend in Player.controller.</summary>
        public const string Locomotion = "Locomotion";
        /// <summary>The fastest stride's own speed (m/s): above it the sprint plays faster (Player.controller sets the same).</summary>
        public static float SprintSpeed = 4.48f;
        /// <summary>The model's height (PlayerLook.ModelHeight): a taller player covers more ground with the same stride.</summary>
        const float ModelHeight = 1.82f;

        Animator animator;
        Vector3 last;
        bool placed;
        float speed;
        string playing;

        /// <summary>His speed now, in metres a second on the grass (smoothed), as the Animator is given it.</summary>
        public float CurrentSpeed => speed;
        /// <summary>The one-off move he is in, or null while he walks and runs.</summary>
        public string Playing => playing;

        void Awake()
        {
            animator = GetComponent<Animator>();
            animator.applyRootMotion = false;
            animator.cullingMode = AnimatorCullingMode.CullUpdateTransforms;   // off camera: no bones moved
        }

        void OnEnable() => placed = false;

        void LateUpdate()
        {
            var at = transform.position;
            float dt = Time.deltaTime;
            if (placed && dt > 0f)
            {
                var d = at - last;
                d.y = 0f;
                float now = d.magnitude / dt;
                if (now > 15f) now = 0f;          // a jump (a new minute, a substitute walking on): not a run
                // smoothed over about a tenth of a second, so a key frame's corner never jerks the stride
                speed = Mathf.Lerp(speed, now, 1f - Mathf.Exp(-dt * 10f));
            }
            last = at;
            placed = true;
            if (animator == null || animator.runtimeAnimatorController == null) return;
            // the stride is the model's: scaled by his height, the ground it covers is too
            float scale = Mathf.Max(0.5f, transform.lossyScale.y);
            float pace = speed / scale;
            animator.SetFloat(Speed, pace);
            animator.SetFloat(Pace, pace > SprintSpeed ? pace / SprintSpeed : 1f);
        }

        /// <summary>A one-off move by its name (Animation/Moves), blended in over `fade` seconds; held at its end.</summary>
        public void Play(string move, float fade = 0.15f)
        {
            if (animator == null || animator.runtimeAnimatorController == null) return;
            playing = move;
            animator.CrossFadeInFixedTime(move, fade);
        }

        /// <summary>Back to walking and running at his pace.</summary>
        public void Locomote(float fade = 0.25f)
        {
            if (animator == null || animator.runtimeAnimatorController == null || playing == null) return;
            playing = null;
            animator.CrossFadeInFixedTime(Locomotion, fade);
        }
    }
}
