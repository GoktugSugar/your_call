using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// Chapter 8 beat 9, The Boss. The convergence, where the linear but chained choices pay off. The dragon is
    /// approached based on everything: the CLASS (a unique approach), whether the COMPANION is here (the flag
    /// from beat 6), and whether the VILLAGERS ride to help (the flag from beat 7). The narration is assembled
    /// from those flags (who stands with you, or does not), and a situational option literally changes what is
    /// available (finish it together, loose the village, trust the one you used, or throw everything you have
    /// left at it alone). The imp DMs the climax he built the whole night around and keeps deflating it. Heavy.
    /// [heavy, class + flags]
    /// </summary>
    public sealed class CampaignBossBeat : CampaignBeat
    {
        protected override CampaignData BuildData(CampaignState state)
        {
            var lines = new List<string>
            {
                "The dragon. The one I built the entire evening around. It is bigger than it strictly needed to be, because I got excited making it, and I regret nothing. It uncoils out of the dark and fixes on you.",
            };
            lines.Add(CompanionLine(state));
            string village = VillageLine(state);
            if (village != null) lines.Add(village);
            lines.Add("So here it is, judge. The whole night comes down to this room. It looks at you and waits. How do you take a dragon.");

            var d = new CampaignData
            {
                Narration = lines.ToArray(),
                RulePrompt = "The dragon waits.",
                Heading = "how others took the dragon",
                SceneDoodle = DoodleKind.Dragon, SceneOutline = Palette.InkRed, SceneScale = 2.0f,
                ScenePos = new UnityEngine.Vector2(0f, 0.85f),
            };
            d.Add(new CampaignOption
            {
                Label = "Fight it", Seed = 34,
                React = "You fight it. Sword and fury and no plan beyond hitting the dragon until the dragon stops being a dragon. It is the option every table reaches for and it is never once the clever one, and it works about half the time, which is somehow better odds than clever, and I hate that.",
            });
            d.Add(new CampaignOption
            {
                Label = "Talk it down", Seed = 22,
                React = "You try to talk down a dragon. A DRAGON. And because I am a soft touch and I secretly live for the moment a player tries the completely mad thing, I let it half work. It listens. Dragons are older than the kingdoms and bored out of their enormous skulls, and sometimes the maddest thing you can do to one is simply make conversation.",
                HasProfile = true, Axis = MoralAxis.MercyVsJustice, Nudge = -0.2f,
            });
            d.Add(new CampaignOption
            {
                Label = "Trick it", Seed = 21,
                React = "You trick it. A feint, a lie, a neat little piece of misdirection, because if you cannot out muscle a dragon you can out think one, and this dragon, for all its size, has the strategic mind of a very large, very warm cat. It falls for it. Mostly. Enough.",
            });
            var co = ClassOption(state.Class);
            if (co != null) d.Add(co);
            d.Add(SituationalOption(state));
            return d;
        }

        // ---------- flag-driven narration ----------

        private static string CompanionLine(CampaignState s)
        {
            switch (s.Companion)
            {
                case CompanionTreatment.Trusted:
                    return "Your companion is at your shoulder, hood down at last, blade drawn. The stranger you trusted turned out to be worth trusting. You are not alone up here. Most people reach my dragon having burned every last bridge behind them. Not you. Huh.";
                case CompanionTreatment.Used:
                    return "Your companion is here too, at your shoulder, though they will not meet your eye. You used them, and they know it, and they came anyway, which is either loyalty or a plan, and with this one I could not honestly tell you which.";
                default:
                    return "You face it alone. The stranger who offered to walk with you is somewhere far behind, sent off at the crossroads, and there is only you up here now, which is exactly how the songs pretend a hero wants it.";
            }
        }

        private static string VillageLine(CampaignState s)
        {
            switch (s.Village)
            {
                case VillageOutcome.SparedThem:
                    return "And there, cresting the hill behind you, the village. Pitchforks, torches, terrible courage. The people you spared in the barrow, come to stand at a dragon's feet for a stranger. I did not build them to do that. Your mercy did.";
                case VillageOutcome.DidTheUglyThing:
                    return "The village is not coming. Their doors are barred and their shutters are down, because a village does not march on a dragon for the man who did what you did in the barrow. You bought the relic. It cost you the militia. Everything costs something here, especially here.";
                default:
                    return null;
            }
        }

        // ---------- the situational option (availability changes with the chaining) ----------

        private static CampaignOption SituationalOption(CampaignState s)
        {
            if (s.Companion == CompanionTreatment.Trusted)
                return new CampaignOption
                {
                    Label = "Finish it together", Seed = 12,
                    React = "You and the one you trusted hit it as one, two blades and a shared plan, and it is exactly the kind of moment I was hoping somebody would earn tonight, and almost nobody does, because almost nobody trusts the hooded stranger on the road. You did. Look at it. Look at what trust buys.",
                    HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.2f,
                };
            if (s.Companion == CompanionTreatment.Used)
                return new CampaignOption
                {
                    Label = "Put your life in their hands now", Seed = 11,
                    React = "You turn to the companion you used and, at the one moment it truly matters, you put your life in their hands. And they look at you. And there is a long, long beat where even I, who wrote them, do not know what they will do. Then they move. You will have to work out later whether it was for you or in spite of you. Not now. Now there is a dragon.",
                };
            if (s.VillagersHelpAtBoss)
                return new CampaignOption
                {
                    Label = "Loose the village on it", Seed = 12,
                    React = "You raise one hand and a whole village you once spared pours past you at a dragon, which is insane, and glorious, and works, roughly, at a cost, the way a mob always does. You did not do this alone. You did it because once, in a barrow, you were merciful and poor about it. Funny, how that comes back around.",
                    HasProfile = true, Axis = MoralAxis.SelfVsOthers, Nudge = 0.2f,
                };
            return new CampaignOption
            {
                Label = "Throw everything you have left at it", Seed = 10,
                React = "No companion, no village, no cavalry over the hill. Just you and the too big dragon and whatever you happened to walk in carrying. You throw all of it at the thing at once, holding nothing back, because there is nothing behind you left to save it for. It is desperate, and lonely, and, fine, all right, a little magnificent.",
            };
        }

        // ---------- the class approach ----------

        private static CampaignOption ClassOption(CampaignClass cls)
        {
            switch (cls)
            {
                case CampaignClass.Knight:
                    return new CampaignOption
                    {
                        Label = "Challenge it to single combat", Seed = 14,
                        React = "You challenge a dragon to single combat by the old code, and the ridiculous thing is it accepts, because dragons are vain and a formal duel appeals to something ancient in them. Honour against a lizard the size of a barn. Somewhere your old bench is applauding and appalled in exactly equal measure.",
                    };
                case CampaignClass.Rogue:
                    return new CampaignOption
                    {
                        Label = "Go for the soft spot under the wing", Seed = 13,
                        React = "You go for the one soft spot under the wing, the unglamorous, unheroic, wholly effective spot, while it is busy being a dragon at you. No song will ever mention it. Every song leaves out the part where the hero wins dirty. You know why. Because winning dirty is how heroes actually win.",
                    };
                case CampaignClass.Wizard:
                    return new CampaignOption
                    {
                        Label = "Unbind the spell that chains it here", Seed = 12,
                        React = "You stop swinging and start reading, and you find the spell chaining the thing to this barrow, the leash, and you unpick it, and the dragon, suddenly free, looks at you with something almost like gratitude before it decides what to do about you. You gambled the entire fight on being right. Very wizard. Very brave. Do not ever do it again.",
                    };
                case CampaignClass.Bard:
                    return new CampaignOption
                    {
                        Label = "Sing the one song that unmakes it", Seed = 13,
                        React = "You sing it the one song, the old one, the one that unmakes a dragon, and I have to allow it, because three hours ago I wrote a rule that said a good enough performance beats anything, and here we are, and it is genuinely beautiful, and I am furious, and you are magnificent.",
                    };
                case CampaignClass.Cleric:
                    return new CampaignOption
                    {
                        Label = "Offer it peace, and mean it", Seed = 12,
                        React = "You offer a dragon peace, and you mean it, all the way to the floor, and the terrible thing about meaning it is that sometimes it simply works, and the single most dangerous creature in my whole world just, quietly, decides not to be. You did not defeat it. You forgave it into standing down. I do not have a rule for that. I am writing one now, while you watch.",
                        HasProfile = true, Axis = MoralAxis.MercyVsJustice, Nudge = -0.2f,
                    };
                default: return null;
            }
        }
    }
}
