namespace YourCall
{
    /// <summary>Chapter 5, matchup 4: a grizzly bear vs a silverback gorilla. Two heavyweights, no numbers, confident opinions.</summary>
    public sealed class MatchupBearGorillaBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Two heavyweights now. No numbers, no tricks, no field advantage. A [amber]grizzly bear[/amber] versus a [amber]silverback gorilla[/amber].",
                "Pound for pound the gorilla is stronger. But the bear is bigger, meaner, twice the weight, and comes with knives on every foot. This is the one that ends friendships. Pick.",
            },
            A = MatchupSide.Solo("grizzly bear", DoodleKind.Grizzly, Palette.InkBrown, 1.28f),
            B = MatchupSide.Solo("silverback gorilla", DoodleKind.Gorilla, Palette.Muted, 1.22f),
            ReactA = "The [amber]bear[/amber]. Half a ton of muscle and claw that treats a wolf pack as a light snack. Hard to argue with. The gorilla has, to be fair, never once fought something with actual blades on its hands.",
            ReactB = "The [amber]gorilla[/amber]. Speed, grip, and the raw power to end it before the bear even gets going. Bold. You are staking agility against an animal that shrugs off a charging moose.",
            SeedA = 63,
            SeedB = 37,
            Heading = "how the bar voted",
        };
    }
}
