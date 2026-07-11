using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The one mid-chapter buyback beat (Chapter 3, the money): the imp offers to REPURCHASE things the
    /// player has already bought, handing money back to the balance so a player who overspent early can
    /// recover, and forcing a real value question, did you want the thing, or only the having of it. It
    /// lists the currently-owned items (from the run's <see cref="PurchaseLedger"/>) with their coloured
    /// doodles and the buyback amount offered, and walks each one, letting the player sell it back (the
    /// money returns, the item is given up) or keep it. The imp mocks either way, choice independent, never
    /// grading.
    ///
    /// It also ABSORBS the poverty refund: if the player ended poverty in the opener, ending poverty is one
    /// entry in this list (detected by its doodle), with its own dark framing, sell it back and the children
    /// starve again for the money. So there is ONE buyback system and poverty is one entry in it, not a
    /// separate beat. Buyback amounts are data (a fraction of what was paid, poverty its own). Reuses the
    /// MoneyBalance, the PurchaseLedger, InkDoodle / InkText, the narrator, the ChoiceButtons and the
    /// silent Profile; one job, decoupled. If the player owns nothing, a quick remark and it skips.
    /// </summary>
    public sealed class BuybackBeat : SequenceBeat
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private TMP_FontAsset _font;

        [Header("Buyback amounts (data; a fraction of what was paid)")]
        [Tooltip("Buyback offer for a normal item, as a fraction of what the player paid (0.5 = half back; the imp keeps the rest, so selling is a genuine loss and a real value question).")]
        [SerializeField, Range(0f, 1f)] private float _buybackFraction = 0.5f;
        [Tooltip("Buyback offer for ending poverty, as a fraction of what it cost (1 = the whole pot back, matching the old refund: hand it all back, the children starve again).")]
        [SerializeField, Range(0f, 1f)] private float _povertyBuybackFraction = 1f;
        [Tooltip("Round buyback offers to this step so amounts stay clean.")]
        [SerializeField] private int _roundTo = 10;

        [Header("Layout (world space; the list sits above the dialogue box)")]
        [SerializeField] private float _rowsTop = 2.7f;
        [SerializeField] private float _rowHeight = 0.6f;
        [SerializeField] private float _doodleX = -3.4f;
        [SerializeField] private float _rowDoodleScale = 0.44f;
        [SerializeField] private float _nameX = -2.6f;
        [SerializeField] private float _priceX = 3.6f;
        [SerializeField] private float _nameSize = 2.4f;
        [SerializeField] private float _priceSize = 2.5f;
        [SerializeField] private int _sorting = 15;
        [SerializeField, Range(0f, 1f)] private float _dimAlpha = 0.5f;
        [SerializeField] private float _keepoutPadding = 0.5f;

        [Header("Copy (the imp; no dashes). {0} = item name, {1} = money where noted.")]
        [SerializeField, TextArea(2, 6)] private string _offerIntro =
            "Second thoughts? Here is how it works. I will buy back anything you have already bought. Not for what you paid, I am not a charity, but for something. The real question is whether you wanted the thing, or only wanted the having of it. Sell me back whatever you no longer need.";
        [Tooltip("If they own nothing at the buyback point (bought nothing yet, or nothing they regret).")]
        [SerializeField, TextArea(2, 4)] private string _emptyRemark =
            "Nothing to sell back. You have bought nothing, or nothing you regret yet. Give it time. On we go.";
        [Tooltip("Offer a normal item. {0} = item name, {1} = buyback amount.")]
        [SerializeField, TextArea(1, 3)] private string _sellPrompt =
            "{0}. I will hand you [amber]{1}[/amber] back for it. Sell it, or keep it.";
        [Tooltip("Mock selling a normal item. {0} = item name.")]
        [SerializeField, TextArea(2, 5)] private string _sellReact =
            "Sold, just like that. So you never wanted it, you wanted to have wanted it. There is a difference, and I have just watched you find it.";
        [Tooltip("Mock keeping a normal item. {0} = item name.")]
        [SerializeField, TextArea(2, 4)] private string _keepReact =
            "Kept it. You would rather have the thing than the money. Noted. That is the whole game, really.";

        [Header("Poverty (the folded-in refund). {1} = the buyback amount (the whole pot).")]
        [SerializeField, TextArea(2, 5)] private string _povertySellPrompt =
            "And this one. You ended poverty, the whole grand gesture. I can undo it. Every hungry child back to hungry, and [amber]{1}[/amber] straight back into your pocket, all of it. Sell the good deed, or keep it.";
        [SerializeField, TextArea(2, 5)] private string _povertySellReact =
            "And back it comes, every penny, and the children starve again. That charity of yours lasted, what, half a chapter. I knew you had a price on other people; I just did not think it was this cheap.";
        [SerializeField, TextArea(2, 5)] private string _povertyKeepReact =
            "You kept it ended. Broke, maybe, and you kept it. Either a genuinely good man, or you could not stand to look like a bad one in front of me. I still cannot tell, and that is the fun of you.";

        [Header("Closing")]
        [SerializeField, TextArea(2, 5)] private string _closeSold =
            "There. What you sold back, and what you could not let go of. That tells me more than the buying did. It always does.";
        [SerializeField, TextArea(2, 5)] private string _closeKeptAll =
            "Sold nothing. Not one thing. Either you meant every purchase, or you cannot bear to admit a mistake to me. Either way, you keep the lot.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _sellLabel = "Sell it back";
        [SerializeField] private string _keepLabel = "Keep it";

        [Header("Profile (silent, light; self vs others). Selling back leans self.")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [SerializeField] private float _sellNudge = -0.05f;
        [SerializeField] private float _povertySellNudge = -0.14f;
        [SerializeField] private float _povertyKeepNudge = 0.14f;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _soldSeed = 44;
        [SerializeField] private int _keptSeed = 56;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _soldLabel = "sold something back";
        [SerializeField] private string _keptLabel = "kept it all";

        [Header("Timing")]
        [SerializeField] private float _fadeIn = 0.5f;
        [SerializeField] private float _fadeOut = 0.5f;
        [SerializeField] private float _rowFade = 0.35f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private sealed class Row
        {
            public InkDoodle Doodle;
            public TextMeshPro Name;
            public TextMeshPro Price;
            public PurchaseLedger.Entry Entry;
            public bool Poverty;
            public int Offer;
            public void SetAlpha(float a)
            {
                if (Doodle != null) Doodle.SetAlpha(a);
                if (Name != null) InkText.SetAlpha(Name, a);
                if (Price != null) InkText.SetAlpha(Price, a);
            }
        }

        private readonly List<Row> _rows = new List<Row>();
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null || ctx.Ledger == null || ctx.Choices == null)
            {
                Debug.LogError("[BuybackBeat] '" + Note + "' needs the MoneyBalance, PurchaseLedger and ChoiceButtons.");
                yield break;
            }

            // Snapshot what they own right now (the loop below mutates the ledger as they sell).
            var owned = new List<PurchaseLedger.Entry>(ctx.Ledger.Bought);
            if (owned.Count == 0)
            {
                yield return Say(ctx, _emptyRemark);
                yield break;
            }

            BuildRows(owned);
            var keepout = gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);
            yield return FadeRows(0f, _dimAlpha, _fadeIn);
            yield return Say(ctx, _offerIntro);

            int sold = 0;
            ctx.Choices.Chosen += OnPicked;
            try
            {
                for (int i = 0; i < _rows.Count; i++)
                {
                    var row = _rows[i];
                    row.SetAlpha(1f);   // highlight the one being offered

                    string name = Localization.Localize(row.Entry.Name);
                    string prompt = row.Poverty
                        ? Localization.Format(_povertySellPrompt, name, Localization.Money(row.Offer))
                        : Localization.Format(_sellPrompt, name, Localization.Money(row.Offer));
                    ctx.Narrator.Show(prompt);
                    while (ctx.Narrator.IsShowing) yield return null;

                    _picked = -1;
                    ctx.Choices.Present(_sellLabel, _keepLabel);
                    while (_picked < 0) yield return null;
                    ctx.Choices.Dismiss();
                    ctx.Narrator.Clear();

                    bool sell = _picked == 0;
                    if (sell)
                    {
                        ctx.Money.Refund(row.Offer);                 // money back to the balance (bumps the readout)
                        ctx.Ledger.RemoveBought(row.Entry.Name);     // they no longer own it
                        ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, row.Poverty ? _povertySellNudge : _sellNudge) });
                        sold++;
                        StartCoroutine(FadeRowOut(row));             // it is gone
                        yield return Say(ctx, row.Poverty ? Localization.Localize(_povertySellReact) : Localization.Format(_sellReact, name));
                    }
                    else
                    {
                        if (row.Poverty) ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, _povertyKeepNudge) });
                        row.SetAlpha(_dimAlpha);                     // dim it back, still owned
                        yield return Say(ctx, row.Poverty ? Localization.Localize(_povertyKeepReact) : Localization.Format(_keepReact, name));
                    }
                }
            }
            finally { ctx.Choices.Chosen -= OnPicked; ctx.Choices.Dismiss(); }

            yield return Say(ctx, sold > 0 ? Localization.Localize(_closeSold) : Localization.Localize(_closeKeptAll));
            yield return RevealSplit(ctx, sold > 0);
            yield return FadeRows(_dimAlpha, 0f, _fadeOut);   // fade whatever is left
            Teardown();
        }

        // ---------- build ----------

        private void BuildRows(List<PurchaseLedger.Entry> owned)
        {
            float y = _rowsTop;
            for (int i = 0; i < owned.Count; i++)
            {
                var e = owned[i];
                bool poverty = e.Doodle == DoodleKind.Poverty;
                float frac = poverty ? _povertyBuybackFraction : _buybackFraction;
                var row = new Row { Entry = e, Poverty = poverty, Offer = OfferFor(e.Amount, frac) };

                row.Doodle = InkDoodle.Create(transform, "Doodle" + i, new Vector3(_doodleX, y, 0f), _rowDoodleScale,
                    e.Doodle, _inkMaterial, InkDoodle.DefaultColorFor(e.Doodle), 0.05f, _sorting);

                string name = string.IsNullOrEmpty(e.Name) ? string.Empty : Localization.Localize(e.Name);
                if (e.Count > 1) name = name + " x" + e.Count;
                row.Name = MakeText("Name" + i, new Vector3(_nameX, y, 0f), name, _nameSize, Palette.Ink, TextAlignmentOptions.Left, 5.6f);
                row.Price = MakeText("Price" + i, new Vector3(_priceX, y, 0f), Localization.Money(row.Offer), _priceSize, Palette.Amber, TextAlignmentOptions.Right, 3f);

                row.SetAlpha(0f);
                _rows.Add(row);
                y -= _rowHeight;
            }
        }

        private int OfferFor(int paid, float frac)
        {
            int step = Mathf.Max(1, _roundTo);
            int raw = Mathf.RoundToInt(paid * Mathf.Clamp01(frac));
            int rounded = Mathf.RoundToInt(raw / (float)step) * step;
            return Mathf.Max(step, rounded);
        }

        private TextMeshPro MakeText(string name, Vector3 localPos, string text, float size, Color color, TextAlignmentOptions align, float width)
        {
            var t = InkText.Create(transform, name, size, color, align, _sorting + 1);
            if (_font != null) t.font = _font;
            t.rectTransform.sizeDelta = new Vector2(width, 1f);
            t.transform.localPosition = localPos;
            t.text = text;
            InkText.SetAlpha(t, 0f);
            return t;
        }

        // ---------- flow helpers ----------

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        private IEnumerator Say(SequenceContext ctx, string line)
        {
            ctx.Narrator.Show(line);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
        }

        private IEnumerator RevealSplit(SequenceContext ctx, bool soldSomething)
        {
            if (ctx.Stats == null) yield break;
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_soldSeed, _keptSeed));
            report.Bars.Add(new StatBar(_soldLabel, _soldSeed, soldSomething));
            report.Bars.Add(new StatBar(_keptLabel, _keptSeed, !soldSomething));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private IEnumerator FadeRows(float from, float to, float dur)
        {
            float d = Mathf.Max(dur, 0.01f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                for (int i = 0; i < _rows.Count; i++) _rows[i].SetAlpha(a);
                yield return null;
            }
            for (int i = 0; i < _rows.Count; i++) _rows[i].SetAlpha(to);
        }

        private IEnumerator FadeRowOut(Row row)
        {
            float d = Mathf.Max(_rowFade, 0.01f), t = 0f;
            while (t < d) { t += Time.deltaTime; row.SetAlpha(1f - t / d); yield return null; }
            row.SetAlpha(0f);
        }

        private void Teardown()
        {
            for (int i = 0; i < _rows.Count; i++)
            {
                if (_rows[i].Doodle != null) Destroy(_rows[i].Doodle.gameObject);
                if (_rows[i].Name != null) Destroy(_rows[i].Name.gameObject);
                if (_rows[i].Price != null) Destroy(_rows[i].Price.gameObject);
            }
            _rows.Clear();
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
