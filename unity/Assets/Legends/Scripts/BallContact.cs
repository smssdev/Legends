using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 07 U5] A player's touch on the ball, after the Animator has posed him (Unity's humanoid IK, the IK pass of
    /// Animation/Player.controller): in a kick his kicking foot goes onto the ball around its contact (takes.json), the
    /// keeper's hands go to it in a dive, a catch or a punch, and his head follows it wherever it is near. The moves are
    /// right as they are; this only closes the last few centimetres to where the ball really is. Draws only.
    /// </summary>
    [ExecuteAlways]
    [RequireComponent(typeof(Animator))]
    public sealed class BallContact : MonoBehaviour
    {
        [System.Serializable]
        public struct Touch
        {
            [Tooltip("the move's name, as its state in Player.controller")]
            public string move;
            [Tooltip("seconds into the move the ball is met")]
            public float contact;
            [Tooltip("right, left, head or hands")]
            public string with;
        }

        /// <summary>The ball (MatchScene's, or the pictures'). None: he only moves as the move says.</summary>
        public Transform Ball;
        /// <summary>The moves that meet the ball and when (PlayerArt.touches, from takes.json).</summary>
        public Touch[] Touches;
        /// <summary>[U6] Beaten this minute (a goal past him): his dive goes the ball's way, his hands miss it.</summary>
        public bool Beaten;

        /// <summary>How long before and after the contact the foot or the hands are drawn to the ball (s).</summary>
        public const float Window = 0.16f;
        /// <summary>Further than this from where the move puts the foot or hands, the ball is not his to touch (m).</summary>
        public const float Reach = 1.1f;
        /// <summary>The head turns to a ball nearer than this (m).</summary>
        public const float Sight = 30f;

        /// <summary>What he is doing with the ball now: the touch and how strongly (0..1), for the tests.</summary>
        public string Now { get; private set; } = "";
        public float Weight { get; private set; }

        Animator animator;

        void OnAnimatorIK(int layer)
        {
            if (animator == null) animator = GetComponent<Animator>();
            Now = "";
            Weight = 0f;
            if (Ball == null || Touches == null) return;
            var ball = Ball.position;
            var head = animator.GetBoneTransform(HumanBodyBones.Head);
            float far = head != null ? Vector3.Distance(head.position, ball) : 0f;
            // the head follows the ball; in a header it is all on it
            float look = far < Sight ? Mathf.Lerp(0.8f, 0.35f, far / Sight) : 0f;

            if (Playing(out var touch, out float t))
            {
                float w = Mathf.Clamp01(1f - Mathf.Abs(t - touch.contact) / Window);
                w = w * w * (3f - 2f * w);   // eased in and out
                if (touch.with == "head")
                {
                    look = Mathf.Max(look, 0.6f + 0.4f * w);
                    Note(touch, w);
                }
                else if (touch.with == "hands")
                {
                    if (!Beaten) Hands(ball, w, touch);
                }
                else
                    Foot(touch.with == "left" ? AvatarIKGoal.LeftFoot : AvatarIKGoal.RightFoot, ball, w, touch);
            }
            animator.SetLookAtWeight(look, 0.1f, 0.8f, 1f, 0.6f);
            animator.SetLookAtPosition(ball);
        }

        /// <summary>The move he is in (the one he is blending into, during a blend), if it meets the ball, and how far into it (s).</summary>
        bool Playing(out Touch touch, out float t)
        {
            touch = default;
            t = 0f;
            var state = animator.IsInTransition(0) ? animator.GetNextAnimatorStateInfo(0) : animator.GetCurrentAnimatorStateInfo(0);
            foreach (var x in Touches)
            {
                if (Animator.StringToHash(x.move) != state.shortNameHash) continue;
                touch = x;
                t = state.normalizedTime * state.length;
                return true;
            }
            return false;
        }

        /// <summary>Where the ankle goes to strike the ball: behind its centre the way he faces, low, so the instep and toes meet it.</summary>
        public const float Behind = 0.12f;

        /// <summary>The kicking foot onto the ball (IK moves the ankle: it goes Behind the ball, the foot through it).</summary>
        void Foot(AvatarIKGoal goal, Vector3 ball, float w, Touch touch)
        {
            if (w <= 0f) return;
            var now = animator.GetIKPosition(goal);
            var at = ball - transform.forward * Behind;
            at.y = Mathf.Max(ball.y - 0.02f, 0.09f);
            if (Vector3.Distance(now, at) > Reach) return;
            animator.SetIKPositionWeight(goal, w);
            animator.SetIKPosition(goal, at);
            Note(touch, w);
        }

        /// <summary>The keeper's hands either side of the ball.</summary>
        void Hands(Vector3 ball, float w, Touch touch)
        {
            if (w <= 0f) return;
            var mid = (animator.GetIKPosition(AvatarIKGoal.LeftHand) + animator.GetIKPosition(AvatarIKGoal.RightHand)) / 2f;
            if (Vector3.Distance(mid, ball) > Reach * 1.6f) return;
            var across = Vector3.Cross(Vector3.up, (ball - transform.position).normalized);
            if (across.sqrMagnitude < 1e-4f) across = transform.right;
            across = across.normalized * (MatchScene.BallRadius + 0.02f);
            animator.SetIKPositionWeight(AvatarIKGoal.LeftHand, w);
            animator.SetIKPositionWeight(AvatarIKGoal.RightHand, w);
            // each hand to the side of the ball it is already nearer, so the arms never cross
            var l = animator.GetIKPosition(AvatarIKGoal.LeftHand);
            var r = animator.GetIKPosition(AvatarIKGoal.RightHand);
            bool plain = Vector3.Distance(l, ball + across) + Vector3.Distance(r, ball - across)
                         <= Vector3.Distance(l, ball - across) + Vector3.Distance(r, ball + across);
            animator.SetIKPosition(AvatarIKGoal.LeftHand, plain ? ball + across : ball - across);
            animator.SetIKPosition(AvatarIKGoal.RightHand, plain ? ball - across : ball + across);
            Note(touch, w);
        }

        void Note(Touch touch, float w)
        {
            Now = touch.move;
            Weight = w;
        }
    }
}
