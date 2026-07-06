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
        [Tooltip("Offer the plain text choices as a fallback (the trolley). Off for diegetic-only verbs.")]
        [SerializeField] private bool _showTextFallback = true;
        [SerializeField] private DilemmaTiming _timing = DilemmaTiming.Default;

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
            var runner = new DilemmaRunner(_dilemma, _presenter, ctx.Narrator, ctx.Stats, ctx.Profile, choices, _timing);
            yield return runner.Run();

            // The player has advanced: lift the tableau and clear the apparatus for the next beat.
            yield return ctx.Stats.Hide(_statsHideFade);
            if (_deactivateStationAtEnd && _station != null) _station.SetActive(false);
        }
    }
}
