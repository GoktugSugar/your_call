using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The forking track and the single source of truth for layout. Everything else asks the
    /// Track where the figures stand and which path the trolley runs, so nothing else hard-codes
    /// geometry. The branch is a schematic right-angle switch: the main line runs straight through
    /// the fork, and the second track steps down at a right angle then runs straight and parallel
    /// below (---|---- over |____). Draws clean rails with light cross-ties.
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
        [SerializeField] private float _trolleyStartX = -4.3f;
        [SerializeField] private float _mainY = 0f;
        [Tooltip("Where the branch steps off the main line (the switch, and where the lever sits).")]
        [SerializeField] private float _forkX = -0.5f;
        [SerializeField] private float _mainEndX = 4.8f;

        [Header("Right-angle branch (parallel, below the main line)")]
        [Tooltip("The y of the horizontal branch: the switch drops straight to here at the fork, then runs parallel.")]
        [SerializeField] private float _branchY = -1.6f;
        [Tooltip("Where the branch rail ends (it runs past the lone figure).")]
        [SerializeField] private float _branchEndX = 4.8f;
        [Tooltip("Where the lone figure stands on the branch.")]
        [SerializeField] private float _spurFigureX = 2.6f;

        [Header("Figures")]
        [SerializeField] private int _mainCount = 5;
        [SerializeField] private float _mainGroupCenterX = 2.6f;
        [SerializeField] private float _mainSpacing = 0.56f;

        [Header("Cross-ties")]
        [SerializeField] private float _tieSpacing = 0.7f;
        [SerializeField] private float _tieLength = 0.34f;

        [Header("Path")]
        [Tooltip("How far the trolley noses into a struck group before it stops.")]
        [SerializeField] private float _impactOverlap = 0.25f;

        private bool _built;

        public int MainCount => _mainCount;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;
            BuildRails();
            BuildTies();
            _built = true;
        }

        // ---------- Queries (world space) ----------

        public Vector3 TrolleyStart => transform.TransformPoint(new Vector3(_trolleyStartX, _mainY, 0f));
        public Vector3 LeverPosition => transform.TransformPoint(new Vector3(_forkX, _mainY, 0f));
        public Vector3 SpurFigurePosition => transform.TransformPoint(new Vector3(_spurFigureX, _branchY, 0f));

        public List<Vector3> MainFigurePositions()
        {
            var list = new List<Vector3>(_mainCount);
            float total = (_mainCount - 1) * _mainSpacing;
            float startX = _mainGroupCenterX - total * 0.5f;
            for (int i = 0; i < _mainCount; i++)
                list.Add(transform.TransformPoint(new Vector3(startX + i * _mainSpacing, _mainY, 0f)));
            return list;
        }

        /// <summary>Waypoints for the trolley. A route containing "spur" diverts: straight to the
        /// switch, a right-angle corner down, then straight along the branch to the lone figure.
        /// Otherwise it runs straight into the main group.</summary>
        public List<Vector3> GetPath(string route)
        {
            bool spur = !string.IsNullOrEmpty(route) && route.ToLowerInvariant().Contains("spur");
            var pts = new List<Vector3> { new Vector3(_trolleyStartX, _mainY, 0f) };
            if (spur)
            {
                pts.Add(new Vector3(_forkX, _mainY, 0f));          // straight to the switch
                pts.Add(new Vector3(_forkX, _branchY, 0f));        // corner: step down at a right angle
                pts.Add(new Vector3(_spurFigureX, _branchY, 0f));  // straight along the branch to the figure
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

        private List<Vector3> BranchPolyline() => new List<Vector3>
        {
            new Vector3(_forkX, _mainY, 0f),
            new Vector3(_forkX, _branchY, 0f),
            new Vector3(_branchEndX, _branchY, 0f),
        };

        private void BuildRails()
        {
            var main = InkLine.Create(transform, "MainRail", _inkMaterial, _railWidth, _railColor, _sortingOrder);
            InkLine.SetPoints(main, new List<Vector3>
            {
                new Vector3(_trolleyStartX - 0.8f, _mainY, 0f),
                new Vector3(_mainEndX, _mainY, 0f)
            });
            main.gameObject.AddComponent<LineBoil>().Capture();

            var branch = InkLine.Create(transform, "BranchRail", _inkMaterial, _railWidth, _railColor, _sortingOrder);
            InkLine.SetPoints(branch, BranchPolyline());
            branch.gameObject.AddComponent<LineBoil>().Capture();
        }

        private void BuildTies()
        {
            var container = new GameObject("Ties");
            container.transform.SetParent(transform, false);
            int idx = 0;

            // Main line: vertical ties along the whole run.
            for (float x = _trolleyStartX; x <= _mainEndX; x += _tieSpacing)
                AddTie(container.transform, idx++,
                    new Vector3(x, _mainY - _tieLength * 0.5f, 0f),
                    new Vector3(x, _mainY + _tieLength * 0.5f, 0f));

            // Branch (horizontal part): vertical ties, starting clear of the corner.
            for (float x = _forkX + _tieSpacing; x <= _branchEndX; x += _tieSpacing)
                AddTie(container.transform, idx++,
                    new Vector3(x, _branchY - _tieLength * 0.5f, 0f),
                    new Vector3(x, _branchY + _tieLength * 0.5f, 0f));

            // The vertical drop of the switch: a couple of horizontal ties.
            for (float y = _mainY - _tieSpacing; y > _branchY + 0.01f; y -= _tieSpacing)
                AddTie(container.transform, idx++,
                    new Vector3(_forkX - _tieLength * 0.5f, y, 0f),
                    new Vector3(_forkX + _tieLength * 0.5f, y, 0f));
        }

        private void AddTie(Transform parent, int idx, Vector3 a, Vector3 b)
        {
            var lr = InkLine.Create(parent, "Tie" + idx, _inkMaterial, _tieWidth, _tieColor, _sortingOrder - 1, 2);
            InkLine.SetPoints(lr, new List<Vector3> { a, b });
        }
    }
}
