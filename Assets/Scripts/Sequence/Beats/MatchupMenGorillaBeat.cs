namespace YourCall
{
    /// <summary>Chapter 5, matchup 1 (the flagship): 100 men vs 1 gorilla. The argument everyone has already had.</summary>
    public sealed class MatchupMenGorillaBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Right. THE argument. The one every group of idiots has had at least once, usually at [amber]2[/amber] in the morning. [amber]100[/amber] men, unarmed, versus [amber]one[/amber] silverback gorilla. Open field, no weapons, no cages, everyone starts in the middle.",
                "The men can talk to each other and make a plan. The gorilla can bench a small car and has genuinely never once felt fear. So. Where is your money.",
            },
            A = MatchupSide.Mob("100 men", DoodleKind.Brawler, Palette.InkBlue, 11),
            B = MatchupSide.Solo("1 gorilla", DoodleKind.Gorilla, Palette.Muted, 1.28f),
            ReactA = "The [amber]hundred[/amber]. Strength in numbers, is it. You are picturing a clean coordinated swarm. I am picturing the first twenty men learning exactly what a gorilla does to a person, and the other eighty suddenly remembering they left the oven on.",
            ReactB = "The [amber]gorilla[/amber]. One furious ape against a small army, and you like the ape. I respect the sheer contempt you have just shown for your own species.",
            SeedA = 46,
            SeedB = 54,
            Heading = "how the bar voted",
        };
    }
}
