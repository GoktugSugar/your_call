using System.Collections;
using TMPro;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Button That Walks Away (Chapter 2, a pure gag). The imp presents a plain button and says it is
    /// just a button, even he does not know what it does. Press it, or do not.
    ///
    /// Leave it and the imp mocks the caution, and the beat ends. Press it and the button springs to life,
    /// recoils as if hurt, swears in a small put-out voice, gets up and walks off the screen. The IMP is
    /// genuinely surprised too, a rare crack in his smugness (the Surprised face and a broken line), then
    /// he recovers and comments (well, that has never happened). No death, no consequence, it is a joke.
    /// The button is drawn on-model (a button that sprouts little stick limbs and walks). Stats: a light
    /// seeded press-vs-not split.
    ///
    /// Self contained, reusing the shared ChoiceButtons, StatsView, the imp (and its expression set for
    /// the surprise), and the WalkingButton figure. Another beat the SequencePlayer plays in order.
    /// </summary>
    public sealed class WalkingButtonBeat : SequenceBeat
    {
        [Header("References")]
        [Tooltip("The walking-button figure prefab (sprouts limbs and walks).")]
        [SerializeField] private WalkingButton _buttonPrefab;
        [Tooltip("Optional font for the button's outburst (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The button (centred)")]
        [SerializeField] private Vector2 _buttonPosition = new Vector2(0f, 0f);
        [SerializeField] private float _buttonScale = 1.1f;
        [Tooltip("Click radius for pressing the button directly (world units, roughly the drawn button's size).")]
        [SerializeField] private float _pressRadius = 0.62f;
        [Tooltip("The quick hand-drawn press squash before it comes to life.")]
        [SerializeField] private float _pressDuration = 0.14f;
        [Tooltip("Padding for the imp keep-out around the button, so the imp never sits on it.")]
        [SerializeField] private float _keepoutPadding = 0.45f;

        [Header("The button's voice (floating ink, its own words, not the imp's)")]
        [SerializeField] private float _voiceSize = 2.3f;
        [SerializeField] private Color _voiceColor = Palette.Ink;
        [SerializeField] private float _voiceHeight = 1.15f;
        [SerializeField] private int _voiceSorting = 26;

        [Header("Crowd split (seeded; light, mostly for the gag)")]
        [SerializeField] private int _pressSeed = 58;
        [SerializeField] private int _leaveSeed = 42;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _pressStatLabel = "pressed it";
        [SerializeField] private string _leaveStatLabel = "left it be";

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The setup, shown in order, a click between each.")]
        [SerializeField, TextArea(2, 4)] private string[] _setupLines = new[]
        {
            "Last one. And this time, honestly, I have no idea what it does.",
            "A plain button. No trick, no catch, no tidy little lesson at the end. Even I do not know. Press it, or do not. Genuinely your call.",
        };
        [Tooltip("If they leave it. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _leftReact =
            "You did not press it. The one button in this entire place with nothing whatsoever riding on it, and you still could not make yourself. You are exhausting, and I mean that with real affection.";

        [Tooltip("The button's outburst when pressed (its own voice, floating over it). Small, put-out, strong language fine, no dashes.")]
        [SerializeField, TextArea(1, 3)] private string _buttonYelp = "Ow! Fuck. That actually hurt, you absolute prick.";
        [Tooltip("The button's parting mutter as it walks off.")]
        [SerializeField, TextArea(1, 3)] private string _buttonMutter = "Unbelievable. I did nothing to you. Nothing.";

        [Tooltip("The imp caught off guard (a broken line; his smugness cracks for a second).")]
        [SerializeField, TextArea(2, 4)] private string _impSurprised =
            "What. What was. Hold on, that is not. It has never done that. It does not do things.";
        [Tooltip("The imp recovering and commenting, smug mask back on.")]
        [SerializeField, TextArea(2, 5)] private string _impRecover =
            "Right. Well. That has never happened, not once, and I have been at this an extremely long time. Let us both agree we did not see it, and move along.";

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _pressLabel = "Press it";
        [SerializeField] private string _leaveLabel = "Leave it";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _comeAliveDuration = 0.45f;
        [SerializeField] private float _yelpHold = 1.3f;
        [SerializeField] private float _surpriseHold = 0.5f;
        [SerializeField] private float _recoverHold = 0.4f;
        [SerializeField] private float _voiceFade = 0.3f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private Camera _cam;
        private WalkingButton _button;
        private TextMeshPro _voice;
        private ClickSfx _clickSfx;
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Choices == null)
            {
                Debug.LogError("[WalkingButtonBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }
            if (_buttonPrefab == null)
            {
                Debug.LogError("[WalkingButtonBeat] '" + Note + "' is missing its walking-button prefab.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            _button = Instantiate(_buttonPrefab, transform);
            _button.name = "WalkingButton";
            _button.transform.localPosition = new Vector3(_buttonPosition.x, _buttonPosition.y, 0f);
            _button.transform.localScale = new Vector3(_buttonScale, _buttonScale, 1f);

            // Add the button to the imp's keep-out so the imp never sits on it while roaming the setup.
            var keepout = _button.gameObject.AddComponent<ScreenKeepout>();
            keepout.UseRendererBounds(_keepoutPadding);

            // Setup.
            if (_setupLines != null)
            {
                for (int i = 0; i < _setupLines.Length; i++)
                {
                    if (string.IsNullOrEmpty(_setupLines[i])) continue;
                    ctx.Narrator.Show(_setupLines[i]);
                    while (ctx.Narrator.IsShowing) yield return null;
                    yield return WaitAdvance(_advanceLockout);
                }
            }
            ctx.Narrator.Clear();

            // The choice: click the button itself, or the text options.
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_pressLabel, _leaveLabel);
            try
            {
                while (_picked < 0)
                {
                    if (OverButton() && PointerInput.Clicked) { _picked = 0; break; }
                    yield return null;
                }
            }
            finally { ctx.Choices.Chosen -= OnPicked; ctx.Choices.Dismiss(); }
            bool pressed = _picked == 0;

            if (pressed)
            {
                // Press feedback: a quick squash and a click, before it comes to life.
                PlayClick();
                yield return _button.Press(_pressDuration);
                yield return PlayTheGag(ctx);
            }
            else
            {
                ctx.Narrator.Show(_leftReact);
                while (ctx.Narrator.IsShowing) yield return null;
                yield return WaitAdvance(_advanceLockout);
                ctx.Narrator.Clear();
                yield return FadeVoiceHostTeardown();
            }

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_pressSeed, _leaveSeed));
            report.Bars.Add(new StatBar(_pressStatLabel, _pressSeed, pressed));
            report.Bars.Add(new StatBar(_leaveStatLabel, _leaveSeed, !pressed));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        private IEnumerator PlayTheGag(SequenceContext ctx)
        {
            // Hold the imp still so its surprise reads in place, not mid-hop.
            ImpRoamer roamer = ctx.Imp != null ? ctx.Imp.GetComponent<ImpRoamer>() : null;
            if (roamer != null) roamer.enabled = false;

            // It comes alive, recoils, and swears in its own voice (floating over it, not the imp's box).
            yield return _button.ComeAlive(_comeAliveDuration);
            ShowVoice(_buttonYelp);
            yield return new WaitForSeconds(_yelpHold);

            // The imp is genuinely caught off guard: the surprised face and a broken line.
            if (ctx.Imp != null) ctx.Imp.SetExpression(ImpExpression.Surprised);
            ctx.Narrator.Show(_impSurprised);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_surpriseHold);
            ctx.Narrator.Clear();

            // It gets up, mutters, and walks off the screen and out, AWAY from the imp so it never
            // walks through it (the imp is held still in a side wing during the gag).
            ShowVoice(_buttonMutter);
            bool impOnLeft = ctx.Imp != null && ctx.Imp.transform.position.x < _button.transform.position.x;
            float exitX = impOnLeft ? RightExitLocalX() : LeftExitLocalX();
            System.Func<Vector3, bool> offScreen = impOnLeft ? (System.Func<Vector3, bool>)OffScreenRight : OffScreenLeft;
            yield return _button.WalkOff(exitX, offScreen);
            yield return FadeVoice(0f);

            // The imp recovers, smug mask back on, and comments.
            if (ctx.Imp != null) ctx.Imp.SetExpression(ImpExpression.Smug);
            ctx.Narrator.Show(_impRecover);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_recoverHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();
            if (ctx.Imp != null) ctx.Imp.SetExpression(ImpExpression.Grin);   // reset for the next beat
            if (roamer != null) roamer.enabled = true;

            yield return FadeVoiceHostTeardown();
        }

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        // ---- the button's floating voice (its own words) ----

        private void ShowVoice(string line)
        {
            if (_voice == null)
            {
                _voice = InkText.Create(transform, "ButtonVoice", _voiceSize, _voiceColor, TextAlignmentOptions.Center, _voiceSorting);
                if (_font != null) _voice.font = _font;
                _voice.rectTransform.sizeDelta = new Vector2(6f, 1.4f);
                _voice.enableWordWrapping = true;
                InkText.SetAlpha(_voice, 0f);
            }
            _voice.text = line;
            StopVoiceRoutine();
            _voiceRoutine = StartCoroutine(FadeVoiceTo(1f));
        }

        private Coroutine _voiceRoutine;
        private void StopVoiceRoutine() { if (_voiceRoutine != null) { StopCoroutine(_voiceRoutine); _voiceRoutine = null; } }

        private void Update()
        {
            // Keep the button's voice pinned above the walking button.
            if (_voice != null && _button != null)
                _voice.transform.position = _button.transform.position + new Vector3(0f, _voiceHeight, 0f);
        }

        private IEnumerator FadeVoice(float target) { StopVoiceRoutine(); yield return FadeVoiceTo(target); }

        private IEnumerator FadeVoiceTo(float target)
        {
            if (_voice == null) yield break;
            float from = _voice.color.a, t = 0f, d = Mathf.Max(_voiceFade, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(_voice, Mathf.Lerp(from, target, t / d)); yield return null; }
            InkText.SetAlpha(_voice, target);
        }

        private IEnumerator FadeVoiceHostTeardown()
        {
            yield return FadeVoice(0f);
            if (_voice != null) { Destroy(_voice.gameObject); _voice = null; }
            if (_button != null) { Destroy(_button.gameObject); _button = null; }
        }

        // Is the pointer over the drawn button (so a direct click presses it)?
        private bool OverButton()
        {
            if (_cam == null || _button == null) return false;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            Vector2 c = _button.transform.position;
            return ((Vector2)wp - c).sqrMagnitude <= _pressRadius * _pressRadius;
        }

        private void PlayClick()
        {
            if (_clickSfx == null)
            {
                _clickSfx = GetComponent<ClickSfx>();
                if (_clickSfx == null) _clickSfx = gameObject.AddComponent<ClickSfx>();
            }
            _clickSfx.Play();
        }

        // Off-screen thresholds to either side of the camera, plus a hard local-X stop as a fallback.
        private float LeftExitLocalX()
        {
            if (_cam != null && _cam.orthographic)
            {
                float leftEdge = _cam.transform.position.x - _cam.orthographicSize * _cam.aspect;
                return (leftEdge - 2f) - transform.position.x + transform.localPosition.x;
            }
            return -14f;
        }

        private float RightExitLocalX()
        {
            if (_cam != null && _cam.orthographic)
            {
                float rightEdge = _cam.transform.position.x + _cam.orthographicSize * _cam.aspect;
                return (rightEdge + 2f) - transform.position.x + transform.localPosition.x;
            }
            return 14f;
        }

        private bool OffScreenLeft(Vector3 worldPos)
        {
            if (_cam == null || !_cam.orthographic) return false;
            float leftEdge = _cam.transform.position.x - _cam.orthographicSize * _cam.aspect;
            return worldPos.x < leftEdge - 1.2f;
        }

        private bool OffScreenRight(Vector3 worldPos)
        {
            if (_cam == null || !_cam.orthographic) return false;
            float rightEdge = _cam.transform.position.x + _cam.orthographicSize * _cam.aspect;
            return worldPos.x > rightEdge + 1.2f;
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
