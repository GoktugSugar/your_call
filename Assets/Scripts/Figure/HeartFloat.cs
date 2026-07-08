using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A small hand-drawn ink heart that floats over the player's partner (the loved one) and gently
    /// pulses and bobs on a loop, in the ink style (see docs/art-and-ui.md), so the relationship reads
    /// at a glance. Pink to match the partner's outline (pink = love). Instanced as a child of the
    /// partner figure at the head by the trolley presenter; it stops the moment the figure is struck.
    /// One component, one job (mirrors <see cref="SleepZ"/>).
    /// </summary>
    public sealed class HeartFloat : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.InkPink;
        [SerializeField] private float _lineWidth = 0.04f;
        [SerializeField] private int _sortingOrder = 12;

        [Header("Heart")]
        [SerializeField] private float _size = 0.3f;
        [SerializeField, Range(10, 40)] private int _segments = 26;

        [Header("Motion (a gentle beat and bob, looping)")]
        [Tooltip("How much the heart swells and shrinks, as a fraction.")]
        [SerializeField] private float _pulseAmount = 0.14f;
        [SerializeField] private float _pulsePeriod = 1.2f;
        [Tooltip("A small vertical drift on top of the beat.")]
        [SerializeField] private float _bobAmount = 0.05f;
        [SerializeField] private float _bobPeriod = 2.6f;

        private Figure _figure;
        private Transform _heart;
        private LineRenderer _line;
        private bool _built;
        private bool _stopped;

        private void Awake()
        {
            _figure = GetComponentInParent<Figure>();
            Build();
        }

        private void Build()
        {
            if (_built) return;
            var go = new GameObject("Heart");
            go.transform.SetParent(transform, false);
            _heart = go.transform;
            _line = InkLine.Create(_heart, "Ink", _inkMaterial, _lineWidth, _color, _sortingOrder);
            InkLine.SetPoints(_line, HeartShape(_segments));
            _built = true;
        }

        // A closed heart outline (the classic parametric heart), scaled to roughly a unit and centred,
        // so the child transform's scale sets its size and the pulse.
        private static List<Vector3> HeartShape(int seg)
        {
            var pts = new List<Vector3>(seg + 1);
            for (int i = 0; i <= seg; i++)
            {
                float t = (i / (float)seg) * Mathf.PI * 2f;
                float x = 16f * Mathf.Pow(Mathf.Sin(t), 3f);
                float y = 13f * Mathf.Cos(t) - 5f * Mathf.Cos(2f * t) - 2f * Mathf.Cos(3f * t) - Mathf.Cos(4f * t);
                pts.Add(new Vector3(x / 34f, (y + 2.6f) / 34f, 0f));
            }
            return pts;
        }

        private void Update()
        {
            if (!_built || _heart == null) return;

            if (_figure != null && _figure.IsStruck)
            {
                if (!_stopped) { _stopped = true; if (_line != null) InkLine.SetAlpha(_line, _color, 0f); }
                return;
            }

            float pulse = 1f + Mathf.Sin(Time.time * (Mathf.PI * 2f / Mathf.Max(_pulsePeriod, 0.05f))) * _pulseAmount;
            float bob = Mathf.Sin(Time.time * (Mathf.PI * 2f / Mathf.Max(_bobPeriod, 0.05f))) * _bobAmount;
            _heart.localScale = new Vector3(_size * pulse, _size * pulse, 1f);
            _heart.localPosition = new Vector3(0f, bob, 0f);
        }
    }
}
