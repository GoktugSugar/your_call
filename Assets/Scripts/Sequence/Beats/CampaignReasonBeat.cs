namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 2, Your Reason. Why you are on this quest, as a coloured-doodle menu. Pure flavor plus a
    /// light silent profile read (no pole is the good one); it does not gate anything, it just colours who the
    /// hero is and gives the imp more to needle. He keeps breaking the fantasy: the thing you want to save does
    /// not exist, the gold cannot be spent, and he wrote all of it.
    /// </summary>
    public sealed class CampaignReasonBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "Every hero needs a reason. It is called motivation. I read half a book about it once and then got bored, which is also a kind of motivation.",
                    "So why are you doing this. Why does a dead judge pick up a sword and march off into a story. Be honest, I already know, I wrote you.",
                },
                RulePrompt = "Why are you here?",
                Heading = "why others answered the call",
            };
            d.Add(new CampaignOption
            {
                Label = "For the gold", Doodle = DoodleKind.Coins, Outline = Palette.InkGold, Seed = 30,
                React = "Gold. Refreshingly honest. A dead man chasing a pile of money he cannot spend, in a kingdom that is not real. I could not have written you better myself, and I did.",
                Effect = s => s.Reason = CampaignReason.Gold,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "For the glory", Doodle = DoodleKind.Trophy, Outline = Palette.InkOrange, Seed = 24,
                React = "Glory. The songs, the statues, a tavern named after you. You, a man nobody in the waking world will remember by next Thursday, want the imaginary people to chant your name. It is almost sweet.",
                Effect = s => s.Reason = CampaignReason.Glory,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.2f,
            });
            d.Add(new CampaignOption
            {
                Label = "To save someone", Doodle = DoodleKind.QuestHeart, Outline = Palette.InkPink, Seed = 31,
                React = "To save someone. Noble. There is nobody to save, they are all made of me, but the reflex is lovely. A man who cannot save himself, off to rescue a stranger I invented. I will allow it.",
                Effect = s => s.Reason = CampaignReason.Rescue,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.3f,
            });
            d.Add(new CampaignOption
            {
                Label = "Nowhere else to be", Doodle = DoodleKind.Signpost, Outline = Palette.Muted, Seed = 15,
                React = "Nowhere else to be. Ha. There it is. The truest answer a dead man ever gave me. You are here because I am the only thing still happening to you. Come on then. Let us make the nothing count.",
                Effect = s => s.Reason = CampaignReason.Nowhere,
            });
            return d;
        }
    }
}
