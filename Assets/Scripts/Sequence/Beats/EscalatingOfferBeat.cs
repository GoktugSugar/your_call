using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using TMPro;
using UnityEngine;
using UnityEngine.Serialization;

namespace YourCall
{
    /// <summary>
    /// A single button offer that returns and returns, the amount changing each press. One component,
    /// two modes (Chapter 2), configured by data (start amount, factor, limit, per-tier lines):
    ///
    /// <b>Halving</b> (The Price of a Life, beat 2): press it and a running money total grows while a
    /// random stranger folds; the offer returns HALVED, all the way down. Refuse at any point and the
    /// imp mocks where you stopped (choice independent, never graded), then shows how others chose at
    /// that price. He stays completely business as usual the whole descent, giving each tier its own
    /// distinct line, so the break lands: accepting at the very bottom (one dollar, tunable) drops the
    /// act, rages, and quits, then the credits roll. That break is the game's third choice triggered
    /// secret ending and the one sanctioned exception to the mocking rule (with the baby and shoot the imp).
    ///
    /// <b>Climbing</b> (The Button for Everyone But You, beat 1): press it and every living person gets a
    /// sum, growing each press up to a cap. It costs you nothing, gains you nothing, and no one dies (no
    /// victim). Refuse (stop) and it ends. The imp needles either way, per tier. No death, no ending.
    ///
    /// Self contained: it loops the tiers itself and reuses the shared choice affordance, the Figure fold
    /// and fall (halving only), the StatsView, the silent Profile, and the reusable Ending + CreditsRoll
    /// (halving only). DilemmaStage/DilemmaRunner stay generic; this is just another beat in order.
    /// </summary>
    public sealed class EscalatingOfferBeat : SequenceBeat
    {
        private enum OfferMode
        {
            Halving,   // the money button: amount halves, a stranger dies each press, a rage-quit at the floor
            Climbing   // the everyone-but-you button: amount grows, no victim, ends when the player stops
        }

        [Header("Mode")]
        [Tooltip("Halving = the money-for-a-death button (a stranger folds each press, rage-quit at the floor). " +
                 "Climbing = the everyone-but-you button (no victim, grows to a cap, ends on refuse).")]
        [SerializeField] private OfferMode _mode = OfferMode.Halving;

        [Header("Tiers")]
        [Tooltip("The first offer, in dollars.")]
        [SerializeField] private int _startAmount = 100000;
        [Tooltip("Each acceptance re-offers at this factor of the previous amount. Below 1 halves (money button); above 1 climbs (everyone-but-you).")]
        [FormerlySerializedAs("_halveFactor")]
        [SerializeField, Range(0.1f, 4f)] private float _stepFactor = 0.5f;
        [Tooltip("Halving only: accepting at or below this amount fires the rage-quit ending. Must be at least 1.")]
        [SerializeField] private int _rageThreshold = 1;
        [Tooltip("Climbing only: the amount stops growing at this cap (the button keeps offering the cap until the player stops).")]
        [SerializeField] private int _capAmount = 512;

        [Header("References")]
        [Tooltip("Halving only: the ordinary stranger who folds on each acceptance (reuses the shared Figure fold-and-fall). Unused when climbing.")]
        [SerializeField] private Figure _figurePrefab;
        [Tooltip("Halving only: the reusable ending fired at the rage threshold (the imp breaks, fades, then the credits roll). Unused when climbing.")]
        [SerializeField] private Ending _ending;
        [Tooltip("Optional font for the on-screen readout (Caveat, to match the narration). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The stranger (halving only)")]
        [SerializeField] private Vector2 _strangerPosition = new Vector2(0f, -0.7f);
        [SerializeField] private float _strangerScale = 1.15f;
        [Tooltip("A beat the stranger stands before folding, so the eye registers the life.")]
        [SerializeField] private float _strangerHold = 0.35f;
        [SerializeField] private float _foldDuration = 0.7f;
        [SerializeField] private float _foldSettle = 0.3f;

