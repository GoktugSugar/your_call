using System;
using TMPro;
using System.Collections.Generic;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// Two clean ink buttons, told apart by label alone (never by colour, since the palette
    /// is one amber accent). The narrator names them the blue and the red button, so the
    /// reference is unmistakable while nothing on screen is blue or red. Amber appears only
    /// on hover and selection. Picked by click or number key. Raises <see cref="Chosen"/>.
    /// </summary>
    public sealed class ButtonChoice : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _ink = Palette.Ink;
        [SerializeField] private Color _amber = Palette.Amber;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private int _sortingOrder = 8;

        [Header("Layout")]
        [SerializeField] private Vector3 _leftPosition = new Vector3(-1.7f, 1.4f, 0f);
        [SerializeField] private Vector3 _rightPosition = new Vector3(1.7f, 1.4f, 0f);
        [SerializeField] private float _buttonWidth = 1.7f;
        [SerializeField] private float _buttonHeight = 0.8f;
        [SerializeField] private float _cornerRadius = 0.16f;
        [SerializeField] private float _labelSize = 2.7f;

        [Header("Feel")]
        [SerializeField] private float _hoverWidthMul = 1.3f;
        [SerializeField] private float _hoverLerp = 0.12f;
        [SerializeField] private float _pulsePeriod = 1.8f;
        [SerializeField, Range(0f, 0.5f)] private float _pulseAmount = 0.12f;
        [SerializeField, Range(0f, 1f)] private float _dimmedAlpha = 0.4f;
        [SerializeField] private Camera _camera;

        public event Action<int> Chosen;

        private sealed class Button
        {
            public GameObject Root;
            public LineRenderer Outline;
            public BoxCollider2D Collider;
            public TextMeshPro Label;
            public float HoverT;
        }

        private readonly Button[] _buttons = new Button[2];
        private bool _armed;
        private bool _locked;
        private int _lockedIndex = -1;
        private bool _built;

        public void Build(Dilemma dilemma)
        {
            if (_built) return;
            string left = dilemma.Choices.Count > 0 ? dilemma.Choices[0].Label : "blue";
            string right = dilemma.Choices.Count > 1 ? dilemma.Choices[1].Label : "red";
            _buttons[0] = BuildButton(0, _leftPosition, left);
            _buttons[1] = BuildButton(1, _rightPosition, right);
            _built = true;
            Apply();
        }

        private Button BuildButton(int index, Vector3 pos, string label)
        {
            var b = new Button();
            b.Root = new GameObject("Button" + index);
            b.Root.transform.SetParent(transform, false);
            b.Root.transform.localPosition = pos;

            b.Outline = InkLine.Create(b.Root.transform, "Outline", _inkMaterial, _lineWidth, _ink, _sortingOrder);
            InkLine.SetPoints(b.Outline, RoundedRect(_buttonWidth * 0.5f, _buttonHeight * 0.5f, _cornerRadius, 4));

            b.Collider = b.Root.AddComponent<BoxCollider2D>();
            b.Collider.isTrigger = true;
            b.Collider.size = new Vector2(_buttonWidth, _buttonHeight);

            b.Label = InkText.Create(b.Root.transform, "Label", _labelSize, _ink, TextAlignmentOptions.Center, _sortingOrder + 1);
            b.Label.rectTransform.sizeDelta = new Vector2(_buttonWidth, _buttonHeight);
            b.Label.transform.localPosition = Vector3.zero;
            b.Label.text = label;
            return b;
        }

        private static List<Vector3> RoundedRect(float halfW, float halfH, float r, int seg)
        {
            r = Mathf.Min(r, Mathf.Min(halfW, halfH));
            float minX = -halfW, minY = -halfH, maxX = halfW, maxY = halfH;
            var p = new List<Vector3>();
            Vector2 bl = new Vector2(minX + r, minY + r), br = new Vector2(maxX - r, minY + r);
            Vector2 tr = new Vector2(maxX - r, maxY - r), tl = new Vector2(minX + r, maxY - r);
            p.Add(new Vector3(minX + r, minY, 0f));
            p.Add(new Vector3(maxX - r, minY, 0f));
            InkLine.AddArc(p, br, r, -90f, 0f, seg);
            p.Add(new Vector3(maxX, maxY - r, 0f));
            InkLine.AddArc(p, tr, r, 0f, 90f, seg);
            p.Add(new Vector3(minX + r, maxY, 0f));
            InkLine.AddArc(p, tl, r, 90f, 180f, seg);
            p.Add(new Vector3(minX, minY + r, 0f));
            InkLine.AddArc(p, bl, r, 180f, 270f, seg);
            return p;
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
            if (kb == null) return;
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

                float amberT;
                if (_locked) amberT = (i == _lockedIndex) ? 1f : 0f;
                else
                {
                    amberT = b.HoverT;
                    if (_armed)
                        amberT += Mathf.Max(0f, Mathf.Sin(Time.time * (Mathf.PI * 2f / _pulsePeriod))) * _pulseAmount * (1f - b.HoverT);
                }
                amberT = Mathf.Clamp01(amberT);

                float alpha = (_locked && i != _lockedIndex) ? _dimmedAlpha : 1f;
                Color col = Color.Lerp(_ink, _amber, amberT); col.a = alpha;
                float w = _lineWidth * Mathf.Lerp(1f, _hoverWidthMul, amberT);

                b.Outline.widthMultiplier = w;
                InkLine.SetColor(b.Outline, col);
                b.Label.color = col;
            }
        }
    }
}
