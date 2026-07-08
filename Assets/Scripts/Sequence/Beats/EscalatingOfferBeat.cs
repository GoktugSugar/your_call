using System.Collections;
using System.Globalization;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Price of a Life (Chapter 2, beat 2): a single button offer that returns, halving, all
    /// the way down. Press it and a running money total grows while a random stranger folds; refuse
    /// at any point and the offer ends (the imp mocks where you stopped, choice independent, never
    /// graded). The imp stays completely business as usual the whole descent, so the break lands: if
    /// the player accepts at the very bottom (one dollar, tunable), the imp DROPS THE ACT, rages with
    /// genuine disgust, and quits, then the credits roll. That break is the game's third choice
    /// triggered secret ending and the one sanctioned exception to the mocking rule (with the baby and
    /// shoot the imp).
    ///
    /// Self contained: it loops the tiers itself (start amount, halving factor and rage threshold all
    /// exposed) and reuses the shared choice affordance, the Figure fold and fall, the StatsView, the
    /// silent Profile, and the reusable Ending + CreditsRoll. DilemmaStage/DilemmaRunner stay generic;
    /// this is just another beat the SequencePlayer plays in order.
    /// </summary>
    public sealed class EscalatingOfferBeat : SequenceBeat
    {
        [Header("Tiers")]
        [Tooltip("The first offer, in dollars. Each acceptance re-offers at Halve Factor of the previous amount.")]
        [SerializeField] private int _startAmount = 100000;
        [SerializeField, Range(0.1f, 0.9f)] private float _halveFactor = 0.5f;
        [Tooltip("Accepting at or below this amount (in dollars) fires the rage-quit ending. Must be at least 1.")]
        [SerializeField] private int _rageThreshold = 1;

        [Header("References")]
        [Tooltip("The ordinary stranger who folds on each acceptance (reuses the shared Figure fold-and-fall).")]
        [SerializeField] private Figure _figurePrefab;
        [Tooltip("The reusable ending fired when the player accepts at the rage threshold (the imp breaks, fades, then the credits roll).")]
        [SerializeField] private Ending _ending;
        [Tooltip("Optional font for the on-screen money/body-count readout (Caveat, to match the narration). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The stranger")]
        [SerializeField] private Vector2 _strangerPosition = new Vector2(0f, -0.7f);
        [SerializeField] private float _strangerScale = 1.15f;
        [Tooltip("A beat the stranger stands before folding, so the eye registers the life.")]
        [SerializeField] private float _strangerHold = 0.35f;
        [SerializeField] private float _foldDuration = 0.7f;
        [SerializeField] private float _foldSettle = 0.3f;

        [Header("Running readout (money amber, the dead red; the colour mapping)")]
        [SerializeField] private Vector2 _moneyAnchor = new Vector2(0f, 2.7f);
        [SerializeField] private float _moneySize = 3.4f;
        [SerializeField] private Vector2 _deadAnchor = new Vector2(0f, 1.95f);
        [SerializeField] private float _deadSize = 2.3f;
        [SerializeField] private int _sortingOrder = 16;
        [SerializeField] private float _readoutFade = 0.4f;

        [Header("Crowd split (seeded; the take rate drops as the amount drops)")]
        [Tooltip("Seeded percentage who took the money at the top amount.")]
        [SerializeField, Range(0f, 100f)] private float _topAcceptancePct = 61f;
        [Tooltip("Seeded percentage who took the money at one dollar (almost no one).")]
        [SerializeField, Range(0f, 100f)] private float _floorAcceptancePct = 2f;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _tookLabel = "took the money";
        [SerializeField] private string _walkedLabel = "walked away";

        [Header("Profile (silent; self vs others, nudged by how far they descend)")]
        [Tooltip("Recorded on the self-vs-others axis per acceptance. Negative leans self (see MoralAxis). Kept light.")]
        [SerializeField] private float _selfNudgePerAccept = -0.12f;

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The offer, business as usual. {0} is the amount, e.g. $100,000.")]
        [SerializeField, TextArea(2, 4)] private string _offerFormat =
            "Here. One button. Press it and [amber]{0}[/amber] is yours, and somewhere a stranger you will never meet folds up and [red]dies[/red]. Or do not, and we stop. Your call.";
        [Tooltip("Business-as-usual egging after each acceptance (indexed by body count, holding on the last). Never grades the choice.")]
        [SerializeField, TextArea(2, 3)] private string[] _eggLines = new[]
        {
            "Done. That was easy, was it not.",
            "And again. You are quick, I will give you that.",
            "Mm. Keep going. We have all the time in the world down here.",
            "Barely a flicker that time.",
            "Look at you go.",
        };
        [Tooltip("Mock where they stopped when they refuse. {0} is the amount they would not take. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _refuseReact =
            "And there it is. [amber]{0}[/amber] was the number you would not go below. Everyone has one. Now I know yours.";
        [Tooltip("The rage-quit break line (real disgust, the act dropped; the sanctioned exception). No dashes.")]
        [SerializeField, TextArea(3, 6)] private string _breakLine =
            "[red]A person.[/red] You just killed a person. For [amber]one dollar[/amber]. One. I am not doing the voice for this one. There is nothing funny here, nothing, and I find everything funny. You are a greedy piece of shit and I am done with you. Go and rot. I quit.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _acceptLabel = "Press it";
        [SerializeField] private string _refuseLabel = "Refuse";

        [Header("Timing")]
        [SerializeField] private float _postAcceptBeat = 0.35f;
        [Tooltip("Auto-advance the business-as-usual egging line (so the descent keeps rolling), instead of waiting for a click.")]
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

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_figurePrefab == null)
            {
                Debug.LogError("[EscalatingOfferBeat] '" + Note + "' is missing its figure prefab.");
                yield break;
            }
            if (ctx.Choices == null)
            {
                Debug.LogError("[EscalatingOfferBeat] '" + Note + "' needs the shared ChoiceButtons (accept / refuse).");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;
            BuildReadout();

            int threshold = Mathf.Max(1, _rageThreshold);
            int amount = Mathf.Max(threshold, _startAmount);
            long total = 0;
            int dead = 0;

            ctx.Choices.Chosen += OnPicked;
            try
            {
                while (true)
                {
                    // Present the offer, business as usual, then arm accept / refuse.
                    _picked = -1;
                    ctx.Narrator.Show(string.Format(_offerFormat, Money(amount)));
                    while (ctx.Narrator.IsShowing) yield return null;
                    ctx.Choices.Present(_acceptLabel, _refuseLabel);
                    while (_picked < 0) yield return null;

                    if (_picked == 1)
                    {
                        // Refused: the offer ends. The imp mocks where they stopped (choice independent,
                        // never graded), then how others chose at this price, matching the reaction-then-stats
                        // rhythm of the normal loop. Then the run moves on.
                        ctx.Narrator.Clear();
                        ctx.Narrator.Show(string.Format(_refuseReact, Money(amount)));
                        while (ctx.Narrator.IsShowing) yield return null;
                        yield return WaitAdvance(_advanceLockout);
                        ctx.Narrator.Clear();
                        yield return RevealCrowdSplit(ctx, amount);
                        break;
                    }

                    // Accepted: a stranger folds, the money is banked, the body count ticks up.
                    ctx.Narrator.Clear();
                    yield return KillStranger(ctx);
                    total += amount;
                    dead += 1;
                    UpdateReadout(total, dead);
                    ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.SelfVsOthers, _selfNudgePerAccept) });
                    yield return new WaitForSeconds(_postAcceptBeat);

                    if (amount <= threshold)
                    {
                        // Sold a life for a dollar: the imp drops the act, rages, and quits.
                        yield return RageQuit(ctx);
                        yield break;   // the credits reload the scene; we never return
                    }

                    // Business as usual: a light egging line, no grading, then the offer returns halved.
                    // It auto-advances so the descent keeps rolling and the imp reads as unbothered.
                    string egg = EggLine(dead);
                    if (!string.IsNullOrEmpty(egg))
                    {
                        ctx.Narrator.Show(egg);
                        while (ctx.Narrator.IsShowing) yield return null;
                        if (_eggAutoAdvance) yield return new WaitForSeconds(_eggHold);
                        else yield return WaitAdvance(_advanceLockout);
                    }
                    ctx.Narrator.Clear();
                    amount = Mathf.Max(1, Mathf.FloorToInt(amount * _halveFactor));
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
            float took = AcceptPctFor(amount);
            var report = new ResolutionReport { Heading = _statsHeading, MaxValue = 100f };
            report.Bars.Add(new StatBar(_tookLabel, Mathf.Round(took), false));
            report.Bars.Add(new StatBar(_walkedLabel, Mathf.Round(100f - took), true)); // the player walked away
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
                // No ending wired: at least deliver the break so the beat is not silent.
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

        // Seeded take rate for a tier: interpolated on a log scale from the top amount to one dollar,
        // so it drops smoothly as the amount drops (many take the big money, almost no one the dollar).
        private float AcceptPctFor(int amount)
        {
            float top = Mathf.Max(1, _startAmount);
            float a = Mathf.Clamp(amount, 1, (int)top);
            float t = 1f;
            if (top > 1f) t = 1f - (Mathf.Log(a) / Mathf.Log(top));   // 0 at the top amount, 1 at a dollar
            return Mathf.Lerp(_topAcceptancePct, _floorAcceptancePct, Mathf.Clamp01(t));
        }

        private string EggLine(int dead)
        {
            if (_eggLines == null || _eggLines.Length == 0) return null;
            return _eggLines[Mathf.Clamp(dead - 1, 0, _eggLines.Length - 1)];
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
            _deadLabel = InkText.Create(transform, "BodyCount", _deadSize, Palette.InkRed, TextAlignmentOptions.Center, _sortingOrder);
            if (_font != null) { _moneyLabel.font = _font; _deadLabel.font = _font; }
            _moneyLabel.rectTransform.sizeDelta = new Vector2(9f, 1.4f);
            _deadLabel.rectTransform.sizeDelta = new Vector2(9f, 1.2f);
            _moneyLabel.transform.localPosition = new Vector3(_moneyAnchor.x, _moneyAnchor.y, 0f);
            _deadLabel.transform.localPosition = new Vector3(_deadAnchor.x, _deadAnchor.y, 0f);
            InkText.SetAlpha(_moneyLabel, 0f);
            InkText.SetAlpha(_deadLabel, 0f);
            _readoutShown = false;
        }

        private void UpdateReadout(long total, int dead)
        {
            if (_moneyLabel == null) return;
            _moneyLabel.text = "$" + total.ToString("#,0", CultureInfo.InvariantCulture);
            _deadLabel.text = dead + " dead";
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
