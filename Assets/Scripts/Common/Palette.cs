using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The single source of truth for the palette: black ink, one paper ground, and
    /// exactly one amber accent used only for attention and consequence. Kept in one
    /// place so the accent never drifts into decoration (see docs/art-and-ui.md).
    /// The only exception is InkBlue and InkRed, used solely on the blue/red button
    /// dilemma (its two buttons and its stats bars); see the note by those fields.
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
    }
}
