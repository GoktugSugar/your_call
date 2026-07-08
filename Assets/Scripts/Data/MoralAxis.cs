namespace YourCall
{
    /// <summary>
    /// The axes the silent profile tracks: what KIND of person the player is, never how good.
    /// Neither pole is the good guy. See docs/narrative.md. The moral-only axes came first; the
    /// wider "who you are" portrait axes are appended at the end (new values only, so the existing
    /// serialized indices never shift). See docs/open-questions.md for the still-open final set.
    ///
    /// Sign convention (documented once, here, and never displayed): a negative tally
    /// leans toward the first-named pole, a positive tally toward the second-named pole.
    /// </summary>
    public enum MoralAxis
    {
        OneVsMany,      // -1 the one   | +1 the many
        MercyVsJustice, // -1 mercy     | +1 justice
        EndsVsRules,    // -1 ends      | +1 rules
        OrderVsFreedom, // -1 order     | +1 freedom
        SelfVsOthers,   // -1 self      | +1 others   (the buttons: taking for yourself at another's cost)
        RiskVsSafety    // -1 risk      | +1 safety   (the timer: sitting in the unknown vs acting to end it)
    }
}
