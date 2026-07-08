using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Small hand-drawn "z" marks that rise from a sleeping figure's head, drifting up and out and
    /// fading, on a gentle staggered loop, in the ink style (see docs/art-and-ui.md). Instanced as a
    /// child of a sleeping figure at the head's top-right by the trolley presenter. It stops the moment
    /// the figure is struck (they never wake, and then they are gone). One component, one job.
    /// </summary>
    public sealed class SleepZ : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.03f;
        [SerializeField] private int _sortingOrder = 12;

        [Header("Marks")]
        [Tooltip("How many z marks drift in the loop at once.")]
        [SerializeField, Range(1, 5)] private int _count = 3;
        [SerializeField] private float _size = 0.13f;
        [Tooltip("Seconds for one z to travel its whole rise-and-fade before the next takes its place.")]
        [SerializeField] private float _period = 2.4f;
        [Tooltip("How far a z rises over its life.")]
        [SerializeField] private float _riseHeight = 0.62f;
        [Tooltip("How far a z drifts to the right as it rises.")]
        [SerializeField] private float _drift = 0.2f;
        [Tooltip("Extra size a z gains by the top of its rise, as a fraction.")]
        [SerializeField] private float _growth = 0.5f;

        private Figure _figure;
        private readonly List<Transform> _marks = new List<Transform>();
        private readonly List<LineRenderer> _lines = new List<LineRenderer>();
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
            for (int i = 0; i < _count; i++)
            {
                var go = new GameObject("Z" + i);
                go.transform.SetParent(transform, false);
                var lr = InkLine.Create(go.transform, "Ink", _inkMaterial, _lineWidth, _color, _sortingOrder);
                InkLine.SetPoints(lr, ZShape());
                InkLine.SetAlpha(lr, _color, 0f);
                _marks.Add(go.transform);
                _lines.Add(lr);
            }
            _built = true;
        }

        // The letter z as a unit shape (top bar, diagonal, bottom bar), scaled per mark.
        private static List<Vector3> ZShape()
        {
            return new List<Vector3>
            {
                new Vector3(-0.5f, 1f, 0f),
                new Vector3(0.5f, 1f, 0f),
                new Vector3(-0.5f, 0f, 0f),
                new Vector3(0.5f, 0f, 0f),
            };
        }

        private void Update()
        {
            if (!_built) return;

            // They never wake: once struck, the marks vanish and stop.
            if (_figure != null && _figure.IsStruck)
            {
                if (!_stopped)
                {
                    _stopped = true;
                    for (int i = 0; i < _lines.Count; i++) if (_lines[i] != null) InkLine.SetAlpha(_lines[i], _color, 0f);
                }
                return;
            }

            for (int i = 0; i < _marks.Count; i++)
            {
                float phase = _count > 0 ? (float)i / _count : 0f;
                float p = Mathf.Repeat(Time.time / Mathf.Max(_period, 0.05f) + phase, 1f);
                float s = _size * (1f + _growth * p);
                _marks[i].localPosition = new Vector3(p * _drift, p * _riseHeight, 0f);
                _marks[i].localScale = new Vector3(s, s, 1f);
                InkLine.SetAlpha(_lines[i], _color, Mathf.Sin(p * Mathf.PI));   // fade in then out
            }
        }
    }
}
