using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The binary trolley apparatus: figures on the track, the diegetic lever, and the trolley run
    /// with an anticipation and a settle. The struck party folds on impact. DilemmaStage knows none
    /// of this; it only sees a ConsequencePresenter.
    ///
    /// One station serves the whole chapter: the per-dilemma data drives how many figures stand on
    /// each track, whether they are branded, an optional different figure prefab per track (the baby),
    /// and an optional floating plea over the lone branch soul (the Begging trolley). BuildScene tears
    /// down the previous beat so the same station can run many dilemmas in a row.
    /// </summary>
    public sealed class TrolleyConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Track _track;
        [SerializeField] private Trolley _trolley;
        [SerializeField] private Lever _lever;
        [SerializeField] private Figure _figurePrefab;
        [Tooltip("Optional: floats a plea over the lone branch figure when the dilemma carries one (the Begging trolley).")]
        [SerializeField] private FloatingFigureText _plea;
        [Tooltip("Optional: the z-mark prefab instanced onto sleeping figures (The Sleeping).")]
        [SerializeField] private SleepZ _sleepZPrefab;
        [Tooltip("Where the z marks sit relative to a sleeping figure (top-right of the head).")]
        [SerializeField] private Vector2 _sleepZOffset = new Vector2(0.14f, 0.9f);
        [Tooltip("Optional: the heart prefab instanced over the player's partner (Someone You Loved).")]
        [SerializeField] private HeartFloat _heartPrefab;
        [Tooltip("Where the heart sits relative to the partner figure (above the head).")]
        [SerializeField] private Vector2 _heartOffset = new Vector2(0f, 1.15f);

        [Header("Timing")]
        [SerializeField] private float _lightDuration = 1.7f;
        [SerializeField] private float _mediumDuration = 2.5f;
        [SerializeField] private float _heavyDuration = 3.6f;
        [SerializeField] private float _foldDuration = 0.6f;
        [SerializeField] private float _foldSettle = 0.4f;

        private readonly List<Figure> _main = new List<Figure>();
        private readonly List<Figure> _spur = new List<Figure>();
        private Transform _figures;
        private int _divertIndex = -1;
        private Dilemma _dilemma;
        private bool _leverHooked;

        public override void BuildScene(Dilemma dilemma)
        {
            _dilemma = dilemma;
            Teardown();

            _figures = new GameObject("Figures").transform;
            _figures.SetParent(transform, false);

            var mainPrefab = dilemma.MainFigurePrefab != null ? dilemma.MainFigurePrefab : _figurePrefab;
            var spurPrefab = dilemma.SpurFigurePrefab != null ? dilemma.SpurFigurePrefab : _figurePrefab;

            var mainPositions = _track.MainFigurePositions(dilemma.MainFigureCount);
            for (int i = 0; i < mainPositions.Count; i++)
            {
                var fig = Instantiate(mainPrefab, mainPositions[i], Quaternion.identity, _figures);
                if (dilemma.MainPartner) { fig.Brand(Palette.InkPink); AttachHeart(fig); }   // the loved one: pink and a heart
                // Red marks the guilty: all of them (Marked Ones), or specific ones (the murderer in The Passenger).
                else if (dilemma.FiguresBranded || In(dilemma.BrandedMainIndices, i)) fig.Brand();
                if (dilemma.MainAsleep) AttachSleepZ(fig);
                _main.Add(fig);
            }
            var spurPositions = _track.SpurFigurePositions(dilemma.SpurFigureCount);
            for (int i = 0; i < spurPositions.Count; i++)
            {
                var fig = Instantiate(spurPrefab, spurPositions[i], Quaternion.identity, _figures);
                if (dilemma.SpurPartner) { fig.Brand(Palette.InkPink); AttachHeart(fig); }   // the loved one on the branch (Someone You Loved)
                else if (In(dilemma.BrandedSpurIndices, i)) fig.Brand();   // the cruel man in The Reformed and the Cruel
                if (dilemma.SpurAsleep) AttachSleepZ(fig);
                _spur.Add(fig);
            }

            _trolley.transform.position = _track.TrolleyStart;
            _lever.transform.position = _track.LeverPosition;

            _divertIndex = -1;
            var choices = dilemma.Choices;
            for (int i = 0; i < choices.Count; i++) if (choices[i].Diverts) _divertIndex = i;

            if (!_leverHooked) { _lever.Pulled += OnLeverPulled; _leverHooked = true; }
            _lever.ResetSwitch();
            _lever.Arm(false);

            // The lone soul's plea, floated in ink over them (the Begging trolley); none otherwise.
            if (_plea != null)
            {
                if (!string.IsNullOrEmpty(dilemma.SpurPlea) && _spur.Count > 0)
                    _plea.Show(dilemma.SpurPlea, _track.SpurFigurePositions(dilemma.SpurFigureCount)[0]);
                else
                    _plea.Hide();
            }
        }

        private void Teardown()
        {
            if (_figures != null) Destroy(_figures.gameObject);
            _figures = null;
            _main.Clear();
            _spur.Clear();
            if (_plea != null) _plea.Hide();
        }

        private void OnLeverPulled() => RaiseChosen(_divertIndex >= 0 ? _divertIndex : 0);

        public override void ArmChoice(bool on) { if (_lever != null) _lever.Arm(on); }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            if (choice.Diverts && _lever != null) _lever.Throw();
        }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            if (_plea != null) _plea.Hide();

            var path = _track.GetPath(choice.Route, _dilemma.MainFigureCount);
            var struck = FiguresFor(outcome);

            // The death is only the fold-and-fall: no strike lines or impact puff over the figure.
            Action<Vector3> onImpact = _ =>
            {
                for (int i = 0; i < struck.Count; i++) if (struck[i] != null) struck[i].Strike(_foldDuration);
            };
            _trolley.Impact += onImpact;
            yield return StartCoroutine(_trolley.Run(path, TravelFor(_dilemma.Weight)));
            _trolley.Impact -= onImpact;
            yield return new WaitForSeconds(_foldDuration + _foldSettle);
        }

        private List<Figure> FiguresFor(DilemmaOutcome outcome)
        {
            var list = new List<Figure>();
            foreach (var party in outcome.StruckParties)
            {
                if (party == "spur") list.AddRange(_spur);
                else if (party == "main") list.AddRange(_main);
            }
            return list;
        }

        private void AttachSleepZ(Figure fig)
        {
            if (_sleepZPrefab == null) return;
            var z = Instantiate(_sleepZPrefab, fig.transform);
            z.transform.localPosition = new Vector3(_sleepZOffset.x, _sleepZOffset.y, 0f);
        }

        private void AttachHeart(Figure fig)
        {
            if (_heartPrefab == null) return;
            var h = Instantiate(_heartPrefab, fig.transform);
            h.transform.localPosition = new Vector3(_heartOffset.x, _heartOffset.y, 0f);
        }

        private static bool In(IReadOnlyList<int> indices, int i)
        {
            if (indices == null) return false;
            for (int k = 0; k < indices.Count; k++) if (indices[k] == i) return true;
            return false;
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
