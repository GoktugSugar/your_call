namespace YourCall
{
    /// <summary>
    /// Maps a verb to its resolver so DilemmaStage stays free of verb-specific branches.
    /// A new verb is a new resolver plus one line here.
    /// </summary>
    public static class VerbResolvers
    {
        public static VerbResolver For(DilemmaVerb verb)
        {
            switch (verb)
            {
                case DilemmaVerb.Binary: return new BinaryResolver();
                case DilemmaVerb.CoordinationGamble: return new CoordinationGambleResolver();
                case DilemmaVerb.Allocation: return new AllocationResolver();
                case DilemmaVerb.SelfSacrifice: return new SelfSacrificeResolver();
                default: return new BinaryResolver();
            }
        }
    }
}
