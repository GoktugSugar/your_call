using System;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The first person gun: an ink reticle that follows the pointer over the void, with an
    /// optional subtle ink barrel at the lower frame edge to sell the point of view. This is the
    /// diegetic aim for the shooting dilemma, the analogue of the trolley's <see cref="Lever"/>.
    /// It is pure black ink (the amber attention lock lives on the target, in <see cref="AimHighlight"/>);
    /// it only draws and reports where it is aimed and when it fires. It raises <see cref="Fired"/>
    /// with the world point under the reticle; the presenter decides what, if anything, was hit.
    /// </summary>
    public sealed class Crosshair : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.032f;
        [SerializeField] private int _sortingOrder = 30;
        [SerializeField] private bool _boil = true;

        [Header("Reticle")]
        [SerializeField] private float _radius = 0.32f;
        [SerializeField] private float _tickGap = 0.06f;
        [SerializeField] private float _tickLength = 0.17f;
        [SerializeField] private float _centerDotRadius = 0.022f;

        [Header("Barrel (subtle POV cue, tunable)")]
        [SerializeField] private bool _showBarrel = true;
        [SerializeField] private Vector2 _barrelPosition = new Vector2(0f, -4.55f);
        [SerializeField] private float _barrelHalfWidth = 0.34f;
        [SerializeField] private float _barrelHeight = 0.95f;

        [Header("Feel")]
        [Tooltip("Seconds to ink the reticle in or out as aiming is armed / disarmed.")]
        [SerializeField] private float _fade = 0.18f;
        [SerializeField] private Camera _camera;

        /// <summary>Fired at the given world point (only while armed).</summary>
        public event Action<Vector3> Fired;

        /// <summary>The world point the reticle currently sits over.</summary>
        public Vector3 AimPoint { get; private set; }

        private Transform _reticleRoot;
        private readonly List<LineRenderer> _reticle = new List<LineRenderer>();
        private readonly List<LineRenderer> _barrel = new List<LineRenderer>();
        private bool _armed;
        private bool _built;
        private float _alpha;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;

            _reticleRoot = new GameObject("Reticle").transform;
            _reticleRoot.SetParent(transform, false);

            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _radius, 0f, 360f, 40);
            AddReticleStroke("Ring", ring);

            // Four ticks just outside the ring (N / E / S / W).
            AddReticleStroke("TickN", Segment(new Vector2(0f, _radius + _tickGap), new Vector2(0f, _radius + _tickGap + _tickLength)));
            AddReticleStroke("TickS", Segment(new Vector2(0f, -_radius - _tickGap), new Vector2(0f, -_radius - _tickGap - _tickLength)));
            AddReticleStroke("TickE", Segment(new Vector2(_radius + _tickGap, 0f), new Vector2(_radius + _tickGap + _tickLength, 0f)));
            AddReticleStroke("TickW", Segment(new Vector2(-_radius - _tickGap, 0f), new Vector2(-_radius - _tickGap - _tickLength, 0f)));

            var dot = new List<Vector3>();
            InkLine.AddArc(dot, Vector2.zero, _centerDotRadius, 0f, 360f, 10);
            AddReticleStroke("CenterDot", dot);

            if (_showBarrel) BuildBarrel();

            _built = true;
            _alpha = 0f;
            ApplyAlpha();
        }

        private void BuildBarrel()
        {
            var barrelRoot = new GameObject("Barrel").transform;
            barrelRoot.SetParent(transform, false);
            barrelRoot.localPosition = new Vector3(_barrelPosition.x, _barrelPosition.y, 0f);

            float bw = _barrelHalfWidth, h = _barrelHeight;
            AddBarrelStroke(barrelRoot, "SideL", Segment(new Vector2(-bw, 0f), new Vector2(-bw, h)));
            AddBarrelStroke(barrelRoot, "SideR", Segment(new Vector2(bw, 0f), new Vector2(bw, h)));

            // The muzzle rim: a shallow arc across the top opening.
            var rim = new List<Vector3>();
            InkLine.AddArc(rim, new Vector2(0f, h - bw * 0.5f), bw, 20f, 160f, 16);
            AddBarrelStroke(barrelRoot, "Rim", rim);
        }

        private void AddReticleStroke(string name, List<Vector3> pts)
        {
            var lr = InkLine.Create(_reticleRoot, name, _inkMaterial, _lineWidth, _color, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _reticle.Add(lr);
        }

        private void AddBarrelStroke(Transform root, string name, List<Vector3> pts)
        {
            var lr = InkLine.Create(root, name, _inkMaterial, _lineWidth * 1.6f, _color, _sortingOrder - 1);
            InkLine.SetPoints(lr, pts);
            if (_boil) lr.gameObject.AddComponent<LineBoil>().Capture();
            _barrel.Add(lr);
        }

        public void Arm(bool on) { _armed = on; }

        private void Update()
        {
            if (!_built) return;
            if (_camera == null) _camera = Camera.main;
            if (_camera == null) return;

            AimPoint = PointerInput.WorldPosition(_camera, transform.position.z);
            _reticleRoot.position = new Vector3(AimPoint.x, AimPoint.y, transform.position.z);

            float target = _armed ? 1f : 0f;
            _alpha = Mathf.MoveTowards(_alpha, target, Time.deltaTime / Mathf.Max(_fade, 0.01f));
            ApplyAlpha();

            if (_armed && _alpha > 0.5f && PointerInput.Clicked)
                Fired?.Invoke(AimPoint);
        }

        private void ApplyAlpha()
        {
            for (int i = 0; i < _reticle.Count; i++) InkLine.SetAlpha(_reticle[i], _color, _alpha);
            for (int i = 0; i < _barrel.Count; i++) InkLine.SetAlpha(_barrel[i], _color, _alpha);
        }

        private static List<Vector3> Segment(Vector2 a, Vector2 b)
            => new List<Vector3> { new Vector3(a.x, a.y, 0f), new Vector3(b.x, b.y, 0f) };
    }
}
