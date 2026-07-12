namespace YourCall
{
    /// <summary>Chapter 5, matchup 7: 100 toddlers vs 1 adult man. Absurd and genuinely dividing, dark-comic.</summary>
    public sealed class MatchupToddlersManBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Absurd, and yet here we are. [amber]100[/amber] toddlers versus [amber]one[/amber] grown man. A hundred tiny, furious, wildly uncoordinated attackers, none of them taller than his knee, all of them biting.",
                "He is strong. He is also deeply unwilling to punt a toddler across a field, and there are, again, [amber]one hundred[/amber] of them. Choose.",
            },
            A = MatchupSide.Mob("100 toddlers", DoodleKind.Toddler, Palette.InkOrange, 12),
            B = MatchupSide.Solo("1 adult man", DoodleKind.Brawler, Palette.InkBlue),
            ReactA = "The [amber]hundred[/amber] toddlers. A gurgling tide that feels no fear and respects no man. He can throw a few. He cannot throw a hundred, and they simply keep toddling back for more.",
            ReactB = "The [amber]man[/amber]. One adult versus a hundred tiny menaces. Sensible, if he is prepared to be an absolute monster about it. The instant he hesitates, and he will hesitate, they are all over him.",
            SeedA = 40,
            SeedB = 60,
            Heading = "how the bar voted",
        };
    }
}
