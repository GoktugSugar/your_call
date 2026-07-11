using System;
using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The finite money pot for Chapter 3 (the money): a starting pile the player spends down as they buy
    /// the priceable things, or keeps by passing. It shows a running BALANCE on screen from the start and
    /// rides along the whole chapter like the crowd stat does elsewhere (see docs/gameplay.md, docs/tech.md).
    ///
    /// Part display, part tiny service: it holds the balance, spends / refunds / tests affordability, and
    /// draws the amber readout (amber = money, per the colour mapping). The money beats (PriceableBeat, the
    /// poverty refund, AuctionBeat, the cash-out) read and spend through this one instance, handed to them
    /// on the <see cref="SequenceContext"/> so they stay decoupled from how the chapter is wired. It is a
    /// chapter-scoped scene object, not a persistent service; other chapters carry none and are unaffected.
    /// One job: be the pot and show it.
    /// </summary>
    public sealed class MoneyBalance : MonoBehaviour
    {
        [Header("Pot")]
        [Tooltip("The starting pile, in dollars. Finite: End Poverty costs exactly this, everything else spends from it.")]
        [SerializeField] private int _startingAmount = 10000;

        [Header("Readout (amber = money; rides along the whole chapter)")]
        [Tooltip("Optional font (Caveat, to match the narration). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;
        [SerializeField] private Vector2 _anchor = new Vector2(0f, 4.15f);
        [SerializeField] private float _captionSize = 2.1f;
        [SerializeField] private float _amountSize = 3.7f;
        [SerializeField] private int _sortingOrder = 16;
        [SerializeField] private float _fadeIn = 0.6f;
        [SerializeField] private float _startDelay = 0.2f;
        [Tooltip("The small caption above the amount. Localized.")]
        [SerializeField] private string _caption = "balance";
        [Tooltip("Padding for the imp keep-out around the readout, so the roaming imp never sits on it.")]
        [SerializeField] private float _keepoutPadding = 0.4f;

        [Header("Change feedback")]
        [Tooltip("A short bump when the balance changes, so a spend or refund reads.")]
        [SerializeField] private float _bumpScale = 1.16f;
        [SerializeField] private float _bumpTime = 0.24f;

        /// <summary>Raised after the balance changes (a spend or a refund).</summary>
        public event Action BalanceChanged;

        public int StartingAmount => _startingAmount;
        public int Balance { get; private set; }
        public bool IsBroke => Balance <= 0;

        private TextMeshPro _captionLabel;
        private TextMeshPro _amount;
        private bool _built;
        private Coroutine _bump;

        private void Awake()
        {
            Balance = Mathf.Max(0, _startingAmount);
            Build();
            Localization.LanguageChanged += Refresh;
        }

        private void OnDestroy()
        {
            Localization.LanguageChanged -= Refresh;
        }

        private void Start()
        {
            StartCoroutine(FadeInRoutine());
        }

        /// <summary>Can the player afford this price right now?</summary>
        public bool CanAfford(int price) => price >= 0 && Balance >= price;

        /// <summary>Spend up to the balance; returns the amount actually taken (clamped so it never goes
        /// negative). End Poverty spends exactly the whole pot; the auction can spend the player broke.</summary>
        public int Spend(int amount)
        {
            int taken = Mathf.Clamp(amount, 0, Balance);
            if (taken <= 0) { return 0; }
            Balance -= taken;
            AfterChange();
            return taken;
        }

        /// <summary>Give money back (the poverty refund, or a returned bid).</summary>
        public void Refund(int amount)
        {
            if (amount <= 0) return;
            Balance += amount;
            AfterChange();
        }

        /// <summary>Set the balance directly, for the save system restoring a resumed run (see
        /// <see cref="SaveService"/>). Refreshes the readout without a spend/refund bump or event, since this
        /// is a silent restore, not an in-game transaction.</summary>
        public void SetBalance(int amount)
        {
            Balance = Mathf.Max(0, amount);
            Refresh();
        }

        private void AfterChange()
        {
            Refresh();
            Bump();
            BalanceChanged?.Invoke();
        }

        // ---------- readout ----------

        private void Build()
        {
            if (_built) return;
            _captionLabel = InkText.Create(transform, "BalanceCaption", _captionSize, Palette.Muted, TextAlignmentOptions.Center, _sortingOrder);
            _amount = InkText.Create(transform, "BalanceAmount", _amountSize, Palette.Amber, TextAlignmentOptions.Center, _sortingOrder);
            if (_font != null) { _captionLabel.font = _font; _amount.font = _font; }
            _captionLabel.rectTransform.sizeDelta = new Vector2(6f, 1f);
            _amount.rectTransform.sizeDelta = new Vector2(8f, 1.4f);
            _captionLabel.transform.localPosition = new Vector3(_anchor.x, _anchor.y + 0.6f, 0f);
            _amount.transform.localPosition = new Vector3(_anchor.x, _anchor.y, 0f);
            InkText.SetAlpha(_captionLabel, 0f);
            InkText.SetAlpha(_amount, 0f);
            Refresh();

            // Keep the roaming imp off the readout (it lives at the top all chapter).
            var keepout = gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);
            _built = true;
        }

        private void Refresh()
        {
            if (_captionLabel != null) _captionLabel.text = Localization.Localize(_caption);
            if (_amount != null) _amount.text = Localization.Money(Balance);
        }

        private IEnumerator FadeInRoutine()
        {
            if (_startDelay > 0f) yield return new WaitForSeconds(_startDelay);
            float t = 0f, d = Mathf.Max(_fadeIn, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Clamp01(t / d);
                if (_captionLabel != null) InkText.SetAlpha(_captionLabel, a);
                if (_amount != null) InkText.SetAlpha(_amount, a);
                yield return null;
            }
            if (_captionLabel != null) InkText.SetAlpha(_captionLabel, 1f);
            if (_amount != null) InkText.SetAlpha(_amount, 1f);
        }

        private void Bump()
        {
            if (_amount == null) return;
            if (_bump != null) StopCoroutine(_bump);
            _bump = StartCoroutine(BumpRoutine());
        }

        private IEnumerator BumpRoutine()
        {
            float d = Mathf.Max(_bumpTime, 0.02f), t = 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = Mathf.Sin(Mathf.Clamp01(t / d) * Mathf.PI);
                float s = Mathf.Lerp(1f, _bumpScale, k);
                _amount.transform.localScale = new Vector3(s, s, 1f);
                yield return null;
            }
            _amount.transform.localScale = Vector3.one;
        }
    }
}
