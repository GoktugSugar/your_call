using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// The composition root for one dilemma. An explicit phase state machine
    /// (Present, Choose, Consequence, Stats, End) that wires input through C# events,
    /// drives the consequence, reveals the stats, and records the profile silently. It
    /// coordinates the small components; it does not draw anything itself.
    /// </summary>
    public class DilemmaStage : MonoBehaviour
    {
        [Header("Content")]
        [SerializeField] private Dilemma _dilemma;

        [Header("References")]
        [SerializeField] private Camera _camera;
        [SerializeField] private Track _track;
        [SerializeField] private Trolley _trolley;
        [SerializeField] private Lever _lever;
        [SerializeField] private NarratorView _narrator;
        [SerializeField] private ChoiceButtons _choices;
        [SerializeField] private StatsView _stats;
        [SerializeField] private Figure _figurePrefab;
        [SerializeField] private Profile _profile;
        [SerializeField] private Material _inkMaterial;

        [Header("Timing (seconds)")]
        [SerializeField] private float _presentHold = 0.7f;
        [SerializeField] private float _postChoiceBeat = 0.45f;
        [SerializeField] private float _lightDuration = 1.7f;
        [SerializeField] private float _mediumDuration = 2.5f;
        [SerializeField] private float _heavyDuration = 3.6f;
        [SerializeField] private float _foldDuration = 0.6f;
        [SerializeField] private float _preStatsBeat = 0.9f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _endInputDelay = 0.5f;

        public DilemmaPhase Phase { get; private set; }

        private readonly List<Figure> _mainFigures = new List<Figure>();
        private Figure _spurFigure;
        private int _chosenIndex = -1;
        private int _divertIndex = -1;

        private void Start()
        {
            if (!Setup()) return;
            StartCoroutine(RunLoop());
        }

        private bool Setup()
        {
            if (_dilemma == null) { Debug.LogError("[DilemmaStage] No Dilemma assigned."); return false; }
            if (_camera == null) _camera = Camera.main;
            _profile = _profile != null ? _profile : Profile.Ensure();

            var container = new GameObject("Figures").transform;
            container.SetParent(transform, false);

            foreach (var pos in _track.MainFigurePositions())
                _mainFigures.Add(Instantiate(_figurePrefab, pos, Quaternion.identity, container));
            _spurFigure = Instantiate(_figurePrefab, _track.SpurFigurePosition, Quaternion.identity, container);

            _trolley.transform.position = _track.TrolleyStart;
            _lever.transform.position = _track.LeverPosition;

            var choices = _dilemma.Choices;
            for (int i = 0; i < choices.Count; i++) if (choices[i].Diverts) _divertIndex = i;

            _lever.Pulled += OnLeverPulled;
            _choices.Chosen += OnChoiceChosen;
            _lever.Arm(false);
            return true;
        }

        private void OnDestroy()
        {
            if (_lever != null) _lever.Pulled -= OnLeverPulled;
            if (_choices != null) _choices.Chosen -= OnChoiceChosen;
        }

        // ---------- Input handlers ----------

        private void OnLeverPulled() => Commit(_divertIndex >= 0 ? _divertIndex : 0);
        private void OnChoiceChosen(int index) => Commit(index);

        private void Commit(int index)
        {
            if (_chosenIndex >= 0) return;
            _chosenIndex = index;
            _lever.Arm(false);
            _choices.Dismiss();
        }

        // ---------- The loop ----------

        private IEnumerator RunLoop()
        {
            // Present
            Phase = DilemmaPhase.Present;
            _narrator.Show(_dilemma.NarratorPrompt);
            while (_narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_presentHold);

            // Choose
            Phase = DilemmaPhase.Choose;
            _lever.Arm(true);
            var choices = _dilemma.Choices;
            string l0 = choices.Count > 0 ? choices[0].Label : string.Empty;
            string l1 = choices.Count > 1 ? choices[1].Label : string.Empty;
            _choices.Present(l0, l1);
            while (_chosenIndex < 0) yield return null;

            var choice = choices[_chosenIndex];
            _profile.Record(choice.ProfileImpact); // silent; never drawn
            if (choice.Diverts) _lever.Throw();
            yield return new WaitForSeconds(_postChoiceBeat);

            // Consequence
            Phase = DilemmaPhase.Consequence;
            _narrator.Clear();
            var path = _track.GetPath(choice.Route);
            var struck = StruckFor(choice);
            Action<Vector3> onImpact = pos =>
            {
                SpawnPuff(pos);
                for (int i = 0; i < struck.Count; i++) struck[i].Strike(_foldDuration);
            };
            _trolley.Impact += onImpact;
            yield return StartCoroutine(_trolley.Run(path, TravelFor(_dilemma.Weight)));
            _trolley.Impact -= onImpact;
            yield return new WaitForSeconds(_foldDuration + _preStatsBeat);

            // Stats + the narrator's reaction over the dimmed world
            Phase = DilemmaPhase.Stats;
            yield return StartCoroutine(_stats.Reveal(_dilemma, _chosenIndex, _statsFade));
            _narrator.Show(choice.NarratorReact);

            // End: replay on any click or key
            Phase = DilemmaPhase.End;
            yield return new WaitForSeconds(_endInputDelay);
            while (!PointerInput.AdvancePressed) yield return null;
            SceneManager.LoadScene(gameObject.scene.name);
        }

        // ---------- Helpers ----------

        private List<Figure> StruckFor(DilemmaChoice choice)
        {
            bool spur = !string.IsNullOrEmpty(choice.Route) && choice.Route.ToLowerInvariant().Contains("spur");
            if (!spur) return _mainFigures;
            var list = new List<Figure>();
            if (_spurFigure != null) list.Add(_spurFigure);
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
    }
}
