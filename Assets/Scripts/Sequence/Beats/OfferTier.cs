using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One authored, per-tier imp line for <see cref="EscalatingOfferBeat"/>, keyed to the dollar amount
    /// of that tier. Stored as a serialized list so a writer can tune each tier's line without touching
    /// code (see docs/tech.md): the money button's line as the price halves, or the everyone-but-you
    /// button's line as the amount climbs. Matched by amount, with a graceful fallback if the amounts are
    /// retuned. No dashes in player-facing text.
    /// </summary>
    [Serializable]
    public sealed class OfferTier
    {
        [Tooltip("The dollar amount of this tier (the offer the line comments on).")]
        public int Amount;

        [TextArea(2, 4)]
        [Tooltip("The imp's line for this tier. Choice independent, never graded. May carry [amber]/[red] tags.")]
        public string Line;

        public OfferTier() { }
        public OfferTier(int amount, string line) { Amount = amount; Line = line; }
    }
}
