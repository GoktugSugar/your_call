namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 1, Your Class. A genuine personality question dressed as a character-creation menu: pick
    /// the kind of hero you are, each a distinct coloured doodle. It stores the class in the run state, which
    /// UNLOCKS a unique option at the key beats later (the tavern, the village, the boss). The imp, as an over
    /// eager DM, sells the fantasy and immediately punctures it (the choices decide nothing, and also
    /// everything). Classes are equal, none stronger, each a way of being; the light silent profile nudge just
    /// reads which way the player leans. [the character read]
    /// </summary>
    public sealed class CampaignClassBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "New game. Forget the tracks, forget the buttons, we are doing something completely different tonight, and I have been looking forward to it for an embarrassingly long time.",
                    "You are an adventurer now. I am the Dungeon Master. That means I built this entire world, I know everything that is going to happen in it, and you get to sit there and pretend your choices matter. They will not, particularly. But you get to pretend, and that is the fun part, for me.",
                    "So. What kind of hero are you. Choose carefully. It decides absolutely nothing, and also the whole rest of your night.",
                },
                RulePrompt = "Pick your class.",
                Heading = "how others built their hero",
            };
            d.Add(new CampaignOption
            {
                Label = "The Knight", Doodle = DoodleKind.Knight, Outline = Palette.InkBlue, Seed = 34,
                React = "A knight. Honour, a big sword, a jaw you could set a table on. You will do the right thing at every turn and die nobly, and bore absolutely everyone at the funeral.",
                Effect = s => s.Class = CampaignClass.Knight,
                HasProfile = true, Axis = MoralAxis.OrderVsFreedom, Nudge = -0.4f,
            });
            d.Add(new CampaignOption
            {
                Label = "The Rogue", Doodle = DoodleKind.Rogue, Outline = Palette.InkGreen, Seed = 27,
                React = "A rogue. You checked me for a coin purse while I was still explaining the rules. I saw that. We are going to get along horribly.",
                Effect = s => s.Class = CampaignClass.Rogue,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.4f,
            });
            d.Add(new CampaignOption
            {
                Label = "The Wizard", Doodle = DoodleKind.Wizard, Outline = Palette.InkPurple, Seed = 22,
                React = "A wizard. Naturally. You will solve every problem by explaining it to death, and I will sit here pretending the rules of magic are consistent. They are not. I invent them as I go. So do you, it turns out.",
                Effect = s => s.Class = CampaignClass.Wizard,
                HasProfile = true, Axis = MoralAxis.RiskVsSafety, Nudge = 0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "The Bard", Doodle = DoodleKind.Bard, Outline = Palette.InkOrange, Seed = 10,
                React = "A bard. You are going to try to talk your way past a dragon at some point tonight, and honestly a small part of me cannot wait to watch that not work.",
                Effect = s => s.Class = CampaignClass.Bard,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "The Cleric", Doodle = DoodleKind.Cleric, Outline = Palette.InkGold, Seed = 7,
                React = "A cleric. Faith, mending, a good and tender heart. You will spend the whole night healing people who were going to be perfectly fine, and calling it a calling.",
                Effect = s => s.Class = CampaignClass.Cleric,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.4f,
            });
            return d;
        }
    }
}
