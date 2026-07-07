using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The guide, embodied: a small hand-drawn imp (little horns, a tail, a grin) in pure
    /// black ink, no amber and no colour. It scribbles into being, keeps a tiny restless
    /// life, and leans in while its words ink on. It draws itself from a handful of ink
    /// strokes, the same way the Figure and Trolley do, so it can boil and fade as one.
    /// One job: be the imp on screen. The words themselves are the reused NarratorView.
    /// </summary>
    public class ImpFigure : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("The imp's single ink colour, driving every stroke. Palette.Ink (near-black) normally; " +
                 "temporarily set to amber for the imp-colour test. Reverting that experiment is just this " +
                 "one field back to black.")]
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private float _detailWidth = 0.04f;
        [SerializeField] private int _sortingOrder = 14;
        [SerializeField] private bool _boil = true;
        [SerializeField] private bool _startHidden = true;

        [Header("Size")]
        [Tooltip("Overall size, applied to the imp's transform. Tune to taste.")]
        [SerializeField] private float _scale = 1.55f;

        [Header("Idle life")]
        [Tooltip("Slow vertical bob height.")]
        [SerializeField] private float _bobAmplitude = 0.06f;
        [SerializeField] private float _bobPeriod = 2.4f;
        [Tooltip("Gentle rocking lean, in degrees.")]
        [SerializeField] private float _swayAngle = 3.5f;
        [SerializeField] private float _swayPeriod = 3.1f;
        [Tooltip("Subtle breath: a small scale pulse.")]
        [SerializeField] private float _breathAmount = 0.03f;
        [SerializeField] private float _breathPeriod = 2.7f;

        [Header("Speaking")]
        [Tooltip("Extra bob while a line inks on, so the imp reads as the one speaking.")]
        [SerializeField] private float _speakBob = 0.05f;
        [Tooltip("Lean it throws while speaking, in degrees, like a gesture.")]
        [SerializeField] private float _speakLean = 4f;
        [SerializeField] private float _speakPeriod = 0.5f;

        [Header("Pop in")]
        [SerializeField] private float _popScaleFrom = 0.15f;
        [SerializeField] private float _popWobble = 10f;

        [Tooltip("Optional: the narrator line this imp mouths, so it stirs while text inks on.")]
        [SerializeField] private NarratorView _voice;

        [Header("Expressions (revertible; off keeps the single default face)")]
        [Tooltip("Master toggle. Off: the imp keeps its single hand-drawn face, exactly as before. " +
                 "On: the face is drawn per the current expression, and a bark can change it.")]
        [SerializeField] private bool _useExpressions = false;
        [Tooltip("The face shown when nothing sets another (the neutral grin).")]
        [SerializeField] private ImpExpression _defaultExpression = ImpExpression.Grin;

        private Transform _rig;
        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private LineRenderer _eyeL, _eyeR, _mouth;   // expression face strokes (only when _useExpressions)
        private ImpExpression _expression;
        private float _alpha;
        private float _speakT;
        private bool _speaking;
        private bool _appearing;
        private bool _built;

        private void Awake() { Build(); }

        private void OnEnable() { if (_voice != null) _voice.Speaking += OnSpeaking; }
        private void OnDisable() { if (_voice != null) _voice.Speaking -= OnSpeaking; }

        public void Build()
        {
            if (_built) return;
            _rig = new GameObject("Rig").transform;
            _rig.SetParent(transform, false);

            BuildBody();
            BuildHeadAndHorns();
            BuildFace();
            BuildArms();
            BuildLegs();
            BuildTail();

            transform.localScale = new Vector3(_scale, _scale, 1f);
            _alpha = _startHidden ? 0f : 1f;
            ApplyAlpha();
            _built = true;
        }

        // ---------- Presence ----------

        /// <summary>Visible and settled (done appearing), so a roamer knows it may move it.</summary>
        public bool Present => _built && !_appearing && _alpha > 0.5f;

        public void SetAlpha(float a) { _alpha = Mathf.Clamp01(a); ApplyAlpha(); }

        /// <summary>Scribble into being: a quick alpha in with a scale pop and a little wobble.</summary>
        public IEnumerator PopIn(float duration)
        {
            if (!_built) Build();
            _appearing = true;
            float d = Mathf.Max(duration, 0.05f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);
                float s = Mathf.LerpUnclamped(_popScaleFrom, 1f, EaseUtil.OutBack(k));
                _rig.localScale = new Vector3(s, s, 1f);
                _rig.localRotation = Quaternion.Euler(0f, 0f, Mathf.Sin(k * Mathf.PI * 3f) * _popWobble * (1f - k));
                SetAlpha(EaseUtil.Clamp01(k * 1.4f));
                yield return null;
            }
            _rig.localScale = Vector3.one;
            _rig.localRotation = Quaternion.identity;
            SetAlpha(1f);
            _appearing = false;
        }

        private void OnSpeaking(bool on) { _speaking = on; }

        private void Update()
        {
            if (!_built || _rig == null || _appearing || _alpha <= 0.001f) return;
            _speakT = Mathf.MoveTowards(_speakT, _speaking ? 1f : 0f, Time.deltaTime / 0.18f);

            float t = Time.time;
            float speakOsc = Mathf.Sin(t * (Mathf.PI * 2f / Mathf.Max(_speakPeriod, 0.01f)));
            // Slow idle bob, plus a livelier nod while speaking.
            float bob = Mathf.Sin(t * (Mathf.PI * 2f / Mathf.Max(_bobPeriod, 0.01f))) * _bobAmplitude
                        + speakOsc * _speakBob * _speakT;
            // Gentle idle rocking, plus a lean it throws as a gesture while speaking.
            float lean = Mathf.Sin(t * (Mathf.PI * 2f / Mathf.Max(_swayPeriod, 0.01f))) * _swayAngle
                         + speakOsc * _speakLean * _speakT;
            // A subtle breath.
            float breath = 1f + Mathf.Sin(t * (Mathf.PI * 2f / Mathf.Max(_breathPeriod, 0.01f))) * _breathAmount;

            _rig.localPosition = new Vector3(0f, bob, 0f);
            _rig.localRotation = Quaternion.Euler(0f, 0f, lean);
            _rig.localScale = new Vector3(breath, breath, 1f);
        }

        // ---------- Drawing ----------

        private LineRenderer Stroke(string name, IList<Vector3> pts, float width) => Stroke(name, pts, width, _boil);

        private LineRenderer Stroke(string name, IList<Vector3> pts, float width, bool boil)
        {
            var lr = InkLine.Create(_rig, name, _inkMaterial, width, _color, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            if (boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _strokes.Add(lr);
            return lr;
        }

        private void BuildBody()
        {
            // A rounded bean torso: neck, down one side to the base, up the other. Rounded
            // corners on the LineRenderer soften it into a doodle body.
            var pts = new List<Vector3>
            {
                new Vector3(-0.05f, 0.46f, 0f),
                new Vector3(-0.19f, 0.30f, 0f),
                new Vector3(-0.16f, 0.10f, 0f),
                new Vector3(-0.07f, 0.03f, 0f),
                new Vector3(0.07f, 0.03f, 0f),
                new Vector3(0.16f, 0.10f, 0f),
                new Vector3(0.19f, 0.30f, 0f),
                new Vector3(0.05f, 0.46f, 0f),
            };
            Stroke("Body", pts, _lineWidth);
        }

        private void BuildHeadAndHorns()
        {
            var head = new List<Vector3>();
            InkLine.AddArc(head, new Vector2(0f, 0.62f), 0.19f, 0f, 360f, 22);
            Stroke("Head", head, _lineWidth);

            Stroke("HornL", new List<Vector3>
            {
                new Vector3(-0.11f, 0.76f, 0f),
                new Vector3(-0.17f, 0.87f, 0f),
                new Vector3(-0.23f, 1.0f, 0f),
            }, _detailWidth);
            Stroke("HornR", new List<Vector3>
            {
                new Vector3(0.11f, 0.76f, 0f),
                new Vector3(0.17f, 0.87f, 0f),
                new Vector3(0.23f, 1.0f, 0f),
            }, _detailWidth);
        }

        private void BuildFace()
        {
            if (!_useExpressions)
            {
                // Original single face: two slanted eyes and a wide little grin, mischief not menace.
                Stroke("EyeL", new List<Vector3> { new Vector3(-0.10f, 0.66f, 0f), new Vector3(-0.03f, 0.62f, 0f) }, _detailWidth);
                Stroke("EyeR", new List<Vector3> { new Vector3(0.10f, 0.66f, 0f), new Vector3(0.03f, 0.62f, 0f) }, _detailWidth);
                var grin = new List<Vector3>();
                InkLine.AddArc(grin, new Vector2(0f, 0.60f), 0.09f, 210f, 330f, 10);
                Stroke("Grin", grin, _detailWidth);
                return;
            }

            // Expression-driven face: three re-pointable strokes (no boil, so redrawing per expression is clean).
            _eyeL = Stroke("EyeL", new List<Vector3> { Vector3.zero, Vector3.zero }, _detailWidth, false);
            _eyeR = Stroke("EyeR", new List<Vector3> { Vector3.zero, Vector3.zero }, _detailWidth, false);
            _mouth = Stroke("Mouth", new List<Vector3> { Vector3.zero, Vector3.zero }, _detailWidth, false);
            _expression = _defaultExpression;
            ApplyExpression(_expression);
        }

        // ---------- Expressions (self-contained; only active when _useExpressions) ----------

        /// <summary>Set the imp's face. A no-op unless expressions are switched on, so it stays revertible.</summary>
        public void SetExpression(ImpExpression e)
        {
            if (!_useExpressions || !_built) return;
            _expression = e;
            ApplyExpression(e);
        }

        private void ApplyExpression(ImpExpression e)
        {
            if (_eyeL == null || _eyeR == null || _mouth == null) return;
            List<Vector3> eyeL, eyeR, mouth;
            FaceFor(e, out eyeL, out eyeR, out mouth);
            InkLine.SetPoints(_eyeL, eyeL);
            InkLine.SetPoints(_eyeR, eyeR);
            InkLine.SetPoints(_mouth, mouth);
        }

        // Eyes-and-mouth point sets per expression, on-model with the imp's head (face centred ~(0,0.62)).
        private static void FaceFor(ImpExpression e, out List<Vector3> eyeL, out List<Vector3> eyeR, out List<Vector3> mouth)
        {
            eyeL = new List<Vector3>();
            eyeR = new List<Vector3>();
            mouth = new List<Vector3>();
            switch (e)
            {
                case ImpExpression.WideGrin:
                    eyeL.Add(new Vector3(-0.11f, 0.67f, 0f)); eyeL.Add(new Vector3(-0.03f, 0.625f, 0f));
                    eyeR.Add(new Vector3(0.11f, 0.67f, 0f));  eyeR.Add(new Vector3(0.03f, 0.625f, 0f));
                    InkLine.AddArc(mouth, new Vector2(0f, 0.61f), 0.13f, 200f, 340f, 12);
                    break;
                case ImpExpression.Smug:
                    eyeL.Add(new Vector3(-0.11f, 0.645f, 0f)); eyeL.Add(new Vector3(-0.03f, 0.645f, 0f));
                    eyeR.Add(new Vector3(0.03f, 0.645f, 0f));  eyeR.Add(new Vector3(0.11f, 0.645f, 0f));
                    mouth.Add(new Vector3(-0.08f, 0.575f, 0f));
                    mouth.Add(new Vector3(0.02f, 0.57f, 0f));
                    mouth.Add(new Vector3(0.085f, 0.605f, 0f));
                    break;
                case ImpExpression.Glare:
                    eyeL.Add(new Vector3(-0.12f, 0.685f, 0f)); eyeL.Add(new Vector3(-0.02f, 0.625f, 0f));
                    eyeR.Add(new Vector3(0.12f, 0.685f, 0f));  eyeR.Add(new Vector3(0.02f, 0.625f, 0f));
                    mouth.Add(new Vector3(-0.07f, 0.55f, 0f));
                    mouth.Add(new Vector3(0f, 0.58f, 0f));
                    mouth.Add(new Vector3(0.07f, 0.55f, 0f));
                    break;
                case ImpExpression.Surprised:
                    InkLine.AddArc(eyeL, new Vector2(-0.065f, 0.645f), 0.028f, 0f, 360f, 12);
                    InkLine.AddArc(eyeR, new Vector2(0.065f, 0.645f), 0.028f, 0f, 360f, 12);
                    InkLine.AddArc(mouth, new Vector2(0f, 0.555f), 0.04f, 0f, 360f, 14);
                    break;
                default: // Grin: the original face
                    eyeL.Add(new Vector3(-0.10f, 0.66f, 0f)); eyeL.Add(new Vector3(-0.03f, 0.62f, 0f));
                    eyeR.Add(new Vector3(0.10f, 0.66f, 0f));  eyeR.Add(new Vector3(0.03f, 0.62f, 0f));
                    InkLine.AddArc(mouth, new Vector2(0f, 0.60f), 0.09f, 210f, 330f, 10);
                    break;
            }
        }

        private void BuildArms()
        {
            Stroke("ArmL", new List<Vector3>
            {
                new Vector3(-0.16f, 0.40f, 0f),
                new Vector3(-0.30f, 0.34f, 0f),
                new Vector3(-0.30f, 0.26f, 0f),
            }, _detailWidth);
            Stroke("ArmR", new List<Vector3>
            {
                new Vector3(0.16f, 0.40f, 0f),
                new Vector3(0.30f, 0.34f, 0f),
                new Vector3(0.30f, 0.26f, 0f),
            }, _detailWidth);
        }

        private void BuildLegs()
        {
            Stroke("LegL", new List<Vector3>
            {
                new Vector3(-0.07f, 0.03f, 0f),
                new Vector3(-0.10f, -0.05f, 0f),
                new Vector3(-0.17f, -0.06f, 0f),
            }, _detailWidth);
            Stroke("LegR", new List<Vector3>
            {
                new Vector3(0.07f, 0.03f, 0f),
                new Vector3(0.10f, -0.05f, 0f),
                new Vector3(0.17f, -0.06f, 0f),
            }, _detailWidth);
        }

        private void BuildTail()
        {
            // A curling tail out to a little spade tip.
            var tail = new List<Vector3>();
            Vector2 a = new Vector2(0.16f, 0.14f);
            Vector2 b = new Vector2(0.42f, 0.10f);
            Vector2 c = new Vector2(0.44f, 0.40f);
            for (int i = 0; i <= 14; i++)
            {
                float t = i / 14f, u = 1f - t;
                Vector2 p = u * u * a + 2f * u * t * b + t * t * c;
                tail.Add(new Vector3(p.x, p.y, 0f));
            }
            Stroke("Tail", tail, _detailWidth);

            Stroke("TailTip", new List<Vector3>
            {
                new Vector3(0.44f, 0.40f, 0f),
                new Vector3(0.38f, 0.47f, 0f),
                new Vector3(0.47f, 0.50f, 0f),
                new Vector3(0.50f, 0.42f, 0f),
                new Vector3(0.44f, 0.40f, 0f),
            }, _detailWidth);
        }

        private void ApplyAlpha()
        {
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _color, _alpha);
        }
    }
}
