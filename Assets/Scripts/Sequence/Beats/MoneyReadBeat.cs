using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The money chapter's closer (Chapter 3): the imp reads the player. There is no shop and no final
    /// purchase (the cash-out menu was removed); this is just the read. It looks at how much of the finite
    /// <see cref="MoneyBalance"/> the player spent versus hoarded across the chapter, folds that silently
    /// into the <see cref="Profile"/> (self vs others; hoarding leans self), and delivers a hoard / spend /
    /// middle read line pointing toward the ending (never scoring). A seeded spent-vs-kept split closes it.
    ///
    /// Self contained (one job: read the player from the pot), reusing the shared StatsView and the silent
    /// Profile. The last beat of the chapter; the SequencePlayer fades to black after it.
    /// </summary>
    public sealed class MoneyReadBeat : SequenceBeat
    {
        [Header("Crowd split (seeded; how others chose over the whole chapter)")]
        [SerializeField] private int _spentSeed = 58;
        [SerializeField] private int _keptSeed = 42;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _spentLabel = "spent most of it";
        [SerializeField] private string _keptLabel = "held onto it";

        [Header("Profile (silent, light; self vs others). Hoarding leans self.")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [SerializeField] private float _hoardNudgeScale = 0.2f;
        [Tooltip("At or above this share of the pot kept, the imp reads them as a hoarder.")]
        [SerializeField, Range(0.5f, 1f)] private float _hoardThreshold = 0.8f;
        [Tooltip("At or below this share kept, the imp reads them as a spender.")]
        [SerializeField, Range(0f, 0.5f)] private float _blewThreshold = 0.2f;

        [Header("Copy (the imp; no dashes). The read that points toward the ending, never scoring.")]
        [Tooltip("The read when they spent most of it. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _readBlew =
            "You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. Cash does not hide who a person is, it shows it, and I watched you empty yourself out here. I have a very clear picture of you now.";
        [Tooltip("The read when they hoarded most of it.")]
        [SerializeField, TextArea(2, 6)] private string _readHoard =
            "You kept nearly all of it. Dead, in a void, no pockets, no tomorrow, and still you would not let a single dollar go. That is not thrift. That is a man who counts, who always was counting, up there on the bench. Cash does not hide who a person is, and yours is loud.";
        [Tooltip("The read when they spent a middling amount.")]
        [SerializeField, TextArea(2, 6)] private string _readMiddle =
            "Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. Cash does not hide who a person is, it shows it, and I have a very clear picture of you now, clearer than you would like.";

        [Header("Timing")]
        [SerializeField] private float _preReadHold = 0.4f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null)
            {
                Debug.LogError("[MoneyReadBeat] '" + Note + "' needs the chapter MoneyBalance (SequencePlayer money slot).");
                yield break;
            }

            int hoarded = ctx.Money.Balance;
            int starting = Mathf.Max(1, ctx.Money.StartingAmount);
            float hoardRatio = Mathf.Clamp01(hoarded / (float)starting);

            // Silent profile: hoarding leans self.
            ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, -hoardRatio * _hoardNudgeScale) });

            string read = hoardRatio >= _hoardThreshold ? _readHoard
                        : (hoardRatio <= _blewThreshold ? _readBlew : _readMiddle);
            if (_preReadHold > 0f) yield return new WaitForSeconds(_preReadHold);
            yield return Say(ctx, read);

            // How others chose (over the whole chapter): spent most vs held on.
            bool spentMost = hoardRatio < 0.5f;
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_spentSeed, _keptSeed));
            report.Bars.Add(new StatBar(_spentLabel, _spentSeed, spentMost));
            report.Bars.Add(new StatBar(_keptLabel, _keptSeed, !spentMost));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private IEnumerator Say(SequenceContext ctx, string line)
        {
            ctx.Narrator.Show(line);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
        }

        private IEnumerator WaitAdvance(float lockout)
        {
            float t = 0f;
            while (true)
            {
                t += Time.deltaTime;
                if (t > lockout && PointerInput.AdvancePressed) yield break;
                yield return null;
            }
        }
    }
}
