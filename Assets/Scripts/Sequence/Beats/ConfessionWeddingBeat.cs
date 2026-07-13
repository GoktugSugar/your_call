namespace YourCall
{
    /// <summary>Chapter 7, case 2: THE WEDDING. A woman wore white to someone else's wedding, on purpose, to
    /// spite a bride she has history with. A crime, or was the bride asking for it. [light]</summary>
    public sealed class ConfessionWeddingBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Next. A wedding. And a woman who wore [amber]white[/amber] to one that was not hers. On purpose. Which is, I am reliably informed, a declaration of open war among your people.",
                "She and the bride have, and I am quoting the file here, history. State it.",
            },
            Account = new[]
            {
                "It was cream. And she knew exactly what she was doing when she sat me at the very back table, next to her ghastly uncle. This was years in the making. She started it.",
                "If she did not want anyone outshining her, she should not have married a man who used to be mine. I looked incredible, for the record. That is not a crime in any court worth the name.",
            },
            Headline = "It was cream, actually.",
            RulePrompt = "A dress, a decade of grudge, and a bride who may or may not have had it coming. Rule.",
            VerdictGuilty = "She did it to wound",
            VerdictInnocent = "The bride had it coming",
            VerdictBoth = "Two feuds, no innocents",
            ReactGuilty = "Guilty. She weaponised an outfit at a stranger's altar, and you called it exactly that. Fair. Petty crimes still leave a mark, and that dress is going to hang in a closet somewhere, radiating pure spite, for the next ten years.",
            ReactInnocent = "Not guilty, on the grounds that the bride married the ex, seated her by the ghastly uncle, and thereby ordered up a dress like that herself. You are doing tit for tat accounting at a wedding reception. It is certainly a look.",
            ReactBoth = "Everyone sucks, the whole reception hall. Two women quietly at war for years, using a wedding as the battlefield. No clean party, no clean dress, no table still speaking to any other table. Refreshingly bleak. You did not even try to find a hero. Wise.",
            SeedGuilty = 49,
            SeedInnocent = 18,
            SeedBoth = 33,
            Heading = "how the room ruled",
        };
    }
}