        [Header("Running readout (money amber; the second line red for the dead, muted for the given)")]
        [SerializeField] private Vector2 _moneyAnchor = new Vector2(0f, 2.7f);
        [SerializeField] private float _moneySize = 3.4f;
        [SerializeField] private Vector2 _deadAnchor = new Vector2(0f, 1.95f);
        [SerializeField] private float _deadSize = 2.3f;
        [SerializeField] private int _sortingOrder = 16;
        [SerializeField] private float _readoutFade = 0.4f;
        [Tooltip("Climbing only: the living population the per-person sum is handed to, for the dramatised total-given line.")]
        [SerializeField] private long _worldPopulation = 8100000000L;

        [Header("Crowd split (seeded; the keep-going rate drops as the stakes climb)")]
        [Tooltip("Halving: seeded percentage who took the money at the top amount. Climbing: percentage who gave at the first (cheapest) tier.")]
        [SerializeField, Range(0f, 100f)] private float _topAcceptancePct = 61f;
        [Tooltip("Halving: seeded percentage who took the money at one dollar. Climbing: percentage who kept giving at the cap.")]
        [SerializeField, Range(0f, 100f)] private float _floorAcceptancePct = 2f;
        [SerializeField] private string _statsHeading = "how others chose";
        [Tooltip("Left/first bar label (the seeded crowd). Halving: took the money. Climbing: kept giving.")]
        [SerializeField] private string _tookLabel = "took the money";
        [Tooltip("Right/second bar label (the player's pick, who stopped here). Halving: walked away. Climbing: stopped here.")]
        [SerializeField] private string _walkedLabel = "walked away";

        [Header("Profile (silent, light; self vs others)")]
        [Tooltip("Halving: recorded on self-vs-others per acceptance. Negative leans self (taking for yourself at another's cost).")]
        [SerializeField] private float _selfNudgePerAccept = -0.12f;
        [Tooltip("Climbing: recorded on self-vs-others per acceptance. Positive leans others (pointless generosity to strangers).")]
        [SerializeField] private float _othersNudgePerAccept = 0.08f;

        [Header("Copy (the imp; no dashes). {0} is the amount, e.g. $100,000.")]
        [SerializeField, TextArea(2, 4)] private string _offerFormat =
            "Here. One button. Press it and [amber]{0}[/amber] is yours, and somewhere a stranger you will never meet folds up and [red]dies[/red]. Or do not, and we stop. Your call.";
        [Tooltip("Climbing offer, business as usual. {0} is the amount per person.")]
        [SerializeField, TextArea(2, 4)] private string _climbOfferFormat =
            "Here. Press it and every living person gets [amber]{0}[/amber]. It costs you nothing. It gains you nothing. You will never meet a single one of them. Press it, or walk away.";

        [Tooltip("Per-tier lines for the halving money button, keyed by amount (the tier just accepted). Escalates in flavour as the price drops and the body count climbs. Never grades. The one-dollar tier fires the break instead.")]
        [SerializeField] private List<OfferTier> _halveTierQuips = new List<OfferTier>
        {
            new OfferTier(100000, "One [red]life[/red], banked. Barely broke a sweat, did you."),
            new OfferTier(50000,  "Half the price, and the very same yes. Efficient of you."),
            new OfferTier(25000,  "[amber]Twenty five thousand[/amber] now. The number keeps falling and your thumb does not. Curious."),
            new OfferTier(12500,  "Another one [red]folds[/red]. You did not even watch that time."),
            new OfferTier(6250,   "We are into the loose change of a whole person now. Keep pressing."),
            new OfferTier(3125,   "Cheaper than a used car, and off they [red]go[/red]."),
            new OfferTier(1562,   "You have stopped reading the number, have you not. You simply press."),
            new OfferTier(781,    "Look at the tidy little pile you are making. All those quiet [red]dead[/red] strangers."),
            new OfferTier(390,    "Three figures for a living soul, and not a flicker of hesitation."),
            new OfferTier(195,    "Under two hundred. I would be embarrassed. You are not, which I adore."),
            new OfferTier(97,     "Double digits any moment now. This is my favourite part."),
            new OfferTier(48,     "Forty eight dollars. A decent dinner. A whole [red]person[/red]. The same button."),
            new OfferTier(24,     "Twenty four. You could find that in a coat pocket."),
            new OfferTier(12,     "A dozen dollars a [red]body[/red]. Bulk rate. Do carry on."),
            new OfferTier(6,      "Six. Six! I can hardly say it with a straight face, and I have no face."),
            new OfferTier(3,      "Three dollars. We are nearly at the bottom, you magnificent ghoul. Press on."),
        };

