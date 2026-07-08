using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

namespace YourCall
{
    /// <summary>
    /// A clean single-silhouette stick figure drawn as ink strokes with rounded joints and no
    /// joint dots. Built to be reposed later on Unity 2D Animation; for the prototype it is a set
    /// of LineRenderers whose outline can be recoloured to a brand red for the damned wretches. It
    /// strikes, folds and fades as one unit and leaves nothing behind. One job.
    ///
    /// The shape is a <see cref="BuildShape"/> seam so on-model relatives (a baby, a pregnant
    /// woman) can subclass and redraw only their strokes, inheriting the ink, brand, fold and fade
    /// unchanged. The default shape is the single stick stroke, exactly as before.
    /// </summary>
    public class Figure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = new Color(0.106f, 0.102f, 0.090f, 1f);
        [SerializeField] private float _lineWidth = 0.045f;
        [SerializeField] private int _sortingOrder = 10;
        [SerializeField] private bool _boil = true;
        [Tooltip("Outline colour for the branded wretches (the whose-life-counts second trolley): a deliberate red that marks the damned five. Reuses the button red; see art-and-ui.md.")]
        [FormerlySerializedAs("_hornColor")]
        [SerializeField] private Color _brandColor = Palette.InkRed;

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

        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private readonly List<LineBoil> _boils = new List<LineBoil>();
        private Color _baseColor;
        private bool _built;
        private bool _branded;

        public bool IsStruck { get; private set; }

        // Exposed to subclasses that draw their own shape.
        protected float LineWidth => _lineWidth;
        protected float HeadRadius => _headRadius;
        protected int HeadSegments => _headSegments;
        protected float HipY => _hipY;
        protected float ShoulderY => _shoulderY;
        protected float NeckY => _neckY;
        protected float ArmSpan => _armSpan;
        protected float ArmDrop => _armDrop;
        protected float LegSpan => _legSpan;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _baseColor = _color;
            BuildShape();
            if (_startHidden) SetInkAlpha(0f);
            _built = true;
        }

        /// <summary>Add one ink stroke to the figure (registered so it inks, brands, folds and fades as
        /// one). Subclasses build their shape by calling this. A width of 0 or less uses the figure's line
        /// width.</summary>
        protected LineRenderer AddStroke(string name, List<Vector3> points, float width = 0f)
        {
            float w = width > 0f ? width : _lineWidth;
            var lr = InkLine.Create(transform, name, _inkMaterial, w, _color, _sortingOrder);
            InkLine.SetPoints(lr, points);
            if (_boil)
            {
                var b = lr.gameObject.AddComponent<LineBoil>();
                b.Capture();
                _boils.Add(b);
            }
            _strokes.Add(lr);
            return lr;
        }

        /// <summary>Draw the figure's ink. Default: the single stick stroke. Override to repose it into an
        /// on-model relative (a baby, a pregnant woman), reusing <see cref="AddStroke"/>.</summary>
        protected virtual void BuildShape()
        {
            AddStroke("Ink", BuildStickStroke());
        }

        private List<Vector3> BuildStickStroke()
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

        /// <summary>Set the ink alpha directly, so the figure can ink in or dissolve without folding
        /// (the player waking, or quietly stepping out of a scene). Strike still owns the fold-and-fade
        /// on impact.</summary>
        public void SetInkAlpha(float alpha)
        {
            if (!_built) Build();
            float a = Mathf.Clamp01(alpha);
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _baseColor, a);
        }

        /// <summary>Mark this figure as one of the damned: recolour its whole outline to the brand
        /// colour (red), used for the branded wretches in the whose-life-counts second trolley. A
        /// deliberate red on the black-ink base (see art-and-ui.md); the innocent figures stay black.</summary>
        public void Brand() => Brand(_brandColor);

        /// <summary>Recolour the whole outline to a deliberate colour (red for the guilty, pink for the
        /// player's partner), on the black-ink base. The colour becomes the base, so it inks, folds and
        /// fades in that colour. Ordinary figures are left black.</summary>
        public void Brand(Color color)
        {
            if (!_built) Build();
            _branded = true;
            _baseColor = color;
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetColor(_strokes[i], color);
        }

        /// <summary>Fold and fade as one unit, then leave nothing behind.</summary>
        public void Strike(float foldDuration)
        {
            if (IsStruck) return;
            IsStruck = true;
            for (int i = 0; i < _boils.Count; i++) if (_boils[i] != null) _boils[i].enabled = false;
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
                for (int i = 0; i < _strokes.Count; i++)
                    if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _baseColor, 1f - fadeK);
                yield return null;
            }
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _baseColor, 0f);
            gameObject.SetActive(false);
        }
    }
}
