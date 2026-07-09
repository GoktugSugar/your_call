using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One country in the bundled roulette list for <see cref="CancerNukeButtonBeat"/> (Chapter 2's
    /// cure-cancer-but-nuke-a-country button). Authored as a serialized list so the roster, the
    /// populations, and the pin placements can be corrected and expanded without touching code
    /// (see docs/tech.md). The populations are APPROXIMATE bundled placeholders, not live data.
    ///
    /// <see cref="Pin"/> is normalised map space: x and y each run -1..1 across the ink map's half
    /// extents (x = longitude -180..180, y = latitude -90..90 on the equirectangular doodle), so a
    /// designer can nudge a pin against the drawn continents and the beat scales it to the real map.
    /// No dashes in player-facing text.
    /// </summary>
    [Serializable]
    public sealed class NukeCountry
    {
        [Tooltip("The country's name, shown under the pin. Accurate.")]
        public string Name;

        [Tooltip("ISO two letter code (e.g. US, JP), used only to spot the player's own country for the special jab. Optional.")]
        public string Iso;

        [Tooltip("Approximate population (a bundled placeholder to refine; not live data).")]
        public long Population;

        [Tooltip("Pin position in normalised map space: x,y each -1..1 (x = longitude, y = latitude). The beat scales it to the ink map.")]
        public Vector2 Pin;

        [TextArea(1, 3)]
        [Tooltip("Optional imp line for landing here. Choice independent, never graded. Empty falls back to a size based jab. May carry [amber]/[red] tags.")]
        public string Quip;

        public NukeCountry() { }
        public NukeCountry(string name, string iso, long population, Vector2 pin, string quip = "")
        {
            Name = name; Iso = iso; Population = population; Pin = pin; Quip = quip;
        }
    }
}
