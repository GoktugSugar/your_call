using System.Collections;
using UnityEngine;
using TMPro;

namespace YourCall
{
    /// <summary>
    /// The Better Offer (Chapter 2, a button with a golden-crowned figure reveal). Press it and the
    /// player's life is swapped for the best life any human has actually lived, but they become that
    /// person completely: no memories, no self. Perfect happiness, but not theirs.
    ///
    /// Presentation: it first inks in the best-life person as a GOLDEN crowned <see cref="CrownedFigure"/>
    /// (gold = the best life, see art-and-ui.md) while the imp sells how great this life is, then presents
    /// the choice, take their life (become them, lose yourself) or keep your own (the one that ended drunk
    /// behind the wheel). Whatever they choose, the imp mocks either way (you erased yourself for a
    /// stranger's bliss, or you clung to your sad little self), choice independent, never graded. Minimal,
    /// in the ink style: a gentle figure consequence, then a seeded split. Profile: a light, silent nudge
    /// on self vs others (clinging to your own identity vs dissolving into another).
    ///
    /// Self contained, reusing the shared ChoiceButtons, StatsView, silent Profile, and the Figure ink
    /// in / fold. Another beat the SequencePlayer plays in order.
    /// </summary>
    public sealed class BetterOfferBeat : SequenceBeat
    {
        [Header("References")]
        [Tooltip("The golden crowned figure prefab (a CrownedFigure). The beat gold-brands it.")]
        [SerializeField] private CrownedFigure _crownedPrefab;
        [Tooltip("Shared ink material for the pressable button.")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the button label (unused while the button is unlabelled).")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The golden figure")]
        [SerializeField] private Vector2 _figurePosition = new Vector2(0f, -0.6f);
        [SerializeField] private float _figureScale = 1.7f;
        [SerializeField] private Color _goldColor = Palette.InkGold;
        [SerializeField] private float _inkInDuration = 0.9f;

        [Header("The button (pressable ink; press it to take the swap)")]
        [Tooltip("Beside the golden figure, clear of it. Pressing it takes the better life (the same as the Take text option).")]
        [SerializeField] private Vector2 _buttonPosition = new Vector2(2.7f, 0.3f);
        [SerializeField] private float _buttonRadius = 0.7f;
        [SerializeField] private float _buttonLineWidth = 0.055f;
        [SerializeField] private int _buttonSorting = 14;
        [SerializeField] private float _buttonFadeIn = 0.4f;
        [SerializeField] private float _buttonFadeOut = 0.35f;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _takeSeed = 37;
        [SerializeField] private int _keepSeed = 63;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _takeStatLabel = "took the better life";
        [SerializeField] private string _keepStatLabel = "kept their own";

        [Header("Profile (silent, light; self vs others / identity)")]
        [Tooltip("Recorded on self-vs-others. Keeping your own self leans self (negative); dissolving into another leans away from self (positive). First pass; see open-questions.md.")]
        [SerializeField] private float _identityNudge = 0.08f;