        [Tooltip("Per-tier lines for the climbing everyone-but-you button, keyed by amount (the tier just given). Needles both the generosity and the pointlessness. Never grades. Holds on the last for the cap.")]
        [SerializeField] private List<OfferTier> _climbTierQuips = new List<OfferTier>
        {
            new OfferTier(1,   "One dollar. To every soul alive at once. That is a great many dollars, and not one of them yours."),
            new OfferTier(2,   "Two now. Somewhere a stranger you will never meet is a little less broke, and you feel precisely nothing."),
            new OfferTier(4,   "Four each. Billions of tiny thank-yous you will never once hear. Press on, saint."),
            new OfferTier(8,   "Eight. Look at you, quietly handing a fortune to people who will never learn your name."),
            new OfferTier(16,  "Sixteen apiece. It costs you nothing and buys you nothing, and still you press. Fascinating."),
            new OfferTier(32,  "Thirty two. Either you are boundlessly generous or you simply like the button. I honestly cannot tell."),
            new OfferTier(64,  "Sixty four each. Real money, to real strangers, for no reason on earth. Marvellous."),
            new OfferTier(128, "A hundred and twenty eight a head. The whole world is richer and you are exactly the same."),
            new OfferTier(256, "Two hundred and fifty six. You could stop. No one is watching. No one ever was."),
            new OfferTier(512, "The very top, over and over, every living person the richer, and not a thing in it for you. Keep going or do not. I am delighted either way."),
        };

