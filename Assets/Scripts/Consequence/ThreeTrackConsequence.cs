using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The Full Track: no empty rail, three tracks, the trolley already rolling. The player picks one of
    /// three (click a track's option, or press 1/2/3); the trolley runs down it and folds whoever stands
    /// there. The first multiple-choice apparatus, built in the ink style from the shared Trolley, Figure
    /// and fold-and-fall. It owns its three diegetic options (so the loop needs no text fallback) and
    /// raises <see cref="ConsequencePresenter.Chosen"/> on a pick.
    ///
    /// Routes map to tracks: "up" = top, "straight" = middle, "down" = bottom; struck parties are
    /// "top" / "mid" / "bottom". Each track's figure prefab, count and scale are set per station, so the
    /// top can be a child, the middle a pregnant woman, the bottom three strangers.
    /// </summary>
    public sealed class ThreeTrackConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Trolley _trolley;

        [Header("Tracks: top / middle / bottom")]
        [SerializeField] private Figure _topPrefab;
        [SerializeField] private int _topCount = 2;
        [SerializeField] private float _topScale = 0.62f;
        [SerializeField] private Figure _midPrefab;
        [SerializeField] private int _midCount = 1;
        [SerializeField] private float _midScale = 1f;
        [SerializeField] private Figure _bottomPrefab;
        [SerializeField] private int _bottomCount = 3;
        [SerializeField] private float _bottomScale = 1f;

        [Header("Rails (ink)")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _railColor = Palette.Ink;
        [SerializeField] private Color _tieColor = Palette.Muted;
        [SerializeField] private float _railWidth = 0.05f;
        [SerializeField] private float _tieWidth = 0.035f;
        [SerializeField] private int _sortingOrder = 0;

        [Header("Geometry (local)")]
        [SerializeField] private float _entryX = -4.6f;
        [SerializeField] private float _forkX = -2.2f;
        [SerializeField] private float _rightEndX = 4.7f;
        [SerializeField] private float _topY = 2.0f;
        [SerializeField] private float _midY = 0f;
        [SerializeField] private float _bottomY = -2.0f;
        [Tooltip("Lifts the three tracks, their figures and the trolley up the screen (not the option row), matching the binary trolley's lift.")]
        [SerializeField] private float _verticalOffset = 0.8f;
        [SerializeField] private float _groupCenterX = 2.3f;
        [SerializeField] private float _figureSpacing = 0.56f;
        [SerializeField] private float _impactOverlap = 0.25f;
        [SerializeField] private float _tieSpacing = 0.7f;
        [SerializeField] private float _tieLength = 0.34f;

        [Header("Pick options (a row above the dialogue box, clear of the tracks; click or 1/2/3)")]
        [SerializeField] private TMP_FontAsset _font;
        [Tooltip("Row height for the option labels, matching the binary choice buttons (clear of the box).")]
        [SerializeField] private float _optionsRowY = -2.5f;
        [Tooltip("Total width the option labels spread across, centred on x = 0.")]
        [SerializeField] private float _optionsSpan = 6.6f;
        [SerializeField] private float _pickFontSize = 3.3f;
        [SerializeField] private Color _pickColor = Palette.Ink;
        [SerializeField, Range(0f, 1f)] private float _pickRestAlpha = 0.7f;
        [SerializeField] private float _hoverScale = 1.07f;
        [SerializeField] private int _pickSorting = 20;
        [SerializeField] private Vector2 _pickPadding = new Vector2(0.5f, 0.35f);

        [Header("Timing")]
        [SerializeField] private float _travelDuration = 3.4f;
        [SerializeField] private float _foldDuration = 0.6f;
        [SerializeField] private float _foldSettle = 0.4f;

        private readonly Dictionary<string, List<Figure>> _groups = new Dictionary<string, List<Figure>>();
        private readonly List<TextMeshPro> _labels = new List<TextMeshPro>();
        private readonly List<BoxCollider2D> _cols = new List<BoxCollider2D>();
        private readonly List<float> _hoverT = new List<float>();
        private readonly List<string> _routes = new List<string>();
        private Transform _figures;
        private Transform _rails;
        private Transform _options;
        private Dilemma _dilemma;
        private bool _built;
        private bool _armed;
        private Camera _camera;

        public override void BuildScene(Dilemma dilemma)
        {
            _dilemma = dilemma;
            Teardown();

            BuildRails();

            _figures = new GameObject("Figures").transform;
            _figures.SetParent(transform, false);
            _groups["top"] = SpawnGroup(_topPrefab, _topCount, _topY + _verticalOffset, _topScale);
            _groups["mid"] = SpawnGroup(_midPrefab, _midCount, _midY + _verticalOffset, _midScale);
            _groups["bottom"] = SpawnGroup(_bottomPrefab, _bottomCount, _bottomY + _verticalOffset, _bottomScale);

            BuildOptions(dilemma);

            _trolley.transform.position = transform.TransformPoint(new Vector3(_entryX, _midY + _verticalOffset, 0f));
        }

        private void Teardown()
        {
            if (_figures != null) Destroy(_figures.gameObject);
            if (_rails != null) Destroy(_rails.gameObject);
            if (_options != null) Destroy(_options.gameObject);
            _figures = _rails = _options = null;
            _groups.Clear(); _labels.Clear(); _cols.Clear(); _hoverT.Clear(); _routes.Clear();
        }

        // ---------- Options (the three diegetic picks) ----------

        private void BuildOptions(Dilemma dilemma)
        {
            _options = new GameObject("Options").transform;
            _options.SetParent(transform, false);
            var choices = dilemma.Choices;
            int n = choices.Count;
            for (int i = 0; i < n; i++)
            {
                string route = choices[i].Route;
                // A row above the dialogue box, clear of the rails, matching the binary choice buttons.
                float x = n <= 1 ? 0f : -_optionsSpan * 0.5f + _optionsSpan * i / (n - 1);
                var t = InkText.Create(_options, "Pick" + i, _pickFontSize, _pickColor, TextAlignmentOptions.Center, _pickSorting);
                if (_font != null) t.font = _font;
                t.rectTransform.sizeDelta = new Vector2(4.5f, 1.1f);
                t.transform.localPosition = new Vector3(x, _optionsRowY, 0f);
                t.text = Localization.Localize(choices[i].Label);
                InkText.SetAlpha(t, 0f);
                var col = t.gameObject.AddComponent<BoxCollider2D>();
                col.isTrigger = true;
                _labels.Add(t);
                _cols.Add(col);
                _hoverT.Add(0f);
                _routes.Add(route);
            }
        }

        public override void ArmChoice(bool on)
        {
            _armed = on;
            for (int i = 0; i < _labels.Count; i++)
            {
                if (_labels[i] == null) continue;
                if (on) SizeCollider(i);
                InkText.SetAlpha(_labels[i], on ? _pickRestAlpha : 0f);
            }
        }

        private void SizeCollider(int i)
        {
            _labels[i].ForceMeshUpdate();
            Bounds b = _labels[i].textBounds;
            _cols[i].offset = new Vector2(b.center.x, b.center.y);
            _cols[i].size = new Vector2(Mathf.Max(b.size.x, 0.5f) + _pickPadding.x, Mathf.Max(b.size.y, 0.5f) + _pickPadding.y);
        }

        private void Update()
        {
            if (!_armed) return;
            if (_camera == null) _camera = Camera.main;
            if (_camera == null) return;

            Vector3 wp = PointerInput.WorldPosition(_camera, transform.position.z);
            for (int i = 0; i < _labels.Count; i++)
            {
                bool hovered = _cols[i] != null && _cols[i].OverlapPoint(wp);
                _hoverT[i] = Mathf.MoveTowards(_hoverT[i], hovered ? 1f : 0f, Time.deltaTime / 0.1f);
                Color c = _pickColor;                                  // ink, like the binary choice buttons (no amber; amber stays for the scene accents)
                c.a = Mathf.Lerp(_pickRestAlpha, 1f, _hoverT[i]);
                _labels[i].color = c;
                float s = Mathf.Lerp(1f, _hoverScale, _hoverT[i]);
                _labels[i].transform.localScale = new Vector3(s, s, 1f);
                if (hovered && PointerInput.Clicked) { Choose(i); return; }
            }
            ReadKeyboard();
        }

        private void ReadKeyboard()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null || PointerInput.Suppressed) return;
            if (kb.digit1Key.wasPressedThisFrame && _labels.Count > 0) { Choose(0); return; }
            if (kb.digit2Key.wasPressedThisFrame && _labels.Count > 1) { Choose(1); return; }
            if (kb.digit3Key.wasPressedThisFrame && _labels.Count > 2) { Choose(2); return; }
