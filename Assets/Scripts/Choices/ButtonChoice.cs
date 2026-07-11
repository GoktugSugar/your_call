using System;
using System.Collections.Generic;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The blue/red button's two buttons: round, unlabelled, a hand-drawn crayon fill inside
    /// a black ink circle (left blue, right red). Colour alone identifies them; the narrator
    /// names them in the spoken rule. This is the one documented exception to the one-amber
    /// palette (see docs/art-and-ui.md), contained to this dilemma. Hover and selection are
    /// carried by the button's own colour deepening, never amber. Picked by click or number
    /// key. Raises <see cref="Chosen"/>.
    /// </summary>
    public sealed class ButtonChoice : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _ink = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private int _sortingOrder = 8;

        [Header("Colour (documented palette exception)")]
        [SerializeField] private Color _leftFillColor = Palette.InkBlue;
        [SerializeField] private Color _rightFillColor = Palette.InkRed;

        [Header("Layout")]
        [SerializeField] private Vector3 _leftPosition = new Vector3(-1.5f, 1.3f, 0f);
        [SerializeField] private Vector3 _rightPosition = new Vector3(1.5f, 1.3f, 0f);
        [SerializeField] private float _buttonRadius = 0.56f;

        [Header("Crayon fill")]
        [SerializeField] private float _fillMargin = 0.13f;
        [SerializeField, Range(3, 16)] private int _fillRows = 7;
        [SerializeField] private float _fillWidth = 0.075f;
        [SerializeField] private float _fillJitter = 0.03f;
        [Tooltip("Fill opacity, so the colour reads as a hand-drawn wash.")]
        [SerializeField, Range(0.4f, 1f)] private float _fillOpacity = 0.8f;
        [SerializeField] private bool _boil = true;

        [Header("Feel")]
        [SerializeField] private float _hoverWidthMul = 1.25f;
        [SerializeField] private float _hoverLerp = 0.12f;
        [SerializeField] private float _pulsePeriod = 1.9f;
        [SerializeField, Range(0f, 0.5f)] private float _pulseAmount = 0.14f;
        [SerializeField, Range(0.3f, 1f)] private float _deepen = 0.62f;
        [SerializeField, Range(0f, 1f)] private float _dimmedAlpha = 0.4f;
        [SerializeField] private Camera _camera;

        public event Action<int> Chosen;

        private sealed class Button
        {
            public GameObject Root;
            public LineRenderer Outline;
            public LineRenderer Fill;
            public Color FillColor;
            public CircleCollider2D Collider;
            public float HoverT;
        }

        private readonly Button[] _buttons = new Button[2];
        private bool _armed;
        private bool _locked;
        private int _lockedIndex = -1;
        private bool _built;

        public void Build()
        {
            if (_built) return;
            _buttons[0] = BuildButton(0, _leftPosition, _leftFillColor);
            _buttons[1] = BuildButton(1, _rightPosition, _rightFillColor);
            _built = true;
            Apply();
        }

        private Button BuildButton(int index, Vector3 pos, Color fillColor)
        {
            var b = new Button { FillColor = fillColor };
            b.Root = new GameObject("Button" + index);
            b.Root.transform.SetParent(transform, false);
            b.Root.transform.localPosition = pos;

            // Crayon fill, behind the linework.
            b.Fill = InkLine.Create(b.Root.transform, "Fill", _inkMaterial, _fillWidth, fillColor, _sortingOrder - 1);
            InkLine.SetPoints(b.Fill, CircularScribbleFill(_buttonRadius, _fillMargin, _fillRows, _fillJitter, index * 97 + 13));
            if (_boil) b.Fill.gameObject.AddComponent<LineBoil>().Capture();

            // Black ink circle.
            b.Outline = InkLine.Create(b.Root.transform, "Outline", _inkMaterial, _lineWidth, _ink, _sortingOrder);
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _buttonRadius, 0f, 360f, 40);
            InkLine.SetPoints(b.Outline, ring);
            if (_boil) b.Outline.gameObject.AddComponent<LineBoil>().Capture();

            b.Collider = b.Root.AddComponent<CircleCollider2D>();
            b.Collider.isTrigger = true;
            b.Collider.radius = _buttonRadius * 1.05f;
            return b;
        }

        // Horizontal crayon scribble clipped to the circle (chord width per row).
        private static List<Vector3> CircularScribbleFill(float radius, float margin, int rows, float jitter, int seed)
        {
            float ir = Mathf.Max(0.05f, radius - margin);
            var pts = new List<Vector3>();
            float rowStep = (rows > 1) ? (2f * ir) / (rows - 1) : 0f;
            for (int r = 0; r < rows; r++)
            {
                float y = ir - r * rowStep;
                float w = Mathf.Sqrt(Mathf.Max(0f, ir * ir - y * y));
                if (w < 0.04f) continue;
                bool ltr = (r % 2 == 0);
                float xa = ltr ? -w : w;
                float xb = ltr ? w : -w;
                pts.Add(new Vector3(xa + J(seed, r * 4) * jitter, y + J(seed, r * 4 + 1) * jitter, 0f));
                pts.Add(new Vector3(xb + J(seed, r * 4 + 2) * jitter, y + J(seed, r * 4 + 3) * jitter, 0f));
            }
            return pts;
        }

        public void Arm(bool on) { _armed = on; }

        public void Lock(int index)
        {
            _locked = true;
            _lockedIndex = index;
            _armed = false;
        }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;

            if (_armed && !_locked && _camera != null)
            {
                Vector3 wp = PointerInput.WorldPosition(_camera, transform.position.z);
                for (int i = 0; i < 2; i++)
                {
                    bool hovered = _buttons[i].Collider != null && _buttons[i].Collider.OverlapPoint(wp);
                    _buttons[i].HoverT = Mathf.MoveTowards(_buttons[i].HoverT, hovered ? 1f : 0f, Time.deltaTime / Mathf.Max(_hoverLerp, 0.01f));
                    if (hovered && PointerInput.Clicked) { Pick(i); return; }
                }
                ReadKeyboard();
            }
            else
            {
                for (int i = 0; i < 2; i++)
                    _buttons[i].HoverT = Mathf.MoveTowards(_buttons[i].HoverT, 0f, Time.deltaTime / Mathf.Max(_hoverLerp, 0.01f));
            }

            Apply();
        }

        private void ReadKeyboard()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null || PointerInput.Suppressed) return;
            if (kb.digit1Key.wasPressedThisFrame || kb.leftArrowKey.wasPressedThisFrame) { Pick(0); return; }
            if (kb.digit2Key.wasPressedThisFrame || kb.rightArrowKey.wasPressedThisFrame) { Pick(1); return; }
