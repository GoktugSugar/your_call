using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using TMPro;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// The Cancer and Nuke Button (Chapter 2). A single red button: press it and cancer is cured,
    /// forever, for everyone; the cost is that one country, chosen at random anywhere on Earth, is
    /// nuked off the map. Dark comedy roulette in the game's stick style.
    ///
    /// Refuse and the imp mocks the squeamishness (all those lives, too delicate to spend a place you
    /// will never visit), the beat ends, and the run continues. Press and a hand-drawn ink WORLD MAP
    /// fades in, a small red PIN drops from the top and lands on a genuinely random country's LANDMASS,
    /// and its accurate NAME and (approximate, bundled) POPULATION read out below the map. Then the imp
    /// reacts to wherever it landed, delighting in it (needling a tiny country like the Vatican, or a
    /// giant like China, and a special jab if it is the player's own). Choice independent, never grading.
    ///
    /// Self contained (one script, one job): it owns the button, the map, the pin, and the readout, all
    /// built at runtime from ink strokes, and reuses the shared choice affordance, the imp,
    /// the StatsView (a seeded press vs refuse split), and the silent Profile. The country roster, the
    /// pin positions, and every timing are exposed data / [SerializeField]. The populations are
    /// APPROXIMATE bundled placeholders, not live data. DilemmaStage/DilemmaRunner stay generic; this is
    /// another beat the SequencePlayer plays in order.
    /// </summary>
    public sealed class CancerNukeButtonBeat : SequenceBeat
    {
        [Header("References")]
        [SerializeField] private Material _inkMaterial;
        [Tooltip("Optional font for the button label and the country readout (Caveat). Empty uses the default.")]
        [SerializeField] private TMP_FontAsset _font;

        [Header("The red button (single, danger red)")]
        [SerializeField] private Vector2 _buttonPosition = new Vector2(0f, 0.2f);
        [SerializeField] private float _buttonRadius = 0.85f;
        [SerializeField] private float _lineWidth = 0.06f;
        [Tooltip("Resting colour of the button: the danger/death red (red = danger, per the palette).")]
        [SerializeField] private Color _buttonInk = Palette.InkRed;
        [Tooltip("The button brightens to the amber attention accent on hover, like the lever and the timer button.")]
        [SerializeField] private Color _buttonHot = Palette.Amber;
        [Tooltip("Optional button label. Empty draws no text (pressable without it, like the blue/red buttons).")]
        [SerializeField] private string _buttonLabel = "";
        [SerializeField] private float _buttonLabelSize = 2.6f;
        [SerializeField] private int _buttonSorting = 14;
        [SerializeField] private float _buttonFadeIn = 0.4f;
        [SerializeField] private float _buttonFadeOut = 0.35f;

        [Header("The ink world map (equirectangular doodle)")]
        [Tooltip("Centre of the map on screen (raised so a clean band sits below the frame for the readout).")]
        [SerializeField] private Vector2 _mapAnchor = new Vector2(0f, 1.0f);
        [Tooltip("Half width of the map (x = longitude -180..180 maps to -halfWidth..+halfWidth).")]
        [SerializeField] private float _mapHalfWidth = 4.6f;
        [Tooltip("Half height of the map (y = latitude -90..90 maps to -halfHeight..+halfHeight).")]
        [SerializeField] private float _mapHalfHeight = 1.85f;
        [SerializeField] private float _mapLineWidth = 0.05f;
        [SerializeField] private Color _mapInk = Palette.Ink;
        [SerializeField] private int _mapSorting = 12;
        [Tooltip("Draw a faint frame around the map so it reads as a chart, not floating continents.")]
        [SerializeField] private bool _mapFrame = true;
        [SerializeField] private float _mapFadeIn = 0.7f;

        [Header("The pin (drops from the top of the screen)")]
        [SerializeField] private Color _pinColor = Palette.InkRed;
        [SerializeField] private float _pinScale = 1f;
        [SerializeField] private float _pinLineWidth = 0.055f;
        [SerializeField] private int _pinSorting = 22;
        [Tooltip("How long the pin takes to fall onto its country.")]
        [SerializeField] private float _pinDropDuration = 0.6f;
        [SerializeField] private float _pinSettle = 0.18f;

        [Header("The country readout (name in ink, population in amber)")]
        [Tooltip("Where the name/population caption sits: in the clean band below the map frame, clear of the border.")]
        [SerializeField] private Vector2 _readoutAnchor = new Vector2(0f, -2.05f);
        [SerializeField] private float _nameSize = 3.4f;
        [SerializeField] private float _popSize = 2.7f;
        [SerializeField] private Color _nameColor = Palette.Ink;
        [SerializeField] private Color _popColor = Palette.Amber;
        [SerializeField] private int _readoutSorting = 24;
        [SerializeField] private float _readoutFade = 0.35f;
        [Tooltip("Suffix after the population number, e.g. '410,000,000 people'. No dashes.")]
        [SerializeField] private string _popSuffix = " people, give or take";

        [Header("Crowd split (seeded; press vs refuse)")]
        [SerializeField] private int _pressSeed = 71;
        [SerializeField] private int _refuseSeed = 29;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _pressStatLabel = "pressed it";
        [SerializeField] private string _refuseStatLabel = "would not";

        [Header("Profile (silent, light; ends vs rules)")]
        [Tooltip("Recorded on ends-vs-rules. Pressing (a whole disease cured at the cost of a nuked country) leans ends " +
                 "(negative); refusing (will not nuke innocents even for that) leans rules (positive). See MoralAxis.")]
        [SerializeField] private float _endsNudge = 0.15f;

        [Header("Copy (the imp; no dashes)")]
        [Tooltip("The offer, shown in order, a click between each.")]
        [SerializeField, TextArea(2, 5)] private string[] _offerLines = new[]
        {
            "Here. A red button, and a genuinely good deal for once. Press it and [red]cancer[/red] is cured. All of it. Forever, for everyone, every kind, gone for good. No more wards, no more waiting rooms, no more of those little bald children you all find so upsetting.",
            "The price is small. Trivial, really. [amber]One country.[/amber] Somewhere on this Earth, chosen at [amber]random[/amber], and I [red]wipe it off the map.[/red] Everyone in it. Could be anywhere. Press it and save the countless, or keep your soft little hands clean. Your call.",
        };
        [Tooltip("If they refuse. Choice independent, never graded (mock the squeamishness, not the morality).")]
        [SerializeField, TextArea(2, 5)] private string _refuseReact =
            "You will not press it. Every [red]cancer[/red] there will ever be, wiped off the board forever, and you would not spend one country you could not even find on a map. All those wards, still full, because you could not stomach a gamble on strangers with the wrong postcode. Too squeamish. What a judge you were.";

        [Tooltip("Imp line while the pin is still falling (a drumroll). Choice independent.")]
        [SerializeField, TextArea(1, 3)] private string _pinDropLine =
            "Round and round it goes. Do try to look excited. This is the fun part.";

        [Tooltip("Reaction for a TINY country (population below the small threshold). {0}=name, {1}=population. Delight, never graded.")]
        [SerializeField, TextArea(2, 4)] private string _tinyJab =
            "Ha! [amber]{0}[/amber]. All [amber]{1}[/amber] of them. Off an entire planet to aim at, the dice found a rounding error. Somewhere a cancer ward is cheering and a very small country is a crater. Perfect.";
        [Tooltip("Reaction for a SMALL country. {0}=name, {1}=population.")]
        [SerializeField, TextArea(2, 4)] private string _smallJab =
            "[amber]{0}[/amber]. [amber]{1}[/amber] souls, and none of them saw it coming, because how could they. You cured a disease and mislaid a country. I did say it was random.";
        [Tooltip("Reaction for a LARGE country. {0}=name, {1}=population.")]
        [SerializeField, TextArea(2, 4)] private string _largeJab =
            "Oh, [amber]{0}[/amber]. [amber]{1}[/amber] people, and all it took was one small red pin. A whole real country for a clean scan. Bold trade. I would never have dared, and you did it with your thumb.";
        [Tooltip("Reaction for a HUGE country (population above the huge threshold). {0}=name, {1}=population.")]
        [SerializeField, TextArea(2, 4)] private string _hugeJab =
            "[amber]{0}.[/amber] [amber]{1}[/amber] people. You did not pick a country, you picked a small civilisation, and the button did not blink and neither did you. Cancer is cured. So is [amber]{0}[/amber], in a manner of speaking.";
        [Tooltip("Special jab when the pin lands on the player's OWN country (detected by region). {0}=name, {1}=population. Delight, never graded.")]
        [SerializeField, TextArea(2, 5)] private string _selfCountryJab =
            "Oh. Oh, this is delicious. [amber]{0}[/amber]. That is yours, is it not. Home. [amber]{1}[/amber] of your very own, and your thumb did not so much as twitch. Whatever they say about you at the end, they cannot say you played favourites.";

        [Tooltip("Population thresholds for the size buckets above.")]
        [SerializeField] private long _tinyBelow = 100000L;
        [SerializeField] private long _smallBelow = 5000000L;
        [SerializeField] private long _hugeAtLeast = 100000000L;

        [Header("Choice affordance labels (no dashes)")]
        [SerializeField] private string _pressLabel = "Press it";
        [SerializeField] private string _refuseLabel = "Refuse";

        [Header("Timing")]
        [SerializeField] private float _advanceLockout = 0.3f;
        [SerializeField] private float _preMapBeat = 0.3f;
        [SerializeField] private float _postPinBeat = 0.35f;
        [SerializeField] private float _reactHold = 0.4f;
        [SerializeField] private float _statsFade = 0.5f;
        [SerializeField] private float _statsHideFade = 0.6f;
        [SerializeField] private float _teardownFade = 0.5f;

        [Header("The country roster (bundled; approximate populations, tunable pins)")]
        [Tooltip("Genuinely picked at random each play. Name, ISO (for the self-country jab), approximate population, " +
                 "and a normalised pin (x,y each -1..1 = longitude/latitude). Correct and expand freely; populations are placeholders.")]
        [SerializeField] private List<NukeCountry> _countries = new List<NukeCountry>
        {
            // Tiny
            new NukeCountry("Vatican City", "VA", 800L, new Vector2(0.061f, 0.511f), "The [amber]Vatican[/amber]. Eight hundred people and the odd infallible one. You aimed a nuclear weapon at God's landlord to cure a cough. I am beside myself."),
            new NukeCountry("Nauru", "NR", 11000L, new Vector2(0.950f, -0.122f)),
            new NukeCountry("Tuvalu", "TV", 11000L, new Vector2(0.965f, -0.140f)),
            new NukeCountry("San Marino", "SM", 34000L, new Vector2(0.072f, 0.522f)),
            new NukeCountry("Monaco", "MC", 38000L, new Vector2(0.039f, 0.511f), "[amber]Monaco[/amber]. The richest little rock on Earth, and you glassed it to cure cancer. Somewhere an accountant is weeping and I am delighted."),
            new NukeCountry("Liechtenstein", "LI", 39000L, new Vector2(0.053f, 0.524f)),
            // Small
            new NukeCountry("Iceland", "IS", 380000L, new Vector2(-0.106f, 0.721f)),
            new NukeCountry("Malta", "MT", 520000L, new Vector2(0.078f, 0.467f)),
            new NukeCountry("Luxembourg", "LU", 660000L, new Vector2(0.034f, 0.553f)),
            new NukeCountry("Fiji", "FJ", 930000L, new Vector2(0.950f, -0.167f)),
            new NukeCountry("Estonia", "EE", 1300000L, new Vector2(0.142f, 0.651f)),
            new NukeCountry("Jamaica", "JM", 2800000L, new Vector2(-0.467f, 0.167f)),
            new NukeCountry("Mongolia", "MN", 3300000L, new Vector2(0.572f, 0.521f), "[amber]Mongolia[/amber]. All that empty sky and only [amber]3,300,000[/amber] under it. You could not have missed more people if you tried, and cancer is still cured. Efficient."),
            // Medium
            new NukeCountry("New Zealand", "NZ", 5100000L, new Vector2(0.956f, -0.456f)),
            new NukeCountry("Ireland", "IE", 5100000L, new Vector2(-0.050f, 0.600f)),
            new NukeCountry("Norway", "NO", 5400000L, new Vector2(0.050f, 0.678f)),
            new NukeCountry("Switzerland", "CH", 8700000L, new Vector2(0.046f, 0.520f)),
            new NukeCountry("Sweden", "SE", 10400000L, new Vector2(0.083f, 0.689f)),
            new NukeCountry("Portugal", "PT", 10300000L, new Vector2(-0.036f, 0.440f)),
            new NukeCountry("Greece", "GR", 10400000L, new Vector2(0.122f, 0.478f)),
            new NukeCountry("Chile", "CL", 19600000L, new Vector2(-0.372f, -0.383f)),
            new NukeCountry("Australia", "AU", 26000000L, new Vector2(0.744f, -0.278f), "[amber]Australia[/amber]. An entire continent, mostly spiders, and you volunteered the lot. The spiders had it coming. The [amber]26,000,000[/amber] people, less so. Cancer is cured, though."),
            new NukeCountry("Canada", "CA", 39000000L, new Vector2(-0.589f, 0.644f)),
            new NukeCountry("Poland", "PL", 38000000L, new Vector2(0.106f, 0.578f)),
            new NukeCountry("Argentina", "AR", 46000000L, new Vector2(-0.356f, -0.422f)),
            new NukeCountry("Kenya", "KE", 54000000L, new Vector2(0.211f, 0.002f)),
            new NukeCountry("South Korea", "KR", 52000000L, new Vector2(0.685f, 0.428f)),
            new NukeCountry("Spain", "ES", 47000000L, new Vector2(-0.021f, 0.449f)),
            new NukeCountry("France", "FR", 65000000L, new Vector2(0.013f, 0.518f)),
            new NukeCountry("United Kingdom", "GB", 67000000L, new Vector2(-0.030f, 0.600f)),
            // Huge
            new NukeCountry("Egypt", "EG", 110000000L, new Vector2(0.167f, 0.298f)),
            new NukeCountry("Japan", "JP", 124000000L, new Vector2(0.767f, 0.411f)),
            new NukeCountry("Mexico", "MX", 128000000L, new Vector2(-0.567f, 0.262f)),
            new NukeCountry("Brazil", "BR", 215000000L, new Vector2(-0.283f, -0.111f)),
            new NukeCountry("Nigeria", "NG", 223000000L, new Vector2(0.044f, 0.107f)),
            new NukeCountry("United States", "US", 335000000L, new Vector2(-0.544f, 0.442f)),
            new NukeCountry("Indonesia", "ID", 277000000L, new Vector2(0.650f, -0.050f)),
            new NukeCountry("India", "IN", 1430000000L, new Vector2(0.439f, 0.244f), "[amber]India.[/amber] [amber]1,430,000,000[/amber] people. That is not a country, that is nearly one in five of every human breathing, and you spent them on a cure like loose change. I could kiss you."),
            new NukeCountry("China", "CN", 1410000000L, new Vector2(0.578f, 0.389f), "[amber]China.[/amber] [amber]1,410,000,000[/amber] people, and the button did not so much as hesitate, and neither did you. You cured cancer and unpicked a fifth of the species in the same little press. Magnificent."),
        };

        private Camera _cam;
        private GameObject _buttonRoot;
        private LineRenderer _buttonOutline;
        private TextMeshPro _buttonText;
        private Transform _mapRoot;
        private readonly List<LineRenderer> _mapStrokes = new List<LineRenderer>();
        private Transform _pin;
        private readonly List<LineRenderer> _pinStrokes = new List<LineRenderer>();
        private TextMeshPro _nameLabel;
        private TextMeshPro _popLabel;
        private int _picked = -1;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (ctx.Choices == null)
            {
                Debug.LogError("[CancerNukeButtonBeat] '" + Note + "' needs the shared ChoiceButtons.");
                yield break;
            }
            _cam = ctx.Camera != null ? ctx.Camera : Camera.main;

            BuildButton();
            yield return FadeButton(0f, 1f, _buttonFadeIn);

            // The offer.
            if (_offerLines != null)
            {
                for (int i = 0; i < _offerLines.Length; i++)
                {
                    if (string.IsNullOrEmpty(_offerLines[i])) continue;
                    ctx.Narrator.Show(_offerLines[i]);
                    while (ctx.Narrator.IsShowing) yield return null;
                    if (i < _offerLines.Length - 1) yield return WaitAdvance(_advanceLockout);
                }
            }

            // Press (click the red button or the Press choice) or refuse.
            _picked = -1;
            ctx.Choices.Chosen += OnPicked;
            ctx.Choices.Present(_pressLabel, _refuseLabel);
            while (_picked < 0)
            {
                bool hot = OverButton();
                ApplyButtonVisual(hot);
                if (hot && PointerInput.Clicked) { _picked = 0; break; }
                yield return null;
            }
            ctx.Choices.Chosen -= OnPicked;
            ctx.Choices.Dismiss();
            bool pressed = _picked == 0;

            ctx.Narrator.Clear();
            yield return FadeButton(1f, 0f, _buttonFadeOut);
            TeardownButton();

            if (pressed) yield return PlayNuke(ctx);
            else
            {
                ctx.Narrator.Show(_refuseReact);
                while (ctx.Narrator.IsShowing) yield return null;
                yield return WaitAdvance(_advanceLockout);
                ctx.Narrator.Clear();
            }

            // Silent profile nudge: ends (press) vs rules (refuse). Light.
            ctx.Profile.Record(new[] { new AxisImpact(MoralAxis.EndsVsRules, pressed ? -_endsNudge : _endsNudge) });

            // How others chose.
            var report = new ResolutionReport { Heading = _statsHeading };
            report.MaxValue = Mathf.Max(1, Mathf.Max(_pressSeed, _refuseSeed));
            report.Bars.Add(new StatBar(_pressStatLabel, _pressSeed, pressed));
            report.Bars.Add(new StatBar(_refuseStatLabel, _refuseSeed, !pressed));
            yield return ctx.Stats.Reveal(report, _statsFade);
            yield return WaitAdvance(_advanceLockout);
            yield return ctx.Stats.Hide(_statsHideFade);
        }

        // Press: the map fades in, the pin drops on a random country, its name and population read out,
        // the blast doodles on, and the imp delights in wherever it landed. Choice independent.
        private IEnumerator PlayNuke(SequenceContext ctx)
        {
            if (_countries == null || _countries.Count == 0)
            {
                Debug.LogError("[CancerNukeButtonBeat] '" + Note + "' has no countries to pick from.");
                yield break;
            }
            if (_preMapBeat > 0f) yield return new WaitForSeconds(_preMapBeat);

            BuildMap();
            yield return FadeMap(0f, 1f, _mapFadeIn);

            // Genuinely random each play.
            NukeCountry country = _countries[Random.Range(0, _countries.Count)];
            Vector3 target = MapToWorld(country.Pin);

            // Drop the pin from the top of the screen onto the country, with a drumroll line.
            ctx.Narrator.Show(_pinDropLine);
            yield return DropPin(target);
            if (_postPinBeat > 0f) yield return new WaitForSeconds(_postPinBeat);

            // Name and population, a clean red pin on the country. No blast, nothing around the pin.
            ShowReadout(country);
            yield return FadeReadout(1f);
            if (_reactHold > 0f) yield return new WaitForSeconds(_reactHold);

            ctx.Narrator.Clear();

            // The imp reacts to wherever it hit. Choice independent, never graded.
            ctx.Narrator.Show(ReactionFor(country));
            while (ctx.Narrator.IsShowing) yield return null;
            yield return new WaitForSeconds(_reactHold);
            yield return WaitAdvance(_advanceLockout);
            ctx.Narrator.Clear();

            yield return TeardownMap();
        }

        private string ReactionFor(NukeCountry c)
        {
            string pop = c.Population.ToString("#,0", CultureInfo.InvariantCulture);
            string name = c.Name;
            if (IsHomeCountry(c)) return Format(_selfCountryJab, name, pop);
            if (!string.IsNullOrEmpty(c.Quip)) return c.Quip;
            if (c.Population < _tinyBelow) return Format(_tinyJab, name, pop);
            if (c.Population < _smallBelow) return Format(_smallJab, name, pop);
            if (c.Population >= _hugeAtLeast) return Format(_hugeJab, name, pop);
            return Format(_largeJab, name, pop);
        }

        private static string Format(string fmt, string name, string pop)
        {
            if (string.IsNullOrEmpty(fmt)) return name;
            return fmt.Replace("{0}", name).Replace("{1}", pop);
        }

        // Best-effort detection of the player's own country, for the special jab. Null-safe: any failure
        // (or no match) simply means no self-jab, and a size bucket is used instead.
        private bool IsHomeCountry(NukeCountry c)
        {
            if (c == null || string.IsNullOrEmpty(c.Iso)) return false;
            string home = null;
            try { home = System.Globalization.RegionInfo.CurrentRegion.TwoLetterISORegionName; }
            catch { home = null; }
            return !string.IsNullOrEmpty(home) && string.Equals(home, c.Iso, System.StringComparison.OrdinalIgnoreCase);
        }

        private void OnPicked(int index) { if (_picked < 0) _picked = index; }

        // ---- the red button ----

        private void BuildButton()
        {
            _buttonRoot = new GameObject("NukeButton");
            _buttonRoot.transform.SetParent(transform, false);
            _buttonRoot.transform.localPosition = new Vector3(_buttonPosition.x, _buttonPosition.y, 0f);

            _buttonOutline = InkLine.Create(_buttonRoot.transform, "Outline", _inkMaterial, _lineWidth, _buttonInk, _buttonSorting);
            var ring = new List<Vector3>();
            InkLine.AddArc(ring, Vector2.zero, _buttonRadius, 0f, 360f, 40);
            InkLine.SetPoints(_buttonOutline, ring);
            if (_buttonOutline.gameObject.GetComponent<LineBoil>() == null) _buttonOutline.gameObject.AddComponent<LineBoil>().Capture();
            InkLine.SetAlpha(_buttonOutline, _buttonInk, 0f);

            // The button is pressable without a label (consistent with the blue/red buttons); only draw
            // text if a label is set.
            if (!string.IsNullOrEmpty(_buttonLabel))
            {
                _buttonText = InkText.Create(_buttonRoot.transform, "Label", _buttonLabelSize, _buttonInk, TextAlignmentOptions.Center, _buttonSorting + 1);
                if (_font != null) _buttonText.font = _font;
                _buttonText.rectTransform.sizeDelta = new Vector2(_buttonRadius * 2.2f, 1f);
                _buttonText.transform.localPosition = Vector3.zero;
                _buttonText.text = _buttonLabel;
                InkText.SetAlpha(_buttonText, 0f);
            }
        }

        private bool OverButton()
        {
            if (_cam == null || _buttonRoot == null) return false;
            Vector3 wp = PointerInput.WorldPosition(_cam, 0f);
            Vector2 c = _buttonRoot.transform.position;
            return ((Vector2)wp - c).sqrMagnitude <= _buttonRadius * _buttonRadius;
        }

        private void ApplyButtonVisual(bool hot)
        {
            if (_buttonOutline == null) return;
            Color c = hot ? _buttonHot : _buttonInk;
            InkLine.SetColor(_buttonOutline, c);
            _buttonOutline.widthMultiplier = _lineWidth * (hot ? 1.3f : 1f);
            if (_buttonText != null) _buttonText.color = c;
        }

        private IEnumerator FadeButton(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                if (_buttonOutline != null) InkLine.SetAlpha(_buttonOutline, _buttonOutline.startColor, a);
                if (_buttonText != null) InkText.SetAlpha(_buttonText, a);
                yield return null;
            }
        }

        private void TeardownButton()
        {
            if (_buttonRoot != null) { Destroy(_buttonRoot); _buttonRoot = null; }
            _buttonOutline = null;
            _buttonText = null;
        }

        // ---- the ink world map ----

        private void BuildMap()
        {
            var go = new GameObject("WorldMap");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(_mapAnchor.x, _mapAnchor.y, 0f);
            _mapRoot = go.transform;

            if (_mapFrame)
            {
                var frame = new List<Vector3>
                {
                    new Vector3(-_mapHalfWidth, -_mapHalfHeight, 0f),
                    new Vector3( _mapHalfWidth, -_mapHalfHeight, 0f),
                    new Vector3( _mapHalfWidth,  _mapHalfHeight, 0f),
                    new Vector3(-_mapHalfWidth,  _mapHalfHeight, 0f),
                    new Vector3(-_mapHalfWidth, -_mapHalfHeight, 0f),
                };
                AddMapStroke("Frame", frame, _mapLineWidth * 0.7f);
            }

            foreach (var kv in Continents())
                AddMapStroke(kv.Key, ProjectLoop(kv.Value), _mapLineWidth);

            foreach (var lr in _mapStrokes) InkLine.SetAlpha(lr, _mapInk, 0f);
        }

        private void AddMapStroke(string name, List<Vector3> pts, float width)
        {
            var lr = InkLine.Create(_mapRoot, name, _inkMaterial, width, _mapInk, _mapSorting);
            InkLine.SetPoints(lr, pts);
            lr.gameObject.AddComponent<LineBoil>().Capture();
            _mapStrokes.Add(lr);
        }

        // Project a loop of (longitude, latitude) points into local map space.
        private List<Vector3> ProjectLoop(Vector2[] lonLat)
        {
            var pts = new List<Vector3>(lonLat.Length);
            for (int i = 0; i < lonLat.Length; i++)
                pts.Add(new Vector3(lonLat[i].x / 180f * _mapHalfWidth, lonLat[i].y / 90f * _mapHalfHeight, 0f));
            return pts;
        }

        // A normalised pin (x,y each -1..1) to a world position on the map.
        private Vector3 MapToWorld(Vector2 pin)
        {
            Vector3 local = new Vector3(pin.x * _mapHalfWidth, pin.y * _mapHalfHeight, 0f);
            return _mapRoot != null ? _mapRoot.TransformPoint(local)
                                    : (Vector3)_mapAnchor + local;
        }

        private IEnumerator FadeMap(float from, float to, float dur)
        {
            float t = 0f, d = Mathf.Max(dur, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, to, t / d);
                for (int i = 0; i < _mapStrokes.Count; i++)
                    if (_mapStrokes[i] != null) InkLine.SetAlpha(_mapStrokes[i], _mapInk, a);
                yield return null;
            }
            for (int i = 0; i < _mapStrokes.Count; i++)
                if (_mapStrokes[i] != null) InkLine.SetAlpha(_mapStrokes[i], _mapInk, to);
        }

        // ---- the dropping pin ----

        private IEnumerator DropPin(Vector3 target)
        {
            BuildPin();
            float topY = _cam != null && _cam.orthographic
                ? _cam.transform.position.y + _cam.orthographicSize + 1.2f
                : target.y + 6f;
            _pin.position = new Vector3(target.x, topY, 0f);

            float t = 0f, d = Mathf.Max(_pinDropDuration, 0.05f);
            while (t < d)
            {
                t += Time.deltaTime;
                float k = EaseUtil.Clamp01(t / d);
                float e = k * k;   // accelerate as it falls
                _pin.position = new Vector3(target.x, Mathf.Lerp(topY, target.y, e), 0f);
                yield return null;
            }
            _pin.position = target;

            // A small settle bounce.
            if (_pinSettle > 0f)
            {
                float bt = 0f, bd = _pinSettle;
                while (bt < bd)
                {
                    bt += Time.deltaTime;
                    float k = bt / bd;
                    float lift = Mathf.Sin(k * Mathf.PI) * 0.12f;
                    _pin.position = new Vector3(target.x, target.y + lift, 0f);
                    yield return null;
                }
                _pin.position = target;
            }
        }

        private void BuildPin()
        {
            var go = new GameObject("Pin");
            go.transform.SetParent(transform, false);
            go.transform.localScale = new Vector3(_pinScale, _pinScale, 1f);
            _pin = go.transform;

            // A small classic map pin: a thin needle tapering to the point at the local origin (the exact
            // spot on the country), with a small round head above it. Plain red ink, nothing around it.
            var needle = new List<Vector3>
            {
                new Vector3(-0.035f, 0.17f, 0f), new Vector3(0f, 0f, 0f), new Vector3(0.035f, 0.17f, 0f),
            };
            var lrNeedle = InkLine.Create(_pin, "Needle", _inkMaterial, _pinLineWidth, _pinColor, _pinSorting);
            InkLine.SetPoints(lrNeedle, needle);
            _pinStrokes.Add(lrNeedle);

            var head = new List<Vector3>();
            InkLine.AddArc(head, new Vector2(0f, 0.235f), 0.075f, 0f, 360f, 18);
            var lrHead = InkLine.Create(_pin, "Head", _inkMaterial, _pinLineWidth, _pinColor, _pinSorting);
            InkLine.SetPoints(lrHead, head);
            _pinStrokes.Add(lrHead);
        }

        // ---- the country readout ----

        private void ShowReadout(NukeCountry c)
        {
            _nameLabel = InkText.Create(transform, "CountryName", _nameSize, _nameColor, TextAlignmentOptions.Center, _readoutSorting);
            _popLabel = InkText.Create(transform, "CountryPop", _popSize, _popColor, TextAlignmentOptions.Center, _readoutSorting);
            if (_font != null) { _nameLabel.font = _font; _popLabel.font = _font; }
            _nameLabel.rectTransform.sizeDelta = new Vector2(12f, 1.4f);
            _popLabel.rectTransform.sizeDelta = new Vector2(12f, 1.2f);
            _nameLabel.transform.localPosition = new Vector3(_readoutAnchor.x, _readoutAnchor.y + 0.55f, 0f);
            _popLabel.transform.localPosition = new Vector3(_readoutAnchor.x, _readoutAnchor.y - 0.2f, 0f);
            _nameLabel.text = c.Name;
            _popLabel.text = c.Population.ToString("#,0", CultureInfo.InvariantCulture) + _popSuffix;
            InkText.SetAlpha(_nameLabel, 0f);
            InkText.SetAlpha(_popLabel, 0f);
        }

        private IEnumerator FadeReadout(float target)
        {
            float t = 0f, d = Mathf.Max(_readoutFade, 0.01f);
            float from = _nameLabel != null ? _nameLabel.color.a : 0f;
            while (t < d)
            {
                t += Time.deltaTime;
                float a = Mathf.Lerp(from, target, t / d);
                if (_nameLabel != null) InkText.SetAlpha(_nameLabel, a);
                if (_popLabel != null) InkText.SetAlpha(_popLabel, a);
                yield return null;
            }
            if (_nameLabel != null) InkText.SetAlpha(_nameLabel, target);
            if (_popLabel != null) InkText.SetAlpha(_popLabel, target);
        }

        // ---- teardown ----

        private IEnumerator TeardownMap()
        {
            float t = 0f, d = Mathf.Max(_teardownFade, 0.01f);
            while (t < d)
            {
                t += Time.deltaTime;
                float a = 1f - t / d;
                for (int i = 0; i < _mapStrokes.Count; i++)
                    if (_mapStrokes[i] != null) InkLine.SetAlpha(_mapStrokes[i], _mapInk, a);
                for (int i = 0; i < _pinStrokes.Count; i++)
                    if (_pinStrokes[i] != null) InkLine.SetAlpha(_pinStrokes[i], _pinColor, a);
                if (_nameLabel != null) InkText.SetAlpha(_nameLabel, a);
                if (_popLabel != null) InkText.SetAlpha(_popLabel, a);
                yield return null;
            }
            if (_mapRoot != null) Destroy(_mapRoot.gameObject);
            if (_pin != null) Destroy(_pin.gameObject);
            if (_nameLabel != null) Destroy(_nameLabel.gameObject);
            if (_popLabel != null) Destroy(_popLabel.gameObject);
            _mapStrokes.Clear(); _pinStrokes.Clear();
            _mapRoot = null; _pin = null; _nameLabel = null; _popLabel = null;
        }

        // Simplified continent outlines as (longitude, latitude) loops. Rough but readable; a doodle
        // world map, not a survey. Correct these alongside the pins (see docs/open-questions.md).
        private static Dictionary<string, Vector2[]> Continents()
        {
            return new Dictionary<string, Vector2[]>
            {
                ["NorthAmerica"] = new[]
                {
                    new Vector2(-168,66), new Vector2(-140,70), new Vector2(-120,60), new Vector2(-124,48),
                    new Vector2(-117,33), new Vector2(-105,23), new Vector2(-90,18), new Vector2(-83,10),
                    new Vector2(-80,26), new Vector2(-76,36), new Vector2(-70,44), new Vector2(-60,47),
                    new Vector2(-56,52), new Vector2(-70,58), new Vector2(-85,62), new Vector2(-100,68),
                    new Vector2(-130,70), new Vector2(-160,71), new Vector2(-168,66),
                },
                ["SouthAmerica"] = new[]
                {
                    new Vector2(-80,8), new Vector2(-78,-5), new Vector2(-70,-18), new Vector2(-70,-38),
                    new Vector2(-73,-52), new Vector2(-66,-55), new Vector2(-58,-50), new Vector2(-48,-25),
                    new Vector2(-35,-8), new Vector2(-42,-2), new Vector2(-50,2), new Vector2(-60,8),
                    new Vector2(-77,11), new Vector2(-80,8),
                },
                ["Africa"] = new[]
                {
                    new Vector2(-16,15), new Vector2(-17,22), new Vector2(-10,32), new Vector2(10,37),
                    new Vector2(24,32), new Vector2(32,31), new Vector2(43,12), new Vector2(51,12),
                    new Vector2(42,-2), new Vector2(40,-15), new Vector2(35,-24), new Vector2(25,-34),
                    new Vector2(18,-35), new Vector2(12,-18), new Vector2(8,4), new Vector2(-7,4),
                    new Vector2(-16,15),
                },
                // Europe: a compact western blob whose east edge stops near longitude 29, so it reads
                // separate from Asia (the two used to overlap around longitude 28 to 40).
                ["Europe"] = new[]
                {
                    new Vector2(-9,43), new Vector2(-8,37), new Vector2(2,38), new Vector2(12,40),
                    new Vector2(20,41), new Vector2(27,46), new Vector2(29,53), new Vector2(26,59),
                    new Vector2(21,64), new Vector2(11,64), new Vector2(6,60), new Vector2(-4,58),
                    new Vector2(-10,51), new Vector2(-9,43),
                },
                // Asia: a large eastern mass whose west edge starts near longitude 35, leaving a clean
                // seam (the Urals) between it and Europe rather than crossing into it.
                ["Asia"] = new[]
                {
                    new Vector2(36,45), new Vector2(45,38), new Vector2(50,28), new Vector2(60,25),
                    new Vector2(78,8), new Vector2(88,20), new Vector2(97,5), new Vector2(108,10),
                    new Vector2(122,30), new Vector2(135,35), new Vector2(140,50), new Vector2(160,62),
                    new Vector2(180,66), new Vector2(168,71), new Vector2(120,75), new Vector2(80,74),
                    new Vector2(52,69), new Vector2(40,62), new Vector2(35,53), new Vector2(36,45),
                },
                ["Australia"] = new[]
                {
                    new Vector2(114,-22), new Vector2(122,-18), new Vector2(130,-12), new Vector2(137,-12),
                    new Vector2(142,-11), new Vector2(146,-18), new Vector2(150,-25), new Vector2(153,-28),
                    new Vector2(150,-38), new Vector2(140,-38), new Vector2(130,-32), new Vector2(122,-34),
                    new Vector2(115,-30), new Vector2(114,-22),
                },
                // Islands, so island nations land on real (if small) drawn land, and the map reads better.
                ["Iceland"] = new[]
                {
                    new Vector2(-24,64), new Vector2(-20,66), new Vector2(-13,65),
                    new Vector2(-13,63), new Vector2(-19,62), new Vector2(-24,63), new Vector2(-24,64),
                },
                ["BritishIsles"] = new[]
                {
                    new Vector2(-10,50), new Vector2(-5,51), new Vector2(-2,55), new Vector2(-4,59),
                    new Vector2(-9,58), new Vector2(-11,54), new Vector2(-10,50),
                },
                ["Japan"] = new[]
                {
                    new Vector2(142,44), new Vector2(140,39), new Vector2(137,35), new Vector2(133,33),
                    new Vector2(131,35), new Vector2(134,39), new Vector2(138,42), new Vector2(142,44),
                },
                ["Indonesia"] = new[]
                {
                    new Vector2(99,3), new Vector2(112,-1), new Vector2(124,-3), new Vector2(135,-2),
                    new Vector2(141,-4), new Vector2(133,-9), new Vector2(118,-9), new Vector2(105,-6), new Vector2(99,3),
                },
                ["NewZealand"] = new[]
                {
                    new Vector2(170,-38), new Vector2(174,-40), new Vector2(176,-44),
                    new Vector2(173,-47), new Vector2(169,-46), new Vector2(167,-42), new Vector2(170,-38),
                },
                ["PacificIslands"] = new[]
                {
                    new Vector2(167,-9), new Vector2(174,-9), new Vector2(178,-13),
                    new Vector2(176,-17), new Vector2(170,-17), new Vector2(166,-13), new Vector2(167,-9),
                },
            };
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
