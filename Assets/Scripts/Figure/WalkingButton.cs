using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The button that walks away (Chapter 2's pure gag): a plain ink push-button that, when pressed,
    /// sprouts little stick limbs and a put-out face, recoils as if hurt, then gets up and walks off the
    /// screen. On-model in the simple ink style (see art-and-ui.md), built from LineRenderers like the
    /// Figure. No death, no consequence, just a joke. The imp's genuine surprise is driven by the beat
    /// (<see cref="WalkingButtonBeat"/>); this only draws and animates the button. One job.
    /// </summary>
    public sealed class WalkingButton : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _ink = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private float _detailWidth = 0.04f;
        [SerializeField] private int _sortingOrder = 14;

        [Header("Shape")]
        [SerializeField] private float _radius = 0.5f;

        [Header("Walk")]
        [Tooltip("How fast it strides, in local units per second.")]
        [SerializeField] private float _walkSpeed = 4.2f;
        [Tooltip("Stride swing of the feet.")]
        [SerializeField] private float _stride = 0.14f;
        [Tooltip("Little body bob while walking.")]
        [SerializeField] private float _bob = 0.05f;
        [SerializeField] private float _bobRate = 9f;

        private Transform _rig;         // scaled/rotated for the pop and recoil, leaving position to the root
        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private LineRenderer _legL, _legR;
        private Vector3 _legLHip, _legRHip;
        private bool _built;
        private bool _alive;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _rig = new GameObject("Rig").transform;
            _rig.SetParent(transform, false);

            // The button: an ink circle with a small inner ring, so it reads as a plain push-button
            // before it comes to life.
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _radius, 0f, 360f, 40);
            Stroke("Outline", ring, _lineWidth);
            var inner = new List<Vector3>();
            InkLine.AddArc(inner, Vector2.zero, _radius * 0.62f, 0f, 360f, 32);
            Stroke("Inner", inner, _detailWidth);

            _built = true;
        }

        private LineRenderer Stroke(string name, List<Vector3> pts, float width)
        {
            var lr = InkLine.Create(_rig, name, _inkMaterial, width, _ink, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            lr.gameObject.AddComponent<LineBoil>().Capture();
            _strokes.Add(lr);
            return lr;
        }

        /// <summary>A quick hand-drawn press: the button squashes down (flattens and spreads) and springs
        /// back, the physical feedback of being pressed, before it comes to life. Purely the button; no
        /// limbs yet.</summary>
        public IEnumerator Press(float duration, float squash = 0.2f)
        {
            if (!_built) Build();
            float d = Mathf.Max(duration, 0.05f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = Mathf.Sin(Mathf.Clamp01(t / d) * Mathf.PI); // 0 -> 1 -> 0
                _rig.localScale = new Vector3(1f + k * squash * 0.6f, 1f - k * squash, 1f);
                yield return null;
            }
            _rig.localScale = Vector3.one;
        }

        /// <summary>Sprout limbs and a put-out face, with a hurt recoil. It is alive and offended.</summary>
        public IEnumerator ComeAlive(float duration)
        {
            if (!_built) Build();
            if (_alive) yield break;
            _alive = true;

            // Legs from the base, arms from the sides, a face inside, a downturned mouth.
            _legLHip = new Vector3(-0.16f, -_radius * 0.92f, 0f);
            _legRHip = new Vector3(0.16f, -_radius * 0.92f, 0f);
            _legL = Stroke("LegL", new List<Vector3> { _legLHip, _legLHip + new Vector3(-0.05f, -0.34f, 0f) }, _detailWidth);
            _legR = Stroke("LegR", new List<Vector3> { _legRHip, _legRHip + new Vector3(0.05f, -0.34f, 0f) }, _detailWidth);

            Stroke("ArmL", new List<Vector3> { new Vector3(-_radius * 0.95f, 0.02f, 0f), new Vector3(-_radius - 0.24f, 0.14f, 0f), new Vector3(-_radius - 0.30f, 0.02f, 0f) }, _detailWidth);
            Stroke("ArmR", new List<Vector3> { new Vector3(_radius * 0.95f, 0.02f, 0f), new Vector3(_radius + 0.24f, 0.14f, 0f), new Vector3(_radius + 0.30f, 0.02f, 0f) }, _detailWidth);

            var eyeL = new List<Vector3>(); InkLine.AddArc(eyeL, new Vector2(-0.16f, 0.13f), 0.045f, 0f, 360f, 10); Stroke("EyeL", eyeL, _detailWidth);
            var eyeR = new List<Vector3>(); InkLine.AddArc(eyeR, new Vector2(0.16f, 0.13f), 0.045f, 0f, 360f, 10); Stroke("EyeR", eyeR, _detailWidth);
            // A put-out, downturned mouth.
            var mouth = new List<Vector3>(); InkLine.AddArc(mouth, new Vector2(0f, -0.20f), 0.13f, 35f, 145f, 12); Stroke("Mouth", mouth, _detailWidth);

            // A hurt recoil: a quick lean back and a scale pop, then settle.
            float d = Mathf.Max(duration, 0.05f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);
                float pop = Mathf.Sin(k * Mathf.PI) * 0.14f;
                _rig.localScale = new Vector3(1f + pop, 1f + pop * 1.4f, 1f);
                _rig.localRotation = Quaternion.Euler(0f, 0f, Mathf.Sin(k * Mathf.PI * 2.2f) * 13f * (1f - k));
                yield return null;
            }
            _rig.localScale = Vector3.one;
            _rig.localRotation = Quaternion.identity;
        }

        /// <summary>Get up and walk to a local X (off screen), striding, then hold there.</summary>
        public IEnumerator WalkOff(float toLocalX, System.Func<Vector3, bool> offScreen = null)
        {
            float baseY = transform.localPosition.y;
            int dir = toLocalX < transform.localPosition.x ? -1 : 1;
            float phase = 0f;

            while (true)
            {
                Vector3 p = transform.localPosition;
                float step = _walkSpeed * Time.deltaTime;
                p.x = Mathf.MoveTowards(p.x, toLocalX, step);
                phase += Time.deltaTime * _bobRate;
                p.y = baseY + Mathf.Abs(Mathf.Sin(phase)) * _bob;
                transform.localPosition = p;

                // Stride: swing the two feet in opposition.
                float swing = Mathf.Sin(phase) * _stride;
                if (_legL != null) InkLine.SetPoints(_legL, new List<Vector3> { _legLHip, _legLHip + new Vector3(-0.05f + swing, -0.34f, 0f) });
                if (_legR != null) InkLine.SetPoints(_legR, new List<Vector3> { _legRHip, _legRHip + new Vector3(0.05f - swing, -0.34f, 0f) });
                // A tiny waddle lean into the stride.
                _rig.localRotation = Quaternion.Euler(0f, 0f, Mathf.Sin(phase) * 4f * dir);

                bool done = Mathf.Approximately(p.x, toLocalX);
                if (offScreen != null && offScreen(transform.position)) done = true;
                if (done) yield break;
                yield return null;
            }
        }

        public void SetAlpha(float a)
        {
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _ink, a);
        }
    }
}
