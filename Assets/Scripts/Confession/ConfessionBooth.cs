using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The fixed confession booth (Chapter 7): a clean hand drawn ink confessional the dead souls file up to,
    /// one at a time, to confess. It is the chapter's single set piece, drawn once and held for the whole
    /// docket (the conveyor of cases files in and out in front of it), so the chapter reads as a fixed location
    /// rather than a fresh scene per beat. On model in the doodle line style, built from ink strokes like the
    /// Track and the buttons: an outer frame, a doorway the confessor stands in, a latticed grille screen (the
    /// confessional cue), and a peaked roof. It inks in once on the first case and then just sits there, alive
    /// on the subtle boil. It registers a keep out so the roaming imp never sits on it. One job: draw the booth.
    /// </summary>
    public sealed class ConfessionBooth : MonoBehaviour
    {
        [Header("Ink")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _color = Palette.Ink;
        [SerializeField] private float _lineWidth = 0.05f;
        [SerializeField] private float _grilleWidth = 0.03f;
        [SerializeField] private int _sortingOrder = 6;   // behind the confessors (Figure default 10)
        [SerializeField] private bool _boil = true;

        [Header("Proportions (booth centred on this transform)")]
        [SerializeField] private float _floorY = -1.65f;
        [SerializeField] private float _outerHalf = 1.8f;
        [SerializeField] private float _wallTop = 2.0f;
        [SerializeField] private float _doorwayHalf = 1.0f;
        [SerializeField] private float _headerY = 1.3f;
        [SerializeField] private float _roofPeakY = 2.78f;
        [SerializeField] private float _roofHalf = 2.02f;

        [Header("Grille (the confessional screen)")]
        [SerializeField] private float _grilleHalf = 0.9f;
        [SerializeField] private float _grilleBottom = 1.46f;
        [SerializeField] private float _grilleTop = 1.94f;
        [SerializeField] private float _grilleStep = 0.26f;

        [Header("Keep out")]
        [SerializeField] private float _keepoutPadding = 0.4f;

        private readonly List<LineRenderer> _strokes = new List<LineRenderer>();
        private readonly List<LineBoil> _boils = new List<LineBoil>();
        private bool _built;
        private bool _shown;

        public bool IsShown => _shown;

        private void Awake() { Build(); }

        public void Build()
        {
            if (_built) return;

            // Front step and floor.
            Stroke("Step", new List<Vector3> {
                new Vector3(-_outerHalf - 0.2f, _floorY - 0.2f, 0f),
                new Vector3(_outerHalf + 0.2f, _floorY - 0.2f, 0f) }, _lineWidth);
            Stroke("Floor", new List<Vector3> {
                new Vector3(-_outerHalf - 0.2f, _floorY - 0.2f, 0f),
                new Vector3(-_outerHalf, _floorY, 0f),
                new Vector3(_outerHalf, _floorY, 0f),
                new Vector3(_outerHalf + 0.2f, _floorY - 0.2f, 0f) }, _lineWidth);

            // Outer frame: the two side walls and the lintel across the top.
            Stroke("WallL", new List<Vector3> { new Vector3(-_outerHalf, _floorY, 0f), new Vector3(-_outerHalf, _wallTop, 0f) }, _lineWidth);
            Stroke("WallR", new List<Vector3> { new Vector3(_outerHalf, _floorY, 0f), new Vector3(_outerHalf, _wallTop, 0f) }, _lineWidth);
            Stroke("Lintel", new List<Vector3> { new Vector3(-_outerHalf, _wallTop, 0f), new Vector3(_outerHalf, _wallTop, 0f) }, _lineWidth);

            // The doorway the confessor stands in: inner posts and a header.
            Stroke("PostL", new List<Vector3> { new Vector3(-_doorwayHalf, _floorY, 0f), new Vector3(-_doorwayHalf, _headerY, 0f) }, _lineWidth);
            Stroke("PostR", new List<Vector3> { new Vector3(_doorwayHalf, _floorY, 0f), new Vector3(_doorwayHalf, _headerY, 0f) }, _lineWidth);
            Stroke("Header", new List<Vector3> { new Vector3(-_doorwayHalf, _headerY, 0f), new Vector3(_doorwayHalf, _headerY, 0f) }, _lineWidth);

            // The peaked roof.
            Stroke("Roof", new List<Vector3> {
                new Vector3(-_roofHalf, _wallTop, 0f),
                new Vector3(0f, _roofPeakY, 0f),
                new Vector3(_roofHalf, _wallTop, 0f) }, _lineWidth);

            // The latticed grille screen in the tympanum, above the doorway header. The confessional cue.
            BuildGrille();

            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _color, 0f);   // start hidden; Reveal inks it in

            var keep = gameObject.AddComponent<ScreenKeepout>();
            keep.UseRendererBounds(_keepoutPadding);

            _built = true;
        }

        private void BuildGrille()
        {
            for (float x = -_grilleHalf; x <= _grilleHalf + 0.001f; x += _grilleStep)
                Stroke("GrilleV", new List<Vector3> { new Vector3(x, _grilleBottom, 0f), new Vector3(x, _grilleTop, 0f) }, _grilleWidth);
            for (float y = _grilleBottom; y <= _grilleTop + 0.001f; y += _grilleStep)
                Stroke("GrilleH", new List<Vector3> { new Vector3(-_grilleHalf, y, 0f), new Vector3(_grilleHalf, y, 0f) }, _grilleWidth);
        }

        private LineRenderer Stroke(string name, List<Vector3> pts, float width)
        {
            var lr = InkLine.Create(transform, name, _inkMaterial, width, _color, _sortingOrder);
            InkLine.SetPoints(lr, pts);
            if (_boil && name != "GrilleV" && name != "GrilleH")   // keep the fine lattice steady, boil the frame
            {
                var b = lr.gameObject.AddComponent<LineBoil>();
                b.Capture();
                _boils.Add(b);
            }
            _strokes.Add(lr);
            return lr;
        }

        /// <summary>Ink the booth in once (idempotent). Later calls are no ops, so the first case reveals it and
        /// every case after just finds it already standing.</summary>
        public IEnumerator EnsureShown(float dur)
        {
            if (_shown) yield break;
            _shown = true;
            if (!_built) Build();
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                for (int i = 0; i < _strokes.Count; i++)
                    if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _color, k);
                yield return null;
            }
            for (int i = 0; i < _strokes.Count; i++)
                if (_strokes[i] != null) InkLine.SetAlpha(_strokes[i], _color, 1f);
        }
    }
}
