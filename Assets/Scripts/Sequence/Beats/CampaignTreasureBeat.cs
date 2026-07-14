namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 8, The Treasure. The second real dilemma, inside the fiction. Past the beast is a hoard
    /// and a cursed, powerful black blade. Take the cursed power, grab the gold and abandon the whole quest, or
    /// walk past all of it and keep to the mission. Greed against the mission, and the imp is openly delighted
    /// if you consider simply leaving (and then railroads you back, because he built a dragon). Feeds the profile
    /// more heavily than a flavour beat. [choice / dilemma 2]
    /// </summary>
    public sealed class CampaignTreasureBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            // A short callback to the fork (whole authored lines, so each stays a stable localization key).
            var shortcut = state.TookShortcut
                ? "The shortcut spat you out right on top of it, which is the one good thing that wood ever did for anybody."
                : "The long road got you here eventually, footsore and thorough, but it got you here.";
            var d = new CampaignData
            {
                Narration = new[]
                {
                    shortcut,
                    "Deep in the barrow you find it. A hoard. Gold to the ceiling, and resting on the pile, a black blade that hums. Cursed. Powerful. The kind of thing that solves your every problem and takes a small piece of you for each one it solves.",
                    "Now. Here is where I, as your Dungeon Master, lean in and watch very closely. Because the quest is still out there, waiting, important, the entire point of the evening. And here is a room with everything you came for in it, and no dragon.",
                    "You could take the cursed blade. You could scoop the gold and simply leave, quest be damned. Or you could walk past all of it and stay the course. I honestly do not know which you will do, and that is rare for me. Go on.",
                },
                RulePrompt = "The hoard glitters.",
                Heading = "what others did in the hoard",
                SceneDoodle = DoodleKind.TreasureChest, SceneOutline = Palette.InkGold, SceneScale = 1.6f,
            };
            d.Add(new CampaignOption
            {
                Label = "Take the cursed blade", Seed = 38,
                React = "You take the humming black blade, and it purrs, and something behind your eyes goes a little dim, and you feel wonderful, which is exactly how it always begins. Power for parts. You will not miss the parts. That is the whole trick of a curse. Lovely choice.",
                Effect = s => s.GrabbedTreasure = true,
                HasProfile = true, Axis = MoralAxis.EndsVsRules, Nudge = -0.4f,
            });
            d.Add(new CampaignOption
            {
                Label = "Grab the gold and go home", Seed = 24,
                React = "You scoop the gold and turn for the door, abandoning the entire quest on the very doorstep of its treasure, and I want you to know, as a storyteller, that this is the single most honest thing a player has ever done in one of my campaigns. It is also not allowed. Sit down. I built a dragon. We are seeing the dragon. Bring the gold, fine. But we are seeing the dragon.",
                Effect = s => s.GrabbedTreasure = true,
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = -0.5f,
            });
            d.Add(new CampaignOption
            {
                Label = "Leave it, keep to the mission", Seed = 38,
                React = "You walk past a literal room of gold and a literal cursed sword of power to go finish a job for a man who lied to your face. That is either the noblest thing I have watched all night or a diagnosable condition, and in you I genuinely cannot tell which, and that is the kindest thing I can say about a person.",
                HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.35f,
            });
            return d;
        }
    }
}
