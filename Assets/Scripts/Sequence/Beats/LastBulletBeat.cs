using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The Last Bullet and the Crowd (Chapter 4, beat 5). Several people stand together, each drawn a
    /// different colour; the imp says one of them is about to do something that gets them all killed, and
    /// will not say which colour. One bullet. Fire blind (maybe stop it by killing the wrong person) or hold
    /// and hope. A guess with a gun.
    ///
    /// A multi-target aim over the reused crosshair: the player aims at one of the coloured crowd and fires
    /// (a blind guess), or holds. If they fire, that one folds and the imp savours that they will never know
    /// if it was the one. If they hold, no one folds and the imp savours that either nothing happened or
    /// everything did, and they will never know that either. Choice independent, never grading. Silent nudge
    /// on risk vs safety. The how-others-chose reveal is a per-colour breakdown (how the crowd's blind shots
    /// spread across the coloured figures, plus who held), each bar in its figure's own colour, so the blind
    /// guess reads as a colourful, readable stat.
    /// </summary>
    public sealed class LastBulletBeat : GunBeat
    {
        /// <summary>One coloured member of the crowd: how the imp / stat names it, its ink outline colour
        /// (also its stat bar colour), and the seeded share of the crowd who blind-shot this colour.</summary>
        [System.Serializable]
        private struct CrowdColour
        {
            public string name;
            public Color colour;
            public int seed;
            public CrowdColour(string n, Color c, int s) { name = n; colour = c; seed = s; }
        }

        [Header("The crowd (each a distinct colour, left to right)")]
        [Tooltip("One entry per figure: its name (the imp / stat), its ink outline colour, and the seeded share who shot it. The count of the crowd is the number of entries.")]
        [SerializeField] private CrowdColour[] _members = new[]
        {
            new CrowdColour("red", Palette.InkRed, 15),
            new CrowdColour("blue", Palette.InkBlue, 12),
            new CrowdColour("green", Palette.InkGreen, 10),
            new CrowdColour("orange", Palette.InkOrange, 11),
            new CrowdColour("purple", Palette.InkPurple, 12),
        };
        [SerializeField] private float _spanX = 7.2f;
        [SerializeField] private float _feetY = -0.5f;
        [SerializeField] private float _scale = 1.1f;
        [SerializeField] private Vector2 _boxSize = new Vector2(1.3f, 1.9f);
        [SerializeField] private float _boxCenterYOffset = 0.85f;

        [Header("Copy (the imp; no dashes)")]
        [SerializeField, TextArea(2, 5)] private string[] _promptLines = new[]
        {
            "See this lot. Red, blue, green, orange and purple, five of them, lined up like a packet of sweets. In a moment, one of them is going to do something extremely stupid that gets [red]all of them killed[/red]. Every one. I know the colour. I am not going to tell you.",
            "You have [amber]one[/amber] bullet. You could fire into the crowd right now, pick a colour, and maybe, maybe, take the one out before they do it. Or you could hold, and hope I am lying, or wrong, or bored. Choose a colour, or do not.",
        };
        [Tooltip("If they fire on someone. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _fireReact =
            "Bang. You picked a colour and put a stranger down on my word alone, on a guess, hoping it was the right one. Maybe it was. Maybe that was the one, and you are a hero nobody will ever thank. Maybe it was just some poor soul who happened to be that colour, and the real one is still standing there, grinning. You will never know which. I will. I am not telling.";
        [Tooltip("If they hold. Choice independent, never graded.")]
        [SerializeField, TextArea(2, 6)] private string _holdReact =
            "You held. And they all walked away, or they all died screaming the second you turned your back, and here is the beautiful part, you will never know which, because you did not look, because you could not bring yourself to pick a colour. I know. I always know. That is the job.";

        [Header("Choice labels (no dashes)")]
        [SerializeField] private string _fireLabel = "Fire blind";
        [SerializeField] private string _holdLabel = "Hold";

        [Header("Crowd split (seeded; per-colour seeds live on the members above)")]
        [SerializeField] private int _holdSeed = 40;
        [SerializeField] private string _statsHeading = "how others chose";
        [SerializeField] private string _holdStatLabel = "held the shot";

        [Header("Profile (silent; risk vs safety, light)")]
        [Tooltip("Firing blind on a guess leans risk (negative); holding the shot leans safety (positive).")]
        [SerializeField] private float _riskNudge = 0.25f;

        public override IEnumerator Play(SequenceContext ctx)
        {
            if (!ApparatusReady()) yield break;

            int n = Mathf.Max(1, _members != null ? _members.Length : 0);
            var crowd = new List<Figure>(n);
            var boxes = new List<AimField.Box>(n);
            for (int i = 0; i < n; i++)
            {
                float x = n > 1 ? Mathf.Lerp(-_spanX * 0.5f, _spanX * 0.5f, i / (float)(n - 1)) : 0f;
                var fig = SpawnFigure(new Vector2(x, _feetY), _scale, "Crowd" + i);
                fig.Brand(_members[i].colour);   // each figure a distinct colour (an ink outline, not a fill)
                crowd.Add(fig);
                boxes.Add(new AimField.Box(new Vector2(x, _feetY + _boxCenterYOffset), _boxSize));
            }

            yield return Lines(ctx, _promptLines);

            var aim = NewAimField();
            aim.SetTargets(boxes);
            aim.Arm(true);
            ArmChoices(ctx, _fireLabel, _holdLabel);

            int shotTarget = -2;   // -2 pending, -1 hold, >=0 fired on that index
            while (shotTarget == -2)
            {
                aim.Tick();
                if (aim.TryTakeFire(out int t) && t >= 0) shotTarget = t;
                else if (PickedChoice == 0) shotTarget = Random.Range(0, n);   // "fire blind" text: a random colour
                else if (PickedChoice == 1) shotTarget = -1;                   // hold
                if (shotTarget == -2) yield return null;
            }
            aim.Arm(false);
            DisarmChoices(ctx);
            bool fired = shotTarget >= 0;

            if (fired)
            {
                Fire();
                yield return new WaitForSeconds(_resolveBeat);
                crowd[shotTarget].Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
            }

            Nudge(ctx, MoralAxis.RiskVsSafety, fired ? -_riskNudge : _riskNudge);
            yield return React(ctx, fired ? _fireReact : _holdReact);

            // The colour breakdown: one bar per colour (in the figure's own colour, the player's shot the
            // pick), then a plain held bar. So the reveal reads as which colour the crowd's blind shots hit.
            var bars = new StatBar[n + 1];
            for (int i = 0; i < n; i++)
            {
                var b = new StatBar(_members[i].name, _members[i].seed, fired && shotTarget == i);
                b.Tint = _members[i].colour;
                bars[i] = b;
            }
            bars[n] = new StatBar(_holdStatLabel, _holdSeed, !fired);
            yield return Split(ctx, _statsHeading, bars);

            for (int i = 0; i < crowd.Count; i++)
                if (crowd[i] != null) Destroy(crowd[i].gameObject);
        }
    }
}
