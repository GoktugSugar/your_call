using System.Collections;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// An illustrated would-you-rather: the light, quick, no-right-answer breather sprinkled between the
    /// heavy beats (see docs/gameplay.md). It shows the imp's prompt and TWO small hand-drawn ink doodles
    /// side by side, each with a short label, a clear this-or-that; the player clicks a side (or its
    /// illustration) or keys it, the imp mocks whichever they picked (choice independent, never graded),
    /// and the usual how-others-chose reveal plays. No elaborate consequence, just a small ink flourish,
    /// so it stays snappy.
    ///
    /// Reusable and data-driven: it takes a `Dilemma` (Binary, weight Light) for the prompt, the two
    /// labels, the seeded split, the per-side reactions and any (usually absent) profile impact, plus the
    /// two <see cref="DoodleKind"/>s off the same asset for the illustrations. So adding a would-you-rather
    /// is a new `Dilemma` asset plus its two doodles, not new code. It reuses `BinaryResolver` (via
    /// `VerbResolvers`), the shared `StatsView`, the silent `Profile`, and the `InkPoof` flourish; it owns
    /// only its two-doodle pick. `DilemmaStage` / the sequence stay generic.
    /// </summary>
    public sealed class WouldYouRatherBeat : SequenceBeat
    {
        [Header("Content")]
        [Tooltip("A Binary, weight Light Dilemma: the prompt, the two option labels, the seeded split, the per-side reactions, and the two option doodles (OptionADoodle / OptionBDoodle).")]
        [SerializeField] private Dilemma _dilemma;

        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the option labels and the 'or' (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("Layout (two doodles side by side)")]
        [SerializeField] private float _sideX = 2.7f;
        [SerializeField] private float _doodleY = 0.7f;
        [SerializeField] private float _doodleScale = 1.05f;
        [SerializeField] private float _labelY = -0.75f;
        [SerializeField] private float _labelSize = 2.8f;
        [SerializeField] private int _sorting = 14;
        [Tooltip("Half width / half height of each clickable side region (around the doodle and its label).")]
        [SerializeField] private Vector2 _pickHalfExtents = new Vector2(1.35f, 1.7f);
        [Tooltip("Show a small 'or' between the two options.")]
        [SerializeField] private bool _showOr = true;
        [SerializeField] private float _orY = 0.45f;

        [Header("Feel")]
        [SerializeField] private float _doodleFadeIn = 0.35f;
        [SerializeField] private float _doodleFadeOut = 0.35f;
        [Tooltip("The hovered side lifts and brightens a touch.")]
        [SerializeField] private float _hoverScale = 1.08f;
        [SerializeField, Range(0f, 1f)] private float _restLabelAlpha = 0.8f;

        [Header("Flourish (the small ink burst on the chosen side; amber)")]
        [SerializeField] private Color _flourishColor = Palette.Amber;
        [SerializeField] private float _flourishRadius = 0.7f;
        [SerializeField, Range(3, 24)] private int _flourishStrokes = 9;
        [SerializeField] private float _flourishWidth = 0.05f;
        [SerializeField] private float _flourishDuration = 0.6f;

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;

        private Camera _cam;
        private InkDoodle _doodleA, _doodleB;
        private TextMeshPro _labelA, _labelB, _orLabel;
        private float _hoverA, _hoverB;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_dilemma == null)
            {
                Debug.LogError("[WouldYouRatherBeat] '" + Note + "' is missing its dilemma.");
                yield break;
            }
            if (_dilemma.Choices.Count < 2)
            {
                Debug.LogError("[WouldYouRatherBeat] '" + Note + "' needs two choices.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            BuildOptions();
            StartCoroutine(_doodleA.FadeIn(_doodleFadeIn));
            StartCoroutine(_doodleB.FadeIn(_doodleFadeIn));
            yield return FadeLabels(0f, 1f, _doodleFadeIn);

            // The imp poses the this-or-that; the options are already in view.
            ctx.Narrator.Show(_dilemma.NarratorPrompt);
            while (ctx.Narrator.IsShowing) yield return null;

            // Pick a side: click a doodle / its label, or key it (1/left, 2/right).
            int picked = -1;
            while (picked < 0)
            {
                int hover = HoverSide();
                _hoverA = Mathf.MoveTowards(_hoverA, hover == 0 ? 1f : 0f, Time.deltaTime / 0.1f);
                _hoverB = Mathf.MoveTowards(_hoverB, hover == 1 ? 1f : 0f, Time.deltaTime / 0.1f);
                ApplyHover();
                if (hover >= 0 && PointerInput.Clicked) { picked = hover; break; }
                int key = KeySide();
                if (key >= 0) { picked = key; break; }
                yield return null;
            }

            // A small ink flourish on the chosen side (amber), so even a light beat resolves into a drawn moment.
            float chosenX = picked == 0 ? -_sideX : _sideX;
            if (_inkMaterial != null)
                InkPoof.Spawn(new Vector3(chosenX, _doodleY, 0f), _inkMaterial, _flourishColor,
                    _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _sorting + 2);
            yield return new WaitForSeconds(_flourishDuration * 0.6f);

            // Reuse BinaryResolver for the reaction and the reflective how-others-chose report.
            var outcome = VerbResolvers.For(_dilemma.Verb).Resolve(new DilemmaContext(_dilemma, picked));

            // The imp mocks whichever they chose (choice independent, never graded).
            ctx.Narrator.Clear();
            ctx.Narrator.Show(outcome.NarratorReact);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            // Silent profile (usually none: these are pure taste).
            ctx.Profile.Record(_dilemma.Choices[picked].ProfileImpact);

            // Lift the options, then the how-others-chose reveal.
            yield return FadeOptionsOut();
            yield return ctx.Stats.Reveal(outcome.Report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);

            TeardownOptions();
        }

        // ---------- build / layout ----------

        private void BuildOptions()
        {
            _doodleA = InkDoodle.Create(transform, "DoodleA", new Vector3(-_sideX, _doodleY, 0f), _doodleScale,
                _dilemma.OptionADoodle, _inkMaterial, Palette.Ink, _flourishWidth, _sorting);
            _doodleB = InkDoodle.Create(transform, "DoodleB", new Vector3(_sideX, _doodleY, 0f), _doodleScale,
                _dilemma.OptionBDoodle, _inkMaterial, Palette.Ink, _flourishWidth, _sorting);

            _labelA = MakeLabel("LabelA", new Vector3(-_sideX, _labelY, 0f), _dilemma.Choices[0].Label);
            _labelB = MakeLabel("LabelB", new Vector3(_sideX, _labelY, 0f), _dilemma.Choices[1].Label);
            if (_showOr)
            {
                _orLabel = MakeLabel("Or", new Vector3(0f, _orY, 0f), "or");
                _orLabel.fontSize = _labelSize * 0.9f;
                _orLabel.color = Palette.Muted;
            }
        }

        private TextMeshPro MakeLabel(string name, Vector3 localPos, string text)
        {
            var t = InkText.Create(transform, name, _labelSize, Palette.Ink, TextAlignmentOptions.Center, _sorting + 1);
            if (_font != null) t.font = _font;
            t.rectTransform.sizeDelta = new Vector2(2.6f, 1.2f);
            t.enableWordWrapping = true;
            t.transform.localPosition = localPos;
            t.text = text;
            InkText.SetAlpha(t, 0f);
            return t;
        }

        private int HoverSide()
        {
            if (_cam == null) return -1;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            if (InRegion(wp, -_sideX)) return 0;
            if (InRegion(wp, _sideX)) return 1;
            return -1;
        }

        private bool InRegion(Vector3 wp, float centreX)
        {
            Vector2 c = transform.TransformPoint(new Vector3(centreX, (_doodleY + _labelY) * 0.5f, 0f));
            return Mathf.Abs(wp.x - c.x) <= _pickHalfExtents.x && Mathf.Abs(wp.y - c.y) <= _pickHalfExtents.y;
        }

        private int KeySide()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null)
            {
                if (kb.digit1Key.wasPressedThisFrame || kb.leftArrowKey.wasPressedThisFrame) return 0;
                if (kb.digit2Key.wasPressedThisFrame || kb.rightArrowKey.wasPressedThisFrame) return 1;
            }
