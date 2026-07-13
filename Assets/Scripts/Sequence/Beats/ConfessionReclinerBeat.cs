namespace YourCall
{
    /// <summary>Chapter 7, case 1 (the opener that teaches the verdict loop): THE RECLINER. A man reclined his
    /// seat on a long flight into the knees of the person behind him and will not apologise, he paid for the
    /// seat. Petty, universal, and it violently splits a room. [light]</summary>
    public sealed class ConfessionReclinerBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Court is in session, such as it is. First on the docket. Approach, and do try not to bleed on my floor, most of you are only metaphorical anyway.",
                "The charge, if we are calling it that. This one reclined his seat on a [amber]nine hour[/amber] flight, all the way back, into the knees of the soul behind him. And then, asked politely to ease it up, declined. State your case.",
            },
            Account = new[]
            {
                "I paid for that seat. The whole seat. The recline is part of the seat. It is a button, it is right there, the airline put it there for me to press.",
                "If the person behind me wanted knee room, they could have paid for it, or asked nicely, instead of kicking the back of my chair for six hours like a furious toddler.",
            },
            Headline = "I paid for the whole seat.",
            RulePrompt = "So. A man, a button, and the eternal war over four inches of stale air. You spent a whole career on smaller things than this. Your verdict.",
            VerdictGuilty = "He was out of line",
            VerdictInnocent = "He paid, it is his seat",
            VerdictBoth = "Everyone on that flight sucks",
            ReactGuilty = "Guilty. For the crime of pressing a button the airline installed and begged him to press. Bold. Somewhere a man is condemned across all eternity for reclining, and he is going to feel that was slightly out of proportion.",
            ReactInnocent = "Cleared. He paid, so he owns the airspace over a stranger's kneecaps outright. A property lawyer's verdict. Cold, defensible, and it is going to make you deeply unpopular on every flight you never take again.",
            ReactBoth = "Everyone sucks. The reclined, the kneed, the airline, the sky itself. A refusal to pick a side, dressed up as wisdom. I adore it. It tells me almost nothing, which is, funnily enough, its own kind of answer.",
            OddRulingAside = "Hm. Hold that thought. When I polled the room, it did not land anywhere near where you just did. Not the popular call, that one. Watch.",
            SeedGuilty = 44,
            SeedInnocent = 25,
            SeedBoth = 31,
            Heading = "how the room ruled",
        };
    }
}
