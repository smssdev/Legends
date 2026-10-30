using UnityEngine;

namespace Legends
{
    /// <summary>
    /// [Sprint 26 U1] The two coaches by the touchline, each in the look he picked (C1 to C3, the Blender models of
    /// tools/unity/art/characters.py) and feeling each minute as the server says (CharacterMood). A club with no
    /// coach has nobody there. Draws only: the look and the mood both come from the server.
    /// </summary>
    public sealed class BenchCoaches : MonoBehaviour
    {
        [Tooltip("The models of C1, C2 and C3, in that order")]
        public GameObject[] looks = new GameObject[3];
        [Tooltip("Where each coach stands, in the scene's metres: the near touchline, either side of halfway")]
        public Vector3 homeSpot = new Vector3(-9, 0, -37.5f), awaySpot = new Vector3(9, 0, -37.5f);

        CharacterMood home, away;

        public void Setup(string homeLook, string awayLook)
        {
            if (home != null) Destroy(home.gameObject);
            if (away != null) Destroy(away.gameObject);
            home = Place(homeLook, homeSpot, "Home coach");
            away = Place(awayLook, awaySpot, "Away coach");
        }

        public void Feel(string homeMood, string awayMood)
        {
            if (home != null) home.SetMood(homeMood);
            if (away != null) away.SetMood(awayMood);
        }

        CharacterMood Place(string look, Vector3 at, string name)
        {
            int i = look == "C1" ? 0 : look == "C2" ? 1 : look == "C3" ? 2 : -1;
            if (i < 0 || i >= looks.Length || looks[i] == null) return null;
            var coach = Instantiate(looks[i], transform);
            coach.name = name;
            coach.transform.localPosition = at;
            TurnToCamera(coach.transform);
            return coach.AddComponent<CharacterMood>();   // after the turn: it reads the coach's directions as he stands
        }

        /// <summary>The coach faces the broadcast camera, whichever way the importer turned the model.</summary>
        static void TurnToCamera(Transform coach)
        {
            var cam = Camera.main;
            Transform head = null, nose = null;
            foreach (var t in coach.GetComponentsInChildren<Transform>(true))
            {
                if (t.name == "Head") head = t;
                else if (t.name == "Nose") nose = t;
            }
            if (cam == null || head == null || nose == null) return;
            var r = nose.GetComponent<Renderer>();
            Vector3 front = Vector3.ProjectOnPlane((r != null ? r.bounds.center : nose.position) - head.position, Vector3.up);
            Vector3 want = Vector3.ProjectOnPlane(cam.transform.position - coach.position, Vector3.up);
            if (front.sqrMagnitude < 1e-6f || want.sqrMagnitude < 1e-6f) return;
            coach.rotation = Quaternion.AngleAxis(Vector3.SignedAngle(front, want, Vector3.up), Vector3.up) * coach.rotation;
        }
    }
}
