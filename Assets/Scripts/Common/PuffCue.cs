using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The one cheap motion cue at impact: a small ink puff plus a couple of speed
    /// lines that expand and fade, then remove themselves. Nothing is left behind.
    /// </summary>
    public class PuffCue : MonoBehaviour
    {
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = new Color(0.106f, 0.102f, 0.090f, 1f);
        [SerializeField] private float _width = 0.05f;
        [SerializeField] private float _duration = 0.45f;
        [SerializeField] private float _reach = 0.75f;
        [SerializeField] private int _sortingOrder = 15;
        [SerializeField] private int _speedLines = 3;

        private readonly List<LineRenderer> _marks = new List<LineRenderer>();
        private readonly List<Vector3[]> _base = new List<Vector3[]>();

        public void Configure(Material inkMaterial) { _inkMaterial = inkMaterial; }

        /// <summary>Fire the cue at world position p, then destroy this GameObject.</summary>
        public void Play(Vector3 p)
        {
            transform.position = p;
            Build();
            StartCoroutine(Run());
        }

        private void Build()
        {
            const int ticks = 5;
            for (int i = 0; i < ticks; i++)
            {
                float a = Mathf.Deg2Rad * (35f + i * (110f / (ticks - 1)));
                var dir = new Vector3(Mathf.Cos(a), Mathf.Sin(a), 0f);
                var lr = InkLine.Create(transform, "Puff" + i, _inkMaterial, _width, _color, _sortingOrder);
                var pts = new List<Vector3> { dir * 0.12f, dir * 0.32f };
                InkLine.SetPoints(lr, pts);
                _marks.Add(lr); _base.Add(new[] { pts[0], pts[1] });
            }
            for (int i = 0; i < _speedLines; i++)
            {
                float y = -0.12f + i * 0.12f;
                var lr = InkLine.Create(transform, "Speed" + i, _inkMaterial, _width * 0.8f, _color, _sortingOrder);
                var pts = new List<Vector3> { new Vector3(-0.16f, y, 0f), new Vector3(-0.56f, y, 0f) };
                InkLine.SetPoints(lr, pts);
                _marks.Add(lr); _base.Add(new[] { pts[0], pts[1] });
            }
        }

        private IEnumerator Run()
        {
            float t = 0f;
            while (t < _duration)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / _duration);
                float scale = Mathf.Lerp(0.6f, _reach / 0.32f, k);
                float alpha = 1f - EaseUtil.Clamp01(t / _duration);
                for (int i = 0; i < _marks.Count; i++)
                {
                    var b = _base[i];
                    _marks[i].SetPosition(0, b[0] * scale);
                    _marks[i].SetPosition(1, b[1] * scale);
                    InkLine.SetAlpha(_marks[i], _color, alpha);
                }
                yield return null;
            }
            Destroy(gameObject);
        }
    }
}
