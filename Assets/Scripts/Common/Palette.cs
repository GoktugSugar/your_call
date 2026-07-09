using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The single source of truth for the palette: black ink on a paper ground, with
    /// colour used deliberately as an accent for emphasis and meaning, never blanket
    /// decoration (see docs/art-and-ui.md). Amber is the attention/consequence accent;
    /// the rest carry a fixed colour-to-meaning mapping (red = death and the guilty,
    /// blue/red = the button dilemma, pink = love, brown = the bear, gold = the best life).
    /// Kept in one place so no colour drifts into decoration.
    /// </summary>
    public static class Palette
    {
        /// <summary>Warm near-black ink. #1B1A17</summary>
        public static readonly Color Ink = new Color(0.106f, 0.102f, 0.090f, 1f);

        /// <summary>Faint paper tint on the white ground, not blank white. #F5F2E9</summary>
        public static readonly Color Paper = new Color(0.961f, 0.949f, 0.914f, 1f);

        /// <summary>The one accent. Attention and consequence only. #E8951E</summary>
        public static readonly Color Amber = new Color(0.910f, 0.584f, 0.118f, 1f);

        /// <summary>Muted ink for receded / secondary marks on the aftermath tableau. #9A968C</summary>
        public static readonly Color Muted = new Color(0.604f, 0.588f, 0.549f, 1f);

        // Documented palette exception (see docs/art-and-ui.md and CLAUDE.md). Hand-drawn,
        // muted blue and red, used ONLY on the blue/red button dilemma: its two buttons and
        // its "how the room voted" stats bars. Nowhere else carries colour beyond the amber.

        /// <summary>Muted hand-drawn blue. Exception colour, blue/red button only. #3C6496</summary>
        public static readonly Color InkBlue = new Color(0.235f, 0.392f, 0.588f, 1f);

        /// <summary>Muted hand-drawn red. Exception colour, blue/red button only. #AA483A</summary>
        public static readonly Color InkRed = new Color(0.667f, 0.282f, 0.227f, 1f);

        /// <summary>Muted, slightly desaturated hand-drawn brown. Used only as the last bear's fill wash
        /// (a contained, currently experimental palette exception; see docs/art-and-ui.md). Nothing else
        /// uses it; exposed on BearFigure so it can be tuned or reverted.</summary>
        public static readonly Color InkBrown = new Color(0.5f, 0.36f, 0.24f, 1f);

        /// <summary>Muted hand-drawn pink. Marks the player's partner (the loved one) in the personal
        /// dilemma, and the little heart over them: deliberate colour for meaning (pink = love), on the
        /// ink base, the same crayon-line treatment as the red and blue figures. See docs/art-and-ui.md.</summary>
        public static readonly Color InkPink = new Color(0.851f, 0.451f, 0.573f, 1f);

        /// <summary>Warm hand-drawn gold. Marks "the best life any human has lived": the golden crowned
        /// figure in Chapter 2's better-offer button (gold = the best life / perfect happiness), on the
        /// ink base. Distinct from the amber accent (more yellow, luminous). Exposed on CrownedFigure so
        /// it can be tuned. See docs/art-and-ui.md. Also the gold money button's treatment.</summary>
        public static readonly Color InkGold = new Color(0.859f, 0.706f, 0.278f, 1f);

        // Muted hand-drawn colours for the would-you-rather doodle outlines: colour matched to the thing a
        // doodle depicts (a coloured ink line, not a fill; see docs/art-and-ui.md). Deliberate colour on
        // the ink base, kept muted so it reads as coloured ink, not flat digital colour.

        /// <summary>Muted hand-drawn green. A doodle outline colour (a duck, greenery). #4E8C55</summary>
        public static readonly Color InkGreen = new Color(0.306f, 0.549f, 0.333f, 1f);

        /// <summary>Muted warm hand-drawn orange. A doodle outline colour (the sun, heat). #CC7A33</summary>
        public static readonly Color InkOrange = new Color(0.800f, 0.478f, 0.200f, 1f);

        /// <summary>Muted icy hand-drawn blue. A doodle outline colour (a snowflake, cold). #5E9BC4</summary>
        public static readonly Color InkSky = new Color(0.369f, 0.608f, 0.769f, 1f);

        /// <summary>Muted hand-drawn purple. A doodle outline colour (the odd body doodles). #8A5FA6</summary>
        public static readonly Color InkPurple = new Color(0.541f, 0.373f, 0.651f, 1f);
    }
}
