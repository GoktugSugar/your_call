namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 6, The Companion. A cloaked NPC wants to join, clearly hiding something. Trust them,
    /// refuse them, or use them and plan to ditch them, plus a class specific take. This SETS THE COMPANION FLAG,
    /// which the boss reads (beat 9): the trusted one returns to fight beside you, the used one turns up bitter,
    /// the refused one is simply not there. The imp, as DM, tells you plainly they are hiding something (he wrote
    /// the backstory, it is a doozy, and he will not share). [choice, chains, class option]
    /// </summary>
    public sealed class CampaignCompanionBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "On the road, a figure falls into step beside you. Cloaked, hooded, a little too eager. They would like to join your quest. For reasons. Which they do not offer.",
                    "As your DM, in the interest of fair play, I will tell you plainly: this one is hiding something. I know exactly what, because I wrote it, and it is a doozy, and I am not going to tell you, because that would be telling.",
                    "They hold out a hand. What do you do.",
                },
                RulePrompt = "The stranger waits.",
                Heading = "how others met the stranger",
                SceneDoodle = DoodleKind.Companion, SceneOutline = Palette.InkPurple, SceneScale = 1.6f,
            };
            d.Add(new CampaignOption
            {
                Label = "Trust them", Seed = 33,
                React = "You take their hand and trust them completely. A stranger. Hooded. On a road. In a haunted wood. Beautiful. You would have been eaten twice already tonight if I ran that wood properly. Welcome aboard, mystery friend.",
                Effect = s => s.Companion = CompanionTreatment.Trusted,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "Refuse them", Seed = 26,
                React = "You refuse. No thank you, spooky stranger. They nod, and drift back into the trees, and something goes out of their shoulders, and you will not see them again. Probably. Safe. A little lonely. Your call.",
                Effect = s => s.Companion = CompanionTreatment.Refused,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "Use them, then ditch them", Seed = 18,
                React = "You let them join, already planning to drop them the second they stop being useful. Cold. Efficient. I love it, and I am also a little frightened of you, and I am the deathless narrator of a void, so that is saying something.",
                Effect = s => s.Companion = CompanionTreatment.Used,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.4f,
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
                        Label = "Vouch for them on your honour", Seed = 22,
                        React = "The knight extends his honour over a total stranger like an umbrella, and it holds, because that is what honour is for. They are moved. They will remember this. So, it turns out, will I.",
                        Effect = s => s.Companion = CompanionTreatment.Trusted,
                    };
                case CampaignClass.Rogue:
                    return new CampaignOption
                    {
                        Label = "Clock their tell, keep them close", Seed = 20,
                        React = "You read them in a single glance, the tell, the thing they are hiding, and you keep them near precisely so you can spend it later. One rogue recognising another. This will go great, and by great I mean badly, and by badly I mean memorably.",
                        Effect = s => s.Companion = CompanionTreatment.Used,
                    };
                case CampaignClass.Wizard:
                    return new CampaignOption
                    {
                        Label = "Interrogate every inconsistency", Seed = 17,
                        React = "You cross examine them until the story collapses, which it does, because I built it to, and then, being a wizard, you refuse them on principle. Correctly. Coldly. Completely without backup. Enjoy being right on the road alone.",
                        Effect = s => s.Companion = CompanionTreatment.Refused,
                    };
                case CampaignClass.Bard:
                    return new CampaignOption
                    {
                        Label = "Win them over utterly", Seed = 24,
                        React = "You turn on the full bardic charm and they open right up, or nearly, and pledge themselves to you, terrible secret and all, which is the best kind of companion. Ask any story.",
                        Effect = s => s.Companion = CompanionTreatment.Trusted,
                    };
                case CampaignClass.Cleric:
                    return new CampaignOption
                    {
                        Label = "Offer grace, no questions", Seed = 21,
                        React = "You offer them grace without a single question, which is either deep wisdom or deep naivety, and honestly in a cleric those look identical. They accept, quietly. Something in them unclenches. I did not build that in. You did.",
                        Effect = s => s.Companion = CompanionTreatment.Trusted,
                    };
                default: return null;
            }
        }
    }
}