        [Tooltip("Mock where they stopped when they refuse the money button. {0} is the amount they would not take. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _refuseReact =
            "And there it is. [amber]{0}[/amber] was the number you would not go below. Everyone has one. Now I know yours.";
        [Tooltip("Climbing refuse react after they pushed it a good way. {0} is the amount a head they last gave. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _climbRefuseHigh =
            "And you stop. [amber]{0}[/amber] a head to every stranger alive, for nothing back, and then you were done. A saint, on a timer. Noted.";
        [Tooltip("Climbing refuse react when they gave little or nothing. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _climbRefuseLow =
            "And you are done already. Barely a dollar for the entire living world, when it would have cost you nothing at all. Why would you. There was nothing in it for you.";

        [Tooltip("The rage-quit break line (halving only; real disgust, the act dropped; the sanctioned exception). No dashes.")]
        [SerializeField, TextArea(3, 6)] private string _breakLine =
            "[red]A person.[/red] You just killed a person. For [amber]one dollar[/amber]. One. I am not doing the voice for this one. There is nothing funny here, nothing, and I find everything funny. You are a greedy piece of shit and I am done with you. Go and rot. I quit.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _acceptLabel = "Press it";
        [SerializeField] private string _refuseLabel = "Refuse";
        [Tooltip("Climbing accept label (kept distinct because there is no cost).")]
        [SerializeField] private string _climbAcceptLabel = "Press it";
        [Tooltip("Climbing refuse label.")]
        [SerializeField] private string _climbRefuseLabel = "Stop";

        [Header("Timing")]
        [SerializeField] private float _postAcceptBeat = 0.35f;
        [Tooltip("Auto-advance the per-tier line (so the offer keeps rolling), instead of waiting for a click.")]
        [SerializeField] private bool _eggAutoAdvance = true;
        [SerializeField] private float _eggHold = 1.3f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _preBreakHold = 0.6f;
        [SerializeField] private float _impFade = 0.9f;

        private int _picked = -1;
        private TextMeshPro _moneyLabel;
        private TextMeshPro _deadLabel;
        private bool _readoutShown;
        private Camera _cam;

        private bool Climbing => _mode == OfferMode.Climbing;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Climbing && _figurePrefab == null)
            {
                Debug.LogError("[EscalatingOfferBeat] '" + Note + "' (Halving) is missing its figure prefab.");
                yield break;
            }
            if (ctx.Choices == null)
            {
                Debug.LogError("[EscalatingOfferBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;
            BuildReadout();

            int floor = Mathf.Max(1, _rageThreshold);
            int amount = Climbing ? Mathf.Max(1, _startAmount) : Mathf.Max(floor, _startAmount);
            long total = 0;          // halving: money banked. climbing: cumulative per-person given.
            int dead = 0;            // halving: body count.
            int reached = 0;         // climbing: the last amount actually given (how far they pushed).
            string acceptLabel = Climbing ? _climbAcceptLabel : _acceptLabel;
            string refuseLabel = Climbing ? _climbRefuseLabel : _refuseLabel;

            ctx.Choices.Chosen += OnPicked;
            try
            {
                while (true)
                {
                    // Present the offer, business as usual, then arm accept / refuse.
                    _picked = -1;
                    ctx.Narrator.Show(string.Format(Climbing ? _climbOfferFormat : _offerFormat, Money(amount)));
                    while (ctx.Narrator.IsShowing) yield return null;
                    ctx.Choices.Present(acceptLabel, refuseLabel);
                    while (_picked < 0) yield return null;

                    if (_picked == 1)
                    {
                        // Refused / stopped: the offer ends. The imp mocks where they stopped (choice
                        // independent, never graded), then how others chose, matching the reaction-then-stats
                        // rhythm of the normal loop. Then the run moves on.
                        ctx.Narrator.Clear();
                        ctx.Narrator.Show(RefuseLine(amount, reached));
                        while (ctx.Narrator.IsShowing) yield return null;
                        yield return WaitAdvance(_advanceLockout);
                        ctx.Narrator.Clear();
                        yield return RevealCrowdSplit(ctx, amount);
                        break;
                    }

                    // Accepted.
                    if (Climbing)
                    {
                        // Everyone gets the sum. No victim, no fold. The per-person total climbs.
                        total += amount;
                        reached = amount;
                        UpdateReadout(total, 0);
                        ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.SelfVsOthers, _othersNudgePerAccept) });
                    }
                    else
                    {
                        // A stranger folds, the money is banked, the body count ticks up.
                        ctx.Narrator.Clear();
                        yield return KillStranger(ctx);
                        total += amount;
                        dead += 1;
                        UpdateReadout(total, dead);
                        ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.SelfVsOthers, _selfNudgePerAccept) });
                    }
                    yield return new WaitForSeconds(_postAcceptBeat);

                    if (!Climbing && amount <= floor)
                    {
                        // Sold a life for a dollar: the imp drops the act, rages, and quits.
                        yield return RageQuit(ctx);
                        yield break;   // the credits reload the scene; we never return
                    }

                    // Business as usual: the tier's own line, no grading, then the offer returns at the
                    // next amount. It auto-advances so the offer keeps rolling and the imp reads as unbothered.
                    string quip = TierLine(amount);
                    if (!string.IsNullOrEmpty(quip))
                    {
                        ctx.Narrator.Show(quip);
                        while (ctx.Narrator.IsShowing) yield return null;
                        if (_eggAutoAdvance) yield return new WaitForSeconds(_eggHold);
                        else yield return WaitAdvance(_advanceLockout);
                    }
                    ctx.Narrator.Clear();
                    amount = NextAmount(amount);
                }
            }
            finally
            {
                ctx.Choices.Chosen -= OnPicked;
            }

            TeardownReadout();
        }

        private void OnPicked(int index)
        {
            if (_picked < 0) _picked = index;
        }

