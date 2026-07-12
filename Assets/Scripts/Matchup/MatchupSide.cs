using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One fighter in a Who Would Win matchup (Chapter 5): its label (the name and count, e.g. "100 men",
    /// "1 gorilla", "You"), the coloured ink doodle it is drawn with, and its side colour (each matchup gives
    /// its two sides distinct colours so they read apart). A side is either a single fighter or a stylised
    /// crowd (a cluster of small copies of the unit doodle with the count carried by the label, never the
    /// literal count drawn). Plain data, authored in the beat; see <see cref="MatchupBeat"/> and docs.
    /// </summary>
    public sealed class MatchupSide
    {
        public string Label;        // the fighter name and count, localized at display ("100 men", "1 gorilla")
        public DoodleKind Doodle;   // the single doodle, or the crowd's unit doodle
        public Color Outline;       // the side's ink colour (distinct from the other side)
        public bool Crowd;          // true = draw a cluster of small units (a stylised "a lot")
        public int CrowdDraw;       // how many units to actually draw (representative, capped, not the count)
        public float Scale;         // per-side scale override for a solo fighter (0 = the beat's default)
        public Color BarColor;      // optional how-others-chose bar colour (0 alpha = use Outline). Lets the two
                                    // identical grey knife-gorillas still read apart on the reveal.

        /// <summary>The colour for this side's how-others-chose bar: an explicit BarColor if set, else the outline.</summary>
        public Color ResolveBarColor() => BarColor.a > 0f ? BarColor : Outline;

        /// <summary>A single fighter.</summary>
        public static MatchupSide Solo(string label, DoodleKind doodle, Color outline, float scale = 0f)
            => new MatchupSide { Label = label, Doodle = doodle, Outline = outline, Crowd = false, Scale = scale };

        /// <summary>A crowd of one kind: a cluster of <paramref name="draw"/> small units, the real count in the label.</summary>
        public static MatchupSide Mob(string label, DoodleKind unit, Color outline, int draw, float scale = 0f)
            => new MatchupSide { Label = label, Doodle = unit, Outline = outline, Crowd = true, CrowdDraw = draw, Scale = scale };
    }
}
