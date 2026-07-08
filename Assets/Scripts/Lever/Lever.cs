using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The diegetic switch lever: an ink post with an amber handle. Hovering intensifies
    /// the amber; clicking throws it and raises <see cref="Pulled"/>. Picking is done with
    /// the new Input System against a Collider2D, so no EventSystem is needed. The amber
    /// here is one of the game's only accents: attention now, consequence next.
    /// </summary>
    [RequireComponent(typeof(BoxCollider2D))]
    public class Lever : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _postColor = Palette.Ink;
        [SerializeField] private Color _amber = Palette.Amber;
        [SerializeField] private float _postWidth = 0.05f;
        [SerializeField] private float _handleWidth = 0.062f;
        [SerializeField] private int _sortingOrder = 6;

        [Header("Shape")]
        [SerializeField] private float _postHeight = 0.52f;
        [SerializeField] private float _handleLength = 0.52f;
        [SerializeField] private float _knobRadius = 0.075f;
        [SerializeField] private float _restAngle = -34f;
        [SerializeField] private float _throwAngle = 34f;

        [Header("Feel")]
        [SerializeField] private float _hoverWidthMul = 1.28f;
        [SerializeField, Range(0f, 1f)] private float _restIntensity = 0.82f;
        [SerializeField] private float _throwDuration = 0.32f;
        [SerializeField] private float _pulsePeriod = 1.7f;
        [SerializeField] private float _pulseAmount = 0.12f;

        [SerializeField] private Camera _camera;

        public event Action Pulled;

        private LineRenderer _post;
        private LineRenderer _handle;
        private LineRenderer _knob;
        private BoxCollider2D _collider;
        private float _angle;
        private float _hoverT;
        private bool _armed;
        private bool _thrown;
        private bool _pulled;
        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _angle = _restAngle;

            var basePts = new List<Vector3> { new Vector3(-0.16f, 0f, 0f), new Vector3(0.16f, 0f, 0f) };
            var baseLine = InkLine.Create(transform, "Base", _inkMaterial, _postWidth, _postColor, _sortingOrder - 1, 2);
            InkLine.SetPoints(baseLine, basePts);

            _post = InkLine.Create(transform, "Post", _inkMaterial, _postWidth, _postColor, _sortingOrder - 1);
            InkLine.SetPoints(_post, new List<Vector3> { Vector3.zero, new Vector3(0f, _postHeight, 0f) });
            _post.gameObject.AddComponent<LineBoil>().Capture();

            _handle = InkLine.Create(transform, "Handle", _inkMaterial, _handleWidth, _amber, _sortingOrder);
            _handle.positionCount = 2;

            _knob = InkLine.Create(transform, "Knob", _inkMaterial, _handleWidth, _amber, _sortingOrder);
            var knobPts = new List<Vector3>();
            InkLine.AddArc(knobPts, Vector2.zero, _knobRadius, 0f, 360f, 14);
            InkLine.SetPoints(_knob, knobPts);

            _collider = GetComponent<BoxCollider2D>();
            _collider.isTrigger = true;
            _collider.offset = new Vector2(0f, _postHeight + _handleLength * 0.35f);
            _collider.size = new Vector2(_handleLength * 1.8f, _handleLength * 1.6f);

            _built = true;
            ApplyHandle();
        }

        public void Arm(bool on) { _armed = on; }

        /// <summary>Reset the switch to its resting state so one shared station can run many dilemmas in a
        /// row: not thrown, not pulled, disarmed, handle back at rest. Any in-flight throw is stopped.</summary>
        public void ResetSwitch()
        {
            StopAllCoroutines();
            _thrown = false;
            _pulled = false;
            _armed = false;
            _hoverT = 0f;
            _angle = _restAngle;
            if (_built) ApplyHandle();
        }

        /// <summary>Animate the throw without raising the event (for a text-chosen divert).</summary>
        public void Throw()
        {
            if (_thrown) return;
            _thrown = true;
            if (isActiveAndEnabled) StartCoroutine(ThrowRoutine());
            else _angle = _throwAngle;
        }

        private void Pull()
        {
            if (_pulled) return;
            _pulled = true;
            _armed = false;
            Throw();
            Pulled?.Invoke();
        }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;

            if (_armed && !_pulled && _camera != null)
            {
                Vector3 wp = PointerInput.WorldPosition(_camera, transform.position.z);
                bool hovered = _collider.OverlapPoint(wp);
                _hoverT = Mathf.MoveTowards(_hoverT, hovered ? 1f : 0f, Time.deltaTime / 0.12f);
                if (hovered && PointerInput.Clicked) Pull();
            }
            else
            {
                _hoverT = Mathf.MoveTowards(_hoverT, 0f, Time.deltaTime / 0.12f);
            }

            ApplyHandle();
        }

        private void ApplyHandle()
        {
            float rad = _angle * Mathf.Deg2Rad;
            Vector3 pivot = new Vector3(0f, _postHeight, 0f);
            Vector3 end = pivot + new Vector3(Mathf.Sin(rad) * _handleLength, Mathf.Cos(rad) * _handleLength, 0f);
            _handle.SetPosition(0, pivot);
            _handle.SetPosition(1, end);
            _knob.transform.localPosition = end;

            float alpha = Mathf.Lerp(_restIntensity, 1f, _hoverT);
            if (_armed && !_thrown)
                alpha += Mathf.Sin(Time.time * (Mathf.PI * 2f / _pulsePeriod)) * _pulseAmount * (1f - _hoverT);
            alpha = Mathf.Clamp01(alpha);

            float w = _handleWidth * Mathf.Lerp(1f, _hoverWidthMul, _hoverT);
            var c = _amber; c.a = alpha;
            _handle.widthMultiplier = w; InkLine.SetColor(_handle, c);
            _knob.widthMultiplier = w; InkLine.SetColor(_knob, c);
        }

        private IEnumerator ThrowRoutine()
        {
            float from = _angle, to = _throwAngle;
            float t = 0f, d = Mathf.Max(_throwDuration, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                _angle = Mathf.LerpUnclamped(from, to, EaseUtil.OutBack(t / d));
                yield return null;
            }
            _angle = to;
        }
    }
}
