namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 4, The Tavern. The quest giver is an obvious liar with a too good reward. Take the job,
    /// haggle, threaten, or walk, plus a class specific option (the knight makes him swear, the rogue lifts his
    /// purse, the wizard picks his story apart, the bard charms him, the cleric disarms him). Sets the tone. The
    /// imp DMs it earnestly and keeps puncturing it (he tells you the man is lying, on the record, as a courtesy).
    /// [choice, class option]
    /// </summary>
    public sealed class CampaignTavernBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "The Salted Hog. A tavern. It smells of ale and imaginary vomit, which I rendered for you lovingly. In the corner, a nervous man waves you over. Your quest giver.",
                    "He is lying. I want to be clear about that up front, as your Dungeon Master, breaking every rule of my craft: this man is lying to your face. The reward is too big, the job is too simple, and he keeps glancing at the door. Slay the beast in the northern barrow, he says, and this chest of gold is yours.",
                    "So. What do you do about the obvious liar and his beautiful, obvious lie.",
                },
                RulePrompt = "Your move.",
                Heading = "what others did at the table",
                SceneDoodle = DoodleKind.Coins, SceneOutline = Palette.InkGold, SceneScale = 1.4f,
            };
            d.Add(new CampaignOption
            {
                Label = "Take the job", Seed = 30,
                React = "You take it. No questions, no haggling, straight into the trap with a grin. Bold. Stupid. My favourite kind of player, honestly. You make the night move.",
            });
            d.Add(new CampaignOption
            {
                Label = "Haggle harder", Seed = 22,
                React = "You haggle. Over pretend gold. With a known liar. In a bar I invented this afternoon. And you drive a hard bargain and win forty imaginary extra coins and feel genuinely proud. I am not mocking you. I am. But gently.",
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.2f,
            });
            d.Add(new CampaignOption
            {
                Label = "Threaten him", Seed = 15,
                React = "You lean in and threaten him and he goes pale, because I made him go pale, because you are the player and my little people are frightened of you by default. It is a cheap thrill. You took it anyway. Noted.",
                HasProfile = true, Axis = MoralAxis.OrderVsFreedom, Nudge = 0.2f,
            });
            d.Add(new CampaignOption
            {
                Label = "Walk away", Seed = 13,
                React = "You walk. From the plot. On the very first beat. You magnificent coward. Do not worry, the plot walks after you. It knows where you live. It is called a main quest for a reason. Now sit back down.",
                HasProfile = true, Axis = MoralAxis.RiskVsSafety, Nudge = 0.2f,
            });
            var co = ClassOption(state.Class);
            if (co != null) d.Add(co);
            return d;
        }

        private CampaignOption ClassOption(CampaignClass cls)
        {
            switch (cls)
            {
                case CampaignClass.Knight:
                    return new CampaignOption
                    {
                        Label = "Make him swear it on his honour", Seed = 19,
                        React = "The knight makes the liar swear the reward on his honour, and he does, sweating, because a knight asked and the code compels a made up man to answer. He is still lying. Now he is lying under oath. You have achieved nothing but paperwork, nobly.",
                    };
                case CampaignClass.Rogue:
                    return new CampaignOption
                    {
                        Label = "Lift his purse while he lies", Seed = 21,
                        React = "While he spins his tale you lift his purse clean off his belt. Inside: eleven coins and a note that reads do not trust him. You already knew. You take the job anyway, now down a friend and up a purse. Rogues.",
                    };
                case CampaignClass.Wizard:
                    return new CampaignOption
                    {
                        Label = "List the three holes in his story", Seed = 18,
                        React = "You calmly recite the three holes in his story. He blinks. He had not noticed hole two himself. You have out plotted the plotter, who is me, which is annoying. Fine. He confesses half of it. You take the job anyway, because knowing it is a trap has never once stopped anybody.",
                    };
                case CampaignClass.Bard:
                    return new CampaignOption
                    {
                        Label = "Charm the real terms out of him", Seed = 24,
                        React = "You turn the charm on and he melts and tells you the real deal, which is worse, obviously, and you take it anyway, because you are having a lovely time and the danger belongs to the character you are pretending to be.",
                    };
                case CampaignClass.Cleric:
                    return new CampaignOption
                    {
                        Label = "Ask what he is so afraid of", Seed = 20,
                        React = "You ask him, gently, what he is so afraid of. And the liar stops lying, just for a second, and looks very tired, and I did not plan for that, and now I feel strange about my own NPC. Thanks for that. You take the job. He wishes you luck and, oddly, means it.",
                    };
                default: return null;
            }
        }
    }
}
