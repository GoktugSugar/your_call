namespace YourCall
{
    /// <summary>
    /// The axes the silent moral profile tracks: what KIND of reasoner the player is,
    /// never how good. Neither pole is the good guy. See docs/narrative.md.
    ///
    /// Sign convention (documented once, here, and never displayed): a negative tally
    /// leans toward the first-named pole, a positive tally toward the second-named pole.
    /// </summary>
    public enum MoralAxis
    {
        OneVsMany,      // -1 the one   | +1 the many
        MercyVsJustice, // -1 mercy     | +1 justice
        EndsVsRules,    // -1 ends      | +1 rules
        OrderVsFreedom  // -1 order     | +1 freedom
    }
}
