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
    /// The reusable campaign beat (Chapter 8, The Campaign). The imp runs the dead judge through a tiny
    /// tabletop RPG adventure as his DUNGEON MASTER: a bad, controlling, over enthusiastic DM who railroads the
    /// player and pretends the choices matter more than they do, breaking the fantasy for laughs (stepping out
    /// of character, reminding the player it is all pretend and he is still a dead judge in a void). The story
    /// beats are FIXED and linear; choices FLAVOR the beats, feed the silent profile and the crowd stat, and
    /// set FLAGS that change later beats (the companion and the village dilemma change the boss), but they do
    /// not fork the path.
    ///
    /// One reusable beat type, mirroring <see cref="ConfessionCaseBeat"/> / <see cref="MatchupBeat"/>: a
    /// concrete beat returns its <see cref="CampaignData"/> from <see cref="BuildData"/> (which is handed the
    /// run state, so options and text can vary by class and by the earlier flags). Options can be CLASS GATED
    /// (only the player's class sees them, the "class unlocks a unique option" mechanic) and can carry an
    /// <see cref="CampaignOption.Effect"/> that sets a chaining flag. When any option carries a doodle the beat
    /// draws a little coloured-doodle menu (the class and reason picks); otherwise the options are plain ink
    /// labels in the choice-affordance row (the adventure choices). The two roll beats and the finale override
    /// <see cref="SequenceBeat.Play"/> for the dice and the secret ending. The imp mocks whatever is picked,
    /// choice independent, never grades.
    /// </summary>
    public abstract class CampaignBeat : SequenceBeat
    {
        [Header("Apparatus (shared)")]
        [SerializeField] protected CampaignKit _kit;

        [Header("Option affordances (plain labels, the adventure choices)")]
        [SerializeField] protected float _optionRowY = -2.72f;
        [Tooltip("Ideal spacing between adjacent option centres; shrinks so more options still fit the width.")]
        [SerializeField] protected float _idealStep = 3.8f;
        [Tooltip("Max total span between the outermost option centres (keeps five options on screen).")]
        [SerializeField] protected float _rowMaxSpan = 10.8f;
        [SerializeField] protected float _optionSize = 2.4f;
        [SerializeField] protected float _optionWidth = 3.5f;
        [SerializeField, Range(0f, 1f)] protected float _optionRest = 0.72f;
        [SerializeField] protected float _optionHoverScale = 1.08f;
        [SerializeField] protected Vector2 _optionPickHalf = new Vector2(1.75f, 0.7f);
        [SerializeField] protected float _optionFade = 0.22f;
        [SerializeField] protected int _sorting = 20;

        [Header("Doodle menu (class / reason picks: doodle over its label)")]
        [SerializeField] protected float _menuDoodleY = 0.75f;
        [SerializeField] protected float _menuLabelY = -1.15f;
        [SerializeField] protected float _doodleScale = 0.95f;
        [SerializeField] protected float _lineWidth = 0.05f;

        [Header("Flourish (amber ink burst on the chosen option)")]
        [SerializeField] protected float _flourishRadius = 0.72f;
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
        protected int _picked = -1;

        /// <summary>Each concrete beat returns its data here (copy in code defaults, like the matchup / gun /
        /// confession beats). The run state is passed so options and text can vary by class and earlier flags.</summary>
        protected abstract CampaignData BuildData(CampaignState state);

        protected Camera Cam(SequenceContext ctx) => ctx != null && ctx.Camera != null ? ctx.Camera : Camera.main;
        protected CampaignState State => _kit != null ? _kit.State : null;

        // ---------- the standard choice beat flow ----------

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!Ready()) yield break;
            var state = _kit.State;
            var data = BuildData(state);
            if (data == null || data.Options.Count == 0)
            {
                Debug.LogError("[CampaignBeat] '" + Note + "' produced no options.");
                yield break;
            }
            _cam = Cam(ctx);
            BeginContent();

            // An optional scene doodle for the whole beat (the companion, the beast, the hoard, the dragon).
            DrawSceneDoodle(data);

            // The imp DMs the beat (and breaks the fantasy for laughs, in the copy).
            yield return Lines(ctx, data.Narration);

            // Only the options available to this class (a common option always is; a class option only for its
            // class). If the class is unset (a dev jump straight to a mid beat), only the common options show.
            var vis = VisibleOptions(data, state.Class);
            if (vis.Count == 0) { EndContent(); yield break; }

            if (!string.IsNullOrEmpty(data.RulePrompt)) yield return Line(ctx, data.RulePrompt);

            yield return Choose(ctx, vis);           // sets _picked
            var opt = vis[_picked];

            // The imp reacts (choice independent, never grades), then the flags / profile fold in.
            yield return React(ctx, opt.React);
            opt.Effect?.Invoke(state);
            if (opt.HasProfile) Nudge(ctx, opt.Axis, opt.Nudge);

            // The seeded how-others-chose split (what kind of adventurer are you).
            yield return Reveal(ctx, data.Heading, vis, _picked);
            EndContent();
        }

        protected List<CampaignOption> VisibleOptions(CampaignData data, CampaignClass cls)
        {
            var vis = new List<CampaignOption>();
            for (int i = 0; i < data.Options.Count; i++)
                if (data.Options[i] != null && data.Options[i].AvailableTo(cls)) vis.Add(data.Options[i]);
            return vis;
        }

        // ---------- readiness / content ----------

        protected bool Ready()
        {
            if (_kit == null || _kit.InkMaterial == null)
            {
                Debug.LogError("[CampaignBeat] '" + Note + "' is missing its CampaignKit / ink material.");
                return false;
            }
            return true;
        }

        protected void BeginContent()
        {
            _content = new GameObject("Beat").transform;
            _content.SetParent(transform, false);
            var keep = _content.gameObject.AddComponent<ScreenKeepout>();
            keep.UseRendererBounds(_keepoutPadding);
        }

        protected void EndContent()
        {
            if (_content != null) Destroy(_content.gameObject);
            _content = null;
        }

        /// <summary>Ink in the beat's optional scene doodle (parented under the content, so it is torn down with
        /// the beat). Returns the doodle, or null if the beat has none.</summary>
        protected InkDoodle DrawSceneDoodle(CampaignData data)
        {
            if (data == null || data.SceneDoodle == DoodleKind.None || _content == null) return null;
            Color col = data.SceneOutline.a > 0f ? data.SceneOutline : InkDoodle.DefaultColorFor(data.SceneDoodle);
            var doodle = InkDoodle.Create(_content, "Scene", new Vector3(data.ScenePos.x, data.ScenePos.y, 0f),
                data.SceneScale, data.SceneDoodle, _kit.InkMaterial, col, _lineWidth, _sorting - 2);
            StartCoroutine(doodle.FadeIn(0.5f));
            return doodle;
        }

        // ---------- imp DM narration ----------

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

        /// <summary>The imp's DM reaction to the choice, with the click gate before the crowd reveal (so the
        /// choice lands before the room weighs in). Choice independent; never grades.</summary>
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

        // ---------- the option pick (N options, optional doodle menu) ----------

        private sealed class OptionView
        {
            public float X;
            public bool HasDoodle;
            public InkDoodle Doodle;
            public TextMeshPro Label;
            public float CenterY, HalfY;
        }

        protected IEnumerator Choose(SequenceContext ctx, List<CampaignOption> opts)
        {
            _picked = -1;
            int n = opts.Count;
            float[] xs = SpreadX(n);
            var views = new OptionView[n];
            for (int i = 0; i < n; i++) views[i] = BuildOption(opts[i], xs[i]);

            // ink the labels (and doodles) on
            float f = 0f;
            while (f < 0.22f)
            {
                f += Time.deltaTime;
                float k = f / 0.22f;
                for (int i = 0; i < n; i++)
                {
                    InkText.SetAlpha(views[i].Label, _optionRest * k);
                    if (views[i].Doodle != null) views[i].Doodle.SetAlpha(Mathf.Clamp01(k * 1.2f));
                }
                yield return null;
            }

            int picked = -1;
            var hover = new float[n];
            while (picked < 0)
            {
                int hv = HoverOption(views);
                for (int i = 0; i < n; i++)
                {
                    hover[i] = Mathf.MoveTowards(hover[i], hv == i ? 1f : 0f, Time.deltaTime / 0.1f);
                    ApplyHover(views[i], hover[i]);
                }
                if (hv >= 0 && PointerInput.Clicked) { picked = hv; break; }
                int key = KeyOption(n);
                if (key >= 0) { picked = key; break; }
                yield return null;
            }
            _picked = picked;

            // the light amber ink flourish on the chosen option
            float flY = views[picked].HasDoodle ? _menuDoodleY : _optionRowY;
            Vector3 world = _content.TransformPoint(new Vector3(xs[picked], flY, 0f));
            InkPoof.Spawn(world, _kit.InkMaterial, Palette.Amber, _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _sorting + 4);

            for (int i = 0; i < n; i++) StartCoroutine(FadeOption(views[i], _optionFade));
            yield return new WaitForSeconds(_optionFade + 0.02f);
            for (int i = 0; i < n; i++)
            {
                if (views[i].Doodle != null) Destroy(views[i].Doodle.gameObject);
                if (views[i].Label != null) Destroy(views[i].Label.gameObject);
            }
        }

        private OptionView BuildOption(CampaignOption opt, float x)
        {
            var v = new OptionView { X = x, HasDoodle = opt.Doodle != DoodleKind.None };
            if (v.HasDoodle)
            {
                v.Doodle = InkDoodle.Create(_content, "Doodle", new Vector3(x, _menuDoodleY, 0f), _doodleScale,
                    opt.Doodle, _kit.InkMaterial, opt.ResolveOutline(), _lineWidth, _sorting);
            }
            float labelY = v.HasDoodle ? _menuLabelY : _optionRowY;
            var t = InkText.Create(_content, "Opt", _optionSize, Palette.Ink, TextAlignmentOptions.Center, _sorting);
            if (_kit.Font != null) t.font = _kit.Font;
            t.rectTransform.sizeDelta = new Vector2(_optionWidth, v.HasDoodle ? 1.2f : 2.0f);
            t.enableWordWrapping = true;
            t.transform.localPosition = new Vector3(x, labelY, 0f);
            t.text = Localization.Localize(opt.Label);
            InkText.SetAlpha(t, 0f);
            v.Label = t;

            v.CenterY = v.HasDoodle ? (_menuDoodleY + _menuLabelY) * 0.5f : _optionRowY;
            v.HalfY = v.HasDoodle ? Mathf.Abs(_menuDoodleY - _menuLabelY) * 0.5f + 0.55f : _optionPickHalf.y;
            return v;
        }

        // Spread N option centres across the row, shrinking the spacing so five still fit (see the fields).
        private float[] SpreadX(int n)
        {
            var xs = new float[n];
            if (n <= 1) { xs[0] = 0f; return xs; }
            float step = Mathf.Min(_idealStep, _rowMaxSpan / (n - 1));
            for (int i = 0; i < n; i++) xs[i] = (i - (n - 1) * 0.5f) * step;
            return xs;
        }

        private int HoverOption(OptionView[] views)
        {
            if (_cam == null) return -1;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            for (int i = 0; i < views.Length; i++)
            {
                Vector2 c = _content.TransformPoint(new Vector3(views[i].X, views[i].CenterY, 0f));
                if (Mathf.Abs(wp.x - c.x) <= _optionPickHalf.x && Mathf.Abs(wp.y - c.y) <= views[i].HalfY) return i;
            }
            return -1;
        }

        private int KeyOption(int n)
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null && !PointerInput.Suppressed)
            {
                if (n >= 1 && kb.digit1Key.wasPressedThisFrame) return 0;
                if (n >= 2 && kb.digit2Key.wasPressedThisFrame) return 1;
                if (n >= 3 && kb.digit3Key.wasPressedThisFrame) return 2;
                if (n >= 4 && kb.digit4Key.wasPressedThisFrame) return 3;
                if (n >= 5 && kb.digit5Key.wasPressedThisFrame) return 4;
            }
