using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One menu line in the ink aesthetic: a hand-lettered Caveat label that reads as ink on paper,
    /// turns amber with a small hand-drawn underline when it is the current selection, and greys
    /// out (muted, unpickable) when disabled (as Continue is until there is a save). It builds its
    /// own label, underline stroke, and pick collider, hit-tests the pointer itself (new Input
    /// System, no EventSystem, like the Lever), and raises <see cref="Hovered"/> and
    /// <see cref="Clicked"/>. It holds no navigation state; the controller decides selection and
    /// calls <see cref="SetSelected"/>. One job: present and pick one menu line.
    /// </summary>
    public sealed class MenuItem : MonoBehaviour
    {
        [Header("Type")]
        [SerializeField] private float _fontSize = 3f;
        [SerializeField] private Color _idleColor = Palette.Ink;
        [SerializeField] private Color _selectedColor = Palette.Amber;
        [Tooltip("Greyed, unpickable colour when the item is disabled (e.g. Continue with no save).")]
        [SerializeField] private Color _disabledColor = Palette.Muted;
        [SerializeField] private int _sortingOrder = 30;

        [Header("Underline (drawn when selected)")]
        [SerializeField] private bool _showUnderline = true;
        [SerializeField] private Color _underlineColor = Palette.Amber;
        [SerializeField] private float _underlineWidth = 0.05f;
        [Tooltip("Underline length as a fraction of the label width.")]
        [SerializeField, Range(0.3f, 1.2f)] private float _underlineSpan = 0.86f;
        [SerializeField] private float _underlineDrop = 0.42f;
        [Tooltip("Hand-drawn waviness of the underline.")]
        [SerializeField] private float _underlineWobble = 0.035f;

        [Header("Pick area")]
        [SerializeField] private float _minPickWidth = 2.2f;
        [SerializeField] private float _pickHeight = 1.05f;
        [SerializeField] private float _pickPadX = 0.6f;

        [Header("Feel")]
        [SerializeField] private float _selectLerp = 0.14f;
        [SerializeField] private Camera _camera;

        public event Action<MenuItem> Hovered;
        public event Action<MenuItem> Clicked;

        public bool Interactable { get; private set; } = true;
        public string Label { get; private set; }

        private string _source;   // the English source label; the display is localized from it
        private TextMeshPro _text;
        private LineRenderer _underline;
        private List<Vector3> _underlineBase;
        private BoxCollider2D _collider;
        private bool _selected;
        private bool _armed;
        private bool _wasHovered;
        private float _selT;
        private float _shown = 1f;
        private bool _built;

        /// <summary>Build the visuals and pick area, and set the initial content. Called once by the owner.</summary>
        public void Setup(Material inkMaterial, TMP_FontAsset font, string text, bool interactable)
        {
            Label = text;
            _source = text;
            Interactable = interactable;

            if (!_built)
            {
                _text = InkText.Create(transform, "Label", _fontSize, _idleColor, TextAlignmentOptions.Center, _sortingOrder);
                if (font != null) _text.font = font;
                _text.rectTransform.sizeDelta = new Vector2(14f, _fontSize * 1.4f);

                _underline = InkLine.Create(transform, "Underline", inkMaterial, _underlineWidth, _underlineColor, _sortingOrder - 1);

                _collider = gameObject.GetComponent<BoxCollider2D>();
                if (_collider == null) _collider = gameObject.AddComponent<BoxCollider2D>();
                _collider.isTrigger = true;

                _built = true;
            }

            _collider.enabled = interactable;
            ApplyText();
            Apply();
        }

        /// <summary>Re-apply the label in the active language (called when the language changes live).</summary>
        public void Relocalize()
        {
            if (!_built) return;
            ApplyText();
        }

        // Lay out the localized label and size the pick area and underline to it.
        private void ApplyText()
        {
            _text.text = Localization.Localize(_source);
            _text.ForceMeshUpdate();
            float w = Mathf.Max(_minPickWidth, _text.preferredWidth);
            _collider.size = new Vector2(w + _pickPadX, _pickHeight);
            BuildUnderline(w * _underlineSpan);
        }

        private void BuildUnderline(float span)
        {
            _underlineBase = new List<Vector3>();
            const int seg = 10;
            float half = span * 0.5f;
            for (int i = 0; i <= seg; i++)
            {
                float t = (float)i / seg;
                float x = Mathf.Lerp(-half, half, t);
                float y = -_underlineDrop + Mathf.Sin(t * Mathf.PI * 2f + 0.6f) * _underlineWobble;
                _underlineBase.Add(new Vector3(x, y, 0f));
            }
            InkLine.SetPoints(_underline, _underlineBase);
        }

        public void Arm(bool on)
        {
            _armed = on && Interactable;
            if (!on) { _wasHovered = false; }
        }

        public void SetSelected(bool on) { _selected = on && Interactable; }

        /// <summary>Fade multiplier, so an owner (e.g. the settings panel) can show or hide the item.</summary>
        public void SetShown(float a) { _shown = Mathf.Clamp01(a); Apply(); }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;

            if (_armed && Interactable && _camera != null)
            {
                Vector3 wp = PointerInput.WorldPosition(_camera, transform.position.z);
                bool hovered = _collider != null && _collider.OverlapPoint(wp);
                if (hovered && !_wasHovered) Hovered?.Invoke(this);
                _wasHovered = hovered;
                if (hovered && PointerInput.Clicked) Clicked?.Invoke(this);
            }
            else _wasHovered = false;

            _selT = Mathf.MoveTowards(_selT, _selected ? 1f : 0f, Time.deltaTime / Mathf.Max(_selectLerp, 0.01f));
            Apply();
        }

        private void Apply()
        {
            if (_text != null)
            {
                Color c = Interactable ? Color.Lerp(_idleColor, _selectedColor, _selT) : _disabledColor;
                c.a *= _shown;
                _text.color = c;
            }

            if (_underline != null)
            {
                bool show = _showUnderline && Interactable;
                InkLine.SetAlpha(_underline, _underlineColor, show ? _selT * _shown : 0f);
                _underline.enabled = show && _selT * _shown > 0.001f;
            }
        }
    }
}
