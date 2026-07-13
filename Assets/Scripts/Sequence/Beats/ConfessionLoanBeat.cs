namespace YourCall
{
    /// <summary>Chapter 7, case 3: THE LOAN. A man lent his struggling brother money, then shamed him publicly
    /// when he could not repay on time. The one who did not repay, or the one who humiliated him. [medium]</summary>
    public sealed class ConfessionLoanBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Number three. A family matter, which are always my favourite, because no one involved is ever fully sane and they all remember it differently.",
                "This one lent his younger brother money when the brother was drowning. The brother could not pay it back in time. So this one stood up at a family dinner, in front of everyone, and laid it all out. The debt, the missed date, the excuses. State your case.",
            },
            Account = new[]
            {
                "I carried him for a year. A whole year. And not one thank you, not one honest word about it, just excuses and, I noticed, a brand new phone. People deserve to know who they are handing their goodwill to.",
                "I did not lie. Every single thing I said at that table was true. If the truth humiliated him, that is on the choices he made, not on me for finally saying them out loud.",
            },
            Headline = "I only told the truth about him.",
            RulePrompt = "A debt paid back in humiliation, at a dinner table, in front of the whole bloodline. Rule.",
            VerdictGuilty = "He shamed his own brother",
            VerdictInnocent = "The brother earned it",
            VerdictBoth = "A whole family of debts",
            ReactGuilty = "Guilty. The money was real, the debt was real, but he chose an audience, and you saw the choice for what it was. He did not want it back. He wanted the room to watch him not get it back. Noted, and filed.",
            ReactInnocent = "Cleared. A year of silence and a shiny new phone, and you have ruled that the public shaming was simply an invoice with feelings attached. Truth is a defence, is it. You would have made a very efficient judge. A lonely one, but efficient.",
            ReactBoth = "Everyone sucks. The deadbeat and the town crier. One brother who would not pay and one who would not let it go quietly, ever, at any volume. A family that will be having this exact fight at every dinner until the last of them dies. Some already have. It did not help.",
            SeedGuilty = 46,
            SeedInnocent = 21,
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
