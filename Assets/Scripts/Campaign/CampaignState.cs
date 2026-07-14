namespace YourCall
{
    /// <summary>Why the player took the quest (Chapter 8 beat 2, Your Reason). Flavor plus a light silent
    /// profile read; no pole is the good one.</summary>
    public enum CampaignReason { None, Gold, Glory, Rescue, Nowhere }

    /// <summary>How the player treated the companion (Chapter 8 beat 6, The Companion). Read at the boss
    /// (beat 9): the trusted one returns to fight beside you, the used one turns up anyway but bitter, the
    /// refused one is simply not there.</summary>
    public enum CompanionTreatment { None, Trusted, Refused, Used }

    /// <summary>What the player did at the village dilemma (Chapter 8 beat 7, The Village). Read at the boss:
    /// sparing the village earns their help, doing the ugly thing loses it.</summary>
    public enum VillageOutcome { None, DidTheUglyThing, SparedThem }

    /// <summary>
    /// The Chapter 8 (The Campaign) run state: the handful of FLAGS the chaining is built on. Earlier choices
    /// set these and later beats read them, so the linear story gains the illusion of choice without ever
    /// forking the path (see docs/gameplay.md). The class unlocks options at key beats; the companion and
    /// village flags change the boss; the reason, the fork and the treasure flavor later text and feed the
    /// silent profile.
    ///
    /// It is chapter scoped, owned by the <see cref="CampaignKit"/> and rebuilt fresh whenever the chapter
    /// scene loads (so a dev re-entry or a replay starts clean), NOT a persistent singleton. Like
    /// <see cref="KillLog"/> it is not part of the save file yet (best effort; a mid chapter Continue would
    /// reset it, noted in open-questions.md). It stores no copy and does no logic beyond holding the flags.
    /// </summary>
    public sealed class CampaignState
    {
        public CampaignClass Class = CampaignClass.None;
        public CampaignReason Reason = CampaignReason.None;
        public CompanionTreatment Companion = CompanionTreatment.None;
        public VillageOutcome Village = VillageOutcome.None;
        public bool TookShortcut;     // the fork (beat 5): the bold shortcut vs the safe long road
        public bool GrabbedTreasure;  // the treasure (beat 8): greed (grabbed the hoard) vs the mission

        /// <summary>Whether the companion is at the player's side for the boss (beat 9). The trusted one
        /// returns and the used one turns up too (bitter, which the boss copy handles); the refused one does
        /// not.</summary>
        public bool CompanionPresentAtBoss =>
            Companion == CompanionTreatment.Trusted || Companion == CompanionTreatment.Used;

        /// <summary>Whether the villagers ride in to help at the boss (beat 9): only if the player spared them
        /// instead of doing the ugly thing.</summary>
        public bool VillagersHelpAtBoss => Village == VillageOutcome.SparedThem;
    }
}
