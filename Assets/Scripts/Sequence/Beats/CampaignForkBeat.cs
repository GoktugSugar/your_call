namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 5, The Fork. A crossroads: the safe long road, or the dangerous shortcut the imp swears is
    /// fine in a tone that means it is not. Caution against boldness, remembered on the run's risk axis. The imp
    /// leans into the railroad and then lampshades it (that was me doing a voice, the voice of a DM steering you
    /// at the encounter I already built). Sets the shortcut flag for later flavour. [choice, chains]
    /// </summary>
    public sealed class CampaignForkBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "A fork in the road. Ahead, the long way: safe, well travelled, dull, and a good hour out of your evening. To the left, a shortcut through the Whispering Wood.",
                    "I, your impartial and trustworthy Dungeon Master, promise you the shortcut is completely fine. Totally safe. Nothing lives in the Whispering Wood. Why would it be called that. Do not think about the name. Take the shortcut. It is fine.",
                    "That was me doing a voice, by the way. The voice of a DM steering you straight at the encounter I already built and do not want to waste. You can still take the long road and ruin my whole afternoon. Genuinely. Your call.",
                },
                RulePrompt = "Which way?",
                Heading = "which road others took",
                SceneDoodle = DoodleKind.Signpost, SceneOutline = Palette.Muted, SceneScale = 1.5f,
            };
            d.Add(new CampaignOption
            {
                Label = "The safe long road", Seed = 41,
                React = "You take the long, safe, sensible road, and nothing happens, at length, in detail, for an hour, exactly as promised. It is the most responsible thing anyone has done to me all night. I am bored senseless. You are perfectly safe. Congratulations on both counts.",
                Effect = s => s.TookShortcut = false,
                HasProfile = true, Axis = MoralAxis.RiskVsSafety, Nudge = 0.4f,
            });
            d.Add(new CampaignOption
            {
                Label = "The dangerous shortcut", Seed = 59,
                React = "You take the shortcut, into the wood that is definitely fine, and three separate things immediately try to eat you, and you are delighted, and so am I. See. This is why we take the shortcut. Nobody has ever told a story about the long road.",
                Effect = s => s.TookShortcut = true,
                HasProfile = true, Axis = MoralAxis.RiskVsSafety, Nudge = -0.4f,
            });
            return d;
        }
    }
}
