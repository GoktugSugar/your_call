using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The coordination gamble's two options, rendered in the monochrome ink language and
    /// told apart by form, pattern, and label, never by colour: option 0 is a closed circle
    /// with a check (safe), option 1 is a die with pips (the gamble). Amber appears only on
    /// hover and selection. Picked by click or number key. Raises <see cref="Chosen"/>.
    /// </summary>
    public sealed class OptionMarks : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _ink = Palette.Ink;
        [SerializeField] private Color _amber = Palette.Amber;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private int _sortingOrder = 8;

        [Header("Layout")]
        [SerializeField] private Vector3 _leftPosition = new Vector3(-2.7f, 1.5f, 0f);
        [SerializeField] private Vector3 _rightPosition = new Vector3(2.7f, 1.5f, 0f);
        [SerializeField] private float _markRadius = 0.62f;
        [SerializeField] private float _labelSize = 3.0f;
        [SerializeField] private float _labelDrop = 1.15f;

        [Header("Feel")]
        [SerializeField] private float _hoverWidthMul = 1.3f;
        [SerializeField] private float _hoverLerp = 0.12f;
        [SerializeField] private float _pulsePeriod = 1.8f;
        [SerializeField, Range(0f, 0.5f)] private float _pulseAmount = 0.12f;
        [SerializeField, Range(0f, 1f)] private float _dimmedAlpha = 0.4f;
        [SerializeField] private Camera _camera;

        public event Action<int> Chosen;

        private sealed class Mark
        {
            public GameObject Root;
            public readonly List<LineRenderer> Lines = new List<LineRenderer>();
            public BoxCollider2D Collider;
            public TextMeshPro Label;
            public float HoverT;
        }

        private readonly Mark[] _marks = new Mark[2];
        private bool _armed;
        private bool _locked;
        private int _lockedIndex = -1;
        private bool _built;

        public void Build(Dilemma dilemma)
        {
            if (_built) return;
            string left = dilemma.Choices.Count > 0 ? dilemma.Choices[0].Label : "safe";
            string right = dilemma.Choices.Count > 1 ? dilemma.Choices[1].Label : "gamble";
            _marks[0] = BuildMark(0, _leftPosition, left);
            _marks[1] = BuildMark(1, _rightPosition, right);
            _built = true;
            Apply();
        }

        private Mark BuildMark(int index, Vector3 pos, string label)
        {
            var m = new Mark();
            m.Root = new GameObject("Mark" + index);
            m.Root.transform.SetParent(transform, false);
            m.Root.transform.localPosition = pos;

            if (index == 0) DrawSafe(m);
            else DrawGamble(m);

            m.Collider = m.Root.AddComponent<BoxCollider2D>();
            m.Collider.isTrigger = true;
            m.Collider.offset = new Vector2(0f, -_markRadius * 0.3f);
            m.Collider.size = new Vector2(_markRadius * 2.6f, _markRadius * 2.9f);

            m.Label = InkText.Create(m.Root.transform, "Label", _labelSize, _ink, TextAlignmentOptions.Center, _sortingOrder);
            m.Label.rectTransform.sizeDelta = new Vector2(5.5f, 1.2f);
            m.Label.transform.localPosition = new Vector3(0f, -_labelDrop, 0f);
            m.Label.text = label;
            return m;
        }

        // Option 0: a closed circle with a check. "Safe, certain, approved."
        private void DrawSafe(Mark m)
        {
            var ring = InkLine.Create(m.Root.transform, "Ring", _inkMaterial, _lineWidth, _ink, _sortingOrder);
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, Vector2.zero, _markRadius, 0f, 360f, 32);
            InkLine.SetPoints(ring, pts);
            m.Lines.Add(ring);

            var check = InkLine.Create(m.Root.transform, "Check", _inkMaterial, _lineWidth, _ink, _sortingOrder + 1);
            float r = _markRadius;
            InkLine.SetPoints(check, new List<Vector3>
            {
                new Vector3(-0.42f * r, 0.02f * r, 0f),
                new Vector3(-0.10f * r, -0.34f * r, 0f),
                new Vector3(0.46f * r, 0.40f * r, 0f)
            });
            m.Lines.Add(check);
        }

        // Option 1: a die with pips. "A roll of the dice, chance."
        private void DrawGamble(Mark m)
        {
            float s = _markRadius * 0.92f;
            var box = InkLine.Create(m.Root.transform, "Die", _inkMaterial, _lineWidth, _ink, _sortingOrder);
            InkLine.SetPoints(box, RoundedSquare(s, s * 0.26f, 4));
            m.Lines.Add(box);

            float p = s * 0.5f;
            Vector2[] pips = { new Vector2(-p, p), new Vector2(p, p), Vector2.zero, new Vector2(-p, -p), new Vector2(p, -p) };
            for (int i = 0; i < pips.Length; i++)
            {
                var pip = InkLine.Create(m.Root.transform, "Pip" + i, _inkMaterial, _lineWidth * 1.5f, _ink, _sortingOrder + 1);
                var pc = new List<Vector3>();
                InkLine.AddArc(pc, pips[i], s * 0.08f, 0f, 360f, 10);
                InkLine.SetPoints(pip, pc);
                m.Lines.Add(pip);
            }
        }

        private static List<Vector3> RoundedSquare(float half, float r, int seg)
        {
            float minX = -half, minY = -half, maxX = half, maxY = half;
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
                    bool hovered = _marks[i].Collider != null && _marks[i].Collider.OverlapPoint(wp);
                    _marks[i].HoverT = Mathf.MoveTowards(_marks[i].HoverT, hovered ? 1f : 0f, Time.deltaTime / Mathf.Max(_hoverLerp, 0.01f));
                    if (hovered && PointerInput.Clicked) { Pick(i); return; }
                }
                ReadKeyboard();
            }
            else
            {
                for (int i = 0; i < 2; i++)
                    _marks[i].HoverT = Mathf.MoveTowards(_marks[i].HoverT, 0f, Time.deltaTime / Mathf.Max(_hoverLerp, 0.01f));
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
                var m = _marks[i];
                if (m == null) continue;

                float amberT;
                if (_locked) amberT = (i == _lockedIndex) ? 1f : 0f;
                else
                {
                    amberT = m.HoverT;
                    if (_armed)
                        amberT += Mathf.Max(0f, Mathf.Sin(Time.time * (Mathf.PI * 2f / _pulsePeriod))) * _pulseAmount * (1f - m.HoverT);
                }
                amberT = Mathf.Clamp01(amberT);

                float alpha = (_locked && i != _lockedIndex) ? _dimmedAlpha : 1f;
                Color col = Color.Lerp(_ink, _amber, amberT); col.a = alpha;
                float w = _lineWidth * Mathf.Lerp(1f, _hoverWidthMul, amberT);

                for (int j = 0; j < m.Lines.Count; j++)
                {
                    m.Lines[j].widthMultiplier = m.Lines[j].name.StartsWith("Pip") ? w * 1.5f : w;
                    InkLine.SetColor(m.Lines[j], col);
                }
                var lc = col; m.Label.color = lc;
            }
        }
    }
}
