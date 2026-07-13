namespace YourCall
{
    /// <summary>
    /// The full data for one confession case (Chapter 7, The Confession Booth): the imp's bored clerk
    /// announcement, the confessor's account of an "am I the asshole" dispute with no clean answer, the three
    /// verdict labels, the per verdict imp reactions, the seeded three way crowd split, and an optional silent
    /// profile nudge. This is the reusable "confession case beat type" shape the task calls for: adding a case
    /// is a small beat that returns one of these (plus any per case wiring). See <see cref="ConfessionCaseBeat"/>
    /// and docs.
    ///
    /// The verdict is three way, not binary, because these disputes have an "everyone sucks here" middle: the
    /// confessor is in the wrong (index 0), the confessor is NOT in the wrong and the other party is (index 1),
    /// or both are in the wrong / no one is clean (index 2). The exact wording varies per case. Whatever the
    /// player rules the imp reacts choice independent (mocking the ruling, never declaring a correct verdict),
    /// and the seeded split shows whether the room agreed. The imp here is the court CLERK running the docket,
    /// not posing a dilemma.
    /// </summary>
    public sealed class ConfessionData
    {
        // The imp, as bored court clerk, announces the case and moves the docket along.
        public string[] Announce;

        // The confessor states their side (their account of the dispute). Delivered in the dialogue box.
        public string[] Account;

        // A short line floated over the confessor's head (their core position), no bubble. Optional (null = none).
        public string Headline;

        // The imp calls for the ruling right before the verdict affordances appear. Optional (a default is used).
        public string RulePrompt;

        // The three verdicts, in order. Wording varies per case; localized at display.
        public string VerdictGuilty;    // 0: the confessor is in the wrong (the asshole)
        public string VerdictInnocent;  // 1: the confessor is NOT in the wrong (the other party is)
        public string VerdictBoth;      // 2: both are in the wrong / no one is clean (the everyone sucks middle)

        // The imp's reaction to each verdict (choice independent, mocking, never grades a verdict right or wrong).
        public string ReactGuilty;
        public string ReactInnocent;
        public string ReactBoth;

        // Optional: the clerk noting the room does not see it the player's way, fired only when the player's
        // verdict is the LEAST popular of the three (a genuine "you ruled strangely" moment, crowd relative,
        // never a claim the ruling was morally wrong). Null = never noted for this case.
        public string OddRulingAside;

        // The seeded three way crowd split (display only, the central hook). Made to feel like a real comment
        // section split; often the middle or the "not the asshole" verdict runs large.
        public int SeedGuilty, SeedInnocent, SeedBoth;

        public string Heading = "how the room ruled";

        // An optional light, silent nudge on one axis by verdict pattern (e.g. how decisively vs. how leniently
        // the player judges). Most cases carry one; the petty and gag cases are stats only. Nothing consumes it
        // yet (no ending reads it); tunable, never shown.
        public bool HasProfile;
        public MoralAxis Axis = MoralAxis.MercyVsJustice;
        public float NudgeGuilty, NudgeInnocent, NudgeBoth;

        // The two stories closer only: the second confessor's account and headline (index 1 side). The two
        // stories beat presents A and B side by side; every other case leaves these null and uses one confessor.
        public string[] AccountB;
        public string HeadlineB;
    }
}