        private int NextAmount(int amount)
        {
            // Floor so the halving descent matches the tiers the per-tier lines are keyed to (100000
            // down to 3, then the one-dollar break), the same progression as before. Climbing (a whole
            // factor) is exact, with a +1 guard so a fractional climb factor still grows.
            int next = Mathf.FloorToInt(amount * _stepFactor);
            if (Climbing) return Mathf.Min(Mathf.Max(_capAmount, 1), Mathf.Max(next, amount + 1));
            return Mathf.Max(1, next);
        }

        private string RefuseLine(int amount, int reached)
        {
            if (!Climbing) return string.Format(_refuseReact, Money(amount));
            // Needle either way: a saint who pushed it, or someone who could not be bothered.
            bool pushed = reached >= Mathf.Max(1, Mathf.RoundToInt(Mathf.Max(_capAmount, 1) * 0.25f));
            return pushed ? string.Format(_climbRefuseHigh, Money(reached)) : _climbRefuseLow;
        }

        // Spawn one ordinary stranger at centre stage and fold them with the shared death effect.
        private IEnumerator KillStranger(SequenceContext ctx)
        {
            var s = Instantiate(_figurePrefab, transform);
            s.name = "Stranger";
            s.transform.localPosition = new Vector3(_strangerPosition.x, _strangerPosition.y, 0f);
            s.transform.localScale = new Vector3(_strangerScale, _strangerScale, 1f);
            if (_strangerHold > 0f) yield return new WaitForSeconds(_strangerHold);
            s.Strike(_foldDuration);
            yield return new WaitForSeconds(_foldDuration + _foldSettle);
            if (s != null) Destroy(s.gameObject);
        }

