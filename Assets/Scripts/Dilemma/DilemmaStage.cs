using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// The composition root for a standalone one-dilemma scene. It validates its wiring,
    /// runs the shared <see cref="DilemmaRunner"/> once, and reloads the scene so the loop
    /// can be replayed. The loop itself lives in the runner, so a sequenced
    /// <see cref="DilemmaBeat"/> plays the identical loop without a reload. No verb branches.
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

        private DilemmaRunner _runner;

        public DilemmaPhase Phase => _runner != null ? _runner.Phase : DilemmaPhase.Present;

        private void Start()
        {
            if (!Setup()) return;
            StartCoroutine(RunStandalone());
        }

        private bool Setup()
        {
            if (_dilemma == null) { Debug.LogError("[DilemmaStage] No Dilemma assigned."); return false; }
            if (_presenter == null) { Debug.LogError("[DilemmaStage] No ConsequencePresenter assigned."); return false; }
            if (_camera == null) _camera = Camera.main;
            _profile = _profile != null ? _profile : Profile.Ensure();
            return true;
        }

        private DilemmaTiming Timing => new DilemmaTiming
        {
            PresentHold = _presentHold,
            PostChoiceBeat = _postChoiceBeat,
            PreStatsBeat = _preStatsBeat,
            StatsFade = _statsFade,
            EndInputDelay = _endInputDelay,
        };

        private IEnumerator RunStandalone()
        {
            var choices = (_showTextFallback && _choices != null) ? _choices : null;
            _runner = new DilemmaRunner(_dilemma, _presenter, _narrator, _stats, _profile, choices, Timing);
            yield return StartCoroutine(_runner.Run());
            SceneManager.LoadScene(gameObject.scene.name);
        }
    }
}
