namespace YourCall
{
    /// <summary>What a main-menu line does when chosen. Kept separate from the loop so adding a
    /// line later (e.g. Quit) is a new value and one handler, not new navigation code.</summary>
    public enum MenuAction
    {
        Continue,
        NewGame,
        Settings
    }
}
