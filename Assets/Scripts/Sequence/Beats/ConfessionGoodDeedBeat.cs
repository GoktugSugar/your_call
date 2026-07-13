namespace YourCall
{
    /// <summary>Chapter 7, case 8: THE GOOD DEED. A man saved a stranger's life, then held it over them for
    /// years, demanding gratitude and favors forever. Is a good deed still good if it becomes a debt you collect
    /// on. The rescuer is the one confessing. [medium]</summary>
    public sealed class ConfessionGoodDeedBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Eight. A rescue. And what came after the rescue, which is the actual case.",
                "Years ago this one pulled a drowning stranger out of a river. Saved his life, no question, no argument, a genuinely brave thing. And has spent every year since reminding him of it. Favours, loyalty, a standing invitation to feel indebted. The man he saved has started screening his calls. State your case.",
            },
            Account = new[]
            {
                "He would be dead. Do you understand that. Dead, in the ground, twenty years now, if I had not gone in after him. Everything he has, the wife, the kids, the whole little life, all of it is on loan from me.",
                "So yes, when I need something, I ask him first. Is that so much. I handed him back the entire world. I think I am allowed to expect a phone call returned.",
            },
            Headline = "I gave him his whole life back.",
            RulePrompt = "A life saved, and then invoiced, forever. Is the rescue still a gift if it never once stops being a bill. Rule.",
            VerdictGuilty = "He turned a rescue into a leash",
            VerdictInnocent = "A life owes something",
            VerdictBoth = "Both drowning, differently",
            ReactGuilty = "Guilty. A good deed with a lifelong interest rate, you are saying, is not a good deed at all, it is a purchase. Clean. He is going to loathe that ruling, because in his own head he has been the hero this entire time, and you have just repriced him as a debt collector with wet shoes.",
            ReactInnocent = "Cleared. A life is the largest thing there is, so the man who handed it back gets to keep drawing on the account. Forever. You have ruled that gratitude is a debt with no final payment, which, do please think for a moment about who in your own life might be quietly keeping that exact same ledger open on you.",
            ReactBoth = "Everyone sucks. The drowning man who will not pick up the phone, and the swimmer who will not stop dialling. One cannot say thank you often enough to ever be free, the other cannot hear thank you without wanting more. Bound together by a river neither of them ever really climbed out of. Poetic. Also exhausting for everyone downstream.",
            SeedGuilty = 55,
            SeedInnocent = 17,
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
