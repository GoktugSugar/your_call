using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A real trolley silhouette (rounded body, windows, wheels, a small pole) that
    /// follows a supplied path with anticipation before it launches and a settle on
    /// impact, then raises <see cref="Impact"/> with the impact point. One component,
    /// one job; it knows nothing about figures or choices.
    /// </summary>
    public class Trolley : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _bodyWidth = 0.052f;
        [SerializeField] private float _detailWidth = 0.038f;
        [SerializeField] private int _sortingOrder = 12;
        [SerializeField] private bool _boil = true;

        [Header("Silhouette (local; wheels rest at y = 0)")]
        [SerializeField] private float _bodyMinX = -0.82f;
        [SerializeField] private float _bodyMaxX = 0.86f;
        [SerializeField] private float _bodyMinY = 0.30f;
        [SerializeField] private float _bodyMaxY = 1.02f;
        [SerializeField] private float _bodyRadius = 0.13f;
        [SerializeField] private float _wheelRadius = 0.16f;

        [Header("Motion")]
        [SerializeField] private float _anticipation = 0.35f;
        [SerializeField] private float _recoil = 0.20f;
        [SerializeField] private float _settle = 0.30f;
        [SerializeField] private float _settleKick = 0.13f;

        public event Action<Vector3> Impact;

        private bool _built;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            BuildSilhouette();
            _built = true;
        }

        // ---------- Motion ----------

        public IEnumerator Run(IList<Vector3> path, float travelDuration)
        {
            if (path == null || path.Count < 2) yield break;

            var cum = new float[path.Count];
            for (int i = 1; i < path.Count; i++) cum[i] = cum[i - 1] + Vector3.Distance(path[i - 1], path[i]);
            float total = cum[cum.Length - 1];

            Vector3 tan0 = (path[1] - path[0]);
            tan0 = tan0.sqrMagnitude < 1e-8f ? Vector3.right : tan0.normalized;
            transform.position = path[0];
            SetFacing(tan0);

            // Anticipation: wind up backward along the entry tangent.
            float t = 0f, ant = Mathf.Max(_anticipation, 0.01f);
            while (t < ant) { t += Time.deltaTime; transform.position = path[0] - tan0 * (_recoil * EaseUtil.OutCubic(t / ant)); yield return null; }

            // Travel: accelerate into the impact; the wind-up recoil decays over the first quarter.
            Vector3 tan;
            t = 0f;
            float dur = Mathf.Max(travelDuration, 0.05f);
            while (t < dur)
            {
                t += Time.deltaTime;
                float u = EaseUtil.InCubic(EaseUtil.Clamp01(t / dur));
                Vector3 pos = Sample(path, cum, u * total, out tan);
                float back = _recoil * (1f - EaseUtil.OutCubic(EaseUtil.Clamp01(t / (dur * 0.25f))));
                transform.position = pos - tan * back;
                SetFacing(tan);
                yield return null;
            }

            Vector3 endPos = Sample(path, cum, total, out tan);
            transform.position = endPos;
            SetFacing(tan);
            Impact?.Invoke(endPos);

            // Settle: a damped jolt along the travel direction.
            t = 0f; float st = Mathf.Max(_settle, 0.01f);
            while (t < st)
            {
                t += Time.deltaTime;
                float k = t / st;
                float off = _settleKick * Mathf.Exp(-5f * k) * Mathf.Cos(14f * k);
                transform.position = endPos + tan * off;
                yield return null;
            }
            transform.position = endPos;
        }

        private void SetFacing(Vector3 tangent)
        {
            float ang = Mathf.Atan2(tangent.y, tangent.x) * Mathf.Rad2Deg;
            transform.rotation = Quaternion.Euler(0f, 0f, ang);
        }

        private static Vector3 Sample(IList<Vector3> path, float[] cum, float dist, out Vector3 tangent)
        {
            float total = cum[cum.Length - 1];
            dist = Mathf.Clamp(dist, 0f, total);
            for (int i = 1; i < path.Count; i++)
            {
                if (dist <= cum[i] || i == path.Count - 1)
                {
                    float segLen = cum[i] - cum[i - 1];
                    float f = segLen > 1e-5f ? (dist - cum[i - 1]) / segLen : 0f;
                    tangent = path[i] - path[i - 1];
                    tangent = tangent.sqrMagnitude < 1e-8f ? Vector3.right : tangent.normalized;
                    return Vector3.Lerp(path[i - 1], path[i], f);
                }
            }
            tangent = Vector3.right;
            return path[path.Count - 1];
        }

        // ---------- Build ----------

        private void BuildSilhouette()
        {
            var body = InkLine.Create(transform, "Body", _inkMaterial, _bodyWidth, _color, _sortingOrder);
            InkLine.SetPoints(body, RoundedRect(_bodyMinX, _bodyMinY, _bodyMaxX, _bodyMaxY, _bodyRadius, 4));
            if (_boil) body.gameObject.AddComponent<LineBoil>().Capture();

            // Wheels resting on the rail (bottom at y = 0).
            float wy = _wheelRadius;
            AddCircle("WheelBack", new Vector2(_bodyMinX + 0.35f, wy), _wheelRadius, _detailWidth);
            AddCircle("WheelFront", new Vector2(_bodyMaxX - 0.36f, wy), _wheelRadius, _detailWidth);

            // A couple of windows along the upper body.
            float wyb = _bodyMinY + (_bodyMaxY - _bodyMinY) * 0.42f;
            float wyt = _bodyMaxY - 0.12f;
            AddRect("WindowBack", -0.5f, wyb, -0.06f, wyt);
            AddRect("WindowFront", 0.06f, wyb, 0.5f, wyt);

            // Small trolley pole rising from the roof, with a tiny shoe.
            var pole = InkLine.Create(transform, "Pole", _inkMaterial, _detailWidth, _color, _sortingOrder);
            InkLine.SetPoints(pole, new List<Vector3>
            {
                new Vector3(0.12f, _bodyMaxY, 0f),
                new Vector3(-0.30f, _bodyMaxY + 0.44f, 0f)
            });
            AddCircle("PoleShoe", new Vector2(-0.30f, _bodyMaxY + 0.46f), 0.05f, _detailWidth * 0.9f);
        }

        private void AddCircle(string name, Vector2 center, float radius, float width)
        {
            var lr = InkLine.Create(transform, name, _inkMaterial, width, _color, _sortingOrder);
            var pts = new List<Vector3>();
            InkLine.AddArc(pts, center, radius, 0f, 360f, 20);
            InkLine.SetPoints(lr, pts);
        }

        private void AddRect(string name, float minX, float minY, float maxX, float maxY)
        {
            var lr = InkLine.Create(transform, name, _inkMaterial, _detailWidth, _color, _sortingOrder, 2);
            InkLine.SetPoints(lr, new List<Vector3>
            {
                new Vector3(minX, minY, 0f), new Vector3(maxX, minY, 0f),
                new Vector3(maxX, maxY, 0f), new Vector3(minX, maxY, 0f),
                new Vector3(minX, minY, 0f)
            });
        }

        private static List<Vector3> RoundedRect(float minX, float minY, float maxX, float maxY, float r, int seg)
        {
            var p = new List<Vector3>();
            Vector2 bl = new Vector2(minX + r, minY + r);
            Vector2 br = new Vector2(maxX - r, minY + r);
            Vector2 tr = new Vector2(maxX - r, maxY - r);
            Vector2 tl = new Vector2(minX + r, maxY - r);
            p.Add(new Vector3(minX + r, minY, 0f));
            p.Add(new Vector3(maxX - r, minY, 0f));
            InkLine.AddArc(p, br, r, -90f, 0f, seg);
            p.Add(new Vector3(maxX, maxY - r, 0f));
            InkLine.AddArc(p, tr, r, 0f, 90f, seg);
            p.Add(new Vector3(minX + r, maxY, 0f));
            InkLine.AddArc(p, tl, r, 90f, 180f, seg);
            p.Add(new Vector3(minX, minY + r, 0f));
            InkLine.AddArc(p, bl, r, 180f, 270f, seg);
            return p;
        }
    }
}
