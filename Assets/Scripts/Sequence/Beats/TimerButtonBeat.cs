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
    /// The Timer (Chapter 2, beat 3): a single button with a rule the imp states plainly. Press it and
    /// nothing happens to you, ever; if you do not press it within ten seconds, nothing happens either.
    /// The imp swears there is a catch and refuses to say what, then a visible countdown begins and he
    /// needles the player about the catch he will not name. Whatever the player does, nothing actually
    /// happens, that is the point: after a press or after the timer expires, the reveal is that nothing
    /// happened either way, and the imp mocks whichever they did (pressed out of fear, or froze in the
    /// unknown), never grading, just enjoying it.
    ///
    /// Self contained: it owns its minimal ink button and countdown, and reuses the shared narrator,
    /// the StatsView (a seeded press vs wait split), and the silent Profile. No death, no real
    /// consequence, no station. DilemmaStage/DilemmaRunner stay generic; this is another beat in order.
    /// </summary>
    public sealed class TimerButtonBeat : SequenceBeat
    {
        [Header("Timer")]
        [Tooltip("How long the countdown runs, in seconds.")]
        [SerializeField] private float _seconds = 10f;

        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the countdown/label (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The button (minimal ink)")]
        [SerializeField] private Vector2 _buttonPosition = new Vector2(0f, -0.3f);
        [SerializeField] private float _buttonRadius = 0.85f;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private Color _buttonInk = Palette.Ink;
        [Tooltip("The button brightens to the amber attention accent on hover.")]
        [SerializeField] private Color _buttonHot = Palette.Amber;
        [SerializeField] private string _buttonLabel = "press";
        [SerializeField] private float _buttonLabelSize = 2.6f;
        [SerializeField] private int _sortingOrder = 14;

        [Header("The countdown number")]
        [SerializeField] private Vector2 _countAnchor = new Vector2(0f, 2.1f);
        [SerializeField] private float _countSize = 6.5f;
        [SerializeField] private Color _countColor = Palette.Ink;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _pressSeed = 64;
        [SerializeField] private int _waitSeed = 36;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _pressLabel = "pressed it";
        [SerializeField] private string _waitLabel = "sat on their hands";

        [Header("Profile (silent; risk vs safety, light)")]
        [Tooltip("Recorded on the risk-vs-safety axis. Pressing (acting to end the unknown) leans safety (positive); waiting (sitting in the unknown) leans risk (negative). See MoralAxis.")]
        [SerializeField] private float _riskNudge = 0.2f;

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The rule, stated plainly. He swears there is a catch and will not say what.")]
        [SerializeField, TextArea(2, 5)] private string[] _ruleLines = new[]
        {
            "New game. One button. Press it and nothing happens to you. Not now, not ever.",
            "Do not press it, let the [amber]ten seconds[/amber] run out, and nothing happens either. There is a catch. Oh, there is absolutely a catch. I am simply not going to tell you what it is. Clock starts now.",
        };
        [Tooltip("Needling during the countdown, about the catch he will not name. Shown in order, evenly spaced. Choice independent.")]
        [SerializeField, TextArea(2, 3)] private string[] _needleLines = new[]
        {
            "You are really going to want to think about this one.",
            "The catch. You are forgetting about the catch.",
            "Tick. Tick. Whatever will you do.",
            "Half gone. No pressure.",
            "Last chance to be clever about it.",
        };
        [Tooltip("Reveal after a press: nothing happened, and he mocks that they pressed. Never graded.")]
        [SerializeField, TextArea(2, 5)] private string _pressedReveal =
            "You pressed it. And nothing happened. Nothing was ever going to happen. There was no catch, there was just you, jabbing a button because you could not stand not knowing.";
        [Tooltip("Reveal after the timer expires: nothing happened, and he mocks that they froze. Never graded.")]
        [SerializeField, TextArea(2, 5)] private string _waitedReveal =
            "Time. And nothing happened. Nothing was ever going to happen. There was no catch, there was just you, frozen stiff over a button that did nothing, sweating out ten whole seconds of your endless death.";

        [Header("Timing")]
        [SerializeField] private float _revealHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _buttonFade = 0.35f;

        private Camera _cam;
        private GameObject _buttonRoot;
        private LineRenderer _buttonOutline;
        private TextMeshPro _buttonText;
        private TextMeshPro _countText;

        public override IEnumerator Play(SequenceContext ctx)
        {
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            // The imp states the rule (and swears there is a catch he will not name). Each setup line
            // finishes typing AND lands with a click to continue before the next, so the last one ("clock
            // starts now") is never cut off mid-sentence by the countdown and needling starting.
            if (_ruleLines != null)
            {
                for (int i = 0; i < _ruleLines.Length; i++)
                {
                    if (string.IsNullOrEmpty(_ruleLines[i])) continue;
                    ctx.Narrator.Show(_ruleLines[i]);
                    while (ctx.Narrator.IsShowing) yield return null;
                    yield return WaitAdvance(_advanceLockout);
                }
            }

            // Only now, with the setup fully delivered and acknowledged, does the clock begin.
            BuildButton();
            BuildCountdown();

            // The countdown, the needling, and the press all run together.
            float remaining = Mathf.Max(0.1f, _seconds);
            float total = remaining;
            int nextNeedle = 0;
            int needleCount = _needleLines != null ? _needleLines.Length : 0;
            bool pressed = false;

            while (remaining > 0f && !pressed)
            {
                remaining -= Time.deltaTime;
                SetCountdown(Mathf.CeilToInt(Mathf.Max(0f, remaining)));

                bool hot = OverButton();
                ApplyButtonVisual(hot);
                if (PressRequested(hot)) { pressed = true; break; }

                // Needle lines, evenly spaced across the countdown, in order, non-blocking.
                if (nextNeedle < needleCount)
                {
                    float dueAt = (nextNeedle + 1) * (total / (needleCount + 1));
                    if ((total - remaining) >= dueAt)
                    {
                        if (!string.IsNullOrEmpty(_needleLines[nextNeedle])) ctx.Narrator.Show(_needleLines[nextNeedle]);
                        nextNeedle++;
                    }
                }
                yield return null;
            }

            SetCountdown(0);
            ctx.Narrator.Clear();
            yield return FadeButton(0f);
            TeardownButton();

            // Whatever they did, nothing happened. The imp mocks whichever, never grading.
            ctx.Narrator.Show(pressed ? _pressedReveal : _waitedReveal);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_revealHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            // Silent profile nudge: acting on the unknown (press) vs sitting in it (wait).
            ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.RiskVsSafety, pressed ? _riskNudge : -_riskNudge) });

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            float max = Mathf.Max(1, Mathf.Max(_pressSeed, _waitSeed));
            report.MaxValue = max;
            report.Bars.Add(new StatBar(_pressLabel, _pressSeed, pressed));
            report.Bars.Add(new StatBar(_waitLabel, _waitSeed, !pressed));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private bool OverButton()
        {
            if (_cam == null || _buttonRoot == null) return false;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            Vector2 c = _buttonRoot.transform.position;   // real world position, not the local anchor
            return ((Vector2)wp - c).sqrMagnitude <= _buttonRadius * _buttonRadius;
        }

        private bool PressRequested(bool hot)
        {
            if (hot && PointerInput.Clicked) return true;
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null && (kb.spaceKey.wasPressedThisFrame || kb.enterKey.wasPressedThisFrame || kb.digit1Key.wasPressedThisFrame))
                return true;
