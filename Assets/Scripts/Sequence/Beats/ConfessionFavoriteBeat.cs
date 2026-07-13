namespace YourCall
{
    /// <summary>Chapter 7, case 7: THE FAVORITE. A parent openly favored one child their whole life; the
    /// neglected one cut them off and refused to visit as they died. Does a lifetime of favoritism justify
    /// abandonment at the end. The neglected child is the one confessing. [heavy]</summary>
    public sealed class ConfessionFavoriteBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Seven. A parent, a deathbed, and a child who did not come.",
                "This one grew up second. Always second. A brother who could do no wrong, and this one who could do no right, for a whole childhood and every year after it. When the parent was dying, and asking for them by name, this one did not go. Did not call. Let them go without a goodbye. State it.",
            },
            Account = new[]
            {
                "You want to know the last honest thing they ever said to me. They told me they wished I had more of my brother in me. I was twelve years old. I have carried that sentence around for thirty years.",
                "So no. I did not rush to the bedside to hold the hand of the person who spent my entire life making me feel like a mistake they were stuck with. They wanted their favourite at the end. They could have died looking at him.",
            },
            Headline = "They never chose me. Not once.",
            RulePrompt = "A lifetime of coming second, against a parent dying alone and asking. Rule.",
            VerdictGuilty = "Leaving the dying is too far",
            VerdictInnocent = "They earned that empty room",
            VerdictBoth = "A family that failed each other",
            ReactGuilty = "Guilty. Whatever was done to the child, you are saying, a dying parent asking for you is a line, and this one stepped clean over it. Firm. There are people who will call that cruel and people who will call it right, and you have just quietly found out which one you are, without anyone asking you to.",
            ReactInnocent = "Cleared. Thirty years of being the runner up bought this one the right to skip the finale, and you have signed off on the bill. Consequences arriving late, but arriving. The parent wanted their favourite at the very end. You have ruled that they really should have thought of that a lot earlier. Cold. Possibly correct. Definitely cold.",
            ReactBoth = "Everyone sucks, across two generations and one very quiet funeral. A parent who broke a child, and a child who let them, then broke them right back at the worst possible moment. No villain, no hero, just a family handing the same wound down the line like an heirloom. You did not flinch from that. Noted.",
            SeedGuilty = 35,
            SeedInnocent = 32,
            SeedBoth = 33,
            Heading = "how the room ruled",
            HasProfile = true,
            Axis = MoralAxis.MercyVsJustice,
            NudgeGuilty = 0.5f,
            NudgeInnocent = -0.5f,
            NudgeBoth = 0f,
        };
    }
}