#endif
            return -1;
        }

        private void ApplyHover(OptionView v, float hover)
        {
            if (v.Label != null)
            {
                InkText.SetAlpha(v.Label, Mathf.Lerp(_optionRest, 1f, hover));
                float s = Mathf.Lerp(1f, _optionHoverScale, hover);
                v.Label.transform.localScale = new Vector3(s, s, 1f);
            }
            if (v.Doodle != null)
            {
                float s = Mathf.Lerp(1f, _optionHoverScale, hover);
                v.Doodle.transform.localScale = new Vector3(_doodleScale * s, _doodleScale * s, 1f);
            }
        }

        private IEnumerator FadeOption(OptionView v, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            float labelFrom = v.Label != null ? v.Label.color.a : 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float k = t / d;
                if (v.Label != null) InkText.SetAlpha(v.Label, Mathf.Lerp(labelFrom, 0f, k));
                if (v.Doodle != null) v.Doodle.SetAlpha(1f - k);
                yield return null;
            }
        }

        // ---------- the seeded reveal ----------

        protected IEnumerator Reveal(SequenceContext ctx, string heading, List<CampaignOption> opts, int picked)
        {
            var report = new ResolutionReport { Heading = heading };
            float max = 1f;
            for (int i = 0; i < opts.Count; i++)
            {
                report.Bars.Add(new StatBar(opts[i].Label, opts[i].Seed, i == picked));
                max = Mathf.Max(max, opts[i].Seed);
            }
            report.MaxValue = max;
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // ---------- helpers ----------

        protected void Nudge(SequenceContext ctx, MoralAxis axis, float value)
        {
            if (ctx.Profile != null && Mathf.Abs(value) > 0.0001f)
                ctx.Profile.Record(new[] { new AxisImpact(axis, value) });
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
