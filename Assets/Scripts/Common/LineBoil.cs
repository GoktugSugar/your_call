using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A subtle line boil: cycles two or three near-identical jittered copies of a
    /// LineRenderer's points so the ink reads as hand-drawn and alive for almost no
    /// cost (see docs/art-and-ui.md). Endpoints barely move so joints stay connected.
    /// </summary>
    [RequireComponent(typeof(LineRenderer))]
    public class LineBoil : MonoBehaviour
    {
        [SerializeField] private float _amplitude = 0.014f;
        [SerializeField] private float _interval = 0.11f;
        [SerializeField, Range(2, 4)] private int _frames = 3;

        private LineRenderer _lr;
        private Vector3[][] _variants;
        private int _current;
        private float _t;

        private void OnEnable() { Capture(); }

        /// <summary>Read the current points as the clean base and rebuild the jittered frames.</summary>
        public void Capture()
        {
            _lr = GetComponent<LineRenderer>();
            int n = _lr.positionCount;
            if (n == 0) { _variants = null; return; }

            var basePts = new Vector3[n];
            _lr.GetPositions(basePts);

            _variants = new Vector3[_frames][];
            for (int f = 0; f < _frames; f++)
            {
                var v = new Vector3[n];
                for (int i = 0; i < n; i++)
                {
                    float edge = (i == 0 || i == n - 1) ? 0.35f : 1f;
                    float ox = (Hash01((i * 73856093) ^ (f * 19349663)) - 0.5f) * 2f;
                    float oy = (Hash01((i * 83492791) ^ (f * 39916801)) - 0.5f) * 2f;
                    v[i] = basePts[i] + new Vector3(ox, oy, 0f) * (_amplitude * edge);
                }
                _variants[f] = v;
            }
            _current = 0; _t = 0f;
        }

        private void Update()
        {
            if (_variants == null) return;
            _t += Time.deltaTime;
            if (_t < _interval) return;
            _t = 0f;
            _current = (_current + 1) % _frames;
            _lr.SetPositions(_variants[_current]);
        }

        private static float Hash01(int x)
        {
            unchecked
            {
                x = (x ^ 61) ^ (x >> 16);
                x = x + (x << 3);
                x = x ^ (x >> 4);
                x = x * 0x27d4eb2d;
                x = x ^ (x >> 15);
                return ((x & 0x7fffffff) % 10000) / 10000f;
            }
        }
    }
}