        private IEnumerator RevealCrowdSplit(SequenceContext ctx, int amount)
        {
            float keepGoing = AcceptPctFor(amount);
            var report = new ResolutionReport { Heading = _statsHeading, MaxValue = 100f };
            report.Bars.Add(new StatBar(_tookLabel, Mathf.Round(keepGoing), false));
            report.Bars.Add(new StatBar(_walkedLabel, Mathf.Round(100f - keepGoing), true)); // the player stopped here
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private IEnumerator RageQuit(SequenceContext ctx)
        {
            TeardownReadout();
            ctx.Choices.Dismiss();
            if (ctx.Imp != null)
            {
                var roamer = ctx.Imp.GetComponent<ImpRoamer>();
                if (roamer != null) roamer.enabled = false;   // the imp holds still for its last word
            }
            if (_preBreakHold > 0f) yield return new WaitForSeconds(_preBreakHold);

            if (_ending != null)
            {
                yield return _ending.Play(ctx.Narrator, _breakLine, FadeImp(ctx.Imp));
            }
            else
            {
                Debug.LogWarning("[EscalatingOfferBeat] no Ending wired; playing the break line only.");
                ctx.Narrator.Show(_breakLine);
                while (ctx.Narrator.IsShowing) yield return null;
            }
        }

        private IEnumerator FadeImp(ImpFigure imp)
        {
            if (imp == null) yield break;
            float d = Mathf.Max(_impFade, 0.05f), t = 0f;
            while (t < d) { t += Time.deltaTime; imp.SetAlpha(1f - t / d); yield return null; }
            imp.SetAlpha(0f);
        }

        // Seeded keep-going rate for a tier, interpolated on a log scale so it drops as the stakes climb.
        // Halving: high at the top amount, low at one dollar. Climbing: high at the first cheap tier, low
        // at the cap. Both from _topAcceptancePct to _floorAcceptancePct.
        private float AcceptPctFor(int amount)
        {
            if (Climbing)
            {
                float start = Mathf.Max(1, _startAmount);
                float cap = Mathf.Max(start + 1f, _capAmount);
                float a = Mathf.Clamp(amount, (int)start, (int)cap);
                float t = Mathf.Log(a / start) / Mathf.Log(cap / start);   // 0 at the first tier, 1 at the cap
                return Mathf.Lerp(_topAcceptancePct, _floorAcceptancePct, Mathf.Clamp01(t));
            }
            else
            {
                float top = Mathf.Max(1, _startAmount);
                float a = Mathf.Clamp(amount, 1, (int)top);
                float t = 1f;
                if (top > 1f) t = 1f - (Mathf.Log(a) / Mathf.Log(top));   // 0 at the top amount, 1 at a dollar
                return Mathf.Lerp(_topAcceptancePct, _floorAcceptancePct, Mathf.Clamp01(t));
            }
        }

        // The authored line for a tier, matched by amount with a graceful fallback (nearest lower-or-equal,
        // else the last), so retuning the amounts never leaves a tier silent.
        private string TierLine(int amount)
        {
            var quips = Climbing ? _climbTierQuips : _halveTierQuips;
            if (quips == null || quips.Count == 0) return null;
            for (int i = 0; i < quips.Count; i++)
                if (quips[i] != null && quips[i].Amount == amount) return quips[i].Line;
            // Fallback: the closest authored tier at or below this amount, else the last line.
            OfferTier best = null;
            for (int i = 0; i < quips.Count; i++)
            {
                var q = quips[i];
                if (q == null) continue;
                if (q.Amount <= amount && (best == null || q.Amount > best.Amount)) best = q;
            }
            if (best != null) return best.Line;
            return quips[quips.Count - 1] != null ? quips[quips.Count - 1].Line : null;
        }

        private static string Money(int amount) => "$" + amount.ToString("#,0", CultureInfo.InvariantCulture);

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

        private void BuildReadout()
        {
            _moneyLabel = InkText.Create(transform, "MoneyTotal", _moneySize, Palette.Amber, TextAlignmentOptions.Center, _sortingOrder);
            // Second line: red for the dead (halving), muted for the given (climbing, no death).
            Color secondColor = Climbing ? Palette.Muted : Palette.InkRed;
            _deadLabel = InkText.Create(transform, "SecondLine", _deadSize, secondColor, TextAlignmentOptions.Center, _sortingOrder);
            if (_font != null) { _moneyLabel.font = _font; _deadLabel.font = _font; }
            _moneyLabel.rectTransform.sizeDelta = new Vector2(11f, 1.4f);
            _deadLabel.rectTransform.sizeDelta = new Vector2(13f, 1.2f);
            _moneyLabel.transform.localPosition = new Vector3(_moneyAnchor.x, _moneyAnchor.y, 0f);
            _deadLabel.transform.localPosition = new Vector3(_deadAnchor.x, _deadAnchor.y, 0f);
            InkText.SetAlpha(_moneyLabel, 0f);
            InkText.SetAlpha(_deadLabel, 0f);
            _readoutShown = false;
        }

        private void UpdateReadout(long total, int dead)
        {
            if (_moneyLabel == null) return;
            if (Climbing)
            {
                _moneyLabel.text = "$" + total.ToString("#,0", CultureInfo.InvariantCulture) + " to every soul alive";
                long handed = total * _worldPopulation;
                _deadLabel.text = "$" + handed.ToString("#,0", CultureInfo.InvariantCulture) + " handed out, none of it yours";
            }
            else
            {
                _moneyLabel.text = "$" + total.ToString("#,0", CultureInfo.InvariantCulture);
                _deadLabel.text = dead + " dead";
            }
            if (!_readoutShown)
            {
                _readoutShown = true;
                StartCoroutine(FadeReadout(1f));
            }
        }

        private IEnumerator FadeReadout(float target)
        {
            float t = 0f, f = Mathf.Max(_readoutFade, 0.01f);
            float from0 = _moneyLabel != null ? _moneyLabel.color.a : 0f;
            while (t < f)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from0, target, t / f);
                if (_moneyLabel != null) InkText.SetAlpha(_moneyLabel, a);
                if (_deadLabel != null) InkText.SetAlpha(_deadLabel, a);
                yield return null;
            }
            if (_moneyLabel != null) InkText.SetAlpha(_moneyLabel, target);
            if (_deadLabel != null) InkText.SetAlpha(_deadLabel, target);
        }

        private void TeardownReadout()
        {
            if (_moneyLabel != null) { Destroy(_moneyLabel.gameObject); _moneyLabel = null; }
            if (_deadLabel != null) { Destroy(_deadLabel.gameObject); _deadLabel = null; }
        }
    }
}
