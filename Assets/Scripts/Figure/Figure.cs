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

        private LineRenderer _lr;
        private LineBoil _boilComp;
        private Color _baseColor;
        private bool _built;

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
            _built = true;
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
