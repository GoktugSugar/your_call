using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One priceable thing in Chapter 3 (the money): the imp offers to sell the player something, buying
    /// spends from the running <see cref="MoneyBalance"/>, passing keeps the money. The shared workhorse of
    /// the chapter, configured entirely by data (the imp's pitch, the thing's name, its price, its coloured
    /// ink doodle, the seeded how-others-chose split, and an optional silent profile nudge), so adding a
    /// priceable beat is a new GameObject with this component plus its doodle, not new code.
    ///
    /// Three modes cover every plain beat and two of the specials:
    ///  - <b>Fixed</b>: a set price (the food, the nose, the extra year, no more pain, the memory, the
    ///    forgetting, the truth about how you died).
    ///  - <b>EntireBalance</b>: the price is exactly the whole current pot (End Poverty, the opener that
    ///    costs everything). It exposes <see cref="Bought"/> and <see cref="AmountSpent"/> for the refund.
    ///  - <b>Bulk</b>: priced per unit, buy as many as you like until you stop or run out (ten years of a
    ///    stranger's life).
    ///
    /// It draws the thing's coloured-outline doodle (a coloured ink line, not a fill; the food doodle can
    /// swap per language, burrito for English, kebab for Turkish) and a price tag, offers buy/pass as plain
    /// text choices (no ink button; the coloured doodle carries the visual), spends through the balance,
    /// plays a light amber ink consequence on a buy, then the seeded reveal. The imp mocks either way
    /// (choice independent, never graded). Reuses InkDoodle, ChoiceButtons, StatsView and the silent
    /// Profile; DilemmaStage / the sequence stay generic.
    /// </summary>
    public sealed class PriceableBeat : SequenceBeat
    {
        public enum PriceMode { Fixed, EntireBalance, Bulk }

        [Header("Mode & price")]
        [SerializeField] private PriceMode _mode = PriceMode.Fixed;
        [Tooltip("Fixed / Bulk price in dollars. Ignored for EntireBalance (that costs exactly the whole pot).")]
        [SerializeField] private int _price = 100;
        [Tooltip("Bulk only: the most units the player may buy (a safety cap).")]
        [SerializeField] private int _bulkMax = 50;

        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the price tag / tally (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The thing (a coloured-outline ink doodle)")]
        [SerializeField] private DoodleKind _doodleKind = DoodleKind.Coin;
        [Tooltip("Optional outline colour override. Alpha 0 (default) uses the doodle's own matched colour (InkDoodle.DefaultColorFor).")]
        [SerializeField] private Color _doodleOutline = new Color(0f, 0f, 0f, 0f);
        [SerializeField] private Vector2 _doodlePosition = new Vector2(0f, 0.85f);
        [SerializeField] private float _doodleScale = 1.35f;
        [SerializeField] private int _sorting = 14;
        [Tooltip("Optional: swap the doodle for this one when the active language matches Alt Language (the food beat: burrito for English, kebab for Turkish). None keeps the main doodle.")]
        [SerializeField] private DoodleKind _altDoodleKind = DoodleKind.None;
        [Tooltip("The language code the alt doodle is for, e.g. tr. Empty disables the swap.")]
        [SerializeField] private string _altLanguage = "";

        [Header("The price tag (clear of the visual; amber = money)")]
        [SerializeField] private Vector2 _priceTagPosition = new Vector2(0f, -0.55f);
        [SerializeField] private float _priceTagSize = 3.1f;
        [Tooltip("Format for the price tag. {0} is the money amount. e.g. '{0}' or '{0} a year'.")]
        [SerializeField] private string _priceTagFormat = "{0}";

        [Header("Bulk tally (bulk only)")]
        [SerializeField] private Vector2 _tallyPosition = new Vector2(0f, 2.5f);
        [SerializeField] private float _tallySize = 2.8f;
        [Tooltip("Bulk running tally. {0} is the count so far. e.g. '{0} years taken'.")]
        [SerializeField] private string _tallyFormat = "{0} taken";

        [Header("Crowd split (seeded; how others chose)")]
        [SerializeField] private int _boughtSeed = 40;
        [SerializeField] private int _passedSeed = 60;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _boughtLabel = "bought it";
        [SerializeField] private string _passedLabel = "kept the money";

        [Header("Profile (silent, light; 0 = stats-only)")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [Tooltip("Recorded on the axis when they buy (Bulk: per unit). Sign convention: negative = first pole (e.g. self), positive = second (e.g. others).")]
        [SerializeField] private float _buyNudge = 0f;
        [Tooltip("Recorded on the axis when they pass.")]
        [SerializeField] private float _passNudge = 0f;

        [Header("Copy (the imp; no dashes). {0} = price. {1} = brand (if a brand key is set).")]
        [SerializeField, TextArea(2, 5)] private string _pitch =
            "Here. Something for sale. Yours for [amber]{0}[/amber]. Buy it, or keep your money. Your call.";
        [Tooltip("Optional localized brand term substituted into the pitch as {1} (the food beat: Chipotle for English, its own for each language). Empty means no brand.")]
        [SerializeField] private string _brandKey = "";
        [Tooltip("Mock the buy. Choice independent, never graded. {0} = price. Bulk uses Bulk Stop React instead.")]
        [SerializeField, TextArea(2, 5)] private string _buyReact =
            "Bought. Of course you did. I do so love learning what a man will actually pay for.";
        [Tooltip("Mock the pass. Choice independent, never graded. {0} = price.")]
        [SerializeField, TextArea(2, 5)] private string _passReact =
            "Kept your money. Noted. There is a number in you somewhere; this was not it.";
        [Tooltip("When the player cannot afford it (broke, usually after ending poverty). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _brokeReact =
            "With what, exactly? You have nothing. You gave it all away. You get to just watch this one.";

        [Header("Bulk copy (bulk only)")]
        [Tooltip("Optional business-as-usual line each purchase (auto-advances). {0} = count so far. Empty shows none.")]
        [SerializeField, TextArea(1, 3)] private string _bulkTierLine = "";
        [Tooltip("After they stop buying. {0} = count bought, {1} = total spent.")]
        [SerializeField, TextArea(2, 5)] private string _bulkStopReact =
            "[amber]{0}[/amber] years of some stranger, poured into you. You will not feel a single one of them. Marvellous.";
        [Tooltip("If they buy none at all in a bulk beat.")]
        [SerializeField, TextArea(2, 5)] private string _bulkZeroReact =
            "Not one year. Too squeamish, or too cheap. Either reads the same from here.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _buyLabel = "Buy it";
        [SerializeField] private string _passLabel = "Keep the money";
        [SerializeField] private string _bulkBuyLabel = "Buy one";
        [SerializeField] private string _bulkStopLabel = "Enough";

        [Header("Consequence flourish (amber ink burst on a buy)")]
        [SerializeField] private Color _flourishColor = Palette.Amber;
        [SerializeField] private float _flourishRadius = 0.8f;
        [SerializeField, Range(3, 24)] private int _flourishStrokes = 10;
        [SerializeField] private float _flourishWidth = 0.05f;
        [SerializeField] private float _flourishDuration = 0.6f;

        [Header("Timing")]
        [SerializeField] private float _doodleFadeIn = 0.4f;
        [SerializeField] private float _doodleFadeOut = 0.35f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _bulkTierHold = 1.0f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        /// <summary>Did the player buy this? (Used by the poverty refund to know End Poverty was bought.)</summary>
        public bool Bought { get; private set; }
        /// <summary>How much the player spent here (the whole pot, for End Poverty; total, for bulk).</summary>
        public int AmountSpent { get; private set; }

        private Camera _cam;
        private InkDoodle _doodle;
        private TextMeshPro _priceTag;
        private TextMeshPro _tally;
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null)
            {
                Debug.LogError("[PriceableBeat] '" + Note + "' needs the chapter MoneyBalance (SequencePlayer money slot).");
                yield break;
            }
            if (ctx.Choices == null)
            {
                Debug.LogError("[PriceableBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            int price = _mode == PriceMode.EntireBalance ? ctx.Money.Balance : Mathf.Max(0, _price);
            BuildVisuals(price);
            StartCoroutine(_doodle.FadeIn(_doodleFadeIn));
            yield return FadeTag(0f, 1f, _doodleFadeIn);

            // The imp pitches.
            ctx.Narrator.Show(BuildPitch(price));
            while (ctx.Narrator.IsShowing) yield return null;

            if (_mode == PriceMode.Bulk) yield return RunBulk(ctx, price);
            else yield return RunSingle(ctx, price);

            yield return FadeVisualsOut();
            yield return RevealSplit(ctx);
            Teardown();
        }

        // ---------- single buy / pass (Fixed and EntireBalance) ----------

        private IEnumerator RunSingle(SequenceContext ctx, int price)
        {
            bool affordable = _mode == PriceMode.EntireBalance ? price > 0 : (price <= 0 || ctx.Money.CanAfford(price));
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_buyLabel, _passLabel);
            try
            {
                while (_picked < 0) yield return null;
            }
            finally
            {
                ctx.Choices.Chosen -= OnPicked;
                ctx.Choices.Dismiss();
            }

            bool wantsBuy = _picked == 0;
            ctx.Narrator.Clear();

            if (wantsBuy && !affordable)
            {
                // Broke: he cannot buy. The imp needles it (choice independent), and it resolves as a pass.
                yield return Say(ctx, _brokeReact, price);
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _passNudge) });
                Bought = false;
                yield break;
            }

            if (wantsBuy)
            {
                int spent = ctx.Money.Spend(price);
                AmountSpent = spent;
                Bought = true;
                yield return BuyConsequence();
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _buyNudge) });
                yield return Say(ctx, _buyReact, price);
            }
            else
            {
                Bought = false;
                ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _passNudge) });
                yield return Say(ctx, _passReact, price);
            }
        }

        // ---------- bulk (buy as many as you like) ----------

        private IEnumerator RunBulk(SequenceContext ctx, int price)
        {
            int count = 0;
            BuildTally();
            ctx.Choices.Chosen += OnPicked;
            try
            {
                while (true)
                {
                    bool affordable = ctx.Money.CanAfford(price) && count < Mathf.Max(1, _bulkMax);
                    _picked = -1;
                    ctx.Choices.Present(_bulkBuyLabel, _bulkStopLabel);
                    while (_picked < 0) yield return null;

                    if (_picked == 1) break;                 // stop
                    if (!affordable) { break; }              // cannot buy more: the tally stands, they are done

                    // Buy one unit.
                    int spent = ctx.Money.Spend(price);
                    AmountSpent += spent;
                    count += 1;
                    Bought = true;
                    ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _buyNudge) });
                    UpdateTally(count);
                    StartCoroutine(_doodle.FadeIn(0.01f));   // keep it up
                    SpawnFlourish();

                    if (!string.IsNullOrEmpty(_bulkTierLine))
                    {
                        ctx.Narrator.Clear();
                        ctx.Narrator.Show(Localization.Format(_bulkTierLine, count));
                        while (ctx.Narrator.IsShowing) yield return null;
                        yield return new WaitForSeconds(_bulkTierHold);
                        ctx.Narrator.Clear();
                    }
                }
            }
            finally
            {
                ctx.Choices.Chosen -= OnPicked;
                ctx.Choices.Dismiss();
            }

            ctx.Narrator.Clear();
            if (count > 0) yield return Say(ctx, Localization.Format(_bulkStopReact, count, Localization.Money(AmountSpent)), price, alreadyFormatted: true);
            else { ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _passNudge) }); yield return Say(ctx, _bulkZeroReact, price); }
        }

        // ---------- shared bits ----------

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        private IEnumerator Say(SequenceContext ctx, string line, int price, bool alreadyFormatted = false)
        {
            string shown = alreadyFormatted ? line : Localization.Format(line, Localization.Money(price), BrandOrEmpty());
            ctx.Narrator.Show(shown);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
        }

        private string BuildPitch(int price) => Localization.Format(_pitch, Localization.Money(price), BrandOrEmpty());
        private string BrandOrEmpty() => string.IsNullOrEmpty(_brandKey) ? string.Empty : Localization.Localize(_brandKey);

        private IEnumerator BuyConsequence()
        {
            SpawnFlourish();
            yield return new WaitForSeconds(_flourishDuration * 0.6f);
        }

        private void SpawnFlourish()
        {
            if (_inkMaterial == null) return;
            Vector3 at = transform.TransformPoint(new Vector3(_doodlePosition.x, _doodlePosition.y, 0f));
            InkPoof.Spawn(at, _inkMaterial, _flourishColor, _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _sorting + 3);
        }

        private IEnumerator RevealSplit(SequenceContext ctx)
        {
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_boughtSeed, _passedSeed));
            report.Bars.Add(new StatBar(_boughtLabel, _boughtSeed, Bought));
            report.Bars.Add(new StatBar(_passedLabel, _passedSeed, !Bought));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // ---------- build / teardown ----------

        private void BuildVisuals(int price)
        {
            DoodleKind kind = ChooseDoodle();
            Color col = _doodleOutline.a > 0f ? _doodleOutline : InkDoodle.DefaultColorFor(kind);
            _doodle = InkDoodle.Create(transform, "ItemDoodle", new Vector3(_doodlePosition.x, _doodlePosition.y, 0f),
                _doodleScale, kind, _inkMaterial, col, _flourishWidth, _sorting);

            _priceTag = InkText.Create(transform, "PriceTag", _priceTagSize, Palette.Amber, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) _priceTag.font = _font;
            _priceTag.rectTransform.sizeDelta = new Vector2(8f, 1.2f);
            _priceTag.transform.localPosition = new Vector3(_priceTagPosition.x, _priceTagPosition.y, 0f);
            _priceTag.text = Localization.Format(_priceTagFormat, Localization.Money(price));
            InkText.SetAlpha(_priceTag, 0f);
        }

        private DoodleKind ChooseDoodle()
        {
            if (_altDoodleKind != DoodleKind.None && !string.IsNullOrEmpty(_altLanguage)
                && string.Equals(Localization.CurrentCode, _altLanguage, System.StringComparison.OrdinalIgnoreCase))
                return _altDoodleKind;
            return _doodleKind;
        }

        private void BuildTally()
        {
            _tally = InkText.Create(transform, "Tally", _tallySize, Palette.Amber, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) _tally.font = _font;
            _tally.rectTransform.sizeDelta = new Vector2(10f, 1.2f);
            _tally.transform.localPosition = new Vector3(_tallyPosition.x, _tallyPosition.y, 0f);
            InkText.SetAlpha(_tally, 0f);
        }

        private void UpdateTally(int count)
        {
            if (_tally == null) return;
            _tally.text = Localization.Format(_tallyFormat, count);
            InkText.SetAlpha(_tally, 1f);
        }

        private IEnumerator FadeTag(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                if (_priceTag != null) InkText.SetAlpha(_priceTag, Mathf.Lerp(from, to, t / d));
                yield return null;
            }
            if (_priceTag != null) InkText.SetAlpha(_priceTag, to);
        }

        private IEnumerator FadeVisualsOut()
        {
            if (_doodle != null) StartCoroutine(_doodle.FadeOut(_doodleFadeOut));
            if (_tally != null) StartCoroutine(FadeLabelOut(_tally, _doodleFadeOut));
            yield return FadeTag(1f, 0f, _doodleFadeOut);
        }

        private IEnumerator FadeLabelOut(TextMeshPro t, float dur)
        {
            float from = t.color.a, d = Mathf.Max(dur, 0.01f), e = 0f;
            while (e < d) { e += Time.deltaTime; InkText.SetAlpha(t, Mathf.Lerp(from, 0f, e / d)); yield return null; }
            InkText.SetAlpha(t, 0f);
        }

        private void Teardown()
        {
            if (_doodle != null) Destroy(_doodle.gameObject);
            if (_priceTag != null) Destroy(_priceTag.gameObject);
            if (_tally != null) Destroy(_tally.gameObject);
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
