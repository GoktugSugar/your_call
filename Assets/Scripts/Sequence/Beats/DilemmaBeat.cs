using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One dilemma, played inside a sequence. It activates its station (the verb's apparatus),
    /// runs the shared <see cref="DilemmaRunner"/> over the persistent guide, stats and choice
    /// widgets, then lifts the aftermath tableau and clears the station so the next beat plays
    /// over a clean void. The loop, resolvers and presenters are reused untouched; a dilemma
    /// is still just data plus its station.
    /// </summary>
    public sealed class DilemmaBeat : SequenceBeat
    {
        [Header("Content")]
        [SerializeField] private Dilemma _dilemma;

        [Header("Station (this verb's apparatus, starts inactive)")]
        [SerializeField] private GameObject _station;
        [SerializeField] private ConsequencePresenter _presenter;

        [Header("Loop")]
        [Tooltip("Offer the plain text choices as a fallback (the trolley). Off for diegetic-only verbs (multiple-choice owns its own picks).")]
        [SerializeField] private bool _showTextFallback = true;
        [SerializeField] private DilemmaTiming _timing = DilemmaTiming.Default;

        [Header("Choice-triggered ending (optional; the baby opener)")]
        [Tooltip("If wired, a choice flagged EndsGame hands off to this reusable ending after its consequence: " +
                 "the imp's break line (the choice's Narrator React), the imp fades, then the credits roll. " +
                 "Leave empty on every normal beat.")]
        [SerializeField] private Ending _endsGameEnding;
        [Tooltip("A stunned beat before the imp's break line lands.")]
        [SerializeField] private float _endPreBreakHold = 0.5f;
        [Tooltip("How long the imp takes to fade away as it quits.")]
        [SerializeField] private float _endImpFade = 0.9f;

        [Header("Teardown")]
        [SerializeField] private float _statsHideFade = 0.6f;
        [SerializeField] private bool _deactivateStationAtEnd = true;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_dilemma == null || _presenter == null)
            {
                Debug.LogError("[DilemmaBeat] '" + Note + "' is missing its dilemma or presenter.");
                yield break;
            }

            if (_station != null && !_station.activeSelf) _station.SetActive(true);

            var choices = _showTextFallback ? ctx.Choices : null;
            System.Func<DilemmaChoice, System.Collections.IEnumerator> onEndsGame =
                _endsGameEnding != null ? (choice => PlayEnding(ctx, choice)) : (System.Func<DilemmaChoice, System.Collections.IEnumerator>)null;
            var runner = new DilemmaRunner(_dilemma, _presenter, ctx.Narrator, ctx.Stats, ctx.Profile, choices, _timing, onEndsGame);
            yield return runner.Run();

            // The player has advanced: lift the tableau and clear the apparatus for the next beat.
            yield return ctx.Stats.Hide(_statsHideFade);
            if (_deactivateStationAtEnd && _station != null) _station.SetActive(false);
        }

        // A choice-triggered ending: the imp drops the act. A stunned beat, then its break line (the
        // choice's reaction), then it fades away and the credits roll. Reuses the shared Ending and
        // CreditsRoll untouched, the same shape as the shoot-the-imp ending.
        private IEnumerator PlayEnding(SequenceContext ctx, DilemmaChoice choice)
        {
            if (ctx.Imp != null)
            {
                var roamer = ctx.Imp.GetComponent<ImpRoamer>();
                if (roamer != null) roamer.enabled = false;   // the imp holds still for its last word
            }
            if (_endPreBreakHold > 0f) yield return new WaitForSeconds(_endPreBreakHold);
            yield return _endsGameEnding.Play(ctx.Narrator, choice.NarratorReact, FadeImp(ctx.Imp));
        }

        private IEnumerator FadeImp(ImpFigure imp)
        {
            if (imp == null) yield break;
            float d = Mathf.Max(_endImpFade, 0.05f), t = 0f;
            while (t < d) { t += Time.deltaTime; imp.SetAlpha(1f - t / d); yield return null; }
            imp.SetAlpha(0f);
        }
    }
}
