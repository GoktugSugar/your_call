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
    /// The reusable Who Would Win matchup beat (Chapter 5). A total change of pace from the moral dilemmas:
    /// a barroom "who would win a fight" argument where there is no right or wrong, just the player's gut read,
    /// and the CROWD SPLIT is the whole payoff. It reuses the illustrated two-doodle presentation (the
    /// would-you-rather format): two fighters side by side, each a polished coloured ink doodle with a label
    /// and count (or a stylised crowd for the "many of something" sides), the imp poses the matchup and trash
    /// talks, the player picks a side, and the how-others-chose reveal shows the split. No death, no
    /// consequence, the lightest chapter: just the two doodles, the pick, the imp's banter, and the stat.
    ///
    /// One reusable beat type: a concrete matchup is a small subclass that returns its <see cref="MatchupData"/>
    /// (setup and trash talk, the two <see cref="MatchupSide"/>s, the seeded split, optional light profile
    /// nudge), so adding a matchup is data plus its doodles. Two subclasses override <see cref="PopulateSide"/>
    /// / <see cref="OnSidesShown"/> for the callback beats (the reused walking button, and the killed-everything
    /// finale's mob). The imp mocks whichever the player picks, choice independent, never grades.
    /// </summary>
    public abstract class MatchupBeat : SequenceBeat
    {
        [Header("Apparatus (shared)")]
        [SerializeField] protected MatchupKit _kit;

        [Header("Layout (two fighters side by side)")]
        [SerializeField] protected float _sideX = 3.0f;
        [SerializeField] protected float _doodleY = 0.65f;
        [SerializeField] protected float _soloScale = 1.2f;
        [SerializeField] protected float _labelY = -1.05f;
        [SerializeField] protected float _labelSize = 3.0f;
        [SerializeField] protected float _labelWidth = 3.5f;
        [SerializeField] protected int _sorting = 14;
        [Tooltip("Half width / half height of each clickable side region (around the fighter and its label).")]
        [SerializeField] protected Vector2 _pickHalfExtents = new Vector2(1.75f, 2.1f);
        [SerializeField] protected float _vsY = 0.55f;
        [SerializeField] protected float _vsSize = 3.2f;
        [SerializeField] protected string _vsText = "vs";

        [Header("Crowd (a stylised cluster of small units, the count in the label)")]
        [SerializeField] protected float _crowdUnitScale = 0.4f;
        [SerializeField] protected float _crowdSpreadX = 0.8f;
        [SerializeField] protected float _crowdBackY = 0.62f;
        [SerializeField] protected float _crowdFrontY = -0.55f;
        [Tooltip("Back-row units are drawn this fraction of the front-row size, so the mob reads with depth.")]
        [SerializeField] protected float _crowdBackScale = 0.68f;
        [SerializeField] protected float _crowdJitter = 0.11f;

        [Header("Feel")]
        [SerializeField] protected float _fadeIn = 0.4f;
        [SerializeField] protected float _fadeOut = 0.35f;
        [SerializeField] protected float _hoverScale = 1.06f;
        [SerializeField, Range(0f, 1f)] protected float _restLabelAlpha = 0.82f;
        [SerializeField] protected float _lineWidth = 0.05f;
        [SerializeField] protected float _keepoutPadding = 0.5f;

        [Header("Flourish (amber ink burst on the chosen side)")]
        [SerializeField] protected Color _flourishColor = Palette.Amber;
        [SerializeField] protected float _flourishRadius = 0.85f;
        [SerializeField, Range(3, 24)] protected int _flourishStrokes = 10;
        [SerializeField] protected float _flourishWidth = 0.05f;
        [SerializeField] protected float _flourishDuration = 0.6f;

        [Header("Timing")]
        [SerializeField] protected float _advanceLockout = 0.3f;
        [SerializeField] protected float _reactHold = 0.6f;
        [SerializeField] protected float _statsFade = 0.5f;
        [SerializeField] protected float _statsHideFade = 0.6f;

        protected Camera _cam;
        private Transform _content;
        protected SideView _sideA, _sideB;
        private TextMeshPro _vs;
        private float _hoverA, _hoverB;

        /// <summary>Each concrete matchup returns its data here (copy in code defaults, like the gun beats).</summary>
        protected abstract MatchupData BuildData();

        protected Camera Cam(SequenceContext ctx) => ctx != null && ctx.Camera != null ? ctx.Camera : Camera.main;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (_kit == null || _kit.InkMaterial == null)
            {
                Debug.LogError("[MatchupBeat] '" + Note + "' is missing its MatchupKit / ink material.");
                yield break;
            }
            var data = BuildData();
            if (data == null || data.A == null || data.B == null)
            {
                Debug.LogError("[MatchupBeat] '" + Note + "' produced no matchup data.");
                yield break;
            }
            _cam = Cam(ctx);

            // All content under one container, registered as a keep-out so the roaming imp never sits on a
            // fighter, and torn down as one at the end.
            _content = new GameObject("Matchup").transform;
            _content.SetParent(transform, false);
            var keep = _content.gameObject.AddComponent<ScreenKeepout>();
            keep.UseRendererBounds(_keepoutPadding);

            _sideA = BuildSideView(0, data.A, -_sideX);
            _sideB = BuildSideView(1, data.B, _sideX);
            _vs = MakeText("Vs", new Vector3(0f, _vsY, 0f), _vsSize, Palette.Muted);
            _vs.text = Localization.Localize(_vsText);

            StartCoroutine(FadeSide(_sideA, 1f, _fadeIn));
            StartCoroutine(FadeSide(_sideB, 1f, _fadeIn));
            yield return FadeText(_vs, 1f, _fadeIn);

            yield return OnSidesShown(ctx);   // the walking-button callback wakes its button here

            // The imp poses the matchup and eggs the bet on.
            yield return Lines(ctx, data.Setup);

            // Pick a side: click a fighter / its label, or key it (1/left, 2/right).
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

            // A small amber ink flourish on the chosen side (the light-beat consequence).
            float chosenX = picked == 0 ? -_sideX : _sideX;
            InkPoof.Spawn(new Vector3(chosenX, _doodleY, 0f), _kit.InkMaterial, _flourishColor,
                _flourishRadius, _flourishDuration, _flourishStrokes, _flourishWidth, _sorting + 4);
            yield return new WaitForSeconds(_flourishDuration * 0.5f);

            // The imp trash-talks whichever they backed (choice independent, never grades).
            yield return React(ctx, picked == 0 ? data.ReactA : data.ReactB);

            if (data.HasProfile) Nudge(ctx, data.Axis, picked == 0 ? data.NudgeA : data.NudgeB);

            // Lift the fighters, then the how-the-bar-voted reveal (the whole payoff).
            StartCoroutine(FadeSide(_sideA, 0f, _fadeOut));
            StartCoroutine(FadeSide(_sideB, 0f, _fadeOut));
            yield return FadeText(_vs, 0f, _fadeOut);
            yield return Reveal(ctx, data, picked);

            if (_content != null) Destroy(_content.gameObject);
        }

        // ---------- side building ----------

        /// <summary>One fighter side: a container transform holding its doodle(s) or a live figure, plus a label.</summary>
        protected sealed class SideView
        {
            public int Index;
            public Transform Root;
            public readonly List<InkDoodle> Doodles = new List<InkDoodle>();
            public WalkingButton Button;   // the callback opponent (null on a normal side)
            public TextMeshPro Label;
            public MatchupSide Side;
        }

        /// <summary>A single unit drawn in a crowd cluster: its doodle and colour.</summary>
        protected struct CrowdUnit
        {
            public DoodleKind Kind;
            public Color Color;
            public CrowdUnit(DoodleKind kind, Color color) { Kind = kind; Color = color; }
        }

        private SideView BuildSideView(int index, MatchupSide side, float centerX)
        {
            var view = new SideView { Index = index, Side = side };
            var rootGo = new GameObject(index == 0 ? "SideA" : "SideB");
            rootGo.transform.SetParent(_content, false);
            rootGo.transform.localPosition = new Vector3(centerX, _doodleY, 0f);
            view.Root = rootGo.transform;

            PopulateSide(view, side);

            view.Label = MakeText(index == 0 ? "LabelA" : "LabelB", new Vector3(centerX, _labelY, 0f), _labelSize, Palette.Ink);
            view.Label.rectTransform.sizeDelta = new Vector2(_labelWidth, 1.5f);
            view.Label.enableWordWrapping = true;
            view.Label.text = Localization.Localize(side.Label);
            InkText.SetAlpha(view.Label, 0f);
            return view;
        }

        /// <summary>Fill a side with its visuals. Default: a single fighter doodle, or a stylised crowd of the
        /// unit doodle. The callback beats override this (the walking button, the killed-everything mob).</summary>
        protected virtual void PopulateSide(SideView view, MatchupSide side)
        {
            if (side.Crowd)
            {
                var units = new List<CrowdUnit>();
                int n = Mathf.Max(1, side.CrowdDraw);
                for (int i = 0; i < n; i++) units.Add(new CrowdUnit(side.Doodle, side.Outline));
                BuildCrowd(view, units);
            }
            else
            {
                float sc = side.Scale > 0f ? side.Scale : _soloScale;
                view.Doodles.Add(InkDoodle.Create(view.Root, "Fighter", Vector3.zero, sc,
                    side.Doodle, _kit.InkMaterial, side.Outline, _lineWidth, _sorting));
            }
        }

        /// <summary>Lay a list of units out as a stylised mob: rows from back (small, high) to front (big, low),
        /// with horizontal spread and a little hand-placed jitter, so it reads as "a lot" cleanly (never the
        /// literal count). Shared by the homogeneous crowds and the finale's mixed mob of the dead.</summary>
        protected void BuildCrowd(SideView view, List<CrowdUnit> units)
        {
            int n = units.Count;
            if (n <= 0) return;
            int rows = n <= 3 ? 1 : (n <= 8 ? 2 : 3);
            int baseline = n / rows, extra = n % rows;
            int idx = 0;
            for (int row = 0; row < rows; row++)
            {
                int inRow = baseline + (row >= rows - extra ? 1 : 0);   // the extras sit on the front rows
                float rowT = rows > 1 ? row / (rows - 1f) : 0.5f;       // 0 = back, 1 = front
                float y = Mathf.Lerp(_crowdBackY, _crowdFrontY, rowT);
                float scaleMul = Mathf.Lerp(_crowdBackScale, 1f, rowT);
                int rowSorting = _sorting + row;                         // front draws over back
                for (int c = 0; c < inRow && idx < n; c++)
                {
                    float colT = inRow > 1 ? c / (inRow - 1f) : 0.5f;
                    float x = Mathf.Lerp(-_crowdSpreadX, _crowdSpreadX, colT) + (Hash(idx * 2) * 2f - 1f) * _crowdJitter;
                    float yy = y + (Hash(idx * 2 + 1) * 2f - 1f) * _crowdJitter * 0.6f;
                    var u = units[idx];
                    view.Doodles.Add(InkDoodle.Create(view.Root, "Unit" + idx, new Vector3(x, yy, 0f),
                        _crowdUnitScale * scaleMul, u.Kind, _kit.InkMaterial, u.Color, _lineWidth, rowSorting));
                    idx++;
                }
            }
        }

        // A stable pseudo-random in [0,1) from an index (the classic sin hash), so the mob layout is
        // hand-placed-looking and identical every time (no Random, which would jitter run to run).
        private static float Hash(int i)
        {
            float s = Mathf.Sin(i * 12.9898f) * 43758.5453f;
            return s - Mathf.Floor(s);
        }

        /// <summary>Hook run once both sides are inked in, before the imp poses the matchup. Default no-op; the
        /// walking-button callback overrides it to bring its button to life as a cheeky, offended fighter.</summary>
        protected virtual IEnumerator OnSidesShown(SequenceContext ctx) { yield break; }

        private TextMeshPro MakeText(string name, Vector3 localPos, float size, Color color)
        {
            var t = InkText.Create(_content, name, size, color, TextAlignmentOptions.Center, _sorting + 1);
            if (_kit.Font != null) t.font = _kit.Font;
            t.transform.localPosition = localPos;
            InkText.SetAlpha(t, 0f);
            return t;
        }

        // ---------- fade ----------

        private IEnumerator FadeSide(SideView view, float to, float dur)
        {
            bool inward = to > 0.5f;
            for (int i = 0; i < view.Doodles.Count; i++)
                if (view.Doodles[i] != null)
                    StartCoroutine(inward ? view.Doodles[i].FadeIn(dur) : view.Doodles[i].FadeOut(dur));

            float labelFrom = view.Label != null ? view.Label.color.a : 0f;
            float labelTo = inward ? _restLabelAlpha : 0f;
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = t / d;
                if (view.Label != null) InkText.SetAlpha(view.Label, Mathf.Lerp(labelFrom, labelTo, k));
                if (view.Button != null) view.Button.SetAlpha(inward ? k : 1f - k);
                yield return null;
            }
            if (view.Label != null) InkText.SetAlpha(view.Label, labelTo);
            if (view.Button != null) view.Button.SetAlpha(inward ? 1f : 0f);
        }

        private IEnumerator FadeText(TextMeshPro label, float to, float dur)
        {
            if (label == null) yield break;
            float from = label.color.a, t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d) { t += Time.deltaTime; InkText.SetAlpha(label, Mathf.Lerp(from, to, t / d)); yield return null; }
            InkText.SetAlpha(label, to);
        }

        // ---------- hover / pick ----------

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
            Vector2 c = _content.TransformPoint(new Vector3(centreX, (_doodleY + _labelY) * 0.5f, 0f));
            return Mathf.Abs(wp.x - c.x) <= _pickHalfExtents.x && Mathf.Abs(wp.y - c.y) <= _pickHalfExtents.y;
        }

        private int KeySide()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb != null && !PointerInput.Suppressed)
            {
                if (kb.digit1Key.wasPressedThisFrame || kb.leftArrowKey.wasPressedThisFrame) return 0;
                if (kb.digit2Key.wasPressedThisFrame || kb.rightArrowKey.wasPressedThisFrame) return 1;
            }
