namespace YourCall
{
    /// <summary>Chapter 5, matchup 2: 1 man vs 100 chickens. The numbers flipped, trivial-sounding until you picture it.</summary>
    public sealed class MatchupManChickensBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "New one, and I want you to actually think about it. [amber]One[/amber] grown man versus [amber]100[/amber] chickens. Sounds like nothing, does it. Then you picture a hundred chickens.",
                "That is a lot of beaks. They come in low. They have no plan, no leader, and no concept of mercy, and there are one hundred of them.",
            },
            A = MatchupSide.Solo("1 man", DoodleKind.Brawler, Palette.InkBlue),
            B = MatchupSide.Mob("100 chickens", DoodleKind.Chicken, Palette.InkOrange, 11),
            ReactA = "The [amber]man[/amber]. Big strong biped, opposable thumbs, the whole package. Absolutely. Right up until chicken number forty is inside his coat and he is making a noise no man should make.",
            ReactB = "The [amber]chickens[/amber]. A hundred tiny dinosaurs against one soft, panicking man. You have clearly met a chicken up close. Genuinely deranged little animals.",
            SeedA = 57,
            SeedB = 43,
            Heading = "how the bar voted",
        };
    }
}
