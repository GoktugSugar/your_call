using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Dark Track: a plain group on the branch, and a main line that runs off into a hand-drawn
    /// darkness the imp swears is full of souls. The branch is real; the darkness hides no one. Whatever
    /// the player decides, once it resolves the shroud dissolves to reveal the empty main track, and the
    /// imp savours that they decided it about nobody. Reuses the Track, Trolley, Lever, Figure and the
    /// shared fold-and-fall; the one addition is the shroud and its after-choice reveal. One job.
    /// </summary>
    public sealed class DarkTrackConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Track _track;
        [SerializeField] private Trolley _trolley;
        [SerializeField] private Lever _lever;
        [SerializeField] private Figure _figurePrefab;

        [Header("Timing")]
        [SerializeField] private float _lightDuration = 1.7f;
        [SerializeField] private float _mediumDuration = 2.5f;
        [SerializeField] private float _heavyDuration = 3.6f;
        [SerializeField] private float _foldDuration = 0.6f;
        [SerializeField] private float _foldSettle = 0.4f;
        [Tooltip("How long the darkness takes to dissolve for the reveal.")]
        [SerializeField] private float _revealDuration = 0.9f;
        [Tooltip("Held beat after the reveal, before the imp savours it.")]
        [SerializeField] private float _revealHold = 0.5f;

        [Header("Darkness (a dense dark ink mass over the main line)")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private Color _darkColor = Palette.Ink;
        [SerializeField, Range(0.3f, 1f)] private float _darkOpacity = 0.92f;
        [Tooltip("Centre of the shroud, local to this station (over the main far section).")]
        [SerializeField] private Vector2 _shroudCenter = new Vector2(2.1f, 0.5f);
        [SerializeField] private Vector2 _shroudSize = new Vector2(5.8f, 1.9f);
        [SerializeField, Range(8, 40)] private int _shroudRows = 20;
        [SerializeField] private float _shroudStrokeWidth = 0.16f;
        [SerializeField] private int _shroudSortingOrder = 15;

        private readonly List<Figure> _spur = new List<Figure>();
        private readonly List<LineRenderer> _shroud = new List<LineRenderer>();
        private Transform _figures;
        private Transform _shroudRoot;
        private int _divertIndex = -1;
        private Dilemma _dilemma;
        private bool _leverHooked;

        public override void BuildScene(Dilemma dilemma)
        {
            _dilemma = dilemma;
            Teardown();

            _figures = new GameObject("Figures").transform;
            _figures.SetParent(transform, false);

            // Only the branch is real. The main track is empty; the darkness stands in for the "crowd".
            foreach (var pos in _track.SpurFigurePositions(dilemma.SpurFigureCount))
                _spur.Add(Instantiate(_figurePrefab, pos, Quaternion.identity, _figures));

            BuildShroud();

            _trolley.transform.position = _track.TrolleyStart;
            _lever.transform.position = _track.LeverPosition;

            _divertIndex = -1;
            var choices = dilemma.Choices;
            for (int i = 0; i < choices.Count; i++) if (choices[i].Diverts) _divertIndex = i;

            if (!_leverHooked) { _lever.Pulled += OnLeverPulled; _leverHooked = true; }
            _lever.ResetSwitch();
            _lever.Arm(false);
        }

        private void Teardown()
        {
            if (_figures != null) Destroy(_figures.gameObject);
            if (_shroudRoot != null) Destroy(_shroudRoot.gameObject);
            _figures = null; _shroudRoot = null;
            _spur.Clear(); _shroud.Clear();
        }

        private void OnLeverPulled() => RaiseChosen(_divertIndex >= 0 ? _divertIndex : 0);

        public override void ArmChoice(bool on) { if (_lever != null) _lever.Arm(on); }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            if (choice.Diverts && _lever != null) _lever.Throw();
        }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            // Main count is zero: the straight route runs on down the line into the dark and hits nothing;
            // the spur route kills the branch group.
            var path = _track.GetPath(choice.Route, 0);
            bool striking = outcome.Strikes("spur");

            Action<Vector3> onImpact = _ =>
            {
                if (striking) for (int i = 0; i < _spur.Count; i++) if (_spur[i] != null) _spur[i].Strike(_foldDuration);
            };
            _trolley.Impact += onImpact;
            yield return StartCoroutine(_trolley.Run(path, TravelFor(_dilemma.Weight)));
            _trolley.Impact -= onImpact;
            yield return new WaitForSeconds(_foldDuration + _foldSettle);

            // The reveal: the darkness lifts, and there was never anyone on the main line.
            yield return RevealEmptyTrack();
            yield return new WaitForSeconds(_revealHold);
        }

        private IEnumerator RevealEmptyTrack()
        {
            float t = 0f, d = Mathf.Max(_revealDuration, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = 1f - EaseUtil.OutCubic(t / d);
                for (int i = 0; i < _shroud.Count; i++)
                    if (_shroud[i] != null) InkLine.SetAlpha(_shroud[i], _darkColor, _darkOpacity * k);
                yield return null;
            }
            for (int i = 0; i < _shroud.Count; i++)
                if (_shroud[i] != null) InkLine.SetAlpha(_shroud[i], _darkColor, 0f);
        }

        // A dense dark ink mass: one continuous horizontal zigzag whose rows overlap into a solid blob.
        private void BuildShroud()
        {
            _shroudRoot = new GameObject("Darkness").transform;
            _shroudRoot.SetParent(transform, false);

            float halfW = _shroudSize.x * 0.5f, halfH = _shroudSize.y * 0.5f;
            // Follow the track's vertical lift so the darkness stays over the raised main line.
            float centerY = _shroudCenter.y + (_track != null ? _track.VerticalOffset : 0f);
            float rowStep = _shroudRows > 1 ? _shroudSize.y / (_shroudRows - 1) : 0f;
            var pts = new List<Vector3>(_shroudRows * 2);
            for (int r = 0; r < _shroudRows; r++)
            {
                float y = centerY + halfH - r * rowStep;
                bool ltr = (r % 2 == 0);
                float xa = _shroudCenter.x + (ltr ? -halfW : halfW);
                float xb = _shroudCenter.x + (ltr ? halfW : -halfW);
                pts.Add(new Vector3(xa, y, 0f));
                pts.Add(new Vector3(xb, y, 0f));
            }
            var lr = InkLine.Create(_shroudRoot, "Shroud", _inkMaterial, _shroudStrokeWidth, _darkColor, _shroudSortingOrder);
            InkLine.SetPoints(lr, pts);
            InkLine.SetAlpha(lr, _darkColor, _darkOpacity);
            _shroud.Add(lr);
        }

        private float TravelFor(DilemmaWeight weight)
        {
            switch (weight)
            {
                case DilemmaWeight.Light: return _lightDuration;
                case DilemmaWeight.Heavy: return _heavyDuration;
                default: return _mediumDuration;
            }
        }

        private void OnDestroy()
        {
            if (_lever != null && _leverHooked) _lever.Pulled -= OnLeverPulled;
        }
    }
}
