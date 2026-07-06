using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The binary trolley apparatus: figures on the track, the diegetic lever, and the
    /// trolley run with an anticipation and a settle. The struck party folds on impact.
    /// DilemmaStage knows none of this; it only sees a ConsequencePresenter.
    /// </summary>
    public sealed class TrolleyConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Track _track;
        [SerializeField] private Trolley _trolley;
        [SerializeField] private Lever _lever;
        [SerializeField] private Figure _figurePrefab;
        [SerializeField] private Material _inkMaterial;

        [Header("Timing")]
        [SerializeField] private float _lightDuration = 1.7f;
        [SerializeField] private float _mediumDuration = 2.5f;
        [SerializeField] private float _heavyDuration = 3.6f;
        [SerializeField] private float _foldDuration = 0.6f;
        [SerializeField] private float _foldSettle = 0.4f;

        private readonly List<Figure> _main = new List<Figure>();
        private Figure _spur;
        private int _divertIndex = -1;
        private Dilemma _dilemma;

        public override void BuildScene(Dilemma dilemma)
        {
            _dilemma = dilemma;
            var container = new GameObject("Figures").transform;
            container.SetParent(transform, false);

            foreach (var pos in _track.MainFigurePositions())
                _main.Add(Instantiate(_figurePrefab, pos, Quaternion.identity, container));
            _spur = Instantiate(_figurePrefab, _track.SpurFigurePosition, Quaternion.identity, container);

            _trolley.transform.position = _track.TrolleyStart;
            _lever.transform.position = _track.LeverPosition;

            var choices = dilemma.Choices;
            for (int i = 0; i < choices.Count; i++) if (choices[i].Diverts) _divertIndex = i;

            _lever.Pulled += OnLeverPulled;
            _lever.Arm(false);
        }

        private void OnLeverPulled() => RaiseChosen(_divertIndex >= 0 ? _divertIndex : 0);

        public override void ArmChoice(bool on) { if (_lever != null) _lever.Arm(on); }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            if (choice.Diverts && _lever != null) _lever.Throw();
        }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            var path = _track.GetPath(choice.Route);
            var struck = FiguresFor(outcome);

            Action<Vector3> onImpact = pos =>
            {
                SpawnPuff(pos);
                for (int i = 0; i < struck.Count; i++) struck[i].Strike(_foldDuration);
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
                if (party == "spur") { if (_spur != null) list.Add(_spur); }
                else if (party == "main") list.AddRange(_main);
            }
            return list;
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

        private void SpawnPuff(Vector3 pos)
        {
            var go = new GameObject("PuffCue");
            var puff = go.AddComponent<PuffCue>();
            puff.Configure(_inkMaterial);
            puff.Play(pos);
        }

        private void OnDestroy()
        {
            if (_lever != null) _lever.Pulled -= OnLeverPulled;
        }
    }
}
