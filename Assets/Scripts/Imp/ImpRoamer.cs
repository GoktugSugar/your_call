using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Moves the imp around the empty void with hyperactive, impish energy: quick springy
    /// hops between random spots, never parked. It only roams the free space, rejecting any
    /// target inside an active <see cref="ScreenKeepout"/> (the dialogue box, the current
    /// dilemma tableau, the stats), so it never crowds content. While a line is on screen it
    /// drifts lower, near its words, and fidgets a little less. One job: where the imp goes.
    /// The local liveliness (bob, breath, gesture) stays on <see cref="ImpFigure"/>.
    /// </summary>
    public sealed class ImpRoamer : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private ImpFigure _imp;      // only roam once it has appeared
        [SerializeField] private NarratorView _voice; // calm and drift low while it talks

        [Header("Roam area (world space)")]
        [Tooltip("The rectangle the imp's centre may travel within (before keep-outs).")]
        [SerializeField] private Rect _roamBounds = new Rect(-7.5f, -2.4f, 15f, 5.3f);
        [Tooltip("Extra clearance kept around every keep-out region.")]
        [SerializeField] private float _keepoutMargin = 0.5f;

        [Header("Restlessness")]
        [Tooltip("Pause between hops. Shorter = more hyperactive.")]
        [SerializeField] private float _pauseMin = 0.12f;
        [SerializeField] private float _pauseMax = 0.55f;
        [Tooltip("Multiplies the pause while a line is on screen, so it settles a touch to talk.")]
        [SerializeField] private float _speakingPauseScale = 1.8f;

        [Header("Hop")]
        [Tooltip("Time for one hop. Shorter = faster, zippier.")]
        [SerializeField] private float _hopDurationMin = 0.22f;
        [SerializeField] private float _hopDurationMax = 0.42f;
        [Tooltip("Height of the little arc each hop makes.")]
        [SerializeField] private float _hopArc = 0.7f;
        [Tooltip("Reject targets closer than this, so hops actually travel.")]
        [SerializeField] private float _minHopDistance = 1.4f;
        [SerializeField] private int _pickTries = 24;

        [Header("Speaking drift")]
        [Tooltip("While a line shows, keep to the lower part of the roam area (near the box). 0 = box edge only, 1 = full height.")]
        [SerializeField, Range(0.1f, 1f)] private float _speakLowBand = 0.4f;

        private void Start()
        {
            StartCoroutine(RoamLoop());
        }

        private IEnumerator RoamLoop()
        {
            while (true)
            {
                while (_imp != null && !_imp.Present) yield return null;

                bool speaking = _voice != null && _voice.HasLine;
                float pause = Random.Range(_pauseMin, _pauseMax) * (speaking ? _speakingPauseScale : 1f);
                yield return new WaitForSeconds(pause);

                Vector2 target = PickTarget(_voice != null && _voice.HasLine);
                yield return Hop(transform.position, target, Random.Range(_hopDurationMin, _hopDurationMax));
            }
        }

        private Vector2 PickTarget(bool speaking)
        {
            // While speaking, prefer the low band near the box; but if that is all blocked
            // (a dilemma fills the lower screen), fall back to the full height so the imp still
            // finds the free top strip and hops clear of the content instead of freezing on it.
            Vector2 target;
            if (speaking)
            {
                float lowTop = Mathf.Lerp(_roamBounds.yMin, _roamBounds.yMax, _speakLowBand);
                if (TryPick(_roamBounds.yMin, lowTop, out target)) return target;
            }
            if (TryPick(_roamBounds.yMin, _roamBounds.yMax, out target)) return target;
            return transform.position; // nowhere free and far enough: stay put
        }

        private bool TryPick(float yMin, float yMax, out Vector2 result)
        {
            for (int i = 0; i < _pickTries; i++)
            {
                float x = Random.Range(_roamBounds.xMin, _roamBounds.xMax);
                float y = Random.Range(yMin, yMax);
                Vector2 p = new Vector2(x, y);
                if (Vector2.Distance(p, transform.position) < _minHopDistance) continue;
                if (Blocked(p)) continue;
                result = p; return true;
            }
            result = Vector2.zero; return false;
        }

        private bool Blocked(Vector2 p)
        {
            var list = ScreenKeepout.Active;
            for (int i = 0; i < list.Count; i++)
                if (list[i] != null && list[i].Contains(p, _keepoutMargin)) return true;
            return false;
        }

        private IEnumerator Hop(Vector2 from, Vector2 to, float dur)
        {
            float d = Mathf.Max(dur, 0.05f), t = 0f, z = transform.position.z;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);
                // Springy ease that overshoots and settles, plus a little vertical hop arc.
                Vector2 pos = Vector2.LerpUnclamped(from, to, EaseUtil.OutBack(k));
                pos.y += Mathf.Sin(k * Mathf.PI) * _hopArc;
                transform.position = new Vector3(pos.x, pos.y, z);
                yield return null;
            }
            transform.position = new Vector3(to.x, to.y, z);
        }
    }
}
