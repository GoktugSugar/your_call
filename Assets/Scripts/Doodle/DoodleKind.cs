namespace YourCall
{
    /// <summary>
    /// Which small hand-drawn ink doodle to draw for a would-you-rather option (see
    /// <see cref="InkDoodle"/> and docs/art-and-ui.md). Referenced from the data (a `Dilemma`'s two
    /// option doodles), so adding a new would-you-rather that reuses existing doodles is pure data.
    /// Adding a brand new doodle is a new value here plus its drawer in <see cref="InkDoodle"/>.
    /// </summary>
    public enum DoodleKind
    {
        None,
        TurdSwirl,      // a poop coiled like soft serve (the shit that tastes like ice cream)
        ConeSwirl,      // an ice cream cone with the same swirl (the ice cream that tastes like shit)
        WingedFigure,   // a little figure with wings (flight)
        FlexingFigure,  // a figure flexing a bicep (super strength)
        GiantDuck,      // one big duck (the size of a horse)
        TinyHorses,     // a little herd of tiny horses (the size of ducks)
        RewindButton,   // a round button with a rewind symbol
        PauseButton,    // a round button with a pause symbol
        Snowflake,      // a snowflake (always a little too cold)
        Sun,            // a sun (always a little too hot)
        ThirdArmFigure, // a stick figure with a third arm
        TwoHeadFigure   // a stick figure with two heads
    }
}
