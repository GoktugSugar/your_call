using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A clean, minimal doodle bear in black ink, front facing and sitting: a rounded body
    /// (a little wider than tall), a head circle overlapping it slightly at the neck, two ears
    /// drawn as open arc bumps on the head outline (not full circles laid over it), a small
    /// muzzle, and a minimal face (two dot eyes, a small nose, a tiny line-and-smile mouth).
    /// No arms; two little feet drawn as downward bumps whose tops follow the body's lower edge.
    /// The minimal, un-detailed face is what keeps her reading friendly rather than creepy. She
    /// carries no cub: the "last breeding female, every bear that will ever be" weight is carried
    /// by the imp's words alone. Like <see cref="Figure"/> she strikes, folds and fades as one
    /// unit with no strike lines. One component, one job; LineRenderers for the prototype,
    /// reposable later.
    /// </summary>
    public class BearFigure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private int _sortingOrder = 10;
        [SerializeField] private bool _boil = true;

        [Header("Body (a rounded blob, wider than tall; feet at local origin)")]
        [SerializeField] private float _bodyCenterY = 0.46f;
        [SerializeField] private float _bodyRadiusX = 0.52f;
        [SerializeField] private float _bodyRadiusY = 0.42f;

        [Header("Head (a circle, overlapping the body slightly at the neck)")]
        [SerializeField] private float _headCenterY = 1.15f;
        [SerializeField] private float _headRadius = 0.34f;

        [Header("Ears (open arc bumps on the head outline, curving outward)")]
        [Tooltip("Where each ear sits, in degrees to either side of the top of the head.")]
        [SerializeField, Range(0f, 70f)] private float _earOffsetDeg = 30f;
        [Tooltip("Half-width of each ear along the head outline, in degrees (its two feet on the head).")]
        [SerializeField, Range(4f, 40f)] private float _earSpreadDeg = 20f;
        [Tooltip("How far the ear bulges out past the head surface.")]
        [SerializeField] private float _earHeight = 0.12f;

        [Header("Muzzle (a small oval, low on the face)")]
        [SerializeField] private float _muzzleCenterY = 0.98f;
        [SerializeField] private float _muzzleRadiusX = 0.14f;
        [SerializeField] private float _muzzleRadiusY = 0.10f;

        [Header("Face (minimal: two dot eyes, a small nose, a tiny mouth)")]
        [SerializeField] private float _eyeRadius = 0.032f;
        [SerializeField] private float _eyeSpread = 0.13f;
        [SerializeField] private float _eyeY = 1.20f;
        [SerializeField] private float _noseRadius = 0.042f;

        [Header("Feet (downward bumps whose tops sit on the body's lower edge)")]
        [SerializeField] private float _footSpread = 0.26f;
        [Tooltip("Half-width of each foot along the body's lower edge.")]
        [SerializeField] private float _footHalfWidth = 0.14f;
        [Tooltip("How far each foot hangs below the body's lower edge.")]
        [SerializeField] private float _footDrop = 0.12f;

        [Header("Fold on strike")]
        [Tooltip("+1 topples toward +x.")]
        [SerializeField] private float _fallDirection = 1f;
        [SerializeField] private float _foldAngle = 82f;
        [SerializeField] private float _squash = 0.84f;
        [SerializeField] private float _anticipation = 6f;

        [Header("Appearance")]
        [Tooltip("Build fully faded out, so she can ink in later.")]
        [SerializeField] private bool _startHidden = false;

        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private readonly List<LineBoil> _boils = new List<LineBoil>();
        private bool _built;

        public bool IsStruck { get; private set; }

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;

            // Body and head.
            AddEllipse("Body", new Vector2(0f, _bodyCenterY), _bodyRadiusX, _bodyRadiusY, 34);
            AddCircle("Head", new Vector2(0f, _headCenterY), _headRadius, 26);

            // Ears: an open arc bump either side of the top of the head, curving outward.
            AddEar("EarL", 90f + _earOffsetDeg);
            AddEar("EarR", 90f - _earOffsetDeg);

            // Muzzle and the minimal face.
            AddEllipse("Muzzle", new Vector2(0f, _muzzleCenterY), _muzzleRadiusX, _muzzleRadiusY, 22);
            AddCircle("EyeL", new Vector2(-_eyeSpread, _eyeY), _eyeRadius, 10);
            AddCircle("EyeR", new Vector2(_eyeSpread, _eyeY), _eyeRadius, 10);

            float noseY = _muzzleCenterY + _muzzleRadiusY * 0.5f;
            AddCircle("Nose", new Vector2(0f, noseY), _noseRadius, 12);
            AddMouth(noseY - _noseRadius);

            // Two little feet tucked under the body.
            AddFoot("FootL", -_footSpread);
            AddFoot("FootR", _footSpread);

            if (_startHidden) SetInkAlpha(0f);
            _built = true;
        }

        // ---------- Parts ----------

        private void AddEar(string name, float centerDeg)
        {
            Vector2 hc = new Vector2(0f, _headCenterY);
            Vector2 p0 = hc + _headRadius * Dir(centerDeg + _earSpreadDeg);
            Vector2 p2 = hc + _headRadius * Dir(centerDeg - _earSpreadDeg);
            Vector2 apex = hc + (_headRadius + _earHeight) * Dir(centerDeg);
            AddBump(name, p0, p2, apex);
        }

        private void AddFoot(string name, float footX)
        {
            float x0 = footX - _footHalfWidth, x1 = footX + _footHalfWidth;
            Vector2 p0 = new Vector2(x0, BodyLowerEdgeY(x0));
            Vector2 p2 = new Vector2(x1, BodyLowerEdgeY(x1));
            Vector2 apex = new Vector2(footX, BodyLowerEdgeY(footX) - _footDrop);
            AddBump(name, p0, p2, apex);
        }

        /// <summary>A smooth bump from p0 to p2 that passes through apex (a quadratic curve whose
        /// endpoints stay on the host outline, so it only bulges outward and never crosses in).</summary>
        private void AddBump(string name, Vector2 p0, Vector2 p2, Vector2 apex, int segments = 16)
        {
            Vector2 control = 2f * apex - 0.5f * (p0 + p2);   // makes the curve reach apex at t = 0.5
            var pts = new List<Vector3>(segments + 1);
            for (int i = 0; i <= segments; i++)
            {
                float t = i / (float)segments, u = 1f - t;
                Vector2 p = u * u * p0 + 2f * u * t * control + t * t * p2;
                pts.Add(new Vector3(p.x, p.y, 0f));
            }
            CreateShape(name, pts);
        }

        private void AddMouth(float topY)
        {
            // A short line down from the nose, then a small, shallow smile.
            float lineBottom = _muzzleCenterY - _muzzleRadiusY * 0.35f;
            CreateShape("Philtrum", new List<Vector3>
            {
                new Vector3(0f, topY, 0f),
                new Vector3(0f, lineBottom, 0f),
            });

            Vector2 sl = new Vector2(-0.07f, lineBottom + 0.005f);
            Vector2 sr = new Vector2(0.07f, lineBottom + 0.005f);
            Vector2 apex = new Vector2(0f, lineBottom - 0.045f);
            AddBump("Smile", sl, sr, apex, 12);
        }

        private float BodyLowerEdgeY(float x)
        {
            float k = Mathf.Clamp(x / _bodyRadiusX, -1f, 1f);
            return _bodyCenterY - _bodyRadiusY * Mathf.Sqrt(Mathf.Max(0f, 1f - k * k));
        }

        private void AddEllipse(string name, Vector2 c, float rx, float ry, int segments)
        {
            var pts = new List<Vector3>(segments + 1);
            for (int i = 0; i <= segments; i++)
            {
                float a = Mathf.Deg2Rad * (360f * i / segments);
                pts.Add(new Vector3(c.x + Mathf.Cos(a) * rx, c.y + Mathf.Sin(a) * ry, 0f));
            }
            CreateShape(name, pts);
        }

        private void AddCircle(string name, Vector2 c, float r, int segments)
        {
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, c, r, 0f, 360f, segments);
            CreateShape(name, pts);
        }

        private void CreateShape(string name, List<Vector3> pts)
        {
            var lr = InkLine.Create(transform, name, _inkMaterial, _lineWidth, _color, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            if (_boil)
            {
                var b = lr.gameObject.AddComponent<LineBoil>();
                b.Capture();
                _boils.Add(b);
            }
            _strokes.Add(lr);
        }

        private static Vector2 Dir(float deg)
        {
            float a = deg * Mathf.Deg2Rad;
            return new Vector2(Mathf.Cos(a), Mathf.Sin(a));
        }

        // ---------- Presence & death (unchanged) ----------

        /// <summary>Set the ink alpha directly, so she can ink in or dissolve without folding.
        /// Strike still owns the fold-and-fade on impact.</summary>
        public void SetInkAlpha(float alpha)
        {
            if (!_built) Build();
            float a = Mathf.Clamp01(alpha);
            for (int i = 0; i < _strokes.Count; i++) InkLine.SetAlpha(_strokes[i], _color, a);
        }

        /// <summary>Fold and fade as one unit, then leave nothing behind. No strike lines or impact
        /// puff, matching the established death effect.</summary>
        public void Strike(float foldDuration)
        {
            if (IsStruck) return;
            IsStruck = true;
            for (int i = 0; i < _boils.Count; i++) if (_boils[i] != null) _boils[i].enabled = false;
            StartCoroutine(FoldAndFade(Mathf.Max(foldDuration, 0.05f)));
        }

        private IEnumerator FoldAndFade(float dur)
        {
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
                for (int i = 0; i < _strokes.Count; i++) InkLine.SetAlpha(_strokes[i], _color, 1f - fadeK);
                yield return null;
            }
            for (int i = 0; i < _strokes.Count; i++) InkLine.SetAlpha(_strokes[i], _color, 0f);
            gameObject.SetActive(false);
        }
    }
}
