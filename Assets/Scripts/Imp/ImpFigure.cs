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
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private float _detailWidth = 0.04f;
        [SerializeField] private int _sortingOrder = 14;
        [SerializeField] private bool _boil = true;
        [SerializeField] private bool _startHidden = true;

        [Header("Life")]
        [Tooltip("Idle bob height.")]
        [SerializeField] private float _bobAmplitude = 0.05f;
        [SerializeField] private float _bobPeriod = 2.3f;
        [Tooltip("Extra bob while a line is inking on, so the imp reads as the one speaking.")]
        [SerializeField] private float _speakBob = 0.06f;
        [SerializeField] private float _speakPeriod = 0.42f;

        [Header("Pop in")]
        [SerializeField] private float _popScaleFrom = 0.15f;
        [SerializeField] private float _popWobble = 10f;

        [Tooltip("Optional: the narrator line this imp mouths, so it stirs while text inks on.")]
        [SerializeField] private NarratorView _voice;

        private Transform _rig;
        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private float _alpha;
        private float _speakT;
        private bool _speaking;
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

            _alpha = _startHidden ? 0f : 1f;
            ApplyAlpha();
            _built = true;
        }

        // ---------- Presence ----------

        public void SetAlpha(float a) { _alpha = Mathf.Clamp01(a); ApplyAlpha(); }

        /// <summary>Scribble into being: a quick alpha in with a scale pop and a little wobble.</summary>
        public IEnumerator PopIn(float duration)
        {
            if (!_built) Build();
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
        }

        private void OnSpeaking(bool on) { _speaking = on; }

        private void Update()
        {
            if (!_built || _rig == null) return;
            _speakT = Mathf.MoveTowards(_speakT, _speaking ? 1f : 0f, Time.deltaTime / 0.18f);

            float y = Mathf.Sin(Time.time * (Mathf.PI * 2f / Mathf.Max(_bobPeriod, 0.01f))) * _bobAmplitude;
            y += Mathf.Sin(Time.time * (Mathf.PI * 2f / Mathf.Max(_speakPeriod, 0.01f))) * _speakBob * _speakT;
            var p = _rig.localPosition;
            _rig.localPosition = new Vector3(p.x, y, p.z);
        }

        // ---------- Drawing ----------

        private LineRenderer Stroke(string name, IList<Vector3> pts, float width)
        {
            var lr = InkLine.Create(_rig, name, _inkMaterial, width, _color, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
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
            // Two slanted eyes and a wide little grin: mischief, not menace.
            Stroke("EyeL", new List<Vector3> { new Vector3(-0.10f, 0.66f, 0f), new Vector3(-0.03f, 0.62f, 0f) }, _detailWidth);
            Stroke("EyeR", new List<Vector3> { new Vector3(0.10f, 0.66f, 0f), new Vector3(0.03f, 0.62f, 0f) }, _detailWidth);

            var grin = new List<Vector3>();
            InkLine.AddArc(grin, new Vector2(0f, 0.60f), 0.09f, 210f, 330f, 10);
            Stroke("Grin", grin, _detailWidth);
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
