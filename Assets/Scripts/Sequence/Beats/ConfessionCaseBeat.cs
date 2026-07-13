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
    /// The reusable confession case beat (Chapter 7, The Confession Booth). This is the chapter where the dead
    /// judge finally does his actual job: dead souls file into a fixed booth one at a time, confess an "am I the
    /// asshole" dispute with no clean answer, and the player passes a VERDICT. Then the crowd reveal shows
    /// whether the room agreed. The imp is not posing a dilemma here, he is the bored court CLERK running the
    /// docket: announcing each case, moving things along, and heckling the ruling (choice independent, never
    /// grading a verdict right or wrong).
    ///
    /// The verdict is three way, not binary, because these disputes have an "everyone sucks here" middle: the
    /// confessor is in the wrong, the confessor is NOT in the wrong (the other party is), or both are (no one is
    /// clean). It reuses the pick-one-of-several idea (the multiple choice verb) as three verdict affordances
    /// clear of the scene, and the shared <see cref="StatsView"/> reveal for the seeded three way split, built
    /// self contained like the Chapter 5 matchup rather than a per case Dilemma asset (so the loop stays
    /// generic, no bespoke branches in unrelated systems).
    ///
    /// One reusable beat type: a concrete case is a small subclass returning its <see cref="ConfessionData"/>
    /// (the clerk announcement, the account, the three verdicts and reactions, the seeded split). Two cases
    /// override <see cref="Play"/> to compose their own flow over the same protected helpers: the walking button
    /// files in and confesses too (the gag, case 4), and the two stories closer files TWO confessors in with
    /// contradictory accounts (case 10). Adding an ordinary case is data.
    /// </summary>
    public abstract class ConfessionCaseBeat : SequenceBeat
    {
        [Header("Apparatus (shared)")]
        [SerializeField] protected ConfessionKit _kit;

        [Header("Confessor (files in / out)")]
        [SerializeField] protected float _confessorScale = 1.5f;
        [SerializeField] protected Vector2 _standFeet = new Vector2(0f, -1.5f);
        [SerializeField] protected float _fileInFromX = 8.0f;
        [SerializeField] protected float _fileOutToX = -8.0f;
        [SerializeField] protected float _fileInDuration = 0.9f;
        [SerializeField] protected float _fileOutDuration = 0.8f;
        [Tooltip("Two confessor stand offsets from centre, for the two stories closer.")]
        [SerializeField] protected float _pairOffsetX = 2.3f;

        [Header("Booth")]
        [SerializeField] protected float _boothRevealDuration = 0.7f;

        [Header("Floating headline (ink over the confessor, no bubble)")]
        [SerializeField] protected float _headlineSize = 2.3f;
        [SerializeField] protected float _headlineClearance = 0.35f;
        [SerializeField] protected int _headlineSorting = 24;

        [Header("Verdict affordances (three, clear of the scene)")]
        [SerializeField] protected float _verdictY = -2.78f;
        [SerializeField] protected float _verdictSpan = 3.95f;
        [SerializeField] protected float _verdictSize = 2.5f;
        [SerializeField] protected float _verdictWidth = 3.6f;
        [SerializeField, Range(0f, 1f)] protected float _verdictRest = 0.72f;
        [SerializeField] protected float _verdictHoverScale = 1.07f;
        [SerializeField] protected Vector2 _verdictPickHalf = new Vector2(1.85f, 0.62f);
        [SerializeField] protected float _verdictFade = 0.22f;
        [SerializeField] protected int _verdictSorting = 20;

        [Header("Flourish (amber ink burst on the chosen verdict)")]
        [SerializeField] protected float _flourishRadius = 0.7f;
        [SerializeField, Range(3, 24)] protected int _flourishStrokes = 9;
        [SerializeField] protected float _flourishWidth = 0.05f;
        [SerializeField] protected float _flourishDuration = 0.55f;

        [Header("Timing")]
        [SerializeField] protected float _advanceLockout = 0.3f;
        [SerializeField] protected float _reactHold = 0.9f;
        [SerializeField] protected float _statsFade = 0.5f;
        [SerializeField] protected float _statsHideFade = 0.6f;
        [SerializeField] protected float _keepoutPadding = 0.5f;

        protected Camera _cam;
        protected Transform _content;
        protected int _verdict = -1;
        private float[] _verdictHover = new float[3];

        /// <summary>Each concrete case returns its data here (copy in code defaults, like the matchup / gun beats).</summary>
        protected abstract ConfessionData BuildData();

        protected Camera Cam(SequenceContext ctx) => ctx != null && ctx.Camera != null ? ctx.Camera : Camera.main;

        // ---------- the standard single confessor flow ----------

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            var data = BuildData();
            if (data == null) { Debug.LogError("[ConfessionCaseBeat] '" + Note + "' produced no data."); yield break; }
            _cam = Cam(ctx);
            BeginContent();

            yield return EnsureBooth();

            // A soul files up to the booth.
            var confessor = SpawnFigure(_standFeet, _confessorScale, "Confessor");
            yield return FileIn(confessor, _fileInFromX, _fileInDuration);

            // Their core position floats over them, and the clerk announces the case, then they state their side.
            TextMeshPro headline = null;
            if (!string.IsNullOrEmpty(data.Headline))
            {
                headline = NewFloating("Headline");
                yield return ShowHeadline(headline, confessor, data.Headline);
            }
            yield return Lines(ctx, data.Announce);
            yield return Lines(ctx, data.Account);

            // The verdict: rule one of three, clear of the scene.
            yield return RulePrompt(ctx, data);
            yield return Rule(ctx, data.VerdictGuilty, data.VerdictInnocent, data.VerdictBoth);
            if (headline != null) StartCoroutine(FadeText(headline, 0f, _verdictFade));

            // The clerk heckles the ruling (choice independent, never grades), then the soul files out.
            yield return React(ctx, ReactFor(data, _verdict));
            if (data.HasProfile) Nudge(ctx, data.Axis, NudgeFor(data, _verdict));
            yield return FileOut(confessor, _fileOutToX, _fileOutDuration);

            // The clerk may note the room ruled strangely (crowd relative, never a claim it was wrong), then the
            // seeded three way split (whether the room agreed with the player's verdict).
            yield return MaybeOddRuling(ctx, data);
            yield return Reveal(ctx, data, _verdict);

            EndContent();
        }

        // ---------- readiness / content ----------

        protected bool Ready()
        {
            if (_kit == null || _kit.InkMaterial == null || _kit.FigurePrefab == null)
            {
                Debug.LogError("[ConfessionCaseBeat] '" + Note + "' is missing its ConfessionKit / ink / figure prefab.");
                return false;
            }
            return true;
        }

        protected void BeginContent()
        {
            _content = new GameObject("Case").transform;
            _content.SetParent(transform, false);
            var keep = _content.gameObject.AddComponent<ScreenKeepout>();
            keep.UseRendererBounds(_keepoutPadding);
        }

        protected void EndContent()
        {
            if (_content != null) Destroy(_content.gameObject);
            _content = null;
        }

        protected IEnumerator EnsureBooth()
        {
            if (_kit.Booth != null) yield return _kit.Booth.EnsureShown(_boothRevealDuration);
        }

        // ---------- confessor figures ----------

        protected Figure SpawnFigure(Vector2 feet, float scale, string name)
        {
            var f = Instantiate(_kit.FigurePrefab, _content);
            f.name = name;
            f.transform.localPosition = new Vector3(feet.x, feet.y, 0f);
            f.transform.localScale = new Vector3(scale, scale, 1f);
            f.SetInkAlpha(0f);
            return f;
        }

        /// <summary>A soul files in: slides from an off screen X to its stand spot while inking in (the light
        /// animated consequence, scaled light).</summary>
        protected IEnumerator FileIn(Figure f, float fromX, float dur)
        {
            if (f == null) yield break;
            float toX = f.transform.localPosition.x;
            float y = f.transform.localPosition.y;
            float t = 0f, d = Mathf.Max(dur, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                f.transform.localPosition = new Vector3(Mathf.Lerp(fromX, toX, k), y, 0f);
                f.SetInkAlpha(Mathf.Clamp01(k * 1.3f));
                yield return null;
            }
            f.transform.localPosition = new Vector3(toX, y, 0f);
            f.SetInkAlpha(1f);
        }

        /// <summary>The soul files out: slides off to the given X while inking out, and the next files in.</summary>
        protected IEnumerator FileOut(Figure f, float toX, float dur)
        {
            if (f == null) yield break;
            float fromX = f.transform.localPosition.x;
            float y = f.transform.localPosition.y;
            float t = 0f, d = Mathf.Max(dur, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.OutCubic(t / d);
                f.transform.localPosition = new Vector3(Mathf.Lerp(fromX, toX, k), y, 0f);
                f.SetInkAlpha(1f - Mathf.Clamp01(k * 1.2f));
                yield return null;
            }
            if (f != null) f.gameObject.SetActive(false);
        }

        // ---------- floating headline over a confessor ----------

        protected TextMeshPro NewFloating(string name)
        {
            var t = InkText.Create(_content, name, _headlineSize, Palette.Ink, TextAlignmentOptions.Center, _headlineSorting);
            if (_kit.Font != null) t.font = _kit.Font;
            t.rectTransform.sizeDelta = new Vector2(5.2f, 1.3f);
            t.enableWordWrapping = true;
            InkText.SetAlpha(t, 0f);
            return t;
        }

        protected IEnumerator ShowHeadline(TextMeshPro label, Figure fig, string line)
        {
            if (label == null) yield break;
            label.transform.position = FigurePleaPlacement.Above(fig, _headlineClearance);
            label.text = InkMarkup.ToRichText(Localization.Localize(line));
            yield return FadeText(label, 1f, 0.35f);
        }

        // ---------- imp clerk narration ----------

        /// <summary>Show one line, wait for it to finish typing, then a click to continue.</summary>
        protected IEnumerator Line(SequenceContext ctx, string line)
        {
            if (string.IsNullOrEmpty(line)) yield break;
            ctx.Narrator.Show(line);
            while (ctx.Narrator.IsShowing) yield return null;
            yield return WaitAdvance(_advanceLockout);
        }

        protected IEnumerator Lines(SequenceContext ctx, string[] lines)
        {
            if (lines == null) yield break;
            for (int i = 0; i < lines.Length; i++) yield return Line(ctx, lines[i]);
        }

        private static readonly string[] _defaultRulePrompts =
        {
            "Well? You spent a whole life doing exactly this. Your verdict.",
            "The docket is not getting shorter. Rule.",
            "So. The bench is yours, judge. What is your ruling.",
        };

        protected IEnumerator RulePrompt(SequenceContext ctx, ConfessionData data)
        {
            string line = !string.IsNullOrEmpty(data.RulePrompt)
                ? data.RulePrompt
                : _defaultRulePrompts[Mathf.Abs(Note.GetHashCode()) % _defaultRulePrompts.Length];
            yield return Line(ctx, line);
        }

        /// <summary>The clerk's heckle of the ruling, with the click gate before the crowd reveal (so the verdict
        /// lands before the room weighs in). Choice independent; never grades.</summary>
        protected IEnumerator React(SequenceContext ctx, string line)
        {
            if (!string.IsNullOrEmpty(line))
            {
                ctx.Narrator.Show(line);
                while (ctx.Narrator.IsShowing) yield return null;
            }
            float gate = 0f;
            while (true)
            {
                gate += Time.deltaTime;
                if (gate > _reactHold && PointerInput.AdvancePressed) break;
                yield return null;
            }
            ctx.Narrator.Clear();
        }

        /// <summary>If the player's verdict was the LEAST popular of the three, and the case authored an aside,
        /// the clerk notes the room does not see it that way. Crowd relative, never a claim the ruling was wrong.</summary>
        protected IEnumerator MaybeOddRuling(SequenceContext ctx, ConfessionData data)
        {
            if (string.IsNullOrEmpty(data.OddRulingAside)) yield break;
            if (_verdict == LeastPopular(data)) yield return Line(ctx, data.OddRulingAside);
        }

        // ---------- the three verdict pick ----------

        protected IEnumerator Rule(SequenceContext ctx, string a, string b, string c)
        {
            _verdict = -1;
            for (int i = 0; i < 3; i++) _verdictHover[i] = 0f;
            var labels = new TextMeshPro[3];
            string[] txt = { a, b, c };
            float[] xs = { -_verdictSpan, 0f, _verdictSpan };
            for (int i = 0; i < 3; i++) labels[i] = MakeVerdictLabel("Verdict" + i, txt[i], xs[i]);
            // Ink them on.
            float f = 0f;
            while (f < 0.2f) { f += Time.deltaTime; float k = f / 0.2f; for (int i = 0; i < 3; i++) InkText.SetAlpha(labels[i], _verdictRest * k); yield return null; }

            int picked = -1;
            while (picked < 0)
            {
                int hv = HoverVerdict(xs);
                for (int i = 0; i < 3; i++)
                {
                    _verdictHover[i] = Mathf.MoveTowards(_verdictHover[i], hv == i ? 1f : 0f, Time.deltaTime / 0.1f);
                    ApplyVerdictHover(labels[i], _verdictHover[i]);
                }
                if (hv >= 0 && PointerInput.Clicked) { picked = hv; break; }
                int key = KeyVerdict();
                if (key >= 0) { picked = key; break; }
                yield return null;
            }
            _verdict = picked;

            // The light amber ink flourish on the chosen verdict.
            Vector3 world = _content.TransformPoint(new Vector3(xs[picked], _verdictY, 0f));
            InkPoof.Spawn(world, _kit.InkMaterial, Palette.Amber, _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _verdictSorting + 4);

            for (int i = 0; i < 3; i++) StartCoroutine(FadeText(labels[i], 0f, _verdictFade));
            yield return new WaitForSeconds(_verdictFade + 0.02f);
            for (int i = 0; i < 3; i++) if (labels[i] != null) Destroy(labels[i].gameObject);
        }

        private TextMeshPro MakeVerdictLabel(string name, string text, float x)
        {
            var t = InkText.Create(_content, name, _verdictSize, Palette.Ink, TextAlignmentOptions.Center, _verdictSorting);
            if (_kit.Font != null) t.font = _kit.Font;
            t.rectTransform.sizeDelta = new Vector2(_verdictWidth, 1.5f);
            t.enableWordWrapping = true;
            t.transform.localPosition = new Vector3(x, _verdictY, 0f);
            t.text = Localization.Localize(text);
            InkText.SetAlpha(t, 0f);
            return t;
        }

        private int HoverVerdict(float[] xs)
        {
            if (_cam == null) return -1;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            for (int i = 0; i < 3; i++)
            {
                Vector2 c = _content.TransformPoint(new Vector3(xs[i], _verdictY, 0f));
                if (Mathf.Abs(wp.x - c.x) <= _verdictPickHalf.x && Mathf.Abs(wp.y - c.y) <= _verdictPickHalf.y) return i;
            }
            return -1;
        }

        private int KeyVerdict()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null && !PointerInput.Suppressed)
            {
                if (kb.digit1Key.wasPressedThisFrame) return 0;
                if (kb.digit2Key.wasPressedThisFrame) return 1;
                if (kb.digit3Key.wasPressedThisFrame) return 2;
            }
