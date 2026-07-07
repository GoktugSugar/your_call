using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Moves the imp around the void, but only once per dialogue box: each time a fresh line
    /// or page appears it hops, quick and springy, to a new valid spot and then settles there
    /// to deliver, holding still apart from its idle life. It never lands on content, rejecting
    /// any spot inside an active <see cref="ScreenKeepout"/> (the box, the current dilemma, the
    /// stats), and if content appears over it, it hops clear. One job: where the imp goes; the
    /// bob, breath and speak gesture stay on <see cref="ImpFigure"/>.
    /// </summary>
    public sealed class ImpRoamer : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private ImpFigure _imp;      // only move once it has appeared
        [SerializeField] private NarratorView _voice; // repositions on each new page it raises

        [Header("Roam area (world space)")]
        [Tooltip("The rectangle the imp's centre may travel within, before keep-outs.")]
        [SerializeField] private Rect _roamBounds = new Rect(-7.5f, -2.0f, 15f, 4.7f);
        [Tooltip("Never land closer than this to any content; the imp is roughly this wide, so keep it clear.")]
        [SerializeField] private float _minClearance = 0.9f;
        [Tooltip("Among clear spots, a small pull toward ones further away, for variety.")]
        [SerializeField] private float _travelBias = 0.15f;

        [Header("Hop")]
        [Tooltip("Time for one hop. Shorter = zippier.")]
        [SerializeField] private float _hopDurationMin = 0.28f;
        [SerializeField] private float _hopDurationMax = 0.5f;
        [Tooltip("Height of the little arc each hop makes.")]
        [SerializeField] private float _hopArc = 0.5f;
        [Tooltip("Springiness: overshoot past the landing before settling. 0 = none.")]
        [SerializeField, Range(0f, 2f)] private float _overshoot = 1.1f;
        [SerializeField] private int _pickTries = 48;

        [Header("Restless idle (menu)")]
        [Tooltip("0 = only hop when a new box appears (the opening). Above 0 = also hop on this cadence " +
                 "with no line at all, for a restless idle that never settles (the main menu).")]
        [SerializeField] private float _restlessInterval = 0f;
        [Tooltip("Randomises each restless wait by this fraction, so the hopping never feels metronomic.")]
        [SerializeField, Range(0f, 0.8f)] private float _restlessJitter = 0.35f;

        [Header("Safety")]
        [Tooltip("How often to check that content has not appeared over the imp, and hop it clear.")]
        [SerializeField] private float _blockedCheckInterval = 0.2f;

        private Coroutine _hop;
        private bool _hopping;
        private float _blockTimer;
        private float _restlessTimer;
        private float _restlessNext;

        private void OnEnable() { if (_voice != null) _voice.PageChanged += OnPage; }
        private void OnDisable() { if (_voice != null) _voice.PageChanged -= OnPage; }

        private void OnPage() { Reposition(preferFar: true); }

        private void Update()
        {
            if (_hopping) return;
            if (_imp != null && !_imp.Present) return;
            _blockTimer += Time.deltaTime;
            if (_blockTimer >= _blockedCheckInterval)
            {
                _blockTimer = 0f;
                if (Blocked(transform.position)) Reposition(preferFar: false); // content landed on us
            }

            // A restless idle with no line to prompt it: keep the menu imp hopping about the page.
            if (_restlessInterval > 0f)
            {
                if (_restlessNext <= 0f) _restlessNext = NextRestless();
                _restlessTimer += Time.deltaTime;
                if (_restlessTimer >= _restlessNext) Reposition(preferFar: true);
            }
        }

        private float NextRestless() => _restlessInterval * (1f + Random.Range(-_restlessJitter, _restlessJitter));

        private void Reposition(bool preferFar)
        {
            if (_imp != null && !_imp.Present) return;
            // Any reposition (a new box, a restless tick, a nudge off content) restarts the restless wait.
            _restlessTimer = 0f;
            _restlessNext = NextRestless();
            if (TryPick(preferFar, out Vector2 target)
                && (target - (Vector2)transform.position).sqrMagnitude > 0.0001f)
            {
                if (_hop != null) StopCoroutine(_hop);
                _hop = StartCoroutine(Hop(transform.position, target, Random.Range(_hopDurationMin, _hopDurationMax)));
            }
        }

        private bool TryPick(bool preferFar, out Vector2 result)
        {
            Vector2 best = transform.position;
            float bestScore = float.NegativeInfinity;
            bool found = false;

            // Prefer the spot with the most clearance from all content, nudged toward travelling.
            for (int i = 0; i < _pickTries; i++)
            {
                Vector2 p = RandomInBounds();
                float clear = Clearance(p);
                if (clear < _minClearance) continue;
                float travel = preferFar ? Vector2.Distance(p, transform.position) : 0f;
                float score = clear + travel * _travelBias;
                if (score > bestScore) { bestScore = score; best = p; found = true; }
            }
            if (found) { result = best; return true; }

            // Nothing met the clearance floor (space is tight): take the clearest spot going.
            for (int i = 0; i < _pickTries; i++)
            {
                Vector2 p = RandomInBounds();
                float clear = Clearance(p);
                if (clear > bestScore) { bestScore = clear; best = p; found = true; }
            }
            result = found ? best : (Vector2)transform.position;
            return found;
        }

        private Vector2 RandomInBounds()
            => new Vector2(Random.Range(_roamBounds.xMin, _roamBounds.xMax), Random.Range(_roamBounds.yMin, _roamBounds.yMax));

        /// <summary>Nearest distance from a point to any active keep-out (0 inside; large with none).</summary>
        private float Clearance(Vector2 p)
        {
            var list = ScreenKeepout.Active;
            float min = float.MaxValue;
            for (int i = 0; i < list.Count; i++)
            {
                if (list[i] == null) continue;
                float d = DistanceToRect(p, list[i].WorldRect);
                if (d < min) min = d;
            }
            return min == float.MaxValue ? 999f : min;
        }

        private static float DistanceToRect(Vector2 p, Rect r)
        {
            float dx = Mathf.Max(r.xMin - p.x, 0f, p.x - r.xMax);
            float dy = Mathf.Max(r.yMin - p.y, 0f, p.y - r.yMax);
            return Mathf.Sqrt(dx * dx + dy * dy);
        }

        private bool Blocked(Vector2 p) => Clearance(p) < _minClearance;

        private IEnumerator Hop(Vector2 from, Vector2 to, float dur)
        {
            _hopping = true;
            float d = Mathf.Max(dur, 0.05f), t = 0f, z = transform.position.z;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);
                Vector2 pos = Vector2.LerpUnclamped(from, to, EaseUtil.OutBack(k, _overshoot));
                pos.y += Mathf.Sin(k * Mathf.PI) * _hopArc;
                transform.position = new Vector3(pos.x, pos.y, z);
                yield return null;
            }
            transform.position = new Vector3(to.x, to.y, z);
            _hopping = false;
        }
    }
}
