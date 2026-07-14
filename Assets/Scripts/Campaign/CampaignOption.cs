using System;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One option at a Chapter 8 campaign beat: its label, the imp's choice independent DM reaction, an
    /// optional class gate (the option only appears for that class, the "class unlocks a unique option"
    /// mechanic), an optional coloured doodle (the class and reason menus draw one per option), the seeded
    /// crowd split for the reveal, an optional silent profile nudge, and an optional <see cref="Effect"/> that
    /// sets a run flag when the option is chosen (how the chaining is wired: the companion and village options
    /// set the flags the boss reads). Plain data, authored in the beat's BuildData (copy in code defaults, like
    /// the matchup / confession beats), so adding or gating an option is data.
    /// </summary>
    public sealed class CampaignOption
    {
        public string Label;                                     // the choice text, localized at display
        public string React;                                     // the imp's DM reaction (mock, never grades)
        public CampaignClass RequiresClass = CampaignClass.None; // None = common; else only this class sees it
        public DoodleKind Doodle = DoodleKind.None;              // optional (class / reason menus)
        public Color Outline;                                    // optional doodle outline (alpha 0 = doodle default)
        public int Seed;                                         // how-others-chose vote count (display only)

        // An optional light, silent profile nudge (who the player is, never scored).
        public bool HasProfile;
        public MoralAxis Axis = MoralAxis.EndsVsRules;
        public float Nudge;

        // An optional side effect applied to the run state when this option is chosen: the chaining flags
        // (the class, the companion, the village) are set here. Null = the option only flavors and feeds stats.
        public Action<CampaignState> Effect;

        /// <summary>The doodle outline colour: an explicit Outline if set, else the doodle's own default.</summary>
        public Color ResolveOutline() => Outline.a > 0f ? Outline : InkDoodle.DefaultColorFor(Doodle);

        /// <summary>Whether this option is available to a player of the given class (a common option always is;
        /// a class gated one only for its class).</summary>
        public bool AvailableTo(CampaignClass cls) => RequiresClass == CampaignClass.None || RequiresClass == cls;
    }
}
