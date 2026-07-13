namespace YourCall
{
    /// <summary>Chapter 7, case 5: THE SECRET. A woman found out her best friend's partner was cheating and
    /// said nothing, deciding it was not her business; the friend later found out she knew. Silence as betrayal,
    /// or minding your own business. [medium]</summary>
    public sealed class ConfessionSecretBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Five. A quieter one. No dramatics, no dinner table. Just a thing known, and not said.",
                "This one found out her best friend's partner was cheating. She sat on it. Decided it was not her place. The friend found out much later, and found out worse, that this one had known the whole time and said nothing. State it.",
            },
            Account = new[]
            {
                "If I said something and I was wrong, I lose her forever. If I said something and I was right, I am the one who detonated her whole life. There was no version of that where I walk away clean.",
                "It was not mine to tell. I kept hoping he would end it himself, or she would see it on her own. I was trying to protect her. She does not believe that now. But I was.",
            },
            Headline = "It was not mine to tell.",
            RulePrompt = "A secret kept out of love, or out of cowardice, and a friendship that did not survive the keeping. Rule.",
            VerdictGuilty = "Her silence was a betrayal",
            VerdictInnocent = "It was not hers to tell",
            VerdictBoth = "No clean way through it",
            ReactGuilty = "Guilty. You have decided that knowing and saying nothing is its own quiet lie, and that a friend is owed the truth even when it goes off like a bomb. Clean. Principled. I truly hope no one ever holds you to that standard, because every single person in this room is sitting on something.",
            ReactInnocent = "Cleared. Not her circus, not her monkeys, not her marriage. You have just ruled that the most loyal thing a friend can do is politely look the other way while the house burns. A great many people are going to want you at their dinner parties, and not one of them should get you.",
            ReactBoth = "Everyone sucks, which here means the cheat, obviously, but also both women. One for knowing, one for needing to have been told. There was no clean exit from that room, and you refused to pretend there was. Honest. Bleak. Correct in the only way nothing ever is.",
            SeedGuilty = 38,
            SeedInnocent = 34,
            SeedBoth = 28,
            Heading = "how the room ruled",
            HasProfile = true,
            Axis = MoralAxis.MercyVsJustice,
            NudgeGuilty = 0.5f,
            NudgeInnocent = -0.5f,
            NudgeBoth = 0f,
        };
    }
}
