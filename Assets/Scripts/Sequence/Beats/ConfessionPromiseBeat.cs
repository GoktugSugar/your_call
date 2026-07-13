namespace YourCall
{
    /// <summary>Chapter 7, case 6: THE PROMISE. A man promised his dying mother he would keep the family home
    /// forever, then sold it a year later because he genuinely needed the money to feed his own kids. A promise
    /// to the dead against the needs of the living. [heavy]</summary>
    public sealed class ConfessionPromiseBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Six. And the room gets heavier from here, so brace whatever it is you have instead of a stomach.",
                "This one sat at his mother's deathbed and promised her, out loud, in words, that he would keep the family home. Forever. He sold it inside a year. Not for a boat. He needed the money to feed his own children. State your case, and take your time. She cannot hear you now anyway.",
            },
            Account = new[]
            {
                "She made me promise while she was already going. What was I supposed to say. No? You do not argue with a dying woman. You say yes, and you mean it, and I did mean it, I swear I did.",
                "And then it was a house full of her ghosts, or my kids eating every day. I chose the ones who were still alive. I think she would have understood. I have to think that. It is the only thing that gets me through the night.",
            },
            Headline = "My kids had to eat.",
            RulePrompt = "A promise to the [red]dead[/red], against the hunger of the living. Rule, judge. This one is the actual job.",
            VerdictGuilty = "He broke a sacred vow",
            VerdictInnocent = "The living come first",
            VerdictBoth = "An impossible promise, broken",
            ReactGuilty = "Guilty of breaking a deathbed vow. Some promises are supposed to cost you everything, you are saying, and a word given to the dying is the very heaviest kind. Hard line. She would be proud of that ruling, if pride were still available to her, which, and I cannot stress this strongly enough, it is not.",
            ReactInnocent = "Cleared. The [red]dead[/red] do not eat, the children do, and you sided with the pulse over the promise. Warm. Sensible. And it does quietly establish that a dying wish is worth precisely nothing the moment it becomes inconvenient. Good to know. I will keep it in mind when it is your turn to want something honoured.",
            ReactBoth = "Everyone sucks, though I would gently note that the mother is beyond caring and the children only wanted dinner, so mostly you are indicting a man for being poor at the exact moment he was also grieving. Generous of you. Bleakly, and it must be said humanly, fair.",
            OddRulingAside = "Careful now. The room split hard on this one, and you have landed on the side almost no one did. Not wrong. Just alone up there. Watch.",
            SeedGuilty = 22,
            SeedInnocent = 48,
            SeedBoth = 30,
            Heading = "how the room ruled",
            HasProfile = true,
            Axis = MoralAxis.MercyVsJustice,
            NudgeGuilty = 0.5f,
            NudgeInnocent = -0.5f,
            NudgeBoth = 0f,
        };
    }
}
