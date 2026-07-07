using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The amber attention lock: four hand-drawn corner brackets that snap around whichever
    /// target the crosshair is over (the man or the bear). This is the single amber accent in
    /// the shooting dilemma, used only for attention exactly as the palette rule intends; the
    /// figures themselves stay black ink. It knows nothing about aiming or outcomes: the
    /// presenter tells it where and how big to sit, or to clear. One job, one element.
    /// </summary>
    public sealed class AimHighlight : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Amber;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private int _sortingOrder = 16;

        [Header("Shape")]
        [Tooltip("Length of each corner bracket arm.")]
        [SerializeField] private float _cornerLength = 0.28f;
        [Tooltip("Grow the locked box out from the target by this on every side.")]
        [SerializeField] private float _padding = 0.14f;

        [Header("Feel")]
        [SerializeField] private float _fade = 0.12f;
        [SerializeField] private float _pulsePeriod = 1.5f;
        [SerializeField, Range(0f, 0.5f)] private float _pulseAmount = 0.18f;

        private readonly LineRenderer[] _corners = new LineRenderer[4];
        private bool _shown;
        private Vector2 _center;
        private Vector2 _half;
        private float _alpha;
        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            for (int i = 0; i < 4; i++)
            {
                _corners[i] = InkLine.Create(transform, "Corner" + i, _inkMaterial, _lineWidth, _color, _sortingOrder);
                _corners[i].positionCount = 3;
            }
            _built = true;
            _alpha = 0f;
            ApplyAlpha();
        }

        /// <summary>Lock the brackets around a target box (world centre and full size).</summary>
        public void Show(Vector2 center, Vector2 size)
        {
            if (!_built) Build();
            _shown = true;
            _center = center;
            _half = size * 0.5f + Vector2.one * _padding;
            LayOutCorners();
        }

        public void Hide() { _shown = false; }

        private void Update()
        {
            if (!_built) return;
            float target = _shown ? 1f : 0f;
            _alpha = Mathf.MoveTowards(_alpha, target, Time.deltaTime / Mathf.Max(_fade, 0.01f));
            ApplyAlpha();
        }

        private void LayOutCorners()
        {
            // Corners: 0 TL, 1 TR, 2 BR, 3 BL. Each is an L pointing inward.
            SetCorner(0, new Vector2(_center.x - _half.x, _center.y + _half.y), 1f, -1f);
            SetCorner(1, new Vector2(_center.x + _half.x, _center.y + _half.y), -1f, -1f);
            SetCorner(2, new Vector2(_center.x + _half.x, _center.y - _half.y), -1f, 1f);
            SetCorner(3, new Vector2(_center.x - _half.x, _center.y - _half.y), 1f, 1f);
        }

        private void SetCorner(int i, Vector2 corner, float sx, float sy)
        {
            var lr = _corners[i];
            lr.SetPosition(0, new Vector3(corner.x + sx * _cornerLength, corner.y, 0f));
            lr.SetPosition(1, new Vector3(corner.x, corner.y, 0f));
            lr.SetPosition(2, new Vector3(corner.x, corner.y + sy * _cornerLength, 0f));
        }

        private void ApplyAlpha()
        {
            float a = _alpha;
            if (_shown) a *= 1f - _pulseAmount * (0.5f + 0.5f * Mathf.Sin(Time.time * (Mathf.PI * 2f / _pulsePeriod)));
            for (int i = 0; i < 4; i++)
                if (_corners[i] != null) InkLine.SetAlpha(_corners[i], _color, a);
        }
    }
}
