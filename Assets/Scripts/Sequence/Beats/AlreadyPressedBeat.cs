using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Button You Already Pressed (Chapter 2, a meta beat that hooks the protagonist). The imp
    /// casually claims the player pressed this exact button once before, in life, and that everything
    /// since (the road, the drink, the crash, this room) followed from that one press. He offers to let
    /// the player press it again to change it, or leave it. The player never learns what it does or did.
    ///
    /// Nothing overtly mechanical happens either way: the weight is all in the imp's framing and the
    /// player's dread. Whatever they choose, the imp mocks it (you rolled the dice on your whole
    /// existence, or you were too scared to touch it), choice independent, cryptic, never confirming what
    /// it did. The DUI/crash hook stays light, a glancing reference, not a heavy reveal (see narrative.md).
    ///
    /// Self contained and minimal, in the ink style: a plain ink button, the framing, the choice through
    /// the shared ChoiceButtons, and the mocking aftermath, then a seeded press-vs-leave split. No death,
    /// no station, no profile nudge (stats only). Another beat the SequencePlayer plays in order.
    /// </summary>
    public sealed class AlreadyPressedBeat : SequenceBeat
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the button label (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The button (minimal ink)")]
        [SerializeField] private Vector2 _buttonPosition = new Vector2(0f, 0.2f);
        [SerializeField] private float _buttonRadius = 0.8f;
        [SerializeField] private float _lineWidth = 0.055f;
        [SerializeField] private Color _buttonInk = Palette.Ink;
        [SerializeField] private int _sortingOrder = 14;

        [Header("Crowd split (seeded)")]
        [SerializeField] private int _pressSeed = 44;
        [SerializeField] private int _leaveSeed = 56;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _pressStatLabel = "pressed it again";
        [SerializeField] private string _leaveStatLabel = "left it alone";

        [Header("Copy (the imp; no dashes; cryptic; the crash hook stays light)")]
        [Tooltip("The framing, shown in order, a click between each.")]
        [SerializeField, TextArea(2, 5)] private string[] _framingLines = new[]
        {
            "Now. This one you have seen before.",
            "Not in here. Out there, in the life you had. You stood in front of this exact button once, your hand hovering over it, just like now.",
            "And you pressed it. [amber]Everything[/amber] after was the long slide down from that. The late night, the drink, the headlights, the sudden [red]end[/red] of you. All of it, downstream of one little button.",
            "I can let you press it again. Change it. Or leave it lying exactly where it is. I will not tell you what it does. I never do.",
        };
        [Tooltip("Aftermath if they press. Choice independent, cryptic, never confirms what it did.")]
        [SerializeField, TextArea(3, 6)] private string _pressedReact =
            "You pressed it. Again. You just rolled the dice on your entire existence a second time, with no earthly idea what the dice even were. Bold. Idiotic. My favourite pairing. Did it change a single thing? I will never, ever say.";
        [Tooltip("Aftermath if they leave it. Choice independent, cryptic, never confirms what it did.")]
        [SerializeField, TextArea(3, 6)] private string _leftReact =
            "You left it. Naturally you did. You stood at the one button that might unpick the whole sorry slide, and you could not make your hand close on it. Too frightened of a thing you cannot even name. Did it matter? You will never know.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _pressLabel = "Press it again";
        [SerializeField] private string _leaveLabel = "Leave it";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _buttonFadeIn = 0.45f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;
        [SerializeField] private float _buttonFadeOut = 0.4f;

        private GameObject _buttonRoot;
        private LineRenderer _buttonOutline;
        private LineRenderer _buttonInner;
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Choices == null)
            {
                Debug.LogError("[AlreadyPressedBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }

            BuildButton();
            yield return FadeButton(0f, 1f, _buttonFadeIn);

            // The imp's framing, one box at a time.
            if (_framingLines != null)
            {
                for (int i = 0; i < _framingLines.Length; i++)
                {
                    if (string.IsNullOrEmpty(_framingLines[i])) continue;
                    ctx.Narrator.Show(_framingLines[i]);
                    while (ctx.Narrator.IsShowing) yield return null;
                    yield return WaitAdvance(_advanceLockout);
                }
            }
            ctx.Narrator.Clear();

            // The choice: press it again, or leave it.
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_pressLabel, _leaveLabel);
            try { while (_picked < 0) yield return null; }
            finally { ctx.Choices.Chosen -= OnPicked; }
            bool pressed = _picked == 0;

            // Nothing overtly mechanical: the imp mocks either way, cryptic, never confirming.
            ctx.Narrator.Show(pressed ? _pressedReact : _leftReact);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            yield return FadeButton(1f, 0f, _buttonFadeOut);
            TeardownButton();

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_pressSeed, _leaveSeed));
            report.Bars.Add(new StatBar(_pressStatLabel, _pressSeed, pressed));
            report.Bars.Add(new StatBar(_leaveStatLabel, _leaveSeed, !pressed));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        private void BuildButton()
        {
            _buttonRoot = new GameObject("AlreadyButton");
            _buttonRoot.transform.SetParent(transform, false);
            _buttonRoot.transform.localPosition = new Vector3(_buttonPosition.x, _buttonPosition.y, 0f);

            _buttonOutline = InkLine.Create(_buttonRoot.transform, "Outline", _inkMaterial, _lineWidth, _buttonInk, _sortingOrder);
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _buttonRadius, 0f, 360f, 40);
            InkLine.SetPoints(_buttonOutline, ring);
            if (_buttonOutline.gameObject.GetComponent<LineBoil>() == null) _buttonOutline.gameObject.AddComponent<LineBoil>().Capture();

            // A small inner ring so it reads as a worn, well-pressed button.
            _buttonInner = InkLine.Create(_buttonRoot.transform, "Inner", _inkMaterial, _lineWidth * 0.7f, _buttonInk, _sortingOrder);
            var inner = new List<Vector3>();
            InkLine.AddArc(inner, Vector2.zero, _buttonRadius * 0.6f, 0f, 360f, 32);
            InkLine.SetPoints(_buttonInner, inner);
            if (_buttonInner.gameObject.GetComponent<LineBoil>() == null) _buttonInner.gameObject.AddComponent<LineBoil>().Capture();
        }

        private IEnumerator FadeButton(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                if (_buttonOutline != null) InkLine.SetAlpha(_buttonOutline, _buttonInk, a);
                if (_buttonInner != null) InkLine.SetAlpha(_buttonInner, _buttonInk, a);
                yield return null;
            }
        }

        private void TeardownButton()
        {
            if (_buttonRoot != null) { Destroy(_buttonRoot); _buttonRoot = null; }
            _buttonOutline = null;
            _buttonInner = null;
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