#endif
            return false;
        }

        private void BuildButton()
        {
            _buttonRoot = new GameObject("TimerButton");
            _buttonRoot.transform.SetParent(transform, false);
            _buttonRoot.transform.localPosition = new Vector3(_buttonPosition.x, _buttonPosition.y, 0f);

            _buttonOutline = InkLine.Create(_buttonRoot.transform, "Outline", _inkMaterial, _lineWidth, _buttonInk, _sortingOrder);
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _buttonRadius, 0f, 360f, 40);
            InkLine.SetPoints(_buttonOutline, ring);
            if (_buttonOutline.gameObject.GetComponent<LineBoil>() == null) _buttonOutline.gameObject.AddComponent<LineBoil>().Capture();

            _buttonText = InkText.Create(_buttonRoot.transform, "Label", _buttonLabelSize, _buttonInk, TextAlignmentOptions.Center, _sortingOrder + 1);
            if (_font != null) _buttonText.font = _font;
            _buttonText.rectTransform.sizeDelta = new Vector2(_buttonRadius * 2.2f, 1f);
            _buttonText.transform.localPosition = Vector3.zero;
            _buttonText.text = Localization.Localize(_buttonLabel);
        }

        private void ApplyButtonVisual(bool hot)
        {
            if (_buttonOutline == null) return;
            Color c = hot ? _buttonHot : _buttonInk;
            InkLine.SetColor(_buttonOutline, c);
            _buttonOutline.widthMultiplier = _lineWidth * (hot ? 1.3f : 1f);
            if (_buttonText != null) _buttonText.color = c;
        }

        private void BuildCountdown()
        {
            _countText = InkText.Create(transform, "Countdown", _countSize, _countColor, TextAlignmentOptions.Center, _sortingOrder + 1);
            if (_font != null) _countText.font = _font;
            _countText.rectTransform.sizeDelta = new Vector2(4f, 2.5f);
            _countText.transform.localPosition = new Vector3(_countAnchor.x, _countAnchor.y, 0f);
            SetCountdown(Mathf.CeilToInt(_seconds));
        }

        private void SetCountdown(int value)
        {
            if (_countText != null) _countText.text = Localization.Number(value);
        }

        private IEnumerator FadeButton(float target)
        {
            float t = 0f, f = Mathf.Max(_buttonFade, 0.01f);
            float startA = 1f;
            while (t < f)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(startA, target, t / f);
                if (_buttonOutline != null) InkLine.SetAlpha(_buttonOutline, _buttonOutline.startColor, a);
                if (_buttonText != null) InkText.SetAlpha(_buttonText, a);
                if (_countText != null) InkText.SetAlpha(_countText, a);
                yield return null;
            }
        }

        private void TeardownButton()
        {
            if (_buttonRoot != null) { Destroy(_buttonRoot); _buttonRoot = null; }
            if (_countText != null) { Destroy(_countText.gameObject); _countText = null; }
            _buttonOutline = null;
            _buttonText = null;
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
