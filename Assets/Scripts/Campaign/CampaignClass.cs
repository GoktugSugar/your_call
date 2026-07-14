namespace YourCall
{
    /// <summary>
    /// The player's chosen class in Chapter 8 (The Campaign), picked at character creation and stored in the
    /// run state (see <see cref="CampaignState"/>). It is FLAVOR, not numbers: no class is stronger, each is a
    /// different way of being, and it UNLOCKS a unique option at the key beats (the bard talks his way through,
    /// the rogue steals or lies, the knight fights, the wizard overthinks a clever answer, the cleric helps or
    /// heals). Elsewhere it flavors the wording. A campaign option can require a class (see
    /// <see cref="CampaignOption.RequiresClass"/>); <see cref="None"/> means the option is common to every class.
    /// </summary>
    public enum CampaignClass
    {
        None,
        Knight,   // honour and steel: the fight option
        Rogue,    // knives and lies: the steal / lie option
        Wizard,   // books and cleverness: the overthink / clever option
        Bard,     // charm and song: the talk-your-way option
        Cleric    // faith and mending: the help / heal option
    }
}
