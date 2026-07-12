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
        [Tooltip("Optional: the finite money pot for the money chapter (Chapter 3). Empty in other chapters, " +
                 "so the money beats can assert on it and every other beat ignores it.")]
        [SerializeField] private MoneyBalance _money;

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

        // --- save / continue integration ---
        private SequenceContext _ctx;   // the live context, so a manual save can snapshot at any moment
        private int _currentBeat;       // the beat currently entered (for auto-save and manual save)
        private PauseOverlay _pause;     // the in-chapter Esc pause overlay (built at runtime)

        /// <summary>The beat the player is on right now, for the save system.</summary>
        public int CurrentBeat => _currentBeat;

        /// <summary>The active chapter scene name, for the save system.</summary>
        public string ChapterScene => SceneManager.GetActiveScene().name;

        /// <summary>Whether saving is allowed right now: only during a real player run (a New Game or a
        /// Continue), never on a dev-picker jump or a scene opened directly (both leave the save untouched).
        /// The pause overlay greys its Save line when this is false.</summary>
        public bool CanSave => SaveService.Instance != null && SaveService.Instance.RealRunActive;

        /// <summary>Write the current run to the single save now (the pause overlay's manual Save). Returns
        /// false when saving is not allowed (not a real run) or nothing is ready yet.</summary>
        public bool SaveNow()
        {
            if (!CanSave || _ctx == null) return false;
            SaveService.Instance.Write(SaveCapture.Build(ChapterScene, _currentBeat, _ctx));
            return true;
        }

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
            // The money chapter also carries a purchase ledger, created here (a plain service, no scene
            // object) so the end-of-chapter overview can list what was bought. Null in every other chapter.
            var ledger = _money != null ? new PurchaseLedger() : null;
            var ctx = new SequenceContext(_narrator, _imp, _stats, _choices, _profile, _camera, _fade, _money, ledger);
            _ctx = ctx;

            // Continue resuming a run: restore the saved profile (and, in the money chapter, the balance and
            // ledger) before any beat plays, so the resumed beat sees the exact state the player left off in.
            // One-shot: consumed here so a later chapter hand-off within this run never re-restores.
            var resume = SaveService.PendingResume;
            SaveService.PendingResume = null;
            if (resume != null) SaveCapture.RestoreInto(resume, ctx);

            // Entering partway (a Continue resume, or a dev picker beat jump): the skipped intro beats
            // never ran, so make sure the screen is clear and the imp is present before the beat plays.
            if (startIndex > 0) PrepareMidEntry(ctx);

            EnsurePauseOverlay();

            for (int i = startIndex; i < _beats.Count; i++)
            {
                var beat = _beats[i];
                if (beat == null) continue;
                ResetSharedUiForBeat(ctx);   // first step of entering a beat: clear anything left from the last one
                _currentBeat = i;
                Autosave(ctx, i);            // save on entering each beat: never lose more than the current beat
                if (_logBeats) Debug.Log("[Sequence] beat " + i + ": " + beat.Note);
                yield return StartCoroutine(beat.Play(ctx));
            }
            if (_fadeToBlackAtEnd && _fade != null)
                yield return StartCoroutine(_fade.FadeTo(1f, _endFade));

            // Optional chapter hand-off: save the transition (aimed at the next chapter's first beat) so a
            // quit during the load resumes at the next chapter, then load it.
            if (!string.IsNullOrEmpty(_nextScene))
            {
                var s = SaveService.Instance;
                if (s != null && s.RealRunActive) s.Write(SaveCapture.Build(_nextScene, 0, ctx));
                SceneManager.LoadScene(_nextScene);
            }
        }

        // Save the current run on entering a beat. Only during a real player run (New Game / Continue): a
        // dev-picker jump or a directly-opened scene leaves SaveService.RealRunActive false, so testing never
        // overwrites the player's save.
        private void Autosave(SequenceContext ctx, int beatIndex)
        {
            var s = SaveService.Instance;
            if (s == null || !s.RealRunActive) return;
            s.Write(SaveCapture.Build(SceneManager.GetActiveScene().name, beatIndex, ctx));
        }

        // Build the in-chapter pause overlay once (Esc: Resume / Save / Quit to Menu). Reuses the narrator's
        // Caveat font so it matches the handwriting, with no per-scene wiring.
        private void EnsurePauseOverlay()
        {
            if (_pause != null) return;
            var go = new GameObject("PauseOverlay");
            go.transform.SetParent(transform, false);
            _pause = go.AddComponent<PauseOverlay>();
            _pause.Init(this, _camera, _narrator != null ? _narrator.Font : null);
        }

        // Fired as the very first step of entering every beat: instantly tear down any choice affordances
        // and narration left over from the previous beat, so nothing (option labels, leftover text) from
        // the prior beat is ever visible during this one. A general lifecycle guarantee, so it fixes every
        // beat, including the ones that pick via a diegetic button and used to leave the shared choices up.
        private void ResetSharedUiForBeat(SequenceContext ctx)
        {
            if (ctx.Choices != null) ctx.Choices.HideNow();
            if (ctx.Stats != null) ctx.Stats.HideNow();   // never carry a prior beat's stats reveal into this one
            if (ctx.Narrator != null) ctx.Narrator.Clear();
        }

        /// <summary>Instantly tear down the shared choice, stats and narration UI, so no beat's affordances or
        /// its stats reveal linger when the run is left for the menu (the pause overlay's Quit to Menu calls
        /// this before loading the menu scene). Mirrors <see cref="ResetSharedUiForBeat"/> but is safe to call
        /// from outside the beat loop.</summary>
        public void HideSharedUiNow()
        {
            if (_choices != null) _choices.HideNow();
            if (_stats != null) _stats.HideNow();
            if (_narrator != null) _narrator.Clear();
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
