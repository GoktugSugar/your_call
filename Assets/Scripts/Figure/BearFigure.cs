using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A hand-drawn doodle bear in black ink, front facing, built from rounded ink strokes
    /// (a round body, a head with ears, a muzzle with dot eyes, stubby paws) so she reads as a
    /// bear at a glance without bespoke art. A small cub can be drawn at her side as a subtle,
    /// understated cue that she carries the whole future of her kind; the imp's words carry the
    /// weight, not the picture. Like <see cref="Figure"/> she strikes, folds and fades as one
    /// unit with no strike lines, so a shot bear matches the game's established death effect.
    /// One component, one job; built for the prototype from LineRenderers, reposable later.
    /// </summary>
    public class BearFigure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private int _sortingOrder = 10;
        [SerializeField] private bool _boil = true;

        [Header("Body & head (feet at local origin, +y up)")]
        [SerializeField] private float _bodyRadius = 0.5f;
        [SerializeField] private float _headRadius = 0.36f;
        [SerializeField] private float _headCenterY = 1.12f;
        [SerializeField] private float _earRadius = 0.13f;
        [Tooltip("How far the ears sit around the top of the head, in degrees from vertical.")]
        [SerializeField, Range(0f, 80f)] private float _earAngle = 34f;

        [Header("Face")]
        [SerializeField] private float _muzzleRadius = 0.16f;
        [SerializeField] private float _muzzleCenterY = 0.96f;
        [SerializeField] private float _noseRadius = 0.06f;
        [SerializeField] private float _eyeRadius = 0.033f;
        [SerializeField] private float _eyeSpread = 0.14f;
        [SerializeField] private float _eyeY = 1.2f;

        [Header("Limbs")]
        [SerializeField] private float _legSpread = 0.24f;
        [SerializeField] private float _legLength = 0.18f;
        [SerializeField] private bool _showArms = true;
        [SerializeField] private float _armSpread = 0.52f;
        [SerializeField] private float _armDrop = 0.34f;

        [Header("Cub (the subtle stakes cue)")]
        [Tooltip("Draw a small cub at her side: an understated sign she carries the future of her kind. Black ink, kept small; not a crowd of ghost bears.")]
        [SerializeField] private bool _showCub = true;
        [SerializeField] private Vector2 _cubOffset = new Vector2(0.66f, 0f);
        [SerializeField, Range(0.2f, 0.8f)] private float _cubScale = 0.48f;

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
            BuildSilhouette(Vector2.zero, 1f);              // the mother
            if (_showCub) BuildSilhouette(_cubOffset, _cubScale);  // the cub cue at her side
            if (_startHidden) SetInkAlpha(0f);
            _built = true;
        }

        /// <summary>Build one bear silhouette in feet space, mapped to origin and scaled about her feet.</summary>
        private void BuildSilhouette(Vector2 origin, float scale)
        {
            AddCircle("Body", new Vector2(0f, _bodyRadius), _bodyRadius, origin, scale, 30);

            Vector2 head = new Vector2(0f, _headCenterY);
            AddCircle("Head", head, _headRadius, origin, scale, 26);
            AddCircle("EarL", head + Rotate(new Vector2(0f, _headRadius), _earAngle), _earRadius, origin, scale, 14);
            AddCircle("EarR", head + Rotate(new Vector2(0f, _headRadius), -_earAngle), _earRadius, origin, scale, 14);

            AddCircle("Muzzle", new Vector2(0f, _muzzleCenterY), _muzzleRadius, origin, scale, 18);
            AddCircle("Nose", new Vector2(0f, _muzzleCenterY + _muzzleRadius * 0.55f), _noseRadius, origin, scale, 12);
            AddCircle("EyeL", new Vector2(-_eyeSpread, _eyeY), _eyeRadius, origin, scale, 10);
            AddCircle("EyeR", new Vector2(_eyeSpread, _eyeY), _eyeRadius, origin, scale, 10);

            AddStroke("LegL", new Vector2(-_legSpread, _legLength), new Vector2(-_legSpread, 0f), origin, scale);
            AddStroke("LegR", new Vector2(_legSpread, _legLength), new Vector2(_legSpread, 0f), origin, scale);

            if (_showArms)
            {
                float shoulderY = _bodyRadius * 1.16f;
                AddStroke("ArmL", new Vector2(-_bodyRadius * 0.86f, shoulderY), new Vector2(-_armSpread, shoulderY - _armDrop), origin, scale);
                AddStroke("ArmR", new Vector2(_bodyRadius * 0.86f, shoulderY), new Vector2(_armSpread, shoulderY - _armDrop), origin, scale);
            }
        }

        private void AddCircle(string name, Vector2 center, float radius, Vector2 origin, float scale, int segments)
        {
            Vector2 c = origin + scale * center;
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, c, radius * scale, 0f, 360f, segments);
            CreateShape(name, pts);
        }

        private void AddStroke(string name, Vector2 a, Vector2 b, Vector2 origin, float scale)
        {
            Vector2 aa = origin + scale * a;
            Vector2 bb = origin + scale * b;
            CreateShape(name, new List<Vector3> { new Vector3(aa.x, aa.y, 0f), new Vector3(bb.x, bb.y, 0f) });
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

        /// <summary>Set the ink alpha directly (mother and cub together), so she can ink in or dissolve
        /// without folding. Strike still owns the fold-and-fade on impact.</summary>
        public void SetInkAlpha(float alpha)
        {
            if (!_built) Build();
            float a = Mathf.Clamp01(alpha);
            for (int i = 0; i < _strokes.Count; i++) InkLine.SetAlpha(_strokes[i], _color, a);
        }

        /// <summary>Fold and fade as one unit (mother and cub together), then leave nothing behind.
        /// No strike lines or impact puff, matching the established death effect.</summary>
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

        private static Vector2 Rotate(Vector2 v, float deg)
        {
            float a = deg * Mathf.Deg2Rad;
            float c = Mathf.Cos(a), s = Mathf.Sin(a);
            return new Vector2(v.x * c - v.y * s, v.x * s + v.y * c);
        }
    }
}
