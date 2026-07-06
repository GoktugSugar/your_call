using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The forking track and the single source of truth for layout. Everything else
    /// asks the Track where the figures stand and which path the trolley runs, so no
    /// other component hard-codes geometry. Draws clean rails with light cross-ties.
    /// </summary>
    public class Track : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _railColor = new Color(0.106f, 0.102f, 0.090f, 1f);
        [SerializeField] private float _railWidth = 0.05f;
        [SerializeField] private Color _tieColor = new Color(0.604f, 0.588f, 0.549f, 1f);
        [SerializeField] private float _tieWidth = 0.035f;
        [SerializeField] private int _sortingOrder = 0;

        [Header("Geometry")]
        [SerializeField] private float _trolleyStartX = -7.0f;
        [SerializeField] private float _mainY = 0f;
        [SerializeField] private float _forkX = -2.6f;
        [SerializeField] private float _mainEndX = 6.8f;
        [SerializeField] private Vector2 _spurEnd = new Vector2(5.0f, -2.6f);
        [Tooltip("How far the switch runs level before bending down toward the spur end.")]
        [SerializeField] private float _spurControlDX = 2.4f;
        [SerializeField, Range(6, 32)] private int _spurSegments = 18;

        [Header("Figures")]
        [SerializeField] private int _mainCount = 5;
        [SerializeField] private float _mainGroupCenterX = 4.8f;
        [SerializeField] private float _mainSpacing = 0.56f;

        [Header("Cross-ties")]
        [SerializeField] private float _tieSpacing = 0.7f;
        [SerializeField] private float _tieLength = 0.34f;

        [Header("Path")]
        [Tooltip("How far the trolley noses into a struck group before it stops.")]
        [SerializeField] private float _impactOverlap = 0.25f;

        private List<Vector3> _spur; // local spur polyline: fork -> spurEnd
        private bool _built;

        public int MainCount => _mainCount;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            _spur = BuildSpurPolyline();
            BuildRails();
            BuildTies();
            _built = true;
        }

        // ---------- Queries (world space) ----------

        public Vector3 TrolleyStart => transform.TransformPoint(new Vector3(_trolleyStartX, _mainY, 0f));
        public Vector3 LeverPosition => transform.TransformPoint(new Vector3(_forkX, _mainY, 0f));
        public Vector3 SpurFigurePosition => transform.TransformPoint(new Vector3(_spurEnd.x, _spurEnd.y, 0f));

        public List<Vector3> MainFigurePositions()
        {
            var list = new List<Vector3>(_mainCount);
            float total = (_mainCount - 1) * _mainSpacing;
            float startX = _mainGroupCenterX - total * 0.5f;
            for (int i = 0; i < _mainCount; i++)
                list.Add(transform.TransformPoint(new Vector3(startX + i * _mainSpacing, _mainY, 0f)));
            return list;
        }

        /// <summary>Waypoints for the trolley. A route containing "spur" diverts; otherwise straight.</summary>
        public List<Vector3> GetPath(string route)
        {
            if (_spur == null) _spur = BuildSpurPolyline();
            bool spur = !string.IsNullOrEmpty(route) && route.ToLowerInvariant().Contains("spur");
            var pts = new List<Vector3> { new Vector3(_trolleyStartX, _mainY, 0f) };
            if (spur)
            {
                for (int i = 0; i < _spur.Count; i++) pts.Add(_spur[i]);
            }
            else
            {
                float total = (_mainCount - 1) * _mainSpacing;
                float leftX = _mainGroupCenterX - total * 0.5f;
                pts.Add(new Vector3(leftX + _impactOverlap, _mainY, 0f));
            }
            for (int i = 0; i < pts.Count; i++) pts[i] = transform.TransformPoint(pts[i]);
            return pts;
        }

        // ---------- Build ----------

        private List<Vector3> BuildSpurPolyline()
        {
            var pts = new List<Vector3>(_spurSegments + 1);
            Vector2 a = new Vector2(_forkX, _mainY);
            Vector2 b = new Vector2(_forkX + _spurControlDX, _mainY);
            Vector2 c = _spurEnd;
            for (int i = 0; i <= _spurSegments; i++)
            {
                float t = (float)i / _spurSegments;
                float u = 1f - t;
                Vector2 p = u * u * a + 2f * u * t * b + t * t * c;
                pts.Add(new Vector3(p.x, p.y, 0f));
            }
            return pts;
        }

        private void BuildRails()
        {
            var main = InkLine.Create(transform, "MainRail", _inkMaterial, _railWidth, _railColor, _sortingOrder);
            InkLine.SetPoints(main, new List<Vector3>
            {
                new Vector3(_trolleyStartX - 0.8f, _mainY, 0f),
                new Vector3(_mainEndX, _mainY, 0f)
            });
            main.gameObject.AddComponent<LineBoil>().Capture();

            var spur = InkLine.Create(transform, "SpurRail", _inkMaterial, _railWidth, _railColor, _sortingOrder);
            InkLine.SetPoints(spur, _spur);
            spur.gameObject.AddComponent<LineBoil>().Capture();
        }

        private void BuildTies()
        {
            var container = new GameObject("Ties");
            container.transform.SetParent(transform, false);

            // Main line: vertical ties.
            int idx = 0;
            for (float x = _trolleyStartX; x <= _mainEndX; x += _tieSpacing, idx++)
            {
                var lr = InkLine.Create(container.transform, "TieM" + idx, _inkMaterial, _tieWidth, _tieColor, _sortingOrder - 1, 2);
                InkLine.SetPoints(lr, new List<Vector3>
                {
                    new Vector3(x, _mainY - _tieLength * 0.5f, 0f),
                    new Vector3(x, _mainY + _tieLength * 0.5f, 0f)
                });
            }

            // Spur: ties perpendicular to the local tangent, every other sample.
            for (int i = 1; i < _spur.Count - 1; i += 2)
            {
                Vector3 center = _spur[i];
                Vector3 tangent = (_spur[i + 1] - _spur[i - 1]).normalized;
                Vector3 normal = new Vector3(-tangent.y, tangent.x, 0f);
                var lr = InkLine.Create(container.transform, "TieS" + i, _inkMaterial, _tieWidth, _tieColor, _sortingOrder - 1, 2);
                InkLine.SetPoints(lr, new List<Vector3>
                {
                    center - normal * (_tieLength * 0.5f),
                    center + normal * (_tieLength * 0.5f)
                });
            }
        }
    }
}
