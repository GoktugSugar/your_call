using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The single source of truth for the palette: black ink, one paper ground, and
    /// exactly one amber accent used only for attention and consequence. Kept in one
    /// place so the accent never drifts into decoration (see docs/art-and-ui.md).
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
    }
}
