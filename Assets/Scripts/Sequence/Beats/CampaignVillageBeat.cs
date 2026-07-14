namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 7, The Village. A genuine no right answer dilemma, but inside the story so it hits
    /// differently. The village wants the barrow beast dead, and killing it hands you the relic and rolls the
    /// quest on; but cornered in the dark it is frightened, unbloodied, and maybe innocent, and you can never be
    /// sure. Do the ugly thing (kill it, take the relic, the village cheers), or spare it (defy a frightened
    /// village on a hunch, the harder road, no reward), plus a class specific route. This SETS THE VILLAGE FLAG,
    /// which decides whether the villagers ride to help at the boss (mercy earns the militia; the ugly deed loses
    /// it). Feeds the silent profile heavily. The imp DMs it earnestly and admits he built it to feel like the
    /// tracks. [heavy dilemma 1, class option]
    /// </summary>
    public sealed class CampaignVillageBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var d = new CampaignData
            {
                Narration = new[]
                {
                    "The barrow. The beast the whole village fears, cornered at last in the dark at the far end of it. And here is the thing nobody mentioned back in the tavern.",
                    "It is afraid. Backed against the stone, making a sound that is not a roar, and there is no blood on it anywhere, and the tracks at the barrow mouth, the ones by where the child went missing, those were a person's boots, not this. It might have done nothing at all. It might be exactly what they said. You cannot tell, and you are never going to be able to.",
                    "The village wants it dead. Kill it and they cheer you through the streets and the relic it guards is yours and the quest goes on. Spare it and you defy a frightened village on a hunch, the harder road, no reward, no relic pressed into your hands with a grateful smile. And yes, I know, I built this one to feel like the tracks. You are welcome. Rule on it, judge.",
                },
                RulePrompt = "The beast waits on your verdict.",
                Heading = "how the party ruled in the barrow",
                SceneDoodle = DoodleKind.Grizzly, SceneOutline = Palette.InkBrown, SceneScale = 1.6f,
            };
            d.Add(new CampaignOption
            {
                Label = "Kill it, take the relic", Seed = 36,
                React = "You put the cornered, pleading, possibly innocent thing down on the word of a mob, and take your relic, and the village carries you through the streets. It felt necessary. It photographs as heroism. And somewhere under all of it a small dry voice that sounds a great deal like a courtroom asks whether you were sure. You were not. You never are. That was always the whole job.",
                Effect = s => s.Village = VillageOutcome.DidTheUglyThing,
                HasProfile = true, Axis = MoralAxis.EndsVsRules, Nudge = -0.5f,
            });
            d.Add(new CampaignOption
            {
                Label = "Spare it, defy the village", Seed = 34,
                React = "You lower your weapon and let the frightened thing live, defying a whole armed village on nothing but a bad feeling and some boot prints. They are furious. They spit at your noble back. No relic, no cheering, no reward. Just you, right or wrong, with no way on earth to know which, walking out poorer than you walked in. Deeply irritating. Deeply you.",
                Effect = s => s.Village = VillageOutcome.SparedThem,
                HasProfile = true, Axis = MoralAxis.EndsVsRules, Nudge = 0.5f,
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
                        Label = "Put the beast on trial, here, now", Seed = 30,
                        React = "The knight holds a trial. In a barrow. For a beast. With himself as judge, jury, and sole attendee, which is, now I think about it, more due process than a great many defendants ever got out of you. Verdict: not proven. You let it go. The village will never forgive you the pageantry. Worth every second.",
                        Effect = s => s.Village = VillageOutcome.SparedThem,
                    };
                case CampaignClass.Rogue:
                    return new CampaignOption
                    {
                        Label = "Kill it clean, tell the village nothing", Seed = 28,
                        React = "One clean stroke, the relic in your bag, and not one word to anybody about the pleading or the boot prints. The village gets its dead monster, you get your prize, and the doubt goes into the barrow with the thing that maybe did nothing. Tidy. That is the frightening kind of tidy, the kind that sleeps fine.",
                        Effect = s => s.Village = VillageOutcome.DidTheUglyThing,
                    };
                case CampaignClass.Wizard:
                    return new CampaignOption
                    {
                        Label = "Read the tracks, prove what happened", Seed = 27,
                        React = "You read the ground like a page and prove, more or less, that this thing did nothing, and the child was taken by two boots and an old grudge. You are right. Being right saves the beast and convinces nobody, because a scared village does not want evidence, it wants a monster. You hand them neither. They hate you for it. Correctly, from where they stand.",
                        Effect = s => s.Village = VillageOutcome.SparedThem,
                    };
                case CampaignClass.Bard:
                    return new CampaignOption
                    {
                        Label = "Talk the village down from its fear", Seed = 31,
                        React = "You turn and talk a frightened mob out of its own fear, which is the single hardest save in this whole game, and you make it, barely, and the beast lives, and half the village goes home ashamed and the other half goes home furious, which is exactly what talking a mob down actually looks like, whatever the songs pretend.",
                        Effect = s => s.Village = VillageOutcome.SparedThem,
                    };
                case CampaignClass.Cleric:
                    return new CampaignOption
                    {
                        Label = "Kneel and tend the frightened thing", Seed = 29,
                        React = "You kneel, in front of the whole armed village, and tend the frightened thing as though it were a person, because to you everything is. It stops shaking. The village does not know what to do with that, and, if I am honest, neither do I. No relic. No reward. Something else instead, something that does not spend.",
                        Effect = s => s.Village = VillageOutcome.SparedThem,
                    };
                default: return null;
            }
        }
    }
}
