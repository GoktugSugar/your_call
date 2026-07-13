namespace YourCall
{
    /// <summary>Chapter 7, case 9: THE WHISTLE. A woman reported a beloved coworker for something genuinely
    /// wrong, and the whole workplace turned on HER; the coworker lost everything, and she asks if she was the
    /// asshole for being right. Doing the right thing and paying for it. [heavy]</summary>
    public sealed class ConfessionWhistleBeat : ConfessionCaseBeat
    {
        protected override ConfessionData BuildData() => new ConfessionData
        {
            Announce = new[]
            {
                "Nine. And this one actually asks the question out loud, which most of them are far too proud to do.",
                "This one reported a coworker. A beloved one, the office favourite, for something genuinely, provably wrong. She was right. It cost the coworker everything. And then the whole office turned on her, not on him, and it cost her everything too. She wants to know if being right is what made her the villain. State it.",
            },
            Account = new[]
            {
                "What he did was real. I did not invent it, I did not stretch it, I reported exactly what happened and it was bad. Everyone agreed, out loud, that it was bad. And then everyone hated me for being the one who said it.",
                "I lost my job over his crime. My friends, my references, the way a room goes quiet when I walk into it now. I was right. I keep telling myself I was right. So why am I the only one who got punished for it.",
            },
            Headline = "I told the truth. It cost me everything.",
            RulePrompt = "The truth told, and the truth teller buried for telling it. Was she the [red]villain[/red] for being right. Rule.",
            VerdictGuilty = "She should have stayed quiet",
            VerdictInnocent = "She did the right thing",
            VerdictBoth = "Right, but not clean about it",
            ReactGuilty = "Guilty. Which here means you have looked at a woman who told the truth about a genuine wrong, and ruled that she should have swallowed it whole. Peace over honesty. A workable philosophy, and I do notice it is always the honest one we ask to be quiet, never the one they were being honest about. Interesting little choice.",
            ReactInnocent = "Cleared, fully, no asterisk, no small print. She was right, and she paid for it, and you flatly refuse to call the paying a crime. Clean. It will not hand her back the job, or the friends, or the rooms that stop talking when she enters, but she now has one judge, on the record, saying she was not the monster. That is not nothing. It is very close to nothing. But it is not quite it.",
            ReactBoth = "Everyone sucks, which is a bold thing to say about a woman whose entire crime was being correct. But I think you mean she was right and clumsy with it, righteous in a way that handed the office its excuse to hate her. Maybe. Or maybe you simply could not bring yourself to give a clean verdict to someone the whole crowd had already decided to punish. Even you. Even here. Telling.",
            OddRulingAside = "Sit with that a moment. When I ran this by the room, it did not go where you just went. She would find that either enormously comforting or completely unbearable, and honestly, so would I. Watch.",
            SeedGuilty = 12,
            SeedInnocent = 58,
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
