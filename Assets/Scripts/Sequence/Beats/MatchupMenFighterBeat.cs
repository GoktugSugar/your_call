namespace YourCall
{
    /// <summary>Chapter 5, matchup 5: 5 men vs 1 professional fighter. Skill against numbers.</summary>
    public sealed class MatchupMenFighterBeat : MatchupBeat
    {
        protected override MatchupData BuildData() => new MatchupData
        {
            Setup = new[]
            {
                "Skill against numbers. [amber]Five[/amber] ordinary blokes off the street versus [amber]one[/amber] professional fighter. He does this for a living. They have never thrown a real punch in anger.",
                "But it is five on one, and even a pro can only hit one man at a time. Do the numbers beat the technique. This is a genuine pub argument, so argue.",
            },
            A = MatchupSide.Mob("5 men", DoodleKind.Brawler, Palette.InkBlue, 5),
            B = MatchupSide.Solo("1 pro fighter", DoodleKind.Boxer, Palette.InkRed, 1.2f),
            ReactA = "The [amber]five[/amber]. You reckon they pile on before he can thin them out. Maybe. Or he drops the first two inside four seconds and the other three abruptly remember a prior engagement.",
            ReactB = "The [amber]pro[/amber]. One trained fighter against five flailing amateurs. Reasonable. He also gets tired, and there is always exactly one lunatic in a group of five who does not feel pain and will not go down.",
            SeedA = 55,
            SeedB = 45,
            Heading = "how the bar voted",
        };
    }
}
