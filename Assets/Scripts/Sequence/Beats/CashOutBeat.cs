using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The cash-out finish (Chapter 3's closer). Whatever money is left buys exactly one final thing: the
    /// imp lays out a menu of what the remaining <see cref="MoneyBalance"/> can afford, cheap junk if the
    /// player blew it, something meaningful if they saved. The player picks one (spends) or refuses and
    /// keeps the money for nothing. Then the imp reads them, what they spent, hoarded, and bought, folds it
    /// silently into the <see cref="Profile"/>, and points toward the ending (never scoring).
    ///
    /// Self contained: it draws the menu in ink with coloured item doodles (reusing InkDoodle), owns its
    /// own N-item pick, spends through the balance, and reveals a seeded split. The last beat of the money
    /// chapter; the SequencePlayer fades to black after it. DilemmaStage / the sequence stay generic.
    /// </summary>
    public sealed class CashOutBeat : SequenceBeat
    {
        [Serializable]
        public sealed class CashOutItem
        {
            [Tooltip("The item name (localized). No dashes.")]
            public string Name = "a boiled sweet";
            [Tooltip("Its price in dollars. Only items the player can afford are shown.")]
            public int Price = 3;
            [Tooltip("Its coloured-outline ink doodle.")]
            public DoodleKind Doodle = DoodleKind.Candy;
        }

        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The menu (cheap first, meaningful last). Only affordable items are shown.")]
        [SerializeField] private List<CashOutItem> _items = new List<CashOutItem>
        {
            new CashOutItem { Name = "a boiled sweet",        Price = 3,    Doodle = DoodleKind.Candy },
            new CashOutItem { Name = "a pack of smokes",      Price = 25,   Doodle = DoodleKind.CigarettePack },
            new CashOutItem { Name = "one ice cream",         Price = 80,   Doodle = DoodleKind.ConeSwirl },
            new CashOutItem { Name = "a proper meal",         Price = 200,  Doodle = DoodleKind.Burrito },
            new CashOutItem { Name = "one perfect afternoon", Price = 1500, Doodle = DoodleKind.Sun },
            new CashOutItem { Name = "a moment that matters", Price = 5000, Doodle = DoodleKind.Star },
        };
        [Tooltip("Most items to show at once (the dearest affordable ones).")]
        [SerializeField] private int _maxShown = 4;

        [Header("Layout")]
        [SerializeField] private float _rowY = 0.7f;
        [SerializeField] private float _span = 7.2f;
        [SerializeField] private float _doodleScale = 0.95f;
        [SerializeField] private float _nameY = -0.8f;
        [SerializeField] private float _priceY = -1.25f;
        [SerializeField] private float _labelSize = 2.4f;
        [SerializeField] private float _priceSize = 2.6f;
        [SerializeField] private int _sorting = 14;
        [SerializeField] private Vector2 _pickHalfExtents = new Vector2(1.15f, 1.7f);
        [Tooltip("The refuse (keep the money) label position.")]
        [SerializeField] private Vector2 _refusePos = new Vector2(0f, -2.7f);
        [SerializeField] private Vector2 _refuseHalfExtents = new Vector2(3f, 0.5f);

        [Header("Feel")]
        [SerializeField] private float _fadeIn = 0.4f;
        [SerializeField] private float _fadeOut = 0.35f;
        [SerializeField] private float _hoverScale = 1.1f;
        [SerializeField, Range(0f, 1f)] private float _restLabelAlpha = 0.8f;

        [Header("Consequence flourish (amber ink burst on a buy)")]
        [SerializeField] private Color _flourishColor = Palette.Amber;
        [SerializeField] private float _flourishRadius = 0.8f;
        [SerializeField, Range(3, 24)] private int _flourishStrokes = 10;
        [SerializeField] private float _flourishWidth = 0.05f;
        [SerializeField] private float _flourishDuration = 0.6f;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _spentSeed = 64;
        [SerializeField] private int _keptSeed = 36;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _spentLabel = "spent the last of it";
        [SerializeField] private string _keptLabel = "kept it for nothing";

        [Header("Profile (silent, light; self vs others). Hoarding leans self.")]
        [SerializeField] private MoralAxis _profileAxis = MoralAxis.SelfVsOthers;
        [SerializeField] private float _hoardNudgeScale = 0.2f;

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The imp presents the menu. {0} = the money left.")]
        [SerializeField, TextArea(2, 5)] private string _menuPitch =
            "Last stop. You have [amber]{0}[/amber] left, and it is no use to a dead man. So. One last thing, on me. Whatever it stretches to. Pick something, or do not.";
        [Tooltip("If nothing is affordable (they are flat broke). {0} = the money left (near zero).")]
        [SerializeField, TextArea(2, 5)] private string _brokePitch =
            "Last stop. You have [amber]{0}[/amber]. Which buys precisely nothing. Not even the sweet. There is nothing to offer you, so let us just look at what you did.";
        [Tooltip("Mock the pick. Choice independent, never graded. {0} = the item.")]
        [SerializeField, TextArea(2, 5)] private string _pickReact =
            "{0}. Out of everything, that was the thing. Of course it was. It says more than you know.";
        [Tooltip("Mock refusing (keep the money for nothing). Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _refuseReact =
            "Nothing. You would rather keep a number you cannot spend than let me buy you one small kindness. Clutching an empty wallet all the way out. Perfect.";

        [Tooltip("The read when they spent most of it. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _readBlew =
            "You spent nearly all of it, and fast. A man who cannot hold onto a thing, money, a marriage, a lane in the road. I did watch you empty yourself out here, and I think we both learned what you reach for.";
        [Tooltip("The read when they hoarded most of it.")]
        [SerializeField, TextArea(2, 6)] private string _readHoard =
            "You kept nearly all of it. Dead, in a void, no pockets, no tomorrow, and still you would not let a single dollar go. That is not thrift. That is a man who counts. You always were counting, up there on the bench.";
        [Tooltip("The read when they spent a middling amount.")]
        [SerializeField, TextArea(2, 6)] private string _readMiddle =
            "Some spent, some kept. You weighed every one of these, did you not. Never all in, never all out. I have a very clear picture of you now, clearer than you would like.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _refuseLabel = "Keep the money";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _readHold = 0.5f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private Camera _cam;
        private readonly List<InkDoodle> _doodles = new List<InkDoodle>();
        private readonly List<TextMeshPro> _names = new List<TextMeshPro>();
        private readonly List<TextMeshPro> _prices = new List<TextMeshPro>();
        private readonly List<CashOutItem> _shown = new List<CashOutItem>();
        private TextMeshPro _refuse;
        private readonly List<float> _hover = new List<float>();
        private float _refuseHover;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Money == null || ctx.Choices == null)
            {
                Debug.LogError("[CashOutBeat] '" + Note + "' needs the MoneyBalance and ChoiceButtons.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            int hoarded = ctx.Money.Balance;                 // captured before the final purchase
            int starting = Mathf.Max(1, ctx.Money.StartingAmount);
            PickShownItems(hoarded);

            bool anyAffordable = _shown.Count > 0;
            ctx.Narrator.Show(Localization.Format(anyAffordable ? _menuPitch : _brokePitch, Localization.Money(hoarded)));
            while (ctx.Narrator.IsShowing) yield return null;

            int picked = -1;   // index into _shown, or -1 for refuse (also the broke default)
            if (anyAffordable)
            {
                BuildMenu();
                yield return FadeMenu(0f, 1f, _fadeIn);
                int result = -1;
                yield return RunPick(v => result = v);
                picked = result;
            }

            bool bought = picked >= 0;
            ctx.Narrator.Clear();

            if (bought)
            {
                var item = _shown[picked];
                ctx.Money.Spend(item.Price);
                SpawnFlourish(picked);
                yield return new WaitForSeconds(_flourishDuration * 0.5f);
                yield return Say(ctx, Localization.Format(_pickReact, Localization.Localize(item.Name)));
            }
            else if (anyAffordable)
            {
                yield return Say(ctx, Localization.Localize(_refuseReact));
            }

            if (anyAffordable) yield return FadeMenu(1f, 0f, _fadeOut);
            TeardownMenu();

            // The read: what they spent vs hoarded (silent profile), pointing toward the ending.
            float hoardRatio = Mathf.Clamp01(hoarded / (float)starting);
            ctx.Profile.Record(new[] { new AxisImpact(_profileAxis, -hoardRatio * _hoardNudgeScale) });

            string read = hoardRatio >= 0.8f ? _readHoard : (hoardRatio <= 0.2f ? _readBlew : _readMiddle);
            yield return new WaitForSeconds(_readHold);
            yield return Say(ctx, Localization.Localize(read));

            // How others chose (spent the last of it vs kept it).
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_spentSeed, _keptSeed));
            report.Bars.Add(new StatBar(_spentLabel, _spentSeed, bought));
            report.Bars.Add(new StatBar(_keptLabel, _keptSeed, !bought));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // ---------- choose which items to show ----------

        private void PickShownItems(int balance)
        {
            _shown.Clear();
            var affordable = new List<CashOutItem>();
            for (int i = 0; i < _items.Count; i++)
                if (_items[i] != null && _items[i].Price <= balance) affordable.Add(_items[i]);
            // Show the dearest affordable ones (the best they can get), keeping menu order.
            int max = Mathf.Max(1, _maxShown);
            int start = Mathf.Max(0, affordable.Count - max);
            for (int i = start; i < affordable.Count; i++) _shown.Add(affordable[i]);
        }

        // ---------- the N-item pick ----------

        private IEnumerator RunPick(Action<int> onPicked)
        {
            int picked = -2;
            while (picked == -2)
            {
                int hover = HoverIndex();   // 0..n-1 item, -1 refuse region, -2 none
                for (int i = 0; i < _hover.Count; i++)
                    _hover[i] = Mathf.MoveTowards(_hover[i], hover == i ? 1f : 0f, Time.deltaTime / 0.1f);
                _refuseHover = Mathf.MoveTowards(_refuseHover, hover == -1 ? 1f : 0f, Time.deltaTime / 0.1f);
                ApplyHover();

                if (hover != -2 && PointerInput.Clicked) { picked = hover; break; }
                int key = KeyIndex();
                if (key != -2) { picked = key; break; }
                yield return null;
            }
            onPicked(picked);
        }

        private int HoverIndex()
        {
            if (_cam == null) return -2;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            for (int i = 0; i < _shown.Count; i++)
                if (InRegion(wp, ItemX(i, _shown.Count), (_rowY + _nameY) * 0.5f, _pickHalfExtents)) return i;
            if (InRegion(wp, _refusePos.x, _refusePos.y, _refuseHalfExtents)) return -1;
            return -2;
        }

        private bool InRegion(Vector3 wp, float cx, float cy, Vector2 half)
        {
            Vector2 c = transform.TransformPoint(new Vector3(cx, cy, 0f));
            return Mathf.Abs(wp.x - c.x) <= half.x && Mathf.Abs(wp.y - c.y) <= half.y;
        }

        private int KeyIndex()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null)
            {
                if (kb.digit1Key.wasPressedThisFrame && _shown.Count > 0) return 0;
                if (kb.digit2Key.wasPressedThisFrame && _shown.Count > 1) return 1;
                if (kb.digit3Key.wasPressedThisFrame && _shown.Count > 2) return 2;
                if (kb.digit4Key.wasPressedThisFrame && _shown.Count > 3) return 3;
                if (kb.digit0Key.wasPressedThisFrame || kb.escapeKey.wasPressedThisFrame) return -1;
            }
#endif
            return -2;
        }

        private float ItemX(int i, int n)
        {
            if (n <= 1) return 0f;
            float t = i / (float)(n - 1);
            return Mathf.Lerp(-_span * 0.5f, _span * 0.5f, t);
        }

        // ---------- build / teardown ----------

        private void BuildMenu()
        {
            int n = _shown.Count;
            for (int i = 0; i < n; i++)
            {
                var item = _shown[i];
                float x = ItemX(i, n);
                Color col = InkDoodle.DefaultColorFor(item.Doodle);
                var d = InkDoodle.Create(transform, "Item" + i, new Vector3(x, _rowY, 0f), _doodleScale,
                    item.Doodle, _inkMaterial, col, _flourishWidth, _sorting);
                _doodles.Add(d);
                StartCoroutine(d.FadeIn(_fadeIn));

                var name = MakeLabel("Name" + i, new Vector3(x, _nameY, 0f), item.Name, _labelSize, Palette.Ink);
                _names.Add(name);
                var price = MakeLabel("Price" + i, new Vector3(x, _priceY, 0f), Localization.Money(item.Price), _priceSize, Palette.Amber);
                _prices.Add(price);
                _hover.Add(0f);
            }
            _refuse = MakeLabel("Refuse", new Vector3(_refusePos.x, _refusePos.y, 0f), _refuseLabel, _labelSize, Palette.Muted);
        }

        private TextMeshPro MakeLabel(string name, Vector3 localPos, string text, float size, Color color)
        {
            var t = InkText.Create(transform, name, size, color, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) t.font = _font;
            t.rectTransform.sizeDelta = new Vector2(3.2f, 1.2f);
            t.enableWordWrapping = true;
            t.transform.localPosition = localPos;
            t.text = Localization.Localize(text);
            InkText.SetAlpha(t, 0f);
            return t;
        }

        private void ApplyHover()
        {
            for (int i = 0; i < _doodles.Count; i++)
            {
                float s = _doodleScale * Mathf.Lerp(1f, _hoverScale, _hover[i]);
                if (_doodles[i] != null) _doodles[i].transform.localScale = new Vector3(s, s, 1f);
                if (i < _names.Count) InkText.SetAlpha(_names[i], Mathf.Lerp(_restLabelAlpha, 1f, _hover[i]));
                if (i < _prices.Count) InkText.SetAlpha(_prices[i], Mathf.Lerp(_restLabelAlpha, 1f, _hover[i]));
            }
            if (_refuse != null) InkText.SetAlpha(_refuse, Mathf.Lerp(_restLabelAlpha, 1f, _refuseHover));
        }

        private void SpawnFlourish(int i)
        {
            if (_inkMaterial == null || i < 0 || i >= _shown.Count) return;
            Vector3 at = transform.TransformPoint(new Vector3(ItemX(i, _shown.Count), _rowY, 0f));
            InkPoof.Spawn(at, _inkMaterial, _flourishColor, _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _sorting + 3);
        }

        private IEnumerator FadeMenu(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                for (int i = 0; i < _doodles.Count; i++) if (_doodles[i] != null) _doodles[i].SetAlpha(a);
                for (int i = 0; i < _names.Count; i++) InkText.SetAlpha(_names[i], a * _restLabelAlpha);
                for (int i = 0; i < _prices.Count; i++) InkText.SetAlpha(_prices[i], a * _restLabelAlpha);
                if (_refuse != null) InkText.SetAlpha(_refuse, a * _restLabelAlpha);
                yield return null;
            }
        }

        private void TeardownMenu()
        {
            foreach (var d in _doodles) if (d != null) Destroy(d.gameObject);
            foreach (var t in _names) if (t != null) Destroy(t.gameObject);
            foreach (var t in _prices) if (t != null) Destroy(t.gameObject);
            if (_refuse != null) Destroy(_refuse.gameObject);
            _doodles.Clear(); _names.Clear(); _prices.Clear(); _hover.Clear();
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
