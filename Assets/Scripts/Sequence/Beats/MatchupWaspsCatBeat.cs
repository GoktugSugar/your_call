namespace YourCall
{
    /// <summary>Chapter 5, matchup 9: a swarm of wasps vs a house cat. A genuine toss-up. A light risk nudge.</summary>
    public sealed class MatchupWaspsCatBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "A real toss up, this one. A [amber]swarm[/amber] of wasps versus [amber]one[/amber] house cat. The cat is fast, it swats, it has dealt with the odd fly and enjoyed it.",
                "But this is not one wasp. This is the entire furious cloud, and every one of them can sting more than once and holds a grudge. Genuinely could go either way. So call it.",
            },
            A = MatchupSide.Mob("a swarm of wasps", DoodleKind.Wasp, Palette.InkOrange, 16),
            B = MatchupSide.Solo("1 house cat", DoodleKind.HouseCat, Palette.InkSky, 1.26f),
            ReactA = "The [amber]swarm[/amber]. Death by a thousand tiny needles. The cat gets maybe ten of them, and then the eyes, the nose and the ears all file a formal complaint and it becomes a very fast retreat under the sofa.",
            ReactB = "The [amber]cat[/amber]. Reflexes, murder instinct, and a real enthusiasm for killing small flying things. Fair. Right up until the moment it inhales one of them.",
            SeedA = 49,
            SeedB = 51,
            Heading = "how the bar voted",
            HasProfile = true,
            Axis = MoralAxis.RiskVsSafety,
            NudgeA = -0.3f,
            NudgeB = 0.3f,
        };
    }
}
