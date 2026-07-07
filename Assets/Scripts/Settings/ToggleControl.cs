using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One on/off control in the ink aesthetic: a hand-lettered label and a drawn box that takes an
    /// amber tick when on. Click the box to toggle (new Input System, no EventSystem), or press
    /// enter / left-right when the row is selected; the label takes the amber accent while selected.
    /// It reports <see cref="Changed"/> and owns its own label and highlight; the panel lays it out
    /// and drives navigation. One job: hold one on/off setting (fullscreen).
    /// </summary>
    public sealed class ToggleControl : MonoBehaviour
    {
        [Header("Type")]
        [SerializeField] private float _labelSize = 2.1f;
        [SerializeField] private Color _idleColor = Palette.Ink;
        [SerializeField] private Color _selectedColor = Palette.Amber;
        [Tooltip("The label sits centred just above the box, matching the sliders, so it reads centred.")]
        [SerializeField] private float _labelWidth = 4.4f;
        [SerializeField] private float _labelYOffset = 0.5f;
        [SerializeField] private int _sortingOrder = 32;

        [Header("Box (centred on the control's origin)")]
        [SerializeField] private float _boxCenterX = 0f;
        [SerializeField] private float _boxSize = 0.62f;
        [SerializeField] private Color _boxColor = Palette.Ink;
        [SerializeField] private Color _tickColor = Palette.Amber;
        [SerializeField] private float _boxWidth = 0.055f;
        [SerializeField] private float _tickWidth = 0.075f;

        [Header("Pick / feel")]
        [SerializeField] private float _pickWidth = 1.4f;
        [SerializeField] private float _pickHeight = 0.8f;
        [SerializeField] private float _selectLerp = 0.14f;
        [SerializeField] private float _tickLerp = 0.1f;
        [SerializeField] private Camera _camera;

        public event Action<bool> Changed;
        public event Action Hovered;

        public bool On { get; private set; }

        private TextMeshPro _label;
        private LineRenderer _box;
        private LineRenderer _tick;
        private BoxCollider2D _collider;
        private bool _selected;
        private bool _armed;
        private bool _wasHovered;
        private float _selT;
        private float _onT;
        private float _shown = 1f;
        private bool _built;

        public void Setup(Material inkMaterial, TMP_FontAsset font, string labelText, bool on)
        {
            if (!_built)
            {
                _label = InkText.Create(transform, "Label", _labelSize, _idleColor, TextAlignmentOptions.Center, _sortingOrder);
                if (font != null) _label.font = font;
                _label.rectTransform.sizeDelta = new Vector2(_labelWidth, _labelSize * 1.4f);
                _label.rectTransform.localPosition = new Vector3(0f, _labelYOffset, 0f);

                float h = _boxSize * 0.5f;
                _box = InkLine.Create(transform, "Box", inkMaterial, _boxWidth, _boxColor, _sortingOrder - 1);
                InkLine.SetPoints(_box, new List<Vector3>
                {
                    new Vector3(_boxCenterX - h, -h, 0f),
                    new Vector3(_boxCenterX + h, -h, 0f),
                    new Vector3(_boxCenterX + h, h, 0f),
                    new Vector3(_boxCenterX - h, h, 0f),
                    new Vector3(_boxCenterX - h, -h, 0f),
                });

                // A drawn tick that inks in when on.
                _tick = InkLine.Create(transform, "Tick", inkMaterial, _tickWidth, _tickColor, _sortingOrder);
                InkLine.SetPoints(_tick, new List<Vector3>
                {
                    new Vector3(_boxCenterX - h * 0.45f, -h * 0.02f, 0f),
                    new Vector3(_boxCenterX - h * 0.05f, -h * 0.42f, 0f),
                    new Vector3(_boxCenterX + h * 0.55f, h * 0.5f, 0f),
                });

                _collider = gameObject.GetComponent<BoxCollider2D>();
                if (_collider == null) _collider = gameObject.AddComponent<BoxCollider2D>();
                _collider.isTrigger = true;
                _collider.offset = new Vector2(_boxCenterX, 0f);
                _collider.size = new Vector2(_pickWidth, _pickHeight);

                _built = true;
            }

            _label.text = labelText;
            On = on;
            _onT = on ? 1f : 0f;
            Apply();
        }

        public void SetSelected(bool on) { _selected = on; }
        public void Arm(bool on) { _armed = on; if (!on) _wasHovered = false; }
        public void SetShown(float a) { _shown = Mathf.Clamp01(a); Apply(); }

        public void SetValueSilent(bool on) { On = on; Apply(); }

        /// <summary>Flip the switch (enter, or a click).</summary>
        public void Toggle() { Set(!On); }

        /// <summary>Left sets off, right sets on (arrow keys).</summary>
        public void Adjust(int dir) { if (dir != 0) Set(dir > 0); }

        private void Set(bool on)
        {
            if (on == On) return;
            On = on;
            Changed?.Invoke(On);
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
                if (hovered && PointerInput.Clicked) Toggle();
            }
            else _wasHovered = false;

            _selT = Mathf.MoveTowards(_selT, _selected ? 1f : 0f, Time.deltaTime / Mathf.Max(_selectLerp, 0.01f));
            _onT = Mathf.MoveTowards(_onT, On ? 1f : 0f, Time.deltaTime / Mathf.Max(_tickLerp, 0.01f));
            Apply();
        }

        private void Apply()
        {
            if (!_built) return;
            Color labelC = Color.Lerp(_idleColor, _selectedColor, _selT);
            if (_label != null) { labelC.a = _shown; _label.color = labelC; }

            InkLine.SetAlpha(_box, _boxColor, _shown);
            InkLine.SetAlpha(_tick, _tickColor, _onT * _shown);
            _tick.enabled = _onT * _shown > 0.001f;
        }
    }
}
