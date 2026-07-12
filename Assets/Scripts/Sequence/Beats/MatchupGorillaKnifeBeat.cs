namespace YourCall
{
    /// <summary>Chapter 5, matchup 8 (the modifier gag): 1 gorilla vs 1 gorilla, but one has a knife. How much does the knife matter.</summary>
    public sealed class MatchupGorillaKnifeBeat : MatchupBeat
    {
        protected override MatchupData BuildData()
        {
            var b = MatchupSide.Solo("1 gorilla, with a knife", DoodleKind.GorillaKnife, Palette.Muted, 1.22f);
            b.BarColor = Palette.InkRed;   // the knife side reads red on the stat, so the two grey apes split apart
            return new MatchupData
            {
                Setup = new[]
                {
                    "A control experiment, this. [amber]One[/amber] gorilla versus [amber]one[/amber] gorilla. Identical. Same weight, same reach, same profoundly bad mood.",
                    "Except this one has a [red]knife[/red]. Small knife. Little guy. Now tell me, honestly, how much does a knife actually matter when both parties can already pull a door off a car.",
                },
                A = MatchupSide.Solo("1 gorilla", DoodleKind.Gorilla, Palette.Muted, 1.22f),
                B = b,
                ReactA = "The [amber]unarmed[/amber] one. You reckon a blade is a rounding error to something that strong, all raw power and no need for tools. Brave. Say that to the one holding the knife.",
                ReactB = "The one with the [red]knife[/red]. Obviously, you say. A knife is a knife. Although do picture the precise moment the first gorilla realises it has been stabbed by the second gorilla. That is no longer a calm animal.",
                SeedA = 39,
                SeedB = 61,
                Heading = "how the bar voted",
            };
        }
    }
}
