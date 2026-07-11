using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The end-of-chapter overview / receipt (Chapter 3, the money): after the cucumber finale, a summary
    /// screen that reads the run back using the item doodles. It reads the run's <see cref="PurchaseLedger"/>
    /// and the <see cref="MoneyBalance"/> and draws, in the hand-drawn ink style, a receipt: what the player
    /// BOUGHT (each with its small coloured doodle and what they paid, multi-buys shown with a count), the
    /// money summary (started / spent / left), and a light row of what they notably SKIPPED. The imp gives a
    /// short closing read over it (choice independent, mocking, never grading), folded silently into the
    /// <see cref="Profile"/>. Built as its own beat, reusing InkDoodle / InkText / InkLine / the narrator /
    /// the Profile; scoped to Chapter 3 but reusable in spirit (a future chapter could show its own summary).
    /// </summary>
    public sealed class ChapterOverview : SequenceBeat
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private TMP_FontAsset _font;

        [Header("Layout (world space; the receipt sits above the dialogue box)")]
        [SerializeField] private float _titleY = 3.9f;
        [SerializeField] private float _rowsTop = 3.1f;
        [SerializeField] private float _rowHeight = 0.5f;
        [Tooltip("Most bought rows shown at full size; any extras collapse into an 'and N more' line.")]
        [SerializeField] private int _maxRows = 6;
        [SerializeField] private float _doodleX = -3.5f;
        [SerializeField] private float _rowDoodleScale = 0.42f;
        [SerializeField] private float _nameX = -2.8f;
        [SerializeField] private float _priceX = 3.7f;
        [SerializeField] private float _nameSize = 2.3f;
        [SerializeField] private float _labelSize = 2.4f;
        [SerializeField] private float _titleSize = 2.9f;
        [SerializeField] private float _summaryGap = 0.42f;
        [SerializeField] private int _sorting = 15;
        [Tooltip("Most skipped items shown (the dearest ones the player passed on). 0 hides the passed-on row.")]
        [SerializeField] private int _maxSkipped = 4;
        [SerializeField] private float _skippedDoodleScale = 0.32f;
        [SerializeField] private float _skippedSpan = 4.6f;
        [SerializeField] private float _keepoutPadding = 0.5f;

        [Header("Copy (the imp; no dashes). {0} = a money amount or count.")]
        [SerializeField] private string _titleText = "the receipt";
        [SerializeField] private string _startedLabel = "started with {0}";
        [SerializeField] private string _spentLabel = "spent {0}";
        [SerializeField] private string _leftLabel = "left with {0}";
        [SerializeField] private string _nothingBought = "you bought nothing at all";
        [SerializeField] private string _moreLine = "and {0} more";
        [SerializeField] private string _passedCaption = "passed on";

        [Header("The imp's read over the receipt (choice independent, feeds the profile, no grading)")]
        [Tooltip("Read when they spent most of it.")]
        [SerializeField, TextArea(2, 6)] private string _readBlew =
            "There it is, in ink. You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. Cash does not hide who a person is, it shows it, and this little receipt shows me plenty.";
        [Tooltip("Read when they hoarded most of it.")]
        [SerializeField, TextArea(2, 6)] private string _readHoard =
            "Look at that. You kept nearly all of it. Dead, in a void, no pockets, no tomorrow, and still you would not let a single dollar go. That is not thrift, that is a man who counts. The receipt is almost blank, and it still tells me everything.";
        [Tooltip("Read when they spent a middling amount.")]
        [SerializeField, TextArea(2, 6)] private string _readMiddle =
            "Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. Here it is, itemised. Cash does not hide who a person is, and I have a very clear picture of you now, clearer than you would like.";

        [Header("Profile (silent, light; self vs others). Hoarding leans self.")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [SerializeField] private float _hoardNudgeScale = 0.2f;
        [SerializeField, Range(0.5f, 1f)] private float _hoardThreshold = 0.8f;
        [SerializeField, Range(0f, 0.5f)] private float _blewThreshold = 0.2f;

        [Header("Timing")]
        [SerializeField] private float _fadeIn = 0.6f;
        [SerializeField] private float _fadeOut = 0.6f;
        [SerializeField] private float _preReadHold = 0.5f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;

        private readonly List<InkDoodle> _doodles = new List<InkDoodle>();
        private readonly List<TextMeshPro> _texts = new List<TextMeshPro>();
        private readonly List<LineRenderer> _rules = new List<LineRenderer>();

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null || ctx.Ledger == null)
            {
                Debug.LogError("[ChapterOverview] '" + Note + "' needs the MoneyBalance and the PurchaseLedger (money chapter only).");
                yield break;
            }

            int started = ctx.Money.StartingAmount;
            int left = ctx.Money.Balance;
            int spent = Mathf.Max(0, started - left);
            float hoardRatio = started > 0 ? Mathf.Clamp01(left / (float)started) : 0f;

            BuildReceipt(ctx, started, spent, left);
            var keepout = gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);   // keep the roaming imp off the receipt
            yield return FadeAll(0f, 1f, _fadeIn);

            if (_preReadHold > 0f) yield return new WaitForSeconds(_preReadHold);

            // The imp reads over the receipt, and the read feeds the silent profile (hoarding leans self).
            ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, -hoardRatio * _hoardNudgeScale) });
            string read = hoardRatio >= _hoardThreshold ? _readHoard
                        : (hoardRatio <= _blewThreshold ? _readBlew : _readMiddle);
            ctx.Narrator.Show(read);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            yield return FadeAll(1f, 0f, _fadeOut);
            Teardown();
        }

        // ---------- build ----------

        private void BuildReceipt(SequenceContext ctx, int started, int spent, int left)
        {
            MakeText(new Vector3(0f, _titleY, 0f), Localization.Localize(_titleText), _titleSize, Palette.Ink, TextAlignmentOptions.Center, 9f);

            var bought = new List<PurchaseLedger.Entry>(ctx.Ledger.Bought);
            int cap = Mathf.Max(1, _maxRows);
            if (bought.Count > cap) bought.Sort((a, b) => b.Amount.CompareTo(a.Amount));   // dearest first if truncating
            int shown = Mathf.Min(bought.Count, cap);

            float y = _rowsTop;
            if (ctx.Ledger.Bought.Count == 0)
            {
                MakeText(new Vector3(0f, y, 0f), Localization.Localize(_nothingBought), _nameSize, Palette.Muted, TextAlignmentOptions.Center, 9f);
                y -= _rowHeight;
            }
            for (int i = 0; i < shown; i++)
            {
                var e = bought[i];
                MakeDoodle(e.Doodle, new Vector3(_doodleX, y, 0f), _rowDoodleScale);
                string name = string.IsNullOrEmpty(e.Name) ? string.Empty : Localization.Localize(e.Name);
                if (e.Count > 1) name = name + " x" + e.Count;
                MakeText(new Vector3(_nameX, y, 0f), name, _nameSize, Palette.Ink, TextAlignmentOptions.Left, 5.8f);
                MakeText(new Vector3(_priceX, y, 0f), Localization.Money(e.Amount), _labelSize, Palette.Amber, TextAlignmentOptions.Right, 3f);
                y -= _rowHeight;
            }
            if (ctx.Ledger.Bought.Count > shown)
            {
                MakeText(new Vector3(_nameX, y, 0f), Localization.Format(_moreLine, ctx.Ledger.Bought.Count - shown), _nameSize, Palette.Muted, TextAlignmentOptions.Left, 6f);
                y -= _rowHeight;
            }

            // divider, then the money summary
            y -= 0.06f;
            MakeRule(y);
            y -= _summaryGap + 0.1f;
            MakeText(new Vector3(0f, y, 0f), Localization.Format(_startedLabel, Localization.Money(started)), _labelSize, Palette.Muted, TextAlignmentOptions.Center, 9f); y -= _summaryGap;
            MakeText(new Vector3(0f, y, 0f), Localization.Format(_spentLabel, Localization.Money(spent)), _labelSize, Palette.Amber, TextAlignmentOptions.Center, 9f); y -= _summaryGap;
            MakeText(new Vector3(0f, y, 0f), Localization.Format(_leftLabel, Localization.Money(left)), _labelSize, Palette.Amber, TextAlignmentOptions.Center, 9f); y -= _summaryGap + 0.24f;

            // the notable skipped items (dearest few), a lighter row
            var skipped = new List<PurchaseLedger.Entry>(ctx.Ledger.Skipped);
            if (skipped.Count > 0 && _maxSkipped > 0)
            {
                skipped.Sort((a, b) => b.Amount.CompareTo(a.Amount));
                int n = Mathf.Min(skipped.Count, _maxSkipped);
                MakeText(new Vector3(0f, y, 0f), Localization.Localize(_passedCaption), _nameSize * 0.9f, Palette.Muted, TextAlignmentOptions.Center, 9f);
                y -= 0.5f;
                for (int i = 0; i < n; i++)
                {
                    float x = n <= 1 ? 0f : Mathf.Lerp(-_skippedSpan * 0.5f, _skippedSpan * 0.5f, i / (float)(n - 1));
                    MakeDoodle(skipped[i].Doodle, new Vector3(x, y, 0f), _skippedDoodleScale);
                }
            }
        }

        private void MakeDoodle(DoodleKind kind, Vector3 localPos, float scale)
        {
            var d = InkDoodle.Create(transform, "Doodle", localPos, scale, kind, _inkMaterial,
                InkDoodle.DefaultColorFor(kind), 0.05f, _sorting);
            _doodles.Add(d);
        }

        private void MakeText(Vector3 localPos, string text, float size, Color color, TextAlignmentOptions align, float width)
        {
            var t = InkText.Create(transform, "Line", size, color, align, _sorting + 1);
            if (_font != null) t.font = _font;
            t.rectTransform.sizeDelta = new Vector2(width, 1f);
            t.transform.localPosition = localPos;
            t.text = text;
            InkText.SetAlpha(t, 0f);
            _texts.Add(t);
        }

        private void MakeRule(float y)
        {
            var lr = InkLine.Create(transform, "Rule", _inkMaterial, 0.03f, Palette.Muted, _sorting);
            InkLine.SetPoints(lr, new List<Vector3> { new Vector3(_doodleX - 0.2f, y, 0f), new Vector3(_priceX + 0.4f, y, 0f) });
            InkLine.SetAlpha(lr, Palette.Muted, 0f);
            _rules.Add(lr);
        }

        // ---------- fade / teardown ----------

        private IEnumerator FadeAll(float from, float to, float dur)
        {
            float d = Mathf.Max(dur, 0.01f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                ApplyAlpha(a);
                yield return null;
            }
            ApplyAlpha(to);
        }

        private void ApplyAlpha(float a)
        {
            for (int i = 0; i < _doodles.Count; i++) if (_doodles[i] != null) _doodles[i].SetAlpha(a);
            for (int i = 0; i < _texts.Count; i++) if (_texts[i] != null) InkText.SetAlpha(_texts[i], a);
            for (int i = 0; i < _rules.Count; i++) if (_rules[i] != null) InkLine.SetAlpha(_rules[i], Palette.Muted, a);
        }

        private void Teardown()
        {
            for (int i = 0; i < _doodles.Count; i++) if (_doodles[i] != null) Destroy(_doodles[i].gameObject);
            for (int i = 0; i < _texts.Count; i++) if (_texts[i] != null) Destroy(_texts[i].gameObject);
            for (int i = 0; i < _rules.Count; i++) if (_rules[i] != null) Destroy(_rules[i].gameObject);
            _doodles.Clear(); _texts.Clear(); _rules.Clear();
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