#endif
            return -1;
        }

        private void ApplyHover()
        {
            ApplyHover(_sideA, _hoverA);
            ApplyHover(_sideB, _hoverB);
        }

        private void ApplyHover(SideView view, float hover)
        {
            if (view == null) return;
            if (view.Root != null) view.Root.localScale = Vector3.one * Mathf.Lerp(1f, _hoverScale, hover);
            if (view.Label != null)
            {
                InkText.SetAlpha(view.Label, Mathf.Lerp(_restLabelAlpha, 1f, hover));
                view.Label.transform.localScale = Vector3.one * Mathf.Lerp(1f, _hoverScale, hover);
            }
        }

        // ---------- imp lines / reaction / reveal ----------

        /// <summary>Show one line, wait for it to finish, then a click to continue.</summary>
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

        /// <summary>The imp's trash talk, over the world, with the click gate before the crowd reveal (so the
        /// pick lands before the bar weighs in). Choice independent; never grades.</summary>
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

        /// <summary>The seeded how-the-bar-voted reveal: two bars in each side's own colour, the player's pick
        /// emphasised. Display only, seeded, the whole payoff of the beat.</summary>
        protected IEnumerator Reveal(SequenceContext ctx, MatchupData data, int picked)
        {
            var report = new ResolutionReport { Heading = data.Heading };
            var barA = new StatBar(data.A.Label, data.SeedA, picked == 0); barA.Tint = data.A.ResolveBarColor();
            var barB = new StatBar(data.B.Label, data.SeedB, picked == 1); barB.Tint = data.B.ResolveBarColor();
            report.MaxValue = Mathf.Max(1f, Mathf.Max(data.SeedA, data.SeedB));
            report.Bars.Add(barA);
            report.Bars.Add(barB);
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

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
