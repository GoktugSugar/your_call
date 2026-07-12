namespace YourCall
{
    /// <summary>
    /// The full data for one Who Would Win matchup (Chapter 5): the imp's setup and trash talk, the two
    /// fighters, the per-side reactions, the seeded how-others-chose split, and an optional light profile
    /// nudge. This is the reusable "matchup beat type" shape the task calls for: adding a matchup is a small
    /// beat that returns one of these (plus any new fighter doodles). See <see cref="MatchupBeat"/> and docs.
    ///
    /// The imp's register here is the guy egging on a stupid bar bet: he poses the fight, takes sides, trash
    /// talks whichever the player picks, and stacks absurd modifiers, all choice independent and never graded
    /// (who would win a fight says nothing about who you are, so it is the crowd split that is the payoff).
    /// </summary>
    public sealed class MatchupData
    {
        public string[] Setup;      // the imp poses the matchup and eggs the bet on (one or more lines)
        public MatchupSide A;       // the left fighter
        public MatchupSide B;       // the right fighter
        public string ReactA;       // the imp trash-talks if they backed A (mock, never grades)
        public string ReactB;       // the imp trash-talks if they backed B
        public int SeedA;           // how-others-chose: the crowd's votes for A
        public int SeedB;           // the crowd's votes for B
        public string Heading = "how the bar voted";

        // An optional light nudge to a gut-instinct / risk axis (at most a couple of matchups carry one; who
        // wins a fight is mostly pure taste, so most are stats-only). Silent, tunable, nothing consumes it yet.
        public bool HasProfile;
        public MoralAxis Axis = MoralAxis.RiskVsSafety;
        public float NudgeA;
        public float NudgeB;
    }
}
