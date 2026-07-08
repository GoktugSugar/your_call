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

        /// <summary>The ordered beats, exposed read-only so the dev chapter/beat picker can list them
        /// (see Scripts/Dev/DevChapterPicker.cs). Not used by normal play.</summary>
        public IReadOnlyList<SequenceBeat> Beats => _beats;

        /// <summary>
        /// A one-shot start index for the next sequence load: the dev chapter/beat picker sets this
        /// before loading a chapter scene so the sequence can be entered partway (jump to a beat).
        /// Consumed and reset to 0 on <see cref="Start"/>, so a normal boot always starts from the top.
        /// Inert when 0; nothing in normal play sets it.
        /// </summary>
        public static int PendingStartBeat = 0;

        private void Start()
        {
            if (_camera == null) _camera = Camera.main;
            _profile = _profile != null ? _profile : Profile.Ensure();
            int start = _beats.Count > 0 ? Mathf.Clamp(PendingStartBeat, 0, _beats.Count - 1) : 0;
            PendingStartBeat = 0;   // one-shot: consumed here so the next normal load starts at the top
            StartCoroutine(RunAll(start));
        }

        private IEnumerator RunAll(int startIndex)
        {
            var ctx = new SequenceContext(_narrator, _imp, _stats, _choices, _profile, _camera, _fade);

            // Entering partway (the dev picker jumped to a mid-chapter beat): the skipped intro beats
            // never ran, so make sure the screen is clear and the imp is present before the beat plays.
            if (startIndex > 0) PrepareMidEntry(ctx);

            for (int i = startIndex; i < _beats.Count; i++)
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

        // A minimal baseline for a mid-chapter dev entry: the crash/wake/imp-appear intro beats were
        // skipped, so clear the opening black wash and make sure the imp is on screen. Beats build their
        // own apparatus (stations, figures), so nothing else needs faking.
        private void PrepareMidEntry(SequenceContext ctx)
        {
            if (ctx.Fade != null) ctx.Fade.SetAlpha(0f);
            if (ctx.Imp != null)
            {
                if (!ctx.Imp.gameObject.activeSelf) ctx.Imp.gameObject.SetActive(true);
                ctx.Imp.SetAlpha(1f);
            }
        }
    }
}
