namespace YourCall
{
    /// <summary>
    /// One resolver per verb. Pure logic: the player's choice plus the dilemma data
    /// (and, for coordination, the seeded crowd) produce the outcome. DilemmaStage never
    /// branches on verb; it asks <see cref="VerbResolvers"/> for the right one.
    /// </summary>
    public abstract class VerbResolver
    {
        public abstract DilemmaVerb Verb { get; }
        public abstract DilemmaOutcome Resolve(DilemmaContext context);
    }
}