#endif
            return -1;
        }

        private void ApplyVerdictHover(TextMeshPro label, float hover)
        {
            if (label == null) return;
            InkText.SetAlpha(label, Mathf.Lerp(_verdictRest, 1f, hover));
            float s = Mathf.Lerp(1f, _verdictHoverScale, hover);
            label.transform.localScale = new Vector3(s, s, 1f);
        }

        // ---------- the seeded three way reveal ----------

        protected IEnumerator Reveal(SequenceContext ctx, ConfessionData data, int picked)
        {
            var report = new ResolutionReport { Heading = data.Heading };
            report.Bars.Add(new StatBar(data.VerdictGuilty, data.SeedGuilty, picked == 0));
            report.Bars.Add(new StatBar(data.VerdictInnocent, data.SeedInnocent, picked == 1));
            report.Bars.Add(new StatBar(data.VerdictBoth, data.SeedBoth, picked == 2));
            report.MaxValue = Mathf.Max(1, Mathf.Max(data.SeedGuilty, Mathf.Max(data.SeedInnocent, data.SeedBoth)));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // ---------- helpers ----------

        protected string ReactFor(ConfessionData d, int v) => v == 0 ? d.ReactGuilty : (v == 1 ? d.ReactInnocent : d.ReactBoth);
        protected float NudgeFor(ConfessionData d, int v) => v == 0 ? d.NudgeGuilty : (v == 1 ? d.NudgeInnocent : d.NudgeBoth);

        protected int LeastPopular(ConfessionData d)
        {
            int min = 0;
            if (d.SeedInnocent < d.SeedGuilty) min = 1;
            if (d.SeedBoth < (min == 0 ? d.SeedGuilty : d.SeedInnocent)) min = 2;
            return min;
        }

        protected void Nudge(SequenceContext ctx, MoralAxis axis, float value)
        {
            if (ctx.Profile != null && Mathf.Abs(value) > 0.0001f)
                ctx.Profile.Record(new[] { new AxisImpact(axis, value) });
        }

        protected IEnumerator FadeText(TextMeshPro label, float to, float dur)
        {
            if (label == null) yield break;
            float from = label.color.a, t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(label, Mathf.Lerp(from, to, t / d)); yield return null; }
            InkText.SetAlpha(label, to);
        }

        protected IEnumerator WaitAdvance(float lockout)
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
