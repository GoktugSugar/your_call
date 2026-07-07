using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A clean single-silhouette stick figure drawn as one continuous ink stroke with
    /// rounded joints and no joint dots. Built to be reposed later on Unity 2D Animation;
    /// for the prototype it is a LineRenderer (plus optional horn strokes), so it strikes,
    /// folds and fades as one unit and leaves nothing behind. One component, one job.
    /// </summary>
    public class Figure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = new Color(0.106f, 0.102f, 0.090f, 1f);
        [SerializeField] private float _lineWidth = 0.045f;
        [SerializeField] private int _sortingOrder = 10;
        [SerializeField] private bool _boil = true;
        [Tooltip("Colour of the branded wretches' devil horns. Red is a documented second colour exception; see decisions.md.")]
        [SerializeField] private Color _hornColor = Palette.InkRed;

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
        private readonly List<LineRenderer> _horns = new List<LineRenderer>();

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
            if (_startHidden) SetInkAlpha(0f);
            _built = true;
        }

        /// <summary>Set the ink alpha directly (body and any horns), so the figure can ink in or
        /// dissolve without folding (the player waking, or quietly stepping out of a scene). Strike
        /// still owns the fold-and-fade on impact.</summary>
        public void SetInkAlpha(float alpha)
        {
            if (!_built) Build();
            float a = Mathf.Clamp01(alpha);
            if (_lr != null) InkLine.SetAlpha(_lr, _baseColor, a);
            for (int i = 0; i < _horns.Count; i++) InkLine.SetAlpha(_horns[i], _hornColor, a);
        }

        /// <summary>Add small doodle devil horns as their own red strokes, parented to the figure so
        /// they fold and fade with it. Red is a documented second colour exception (see
        /// decisions.md); a per-dilemma gag on the branded wretches only.</summary>
        public void ShowHorns()
        {
            if (!_built) Build();
            if (_hornsOn) return;
            _hornsOn = true;
            Vector2 c = new Vector2(0f, _neckY + _headRadius);
            float r = _headRadius, hl = r * 1.15f;
            Vector2 baseR = c + r * AngleDir(55f);
            AddHorn("HornR", baseR, new Vector2(baseR.x + hl * 0.34f, baseR.y + hl * 0.94f));
            Vector2 baseL = c + r * AngleDir(125f);
            AddHorn("HornL", baseL, new Vector2(baseL.x - hl * 0.34f, baseL.y + hl * 0.94f));
        }

        private void AddHorn(string name, Vector2 basePt, Vector2 tip)
        {
            var lr = InkLine.Create(transform, name, _inkMaterial, _lineWidth, _hornColor, _sortingOrder + 1);
            InkLine.SetPoints(lr, new List<Vector3> { new Vector3(basePt.x, basePt.y, 0f), new Vector3(tip.x, tip.y, 0f) });
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _horns.Add(lr);
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
            InkLine.AddArc(pts, headCenter, _headRadius, -90f, 270f, _headSegments); // seals at the neck
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

        private static Vector2 AngleDir(float deg)
        {
            float a = deg * Mathf.Deg2Rad;
            return new Vector2(Mathf.Cos(a), Mathf.Sin(a));
        }

        /// <summary>Fold and fade as one unit (body and horns together), then leave nothing behind.</summary>
        public void Strike(float foldDuration)
        {
            if (IsStruck) return;
            IsStruck = true;
            if (_boilComp != null) _boilComp.enabled = false;
            for (int i = 0; i < _horns.Count; i++) { var b = _horns[i].GetComponent<LineBoil>(); if (b != null) b.enabled = false; }
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
                for (int i = 0; i < _horns.Count; i++) InkLine.SetAlpha(_horns[i], _hornColor, 1f - fadeK);
                yield return null;
            }
            InkLine.SetAlpha(_lr, _baseColor, 0f);
            for (int i = 0; i < _horns.Count; i++) InkLine.SetAlpha(_horns[i], _hornColor, 0f);
            gameObject.SetActive(false);
        }
    }
}
