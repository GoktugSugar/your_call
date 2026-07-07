using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A clean single-silhouette stick figure drawn as one continuous ink stroke with
    /// rounded joints and no joint dots. Built to be reposed later on Unity 2D Animation;
    /// for the prototype it is one LineRenderer, so it strikes, folds and fades as one
    /// unit with one alpha and leaves nothing behind. One component, one job.
    /// </summary>
    public class Figure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = new Color(0.106f, 0.102f, 0.090f, 1f);
        [SerializeField] private float _lineWidth = 0.045f;
        [SerializeField] private int _sortingOrder = 10;
        [SerializeField] private bool _boil = true;

        [Header("Proportions (feet at local origin, +y up)")]
        [SerializeField] private float _headRadius = 0.12f;
        [SerializeField] private float _hipY = 0.42f;
        [SerializeField] private float _shoulderY = 0.66f;
        [SerializeField] private float _neckY = 0.72f;
        [SerializeField] private float _armSpan = 0.22f;
        [SerializeField] private float _armDrop = 0.14f;
        [SerializeField] private float _legSpan = 0.17f;
        [SerializeField, Range(8, 28)] private int _headSegments = 18;

        [Header("Fold on strike")]
        [Tooltip("+1 topples toward +x (the trolley's travel direction).")]
        [SerializeField] private float _fallDirection = 1f;
        [SerializeField] private float _foldAngle = 84f;
        [SerializeField] private float _squash = 0.82f;
        [SerializeField] private float _anticipation = 6f;

        [Header("Appearance")]
        [Tooltip("Build fully faded out, so it can ink in later (the player waking in the void).")]
        [SerializeField] private bool _startHidden = false;

        private LineRenderer _lr;
        private LineBoil _boilComp;
        private Color _baseColor;
        private bool _built;
        private bool _hornsOn;

        public bool IsStruck { get; private set; }

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _baseColor = _color;
            _lr = InkLine.Create(transform, "Ink", _inkMaterial, _lineWidth, _color, _sortingOrder);
            InkLine.SetPoints(_lr, BuildStroke());
            if (_boil)
            {
                _boilComp = _lr.gameObject.AddComponent<LineBoil>();
                _boilComp.Capture();
            }
            if (_startHidden) InkLine.SetAlpha(_lr, _baseColor, 0f);
            _built = true;
        }

        /// <summary>Set the ink alpha directly, so the figure can ink in or dissolve without
        /// folding (the player waking, or quietly stepping out of a scene). Strike still owns
        /// the fold-and-fade on impact.</summary>
        public void SetInkAlpha(float alpha)
        {
            if (!_built) Build();
            if (_lr != null) InkLine.SetAlpha(_lr, _baseColor, Mathf.Clamp01(alpha));
        }

        /// <summary>Add small doodle devil horns (plain black ink, part of the one stroke, so they
        /// fold and fade with the figure). A per-dilemma gag on the branded wretches only.</summary>
        public void ShowHorns()
        {
            if (!_built) Build();
            if (_hornsOn) return;
            _hornsOn = true;
            InkLine.SetPoints(_lr, BuildStroke());   // rebuild the same stroke, now with horns
            if (_boilComp != null) _boilComp.Capture();
        }

        private List<Vector3> BuildStroke()
        {
            var pts = new List<Vector3>(32);
            var leftHand = new Vector3(-_armSpan, _shoulderY - _armDrop, 0f);
            var rightHand = new Vector3(_armSpan, _shoulderY - _armDrop, 0f);
            var shoulder = new Vector3(0f, _shoulderY, 0f);
            var hip = new Vector3(0f, _hipY, 0f);
            var leftFoot = new Vector3(-_legSpan, 0f, 0f);
            var rightFoot = new Vector3(_legSpan, 0f, 0f);
            var headCenter = new Vector2(0f, _neckY + _headRadius);

            // One stroke: left arm -> up the neck -> around the head -> torso -> both legs -> right arm.
            pts.Add(leftHand);
            pts.Add(shoulder);
            if (_hornsOn) AddHornedHead(pts, headCenter);
            else InkLine.AddArc(pts, headCenter, _headRadius, -90f, 270f, _headSegments); // seals at the neck
            pts.Add(shoulder);
            pts.Add(hip);
            pts.Add(leftFoot);
            pts.Add(hip);
            pts.Add(rightFoot);
            pts.Add(hip);
            pts.Add(shoulder);
            pts.Add(rightHand);
            return pts;
        }

        // The head arc broken at the top by two small horns, each a spike out to a tip and back,
        // so the whole figure stays one continuous stroke (and fades as one).
        private void AddHornedHead(List<Vector3> pts, Vector2 c)
        {
            float r = _headRadius;
            float hl = r * 1.15f;
            InkLine.AddArc(pts, c, r, -90f, 55f, 8);                 // neck up the right side to the horn base
            Vector2 baseR = c + r * AngleDir(55f);
            pts.Add(new Vector3(baseR.x + hl * 0.34f, baseR.y + hl * 0.94f, 0f)); // right horn tip (up, a little out)
            pts.Add(new Vector3(baseR.x, baseR.y, 0f));
            InkLine.AddArc(pts, c, r, 55f, 125f, 4);                 // across the crown between the horns
            Vector2 baseL = c + r * AngleDir(125f);
            pts.Add(new Vector3(baseL.x - hl * 0.34f, baseL.y + hl * 0.94f, 0f)); // left horn tip
            pts.Add(new Vector3(baseL.x, baseL.y, 0f));
            InkLine.AddArc(pts, c, r, 125f, 270f, 8);                // down the left side back to the neck
        }

        private static Vector2 AngleDir(float deg)
        {
            float a = deg * Mathf.Deg2Rad;
            return new Vector2(Mathf.Cos(a), Mathf.Sin(a));
        }

        /// <summary>Fold and fade as one unit, then leave nothing behind.</summary>
        public void Strike(float foldDuration)
        {
            if (IsStruck) return;
            IsStruck = true;
            if (_boilComp != null) _boilComp.enabled = false;
            StartCoroutine(FoldAndFade(Mathf.Max(foldDuration, 0.05f)));
        }

        private IEnumerator FoldAndFade(float dur)
        {
            // A small flinch back before it goes over.
            float ta = Mathf.Min(0.08f, dur * 0.25f);
            var up = Quaternion.identity;
            var back = Quaternion.Euler(0f, 0f, _anticipation * _fallDirection);
            float t = 0f;
            while (t < ta) { t += Time.deltaTime; transform.localRotation = Quaternion.Slerp(up, back, EaseUtil.OutCubic(t / ta)); yield return null; }

            var target = Quaternion.Euler(0f, 0f, -_foldAngle * _fallDirection);
            var s0 = Vector3.one;
            var s1 = new Vector3(1f, _squash, 1f);
            t = 0f;
            while (t < dur)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / dur);
                transform.localRotation = Quaternion.Slerp(back, target, k);
                transform.localScale = Vector3.Lerp(s0, s1, k);
                float fadeK = EaseUtil.Clamp01((t - dur * 0.25f) / (dur * 0.75f));
                InkLine.SetAlpha(_lr, _baseColor, 1f - fadeK);
                yield return null;
            }
            InkLine.SetAlpha(_lr, _baseColor, 0f);
            gameObject.SetActive(false);
        }
    }
}