        [Header("Copy (the imp; no dashes; the crash hook stays light)")]
        [Tooltip("The sell, shown in order, a click between each. The golden figure inks in during the first line.")]
        [SerializeField, TextArea(2, 5)] private string[] _sellLines = new[]
        {
            "Different button. Look at this one first.",
            "There. That is the best life a human being has ever actually lived. Every door opened. Every love returned. Not one day of it wasted. A [gold]golden[/gold] little existence, first breath to last.",
            "Press the button and you become this person. Completely. Their memories, their joy, all of it yours.",
            "But not you. [amber]You[/amber] would be gone. No trace left. The happy one over there would not be the man who ended drunk behind the wheel. It would be them. Flawless, and not yours.",
            "So. Take the best life anyone has ever had and stop being you. Or keep your own, the one that ended in a ditch, and stay exactly who you are. Choose.",
        };
        [Tooltip("Aftermath if they take the swap. Choice independent, never graded.")]
        [SerializeField, TextArea(3, 6)] private string _tookReact =
            "Gone. You traded yourself away for a stranger's paradise. Somewhere a person is perfectly, endlessly happy, and it is not you, because there is no more you to enjoy it. You wiped out a whole self just to stop being the one you were. I do hope it was worth it. You will not be around to say.";
        [Tooltip("Aftermath if they keep their own. Choice independent, never graded.")]
        [SerializeField, TextArea(3, 6)] private string _keptReact =
            "You kept it. Your own grubby little life, the one that drove itself into a wall. Flawless, endless happiness on offer, and you said no, because it would not have been [amber]yours[/amber]. You clung to being you, right down to the drink and the wreck. Sentimental. Or vain. I can never tell the two apart, and neither can you.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _takeLabel = "Take their life";
        [SerializeField] private string _keepLabel = "Keep your own";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _drainDuration = 0.7f;   // take: the gold drains to ink (you become them)
        [SerializeField] private float _fadeDuration = 1.1f;    // the figure gently inks out
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private CrownedFigure _figure;
        private InkButton _button;
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Choices == null)
            {
                Debug.LogError("[BetterOfferBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }
            if (_crownedPrefab == null)
            {
                Debug.LogError("[BetterOfferBeat] '" + Note + "' is missing its crowned figure prefab.");
                yield break;
            }

            // Build the golden crowned figure, hidden, ready to ink in on the sell's second line.
            _figure = Instantiate(_crownedPrefab, transform);
            _figure.name = "BestLife";
            _figure.transform.localPosition = new Vector3(_figurePosition.x, _figurePosition.y, 0f);
            _figure.transform.localScale = new Vector3(_figureScale, _figureScale, 1f);
            _figure.Build();
            _figure.Brand(_goldColor);       // gold = the best life (crown included)
            _figure.SetInkAlpha(0f);

            if (_sellLines != null)
            {
                for (int i = 0; i < _sellLines.Length; i++)
                {
                    if (string.IsNullOrEmpty(_sellLines[i])) continue;
                    ctx.Narrator.Show(_sellLines[i]);
                    if (i == 1) StartCoroutine(InkFigureIn(_inkInDuration));   // reveal it as he names it
                    while (ctx.Narrator.IsShowing) yield return null;
                    yield return WaitAdvance(_advanceLockout);
                }
            }
            ctx.Narrator.Clear();

            // The button to press: the swap trigger, beside the golden figure.
            _button = InkButton.Create(transform, "BetterButton", new Vector3(_buttonPosition.x, _buttonPosition.y, 0f),
                _inkMaterial, _font, _buttonRadius, _buttonLineWidth, string.Empty, 2.6f, _buttonSorting, innerRing: true);
            yield return _button.FadeIn(_buttonFadeIn);

            // The choice: press the button (take the swap), or keep your own via the text option.
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            _button.Pressed += OnButtonPressed;
            _button.Arm(true);
            ctx.Choices.Present(_takeLabel, _keepLabel);
            try { while (_picked < 0) yield return null; }
            finally { ctx.Choices.Chosen -= OnPicked; ctx.Choices.Dismiss(); _button.Pressed -= OnButtonPressed; _button.Arm(false); }
            bool took = _picked == 0;

            // The button has done its job; fade it away before the consequence plays out.
            yield return _button.FadeOut(_buttonFadeOut);
            if (_button != null) { Destroy(_button.gameObject); _button = null; }

            // Silent profile nudge (self vs others / identity): keep leans self, take leans away from self.
            ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.SelfVsOthers, took ? _identityNudge : -_identityNudge) });

            // A gentle consequence, scaled to the weight: on taking, the gold drains to plain ink (you
            // become them, the specialness is no longer theirs) and then it fades; on keeping, the offered
            // life simply inks away.
            ctx.Narrator.Show(took ? _tookReact : _keptReact);
            if (took) yield return DrainGold(_drainDuration);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return FadeFigureOut(_fadeDuration);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
            if (_figure != null) Destroy(_figure.gameObject);

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_takeSeed, _keepSeed));
            report.Bars.Add(new StatBar(_takeStatLabel, _takeSeed, took));
            report.Bars.Add(new StatBar(_keepStatLabel, _keepSeed, !took));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }
        private void OnButtonPressed() { if (_picked < 0) _picked = 0; }

        private IEnumerator InkFigureIn(float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                if (_figure != null) _figure.SetInkAlpha(EaseUtil.OutCubic(t / d));
                yield return null;
            }
            if (_figure != null) _figure.SetInkAlpha(1f);
        }

        private IEnumerator DrainGold(float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                if (_figure != null) _figure.Brand(Color.Lerp(_goldColor, Palette.Ink, EaseUtil.OutCubic(t / d)));
                yield return null;
            }
            if (_figure != null) _figure.Brand(Palette.Ink);
        }

        private IEnumerator FadeFigureOut(float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                if (_figure != null) _figure.SetInkAlpha(1f - EaseUtil.OutCubic(t / d));
                yield return null;
            }
            if (_figure != null) _figure.SetInkAlpha(0f);
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
