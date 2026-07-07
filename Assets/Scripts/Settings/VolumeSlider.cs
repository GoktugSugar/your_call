using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One volume control in the ink aesthetic: a hand-lettered label with a drawn track, an ink
    /// fill that shows the level, and a knob. Set it by dragging or clicking the track (new Input
    /// System, no EventSystem), or nudge it with the arrow keys when the row is selected; the knob
    /// and label take the amber accent while selected. It reports <see cref="Changed"/> live (so the
    /// music can follow a drag) and <see cref="Committed"/> on release or a nudge (for a discrete
    /// cue). It owns its own label and highlight; the panel only lays it out and drives navigation.
    /// One job: pick a level from 0 to 1.
    /// </summary>
    public sealed class VolumeSlider : MonoBehaviour
    {
        [Header("Type")]
        [SerializeField] private float _labelSize = 2.1f;
        [SerializeField] private Color _idleColor = Palette.Ink;
        [SerializeField] private Color _selectedColor = Palette.Amber;
        [SerializeField] private float _labelWidth = 3.2f;
        [SerializeField] private float _labelCenterX = -1.9f;
        [SerializeField] private int _sortingOrder = 32;

        [Header("Track")]
        [SerializeField] private float _trackMinX = -0.2f;
        [SerializeField] private float _trackMaxX = 3f;
        [SerializeField] private Color _trackColor = Palette.Muted;
        [SerializeField] private Color _fillColor = Palette.Ink;
        [SerializeField] private float _trackWidth = 0.05f;
        [SerializeField] private float _fillWidth = 0.09f;
        [SerializeField] private float _knobRadius = 0.16f;
        [SerializeField] private float _knobWidth = 0.075f;

        [Header("Pick / feel")]
        [SerializeField] private float _pickHeight = 0.7f;
        [SerializeField] private float _endPad = 0.15f;
        [SerializeField] private float _step = 0.1f;
        [SerializeField] private float _selectLerp = 0.14f;
        [SerializeField] private Camera _camera;

        public event Action<float> Changed;
        public event Action<float> Committed;
        public event Action Hovered;

        public float Value { get; private set; } = 1f;

        private TextMeshPro _label;
        private LineRenderer _track;
        private LineRenderer _fill;
        private LineRenderer _knob;
        private BoxCollider2D _collider;
        private bool _selected;
        private bool _armed;
        private bool _dragging;
        private bool _wasHovered;
        private float _selT;
        private float _shown = 1f;
        private bool _built;

        public void Setup(Material inkMaterial, TMP_FontAsset font, string labelText, float value)
        {
            if (!_built)
            {
                _label = InkText.Create(transform, "Label", _labelSize, _idleColor, TextAlignmentOptions.Right, _sortingOrder);
                if (font != null) _label.font = font;
                _label.rectTransform.sizeDelta = new Vector2(_labelWidth, _labelSize * 1.4f);
                _label.rectTransform.localPosition = new Vector3(_labelCenterX, 0f, 0f);

                _track = InkLine.Create(transform, "Track", inkMaterial, _trackWidth, _trackColor, _sortingOrder - 2);
                InkLine.SetPoints(_track, new List<Vector3> { new Vector3(_trackMinX, 0f, 0f), new Vector3(_trackMaxX, 0f, 0f) });

                _fill = InkLine.Create(transform, "Fill", inkMaterial, _fillWidth, _fillColor, _sortingOrder - 1);
                _fill.positionCount = 2;

                _knob = InkLine.Create(transform, "Knob", inkMaterial, _knobWidth, _idleColor, _sortingOrder);
                var ring = new List<Vector3>();
                InkLine.AddArc(ring, Vector2.zero, _knobRadius, 0f, 360f, 18);
                InkLine.SetPoints(_knob, ring);

                _collider = gameObject.GetComponent<BoxCollider2D>();
                if (_collider == null) _collider = gameObject.AddComponent<BoxCollider2D>();
                _collider.isTrigger = true;
                _collider.offset = new Vector2((_trackMinX + _trackMaxX) * 0.5f, 0f);
                _collider.size = new Vector2((_trackMaxX - _trackMinX) + _endPad * 2f, _pickHeight);

                _built = true;
            }

            _label.text = labelText;
            Value = Mathf.Clamp01(value);
            Apply();
        }

        public void SetSelected(bool on) { _selected = on; }
        public void Arm(bool on) { _armed = on; if (!on) { _dragging = false; _wasHovered = false; } }
        public void SetShown(float a) { _shown = Mathf.Clamp01(a); Apply(); }

        /// <summary>Set the value without raising events (used to seed from saved settings).</summary>
        public void SetValueSilent(float v) { Value = Mathf.Clamp01(v); Apply(); }

        /// <summary>Keyboard nudge by one step; a discrete change, so it commits.</summary>
        public void Adjust(int dir)
        {
            float v = Mathf.Clamp01(Value + dir * _step);
            if (v != Value) { Value = v; Changed?.Invoke(Value); Apply(); }
            Committed?.Invoke(Value);
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

                if (hovered && PointerInput.Clicked) { _dragging = true; SetFromWorld(wp); }
                else if (_dragging && PointerInput.Held) { SetFromWorld(wp); }

                if (_dragging && !PointerInput.Held) { _dragging = false; Committed?.Invoke(Value); }
            }
            else _wasHovered = false;

            _selT = Mathf.MoveTowards(_selT, _selected ? 1f : 0f, Time.deltaTime / Mathf.Max(_selectLerp, 0.01f));
            Apply();
        }

        private void SetFromWorld(Vector3 wp)
        {
            float localX = transform.InverseTransformPoint(wp).x;
            float v = Mathf.Clamp01(Mathf.InverseLerp(_trackMinX, _trackMaxX, localX));
            if (v != Value) { Value = v; Changed?.Invoke(Value); }
        }

        private void Apply()
        {
            if (!_built) return;
            float knobX = Mathf.Lerp(_trackMinX, _trackMaxX, Value);

            _fill.SetPosition(0, new Vector3(_trackMinX, 0f, 0f));
            _fill.SetPosition(1, new Vector3(knobX, 0f, 0f));
            _knob.transform.localPosition = new Vector3(knobX, 0f, 0f);

            Color knobC = Color.Lerp(_idleColor, _selectedColor, _selT);
            Color labelC = Color.Lerp(_idleColor, _selectedColor, _selT);

            if (_label != null) { labelC.a = _shown; _label.color = labelC; }
            InkLine.SetAlpha(_track, _trackColor, _shown);
            InkLine.SetAlpha(_fill, _fillColor, _shown);
            InkLine.SetAlpha(_knob, knobC, _shown);
        }
    }
}