#endif
            return -1;
        }

        private void ApplyHover()
        {
            if (_doodleA != null) _doodleA.transform.localScale = Vector3.one * (_doodleScale * Mathf.Lerp(1f, _hoverScale, _hoverA));
            if (_doodleB != null) _doodleB.transform.localScale = Vector3.one * (_doodleScale * Mathf.Lerp(1f, _hoverScale, _hoverB));
            if (_labelA != null) { InkText.SetAlpha(_labelA, Mathf.Lerp(_restLabelAlpha, 1f, _hoverA)); _labelA.transform.localScale = Vector3.one * Mathf.Lerp(1f, _hoverScale, _hoverA); }
            if (_labelB != null) { InkText.SetAlpha(_labelB, Mathf.Lerp(_restLabelAlpha, 1f, _hoverB)); _labelB.transform.localScale = Vector3.one * Mathf.Lerp(1f, _hoverScale, _hoverB); }
        }

        private IEnumerator FadeLabels(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                if (_labelA != null) InkText.SetAlpha(_labelA, a * _restLabelAlpha);
                if (_labelB != null) InkText.SetAlpha(_labelB, a * _restLabelAlpha);
                if (_orLabel != null) InkText.SetAlpha(_orLabel, a);
                yield return null;
            }
        }

        private IEnumerator FadeOptionsOut()
        {
            if (_doodleA != null) StartCoroutine(_doodleA.FadeOut(_doodleFadeOut));
            if (_doodleB != null) StartCoroutine(_doodleB.FadeOut(_doodleFadeOut));
            yield return FadeLabels(1f, 0f, _doodleFadeOut);
        }

        private void TeardownOptions()
        {
            if (_doodleA != null) Destroy(_doodleA.gameObject);
            if (_doodleB != null) Destroy(_doodleB.gameObject);
            if (_labelA != null) Destroy(_labelA.gameObject);
            if (_labelB != null) Destroy(_labelB.gameObject);
            if (_orLabel != null) Destroy(_orLabel.gameObject);
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
