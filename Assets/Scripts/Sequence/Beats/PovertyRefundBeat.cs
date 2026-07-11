using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The poverty refund branch (Chapter 3, only if the player bought End Poverty in the opener). Right
    /// after the free-food beat the imp needles the broke player: they will miss out on everything fun
    /// coming up because they gave it all away, and he can put it right, make those poor children starve
    /// again, and hand the money back. Take the refund (the money returns, poverty comes back) or keep it
    /// ended (stay broke, poverty stays ended). He mocks either way, choice independent, never graded.
    ///
    /// If the player did NOT buy End Poverty, this beat is a no-op: it reads the referenced opener's
    /// <see cref="PriceableBeat.Bought"/> and skips instantly. The refund reflects in the running
    /// <see cref="MoneyBalance"/>. Self contained; reuses the shared ChoiceButtons, StatsView and Profile.
    /// </summary>
    public sealed class PovertyRefundBeat : SequenceBeat
    {
        [Header("Link")]
        [Tooltip("The End Poverty opener beat. This branch only runs if that one was bought.")]
        [SerializeField] private PriceableBeat _povertyBeat;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _tookRefundSeed = 71;
        [SerializeField] private int _keptEndedSeed = 29;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _tookLabel = "took the refund";
        [SerializeField] private string _keptLabel = "kept it ended";

        [Header("Profile (silent, light; self vs others)")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [Tooltip("Recorded when they take the money back (poverty returns): leans self.")]
        [SerializeField] private float _takeNudge = -0.14f;
        [Tooltip("Recorded when they leave it ended (stay broke): leans others.")]
        [SerializeField] private float _keepNudge = 0.14f;

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The setup, shown in order, a click between each. {0} = the amount they gave away.")]
        [SerializeField, TextArea(2, 5)] private string[] _setupLines = new[]
        {
            "Oh. Oh dear. You actually did it. You gave away every last penny to end poverty, and now look at you.",
            "There is a whole lovely chapter of things to buy ahead, and you cannot afford a single one. Broke. For strangers. How noble, how [amber]stupid[/amber].",
            "Tell you what. I am feeling generous. I can undo it. Put the [amber]{0}[/amber] right back in your pocket, and let those poor little children go hungry again. What do you say?",
        };
        [Tooltip("Mock taking the refund (poverty returns). Choice independent, never graded. {0} = the amount.")]
        [SerializeField, TextArea(2, 5)] private string _takeReact =
            "And back it comes. That charity of yours lasted, what, two whole minutes. The children thank you for nothing. I knew you had a price on other people; I just did not think it was [amber]boredom[/amber].";
        [Tooltip("Mock keeping it ended (stay broke). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _keepReact =
            "You kept it. Stone broke, and you kept it. Either you are a genuinely good man, or you just did not want to look like one in front of me. I honestly cannot tell, and that is the fun of you.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _takeLabel = "Take the money back";
        [SerializeField] private string _keepLabel = "Leave it ended";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _postRefundBeat = 0.5f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        /// <summary>After this beat: does poverty stay ended? (True unless the player took the refund.)</summary>
        public bool PovertyEnded { get; private set; }

        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            // Only runs if the opener was bought. Otherwise skip instantly (no needling, nothing on screen).
            if (_povertyBeat == null || !_povertyBeat.Bought)
                yield break;

            if (ctx.Money == null || ctx.Choices == null)
            {
                Debug.LogError("[PovertyRefundBeat] '" + Note + "' needs the MoneyBalance and ChoiceButtons.");
                yield break;
            }

            PovertyEnded = true;
            int refund = _povertyBeat.AmountSpent;

            // The imp needles the broke, selfless player.
            for (int i = 0; i < _setupLines.Length; i++)
            {
                if (string.IsNullOrEmpty(_setupLines[i])) continue;
                ctx.Narrator.Show(Localization.Format(_setupLines[i], Localization.Money(refund)));
                while (ctx.Narrator.IsShowing) yield return null;
                yield return WaitAdvance(_advanceLockout);
            }
            ctx.Narrator.Clear();

            // Take the money back, or leave it ended.
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_takeLabel, _keepLabel);
            try { while (_picked < 0) yield return null; }
            finally { ctx.Choices.Chosen -= OnPicked; ctx.Choices.Dismiss(); }

            bool tookRefund = _picked == 0;
            if (tookRefund)
            {
                ctx.Money.Refund(refund);
                PovertyEnded = false;
                // Undo it on the receipt too: they took the money back, so End Poverty is no longer a purchase.
                if (_povertyBeat != null) ctx.Ledger?.RemoveBought(_povertyBeat.ItemName);
                yield return new WaitForSeconds(_postRefundBeat);
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _takeNudge) });
                yield return Say(ctx, Localization.Format(_takeReact, Localization.Money(refund)));
            }
            else
            {
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _keepNudge) });
                yield return Say(ctx, Localization.Localize(_keepReact));
            }

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_tookRefundSeed, _keptEndedSeed));
            report.Bars.Add(new StatBar(_tookLabel, _tookRefundSeed, tookRefund));
            report.Bars.Add(new StatBar(_keptLabel, _keptEndedSeed, !tookRefund));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

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
