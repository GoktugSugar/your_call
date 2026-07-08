namespace YourCall
{
    /// <summary>
    /// The launch verbs (see docs/gameplay.md). The trolley is a Binary choice; the everyday
    /// volume also runs on MultipleChoice (pick one of several). New values are appended so the
    /// existing serialized indices never shift. Allocation, CoordinationGamble and SelfSacrifice
    /// are the heavy-spike verbs; further verbs are post-launch scope.
    /// </summary>
    public enum DilemmaVerb { Binary, Allocation, CoordinationGamble, SelfSacrifice, MultipleChoice }
}
