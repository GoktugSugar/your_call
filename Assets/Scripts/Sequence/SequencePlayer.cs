using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// Plays an ordered list of <see cref="SequenceBeat"/> over a persistent cast (the guide
    /// and its voice, the shared stats and choice widgets, the screen wash). Minimal on
    /// purpose: an ordered beat player, not a branching narrative engine. The opening is its
    /// first use; the full campaign is just more beats and more stations behind the same
    /// player. It owns no beat logic, only the order.
    /// </summary>
    public class SequencePlayer : MonoBehaviour
    {
        [Header("Persistent cast")]
        [SerializeField] private NarratorView _narrator;
        [SerializeField] private ImpFigure _imp;
        [SerializeField] private StatsView _stats;
        [SerializeField] private ChoiceButtons _choices;
        [SerializeField] private Profile _profile;
        [SerializeField] private Camera _camera;
        [SerializeField] private ScreenFade _fade;

        [Header("Beats (played in order)")]
        [SerializeField] private List<SequenceBeat> _beats = new List<SequenceBeat>();

        [Header("Ending")]
        [Tooltip("Dissolve to black once the last beat finishes.")]
        [SerializeField] private bool _fadeToBlackAtEnd = true;
        [SerializeField] private float _endFade = 1.6f;
        [Tooltip("Optional next chapter to load once this sequence ends (for example the trolley chapter " +
                 "flowing into the buttons chapter). Empty holds on the final beat, as before.")]
        [SerializeField] private string _nextScene = "";

        [Tooltip("Dev only: log each beat as it starts. Never shown to the player.")]
        [SerializeField] private bool _logBeats = false;

        private void Start()
        {
            if (_camera == null) _camera = Camera.main;
            _profile = _profile != null ? _profile : Profile.Ensure();
            StartCoroutine(RunAll());
        }

        private IEnumerator RunAll()
        {
            var ctx = new SequenceContext(_narrator, _imp, _stats, _choices, _profile, _camera, _fade);
            for (int i = 0; i < _beats.Count; i++)
            {
                var beat = _beats[i];
                if (beat == null) continue;
                if (_logBeats) Debug.Log("[Sequence] beat " + i + ": " + beat.Note);
                yield return StartCoroutine(beat.Play(ctx));
            }
            if (_fadeToBlackAtEnd && _fade != null)
                yield return StartCoroutine(_fade.FadeTo(1f, _endFade));

            // Optional chapter hand-off: the trolley chapter can flow into the buttons chapter.
            if (!string.IsNullOrEmpty(_nextScene))
                SceneManager.LoadScene(_nextScene);
        }
    }
}