#endif
        }

        private void Pick(int index)
        {
            if (!_armed || _locked) return;
            Chosen?.Invoke(index);
        }

        private void Apply()
        {
            for (int i = 0; i < 2; i++)
            {
                var b = _buttons[i];
                if (b == null) continue;

                float deepT;
                if (_locked) deepT = (i == _lockedIndex) ? 1f : 0f;
                else
                {
                    deepT = b.HoverT;
                    if (_armed)
                        deepT += Mathf.Max(0f, Mathf.Sin(Time.time * (Mathf.PI * 2f / _pulsePeriod))) * _pulseAmount * (1f - b.HoverT);
                }
                deepT = Mathf.Clamp01(deepT);

                float alpha = (_locked && i != _lockedIndex) ? _dimmedAlpha : 1f;

                Color fill = Deepen(b.FillColor, deepT); fill.a = alpha * _fillOpacity;
                InkLine.SetColor(b.Fill, fill);

                Color outline = _ink; outline.a = alpha;
                InkLine.SetColor(b.Outline, outline);
                b.Outline.widthMultiplier = _lineWidth * Mathf.Lerp(1f, _hoverWidthMul, deepT);
            }
        }

        private Color Deepen(Color c, float t)
        {
            float m = Mathf.Lerp(1f, _deepen, t);
            return new Color(c.r * m, c.g * m, c.b * m, c.a);
        }

        private static float J(int seed, int i)
        {
            unchecked
            {
                int x = (seed * 73856093) ^ (i * 19349663);
                x = (x ^ 61) ^ (x >> 16);
                x += x << 3;
                x ^= x >> 4;
                x *= 0x27d4eb2d;
                x ^= x >> 15;
                return (((x & 0x7fffffff) % 1000) / 1000f) - 0.5f;
            }
        }
    }
}
