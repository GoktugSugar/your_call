using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// The composition root for one dilemma. An explicit phase state machine
    /// (Present, Choose, Consequence, Stats, End) that stays generic across verbs: it asks
    /// a <see cref="VerbResolver"/> for the outcome and a <see cref="ConsequencePresenter"/>
    /// to play it, wires input through C# events, reveals the stats from the resolver's
    /// report, and records the profile silently. No verb-specific branches.
    /// </summary>
    public class DilemmaStage : MonoBehaviour
    {
        [Header("Content")]
        [SerializeField] private Dilemma _dilemma;

        [Header("References")]
        [SerializeField] private Camera _camera;
        [SerializeField] private ConsequencePresenter _presenter;
        [SerializeField] private NarratorView _narrator;
        [SerializeField] private StatsView _stats;
        [SerializeField] private Profile _profile;

        [Header("Text fallback")]
        [SerializeField] private bool _showTextFallback = true;
        [SerializeField] private ChoiceButtons _choices;

        [Header("Timing (seconds)")]
        [SerializeField] private float _presentHold = 0.7f;
        [SerializeField] private float _postChoiceBeat = 0.45f;
        [SerializeField] private float _preStatsBeat = 0.9f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _endInputDelay = 0.5f;

        public DilemmaPhase Phase { get; private set; }

        private VerbResolver _resolver;
        private int _chosenIndex = -1;

        private void Start()
        {
            if (!Setup()) return;
            StartCoroutine(RunLoop());
        }

        private bool Setup()
        {
            if (_dilemma == null) { Debug.LogError("[DilemmaStage] No Dilemma assigned."); return false; }
            if (_presenter == null) { Debug.LogError("[DilemmaStage] No ConsequencePresenter assigned."); return false; }
            if (_camera == null) _camera = Camera.main;
            _profile = _profile != null ? _profile : Profile.Ensure();
            _resolver = VerbResolvers.For(_dilemma.Verb);

            _presenter.BuildScene(_dilemma);
            _presenter.Chosen += OnChosen;
            _presenter.ArmChoice(false);

            if (_showTextFallback && _choices != null) _choices.Chosen += OnChosen;
            return true;
        }

        private void OnDestroy()
        {
            if (_presenter != null) _presenter.Chosen -= OnChosen;
            if (_choices != null) _choices.Chosen -= OnChosen;
        }

        private void OnChosen(int index)
        {
            if (_chosenIndex >= 0) return;
            _chosenIndex = index;
            _presenter.ArmChoice(false);
            if (_showTextFallback && _choices != null) _choices.Dismiss();
        }

        private IEnumerator RunLoop()
        {
            // Present
            Phase = DilemmaPhase.Present;
            _narrator.Show(_dilemma.NarratorPrompt);
            while (_narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_presentHold);

            // Choose
            Phase = DilemmaPhase.Choose;
            _presenter.ArmChoice(true);
            var choices = _dilemma.Choices;
            if (_showTextFallback && _choices != null)
            {
                string l0 = choices.Count > 0 ? choices[0].Label : string.Empty;
                string l1 = choices.Count > 1 ? choices[1].Label : string.Empty;
                _choices.Present(l0, l1);
            }
            while (_chosenIndex < 0) yield return null;

            var choice = choices[_chosenIndex];
            _profile.Record(choice.ProfileImpact);          // silent; never drawn
            _presenter.OnCommitted(choice, _chosenIndex);
            yield return new WaitForSeconds(_postChoiceBeat);

            // Consequence
            Phase = DilemmaPhase.Consequence;
            _narrator.Clear();
            var outcome = _resolver.Resolve(new DilemmaContext(_dilemma, _chosenIndex));
            yield return StartCoroutine(_presenter.PlayConsequence(choice, outcome));
            yield return new WaitForSeconds(_preStatsBeat);

            // Stats + the narrator's reaction over the dimmed world
            Phase = DilemmaPhase.Stats;
            yield return StartCoroutine(_stats.Reveal(outcome.Report, _statsFade));
            _narrator.Show(outcome.NarratorReact);

            // End: replay on any click or key
            Phase = DilemmaPhase.End;
            yield return new WaitForSeconds(_endInputDelay);
            while (!PointerInput.AdvancePressed) yield return null;
            SceneManager.LoadScene(gameObject.scene.name);
        }
    }
}
