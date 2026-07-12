namespace YourCall
{
    /// <summary>Chapter 5, matchup 3: 1000 house cats vs 1 lion. Overwhelming small numbers vs one apex. A light risk nudge.</summary>
    public sealed class MatchupCatsLionBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Escalation. [amber]1000[/amber] house cats versus [amber]one[/amber] lion. A thousand furious little Mr Whiskers against the actual king of the beasts.",
                "Somewhere between one cat and a thousand there is a tipping point where cute becomes a tide. The whole question is whether a thousand is past that line. Your gut. Go.",
            },
            A = MatchupSide.Mob("1000 house cats", DoodleKind.HouseCat, Palette.InkSky, 14),
            B = MatchupSide.Solo("1 lion", DoodleKind.Lion, Palette.InkOrange, 1.32f),
            ReactA = "The [amber]thousand[/amber] cats. A living carpet of teeth and spite. The lion kills, what, forty of them, and then it is just tired and bleeding and outnumbered [amber]twenty[/amber] to one. I could genuinely be talked into this.",
            ReactB = "The [amber]lion[/amber]. One apex predator versus a thousand things that abandon a fight halfway through to stare at a moth. Fair. Cats are not exactly a disciplined army.",
            SeedA = 51,
            SeedB = 49,
            Heading = "how the bar voted",
            // A light nudge: backing the chaotic swarm reads as a gut / long-shot call, the safe apex favourite as safety.
            HasProfile = true,
            Axis = MoralAxis.RiskVsSafety,
            NudgeA = -0.3f,
            NudgeB = 0.3f,
        };
    }
}
