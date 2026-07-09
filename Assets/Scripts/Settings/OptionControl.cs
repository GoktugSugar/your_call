using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One "pick from a short list" control in the ink aesthetic: a hand-lettered label with the current
    /// option shown below it between two drawn chevrons. Click it (or press enter / left-right when the
    /// row is selected) to cycle through the options; the value and chevrons take the amber accent while
    /// selected. Used for the language setting, where the options are the languages' own names (shown in
    /// each language, so "English" and "Türkçe", never translated). It owns its own label, value and
    /// highlight; the panel lays it out and drives navigation. One job: hold one choice from a list.
    /// </summary>
    public sealed class OptionControl : MonoBehaviour
    {
        [Header("Type")]
        [SerializeField] private float _labelSize = 2.1f;
        [SerializeField] private float _valueSize = 2.1f;
        [SerializeField] private Color _idleColor = Palette.Ink;
        [SerializeField] private Color _selectedColor = Palette.Amber;
        [Tooltip("The label sits centred just above the value, matching the sliders, so it reads centred.")]
        [SerializeField] private float _labelWidth = 4.4f;
        [SerializeField] private float _labelYOffset = 0.5f;
        [SerializeField] private float _valueWidth = 3.4f;
        [SerializeField] private int _sortingOrder = 32;

        [Header("Chevrons (drawn either side of the value)")]
        [SerializeField] private float _chevronX = 2.05f;
        [SerializeField] private float _chevronSize = 0.22f;
        [SerializeField] private float _chevronWidth = 0.06f;

        [Header("Pick / feel")]
        [SerializeField] private float _pickWidth = 4.4f;
        [SerializeField] private float _pickHeight = 0.9f;
        [SerializeField] private float _selectLerp = 0.14f;
        [SerializeField] private Camera _camera;

        public event Action<int> Changed;
        public event Action Hovered;

        public int Index { get; private set; }

        private string _labelSource;
        private string[] _options;
        private TextMeshPro _label;
        private TextMeshPro _value;
        private LineRenderer _left;
        private LineRenderer _right;
        private BoxCollider2D _collider;
        private bool _selected;
        private bool _armed;
        private bool _wasHovered;
        private float _selT;
        private float _shown = 1f;
        private bool _built;

        public void Setup(Material inkMaterial, TMP_FontAsset font, string labelText, string[] options, int index)
        {
            _labelSource = labelText;
            _options = options ?? Array.Empty<string>();
            Index = _options.Length > 0 ? Mathf.Clamp(index, 0, _options.Length - 1) : 0;

            if (!_built)
            {
                _label = InkText.Create(transform, "Label", _labelSize, _idleColor, TextAlignmentOptions.Center, _sortingOrder);
                _value = InkText.Create(transform, "Value", _valueSize, _idleColor, TextAlignmentOptions.Center, _sortingOrder);
                if (font != null) { _label.font = font; _value.font = font; }
                _label.rectTransform.sizeDelta = new Vector2(_labelWidth, _labelSize * 1.4f);
                _label.rectTransform.localPosition = new Vector3(0f, _labelYOffset, 0f);
                _value.rectTransform.sizeDelta = new Vector2(_valueWidth, _valueSize * 1.4f);
                _value.rectTransform.localPosition = Vector3.zero;

                _left = MakeChevron(inkMaterial, "ChevronLeft", -_chevronX, true);
                _right = MakeChevron(inkMaterial, "ChevronRight", _chevronX, false);

                _collider = gameObject.GetComponent<BoxCollider2D>();
                if (_collider == null) _collider = gameObject.AddComponent<BoxCollider2D>();
                _collider.isTrigger = true;
                _collider.size = new Vector2(_pickWidth, _pickHeight);

                _built = true;
            }

            ApplyText();
            Apply();
        }

        private LineRenderer MakeChevron(Material inkMaterial, string name, float x, bool pointLeft)
        {
            var lr = InkLine.Create(transform, name, inkMaterial, _chevronWidth, _idleColor, _sortingOrder - 1);
            float dir = pointLeft ? -1f : 1f;
            float h = _chevronSize;
            InkLine.SetPoints(lr, new List<Vector3>
            {
                new Vector3(x - dir * h * 0.5f, h, 0f),
                new Vector3(x + dir * h * 0.5f, 0f, 0f),
                new Vector3(x - dir * h * 0.5f, -h, 0f),
            });
            return lr;
        }

        /// <summary>Re-apply the label in the active language (the option names stay in their own language).</summary>
        public void Relocalize()
        {
            if (_label != null) _label.text = Localization.Localize(_labelSource);
        }

        private void ApplyText()
        {
            _label.text = Localization.Localize(_labelSource);
            _value.text = _options.Length > 0 ? _options[Index] : string.Empty;
        }

        public void SetSelected(bool on) { _selected = on; }
        public void Arm(bool on) { _armed = on; if (!on) _wasHovered = false; }
        public void SetShown(float a) { _shown = Mathf.Clamp01(a); Apply(); }

        /// <summary>Set the index without raising Changed (used to seed from saved settings).</summary>
        public void SetIndexSilent(int index)
        {
            if (_options.Length == 0) return;
            Index = Mathf.Clamp(index, 0, _options.Length - 1);
            if (_value != null) _value.text = _options[Index];
            Apply();
        }

        /// <summary>Enter / a click cycles forward through the options.</summary>
        public void Toggle() { Step(1); }

        /// <summary>Left previous, right next (arrow keys).</summary>
        public void Adjust(int dir) { if (dir != 0) Step(dir > 0 ? 1 : -1); }

        private void Step(int dir)
        {
            if (_options.Length <= 1) return;
            Index = (Index + dir + _options.Length) % _options.Length;
            if (_value != null) _value.text = _options[Index];
            Apply();
            Changed?.Invoke(Index);
        }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;

            if (_armed && _camera != null)
            {
                Vector3 wp = PointerInput.WorldPosition(_camera, transform.position.z);
                bool hovered = _collider != null && _collider.OverlapPoint(wp);
                if (hovered && !_wasHovered) Hovered?.Invoke();
                _wasHovered = hovered;
                if (hovered && PointerInput.Clicked) Step(1);
            }
            else _wasHovered = false;

            _selT = Mathf.MoveTowards(_selT, _selected ? 1f : 0f, Time.deltaTime / Mathf.Max(_selectLerp, 0.01f));
            Apply();
        }

        private void Apply()
        {
            if (!_built) return;
            Color c = Color.Lerp(_idleColor, _selectedColor, _selT);
            if (_label != null) { var lc = c; lc.a = _shown; _label.color = lc; }
            if (_value != null) { var vc = c; vc.a = _shown; _value.color = vc; }
            InkLine.SetAlpha(_left, c, _shown);
            InkLine.SetAlpha(_right, c, _shown);
        }
    }
}
