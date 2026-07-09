using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A single round, hand-drawn ink push-button that the player can actually press (click within its
    /// circle), the reusable affordance for the Chapter 2 button beats that previously offered only text
    /// choices. It draws an ink circle (with an optional inner bezel ring so it reads as a physical
    /// button), brightens to the amber attention accent on hover, plays a quick press squash, and raises
    /// <see cref="Pressed"/>. On-model in the ink style (see art-and-ui.md), the same look as the timer
    /// and nuke buttons; built at runtime by a beat via <see cref="Create"/>. One job: be a pressable
    /// ink button.
    ///
    /// It never owns the choice logic: a beat subscribes to <see cref="Pressed"/> and keeps its text
    /// options as the secondary fallback, so the button is the physical way to choose without removing
    /// anything. Amber only on hover, per the palette.
    /// </summary>
    public sealed class InkButton : MonoBehaviour
    {
        private Material _inkMaterial;
        private TMP_FontAsset _font;
        private float _radius = 0.8f;
        private float _lineWidth = 0.055f;
        private Color _ink = Palette.Ink;
        private Color _hot = Palette.Amber;
        private string _label = string.Empty;
        private float _labelSize = 2.6f;
        private int _sorting = 14;
        private bool _innerRing = true;

        [Header("Feel")]
        [SerializeField] private float _pressSquash = 0.16f;
        [SerializeField] private float _pressDuration = 0.14f;
        [SerializeField] private float _hoverWidthMul = 1.3f;

        /// <summary>Raised once per click while armed.</summary>
        public event System.Action Pressed;

        private Transform _rig;
        private LineRenderer _outline;
        private LineRenderer _inner;
        private TextMeshPro _labelTMP;
        private readonly List<LineRenderer> _details = new List<LineRenderer>();
        private readonly List<Color> _detailColors = new List<Color>();
        private Camera _cam;
        private bool _built;
        private bool _armed;
        private float _hoverT;
        private float _alpha;
        private Coroutine _squash;

        /// <summary>Build a pressable ink button under <paramref name="parent"/> at a local position. It
        /// starts hidden; fade it in with <see cref="FadeIn"/>. Reuses the beat's shared ink material and
        /// font, so it matches the rest of the chapter.</summary>
        public static InkButton Create(Transform parent, string name, Vector3 localPos, Material inkMaterial,
            TMP_FontAsset font = null, float radius = 0.8f, float lineWidth = 0.055f, string label = "",
            float labelSize = 2.6f, int sorting = 14, bool innerRing = true, Color? restColor = null, Color? hotColor = null)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            var b = go.AddComponent<InkButton>();
            b._inkMaterial = inkMaterial;
            b._font = font;
            b._radius = radius;
            b._lineWidth = lineWidth;
            b._label = label;
            b._labelSize = labelSize;
            b._sorting = sorting;
            b._innerRing = innerRing;
            b._ink = restColor ?? Palette.Ink;    // a plain ink button by default; a beat can pass e.g. gold
            b._hot = hotColor ?? Palette.Amber;
            b.Build();
            return b;
        }

        private void Build()
        {
            if (_built) return;
            _rig = new GameObject("Rig").transform;
            _rig.SetParent(transform, false);

            _outline = InkLine.Create(_rig, "Outline", _inkMaterial, _lineWidth, _ink, _sorting);
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _radius, 0f, 360f, 40);
            InkLine.SetPoints(_outline, ring);
            _outline.gameObject.AddComponent<LineBoil>().Capture();

            if (_innerRing)
            {
                _inner = InkLine.Create(_rig, "Inner", _inkMaterial, _lineWidth * 0.7f, _ink, _sorting);
                var inner = new List<Vector3>();
                InkLine.AddArc(inner, Vector2.zero, _radius * 0.62f, 0f, 360f, 32);
                InkLine.SetPoints(_inner, inner);
                _inner.gameObject.AddComponent<LineBoil>().Capture();
            }

            if (!string.IsNullOrEmpty(_label))
            {
                _labelTMP = InkText.Create(_rig, "Label", _labelSize, _ink, TextAlignmentOptions.Center, _sorting + 1);
                if (_font != null) _labelTMP.font = _font;
                _labelTMP.rectTransform.sizeDelta = new Vector2(_radius * 2.2f, 1f);
                _labelTMP.transform.localPosition = Vector3.zero;
                _labelTMP.text = _label;
            }

            _built = true;
            SetAlpha(0f);
        }

        /// <summary>Add an extra ink detail stroke onto the button (for example a hand-drawn money glyph),
        /// drawn under the same rig so it squashes on press and fades with the button. It keeps its own
        /// colour (it is not tinted by the hover), so a gold dollar sign stays gold.</summary>
        public LineRenderer AddDetail(List<Vector3> points, Color color, float width)
        {
            if (!_built) Build();
            var lr = InkLine.Create(_rig, "Detail", _inkMaterial, width, color, _sorting + 2);
            InkLine.SetPoints(lr, points);
            _details.Add(lr);
            _detailColors.Add(color);
            ApplyVisual();
            return lr;
        }

        /// <summary>Enable or disable click handling. Armed only during the choice window, so a press never
        /// fires during narration or a page advance.</summary>
        public void Arm(bool on) { _armed = on; }

        private void Update()
        {
            if (!_built) return;
            if (_cam == null) _cam = Camera.main;
            bool hot = _armed && _alpha > 0.5f && Over();
            _hoverT = Mathf.MoveTowards(_hoverT, hot ? 1f : 0f, Time.deltaTime / 0.1f);
            ApplyVisual();
            if (hot && PointerInput.Clicked) Press();
        }

        private bool Over()
        {
            if (_cam == null) return false;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            Vector2 c = transform.position;
            return ((Vector2)wp - c).sqrMagnitude <= _radius * _radius;
        }

        /// <summary>Fire a press: play the squash and raise <see cref="Pressed"/>. Also callable directly
        /// (e.g. from a text option) so the button reacts when the secondary affordance is used.</summary>
        public void Press()
        {
            if (_squash != null) StopCoroutine(_squash);
            _squash = StartCoroutine(Squash());
            Pressed?.Invoke();
        }

        private IEnumerator Squash()
        {
            float d = Mathf.Max(_pressDuration, 0.02f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = Mathf.Sin(Mathf.Clamp01(t / d) * Mathf.PI); // 0 -> 1 -> 0
                if (_rig != null) _rig.localScale = new Vector3(1f + k * _pressSquash * 0.6f, 1f - k * _pressSquash, 1f);
                yield return null;
            }
            if (_rig != null) _rig.localScale = Vector3.one;
        }

        private void ApplyVisual()
        {
            Color c = Color.Lerp(_ink, _hot, _hoverT);
            float w = _lineWidth * Mathf.Lerp(1f, _hoverWidthMul, _hoverT);
            if (_outline != null) { InkLine.SetAlpha(_outline, c, _alpha); _outline.widthMultiplier = w; }
            if (_inner != null) InkLine.SetAlpha(_inner, c, _alpha * 0.9f);
            if (_labelTMP != null) { var lc = c; lc.a = _alpha; _labelTMP.color = lc; }
            for (int i = 0; i < _details.Count; i++)
                if (_details[i] != null) InkLine.SetAlpha(_details[i], _detailColors[i], _alpha);
        }

        public void SetAlpha(float a)
        {
            _alpha = Mathf.Clamp01(a);
            ApplyVisual();
        }

        public IEnumerator FadeIn(float dur) { yield return Fade(_alpha, 1f, dur); }
        public IEnumerator FadeOut(float dur) { yield return Fade(_alpha, 0f, dur); }

        private IEnumerator Fade(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; SetAlpha(Mathf.Lerp(from, to, t / d)); yield return null; }
            SetAlpha(to);
        }
    }
}