#endif
        }

        private void Choose(int index)
        {
            if (!_armed) return;
            _armed = false;
            for (int i = 0; i < _labels.Count; i++)
                if (_labels[i] != null) InkText.SetAlpha(_labels[i], i == index ? 1f : 0f);
            RaiseChosen(index);
        }

        // ---------- Consequence ----------

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            var path = PathFor(choice.Route);
            var struck = new List<Figure>();
            foreach (var party in outcome.StruckParties)
                if (_groups.ContainsKey(party)) struck.AddRange(_groups[party]);

            Action<Vector3> onImpact = _ =>
            {
                for (int i = 0; i < struck.Count; i++) if (struck[i] != null) struck[i].Strike(_foldDuration);
            };
            _trolley.Impact += onImpact;
            yield return StartCoroutine(_trolley.Run(path, _travelDuration));
            _trolley.Impact -= onImpact;
            yield return new WaitForSeconds(_foldDuration + _foldSettle);
        }

        private List<Vector3> PathFor(string route)
        {
            float y = TrackY(route);
            float midY = _midY + _verticalOffset;
            int count = CountFor(route);
            float total = (count - 1) * _figureSpacing;
            float impactX = _groupCenterX - total * 0.5f + _impactOverlap;
            var local = new List<Vector3> { new Vector3(_entryX, midY, 0f) };
            if (!Mathf.Approximately(y, midY))
            {
                local.Add(new Vector3(_forkX, midY, 0f));
                local.Add(new Vector3(_forkX, y, 0f));
            }
            local.Add(new Vector3(impactX, y, 0f));
            var world = new List<Vector3>(local.Count);
            for (int i = 0; i < local.Count; i++) world.Add(transform.TransformPoint(local[i]));
            return world;
        }

        private float TrackY(string route)
        {
            float y = route == "up" ? _topY : route == "down" ? _bottomY : _midY;
            return y + _verticalOffset;
        }

        private int CountFor(string route)
        {
            if (route == "up") return Mathf.Max(1, _topCount);
            if (route == "down") return Mathf.Max(1, _bottomCount);
            return Mathf.Max(1, _midCount);
        }

        // ---------- Build helpers ----------

        private List<Figure> SpawnGroup(Figure prefab, int count, float y, float scale)
        {
            var list = new List<Figure>(Mathf.Max(0, count));
            if (prefab == null || count <= 0) return list;
            float total = (count - 1) * _figureSpacing;
            float startX = _groupCenterX - total * 0.5f;
            for (int i = 0; i < count; i++)
            {
                Vector3 world = transform.TransformPoint(new Vector3(startX + i * _figureSpacing, y, 0f));
                var wrap = new GameObject("Fig").transform;
                wrap.SetParent(_figures, false);
                wrap.position = world;
                wrap.localScale = new Vector3(scale, scale, 1f);
                list.Add(Instantiate(prefab, wrap.position, Quaternion.identity, wrap));
            }
            return list;
        }

        private void BuildRails()
        {
            _rails = new GameObject("Rails").transform;
            _rails.SetParent(transform, false);

            // Entry line into the fork, then each track runs on to the right.
            float midY = _midY + _verticalOffset;
            Rail("Entry", new Vector3(_entryX - 0.8f, midY, 0f), new Vector3(_forkX, midY, 0f));
            Branch("Top", _topY + _verticalOffset);
            Branch("Mid", midY);
            Branch("Bottom", _bottomY + _verticalOffset);
        }

        private void Branch(string name, float y)
        {
            // The switch drops (or rises) from the fork to this track, then runs straight to the end.
            float midY = _midY + _verticalOffset;
            if (!Mathf.Approximately(y, midY))
                Rail(name + "Step", new Vector3(_forkX, midY, 0f), new Vector3(_forkX, y, 0f));
            Rail(name + "Rail", new Vector3(_forkX, y, 0f), new Vector3(_rightEndX, y, 0f));
            for (float x = _forkX + _tieSpacing; x <= _rightEndX; x += _tieSpacing)
                Tie(new Vector3(x, y - _tieLength * 0.5f, 0f), new Vector3(x, y + _tieLength * 0.5f, 0f));
        }

        private void Rail(string name, Vector3 a, Vector3 b)
        {
            var lr = InkLine.Create(_rails, name, _inkMaterial, _railWidth, _railColor, _sortingOrder);
            InkLine.SetPoints(lr, new List<Vector3> { a, b });
            lr.gameObject.AddComponent<LineBoil>().Capture();
        }

        private void Tie(Vector3 a, Vector3 b)
        {
            var lr = InkLine.Create(_rails, "Tie", _inkMaterial, _tieWidth, _tieColor, _sortingOrder - 1, 2);
            InkLine.SetPoints(lr, new List<Vector3> { a, b });
        }
    }
}
